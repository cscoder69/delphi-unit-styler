program StylerCoreTests;

{$APPTYPE CONSOLE}
{$RANGECHECKS ON}
{$OVERFLOWCHECKS ON}

uses
  System.SysUtils,
  CSCoder.Styler.Types in '..\src\core\CSCoder.Styler.Types.pas',
  CSCoder.Styler.Lexer in '..\src\core\CSCoder.Styler.Lexer.pas',
  CSCoder.Styler.UsesParser in '..\src\core\CSCoder.Styler.UsesParser.pas',
  CSCoder.Styler.Engine in '..\src\core\CSCoder.Styler.Engine.pas',
  CSCoder.Styler.Strings in '..\src\i18n\CSCoder.Styler.Strings.pas',
  CSCoder.Styler.UsesOrganizer in '..\src\core\CSCoder.Styler.UsesOrganizer.pas';

var Checks: NativeInt;

procedure Check(Condition: Boolean; const Message: string);
begin
  Inc(Checks);
  if not Condition then raise Exception.Create(Message);
end;

procedure CheckLexer(const Source: string);
var Tokens: TStylerTokens; T: TStylerToken; Joined: string; P: NativeInt;
begin
  Tokens := Tokenize(Source);
  Joined := '';
  P := 0;
  for T in Tokens do
  begin
    Check(T.Range.Start = P, 'Lexer must produce contiguous ranges');
    Check(T.Range.Length > 0, 'Lexer must advance');
    Check(Copy(Source, T.Range.Start + 1, T.Range.Length) = T.Text, 'Token range');
    Joined := Joined + T.Text;
    P := T.Range.EndOffset;
  end;
  Check(Joined = Source, 'Lexer must preserve every UTF-16 code unit');
end;

procedure TestLexer;
var Tokens: TStylerTokens;
begin
  CheckLexer('');
  CheckLexer('unit X;'#13#10'interface uses &Type, System.SysUtils; implementation end.');
  CheckLexer('{ uses } (* interface *) // implementation'#10'''it''''s uses'' {$IFDEF X} (*$ENDIF*)');
  CheckLexer('unit U; {a '#$D83D#$DE00' comment} interface'#13'uses A;');
  CheckLexer('''broken'#10'next {broken');
  CheckLexer('(*broken');
  Tokens := Tokenize('''it''''s''');
  Check((Length(Tokens) = 1) and (Tokens[0].Kind = tkString), 'Escaped quote');
  Tokens := Tokenize('{$IFDEF X} (*$ENDIF*)');
  Check((Tokens[0].Kind = tkDirective) and (Tokens[2].Kind = tkDirective), 'Both directive styles');
  Tokens := Tokenize('''bad');
  Check(Tokens[0].Kind = tkInvalid, 'Unterminated string');
  Tokens := Tokenize('(*bad');
  Check(Tokens[0].Kind = tkInvalid, 'Unterminated comment');
end;

procedure TestParser;
var R: TUsesParseResult; S: string;
begin
  S := 'unit U; interface uses B, System.A; implementation uses C; end.';
  R := ParseUses(S);
  Check(Length(R.Clauses) = 2, 'Both sections');
  Check(R.Clauses[0].Section = usInterface, 'Interface kind');
  Check(R.Clauses[1].Section = usImplementation, 'Implementation kind');
  Check(R.Clauses[0].CanOrganize and R.Clauses[1].CanOrganize, 'Simple clauses safe');
  Check(Length(R.Clauses[0].Items) = 2, 'Two interface units');
  Check(R.Clauses[0].Items[1].Name = 'System.A', 'Namespace');
  Check(Copy(S, R.Clauses[0].Range.Start + 1, R.Clauses[0].Range.Length) =
    'uses B, System.A;', 'Exact clause range');
  R := ParseUses('unit U; interface implementation end.');
  Check(Length(R.Clauses) = 0, 'No uses');
  R := ParseUses('program U; uses A; begin end.');
  Check((Length(R.Clauses) = 0) and (Length(R.Diagnostics) = 1), 'Unsupported program');
  R := ParseUses('unit U interface uses A; implementation end.');
  Check(Length(R.Clauses) = 0, 'Broken header');
  R := ParseUses('unit U; interface {uses Fake;} uses &Type in ''it''''s.pas'', A; implementation end.');
  Check(R.Clauses[0].CanOrganize, 'Path safe');
  Check(R.Clauses[0].Items[0].Declaration = '&Type in ''it''''s.pas''', 'Preserve path and escaping');
  R := ParseUses('unit U; interface uses A,'#10'// comment'#10'B; implementation uses C; end.');
  Check(not R.Clauses[0].CanOrganize, 'Comment in the middle protects the clause');
  R := ParseUses('unit U; interface uses A, // of A'#10'B; // of B'#10'implementation uses C; end.');
  Check(R.Clauses[0].CanOrganize and (R.Clauses[0].Items[0].Comment = ' // of A') and
    (R.Clauses[0].Items[1].Comment = ' // of B'), 'End-of-line comments belong to their units');
  Check(R.Clauses[1].CanOrganize, 'Independent safe implementation');
  S := 'unit U; interface uses // top'#10' {more} B, A; implementation end.';
  R := ParseUses(S);
  Check(R.Clauses[0].CanOrganize and
    (Copy(S, R.Clauses[0].Range.Start + 1, R.Clauses[0].HeaderEnd - R.Clauses[0].Range.Start) =
    'uses // top'#10' {more}'), 'Comments before the first unit form the clause header');
  R := ParseUses('unit U; interface uses A, {$IFDEF X}B, {$ENDIF}C; implementation uses D; end.');
  Check(R.Clauses[0].CanOrganize and not R.Clauses[0].Items[0].Fixed and
    R.Clauses[0].Items[1].Fixed and not R.Clauses[0].Items[2].Fixed, 'Conditional block pins only its own unit');
  R := ParseUses('unit U; interface uses A, {$IFDEF X}B; {$ELSE}C; {$ENDIF} implementation uses D; end.');
  Check(not R.Clauses[0].CanOrganize, 'Terminator inside a conditional block protects the clause');
  Check(R.Clauses[1].CanOrganize, 'Other section still safe');
  R := ParseUses('unit U; interface uses A, a; implementation end.');
  Check(not R.Clauses[0].CanOrganize, 'Duplicate protected');
  R := ParseUses('unit U; interface uses A,; implementation end.');
  Check(not R.Clauses[0].CanOrganize, 'Trailing comma');
  R := ParseUses('unit U; interface uses A implementation uses B; end.');
  Check((Length(R.Clauses) = 2) and not R.Clauses[0].CanOrganize, 'Missing semicolon boundary');
  R := ParseUses('unit U; interface const S = ''uses Fake; implementation''; implementation uses RealUnit; end.');
  Check((Length(R.Clauses) = 1) and (R.Clauses[0].Items[0].Name = 'RealUnit'), 'Ignore strings');
  R := ParseUses('unit U; interface type T = interface end; implementation uses A; end.');
  Check(Length(R.Clauses) = 1, 'Interface type is not a section');
  R := ParseUses('unit U; interface uses A; implementation {broken');
  Check(not R.Clauses[0].CanOrganize, 'Broken source protects all clauses');
  R := ParseUses('unit U; interface uses ; implementation end.');
  Check(not R.Clauses[0].CanOrganize, 'Empty clause');
  R := ParseUses('unit U; interface {$IFDEF X} implementation uses A; {$ENDIF} end.');
  Check((Length(R.Clauses) = 0) or not R.Clauses[0].CanOrganize, 'Conditional section boundary protected');
end;

procedure TestOrderingRules;
var O: TUsesOptions; S, Actual: string; P: TStylerProposal;
  R: TUsesParseResult; Mask, I, J: NativeInt; Found, Rejected: Boolean;

  procedure Expect(const Input, Expected, Message: string);
  var Output: string;
  begin
    Output := AnalyzeUses(Input, O).ApplyTo(Input);
    Check(Output = Expected, Message);
    Check(Length(AnalyzeUses(Output, O).Edits) = 0, Message + ' idempotent');
  end;

begin
  O := Default(TUsesOptions);
  O.Priorities := ['Missing', 'Z', 'A'];
  O.PrioritiesEnabled := True;
  S := 'unit U; interface uses B, A, Z, C; implementation uses C, A; end.';
  Expect(S, 'unit U; interface uses Z, A, B, C; implementation uses A, C; end.', 'Manual priorities and absent units');
  O.Alphabetical := True;
  Expect(S, 'unit U; interface uses Z, A, B, C; implementation uses A, C; end.', 'Alphabetical keeps manual priorities');
  O.Priorities := ['App.*', 'App.A'];
  Expect('unit U; interface uses Z, App.Z, App.A, App.B; implementation end.',
    'unit U; interface uses App.Z, App.A, App.B, Z; implementation end.', 'Priority prefix preserves relative order and first match');
  Check(SelectorMatches('System.*', 'system.SysUtils'), 'Prefix case independent');
  Check(not SelectorMatches('System.*', 'Systematic.Unit1'), 'Namespace boundary');
  Check(not SelectorMatches('System.*', 'System'), 'Prefix requires child');
  Check(SelectorMatches('Type', '&Type'), 'Escaped identifier exact match');
  O.PrioritiesEnabled := False;
  O.GroupingEnabled := True;
  O.Alphabetical := False;
  SetLength(O.Groups, 3);
  O.Groups[0].Name := 'System';
  O.Groups[0].Selectors := ['System.*'];
  O.Groups[1].Name := 'Application';
  O.Groups[1].Selectors := ['App.*', 'System.A'];
  O.Groups[2].Name := 'Empty';
  O.Groups[2].Selectors := ['Missing.*'];
  S := 'unit U; interface uses Other, App.Z, System.Z, App.A, System.A; implementation end.';
  Expect(S, 'unit U; interface uses System.Z, System.A, App.Z, App.A, Other; implementation end.', 'Groups keep relative order and first group wins overlap');
  O.UngroupedPosition := upFirst;
  Expect(S, 'unit U; interface uses Other, System.Z, System.A, App.Z, App.A; implementation end.', 'Ungrouped first');
  O.UngroupedPosition := upLast;
  O.Alphabetical := True;
  Expect(S, 'unit U; interface uses System.A, System.Z, App.A, App.Z, Other; implementation end.', 'Alphabetical inside groups');
  O.PrioritiesEnabled := True;
  O.Priorities := ['App.Z', 'System.Z'];
  Expect(S, 'unit U; interface uses App.Z, System.Z, System.A, App.A, Other; implementation end.', 'Priorities before groups');
  O.OneUnitPerLine := True;
  O.IndentationEnabled := True;
  O.Indentation := '  ';
  O.BlankLinesBetweenGroups := True;
  S := 'unit U;'#10'interface uses Other, App.Z, System.Z, App.A, System.A;'#10'implementation end.';
  Expect(S, 'unit U;'#10'interface uses'#10'  App.Z,'#10'  System.Z,'#10#10'  System.A,'#10#10'  App.A,'#10#10'  Other;'#10'implementation end.', 'Blank separators for populated blocks');
  O.OneUnitPerLine := False;
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check(Pos('App.Z, System.Z,'#10#10'  System.A', Actual) > 0, 'Group breaks without forcing one per line');
  Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Group breaks without one per line stable');

  // Exercise option combinations and ensure every unit/path is conserved.
  S := 'unit U;'#13#10'interface uses Other, App.Z in ''App.Z.pas'', System.Z,'#13#10'  App.A, System.A;'#13#10'implementation uses System.A, Other; end.';
  for Mask := 0 to 63 do
  begin
    O.Alphabetical := (Mask and 1) <> 0;
    O.PrioritiesEnabled := (Mask and 2) <> 0;
    O.GroupingEnabled := (Mask and 4) <> 0;
    O.OneUnitPerLine := (Mask and 8) <> 0;
    O.BlankLinesBetweenGroups := (Mask and 16) <> 0;
    O.IndentationEnabled := (Mask and 32) <> 0;
    P := AnalyzeUses(S, O);
    Actual := P.ApplyTo(S);
    Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Combination idempotent ' + IntToStr(Mask));
    R := ParseUses(Actual);
    Check((Length(R.Clauses) = 2) and (Length(R.Clauses[0].Items) = 5) and
      (Length(R.Clauses[1].Items) = 2), 'Combination unit count');
    for I := 0 to 4 do
    begin
      Found := False;
      for J := 0 to High(R.Clauses[0].Items) do
        if R.Clauses[0].Items[J].Declaration = ParseUses(S).Clauses[0].Items[I].Declaration then Found := True;
      Check(Found, 'Combination conserves declaration');
    end;
  end;
  O := Default(TUsesOptions);
  O.Priorities := ['bad selector'];
  O.Groups := nil;
  O.BlankLinesBetweenGroups := True;
  Check(Length(AnalyzeUses(S, O).Edits) = 0, 'Disabled rules and populated settings are no-op');
  O.PrioritiesEnabled := True;
  Rejected := False;
  try AnalyzeUses(S, O); except on E: EArgumentException do Rejected := True; end;
  Check(Rejected, 'Invalid enabled selector rejected');
  O.Priorities := ['System.A', 'system.a'];
  Rejected := False;
  try AnalyzeUses(S, O); except on E: EArgumentException do Rejected := True; end;
  Check(Rejected, 'Duplicate priority rejected');
  O.PrioritiesEnabled := False;
  O.GroupingEnabled := True;
  SetLength(O.Groups, 1);
  O.Groups[0].Name := '';
  Rejected := False;
  try AnalyzeUses(S, O); except on E: EArgumentException do Rejected := True; end;
  Check(Rejected, 'Empty group name rejected');
end;

procedure TestCommentsAndExclusions;
var O: TUsesOptions; S, Actual: string; P: TStylerProposal; R: TUsesParseResult;
  Mask: NativeInt;

  procedure Expect(const Input, Expected, Message: string);
  var Output: string;
  begin
    Output := AnalyzeUses(Input, O).ApplyTo(Input);
    Check(Output = Expected, Message);
    Check(Length(AnalyzeUses(Output, O).Edits) = 0, Message + ' idempotent');
  end;

begin
  O := Default(TUsesOptions);
  O.Alphabetical := True;
  // Comments before the first unit stay on top; the units below are organized.
  Expect('unit U; interface uses // top'#10' Z, A; implementation end.',
    'unit U; interface uses // top'#10' A, Z; implementation end.', 'Line comment stays at the top');
  Expect('unit U; interface uses {top} Z, A; implementation end.',
    'unit U; interface uses {top} A, Z; implementation end.', 'Block comment stays at the top');
  Expect('unit U; interface uses'#10' //Old.Unit,'#10' // second line'#10' Z, A; implementation end.',
    'unit U; interface uses'#10' //Old.Unit,'#10' // second line'#10' A, Z; implementation end.', 'Several top comments stay in order');
  Expect('unit U; interface uses Z, A; // after'#10'implementation end.',
    'unit U; interface uses A, Z; // after'#10'implementation end.', 'Comment after the terminator stays in place');
  // A comment that is not at the end of the line of a single unit, after its
  // separator, keeps the whole clause untouched.
  for S in TArray<string>.Create(
    'unit U; interface uses Z {Z note}, A; implementation end.',
    'unit U; interface uses Z,'#10' // A note'#10' A; implementation end.',
    'unit U; interface uses Z,'#10' //Old.Unit,'#10' A; implementation end.',
    'unit U; interface uses Z,'#10#10' // detached heading'#10' A; implementation end.',
    'unit U; interface uses System.{internal}SysUtils, A; implementation end.',
    'unit U; interface uses Z, {ambiguous} A; implementation end.',
    'unit U; interface uses Z (*multi'#10'line*), A; implementation end.',
    'unit U; interface uses Z, A {last}; implementation end.') do
  begin
    P := AnalyzeUses(S, O);
    Check((Length(P.Edits) = 0) and (Length(P.Diagnostics) > 0), 'Middle comment preserves the clause: ' + S);
  end;
  S := 'unit U; interface uses Z,'#10' // note'#10' A; implementation uses D, C; end.';
  Check(AnalyzeUses(S, O).ApplyTo(S) = 'unit U; interface uses Z,'#10' // note'#10' A; implementation uses C, D; end.',
    'Other section still organized');
  O.OneUnitPerLine := True;
  O.IndentationEnabled := True;
  O.Indentation := '  ';
  Expect('unit U;'#13#10'interface'#13#10'uses'#13#10'   //Old.Unit,'#13#10'   Z,'#13#10#13#10'   B, A;'#13#10'implementation end.',
    'unit U;'#13#10'interface'#13#10'uses'#13#10'   //Old.Unit,'#13#10'  A,'#13#10'  B,'#13#10'  Z;'#13#10'implementation end.',
    'Top comment kept with one unit per line');
  O.Priorities := ['Z'];
  SetLength(O.Groups, 2);
  O.Groups[0].Name := 'First';
  O.Groups[0].Selectors := ['A'];
  O.Groups[1].Name := 'Other';
  O.Groups[1].Selectors := ['B', 'Z'];
  S := 'unit U;'#10'interface uses // top note'#10' Z, B,'#10' A;'#10'implementation uses {impl} Y, X; end.';
  for Mask := 0 to 63 do
  begin
    O.Alphabetical := (Mask and 1) <> 0;
    O.PrioritiesEnabled := (Mask and 2) <> 0;
    O.GroupingEnabled := (Mask and 4) <> 0;
    O.OneUnitPerLine := (Mask and 8) <> 0;
    O.BlankLinesBetweenGroups := (Mask and 16) <> 0;
    O.IndentationEnabled := (Mask and 32) <> 0;
    Actual := AnalyzeUses(S, O).ApplyTo(S);
    Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Top comment combination idempotent ' + IntToStr(Mask));
    R := ParseUses(Actual);
    Check((Length(R.Clauses) = 2) and R.Clauses[0].CanOrganize and
      R.Clauses[1].CanOrganize, 'Top comments remain structurally safe ' + IntToStr(Mask));
    Check((Pos('uses // top note', Actual) > 0) and (Pos('uses {impl}', Actual) > 0),
      'Top comments stay next to uses ' + IntToStr(Mask));
    Check(Length(R.Clauses[0].Items) = 3, 'Top comment combination keeps units ' + IntToStr(Mask));
  end;

  O := Default(TUsesOptions);
  O.Alphabetical := True;
  O.ExcludedUnits := ['Anchor'];
  S := 'unit U; interface uses Z, B, Anchor, Y, A; implementation uses Anchor, D, C; end.';
  Expect(S, 'unit U; interface uses B, Z, Anchor, A, Y; implementation uses Anchor, C, D; end.', 'Exclusion partitions sections without crossings');
  O.PrioritiesEnabled := True;
  O.Priorities := ['A', 'B', 'Anchor'];
  Expect(S, 'unit U; interface uses B, Z, Anchor, A, Y; implementation uses Anchor, C, D; end.', 'Priorities cannot cross excluded anchor');
  O.ExcludedUnits := ['System.*'];
  Expect('unit U; interface uses Z, A, System.Anchor, Y, B; implementation end.',
    'unit U; interface uses A, Z, System.Anchor, B, Y; implementation end.', 'Exclusion prefix');
  O.ExcludedUnits := ['Anchor'];
  O.OneUnitPerLine := True;
  O.IndentationEnabled := True;
  O.Indentation := '  ';
  Expect('unit U;'#10'interface uses Z,'#10#9'Anchor,'#10' A;'#10'implementation end.',
    'unit U;'#10'interface uses'#10'  Z,'#10#9'Anchor,'#10' A;'#10'implementation end.', 'Anchor boundaries preserve original layout');
  Expect('unit U; interface uses Z, // Z'#10' Anchor, A; implementation end.',
    'unit U; interface uses'#10'  Z, // Z'#10' Anchor, A; implementation end.', 'End-of-line comment beside an anchor');
  S := 'unit U; interface uses Z,'#10' // note'#10' Anchor, A; implementation end.';
  P := AnalyzeUses(S, O);
  Check((Length(P.Edits) = 0) and (Length(P.Diagnostics) > 0), 'Comments plus anchors conservatively protected');
  O.ExcludedUnits := ['Z', 'Anchor', 'A'];
  S := 'unit U; interface uses Z, Anchor, A; implementation end.';
  Check(Length(AnalyzeUses(S, O).Edits) = 0, 'All units excluded');
end;

procedure TestEngine;
var O: TUsesOptions; P: TStylerProposal; S, Actual: string; Rejected: Boolean;
begin
  O := Default(TUsesOptions);
  O.Indentation := '  ';
  S := 'unit U; interface uses Z, A; implementation uses D, B; end.';
  P := AnalyzeUses(S, O);
  Check((Length(P.Edits) = 0) and (P.ApplyTo(S) = S), 'All options disabled');
  O.Alphabetical := True;
  P := AnalyzeUses(S, O);
  Actual := P.ApplyTo(S);
  Check(Actual = 'unit U; interface uses A, Z; implementation uses B, D; end.', 'Sort both sections');
  Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Sort idempotent');
  Rejected := False;
  try P.ApplyTo(StringReplace(S, 'uses Z', 'uses Q', []));
  except on E: EArgumentException do Rejected := True; end;
  Check(Rejected, 'Stale patch must be rejected');
  Rejected := False;
  try P.ApplyTo(S + ' ');
  except on E: EArgumentException do Rejected := True; end;
  Check(Rejected, 'Change outside patch must invalidate snapshot');
  O.ExcludedSections := [usInterface];
  Check(Length(AnalyzeUses(S, O).Edits) = 1, 'Section exclusion');
  O.ExcludedSections := [];
  S := 'unit U;'#10'interface'#10'uses Z,'#10'    A, B;'#10'implementation end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check(Actual = 'unit U;'#10'interface'#10'uses A,'#10'    B, Z;'#10'implementation end.', 'Keep line slots');
  O.OneUnitPerLine := True;
  O.IndentationEnabled := True;
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check(Actual = 'unit U;'#10'interface'#10'uses'#10'  A,'#10'  B,'#10'  Z;'#10'implementation end.', 'One per line and LF');
  Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Formatting idempotent');
  S := 'unit U; interface uses Z in ''Z.pas'', A; implementation end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check(Pos('Z in ''Z.pas''', Actual) > 0, 'Path survives ordering');
  S := 'unit U; interface uses Z, {for Z} A; implementation end.';
  P := AnalyzeUses(S, O);
  Check((Length(P.Edits) = 0) and (Length(P.Diagnostics) > 0), 'Ambiguous comment preserved');
  S := 'unit U; interface uses Z, {$IFDEF X}A{$ENDIF}; implementation uses Z, A; end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check(Pos('Z, {$IFDEF X}A{$ENDIF};', Actual) > 0, 'Conditional block text kept verbatim');
  Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Conditional block idempotent');
  S := 'unit U;'#13#10'interface'#10'uses Z, A; implementation end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check((Pos('unit U;'#13#10'interface'#10'uses', Actual) = 1) and (Pos('A', Actual) < Pos('Z', Actual)),
    'Mixed line endings: clause organized, breaks outside it kept');
  O := Default(TUsesOptions);
  O.IndentationEnabled := True;
  O.Indentation := #9;
  S := 'unit U;'#13'interface'#13'uses'#13'    Z,'#13'  A;'#13'implementation end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check(Actual = 'unit U;'#13'interface'#13'uses'#13#9'Z,'#13#9'A;'#13'implementation end.', 'Indentation alone without sorting');
  Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Indentation idempotent');
end;

procedure TestSectionSpacing;
var O: TUsesOptions; S, Actual, Expected, NL: string;
  P: TStylerProposal; Kind, Flags: Integer;

  function Gap(Before, After: Boolean): string;
  begin
    Result := NL;
    if Before or After then Result := Result + NL;
  end;

begin
  for Kind := 0 to 2 do
  begin
    case Kind of
      0: NL := #10;
      1: NL := #13;
      2: NL := #13#10;
    end;
    S := 'unit U;' + NL + 'interface' + NL + 'uses' + NL + '  B, A;' + NL +
      'implementation' + NL + 'uses' + NL + '  D, C;' + NL +
      'initialization' + NL + '  DoInit;' + NL + 'finalization' + NL + '  DoFinal;' + NL + 'end.';
    for Flags := 0 to 3 do
    begin
      O := Default(TUsesOptions);
      O.BlankBeforeSections := (Flags and 1) <> 0;
      O.BlankAfterSections := (Flags and 2) <> 0;
      Expected := 'unit U;' + Gap(O.BlankBeforeSections, False) +
        'interface' + Gap(O.BlankBeforeSections, O.BlankAfterSections) +
        'uses' + Gap(False, O.BlankAfterSections) + '  B, A;' + Gap(O.BlankBeforeSections, False) +
        'implementation' + Gap(O.BlankBeforeSections, O.BlankAfterSections) +
        'uses' + Gap(False, O.BlankAfterSections) + '  D, C;' + Gap(O.BlankBeforeSections, False) +
        'initialization' + Gap(False, O.BlankAfterSections) + '  DoInit;' + Gap(O.BlankBeforeSections, False) +
        'finalization' + Gap(False, O.BlankAfterSections) + '  DoFinal;' + NL + 'end.';
      P := AnalyzeUses(S, O); Actual := P.ApplyTo(S);
      Check(Actual = Expected, 'Independent section spacing and original newline style');
      Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Section spacing idempotence');
      Check(Copy(Actual, Length(Actual) - 3, 4) = 'end.', 'No final newline added');
    end;
    O.Alphabetical := True; O.OneUnitPerLine := True;
    O.IndentationEnabled := True; O.Indentation := '  ';
    Actual := AnalyzeUses(S, O).ApplyTo(S);
    Check(Pos('uses' + NL + NL + '  A,' + NL + '  B;', Actual) > 0,
      'Spacing combined with uses sorting and rendering');
    Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Combined spacing idempotence');
    S := 'unit U;' + NL + NL + NL + 'interface' + NL + NL + NL +
      'uses' + NL + NL + NL + '  A;' + NL + NL + NL + 'implementation' + NL + NL + NL + 'end.';
    O := Default(TUsesOptions); O.BlankBeforeSections := True; O.BlankAfterSections := True;
    Check(AnalyzeUses(S, O).ApplyTo(S) = S, 'Existing extra blank lines preserved');
  end;
  O := Default(TUsesOptions); O.BlankBeforeSections := True; O.BlankAfterSections := True;
  S := 'unit U;'#10'interface'#10'uses'#10'  // associated with A'#10'  A;'#10'implementation'#10'end.';
  P := AnalyzeUses(S, O); Actual := P.ApplyTo(S);
  Check(Pos('uses'#10'  // associated with A'#10'  A;', Actual) > 0, 'Comment association preserved');
  Check(Length(P.Diagnostics) > 0, 'Skipped section spacing explained');
  Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Comment spacing idempotence');
  S := 'unit U;'#10'interface // section comment'#10'uses A;'#10'implementation'#10'end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check(Pos('interface // section comment'#10'uses', Actual) > 0, 'Header line comment kept adjacent');
  S := 'unit U; interface {$IFDEF X} uses A; {$ENDIF} implementation end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check(Pos('{$IFDEF X} uses A; {$ENDIF}', Actual) > 0, 'Conditional uses header keeps its spacing');
  Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Conditional header spacing idempotence');
  S := 'unit U;'#13#10'interface'#10'uses A; implementation end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check((Actual <> S) and (Pos('unit U;'#13#10#13#10'interface'#10#10'uses'#10#10, Actual) = 1) and
    (Pos(#13, Copy(Actual, Pos('interface', Actual), MaxInt)) = 0),
    'Mixed line endings: each blank line uses the break in use at its header');
  Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Mixed line endings spacing second run');
  S := 'unit U; interface uses A,; implementation end.';
  Check(Length(AnalyzeUses(S, O).Edits) = 0, 'Incomplete uses protects section spacing');
  S := 'unit U; interface uses A;';
  Check(Length(AnalyzeUses(S, O).Edits) = 0, 'Incomplete unit protects section spacing');
  S := 'program U; uses A; begin end.';
  Check(Length(AnalyzeUses(S, O).Edits) = 0, 'Program outside section spacing scope');
  O.ExcludedSections := [usInterface, usImplementation];
  S := 'unit U; interface uses A; implementation uses B; end.';
  Check(Length(AnalyzeUses(S, O).Edits) = 0, 'Excluded sections protected from spacing');
  O.ExcludedSections := [];
  S := 'unit U;'#10'interface'#10'const Text = ''implementation uses initialization finalization'';'#10 +
    'type T = interface end;'#10'implementation'#10'end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check(Pos('''implementation uses initialization finalization''', Actual) > 0, 'Strings untouched');
  Check(Pos('type T = interface end;', Actual) > 0, 'Interface type untouched');
  S := 'unit U;'#10'// '#$D83D#$DE00#10'interface'#10'uses A;'#10'implementation'#10'end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check(Pos('// '#$D83D#$DE00#10'interface', Actual) > 0, 'UTF-16 offsets and comment protected');
  Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Unicode spacing idempotence');
  O.ExcludedUnits := ['Anchor'];
  S := 'unit U;'#10'interface'#10'uses Anchor, Z;'#10'implementation'#10'end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check(Pos('uses Anchor, Z;', Actual) > 0, 'Spacing keeps excluded first unit boundary');
  Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Excluded unit spacing idempotence');
end;

procedure TestDirectives;
var O: TUsesOptions; S, Actual: string; P: TStylerProposal; Tokens: TStylerTokens;

  procedure Expect(const Input, Expected, Message: string);
  var Output: string;
  begin
    Output := AnalyzeUses(Input, O).ApplyTo(Input);
    Check(Output = Expected, Message);
    Check(Length(AnalyzeUses(Output, O).Edits) = 0, Message + ' idempotent');
  end;

begin
  O := Default(TUsesOptions);
  O.Alphabetical := True;
  // Directives outside the uses clauses stay in place and never block a unit.
  S := 'unit U; interface uses B, A; implementation uses D, C; {$R *.dfm} end.';
  Expect(S, 'unit U; interface uses A, B; implementation uses C, D; {$R *.dfm} end.', 'Form resource after uses');
  Check(Length(AnalyzeUses(S, O).Diagnostics) = 0, 'Outer directives are not reported');
  Expect('unit U; interface uses B, A; implementation {$R *.dfm} uses D, C; end.',
    'unit U; interface uses A, B; implementation {$R *.dfm} uses C, D; end.', 'Form resource before uses');
  Expect('unit U; interface uses B, A; implementation (*$R *.dfm*) end.',
    'unit U; interface uses A, B; implementation (*$R *.dfm*) end.', 'Parenthesis directive style');
  Expect('{$I defs.inc} unit U; {$WARN SYMBOL_PLATFORM OFF} interface uses B, A; implementation ' +
    'procedure X; begin {$IFDEF DEBUG} Beep; {$ENDIF} end; end.',
    '{$I defs.inc} unit U; {$WARN SYMBOL_PLATFORM OFF} interface uses A, B; implementation ' +
    'procedure X; begin {$IFDEF DEBUG} Beep; {$ENDIF} end; end.', 'Include, switch and body conditional');
  Expect('unit U; interface {$IFDEF FPC}{$MODE DELPHI}{$ENDIF} uses B, A; implementation end.',
    'unit U; interface {$IFDEF FPC}{$MODE DELPHI}{$ENDIF} uses A, B; implementation end.',
    'Closed conditional block before uses');
  // A section keyword inside a conditional block keeps only that clause.
  S := 'unit U; interface {$IFDEF X} uses B, A; {$ELSE} uses D, C; {$ENDIF} implementation uses F, E; end.';
  P := AnalyzeUses(S, O);
  Check(P.ApplyTo(S) = 'unit U; interface {$IFDEF X} uses B, A; {$ELSE} uses D, C; {$ENDIF} implementation uses E, F; end.',
    'Conditional uses preserved, other section organized');
  Check(Length(P.Diagnostics) > 0, 'Conditional uses explained');
  S := 'unit U; interface uses B, A; {$IFDEF X} implementation uses D, C; {$ENDIF} end.';
  Check(AnalyzeUses(S, O).ApplyTo(S) = 'unit U; interface uses A, B; {$IFDEF X} implementation uses D, C; {$ENDIF} end.',
    'Conditional implementation preserved');
  S := 'unit U; {$IFDEF X} interface uses B, A; {$ENDIF} implementation uses D, C; end.';
  P := AnalyzeUses(S, O);
  Check((Length(P.Edits) = 0) and (Length(P.Diagnostics) > 0), 'Conditional interface protects the unit');
  // Directive blocks inside uses are fixed points: nothing crosses them and
  // their text, commas included, is copied verbatim.
  S := 'unit U; interface uses D, C, {$IFDEF X}Z, {$ENDIF}B, A; implementation end.';
  Expect(S, 'unit U; interface uses C, D, {$IFDEF X}Z, {$ENDIF}A, B; implementation end.', 'Block in the middle');
  Check(Length(AnalyzeUses(S, O).Diagnostics) = 0, 'Handled block is not reported');
  Expect('unit U; interface uses C, B {$IFDEF X}, Z {$ENDIF}; implementation end.',
    'unit U; interface uses B, C {$IFDEF X}, Z {$ENDIF}; implementation end.', 'Block at the end keeps its own separators');
  Expect('unit U; interface uses {$IFDEF X}Z, {$ENDIF} C, B; implementation end.',
    'unit U; interface uses {$IFDEF X}Z, {$ENDIF} B, C; implementation end.', 'Block at the start');
  Expect('unit U; interface uses D, C, {$IFDEF X}Z1, {$ELSE}Z2, {$ENDIF} B, A; implementation end.',
    'unit U; interface uses C, D, {$IFDEF X}Z1, {$ELSE}Z2, {$ENDIF} A, B; implementation end.', 'Block with else branch');
  Expect('unit U; interface uses D, C, {$IFDEF X}Z, {$ELSE}Z, {$ENDIF} B, A; implementation end.',
    'unit U; interface uses C, D, {$IFDEF X}Z, {$ELSE}Z, {$ENDIF} A, B; implementation end.', 'Same unit in alternative branches');
  Expect('unit U; interface uses D, C, {$IFDEF X}{$IFDEF Y}Z, {$ENDIF}Y, {$ENDIF} B, A; implementation end.',
    'unit U; interface uses C, D, {$IFDEF X}{$IFDEF Y}Z, {$ENDIF}Y, {$ENDIF} A, B; implementation end.', 'Nested blocks');
  Expect('unit U; interface uses D, C, {$WARN X OFF} B, A; implementation end.',
    'unit U; interface uses C, D, {$WARN X OFF} B, A; implementation end.', 'Lone directive pins the next unit');
  Expect('unit U; interface uses B, {$IFDEF X}Z, {$ENDIF}A; implementation end.',
    'unit U; interface uses B, {$IFDEF X}Z, {$ENDIF}A; implementation end.', 'Units never cross a block');
  Expect('unit U; interface uses D, C, // about C'#10'{$IFDEF X}Z, {$ENDIF} A; implementation end.',
    'unit U; interface uses C, // about C'#10'D,'#10'{$IFDEF X}Z, {$ENDIF} A; implementation end.', 'End-of-line comment next to a block follows its unit');
  S := 'unit U; interface uses D, C,'#10'// about the block'#10'{$IFDEF X}Z, {$ENDIF} A; implementation end.';
  P := AnalyzeUses(S, O);
  Check((Length(P.Edits) = 0) and (Length(P.Diagnostics) > 0), 'Comment next to a block preserves the clause');
  S := 'unit U; interface uses D, C, {$IFDEF X}Z {$ELSE}Y {$ENDIF}, A; implementation end.';
  P := AnalyzeUses(S, O);
  Check((Length(P.Edits) = 0) and (Length(P.Diagnostics) > 0), 'Branches without separators preserve the clause');
  O.OneUnitPerLine := True; O.IndentationEnabled := True; O.Indentation := '  ';
  Expect('unit U;'#10'interface'#10'uses'#10'   untMainForm,'#10'   MainModule,'#10'   {$IFDEF DEBUG}'#10'      untDemo,'#10 +
    '   {$ENDIF}'#10'   untZ,'#10'   untA;'#10'implementation'#10'end.',
    'unit U;'#10'interface'#10'uses'#10'  MainModule,'#10'  untMainForm,'#10'   {$IFDEF DEBUG}'#10'      untDemo,'#10 +
    '   {$ENDIF}'#10'  untA,'#10'  untZ;'#10'implementation'#10'end.', 'Debug block kept intact between sorted units');
  O := Default(TUsesOptions); O.Alphabetical := True;
  // Delphi 12 multiline strings are a single token, not broken text.
  S := 'const S = '''''''#10'  it''s uses X;'#10'  '''''';';
  Tokens := Tokenize(S);
  CheckLexer(S);
  Check((Tokens[6].Kind = tkString) and (Tokens[7].Kind = tkSemicolon) and (Length(Tokens) = 8), 'Multiline string token');
  S := 'unit U; interface uses B, A; implementation'#10'const S = '''''''#10'  it''s uses X;'#10'  '''''';'#10'end.';
  Expect(S, 'unit U; interface uses A, B; implementation'#10'const S = '''''''#10'  it''s uses X;'#10'  '''''';'#10'end.',
    'Multiline string does not block the unit');
  Tokens := Tokenize('''''''bad');
  Check(Tokens[High(Tokens)].Kind = tkInvalid, 'Triple quote without line break keeps old rules');
  // Section spacing works next to directives.
  O := Default(TUsesOptions); O.BlankBeforeSections := True; O.BlankAfterSections := True;
  S := 'unit U;'#10'interface'#10'uses A;'#10'implementation'#10'{$R *.dfm}'#10'end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check(Actual = 'unit U;'#10#10'interface'#10#10'uses'#10#10' A;'#10#10'implementation'#10#10'{$R *.dfm}'#10'end.',
    'Section spacing with form resource');
  Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Directive spacing idempotence');
  O.Alphabetical := True; O.OneUnitPerLine := True; O.IndentationEnabled := True; O.Indentation := '  ';
  S := 'unit U;'#10'interface'#10'uses'#10'  // top'#10'  Z,'#10'  A;'#10'implementation'#10'end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check(Pos('uses'#10'  // top'#10'  A,'#10'  Z;', Actual) > 0, 'Top comment stays next to uses with section spacing');
  Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Comment at top spacing idempotence');
end;

// A to Z by the name before the first dot, keeping the order inside each name.
procedure TestFirstNameSorting;
var O: TUsesOptions; Actual: string;

  procedure Expect(const Input, Expected, Message: string);
  begin
    Actual := AnalyzeUses(Input, O).ApplyTo(Input);
    Check(Actual = Expected, Message + ': ' + Actual);
    Check(Length(AnalyzeUses(Actual, O).Edits) = 0, Message + ' (second run)');
  end;

begin
  O := Default(TUsesOptions);
  O.Alphabetical := True; O.SortFirstNameOnly := True;
  Expect('unit U; interface uses Winapi.Windows, Vcl.Forms, System.SysUtils, Winapi.Messages, System.Classes, Vcl.Controls; implementation end.',
    'unit U; interface uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.Controls, Winapi.Windows, Winapi.Messages; implementation end.',
    'Sorted by first name, order inside each name kept');
  // A unit without a dot counts by its whole name.
  Expect('unit U; interface uses uniPanel, System.SysUtils, uniLabel, Data.DB, untBase, System.Classes; implementation end.',
    'unit U; interface uses Data.DB, System.SysUtils, System.Classes, uniLabel, uniPanel, untBase; implementation end.',
    'Dotless units sorted by their whole name');
  Expect('unit U; interface uses system.Zed, SYSTEM.Alpha, &Type.B, Sys.X; implementation end.',
    'unit U; interface uses Sys.X, system.Zed, SYSTEM.Alpha, &Type.B; implementation end.',
    'Case and escape ignored, Sys is not System');
  // Already in first-name order: nothing to do, whatever the second names.
  Check(Length(AnalyzeUses('unit U; interface uses System.Zed, System.Alpha, Vcl.B, Vcl.A; implementation end.', O).Edits) = 0,
    'First-name order is left alone');
  // With groups the rule applies inside each group.
  O.GroupingEnabled := True; SetLength(O.Groups, 2);
  O.Groups[0].Name := 'Winapi'; O.Groups[0].Selectors := ['Winapi.*'];
  O.Groups[1].Name := 'System'; O.Groups[1].Selectors := ['System.*'];
  Expect('unit U; interface uses Vcl.Forms, System.SysUtils, Data.DB, Winapi.Windows, System.Classes, Vcl.Controls; implementation end.',
    'unit U; interface uses Winapi.Windows, System.SysUtils, System.Classes, Data.DB, Vcl.Forms, Vcl.Controls; implementation end.',
    'Groups first, first-name order inside them');
  O.GroupingEnabled := False;
  // Second name too: the full sort.
  O.SortFirstNameOnly := False;
  Expect('unit U; interface uses Winapi.Windows, Vcl.Forms, System.SysUtils, Winapi.Messages, System.Classes, Vcl.Controls; implementation end.',
    'unit U; interface uses System.Classes, System.SysUtils, Vcl.Controls, Vcl.Forms, Winapi.Messages, Winapi.Windows; implementation end.',
    'Second name sorted as well');
  // The depth means nothing while sorting is off.
  O.Alphabetical := False; O.SortFirstNameOnly := True; O.OneUnitPerLine := False;
  Check(Length(AnalyzeUses('unit U; interface uses Winapi.Windows, System.SysUtils; implementation end.', O).Edits) = 0,
    'Depth alone changes nothing');
end;

// Units protected by the rules of the add-on keep their place, silently.
procedure TestProtectedUnits;
var O: TUsesOptions; Actual: string; P: TStylerProposal; Rejected: Boolean;

  procedure Expect(const Input, Expected, Message: string);
  begin
    P := AnalyzeUses(Input, O);
    Actual := P.ApplyTo(Input);
    Check(Actual = Expected, Message + ': ' + Actual);
    Check(Length(P.Diagnostics) = 0, Message + ' (no warning)');
    Check(Length(AnalyzeUses(Actual, O).Edits) = 0, Message + ' (second run)');
  end;

begin
  O := Default(TUsesOptions);
  O.Alphabetical := True;
  O.ProtectedUnits := ['Winapi.*', 'System.*', 'Vcl.*', 'Classes'];
  // The order that decides who wins a repeated name is the one in the source.
  Expect('unit U; interface uses Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, uZeta, uAlfa, uMeio; implementation end.',
    'unit U; interface uses Winapi.Windows, System.SysUtils, System.Classes, Vcl.Forms, uAlfa, uMeio, uZeta; implementation end.',
    'System units untouched, the rest sorted');
  Expect('unit U; interface uses System.Classes, Winapi.Windows, uB, uA; implementation end.',
    'unit U; interface uses System.Classes, Winapi.Windows, uA, uB; implementation end.',
    'An unusual order of system units is kept too');
  // Nothing moves across a protected unit: each run between them is sorted on its own.
  Expect('unit U; interface uses uZ, uA, Winapi.Windows, uY, uB, System.Classes, uX, uC; implementation end.',
    'unit U; interface uses uA, uZ, Winapi.Windows, uB, uY, System.Classes, uC, uX; implementation end.',
    'Runs between protected units');
  Expect('unit U; interface uses Classes, uB, uA; implementation end.',
    'unit U; interface uses Classes, uA, uB; implementation end.', 'Old unscoped name protected');
  // One per line and indentation still reach the lines of the free units.
  O.OneUnitPerLine := True; O.IndentationEnabled := True; O.Indentation := '  ';
  Expect('unit U;'#10'interface'#10'uses'#10'  Winapi.Windows, System.Classes,'#10'  uB, uA;'#10'implementation'#10'end.',
    'unit U;'#10'interface'#10'uses'#10'  Winapi.Windows, System.Classes,'#10'  uA,'#10'  uB;'#10'implementation'#10'end.',
    'Lines of protected units kept as written');
  O.OneUnitPerLine := False; O.IndentationEnabled := False;
  // A unit preserved by the project is still reported; a protected one is not.
  O.ExcludedUnits := ['uAncora'];
  P := AnalyzeUses('unit U; interface uses Winapi.Windows, uZ, uAncora, uB, uA; implementation end.', O);
  Check((Length(P.Diagnostics) = 1) and (P.Diagnostics[0].Code = dcExcludedUnitBarrier), 'Only the project list is reported');
  Check(P.ApplyTo(P.SourceSnapshot) = 'unit U; interface uses Winapi.Windows, uZ, uAncora, uA, uB; implementation end.', 'Both lists hold their units');
  O.ExcludedUnits := nil;
  // An empty list frees everything, which is the choice of an advanced user.
  O.ProtectedUnits := nil;
  Check(AnalyzeUses('unit U; interface uses Winapi.Windows, System.Classes; implementation end.', O).ApplyTo(
    'unit U; interface uses Winapi.Windows, System.Classes; implementation end.') =
    'unit U; interface uses System.Classes, Winapi.Windows; implementation end.', 'Empty list protects nothing');
  O.ProtectedUnits := ['Bad Name'];
  Rejected := False;
  try ValidateUsesOptions(O); except on E: Exception do Rejected := True; end;
  Check(Rejected, 'Invalid protected entry rejected');
end;

// A file that mixes CRLF and LF: each uses is written with its own kind.
procedure TestMixedLineEndings;
var O: TUsesOptions; S, Actual: string; P: TStylerProposal;

  procedure Expect(const Input, Expected, Message: string);
  begin
    Actual := AnalyzeUses(Input, O).ApplyTo(Input);
    Check(Actual = Expected, Message + ': ' + Actual);
    Check(Length(AnalyzeUses(Actual, O).Edits) = 0, Message + ' (second run)');
  end;

begin
  O := Default(TUsesOptions);
  O.Alphabetical := True; O.OneUnitPerLine := True; O.IndentationEnabled := True; O.Indentation := '  ';
  Expect('unit U;'#13#10'interface'#13#10'uses'#10'  Zeta,'#10'  Alfa;'#13#10'implementation'#13#10'end.',
    'unit U;'#13#10'interface'#13#10'uses'#10'  Alfa,'#10'  Zeta;'#13#10'implementation'#13#10'end.',
    'LF clause inside a CRLF file');
  Expect('unit U;'#10'interface'#10'uses'#13#10'  Zeta,'#13#10'  Alfa;'#10'implementation'#10'end.',
    'unit U;'#10'interface'#10'uses'#13#10'  Alfa,'#13#10'  Zeta;'#10'implementation'#10'end.',
    'CRLF clause inside an LF file');
  // A clause on one line takes the break in use just before it.
  Expect('unit U;'#13#10'interface'#10'uses Zeta, Alfa;'#10'implementation'#13#10'end.',
    'unit U;'#13#10'interface'#10'uses'#10'  Alfa,'#10'  Zeta;'#10'implementation'#13#10'end.',
    'One-line clause after an LF');
  Expect('unit U;'#10'interface'#13#10'uses Zeta, Alfa;'#13#10'implementation'#10'end.',
    'unit U;'#10'interface'#13#10'uses'#13#10'  Alfa,'#13#10'  Zeta;'#13#10'implementation'#10'end.',
    'One-line clause after a CRLF');
  // Two clauses, one of each kind.
  Expect('unit U;'#13#10'interface'#13#10'uses'#13#10'  B,'#13#10'  A;'#13#10'implementation'#10'uses'#10'  D,'#10'  C;'#10'end.',
    'unit U;'#13#10'interface'#13#10'uses'#13#10'  A,'#13#10'  B;'#13#10'implementation'#10'uses'#10'  C,'#10'  D;'#10'end.',
    'Each clause keeps its own kind');
  // Several units per line follows the same rule.
  O.OneUnitPerLine := False; O.WrapUnits := True; O.MaxLineWidth := 100;
  Expect('unit U;'#13#10'interface'#13#10'uses'#10'  Zeta,'#10'  Alfa;'#13#10'implementation'#13#10'end.',
    'unit U;'#13#10'interface'#13#10'uses'#10'  Alfa, Zeta;'#13#10'implementation'#13#10'end.',
    'Wrapped clause keeps its kind');
  O.WrapUnits := False; O.OneUnitPerLine := True;
  // Only a clause that mixes the kinds inside itself is left alone, with a warning.
  S := 'unit U;'#13#10'interface'#13#10'uses'#13#10'  Zeta,'#10'  Alfa;'#13#10'implementation'#13#10'uses'#13#10'  D,'#13#10'  C;'#13#10'end.';
  P := AnalyzeUses(S, O);
  Actual := P.ApplyTo(S);
  Check(Pos('uses'#13#10'  Zeta,'#10'  Alfa;', Actual) > 0, 'Clause mixed inside itself is preserved');
  Check(Pos('uses'#13#10'  C,'#13#10'  D;', Actual) > 0, 'The other clause of that file is organized');
  Check((Length(P.Diagnostics) = 1) and (P.Diagnostics[0].Code = dcUnsupportedStructure), 'Preserved clause is reported');
  // A file with a single kind never gains another.
  S := 'unit U;'#10'interface'#10'uses Zeta, Alfa;'#10'implementation'#10'end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  Check((Pos(#13, Actual) = 0) and (Actual <> S), 'LF file gains no CR');
end;

procedure TestWrap;
var O: TUsesOptions; S, Actual, Line: string; Rejected: Boolean; I: Integer;

  procedure Expect(const Input, Expected, Message: string);
  begin
    Actual := AnalyzeUses(Input, O).ApplyTo(Input);
    Check(Actual = Expected, Message + ': ' + Actual);
    Check(Length(AnalyzeUses(Actual, O).Edits) = 0, Message + ' (second run)');
  end;

begin
  O := Default(TUsesOptions);
  O.WrapUnits := True; O.MaxLineWidth := 40; O.IndentationEnabled := True; O.Indentation := '  ';
  // Lines are filled up to the limit, comma or semicolon included.
  S := 'unit U;'#10'interface'#10'uses'#10'  Alpha.One,'#10'  Beta.Two,'#10'  Gamma.Three,'#10'  Delta.Four,'#10'  Eps;'#10'implementation'#10'end.';
  Expect(S, 'unit U;'#10'interface'#10'uses'#10'  Alpha.One, Beta.Two, Gamma.Three,'#10'  Delta.Four, Eps;'#10'implementation'#10'end.',
    'Units fill the line up to the limit');
  for Line in Actual.Split([#10]) do
    Check(Length(Line) <= 40, 'No line passes the limit: ' + Line);
  // The limit counts the separator: 38 characters plus the comma would be 39.
  O.MaxLineWidth := 40;
  S := 'unit U;'#10'interface'#10'uses A234567890, B234567890, C234567890, D2345;'#10'implementation'#10'end.';
  Expect(S, 'unit U;'#10'interface'#10'uses'#10'  A234567890, B234567890, C234567890,'#10'  D2345;'#10'implementation'#10'end.',
    'Next unit goes down when its separator would not fit');
  S := 'unit U;'#10'interface'#10'uses A234567890, B234567890, C234567890, D;'#10'implementation'#10'end.';
  Expect(S, 'unit U;'#10'interface'#10'uses'#10'  A234567890, B234567890, C234567890, D;'#10'implementation'#10'end.',
    'Exactly at the limit stays on the line');
  // A unit longer than the limit gets a line of its own and is never cut.
  O.MaxLineWidth := 40;
  S := 'unit U;'#10'interface'#10'uses A, Very.Long.Namespace.With.Many.Parts.Of.A.Unit.Name, B;'#10'implementation'#10'end.';
  Expect(S, 'unit U;'#10'interface'#10'uses'#10'  A,'#10'  Very.Long.Namespace.With.Many.Parts.Of.A.Unit.Name,'#10'  B;'#10'implementation'#10'end.',
    'Unit longer than the limit');
  // Sorting and the line breaks of the source are both replaced.
  O.Alphabetical := True; O.MaxLineWidth := 100;
  S := 'unit U;'#13#10'interface'#13#10'uses'#13#10'  Zeta,'#13#10'  Alfa,'#13#10'  Midi;'#13#10'implementation'#13#10'uses Y, X;'#13#10'end.';
  Expect(S, 'unit U;'#13#10'interface'#13#10'uses'#13#10'  Alfa, Midi, Zeta;'#13#10'implementation'#13#10'uses'#13#10'  X, Y;'#13#10'end.',
    'Sorted on one line, both sections, CRLF kept');
  // Each group and the priority block start a line of their own.
  O.GroupingEnabled := True; SetLength(O.Groups, 2);
  O.Groups[0].Name := 'System'; O.Groups[0].Selectors := ['System.*'];
  O.Groups[1].Name := 'Vcl'; O.Groups[1].Selectors := ['Vcl.*'];
  O.PrioritiesEnabled := True; O.Priorities := ['App.Core'];
  S := 'unit U;'#10'interface'#10'uses Vcl.Forms, uB, System.SysUtils, App.Core, Vcl.Controls, uA, System.Classes;'#10'implementation'#10'end.';
  Expect(S, 'unit U;'#10'interface'#10'uses'#10'  App.Core,'#10'  System.Classes, System.SysUtils,'#10'  Vcl.Controls, Vcl.Forms,'#10'  uA, uB;'#10'implementation'#10'end.',
    'One line per group');
  O.BlankLinesBetweenGroups := True;
  Expect(S, 'unit U;'#10'interface'#10'uses'#10'  App.Core,'#10#10'  System.Classes, System.SysUtils,'#10#10'  Vcl.Controls, Vcl.Forms,'#10#10'  uA, uB;'#10'implementation'#10'end.',
    'Blank line between group lines');
  // A long group still wraps inside itself.
  O.BlankLinesBetweenGroups := False; O.MaxLineWidth := 40;
  S := 'unit U;'#10'interface'#10'uses System.SysUtils, System.Classes, System.Math, System.IOUtils, Vcl.Forms;'#10'implementation'#10'end.';
  Expect(S, 'unit U;'#10'interface'#10'uses'#10'  System.Classes, System.IOUtils,'#10'  System.Math, System.SysUtils,'#10'  Vcl.Forms;'#10'implementation'#10'end.',
    'Group wider than the limit wraps');
  // Directive blocks and preserved units stay verbatim; free runs around them wrap.
  O := Default(TUsesOptions);
  O.WrapUnits := True; O.MaxLineWidth := 100; O.Alphabetical := True; O.IndentationEnabled := True; O.Indentation := '  ';
  S := 'unit U;'#10'interface'#10'uses'#10'  Zeta,'#10'  Alfa,'#10'  {$IFDEF DEBUG}'#10'  Demo,'#10'  {$ENDIF}'#10'  Omega,'#10'  Beta;'#10'implementation'#10'end.';
  Expect(S, 'unit U;'#10'interface'#10'uses'#10'  Alfa, Zeta,'#10'  {$IFDEF DEBUG}'#10'  Demo,'#10'  {$ENDIF}'#10'  Beta, Omega;'#10'implementation'#10'end.',
    'Directive block kept between wrapped runs');
  O.ExcludedUnits := ['Anchor'];
  S := 'unit U;'#10'interface'#10'uses'#10'  Zeta,'#10'  Alfa,'#10'  Anchor,'#10'  Omega,'#10'  Beta;'#10'implementation'#10'end.';
  Expect(S, 'unit U;'#10'interface'#10'uses'#10'  Alfa, Zeta,'#10'  Anchor,'#10'  Beta, Omega;'#10'implementation'#10'end.',
    'Preserved unit keeps its place and its line');
  O.ExcludedUnits := nil;
  // Comment at the top stays; a unit with an end-of-line comment keeps a line of its own.
  S := 'unit U;'#10'interface'#10'uses'#10'  // top'#10'  Zeta,'#10'  Alfa;'#10'implementation'#10'end.';
  Expect(S, 'unit U;'#10'interface'#10'uses'#10'  // top'#10'  Alfa, Zeta;'#10'implementation'#10'end.', 'Top comment with wrapped units');
  S := 'unit U;'#10'interface'#10'uses'#10'  Zeta, // why'#10'  Midi,'#10'  Beta,'#10'  Alfa;'#10'implementation'#10'end.';
  Expect(S, 'unit U;'#10'interface'#10'uses'#10'  Alfa, Beta, Midi,'#10'  Zeta; // why'#10'implementation'#10'end.', 'Commented unit last among wrapped units');
  S := 'unit U;'#10'interface'#10'uses'#10'  Zeta,'#10'  Midi, // why'#10'  Beta,'#10'  Alfa;'#10'implementation'#10'end.';
  Expect(S, 'unit U;'#10'interface'#10'uses'#10'  Alfa, Beta,'#10'  Midi, // why'#10'  Zeta;'#10'implementation'#10'end.', 'Commented unit between wrapped units');
  S := 'unit U;'#10'interface'#10'uses'#10'  Zeta,'#10'  // why'#10'  Alfa;'#10'implementation'#10'end.';
  Check(Length(AnalyzeUses(S, O).Edits) = 0, 'Comment in the middle preserves the clause');
  // Without an indentation rule the lines keep the indentation of the first unit.
  O.IndentationEnabled := False;
  S := 'unit U;'#10'interface'#10'uses'#10'    Zeta,'#10'    Alfa;'#10'implementation'#10'end.';
  Expect(S, 'unit U;'#10'interface'#10'uses'#10'    Alfa, Zeta;'#10'implementation'#10'end.', 'Existing indentation kept');
  // Many units: every line within the limit, nothing lost.
  O := Default(TUsesOptions); O.WrapUnits := True; O.MaxLineWidth := 60; O.IndentationEnabled := True; O.Indentation := '  ';
  S := 'unit U;'#10'interface'#10'uses';
  for I := 1 to 40 do
  begin
    S := S + #10'  Unit.Number' + IntToStr(I * 37);
    if I < 40 then S := S + ',';
  end;
  S := S + ';'#10'implementation'#10'end.';
  Actual := AnalyzeUses(S, O).ApplyTo(S);
  for Line in Actual.Split([#10]) do
    Check(Length(Line) <= 60, 'Long list within the limit: ' + Line);
  for I := 1 to 40 do
    Check(Pos('Unit.Number' + IntToStr(I * 37), Actual) > 0, 'Unit kept in the long list');
  Check(Length(Actual.Split([#10])) < 20, 'Long list uses several units per line');
  Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Long list second run');
  // The two layouts exclude each other, and the width has a valid range.
  O.OneUnitPerLine := True;
  Rejected := False;
  try ValidateUsesOptions(O); except on E: Exception do Rejected := True; end;
  Check(Rejected, 'One per line together with several per line is rejected');
  O.OneUnitPerLine := False; O.MaxLineWidth := 10;
  Rejected := False;
  try ValidateUsesOptions(O); except on E: Exception do Rejected := True; end;
  Check(Rejected, 'Width below the minimum is rejected');
  O.WrapUnits := False;
  ValidateUsesOptions(O);
  Check(True, 'Width is ignored when the layout is off');
end;

// A comment at the end of the line of a unit goes wherever the unit goes.
procedure TestLineComments;
const
  Head = 'unit U;'#10'interface'#10'uses'#10;
  Tail = #10'implementation'#10'end.';
var O: TUsesOptions; S, Actual: string; P: TStylerProposal; R: TUsesParseResult; Mask, I, Count: Integer;

  procedure Expect(const Input, Expected, Message: string);
  begin
    Actual := AnalyzeUses(Input, O).ApplyTo(Input);
    Check(Actual = Expected, Message + ': ' + Actual);
    Check(Length(AnalyzeUses(Actual, O).Edits) = 0, Message + ' (second run)');
  end;

  procedure Locked(const Input, Message: string);
  begin
    P := AnalyzeUses(Input, O);
    Check((Length(P.Edits) = 0) and (Length(P.Diagnostics) > 0), Message);
  end;

begin
  O := Default(TUsesOptions);
  O.Alphabetical := True; O.OneUnitPerLine := True; O.IndentationEnabled := True; O.Indentation := '  ';
  // The spacing before the comment travels too, so aligned comments stay aligned.
  Expect(Head + '   SysUtils,'#10'   gtPDFDoc,         // main unit'#10'   gtCstPDFDoc,      // constants'#10'   frxClass;' + Tail,
    Head + '  frxClass,'#10'  gtCstPDFDoc,      // constants'#10'  gtPDFDoc,         // main unit'#10'  SysUtils;' + Tail,
    'Comments follow their units');
  // The unit that ends up last takes its comment after the semicolon.
  Expect(Head + '  Zeta, // z'#10'  Alfa;' + Tail, Head + '  Alfa,'#10'  Zeta; // z' + Tail, 'Commented unit becomes the last');
  // And the comment after the semicolon leaves with the unit it was written for.
  Expect(Head + '  Beta,'#10'  Alfa; // a' + Tail, Head + '  Alfa, // a'#10'  Beta;' + Tail, 'Comment of the last unit moves up');
  Expect(Head + '  Zeta, { z }'#10'  Beta; (* b *)' + Tail, Head + '  Beta, (* b *)'#10'  Zeta; { z }' + Tail, 'Block comments at the end of the line');
  Expect(Head + '  Zeta, //Old.Unit,'#10'  Alfa;' + Tail, Head + '  Alfa,'#10'  Zeta; //Old.Unit,' + Tail, 'Commented-out text is just a comment');
  Expect('unit U;'#13#10'interface'#13#10'uses'#13#10'  Zeta, // z'#13#10'  Alfa;'#13#10'implementation'#13#10'end.',
    'unit U;'#13#10'interface'#13#10'uses'#13#10'  Alfa,'#13#10'  Zeta; // z'#13#10'implementation'#13#10'end.', 'CRLF kept');
  // Code after the semicolon on the same line must not end up inside the comment.
  Expect(Head + '  Zeta, // z'#10'  Alfa; implementation end.', Head + '  Alfa,'#10'  Zeta; // z'#10' implementation end.',
    'Line comment never swallows what follows the clause');
  // Both sections, each with its own comments.
  Expect(Head + '  Zeta, // z'#10'  Alfa;'#10'implementation'#10'uses'#10'  Y, // y'#10'  X;'#10'end.',
    Head + '  Alfa,'#10'  Zeta; // z'#10'implementation'#10'uses'#10'  X,'#10'  Y; // y'#10'end.', 'Both sections');
  // What still keeps the clause as it is.
  // Several units on the line: the comment is of the unit right before it.
  Expect(Head + '  Beta, Alfa, // of Alfa'#10'  Gamma;' + Tail, Head + '  Alfa, // of Alfa'#10'  Beta,'#10'  Gamma;' + Tail,
    'Several units on the commented line');
  // A unit tied to a directive keeps its place, and its comment with it.
  Expect(Head + '  Zeta,'#10'  Beta,'#10'  {$IFDEF D}'#10'  Demo, // d'#10'  {$ENDIF}'#10'  Omega,'#10'  Alfa;' + Tail,
    Head + '  Beta,'#10'  Zeta,'#10'  {$IFDEF D}'#10'  Demo, // d'#10'  {$ENDIF}'#10'  Alfa,'#10'  Omega;' + Tail,
    'Comment on a unit tied to a directive');
  Locked(Head + '  Zeta,'#10'  // about Alfa'#10'  Alfa;' + Tail, 'Comment on a line of its own');
  Locked(Head + '  Zeta // z'#10'  ,Alfa;' + Tail, 'Comment before the separator');
  Locked(Head + '  Zeta, { z } Alfa;' + Tail, 'Comment followed by another unit');
  Locked(Head + '  Zeta, { two'#10'  lines }'#10'  Alfa;' + Tail, 'Comment over two lines');
  // A directive block stays where it is; the commented unit moves up to it.
  Expect(Head + '  Zeta, // z'#10'  Alfa,'#10'  {$IFDEF D}'#10'  Demo,'#10'  {$ENDIF}'#10'  Omega, // o'#10'  Beta;' + Tail,
    Head + '  Alfa,'#10'  Zeta, // z'#10'  {$IFDEF D}'#10'  Demo,'#10'  {$ENDIF}'#10'  Beta,'#10'  Omega; // o' + Tail,
    'Comments beside a directive block');
  // A protected unit keeps its place and its comment.
  O.ProtectedUnits := ['System.*'];
  Expect(Head + '  Zeta,'#10'  System.SysUtils, // sys'#10'  Beta,'#10'  Alfa; // a' + Tail,
    Head + '  Zeta,'#10'  System.SysUtils, // sys'#10'  Alfa, // a'#10'  Beta;' + Tail, 'Protected unit with a comment');
  O.ProtectedUnits := nil;
  // Line breaks of the source kept: the commented unit still gets a line to itself.
  O.OneUnitPerLine := False; O.IndentationEnabled := False;
  Expect(Head + '  Zeta, // z'#10'  Beta, Alfa;' + Tail, Head + '  Alfa,'#10'  Beta,'#10'  Zeta; // z' + Tail, 'Kept line breaks');
  Expect(Head + '  Alfa, // a'#10'  Zeta, Beta;' + Tail, Head + '  Alfa, // a'#10'  Beta, Zeta;' + Tail, 'Kept line breaks, comment stays first');
  Expect('unit U; interface uses Zeta, // z'#10'  Alfa;' + Tail, 'unit U; interface uses Alfa,'#10'  Zeta; // z' + Tail, 'First unit on the line of uses');
  // Every combination of rules: nothing lost, each comment on the line of its unit.
  S := Head + '  Zeta, // cz'#10'  System.Classes,'#10'  Beta, {cb}'#10'  App.Core,'#10'  Alfa; // ca'#10'implementation'#10'uses Y, X;'#10'end.';
  O.Priorities := ['App.Core']; SetLength(O.Groups, 1);
  O.Groups[0].Name := 'System'; O.Groups[0].Selectors := ['System.*'];
  O.MaxLineWidth := 60;
  for Mask := 1 to 255 do
  begin
    O.Alphabetical := (Mask and 1) <> 0;
    O.PrioritiesEnabled := (Mask and 2) <> 0;
    O.GroupingEnabled := (Mask and 4) <> 0;
    O.OneUnitPerLine := (Mask and 8) <> 0;
    O.BlankLinesBetweenGroups := (Mask and 16) <> 0;
    O.IndentationEnabled := (Mask and 32) <> 0;
    O.WrapUnits := ((Mask and 64) <> 0) and not O.OneUnitPerLine;
    if (Mask and 128) <> 0 then O.ProtectedUnits := ['System.*'] else O.ProtectedUnits := nil;
    Actual := AnalyzeUses(S, O).ApplyTo(S);
    Check(Length(AnalyzeUses(Actual, O).Edits) = 0, 'Comment combination second run ' + IntToStr(Mask) + ': ' + Actual);
    Check(((Pos('Zeta, // cz'#10, Actual) > 0) or (Pos('Zeta; // cz'#10, Actual) > 0)) and
      ((Pos('Beta, {cb}'#10, Actual) > 0) or (Pos('Beta; {cb}'#10, Actual) > 0)) and
      ((Pos('Alfa, // ca'#10, Actual) > 0) or (Pos('Alfa; // ca'#10, Actual) > 0)),
      'Each comment on the line of its unit ' + IntToStr(Mask) + ': ' + Actual);
    R := ParseUses(Actual);
    Count := 0;
    for I := 0 to Integer(High(R.Clauses[0].Items)) do
      if R.Clauses[0].Items[I].Comment <> '' then Inc(Count);
    Check((Length(R.Clauses) = 2) and R.Clauses[0].CanOrganize and (Length(R.Clauses[0].Items) = 5) and (Count = 3),
      'Units and comments kept ' + IntToStr(Mask) + ': ' + Actual);
  end;
end;

// Every text exists in the five languages, with the same Format markers and
// the same blanks at the ends, so a translation cannot break a message.
procedure TestCatalog;
var Id: TStylerText; Language: TStylerLanguage; Reference, Text, Name: string;

  function Markers(const S: string): string;
  var P: Integer;
  begin
    Result := '';
    for P := 1 to Length(S) - 1 do
      if (S[P] = '%') and CharInSet(S[P + 1], ['s', 'd']) then Result := Result + S[P + 1];
  end;

begin
  for Id := Low(TStylerText) to High(TStylerText) do
  begin
    Reference := L(Id, slEnglish);
    for Language := Low(TStylerLanguage) to High(TStylerLanguage) do
    begin
      Text := L(Id, Language);
      Name := Format('text %d in %s', [Ord(Id), StylerLanguageCodes[Language]]);
      Check(Trim(Text) <> '', 'Not empty: ' + Name);
      Check(Markers(Text) = Markers(Reference), 'Same Format markers: ' + Name + ': ' + Text);
      Check((Text[1] = ' ') = (Reference[1] = ' '), 'Same leading blank: ' + Name);
      Check(Length(Text) < 2000, 'Reasonable size: ' + Name);
    end;
  end;
  // The choice kept in the settings: a known code, or the language of Windows.
  UseStylerLanguage('de');
  Check((StylerLanguage = slGerman) and (L(stCancel) = L(stCancel, slGerman)), 'Chosen language in use');
  UseStylerLanguage('FR');
  Check(StylerLanguage = slFrench, 'Code without regard to case');
  UseStylerLanguage('');
  Check(StylerLanguage = AutomaticLanguage, 'Empty follows Windows');
  UseStylerLanguage('xx');
  Check(StylerLanguage = AutomaticLanguage, 'Unknown code follows Windows');
  UseStylerLanguage('pt');
  Check(L(stErrWidthRange, [40, 500]) = 'O limite de colunas deve ficar entre 40 e 500.', 'Format through the catalog');
end;

begin
  try
    Checks := 0;
    TestCatalog;
    TestLineComments;
    TestLexer;
    TestParser;
    TestEngine;
    TestOrderingRules;
    TestCommentsAndExclusions;
    TestSectionSpacing;
    TestDirectives;
    TestWrap;
    TestMixedLineEndings;
    TestFirstNameSorting;
    TestProtectedUnits;
    Writeln('PASS: ', Checks, ' checks');
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
