unit CSCoder.Styler.UsesParser;

interface

uses CSCoder.Styler.Types;

function ParseUses(const Source: string): TUsesParseResult;

implementation

uses System.SysUtils, System.Generics.Collections, CSCoder.Styler.Lexer;

function IsWord(const Token: TStylerToken; const Word: string): Boolean;
begin
  // Escaped identifiers such as &implementation are never section keywords.
  Result := (Token.Kind = tkIdentifier) and SameText(Token.Text, Word);
end;

function NextSignificant(const Tokens: TStylerTokens; Index: NativeInt): NativeInt;
begin
  Result := Index;
  while (Result < Length(Tokens)) and
    (Tokens[Result].Kind in [tkWhitespace, tkComment, tkDirective]) do Inc(Result);
end;

// +1 opens a conditional compilation block, -1 closes one. Other directives,
// including $ELSE, $R, $I and switches, do not change the nesting depth.
function ConditionalDelta(const Token: TStylerToken): NativeInt;
var P, First: NativeInt; Name: string;
begin
  Result := 0;
  if Token.Kind <> tkDirective then Exit;
  P := Pos('$', Token.Text) + 1;
  First := P;
  while (P <= Length(Token.Text)) and
    CharInSet(Token.Text[P], ['A'..'Z', 'a'..'z']) do Inc(P);
  Name := UpperCase(Copy(Token.Text, First, P - First));
  if (Name = 'IFDEF') or (Name = 'IFNDEF') or (Name = 'IF') or (Name = 'IFOPT') then Result := 1
  else if (Name = 'ENDIF') or (Name = 'IFEND') then Result := -1;
end;

procedure AddDiagnostic(var Diagnostics: TArray<TStylerDiagnostic>;
  Code: TDiagnosticCode; const Range: TSourceRange);
var D: TStylerDiagnostic;
begin
  D.Code := Code;
  D.Range := Range;
  Diagnostics := Diagnostics + [D];
end;

function HasLineBreak(const Text: string): Boolean;
begin
  Result := (Pos(#10, Text) > 0) or (Pos(#13, Text) > 0);
end;

// Comments before the first unit belong to the top of the clause and stay
// there. A comment at the end of the line of a unit, after its separator,
// belongs to that unit. Any other comment keeps the whole clause untouched.
// EndTokens and SeparatorTokens: token of the last part and of the separator
// of each unit.
procedure ClassifyComments(const Source: string; const Tokens: TStylerTokens; First, Last: NativeInt;
  const EndTokens, SeparatorTokens: TArray<NativeInt>; var Clause: TUsesClause);
var I, K, Owner, Limit: NativeInt;

  // The unit whose separator is followed, on that same line, by the comment
  // at Index and by nothing else.
  function OwnerOf(Index: NativeInt): NativeInt;
  var Item, S, T: NativeInt;
  begin
    Result := -1;
    if HasLineBreak(Tokens[Index].Text) then Exit;
    if (Index + 1 < Length(Tokens)) and not ((Tokens[Index + 1].Kind = tkWhitespace) and
      HasLineBreak(Tokens[Index + 1].Text)) then Exit;
    for Item := 0 to High(Clause.Items) do
    begin
      S := SeparatorTokens[Item];
      if (S < 0) or (S >= Index) or (Index - S > 2) then Continue;
      if (Index - S = 2) and not ((Tokens[S + 1].Kind = tkWhitespace) and
        not HasLineBreak(Tokens[S + 1].Text)) then Exit;
      for T := EndTokens[Item] + 1 to S - 1 do
        if (Tokens[T].Kind <> tkWhitespace) or HasLineBreak(Tokens[T].Text) then Exit;
      // After the semicolon of a clause with several units on its last line
      // the comment speaks of the clause, not of the last unit.
      if (Tokens[S].Kind = tkSemicolon) and (Item > 0) and
        not HasLineBreak(Copy(Source, Clause.Items[Item - 1].Range.EndOffset + 1,
        Clause.Items[Item].Range.Start - Clause.Items[Item - 1].Range.EndOffset)) then Exit;
      Exit(Item);
    end;
  end;

begin
  if Length(Clause.Items) = 0 then Exit;
  // The comment of the last unit comes after the semicolon, outside the clause.
  Limit := Last;
  K := Last + 1;
  if (K < Length(Tokens)) and (Tokens[K].Kind = tkWhitespace) then Inc(K);
  if (K < Length(Tokens)) and (Tokens[K].Kind = tkComment) then Limit := K;
  for I := First + 1 to Limit do
  begin
    if Tokens[I].Kind <> tkComment then Continue;
    if Tokens[I].Range.EndOffset <= Clause.Items[0].Range.Start then
    begin Clause.HeaderEnd := Tokens[I].Range.EndOffset; Continue; end;
    Owner := OwnerOf(I);
    if Owner >= 0 then
    begin
      Clause.Items[Owner].Comment := Copy(Source, Clause.Items[Owner].SeparatorEnd + 1,
        Tokens[I].Range.EndOffset - Clause.Items[Owner].SeparatorEnd);
      Clause.Items[Owner].CommentEnd := Tokens[I].Range.EndOffset;
    end
    // After the semicolon a comment that belongs to no unit just stays there.
    else if I < Last then AddDiagnostic(Clause.Diagnostics, dcCommentAssociation, Tokens[I].Range);
  end;
end;

function ReadClause(const Source: string; const Tokens: TStylerTokens;
  var Index: NativeInt; Section: TUsesSectionKind): TUsesClause;
var
  First, Last, P, ItemStart, ItemEnd, I, J: NativeInt;
  LocalDepth, Delta, BlockStart, FirstDirective, Previous, Following: NativeInt;
  Blocks: TArray<TSourceRange>;
  EndTokens, SeparatorTokens: TArray<NativeInt>;
  Block: TSourceRange;
  Item: TUsesItem;
  Items: TList<TUsesItem>;
  Valid, Unbalanced, Inside: Boolean;
begin
  Result := Default(TUsesClause);
  Result.Section := Section;
  First := Index;
  Result.HeaderEnd := Tokens[First].Range.EndOffset;
  Last := First + 1;
  // Stop at a section boundary or EOF when the clause is incomplete.
  while (Last < Length(Tokens)) and (Tokens[Last].Kind <> tkSemicolon) and
    not IsWord(Tokens[Last], 'implementation') and
    not IsWord(Tokens[Last], 'interface') and not IsWord(Tokens[Last], 'end') do
    Inc(Last);
  Valid := (Last < Length(Tokens)) and (Tokens[Last].Kind = tkSemicolon);
  if Valid then
    Result.Range := TSourceRange.Create(Tokens[First].Range.Start,
      Tokens[Last].Range.EndOffset - Tokens[First].Range.Start)
  else
  begin
    if Last < Length(Tokens) then P := Tokens[Last].Range.Start else P := Length(Source);
    Result.Range := TSourceRange.Create(Tokens[First].Range.Start,
      P - Tokens[First].Range.Start);
    AddDiagnostic(Result.Diagnostics, dcInvalidUses, Result.Range);
  end;
  // Conditional blocks that open and close inside the clause become fixed
  // points. A block still open at the terminator makes the clause uncertain.
  LocalDepth := 0; BlockStart := 0; FirstDirective := -1; Unbalanced := False;
  Blocks := nil;
  for I := First + 1 to Last - 1 do
    case Tokens[I].Kind of
      tkDirective:
        begin
          if FirstDirective < 0 then FirstDirective := I;
          Delta := ConditionalDelta(Tokens[I]);
          if (LocalDepth = 0) and (Delta > 0) then BlockStart := Tokens[I].Range.Start;
          Inc(LocalDepth, Delta);
          if LocalDepth < 0 then
          begin Unbalanced := True; LocalDepth := 0; end
          else if (LocalDepth = 0) and (Delta < 0) then
            Blocks := Blocks + [TSourceRange.Create(BlockStart,
              Tokens[I].Range.EndOffset - BlockStart)];
        end;
      tkInvalid: AddDiagnostic(Result.Diagnostics, dcUnterminatedToken, Tokens[I].Range);
    end;
  if Unbalanced or (LocalDepth <> 0) then
    AddDiagnostic(Result.Diagnostics, dcDirectiveBarrier, Tokens[FirstDirective].Range);

  Items := TList<TUsesItem>.Create;
  try
    P := NextSignificant(Tokens, First + 1);
    if P >= Last then Valid := False;
    while P < Last do
    begin
      Item := Default(TUsesItem);
      ItemStart := P;
      if (Tokens[P].Kind <> tkIdentifier) or IsWord(Tokens[P], 'in') then
      begin Valid := False; Break; end;
      Item.Name := Tokens[P].Text;
      ItemEnd := P;
      P := NextSignificant(Tokens, P + 1);
      while (P < Last) and (Tokens[P].Kind = tkDot) do
      begin
        P := NextSignificant(Tokens, P + 1);
        if (P >= Last) or (Tokens[P].Kind <> tkIdentifier) then
        begin Valid := False; Break; end;
        Item.Name := Item.Name + '.' + Tokens[P].Text;
        ItemEnd := P;
        P := NextSignificant(Tokens, P + 1);
      end;
      if not Valid then Break;
      if (P < Last) and IsWord(Tokens[P], 'in') then
      begin
        P := NextSignificant(Tokens, P + 1);
        if (P >= Last) or (Tokens[P].Kind <> tkString) then
        begin Valid := False; Break; end;
        ItemEnd := P;
        P := NextSignificant(Tokens, P + 1);
      end;
      Item.Range := TSourceRange.Create(Tokens[ItemStart].Range.Start,
        Tokens[ItemEnd].Range.EndOffset - Tokens[ItemStart].Range.Start);
      Item.Declaration := Copy(Source, Item.Range.Start + 1, Item.Range.Length);
      EndTokens := EndTokens + [ItemEnd];
      if (P < Length(Tokens)) and (Tokens[P].Kind in [tkComma, tkSemicolon]) then
      begin
        SeparatorTokens := SeparatorTokens + [P];
        Item.SeparatorEnd := Tokens[P].Range.EndOffset;
      end
      else
      begin
        SeparatorTokens := SeparatorTokens + [-1];
        Item.SeparatorEnd := Item.Range.EndOffset;
      end;
      Items.Add(Item);
      if P = Last then Break;
      if Tokens[P].Kind <> tkComma then
      begin Valid := False; Break; end;
      P := NextSignificant(Tokens, P + 1);
      if P >= Last then Valid := False;
    end;
    Result.Items := Items.ToArray;
    for I := 0 to High(Result.Items) do
      for Block in Blocks do
        if (Result.Items[I].Range.Start >= Block.Start) and
          (Result.Items[I].Range.EndOffset <= Block.EndOffset) then Result.Items[I].Fixed := True;
    // The same unit may legitimately appear in alternative conditional branches.
    for I := 1 to High(Result.Items) do
      for J := 0 to I - 1 do
        if SameText(Result.Items[J].Name, Result.Items[I].Name) and
          not (Result.Items[J].Fixed and Result.Items[I].Fixed) then
          AddDiagnostic(Result.Diagnostics, dcDuplicateUnit, Result.Items[I].Range);
    if not Valid and (Length(Result.Diagnostics) = 0) then
    begin
      if FirstDirective >= 0 then
        AddDiagnostic(Result.Diagnostics, dcDirectiveBarrier, Tokens[FirstDirective].Range)
      else AddDiagnostic(Result.Diagnostics, dcInvalidUses, Result.Range);
    end;
    if Valid and (FirstDirective >= 0) then
      // Every directive must touch a fixed unit so its surrounding text is
      // copied verbatim; a directive with no unit in its block pins a neighbor.
      for I := First + 1 to Last - 1 do
      begin
        if Tokens[I].Kind <> tkDirective then Continue;
        Previous := -1; Following := -1; Inside := False;
        for J := 0 to High(Result.Items) do
        begin
          if Result.Items[J].Range.EndOffset <= Tokens[I].Range.Start then Previous := J;
          if (Following = -1) and (Result.Items[J].Range.Start >= Tokens[I].Range.EndOffset) then Following := J;
          if (Tokens[I].Range.Start >= Result.Items[J].Range.Start) and
            (Tokens[I].Range.EndOffset <= Result.Items[J].Range.EndOffset) then Inside := True;
        end;
        if Inside then
          AddDiagnostic(Result.Diagnostics, dcDirectiveBarrier, Tokens[I].Range)
        else if not (((Previous >= 0) and Result.Items[Previous].Fixed) or
          ((Following >= 0) and Result.Items[Following].Fixed)) then
        begin
          if Following >= 0 then Result.Items[Following].Fixed := True
          else if Previous >= 0 then Result.Items[Previous].Fixed := True;
        end;
      end;
    if Valid then ClassifyComments(Source, Tokens, First, Last, EndTokens, SeparatorTokens, Result);
    Result.CanOrganize := Valid and (Length(Result.Diagnostics) = 0);
  finally
    Items.Free;
  end;
  if (Last < Length(Tokens)) and (Tokens[Last].Kind = tkSemicolon) then
    Index := Last + 1
  else Index := Last;
end;

function ParseUses(const Source: string): TUsesParseResult;
var
  Tokens: TStylerTokens;
  I, P: NativeInt;
  Section: TUsesSectionKind;
  Clause: TUsesClause;
  Header: TSectionHeader;
  SeenInterface, SeenImplementation, AllowUses, InUnit, StructuralBarrier,
    ConditionalImplementation: Boolean;
  // Conditional compilation nesting depth in effect at each token.
  Depth: TArray<NativeInt>;

  procedure HeaderAt(Kind: TSectionHeaderKind);
  begin
    Header.Kind := Kind; Header.Range := Tokens[I].Range; Header.Section := Section;
    Header.Conditional := Depth[I] > 0;
    Result.Headers := Result.Headers + [Header];
  end;
begin
  Result := Default(TUsesParseResult);
  Tokens := Tokenize(Source);
  SetLength(Depth, Length(Tokens));
  P := 0;
  for I := 0 to High(Tokens) do
  begin
    Depth[I] := P;
    Inc(P, ConditionalDelta(Tokens[I]));
    if P < 0 then P := 0;
  end;
  for I := 0 to High(Tokens) do
    if Tokens[I].Kind = tkInvalid then
      AddDiagnostic(Result.Diagnostics, dcUnterminatedToken, Tokens[I].Range);
  I := NextSignificant(Tokens, 0);
  InUnit := (I < Length(Tokens)) and IsWord(Tokens[I], 'unit');
  if not InUnit then
  begin
    AddDiagnostic(Result.Diagnostics, dcUnsupportedStructure,
      TSourceRange.Create(0, Length(Source)));
    Exit;
  end;
  // Require a proper unit header; do not search for arbitrary uses keywords.
  I := NextSignificant(Tokens, I + 1);
  if (I >= Length(Tokens)) or (Tokens[I].Kind <> tkIdentifier) then InUnit := False;
  if InUnit then
  begin
    I := NextSignificant(Tokens, I + 1);
    while (I < Length(Tokens)) and (Tokens[I].Kind = tkDot) do
    begin
      I := NextSignificant(Tokens, I + 1);
      if (I >= Length(Tokens)) or (Tokens[I].Kind <> tkIdentifier) then
      begin InUnit := False; Break; end;
      I := NextSignificant(Tokens, I + 1);
    end;
    InUnit := InUnit and (I < Length(Tokens)) and (Tokens[I].Kind = tkSemicolon);
  end;
  if not InUnit then
  begin
    AddDiagnostic(Result.Diagnostics, dcUnsupportedStructure,
      TSourceRange.Create(0, Length(Source)));
    Exit;
  end;
  I := NextSignificant(Tokens, I + 1);
  if (I >= Length(Tokens)) or not IsWord(Tokens[I], 'interface') then
  begin
    AddDiagnostic(Result.Diagnostics, dcUnsupportedStructure,
      TSourceRange.Create(0, Length(Source)));
    Exit;
  end;
  Section := usInterface;
  HeaderAt(shInterface);
  SeenInterface := True;
  SeenImplementation := False;
  AllowUses := True;
  StructuralBarrier := False;
  ConditionalImplementation := False;
  // Directives outside a uses clause are left alone and do not block anything.
  // Only a section keyword placed inside a conditional block is uncertain.
  if Depth[I] > 0 then
  begin
    StructuralBarrier := True;
    AddDiagnostic(Result.Diagnostics, dcDirectiveBarrier, Tokens[I].Range);
  end;
  Inc(I);
  while I < Length(Tokens) do
  begin
    if Tokens[I].Kind in [tkWhitespace, tkComment, tkDirective] then
    begin Inc(I); Continue; end;
    if IsWord(Tokens[I], 'implementation') and SeenInterface and not SeenImplementation then
    begin
      Section := usImplementation;
      HeaderAt(shImplementation);
      SeenImplementation := True;
      ConditionalImplementation := Depth[I] > 0;
      AllowUses := True;
      Inc(I);
      Continue;
    end;
    if AllowUses and IsWord(Tokens[I], 'uses') then
    begin
      HeaderAt(shUses);
      P := I;
      Clause := ReadClause(Source, Tokens, P, Section);
      if (Depth[I] > 0) or
        ((Section = usImplementation) and ConditionalImplementation) then
      begin
        Clause.CanOrganize := False;
        AddDiagnostic(Clause.Diagnostics, dcDirectiveBarrier, Clause.Range);
      end;
      Result.Clauses := Result.Clauses + [Clause];
      I := P;
      AllowUses := False;
      Continue;
    end;
    if SeenImplementation then
    begin
      if IsWord(Tokens[I], 'initialization') then HeaderAt(shInitialization)
      else if IsWord(Tokens[I], 'finalization') then HeaderAt(shFinalization);
    end;
    AllowUses := False;
    Inc(I);
  end;
  // An invalid token anywhere makes the structural interpretation uncertain.
  for I := 0 to High(Tokens) do
    if Tokens[I].Kind = tkInvalid then
      for P := 0 to High(Result.Clauses) do Result.Clauses[P].CanOrganize := False;
  // An interface keyword under a conditional block makes every section uncertain.
  if StructuralBarrier then
    for P := 0 to High(Result.Clauses) do
    begin
      Result.Clauses[P].CanOrganize := False;
      AddDiagnostic(Result.Clauses[P].Diagnostics, dcDirectiveBarrier,
        Result.Clauses[P].Range);
    end;
end;

end.
