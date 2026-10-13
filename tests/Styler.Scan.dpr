program StylerScan;

// Development tool: runs the engine over every .pas below a folder, entirely
// in memory. It never writes to the scanned sources; only the report is saved.

{$APPTYPE CONSOLE}

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Types, System.TypInfo,
  System.Diagnostics, System.Generics.Collections,
  CSCoder.Styler.Types in '..\src\core\CSCoder.Styler.Types.pas',
  CSCoder.Styler.Lexer in '..\src\core\CSCoder.Styler.Lexer.pas',
  CSCoder.Styler.UsesParser in '..\src\core\CSCoder.Styler.UsesParser.pas',
  CSCoder.Styler.Engine in '..\src\core\CSCoder.Styler.Engine.pas',
  CSCoder.Styler.Strings in '..\src\i18n\CSCoder.Styler.Strings.pas',
  CSCoder.Styler.UsesOrganizer in '..\src\core\CSCoder.Styler.UsesOrganizer.pas';

type
  TTally = record
    Files, NotUnit, NoUses, Changed, ChangedPartial, Clean, Preserved, Errors, Broken: Integer;
  end;

var
  Report: TStringList;
  CodeFiles: array[TDiagnosticCode] of Integer;
  Encodings, Newlines: TDictionary<string, Integer>;

procedure Bump(Map: TDictionary<string, Integer>; const Key: string);
var N: Integer;
begin
  if not Map.TryGetValue(Key, N) then N := 0;
  Map.AddOrSetValue(Key, N + 1);
end;

function ValidUtf8(const B: TBytes): Boolean;
var I, Need: Integer;
begin
  I := 0;
  while I < Length(B) do
  begin
    if B[I] < $80 then Need := 0
    else if (B[I] and $E0) = $C0 then Need := 1
    else if (B[I] and $F0) = $E0 then Need := 2
    else if (B[I] and $F8) = $F0 then Need := 3
    else Exit(False);
    Inc(I);
    while Need > 0 do
    begin
      if (I >= Length(B)) or ((B[I] and $C0) <> $80) then Exit(False);
      Inc(I); Dec(Need);
    end;
  end;
  Result := True;
end;

function Decode(const B: TBytes; out Kind: string): string;
var I: Integer; Ascii: Boolean;
begin
  if (Length(B) >= 3) and (B[0] = $EF) and (B[1] = $BB) and (B[2] = $BF) then
  begin Kind := 'UTF-8 com BOM'; Exit(TEncoding.UTF8.GetString(B, 3, Length(B) - 3)); end;
  if (Length(B) >= 2) and (B[0] = $FF) and (B[1] = $FE) then
  begin Kind := 'UTF-16 LE'; Exit(TEncoding.Unicode.GetString(B, 2, Length(B) - 2)); end;
  if (Length(B) >= 2) and (B[0] = $FE) and (B[1] = $FF) then
  begin Kind := 'UTF-16 BE'; Exit(TEncoding.BigEndianUnicode.GetString(B, 2, Length(B) - 2)); end;
  Ascii := True;
  for I := 0 to High(B) do
    if B[I] >= $80 then begin Ascii := False; Break; end;
  if Ascii then Kind := 'ASCII puro'
  else if ValidUtf8(B) then
  begin Kind := 'UTF-8 sem BOM'; Exit(TEncoding.UTF8.GetString(B)); end
  else Kind := 'ANSI';
  Result := TEncoding.ANSI.GetString(B);
end;

function NewlineKind(const S: string): string;
var I: Integer; CRLF, LF, CR: Boolean;
begin
  CRLF := False; LF := False; CR := False; I := 1;
  while I <= Length(S) do
  begin
    if S[I] = #13 then
    begin
      if (I < Length(S)) and (S[I + 1] = #10) then begin CRLF := True; Inc(I); end
      else CR := True;
    end
    else if S[I] = #10 then LF := True;
    Inc(I);
  end;
  if Ord(CRLF) + Ord(LF) + Ord(CR) > 1 then Result := 'misturadas'
  else if CRLF then Result := 'CRLF'
  else if LF then Result := 'LF'
  else if CR then Result := 'CR'
  else Result := 'sem quebra';
end;

function LineOf(const S: string; Offset: NativeInt): Integer;
var I: NativeInt;
begin
  Result := 1; I := 1;
  while (I <= Offset) and (I <= Length(S)) do
  begin
    if S[I] = #13 then
    begin
      Inc(Result);
      if (I < Length(S)) and (S[I + 1] = #10) then Inc(I);
    end
    else if S[I] = #10 then Inc(Result);
    Inc(I);
  end;
end;

// Every token except whitespace and separators, sorted: reordering keeps it equal.
function Content(const S: string): TArray<string>;
var T: TStylerToken; L: TList<string>;
begin
  L := TList<string>.Create;
  try
    for T in Tokenize(S) do
      if not (T.Kind in [tkWhitespace, tkComma, tkSemicolon]) then L.Add(T.Text);
    L.Sort;
    Result := L.ToArray;
  finally L.Free; end;
end;

function SectionUnits(const S: string): TArray<string>;
var C: TUsesClause; Item: TUsesItem; L: TList<string>;
begin
  L := TList<string>.Create;
  try
    for C in ParseUses(S).Clauses do
      for Item in C.Items do L.Add(IntToStr(Ord(C.Section)) + ':' + LowerCase(Item.Declaration));
    L.Sort;
    Result := L.ToArray;
  finally L.Free; end;
end;

// Each end-of-line comment with the unit it was written beside.
function UnitComments(const S: string): TArray<string>;
var C: TUsesClause; Item: TUsesItem; L: TList<string>;
begin
  L := TList<string>.Create;
  try
    for C in ParseUses(S).Clauses do
      for Item in C.Items do
        if Item.Comment <> '' then L.Add(IntToStr(Ord(C.Section)) + ':' + LowerCase(Item.Name) + #1 + Item.Comment);
    L.Sort;
    Result := L.ToArray;
  finally L.Free; end;
end;

function SameList(const A, B: TArray<string>): Boolean;
var I: Integer;
begin
  if Length(A) <> Length(B) then Exit(False);
  for I := 0 to High(A) do
    if A[I] <> B[I] then Exit(False);
  Result := True;
end;

// Both lists sorted: every entry of Part is found in Whole.
function Contains(const Whole, Part: TArray<string>): Boolean;
var I, J: Integer;
begin
  J := 0;
  for I := 0 to High(Part) do
  begin
    while (J < Length(Whole)) and (Whole[J] <> Part[I]) do Inc(J);
    if J >= Length(Whole) then Exit(False);
    Inc(J);
  end;
  Result := True;
end;

function SeparatorCount(const S: string): Integer;
var T: TStylerToken;
begin
  Result := 0;
  for T in Tokenize(S) do
    if T.Kind in [tkComma, tkSemicolon] then Inc(Result);
end;

// Each directive with the tokens right before and after it, in source order.
// Equal lists mean no directive moved, lost its comma or met the terminator.
function DirectiveContext(const S: string): TArray<string>;
var Tokens: TStylerTokens; I, J: NativeInt; Before, After: string; L: TList<string>;

  // Which free unit sits next to a block may change; punctuation may not.
  function Neighbor(Index: NativeInt): string;
  begin
    if Tokens[Index].Kind = tkIdentifier then Result := 'nome' else Result := Tokens[Index].Text;
  end;

begin
  Tokens := Tokenize(S);
  L := TList<string>.Create;
  try
    for I := 0 to High(Tokens) do
    begin
      if Tokens[I].Kind <> tkDirective then Continue;
      Before := ''; After := '';
      J := I - 1;
      while (J >= 0) and (Tokens[J].Kind = tkWhitespace) do Dec(J);
      if J >= 0 then Before := Neighbor(J);
      J := I + 1;
      while (J < Length(Tokens)) and (Tokens[J].Kind = tkWhitespace) do Inc(J);
      if J < Length(Tokens) then After := Neighbor(J);
      L.Add(Before + #1 + Tokens[I].Text + #1 + After);
    end;
    Result := L.ToArray;
  finally L.Free; end;
end;

// Structural safety of one proposal; empty result means every check passed.
function Verify(const Source: string; const Options: TUsesOptions;
  const Proposal: TStylerProposal): string;
var Output: string;
begin
  Result := '';
  Output := Proposal.ApplyTo(Source);
  if not SameList(Content(Source), Content(Output)) then Exit('conteudo fora de espacos mudou');
  if not SameList(DirectiveContext(Source), DirectiveContext(Output)) then Exit('vizinhanca de uma diretiva mudou');
  if SeparatorCount(Source) <> SeparatorCount(Output) then Exit('quantidade de virgulas/ponto e virgula mudou');
  if not SameList(SectionUnits(Source), SectionUnits(Output)) then Exit('units de uma secao mudaram');
  // A comment left after the semicolon may end up beside the last unit and
  // count as its own from then on; one that had a unit must still be with it.
  if not Contains(UnitComments(Output), UnitComments(Source)) then Exit('comentario de fim de linha separado da sua unit');
  if Length(AnalyzeUses(Output, Options).Edits) <> 0 then Exit('segunda execucao ainda propoe mudancas');
end;

function StressOptions: TUsesOptions;
begin
  Result := Default(TUsesOptions);
  Result.Alphabetical := True; Result.OneUnitPerLine := True;
  Result.IndentationEnabled := True; Result.Indentation := '  ';
  Result.PrioritiesEnabled := True; Result.Priorities := ['Winapi.Windows', 'System.SysUtils'];
  Result.GroupingEnabled := True; Result.BlankLinesBetweenGroups := True;
  SetLength(Result.Groups, 4);
  Result.Groups[0].Name := 'Winapi'; Result.Groups[0].Selectors := ['Winapi.*'];
  Result.Groups[1].Name := 'System'; Result.Groups[1].Selectors := ['System.*'];
  Result.Groups[2].Name := 'Data'; Result.Groups[2].Selectors := ['Data.*', 'FireDAC.*'];
  Result.Groups[3].Name := 'UI'; Result.Groups[3].Selectors := ['Vcl.*', 'FMX.*'];
  Result.BlankBeforeSections := True; Result.BlankAfterSections := True;
end;

// Several units per line: plain, and with priorities and groups starting lines.
function WrapOptions(Grouped: Boolean): TUsesOptions;
begin
  if Grouped then Result := StressOptions else Result := Default(TUsesOptions);
  Result.Alphabetical := True; Result.OneUnitPerLine := False;
  Result.WrapUnits := True; Result.MaxLineWidth := 80;
  Result.IndentationEnabled := True; Result.Indentation := '  ';
end;

procedure ScanFile(const Root, FileName: string; const Options: TUsesOptions; var Tally: TTally);
var Source, Kind, Relative, Problem, Codes: string; Proposal: TStylerProposal;
  Parsed: TUsesParseResult; D: TStylerDiagnostic; Seen: set of TDiagnosticCode;
  Code: TDiagnosticCode; FirstLine: Integer; First: TUsesOptions;
begin
  Inc(Tally.Files);
  Relative := Copy(FileName, Length(Root) + 2, MaxInt);
  try
    Source := Decode(TFile.ReadAllBytes(FileName), Kind);
    Bump(Encodings, Kind); Bump(Newlines, NewlineKind(Source));
    Parsed := ParseUses(Source);
    if Length(Parsed.Headers) = 0 then
    begin Inc(Tally.NotUnit); Report.Add('NAO-UNIT   | ' + Relative); Exit; end;
    Proposal := AnalyzeUses(Source, Options);
    Problem := Verify(Source, Options, Proposal);
    if Problem = '' then
      Problem := Verify(Source, StressOptions, AnalyzeUses(Source, StressOptions));
    if Problem = '' then
      Problem := Verify(Source, WrapOptions(False), AnalyzeUses(Source, WrapOptions(False)));
    if Problem = '' then
      Problem := Verify(Source, WrapOptions(True), AnalyzeUses(Source, WrapOptions(True)));
    if Problem = '' then
    begin
      // A to Z by the first name only.
      First := Options; First.SortFirstNameOnly := True;
      Problem := Verify(Source, First, AnalyzeUses(Source, First));
    end;
    if Problem = '' then
    begin
      // The factory list of protected units, with the full sort.
      First := Options;
      First.ProtectedUnits := ['Winapi.*', 'System.*', 'Vcl.*', 'FMX.*', 'Data.*',
        'Windows', 'Messages', 'SysUtils', 'Classes', 'Variants', 'Graphics', 'Controls', 'Forms', 'Dialogs', 'DB'];
      Problem := Verify(Source, First, AnalyzeUses(Source, First));
    end;
    if Problem <> '' then
    begin Inc(Tally.Broken); Report.Add('FALHA      | ' + Relative + ' | ' + Problem); end;
    Seen := []; Codes := ''; FirstLine := 0;
    for D in Proposal.Diagnostics do
    begin
      if FirstLine = 0 then FirstLine := LineOf(Source, D.Range.Start);
      if not (D.Code in Seen) then
      begin
        Include(Seen, D.Code);
        Codes := Codes + ' ' + GetEnumName(TypeInfo(TDiagnosticCode), Ord(D.Code));
      end;
    end;
    for Code in Seen do Inc(CodeFiles[Code]);
    if Length(Proposal.Edits) > 0 then
    begin
      Inc(Tally.Changed);
      if Seen <> [] then
      begin
        Inc(Tally.ChangedPartial);
        Report.Add(Format('PARCIAL    | %s | linha %d |%s', [Relative, FirstLine, Codes]));
      end;
    end
    else if Seen <> [] then
    begin
      Inc(Tally.Preserved);
      Report.Add(Format('PRESERVADA | %s | linha %d |%s', [Relative, FirstLine, Codes]));
    end
    else if Length(Parsed.Clauses) = 0 then Inc(Tally.NoUses)
    else Inc(Tally.Clean);
  except
    on E: Exception do
    begin
      Inc(Tally.Errors);
      Report.Add('ERRO       | ' + Relative + ' | ' + E.ClassName + ': ' + E.Message);
    end;
  end;
end;

procedure Print(const Name: string; const T: TTally);
begin
  Writeln(Format('%-40s %5d %7d %8d %7d %9d %8d %5d %5d', [Copy(Name, 1, 40), T.Files,
    T.Changed, T.ChangedPartial, T.Clean, T.Preserved, T.NoUses + T.NotUnit, T.Errors, T.Broken]));
end;

var
  Root, ProjectDir, FileName, Key: string; Options: TUsesOptions; Tally, Total: TTally;
  Code: TDiagnosticCode; Watch: TStopwatch;
begin
  if ParamCount < 2 then
  begin Writeln('Uso: Styler.Scan <pasta> <relatorio.txt>'); Halt(2); end;
  Root := ExcludeTrailingPathDelimiter(ExpandFileName(ParamStr(1)));
  Options := Default(TUsesOptions);
  Options.Alphabetical := True; Options.OneUnitPerLine := True;
  Options.IndentationEnabled := True; Options.Indentation := '  ';
  Report := TStringList.Create;
  Encodings := TDictionary<string, Integer>.Create;
  Newlines := TDictionary<string, Integer>.Create;
  try
    Total := Default(TTally);
    Watch := TStopwatch.StartNew;
    Writeln(Format('%-40s %5s %7s %8s %7s %9s %8s %5s %5s', ['Projeto', 'units', 'mudam',
      '(parcial)', 'ja ok', 'preserv.', 'sem uses', 'erro', 'falha']));
    for ProjectDir in TDirectory.GetDirectories(Root) do
    begin
      Tally := Default(TTally);
      Report.Add('=== ' + ExtractFileName(ProjectDir));
      for FileName in TDirectory.GetFiles(ProjectDir, '*.pas', TSearchOption.soAllDirectories) do
        ScanFile(Root, FileName, Options, Tally);
      Print(ExtractFileName(ProjectDir), Tally);
      Inc(Total.Files, Tally.Files); Inc(Total.NotUnit, Tally.NotUnit); Inc(Total.NoUses, Tally.NoUses);
      Inc(Total.Changed, Tally.Changed); Inc(Total.ChangedPartial, Tally.ChangedPartial);
      Inc(Total.Clean, Tally.Clean); Inc(Total.Preserved, Tally.Preserved);
      Inc(Total.Errors, Tally.Errors); Inc(Total.Broken, Tally.Broken);
    end;
    Print('TOTAL', Total);
    Writeln(Format('Tempo: %d ms', [Watch.ElapsedMilliseconds]));
    Writeln('Units por motivo de aviso:');
    for Code := Low(TDiagnosticCode) to High(TDiagnosticCode) do
      if CodeFiles[Code] > 0 then
        Writeln(Format('  %-28s %d', [GetEnumName(TypeInfo(TDiagnosticCode), Ord(Code)), CodeFiles[Code]]));
    Writeln('Codificacao:');
    for Key in Encodings.Keys do Writeln(Format('  %-16s %d', [Key, Encodings[Key]]));
    Writeln('Quebras de linha:');
    for Key in Newlines.Keys do Writeln(Format('  %-16s %d', [Key, Newlines[Key]]));
    Report.SaveToFile(ParamStr(2), TEncoding.UTF8);
  finally
    Newlines.Free; Encodings.Free; Report.Free;
  end;
end.
