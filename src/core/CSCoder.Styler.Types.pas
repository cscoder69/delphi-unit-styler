unit CSCoder.Styler.Types;

interface

type
  // All ranges use zero-based UTF-16 offsets; EndOffset is exclusive.
  TSourceRange = record
    Start: NativeInt;
    Length: NativeInt;
    function EndOffset: NativeInt;
    class function Create(AStart, ALength: NativeInt): TSourceRange; static;
  end;

  TTokenKind = (tkIdentifier, tkWhitespace, tkString, tkComment, tkDirective,
    tkDot, tkComma, tkSemicolon, tkSymbol, tkInvalid);

  TStylerToken = record
    Kind: TTokenKind;
    Range: TSourceRange;
    Text: string;
  end;
  TStylerTokens = TArray<TStylerToken>;

  TUsesSectionKind = (usInterface, usImplementation);
  TSectionHeaderKind = (shInterface, shUses, shImplementation, shInitialization, shFinalization);
  TSectionHeader = record
    Kind: TSectionHeaderKind;
    Range: TSourceRange;
    Section: TUsesSectionKind;
    // True when the keyword sits inside a conditional compilation block.
    Conditional: Boolean;
  end;
  TDiagnosticCode = (dcUnterminatedToken, dcUnsupportedStructure,
    dcDirectiveBarrier, dcCommentAssociation, dcInvalidUses, dcDuplicateUnit,
    dcExcludedUnitBarrier, dcExcludedCommentClause, dcCommentGroupSpacing,
    dcSectionSpacingPreserved);
  TStylerDiagnostic = record
    Code: TDiagnosticCode;
    Range: TSourceRange;
  end;

  TUsesItem = record
    Name: string;
    Declaration: string;
    Range: TSourceRange;
    // Tied to a compiler directive inside the clause: never moved, and the
    // text around it (directives, commas, line breaks) is kept verbatim.
    Fixed: Boolean;
    // Offset right after the comma or semicolon that follows the unit.
    SeparatorEnd: NativeInt;
    // Comment written after that separator on the line of the unit, with the
    // blanks before it. It belongs to the unit and moves with it.
    Comment: string;
    // Offset right after that comment; meaningful only with a comment.
    CommentEnd: NativeInt;
  end;

  TUsesClause = record
    Section: TUsesSectionKind;
    Range: TSourceRange;
    // End of the uses keyword plus any comments placed before the first unit.
    HeaderEnd: NativeInt;
    Items: TArray<TUsesItem>;
    CanOrganize: Boolean;
    Diagnostics: TArray<TStylerDiagnostic>;
  end;

  TUsesParseResult = record
    Clauses: TArray<TUsesClause>;
    Headers: TArray<TSectionHeader>;
    Diagnostics: TArray<TStylerDiagnostic>;
  end;

const
  // Ctrl+Alt+U
  DefaultOrganizeShortcut = $4000 or $8000 or Ord('U');

type
  TUsesGroup = record
    Name: string;
    Selectors: TArray<string>;
  end;
  TUngroupedPosition = (upLast, upFirst);

  TUsesOptions = record
    AutoSaveUnits: Boolean;
    // Key combination that opens Organize uses from the editor, as a VCL
    // TShortCut value; 0 for none.
    Shortcut: Integer;
    // Copy each unit, as saved on disk, to the project's .backup before changing it.
    BackupUnits: Boolean;
    // Language of the windows: en, pt, es, de or fr; empty follows Windows.
    Language: string;
    Alphabetical: Boolean;
    // With Alphabetical: compare only the part of the name before the first
    // dot (System, Vcl, Winapi; the whole name when there is no dot) and keep
    // units with the same first name in the order they already have.
    SortFirstNameOnly: Boolean;
    OneUnitPerLine: Boolean;
    // Several units per line: a line is filled up to MaxLineWidth columns and
    // every priority block or group starts a line of its own. Not together
    // with OneUnitPerLine.
    WrapUnits: Boolean;
    MaxLineWidth: Integer;
    IndentationEnabled: Boolean;
    Indentation: string;
    PrioritiesEnabled: Boolean;
    Priorities: TArray<string>;
    GroupingEnabled: Boolean;
    Groups: TArray<TUsesGroup>;
    UngroupedPosition: TUngroupedPosition;
    BlankLinesBetweenGroups: Boolean;
    BlankBeforeSections: Boolean;
    BlankAfterSections: Boolean;
    ExcludedSections: set of TUsesSectionKind;
    ExcludedUnits: TArray<string>;
    // Rule of the add-on: units that never change place, because their order
    // decides which one wins when two declare the same name. They act like
    // ExcludedUnits (nothing moves across them) but are not reported.
    ProtectedUnits: TArray<string>;
    // Folders and files, relative to the project, whose units are never touched.
    IgnoredPaths: TArray<string>;
    function HasTransformations: Boolean;
  end;

  TSourceEdit = record
    Range: TSourceRange;
    Section: TUsesSectionKind;
    ExpectedText: string;
    ReplacementText: string;
  end;

  TStylerProposal = record
    SourceSnapshot: string;
    Edits: TArray<TSourceEdit>;
    Diagnostics: TArray<TStylerDiagnostic>;
    function ApplyTo(const Source: string): string;
  end;

// True when the unit file is one of the ignored entries or lies below an
// ignored folder. Paths are compared without case and with either slash.
function IsIgnoredPath(const UnitPath: string; const Ignored: TArray<string>): Boolean;

implementation

uses System.SysUtils;

function NormalizedPath(const Value: string): string;
begin
  Result := StringReplace(Trim(Value), '/', '\', [rfReplaceAll]);
  while Copy(Result, 1, 2) = '.\' do Delete(Result, 1, 2);
  while (Result <> '') and (Result[Length(Result)] = '\') do Delete(Result, Length(Result), 1);
end;

function IsIgnoredPath(const UnitPath: string; const Ignored: TArray<string>): Boolean;
var Entry, Target, Rule: string;
begin
  Target := NormalizedPath(UnitPath);
  for Entry in Ignored do
  begin
    Rule := NormalizedPath(Entry);
    if Rule = '' then Continue;
    if SameText(Target, Rule) or SameText(Copy(Target, 1, Length(Rule) + 1), Rule + '\') then Exit(True);
  end;
  Result := False;
end;

function TUsesOptions.HasTransformations: Boolean;
begin
  Result := Alphabetical or OneUnitPerLine or WrapUnits or IndentationEnabled or
    PrioritiesEnabled or GroupingEnabled or BlankBeforeSections or BlankAfterSections;
end;

function TStylerProposal.ApplyTo(const Source: string): string;
var I, PreviousEnd: NativeInt; Edit: TSourceEdit;
begin
  if Source <> SourceSnapshot then
    raise EArgumentException.Create('Source has changed since analysis');
  PreviousEnd := 0;
  for Edit in Edits do
  begin
    if (Edit.Range.Start < PreviousEnd) or (Edit.Range.Length < 0) or
      (Edit.Range.EndOffset > Length(Source)) or
      (Copy(Source, Edit.Range.Start + 1, Edit.Range.Length) <> Edit.ExpectedText) then
      raise EArgumentException.Create('Source does not match proposal ranges');
    PreviousEnd := Edit.Range.EndOffset;
  end;
  Result := Source;
  for I := High(Edits) downto 0 do
  begin
    Delete(Result, Edits[I].Range.Start + 1, Edits[I].Range.Length);
    Insert(Edits[I].ReplacementText, Result, Edits[I].Range.Start + 1);
  end;
end;

function TSourceRange.EndOffset: NativeInt;
begin
  Result := Start + Length;
end;

class function TSourceRange.Create(AStart, ALength: NativeInt): TSourceRange;
begin
  Result.Start := AStart;
  Result.Length := ALength;
end;

end.
