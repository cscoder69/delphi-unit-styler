unit CSCoder.Styler.Engine;

interface

uses CSCoder.Styler.Types;

function AnalyzeUses(const Source: string; const Options: TUsesOptions): TStylerProposal;

implementation

uses System.SysUtils, CSCoder.Styler.Lexer, CSCoder.Styler.UsesParser,
  CSCoder.Styler.UsesOrganizer;

function NewlineOf(const Source: string; out Mixed: Boolean): string;
var P: NativeInt; Current: string;
begin
  Result := '';
  Mixed := False;
  P := 1;
  while P <= Length(Source) do
  begin
    Current := '';
    if Source[P] = #13 then
    begin
      Current := #13;
      if (P < Length(Source)) and (Source[P + 1] = #10) then
      begin Current := #13#10; Inc(P); end;
    end
    else if Source[P] = #10 then Current := #10;
    if Current <> '' then
    begin
      if Result = '' then Result := Current
      else if Result <> Current then Mixed := True;
    end;
    Inc(P);
  end;
  // A source without line breaks needs a convention only when adding a line.
  if Result = '' then Result := #13#10;
end;

// Line break in use around Offset: the nearest one before it, or after it.
function NewlineNear(const Source: string; Offset: NativeInt): string;
var P: NativeInt;

  function BreakAt(Index: NativeInt): string;
  begin
    if Source[Index] = #10 then
    begin
      if (Index > 1) and (Source[Index - 1] = #13) then Result := #13#10 else Result := #10;
    end
    else if (Index < Length(Source)) and (Source[Index + 1] = #10) then Result := #13#10
    else Result := #13;
  end;

begin
  P := Offset;
  if P > Length(Source) then P := Length(Source);
  while P >= 1 do
  begin
    if CharInSet(Source[P], [#10, #13]) then Exit(BreakAt(P));
    Dec(P);
  end;
  P := Offset + 1;
  while P <= Length(Source) do
  begin
    if CharInSet(Source[P], [#10, #13]) then Exit(BreakAt(P));
    Inc(P);
  end;
  Result := #13#10;
end;

function ExistingIndent(const Source: string; Offset: NativeInt): string;
var P: NativeInt;
begin
  P := Offset;
  while (P > 0) and CharInSet(Source[P], [' ', #9]) do Dec(P);
  if (P = 0) or CharInSet(Source[P], [#10, #13]) then
    Result := Copy(Source, P + 1, Offset - P)
  else Result := '';
end;

// Characters already on the last line of Text.
function ColumnOf(const Text: string): NativeInt;
var P: NativeInt;
begin
  P := Length(Text);
  while (P > 0) and not CharInSet(Text[P], [#10, #13]) do Dec(P);
  Result := Length(Text) - P;
end;

// End of what belongs to a unit in the source: its separator, or the
// end-of-line comment written after it.
function TailOf(const Item: TUsesItem): NativeInt;
begin
  if Item.Comment <> '' then Result := Item.CommentEnd else Result := Item.SeparatorEnd;
end;

function TrimLeftBlanks(const Text: string): string;
var P: NativeInt;
begin
  P := 1;
  while (P <= Length(Text)) and CharInSet(Text[P], [' ', #9]) do Inc(P);
  Result := Copy(Text, P, MaxInt);
end;

function TrimRightBlanks(const Text: string): string;
var P: NativeInt;
begin
  P := Length(Text);
  while (P > 0) and CharInSet(Text[P], [' ', #9]) do Dec(P);
  Result := Copy(Text, 1, P);
end;

function StartsWithBreak(const Text: string): Boolean;
var Rest: string;
begin
  Rest := TrimLeftBlanks(Text);
  Result := (Rest <> '') and CharInSet(Rest[1], [#10, #13]);
end;

function EndsAtLineStart(const Text: string): Boolean;
var Rest: string;
begin
  Rest := TrimRightBlanks(Text);
  Result := (Rest <> '') and CharInSet(Rest[Length(Rest)], [#10, #13]);
end;

function WithBlankLine(const Whitespace, Newline: string): string;
var I, Count: NativeInt; Own: string; Ignored: Boolean;
begin
  // A gap that already has a line break grows with breaks of its own kind.
  Own := Newline;
  if (Pos(#10, Whitespace) > 0) or (Pos(#13, Whitespace) > 0) then Own := NewlineOf(Whitespace, Ignored);
  Count := 0; I := 1;
  while I <= Length(Whitespace) do
  begin
    if Whitespace[I] = #13 then
    begin
      Inc(Count);
      if (I < Length(Whitespace)) and (Whitespace[I + 1] = #10) then Inc(I);
    end
    else if Whitespace[I] = #10 then Inc(Count);
    Inc(I);
  end;
  Result := Whitespace;
  while Count < 2 do
  begin Result := Own + Result; Inc(Count); end;
end;

procedure AddSectionSpacing(const Source, Newline: string; Mixed: Boolean;
  const Parsed: TUsesParseResult; const Options: TUsesOptions; var Proposal: TStylerProposal);
var Tokens: TStylerTokens; Header: TSectionHeader; Clause: TUsesClause;
  I, J, Last, P, GapIndex, Neighbor: NativeInt; Edit, Swap: TSourceEdit;
  GapRange: TSourceRange; Gap, Replacement, Local: string;
  ChangedEdits: TArray<TSourceEdit>;

  procedure Preserved(const Range: TSourceRange);
  var D: TStylerDiagnostic;
  begin
    D.Code := dcSectionSpacingPreserved; D.Range := Range;
    Proposal.Diagnostics := Proposal.Diagnostics + [D];
  end;

  procedure AddGap(Before: Boolean);
  var K: NativeInt; LocalClause: TUsesClause;
  begin
    // The gap after uses lies inside the clause: keep it when the clause is
    // preserved (directives) or starts with an excluded unit.
    if not Before and (Header.Kind = shUses) then
      for LocalClause in Parsed.Clauses do
        if (LocalClause.Range.Start = Header.Range.Start) and
          (not LocalClause.CanOrganize or ((Length(LocalClause.Items) > 0) and
          (LocalClause.Items[0].Fixed or IsExcludedUnit(LocalClause.Items[0].Name, Options)))) then
        begin Preserved(Header.Range); Exit; end;
    // Spacing after uses belongs inside an existing uses replacement. Decide
    // from the rendered clause: sorting may move a comment to or from the top.
    if not Before and (Header.Kind = shUses) then
      for K := 0 to High(Proposal.Edits) do
        if (Proposal.Edits[K].Range.Start = Header.Range.Start) and
          (Proposal.Edits[K].Range.Length >= Header.Range.Length) then
        begin
          P := 5;
          while (P <= Length(Proposal.Edits[K].ReplacementText)) and
            CharInSet(Proposal.Edits[K].ReplacementText[P], [' ', #9, #10, #13]) do Inc(P);
          Gap := Copy(Proposal.Edits[K].ReplacementText, P, 2);
          if (Gap = '//') or (Gap = '(*') or (Copy(Gap, 1, 1) = '{') then
          begin Preserved(Header.Range); Exit; end;
          Gap := Copy(Proposal.Edits[K].ReplacementText, 5, P - 5);
          Delete(Proposal.Edits[K].ReplacementText, 5, P - 5);
          Insert(WithBlankLine(Gap, Local), Proposal.Edits[K].ReplacementText, 5);
          Exit;
        end;
    if Before then GapIndex := I - 1 else GapIndex := I + 1;
    Neighbor := GapIndex;
    if (GapIndex >= 0) and (GapIndex < Length(Tokens)) and
      (Tokens[GapIndex].Kind = tkWhitespace) then
    begin
      GapRange := Tokens[GapIndex].Range;
      if Before then Dec(Neighbor) else Inc(Neighbor);
    end
    else if Before then GapRange := TSourceRange.Create(Header.Range.Start, 0)
    else GapRange := TSourceRange.Create(Header.Range.EndOffset, 0);
    // Keep comments adjacent to their original section/unit, including // headers.
    if (Neighbor >= 0) and (Neighbor < Length(Tokens)) and
      (Tokens[Neighbor].Kind = tkComment) then
    begin Preserved(Header.Range); Exit; end;
    Gap := Copy(Source, GapRange.Start + 1, GapRange.Length);
    Replacement := WithBlankLine(Gap, Local);
    // Before the next header and after the previous one may share the same gap.
    for K := 0 to High(Proposal.Edits) do
      if (Proposal.Edits[K].Range.Start = GapRange.Start) and
        (Proposal.Edits[K].Range.Length = GapRange.Length) then Exit;
    if Gap = Replacement then Exit;
    Edit.Range := GapRange; Edit.Section := Header.Section;
    Edit.ExpectedText := Gap; Edit.ReplacementText := Replacement;
    Proposal.Edits := Proposal.Edits + [Edit];
  end;

begin
  if not (Options.BlankBeforeSections or Options.BlankAfterSections) then Exit;
  Tokens := Tokenize(Source);
  if (Length(Parsed.Headers) = 0) or (Length(Parsed.Diagnostics) > 0) then
  begin Preserved(TSourceRange.Create(0, Length(Source))); Exit; end;
  for I := 0 to High(Tokens) do
    if Tokens[I].Kind = tkInvalid then
    begin Preserved(Tokens[I].Range); Exit; end;
  // A clause kept only because of directives does not make the unit uncertain;
  // any other unsafe clause still protects the spacing of the whole file.
  for Clause in Parsed.Clauses do
    if not Clause.CanOrganize then
      for J := 0 to High(Clause.Diagnostics) do
        if Clause.Diagnostics[J].Code <> dcDirectiveBarrier then
        begin Preserved(Clause.Range); Exit; end;
  Last := High(Tokens);
  while (Last >= 0) and (Tokens[Last].Kind in [tkWhitespace, tkComment]) do Dec(Last);
  if (Last < 1) or (Tokens[Last].Kind <> tkDot) then
  begin Preserved(TSourceRange.Create(0, Length(Source))); Exit; end;
  Dec(Last);
  while (Last >= 0) and (Tokens[Last].Kind in [tkWhitespace, tkComment]) do Dec(Last);
  if (Last < 0) or not SameText(Tokens[Last].Text, 'end') then
  begin Preserved(TSourceRange.Create(0, Length(Source))); Exit; end;
  J := 0;
  for Header in Parsed.Headers do if Header.Kind = shImplementation then Inc(J);
  if J <> 1 then
  begin Preserved(TSourceRange.Create(0, Length(Source))); Exit; end;
  for Header in Parsed.Headers do
  begin
    if Header.Section in Options.ExcludedSections then Continue;
    if Header.Conditional then
    begin Preserved(Header.Range); Continue; end;
    I := 0;
    while (I < Length(Tokens)) and (Tokens[I].Range.Start <> Header.Range.Start) do Inc(I);
    if I >= Length(Tokens) then Continue;
    // A file with mixed line endings gets, at each header, the kind used there.
    if Mixed then Local := NewlineNear(Source, Header.Range.Start) else Local := Newline;
    if Options.BlankBeforeSections then AddGap(True);
    if Options.BlankAfterSections then AddGap(False);
  end;
  // Merge all independent gaps with uses edits in original-snapshot order.
  ChangedEdits := nil;
  for I := 0 to High(Proposal.Edits) do
    if Proposal.Edits[I].ExpectedText <> Proposal.Edits[I].ReplacementText then
      ChangedEdits := ChangedEdits + [Proposal.Edits[I]];
  Proposal.Edits := ChangedEdits;
  for I := 1 to High(Proposal.Edits) do
  begin
    J := I;
    while J > 0 do
    begin
      if (Proposal.Edits[J - 1].Range.Start < Proposal.Edits[J].Range.Start) or
        ((Proposal.Edits[J - 1].Range.Start = Proposal.Edits[J].Range.Start) and
        (Proposal.Edits[J - 1].Range.Length <= Proposal.Edits[J].Range.Length)) then Break;
      Swap := Proposal.Edits[J - 1]; Proposal.Edits[J - 1] := Proposal.Edits[J];
      Proposal.Edits[J] := Swap; Dec(J);
    end;
  end;
end;

function AnalyzeUses(const Source: string; const Options: TUsesOptions): TStylerProposal;
var
  Parsed: TUsesParseResult;
  Clause: TUsesClause;
  Items: TArray<TOrderedUsesItem>;
  Edit: TSourceEdit;
  I, J, GapStart, GapEnd, EditEnd, P: NativeInt;
  Text, Gap, Separator, Indent, Newline, FileNewline: string;
  Mixed, ClauseMixed, HasExclusions, OrderChanged, OwnLines: Boolean;
begin
  Result := Default(TStylerProposal);
  Result.SourceSnapshot := Source;
  if not Options.HasTransformations then Exit;
  ValidateUsesOptions(Options);
  Parsed := ParseUses(Source);
  Result.Diagnostics := Parsed.Diagnostics;
  FileNewline := NewlineOf(Source, Mixed);
  for Clause in Parsed.Clauses do
  begin
    if Clause.Section in Options.ExcludedSections then Continue;
    Result.Diagnostics := Result.Diagnostics + Clause.Diagnostics;
    if not Clause.CanOrganize then Continue;
    // In a file with mixed line endings the clause is written with its own
    // kind. Only a clause that mixes them inside itself is left as it is.
    Newline := FileNewline;
    if Mixed then
    begin
      Newline := NewlineOf(Copy(Source, Clause.Range.Start + 1, Clause.Range.Length), ClauseMixed);
      if ClauseMixed then
      begin
        SetLength(Result.Diagnostics, Length(Result.Diagnostics) + 1);
        Result.Diagnostics[High(Result.Diagnostics)].Code := dcUnsupportedStructure;
        Result.Diagnostics[High(Result.Diagnostics)].Range := Clause.Range;
        Continue;
      end;
      if Pos(#10, Copy(Source, Clause.Range.Start + 1, Clause.Range.Length)) +
        Pos(#13, Copy(Source, Clause.Range.Start + 1, Clause.Range.Length)) = 0 then
        Newline := NewlineNear(Source, Clause.Range.Start);
    end;
    Items := OrderUses(Clause.Items, Options);
    HasExclusions := False;
    OrderChanged := False;
    for I := 0 to High(Items) do
    begin
      HasExclusions := HasExclusions or Items[I].Excluded;
      OrderChanged := OrderChanged or (Items[I].Item.Range.Start <> Clause.Items[I].Range.Start);
      // A unit pinned by a directive is normal handling, not something to report.
      // Nor is a unit protected by the rules of the add-on: only what the project preserves.
      if Items[I].Excluded and not Items[I].Item.Fixed and IsProjectExcludedUnit(Items[I].Item.Name, Options) then
      begin
        SetLength(Result.Diagnostics, Length(Result.Diagnostics) + 1);
        Result.Diagnostics[High(Result.Diagnostics)].Code := dcExcludedUnitBarrier;
        Result.Diagnostics[High(Result.Diagnostics)].Range := Items[I].Item.Range;
      end;
    end;
    // Both layouts decide every line break between free units themselves.
    OwnLines := Options.OneUnitPerLine or Options.WrapUnits;
    if not OrderChanged and not OwnLines and not Options.IndentationEnabled and
      not (Options.GroupingEnabled and Options.BlankLinesBetweenGroups) then Continue;
    Indent := ExistingIndent(Source, Clause.Items[0].Range.Start);
    if Options.IndentationEnabled then Indent := Options.Indentation;
    // The keyword and any comments before the first unit always stay on top.
    Text := Copy(Source, Clause.Range.Start + 1, Clause.HeaderEnd - Clause.Range.Start);
    if OwnLines and not Items[0].Excluded then Text := Text + Newline + Indent
    else Text := Text + Copy(Source, Clause.HeaderEnd + 1,
      Clause.Items[0].Range.Start - Clause.HeaderEnd);
    for I := 0 to High(Items) do
    begin
      Text := Text + Items[I].Item.Declaration;
      if I < High(Items) then
      begin
        // What the source has at this position, without the end-of-line comment
        // of the unit that was here: up to the comma, and from there to the next unit.
        GapStart := Clause.Items[I].Range.EndOffset;
        Separator := Copy(Source, GapStart + 1, Clause.Items[I].SeparatorEnd - GapStart);
        GapStart := TailOf(Clause.Items[I]);
        GapEnd := Clause.Items[I + 1].Range.Start;
        Gap := Copy(Source, GapStart + 1, GapEnd - GapStart);
        if Items[I].Excluded or Items[I + 1].Excluded then
        begin
          // After a directive block the next free unit starts its own line:
          // align only that line start, leaving the block itself untouched.
          if Options.IndentationEnabled and Items[I].Item.Fixed and not Items[I + 1].Excluded then
          begin
            P := Length(Gap);
            while (P > 0) and CharInSet(Gap[P], [' ', #9]) do Dec(P);
            if (P > 0) and CharInSet(Gap[P], [#10, #13]) then Gap := Copy(Gap, 1, P) + Indent;
          end;
        end
        else if Options.GroupingEnabled and Options.BlankLinesBetweenGroups and
          (Items[I].Segment = Items[I + 1].Segment) and
          (Items[I].Block <> Items[I + 1].Block) then
        begin Separator := ','; Gap := Newline + Newline + Indent; end
        else if Options.OneUnitPerLine then
        begin Separator := ','; Gap := Newline + Indent; end
        else if Options.WrapUnits then
        begin
          // A new line for each priority block or group, and whenever the next
          // unit, with its comma or semicolon, would pass the width limit.
          Separator := ',';
          if (Items[I].Block <> Items[I + 1].Block) or
            (ColumnOf(Text) + 2 + Length(Items[I + 1].Item.Declaration) + 1 > Options.MaxLineWidth) then
            Gap := Newline + Indent
          else Gap := ' ';
        end;
        // A unit with an end-of-line comment gets a line of its own: the
        // comment ends the line, and nothing else comes before the unit on it.
        // One that keeps its place keeps the text the source has around it.
        if (Items[I].Item.Comment <> '') and not Items[I].Excluded and not StartsWithBreak(Gap) then
          Gap := Newline + Indent + TrimLeftBlanks(Gap);
        if (Items[I + 1].Item.Comment <> '') and not Items[I + 1].Excluded and not EndsAtLineStart(Gap) then
          Gap := TrimRightBlanks(Gap) + Newline + Indent;
        Text := Text + Separator + Items[I].Item.Comment + Gap;
      end;
    end;
    // The semicolon, then the comment of the unit that ended up last. The
    // comment the source has after the semicolon went with its own unit.
    GapStart := Clause.Items[High(Clause.Items)].Range.EndOffset;
    Text := Text + Copy(Source, GapStart + 1, Clause.Range.EndOffset - GapStart) + Items[High(Items)].Item.Comment;
    EditEnd := TailOf(Clause.Items[High(Clause.Items)]);
    if (Items[High(Items)].Item.Comment <> '') and not StartsWithBreak(Copy(Source, EditEnd + 1, MaxInt)) and
      (EditEnd < Length(Source)) then Text := Text + Newline;
    if Options.IndentationEnabled and not OwnLines and not HasExclusions then
    begin
      // Replace only leading whitespace after existing line breaks.
      P := 1;
      while P <= Length(Text) do
      begin
        if CharInSet(Text[P], [#10, #13]) then
        begin
          if (Text[P] = #13) and (P < Length(Text)) and (Text[P + 1] = #10) then Inc(P);
          Inc(P);
          J := P;
          while (J <= Length(Text)) and CharInSet(Text[J], [' ', #9]) do Inc(J);
          if (J <= Length(Text)) and not CharInSet(Text[J], [#10, #13]) then
          begin
            Delete(Text, P, J - P);
            Insert(Options.Indentation, Text, P);
            Inc(P, Length(Options.Indentation));
          end;
        end
        else Inc(P);
      end;
    end;
    Edit.Range := TSourceRange.Create(Clause.Range.Start, EditEnd - Clause.Range.Start);
    Edit.Section := Clause.Section;
    Edit.ExpectedText := Copy(Source, Edit.Range.Start + 1, Edit.Range.Length);
    Edit.ReplacementText := Text;
    if Edit.ExpectedText <> Edit.ReplacementText then Result.Edits := Result.Edits + [Edit];
  end;
  AddSectionSpacing(Source, FileNewline, Mixed, Parsed, Options, Result);
end;

end.
