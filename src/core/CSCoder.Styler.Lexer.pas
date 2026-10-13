unit CSCoder.Styler.Lexer;

interface

uses CSCoder.Styler.Types;

function Tokenize(const Source: string): TStylerTokens;

implementation

uses System.SysUtils, System.Character, System.Generics.Collections;

function IsIdentifierStart(C: Char): Boolean;
begin
  Result := (C = '_') or C.IsLetter;
end;

function IsIdentifierPart(C: Char): Boolean;
begin
  Result := IsIdentifierStart(C) or C.IsDigit;
end;

// Delphi 12+ multiline string: an odd run of three or more quotes followed by
// a line break, closed by the same run alone at the start of a later line.
function SkipMultilineString(const Source: string; var P: NativeInt): Boolean;
var N, Quotes, I, Count: NativeInt;
begin
  Result := False;
  N := Length(Source);
  Quotes := 0;
  while (P + Quotes <= N) and (Source[P + Quotes] = '''') do Inc(Quotes);
  if (Quotes < 3) or not Odd(Quotes) then Exit;
  I := P + Quotes;
  if (I > N) or not CharInSet(Source[I], [#10, #13]) then Exit;
  while I <= N do
  begin
    if (Source[I] = #13) and (I < N) and (Source[I + 1] = #10) then Inc(I);
    Inc(I);
    while (I <= N) and CharInSet(Source[I], [' ', #9]) do Inc(I);
    Count := 0;
    while (I + Count <= N) and (Source[I + Count] = '''') do Inc(Count);
    if Count = Quotes then
    begin
      P := I + Count;
      Exit(True);
    end;
    while (I <= N) and not CharInSet(Source[I], [#10, #13]) do Inc(I);
  end;
end;

function Tokenize(const Source: string): TStylerTokens;
var
  Tokens: TList<TStylerToken>;
  Token: TStylerToken;
  P, First, N: NativeInt;
  Closed: Boolean;
  Kind: TTokenKind;
begin
  Tokens := TList<TStylerToken>.Create;
  try
    N := Length(Source);
    P := 1;
    while P <= N do
    begin
      First := P;
      Kind := tkSymbol;
      if CharInSet(Source[P], [#9, #10, #13, ' ']) then
      begin
        Kind := tkWhitespace;
        repeat Inc(P) until (P > N) or
          not CharInSet(Source[P], [#9, #10, #13, ' ']);
      end
      else if IsIdentifierStart(Source[P]) or
        ((Source[P] = '&') and (P < N) and IsIdentifierStart(Source[P + 1])) then
      begin
        Kind := tkIdentifier;
        Inc(P);
        while (P <= N) and IsIdentifierPart(Source[P]) do Inc(P);
      end
      else if Source[P] = '''' then
      begin
        Kind := tkString;
        if not SkipMultilineString(Source, P) then
        begin
          Closed := False;
          Inc(P);
          while P <= N do
          begin
            if CharInSet(Source[P], [#10, #13]) then Break;
            if Source[P] = '''' then
            begin
              Inc(P);
              if (P <= N) and (Source[P] = '''') then Inc(P)
              else
              begin
                Closed := True;
                Break;
              end;
            end
            else Inc(P);
          end;
          if not Closed then Kind := tkInvalid;
        end;
      end
      else if (Source[P] = '/') and (P < N) and (Source[P + 1] = '/') then
      begin
        Kind := tkComment;
        Inc(P, 2);
        while (P <= N) and not CharInSet(Source[P], [#10, #13]) do Inc(P);
      end
      else if Source[P] = '{' then
      begin
        Kind := tkComment;
        if (P < N) and (Source[P + 1] = '$') then Kind := tkDirective;
        Inc(P);
        while (P <= N) and (Source[P] <> '}') do Inc(P);
        if P <= N then Inc(P) else Kind := tkInvalid;
      end
      else if (Source[P] = '(') and (P < N) and (Source[P + 1] = '*') then
      begin
        Kind := tkComment;
        if (P + 2 <= N) and (Source[P + 2] = '$') then Kind := tkDirective;
        Inc(P, 2);
        Closed := False;
        while P < N do
        begin
          if (Source[P] = '*') and (Source[P + 1] = ')') then
          begin
            Inc(P, 2);
            Closed := True;
            Break;
          end;
          Inc(P);
        end;
        if not Closed then
        begin
          P := N + 1;
          Kind := tkInvalid;
        end;
      end
      else
      begin
        case Source[P] of
          '.': Kind := tkDot;
          ',': Kind := tkComma;
          ';': Kind := tkSemicolon;
        end;
        Inc(P);
      end;
      Token.Kind := Kind;
      Token.Range := TSourceRange.Create(First - 1, P - First);
      Token.Text := Copy(Source, First, P - First);
      Tokens.Add(Token);
    end;
    Result := Tokens.ToArray;
  finally
    Tokens.Free;
  end;
end;

end.
