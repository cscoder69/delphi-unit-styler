unit CSCoder.Styler.EditorAdapter;

interface

uses System.Generics.Collections, ToolsAPI, CSCoder.Styler.Workspace, CSCoder.Styler.Types,
  CSCoder.Styler.ProjectSettings, CSCoder.Styler.SourceFile, CSCoder.Styler.Backup;

type
  // Units open in the IDE are read from and written to their editor buffer and
  // are never saved here. Units closed in the IDE are read from disk and, when
  // saving is requested, rewritten on disk in their original encoding. Before
  // either change the unit, as saved on disk, is copied to the run's backup.
  TIDEWorkspace = class(TInterfacedObject, IStylerWorkspace)
  private
    FEditor: IOTASourceEditor;
    FProject: IOTAProject;
    FSettings: TProjectSettings;
    FNames: TArray<string>;
    FCurrentIndex: Integer;
    FInitiallyOpen: TArray<Integer>;
    FDisk: TDictionary<Integer, TSourceFile>;
    FBackup: TBackupSession;
    procedure CheckProject;
    function BackupSaved(Index: Integer): string;
    function EditorOf(Index: Integer): IOTASourceEditor;
    function WasInitiallyOpen(Index: Integer): Boolean;
    function ReadBuffer(const Editor: IOTASourceEditor): string;
    procedure ApplyToBuffer(const Editor: IOTASourceEditor; const Proposal: TStylerProposal);
  public
    constructor Create(RequireUnit: Boolean = True);
    destructor Destroy; override;
    function ProjectName: string;
    function ProjectDirectory: string;
    function SettingsDirectory: string;
    function UnitNames: TArray<string>;
    function CurrentUnit: Integer;
    function OpenUnitIndices: TArray<Integer>;
    function SupportsBatch: Boolean;
    function IsDemo: Boolean;
    function ReadSource(Index: Integer): string;
    function LoadOptions: TUsesOptions;
    procedure SaveOptions(const Options: TUsesOptions);
    procedure OpenUnit(Index: Integer);
    procedure Apply(Index: Integer; const Proposal: TStylerProposal; AutoSave: Boolean);
    procedure StartBackup(Enabled: Boolean);
    function BackupDirectory: string;
  end;

implementation

uses System.SysUtils, System.Classes, System.IOUtils, CSCoder.Styler.Strings;

function SourceEditor(const Module: IOTAModule): IOTASourceEditor;
var I: Integer;
begin
  Result := nil;
  if Module = nil then Exit;
  for I := 0 to Module.ModuleFileCount - 1 do
    if Supports(Module.ModuleFileEditors[I], IOTASourceEditor, Result) and
      SameText(ExtractFileExt(Result.FileName), '.pas') then Exit;
  Result := nil;
end;

constructor TIDEWorkspace.Create(RequireUnit: Boolean);
var Services: IOTAModuleServices; I: Integer; Name: string;
begin
  inherited Create;
  FDisk := TDictionary<Integer, TSourceFile>.Create;
  if not Supports(BorlandIDEServices, IOTAModuleServices, Services) then
    raise EInvalidOperation.Create(L(stErrNoEditorServices));
  FEditor := SourceEditor(Services.CurrentModule);
  FProject := GetActiveProject;
  if FProject = nil then
    raise EInvalidOperation.Create(L(stErrNoProject));
  if RequireUnit and (FEditor = nil) then
    raise EInvalidOperation.Create(L(stErrNotUnit));
  FCurrentIndex := -1;
  // Only units that belong to the project: files that merely sit in its folder are not listed.
  for I := 0 to FProject.GetModuleCount - 1 do
  begin
    Name := FProject.GetModule(I).FileName;
    if not SameText(ExtractFileExt(Name), '.pas') then Continue;
    if not TPath.IsPathRooted(Name) then Name := TPath.Combine(ExtractFileDir(FProject.FileName), Name);
    Name := ExpandFileName(Name);
    if (FEditor <> nil) and SameText(Name, ExpandFileName(FEditor.FileName)) then
      FCurrentIndex := Integer(Length(FNames));
    FNames := FNames + [Name];
  end;
  if RequireUnit and (FCurrentIndex < 0) then
    raise EInvalidOperation.Create(L(stErrNotInProject));
  FInitiallyOpen := OpenUnitIndices;
  FSettings := TProjectSettings.Create(FProject.FileName);
end;

destructor TIDEWorkspace.Destroy;
begin FBackup.Free; FSettings.Free; FDisk.Free; inherited; end;

procedure TIDEWorkspace.CheckProject;
begin
  if (FProject = nil) or (GetActiveProject <> FProject) then
    raise EInvalidOperation.Create(L(stErrProjectChanged));
end;

function TIDEWorkspace.EditorOf(Index: Integer): IOTASourceEditor;
var Services: IOTAModuleServices;
begin
  CheckProject;
  if (Index < 0) or (Index > High(FNames)) then
    raise EArgumentOutOfRangeException.Create(L(stErrUnitOutside));
  if not Supports(BorlandIDEServices, IOTAModuleServices, Services) then
    raise EInvalidOperation.Create(L(stErrNoEditor));
  // Nil means the unit is closed in the IDE.
  Result := SourceEditor(Services.FindModule(FNames[Index]));
  if (Index = FCurrentIndex) and (Result <> FEditor) then
    raise EInvalidOperation.Create(L(stErrEditorClosed));
end;

function TIDEWorkspace.WasInitiallyOpen(Index: Integer): Boolean;
var I: Integer;
begin
  Result := Index = FCurrentIndex;
  for I in FInitiallyOpen do
    if I = Index then Exit(True);
end;

function TIDEWorkspace.ProjectName: string;
begin Result := ExtractFileName(FProject.FileName); end;
function TIDEWorkspace.ProjectDirectory: string;
begin Result := ExtractFileDir(FProject.FileName); end;
function TIDEWorkspace.SettingsDirectory: string;
begin Result := FSettings.RootDirectory; end;
function TIDEWorkspace.UnitNames: TArray<string>;
begin Result := Copy(FNames); end;
function TIDEWorkspace.CurrentUnit: Integer;
begin Result := FCurrentIndex; end;
function TIDEWorkspace.OpenUnitIndices: TArray<Integer>;
var Services: IOTAModuleServices; I: Integer;
begin
  Result := nil;
  if not Supports(BorlandIDEServices, IOTAModuleServices, Services) then Exit;
  for I := 0 to Integer(High(FNames)) do
    if SourceEditor(Services.FindModule(FNames[I])) <> nil then Result := Result + [I];
end;
function TIDEWorkspace.SupportsBatch: Boolean;
begin Result := True; end;
function TIDEWorkspace.IsDemo: Boolean;
begin Result := False; end;

function TIDEWorkspace.ReadBuffer(const Editor: IOTASourceEditor): string;
var Reader: IOTAEditReader; Buffer: array[0..8191] of AnsiChar;
  Count, Position: Integer; Bytes: UTF8String;
begin
  Reader := Editor.CreateReader;
  Bytes := ''; Position := 0;
  try
    repeat
      Count := Reader.GetText(Position, @Buffer[0], Length(Buffer));
      if Count < 0 then raise EInvalidOperation.Create(L(stErrReadEditor));
      if Count > 0 then
      begin
        SetLength(Bytes, Position + Count);
        Move(Buffer[0], Bytes[Position + 1], Count);
        Inc(Position, Count);
      end;
    until Count = 0;
  finally Reader := nil; end;
  Result := UTF8ToString(Bytes);
end;

function TIDEWorkspace.ReadSource(Index: Integer): string;
var Editor: IOTASourceEditor; Disk: TSourceFile;
begin
  Editor := EditorOf(Index);
  if Editor <> nil then
  begin
    FDisk.Remove(Index);
    Exit(ReadBuffer(Editor));
  end;
  // Closed in the IDE: the file itself is the source, bytes kept for the rewrite.
  Disk := LoadSourceFile(FNames[Index]);
  FDisk.AddOrSetValue(Index, Disk);
  Result := Disk.Text;
end;

function TIDEWorkspace.LoadOptions: TUsesOptions;
begin CheckProject; Result := FSettings.Load; end;
procedure TIDEWorkspace.SaveOptions(const Options: TUsesOptions);
begin CheckProject; FSettings.Save(Options); end;

procedure TIDEWorkspace.OpenUnit(Index: Integer);
var Actions: IOTAActionServices;
begin
  if EditorOf(Index) <> nil then Exit;
  if not Supports(BorlandIDEServices, IOTAActionServices, Actions) or
    not Actions.OpenFile(FNames[Index]) or (EditorOf(Index) = nil) then
    raise EInvalidOperation.Create(L(stErrOpenUnit));
  FDisk.Remove(Index);
end;

procedure TIDEWorkspace.StartBackup(Enabled: Boolean);
begin
  FreeAndNil(FBackup);
  if Enabled then FBackup := TBackupSession.Create(ProjectDirectory);
end;

function TIDEWorkspace.BackupDirectory: string;
begin
  if FBackup <> nil then Result := FBackup.Directory else Result := '';
end;

function TIDEWorkspace.BackupSaved(Index: Integer): string;
begin
  // The file as last saved, not the editor buffer. A unit never saved has no file.
  if (FBackup <> nil) and TFile.Exists(FNames[Index]) then
    Result := FBackup.Store(FNames[Index], TFile.ReadAllBytes(FNames[Index]))
  else Result := '';
end;

procedure TIDEWorkspace.Apply(Index: Integer; const Proposal: TStylerProposal; AutoSave: Boolean);
var Editor: IOTASourceEditor; Disk: TSourceFile; Saved: string;
begin
  Editor := EditorOf(Index);
  if Editor <> nil then
  begin
    // In the editor: changed in memory with Undo and left for the user to save.
    Saved := BackupSaved(Index);
    try ApplyToBuffer(Editor, Proposal);
    except
      if FBackup <> nil then FBackup.Discard(Saved);
      raise;
    end;
    Exit;
  end;
  if WasInitiallyOpen(Index) then
    raise EInvalidOperation.Create(L(stErrClosedDuring));
  if not AutoSave then
    raise EInvalidOperation.Create(L(stErrMustOpen));
  if not FDisk.TryGetValue(Index, Disk) or (Disk.Text <> Proposal.SourceSnapshot) then
    raise EInvalidOperation.Create(L(stErrChangedAfter));
  // A unit that could not be copied is not rewritten; a refused rewrite leaves no copy.
  Saved := '';
  if FBackup <> nil then Saved := FBackup.Store(FNames[Index], Disk.Bytes);
  try SaveSourceFile(Disk, Proposal.ApplyTo(Disk.Text));
  except
    if FBackup <> nil then FBackup.Discard(Saved);
    raise;
  end;
  FDisk.Remove(Index);
end;

procedure TIDEWorkspace.ApplyToBuffer(const Editor: IOTASourceEditor; const Proposal: TStylerProposal);
type
  TByteEdit = record
    Start, After, Lines: Integer;
    Text: UTF8String;
  end;
var Source: string; Writer: IOTAEditWriter;
  E: TSourceEdit; ByteEdits: TArray<TByteEdit>; I: Integer;
  View: IOTAEditView; Cursor: TOTAEditPos; CharPos: TOTACharPos;
  CursorByte, StartByte, AfterByte, LineDelta: Integer; BlockType: TOTABlockType;
  BlockVisible, Inside: Boolean;

  function LineBreaks(const Text: string): Integer;
  var P: Integer;
  begin
    Result := 0;
    for P := 1 to Length(Text) do
      if (Text[P] = #10) or ((Text[P] = #13) and ((P = Length(Text)) or (Text[P + 1] <> #10))) then Inc(Result);
  end;

  function MapByte(Original: Integer): Integer;
  var B: TByteEdit; Delta: Integer;
  begin
    Delta := 0;
    for B in ByteEdits do
    begin
      if Original < B.Start then Break;
      if Original < B.After then Exit(B.Start + Delta);
      Inc(Delta, Length(B.Text) - (B.After - B.Start));
    end;
    Result := Original + Delta;
  end;

begin
  Cursor := Default(TOTAEditPos);
  CursorByte := 0; StartByte := 0; AfterByte := 0;
  BlockType := btUnknown; BlockVisible := False;
  Source := ReadBuffer(Editor);
  // Validate the full snapshot and all ranges before creating a writer.
  Proposal.ApplyTo(Source);
  if Pos(#0, Source) > 0 then raise EInvalidOperation.Create('Unsupported source character');
  ByteEdits := nil;
  for E in Proposal.Edits do
  begin
    I := Integer(Length(ByteEdits)); SetLength(ByteEdits, I + 1);
    ByteEdits[I].Start := Length(UTF8Encode(Copy(Source, 1, E.Range.Start)));
    ByteEdits[I].After := Length(UTF8Encode(Copy(Source, 1, E.Range.EndOffset)));
    ByteEdits[I].Text := UTF8Encode(E.ReplacementText);
    ByteEdits[I].Lines := LineBreaks(E.ReplacementText) - LineBreaks(E.ExpectedText);
  end;
  View := nil;
  if Editor.EditViewCount > 0 then View := Editor.EditViews[0];
  if View <> nil then
  begin
    Cursor := View.CursorPos;
    View.ConvertPos(True, Cursor, CharPos);
    CursorByte := View.CharPosToPos(CharPos);
    StartByte := View.CharPosToPos(Editor.BlockStart);
    AfterByte := View.CharPosToPos(Editor.BlockAfter);
    BlockType := Editor.BlockType; BlockVisible := Editor.BlockVisible;
  end;
  Writer := Editor.CreateUndoableWriter;
  try
    for I := 0 to Integer(High(ByteEdits)) do
    begin
      Writer.CopyTo(ByteEdits[I].Start);
      Writer.DeleteTo(ByteEdits[I].After);
      Writer.Insert(PAnsiChar(ByteEdits[I].Text));
    end;
  finally Writer := nil; end;
  if View <> nil then
  begin
    // Outside the changed text the cursor keeps its column and follows its line;
    // converting through byte positions drifts near multi-byte characters.
    Inside := False; LineDelta := 0;
    for I := 0 to Integer(High(ByteEdits)) do
      if CursorByte >= ByteEdits[I].After then Inc(LineDelta, ByteEdits[I].Lines)
      else if CursorByte > ByteEdits[I].Start then Inside := True;
    if Inside then
    begin
      CharPos := View.PosToCharPos(MapByte(CursorByte));
      View.ConvertPos(False, Cursor, CharPos);
    end
    else Inc(Cursor.Line, LineDelta);
    View.CursorPos := Cursor;
    if BlockType <> btColumn then
    begin
      Editor.BlockStart := View.PosToCharPos(MapByte(StartByte));
      Editor.BlockAfter := View.PosToCharPos(MapByte(AfterByte));
      Editor.BlockType := BlockType; Editor.BlockVisible := BlockVisible;
    end;
  end;
end;

end.
