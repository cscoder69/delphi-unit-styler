unit CSCoder.Styler.UsesOrganizer;

interface

uses CSCoder.Styler.Types;

type
  TOrderedUsesItem = record
    Item: TUsesItem;
    Block: NativeInt;
    Priority: NativeInt;
    Segment: NativeInt;
    Excluded: Boolean;
  end;

const
  // Accepted range and default of TUsesOptions.MaxLineWidth.
  MinLineWidth = 40;
  MaxLineWidthLimit = 500;
  DefaultLineWidth = 100;

function SelectorMatches(const Selector, UnitName: string): Boolean;
// True for a unit that keeps its place: preserved by the project or protected
// by the rules of the add-on.
function IsExcludedUnit(const UnitName: string; const Options: TUsesOptions): Boolean;
// True only for the units the project asked to preserve, which are reported.
function IsProjectExcludedUnit(const UnitName: string; const Options: TUsesOptions): Boolean;
procedure ValidateUsesOptions(const Options: TUsesOptions);
function OrderUses(const Items: TArray<TUsesItem>;
  const Options: TUsesOptions): TArray<TOrderedUsesItem>;

implementation

uses System.SysUtils, System.Character, CSCoder.Styler.Strings;

function CanonicalName(const Name: string): string;
var P: NativeInt;
begin
  Result := '';
  for P := 1 to Length(Name) do
    if Name[P] <> '&' then Result := Result + Name[P].ToUpper;
end;

function CompareNames(const A, B: string): NativeInt;
var CA, CB: string; P, Count: NativeInt;
begin
  CA := CanonicalName(A);
  CB := CanonicalName(B);
  Count := Length(CA);
  if Length(CB) < Count then Count := Length(CB);
  for P := 1 to Count do
    if CA[P] <> CB[P] then Exit(Ord(CA[P]) - Ord(CB[P]));
  Result := Length(CA) - Length(CB);
end;

function SelectorMatches(const Selector, UnitName: string): Boolean;
var Prefix, Name: string;
begin
  Name := CanonicalName(UnitName);
  if (Length(Selector) > 2) and (Copy(Selector, Length(Selector) - 1, 2) = '.*') then
  begin
    Prefix := CanonicalName(Copy(Selector, 1, Length(Selector) - 1));
    Result := (Length(Name) > Length(Prefix)) and
      (Copy(Name, 1, Length(Prefix)) = Prefix);
  end
  else Result := CanonicalName(Selector) = Name;
end;

procedure ValidateSelector(const Selector: string);
var Name: string; P: NativeInt; NeedStart: Boolean;
begin
  Name := Selector;
  if (Length(Name) > 2) and (Copy(Name, Length(Name) - 1, 2) = '.*') then
    Delete(Name, Length(Name) - 1, 2);
  if Name = '' then raise EArgumentException.Create(L(stErrEmptyName));
  NeedStart := True;
  P := 1;
  while P <= Length(Name) do
  begin
    if NeedStart then
    begin
      if Name[P] = '&' then Inc(P);
      if (P > Length(Name)) or not ((Name[P] = '_') or Name[P].IsLetter) then
        raise EArgumentException.Create(L(stErrBadSelector, [Selector]));
      NeedStart := False;
    end
    else if Name[P] = '.' then NeedStart := True
    else if not ((Name[P] = '_') or Name[P].IsLetterOrDigit) then
      raise EArgumentException.Create(L(stErrBadSelector, [Selector]));
    Inc(P);
  end;
  if NeedStart then raise EArgumentException.Create(L(stErrBadSelector, [Selector]));
end;

procedure ValidateSelectors(const Selectors: TArray<string>);
var I, J: NativeInt;
begin
  for I := 0 to High(Selectors) do
  begin
    ValidateSelector(Selectors[I]);
    for J := 0 to I - 1 do
      if CompareNames(Selectors[I], Selectors[J]) = 0 then
        raise EArgumentException.Create(L(stErrDupSelector, [Selectors[I]]));
  end;
end;

procedure ValidateUsesOptions(const Options: TUsesOptions);
var I, J: NativeInt;
begin
  ValidateSelectors(Options.ExcludedUnits);
  ValidateSelectors(Options.ProtectedUnits);
  if Options.WrapUnits then
  begin
    if Options.OneUnitPerLine then
      raise EArgumentException.Create(L(stErrBothLayouts));
    if (Options.MaxLineWidth < MinLineWidth) or (Options.MaxLineWidth > MaxLineWidthLimit) then
      raise EArgumentException.Create(L(stErrWidthRange, [MinLineWidth, MaxLineWidthLimit]));
  end;
  if Options.IndentationEnabled then
    for I := 1 to Length(Options.Indentation) do
      if not CharInSet(Options.Indentation[I], [' ', #9]) then
        raise EArgumentException.Create(L(stErrIndentChars));
  if Options.PrioritiesEnabled then ValidateSelectors(Options.Priorities);
  if Options.GroupingEnabled then
    for I := 0 to High(Options.Groups) do
    begin
      if Trim(Options.Groups[I].Name) = '' then
        raise EArgumentException.Create(L(stErrGroupNoName));
      for J := 0 to I - 1 do
        if CompareNames(Trim(Options.Groups[I].Name), Trim(Options.Groups[J].Name)) = 0 then
          raise EArgumentException.Create(L(stErrGroupDup, [Trim(Options.Groups[I].Name)]));
      ValidateSelectors(Options.Groups[I].Selectors);
    end;
end;

function FirstName(const Name: string): string;
var P: NativeInt;
begin
  P := Pos('.', Name);
  if P > 0 then Result := Copy(Name, 1, P - 1) else Result := Name;
end;

function CompareItems(const A, B: TOrderedUsesItem; const Options: TUsesOptions): NativeInt;
begin
  Result := A.Block - B.Block;
  if Result <> 0 then Exit;
  if A.Block = -1 then Result := A.Priority - B.Priority
  else if Options.Alphabetical then
  begin
    // A tie keeps the original order: the sort below is stable.
    if Options.SortFirstNameOnly then Result := CompareNames(FirstName(A.Item.Name), FirstName(B.Item.Name))
    else Result := CompareNames(A.Item.Name, B.Item.Name);
  end;
end;

function OrderSegment(const Items: TArray<TUsesItem>;
  const Options: TUsesOptions): TArray<TOrderedUsesItem>;
var I, J, G, S: NativeInt; Matched: Boolean; Current: TOrderedUsesItem;
begin
  SetLength(Result, Length(Items));
  for I := 0 to High(Items) do
  begin
    Result[I].Item := Items[I];
    Result[I].Block := 0;
    Result[I].Priority := -1;
    if Options.PrioritiesEnabled then
      for J := 0 to High(Options.Priorities) do
        if SelectorMatches(Options.Priorities[J], Items[I].Name) then
        begin
          Result[I].Block := -1;
          Result[I].Priority := J;
          Break;
        end;
    if (Result[I].Block <> -1) and Options.GroupingEnabled then
    begin
      if Options.UngroupedPosition = upLast then Result[I].Block := Length(Options.Groups) + 1;
      Matched := False;
      for G := 0 to High(Options.Groups) do
      begin
        for S := 0 to High(Options.Groups[G].Selectors) do
          if SelectorMatches(Options.Groups[G].Selectors[S], Items[I].Name) then
          begin
            Result[I].Block := G + 1;
            Matched := True;
            Break;
          end;
        if Matched then Break;
      end;
    end;
  end;
  // Stable insertion sort keeps original order inside prefixes and unsorted groups.
  for I := 1 to High(Result) do
  begin
    Current := Result[I];
    J := I - 1;
    while (J >= 0) and (CompareItems(Result[J], Current, Options) > 0) do
    begin
      Result[J + 1] := Result[J];
      Dec(J);
    end;
    Result[J + 1] := Current;
  end;
end;

function IsProjectExcludedUnit(const UnitName: string; const Options: TUsesOptions): Boolean;
var Selector: string;
begin
  Result := False;
  for Selector in Options.ExcludedUnits do
    if SelectorMatches(Selector, UnitName) then Exit(True);
end;

function IsExcludedUnit(const UnitName: string; const Options: TUsesOptions): Boolean;
var Selector: string;
begin
  Result := IsProjectExcludedUnit(UnitName, Options);
  if Result then Exit;
  for Selector in Options.ProtectedUnits do
    if SelectorMatches(Selector, UnitName) then Exit(True);
end;

function OrderUses(const Items: TArray<TUsesItem>;
  const Options: TUsesOptions): TArray<TOrderedUsesItem>;
var First, Last, I, Segment: NativeInt; Ordered: TArray<TOrderedUsesItem>;
begin
  Result := nil;
  First := 0;
  Segment := 0;
  while First < Length(Items) do
  begin
    // Units tied to directives are anchors exactly like excluded units.
    if Items[First].Fixed or IsExcludedUnit(Items[First].Name, Options) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)].Item := Items[First];
      Result[High(Result)].Excluded := True;
      Result[High(Result)].Segment := Segment;
      Inc(First);
      Inc(Segment);
      Continue;
    end;
    Last := First;
    while (Last < Length(Items)) and not Items[Last].Fixed and
      not IsExcludedUnit(Items[Last].Name, Options) do Inc(Last);
    Ordered := OrderSegment(Copy(Items, First, Last - First), Options);
    for I := 0 to High(Ordered) do Ordered[I].Segment := Segment;
    Result := Result + Ordered;
    First := Last;
    Inc(Segment);
  end;
end;

end.
