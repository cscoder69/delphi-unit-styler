unit CSCoder.Styler.ProjectSettings;

interface

uses System.JSON, CSCoder.Styler.Types;

type
  // One versioned JSON file, replaced through a temporary file with a backup,
  // and never overwritten when it changed since it was read.
  TSettingsFile = class
  private
    FPath, FSnapshot: string;
    FExisted, FLoaded: Boolean;
  public
    constructor Create(const Path: string);
    // Returns nil when the file does not exist yet. The caller owns the result.
    function Read: TJSONObject;
    procedure Write(Root: TJSONObject);
    property FileName: string read FPath;
  end;

  // Settings live in the user profile:
  //   D<version>\settings.json    rules of the add-on, one file per Delphi version
  //   projects\<name>.<id>.json   what belongs to one project, whatever the Delphi
  // A project is identified by the ProjectGuid of its .dproj, so it keeps its
  // settings when its folder is moved or renamed; without one, by its path.
  // Without a project file only the add-on rules are read and written.
  TProjectSettings = class
  private
    FAddon, FProject, FLegacy: TSettingsFile;
    FDirectory, FProjectFile: string;
    FLoaded: Boolean;
  public
    constructor Create(const ProjectFile: string; const BaseDirectory: string = '');
    destructor Destroy; override;
    function Load: TUsesOptions;
    procedure Save(const Options: TUsesOptions);
    function AddonFileName: string;
    function ProjectFileName: string;
    property Directory: string read FDirectory;
    // Folder that holds the version folders and the projects folder.
    function RootDirectory: string;
  end;

// Identifier of a project for its settings file: the ProjectGuid of the .dproj
// next to ProjectFile, or a hash of the path when there is none.
function ProjectIdentity(const ProjectFile: string): string;
// Units known to declare the same names as others (RegisterClass, DeleteFile,
// TBitmap...): protected from reordering unless the user changes the list.
function DefaultProtectedUnits: TArray<string>;
function DefaultUsesOptions: TUsesOptions;
// %LOCALAPPDATA%\CSCoder\UnitStyler\D<version>, for the compiler in use.
function DefaultSettingsDirectory: string;

implementation

uses System.SysUtils, System.Classes, System.IOUtils,
  System.Generics.Collections, CSCoder.Styler.UsesOrganizer, CSCoder.Styler.Strings;

function DefaultProtectedUnits: TArray<string>;
begin
  Result := ['Winapi.*', 'System.*', 'Vcl.*', 'FMX.*', 'Data.*',
    'Windows', 'Messages', 'SysUtils', 'Classes', 'Variants', 'Graphics', 'Controls', 'Forms', 'Dialogs', 'DB'];
end;

function DefaultUsesOptions: TUsesOptions;
begin
  Result := Default(TUsesOptions);
  Result.ProtectedUnits := DefaultProtectedUnits;
  Result.AutoSaveUnits := True;
  Result.BackupUnits := True;
  Result.Shortcut := DefaultOrganizeShortcut;
  Result.SortFirstNameOnly := True;
  Result.OneUnitPerLine := True;
  Result.MaxLineWidth := DefaultLineWidth;
  Result.IndentationEnabled := True;
  Result.Indentation := '  ';
end;

function DefaultSettingsDirectory: string;
var Base, Tag: string;
begin
  // Same layout as the other CS.Coder tools: local profile, one folder per Delphi.
  {$IF CompilerVersion >= 38.0}
  Tag := 'D' + IntToStr(Trunc(CompilerVersion) - 24);
  {$ELSEIF CompilerVersion >= 37.0}
  Tag := 'D13';
  {$ELSEIF CompilerVersion >= 36.0}
  Tag := 'D12';
  {$ELSE}
  Tag := 'D11';
  {$IFEND}
  Base := GetEnvironmentVariable('LOCALAPPDATA');
  if Base = '' then Base := TPath.GetHomePath;
  Result := TPath.Combine(TPath.Combine(TPath.Combine(Base, 'CSCoder'), 'UnitStyler'), Tag);
end;

// Short stable identifier so projects with the same name do not share a file.
function PathId(const FileName: string): string;
var C: Char; Hash: UInt32;
begin
  Hash := 2166136261;
  for C in LowerCase(ExpandFileName(FileName)) do
    Hash := UInt32(((UInt64(Hash) xor Ord(C)) * 16777619) and $FFFFFFFF);
  Result := IntToHex(Hash, 8);
end;

function ProjectIdentity(const ProjectFile: string): string;
const OpenTag = '<projectguid>'; CloseTag = '</projectguid>';
var Name, Content, Lower: string; First, Last: Integer; C: Char;
begin
  Result := '';
  Name := ChangeFileExt(ProjectFile, '.dproj');
  if TFile.Exists(Name) then
    try
      Content := TFile.ReadAllText(Name);
      Lower := LowerCase(Content);
      First := Pos(OpenTag, Lower);
      Last := Pos(CloseTag, Lower);
      if (First > 0) and (Last > First) then
        for C in Copy(Content, First + Length(OpenTag), Last - First - Length(OpenTag)) do
          if CharInSet(C, ['0'..'9', 'a'..'f', 'A'..'F', '-']) then Result := Result + UpCase(C);
    except
      // An unreadable project file falls back to the path.
      Result := '';
    end;
  // A real GUID only; anything else would make unrelated projects collide.
  if Length(Result) <> 36 then Result := PathId(ProjectFile);
end;

function StringsToJson(const Values: TArray<string>): TJSONArray;
var V: string;
begin
  Result := TJSONArray.Create;
  for V in Values do Result.Add(V);
end;

function ReadStrings(Root: TJSONObject; const Key: string): TArray<string>;
var A: TJSONArray; V: TJSONValue;
begin
  Result := nil;
  if Root.GetValue(Key) = nil then Exit;
  if not (Root.GetValue(Key) is TJSONArray) then raise EConvertError.Create(L(stErrCfgList, [Key]));
  A := TJSONArray(Root.GetValue(Key));
  for V in A do
  begin
    if not (V is TJSONString) then raise EConvertError.Create(L(stErrCfgItem, [Key]));
    Result := Result + [V.Value];
  end;
end;

function ReadBool(Root: TJSONObject; const Key: string; DefaultValue: Boolean): Boolean;
begin
  if Root.GetValue(Key) = nil then Exit(DefaultValue);
  if not (Root.GetValue(Key) is TJSONBool) then raise EConvertError.Create(L(stErrCfgValue, [Key]));
  Result := TJSONBool(Root.GetValue(Key)).AsBoolean;
end;

{ TSettingsFile }

constructor TSettingsFile.Create(const Path: string);
begin
  inherited Create;
  FPath := Path;
end;

function TSettingsFile.Read: TJSONObject;
var Parsed: TJSONValue;
begin
  Result := nil;
  FLoaded := False;
  FExisted := TFile.Exists(FPath);
  FSnapshot := '';
  if not FExisted then begin FLoaded := True; Exit; end;
  FSnapshot := TFile.ReadAllText(FPath, TEncoding.UTF8);
  Parsed := TJSONObject.ParseJSONValue(FSnapshot);
  try
    if not (Parsed is TJSONObject) then raise EConvertError.Create(L(stErrCfgJson, [FPath]));
    if not (TJSONObject(Parsed).GetValue('schemaVersion') is TJSONNumber) or
      (TJSONObject(Parsed).GetValue<Integer>('schemaVersion', 0) <> 1) then
      raise EConvertError.Create(L(stErrCfgVersion, [FPath]));
  except
    Parsed.Free;
    raise;
  end;
  Result := TJSONObject(Parsed);
  FLoaded := True;
end;

procedure TSettingsFile.Write(Root: TJSONObject);
var TempName, Current: string; Id: TGUID;
begin
  if not FLoaded then raise EInvalidOperation.Create(L(stErrCfgUnread));
  Current := Root.ToJSON;
  if FExisted <> TFile.Exists(FPath) then raise EInvalidOperation.Create(L(stErrCfgChanged));
  if FExisted and (TFile.ReadAllText(FPath, TEncoding.UTF8) <> FSnapshot) then
    raise EInvalidOperation.Create(L(stErrCfgChanged));
  // Nothing to write: keep the file and its backup as they are.
  if FExisted and (Current = FSnapshot) then Exit;
  ForceDirectories(ExtractFileDir(FPath));
  CreateGUID(Id); TempName := FPath + '.' + GUIDToString(Id) + '.tmp';
  try
    TFile.WriteAllText(TempName, Current, TEncoding.UTF8);
    // Recheck immediately before replacement, not only before serialization.
    if FExisted <> TFile.Exists(FPath) then raise EInvalidOperation.Create(L(stErrCfgChanged));
    if FExisted then
    begin
      if TFile.ReadAllText(FPath, TEncoding.UTF8) <> FSnapshot then raise EInvalidOperation.Create(L(stErrCfgChanged));
      TFile.Replace(TempName, FPath, FPath + '.bak');
    end
    else TFile.Move(TempName, FPath);
    FSnapshot := Current; FExisted := True;
  finally
    if TFile.Exists(TempName) then TFile.Delete(TempName);
  end;
end;

{ TProjectSettings }

constructor TProjectSettings.Create(const ProjectFile, BaseDirectory: string);
var Id, Folder, Name, Found: string;
begin
  inherited Create;
  FProjectFile := ProjectFile;
  FDirectory := BaseDirectory;
  if FDirectory = '' then FDirectory := DefaultSettingsDirectory;
  FAddon := TSettingsFile.Create(TPath.Combine(FDirectory, 'settings.json'));
  if ProjectFile = '' then Exit;
  Id := ProjectIdentity(ProjectFile);
  Folder := TPath.Combine(RootDirectory, 'projects');
  Name := ChangeFileExt(ExtractFileName(ProjectFile), '') + '.' + Id + '.json';
  // The identifier decides: a project whose file was renamed keeps its settings.
  if TDirectory.Exists(Folder) then
    for Found in TDirectory.GetFiles(Folder, '*.' + Id + '.json') do
    begin Name := ExtractFileName(Found); Break; end;
  FProject := TSettingsFile.Create(TPath.Combine(Folder, Name));
  // Where earlier builds kept it: inside the version folder, named by the path.
  FLegacy := TSettingsFile.Create(TPath.Combine(TPath.Combine(FDirectory, 'projects'),
    ChangeFileExt(ExtractFileName(ProjectFile), '') + '.' + PathId(ProjectFile) + '.json'));
end;

function TProjectSettings.RootDirectory: string;
begin Result := ExtractFileDir(ExcludeTrailingPathDelimiter(FDirectory)); end;

destructor TProjectSettings.Destroy;
begin
  FLegacy.Free; FProject.Free; FAddon.Free;
  inherited;
end;

function TProjectSettings.AddonFileName: string;
begin Result := FAddon.FileName; end;

function TProjectSettings.ProjectFileName: string;
begin if FProject <> nil then Result := FProject.FileName else Result := ''; end;

function TProjectSettings.Load: TUsesOptions;
var Root, Group: TJSONObject; Groups: TJSONArray; I: Integer;
begin
  Result := DefaultUsesOptions;
  FLoaded := False;
  Root := FAddon.Read;
  try
    if Root <> nil then
    begin
      Result.AutoSaveUnits := ReadBool(Root, 'autoSaveUnits', True);
      Result.BackupUnits := ReadBool(Root, 'backupUnits', True);
      if Root.GetValue('language') <> nil then
      begin
        if not (Root.GetValue('language') is TJSONString) then raise EConvertError.Create(L(stErrCfgValue, ['language']));
        Result.Language := TJSONString(Root.GetValue('language')).Value;
      end;
      if Root.GetValue('shortcut') <> nil then
      begin
        if not (Root.GetValue('shortcut') is TJSONNumber) then raise EConvertError.Create(L(stErrCfgValue, ['shortcut']));
        Result.Shortcut := TJSONNumber(Root.GetValue('shortcut')).AsInt;
      end;
      Result.OneUnitPerLine := ReadBool(Root, 'oneUnitPerLine', True);
      Result.WrapUnits := ReadBool(Root, 'wrapUnits', False);
      if Root.GetValue('maxLineWidth') <> nil then
      begin
        if not (Root.GetValue('maxLineWidth') is TJSONNumber) then raise EConvertError.Create(L(stErrCfgValue, ['maxLineWidth']));
        Result.MaxLineWidth := TJSONNumber(Root.GetValue('maxLineWidth')).AsInt;
      end;
      Result.Alphabetical := ReadBool(Root, 'alphabetical', False);
      Result.SortFirstNameOnly := ReadBool(Root, 'alphabeticalFirstNameOnly', True);
      // Absent: the factory list. Present, even empty: what the user chose.
      if Root.GetValue('protectedUnits') <> nil then Result.ProtectedUnits := ReadStrings(Root, 'protectedUnits');
      Result.IndentationEnabled := ReadBool(Root, 'indentationEnabled', True);
      if Root.GetValue('indentation') <> nil then
      begin
        if not (Root.GetValue('indentation') is TJSONString) then raise EConvertError.Create(L(stErrCfgValue, ['indentation']));
        Result.Indentation := Root.GetValue('indentation').Value;
      end;
      Result.PrioritiesEnabled := ReadBool(Root, 'prioritiesEnabled', False);
      Result.Priorities := ReadStrings(Root, 'priorities');
      Result.GroupingEnabled := ReadBool(Root, 'groupingEnabled', False);
      Result.BlankLinesBetweenGroups := ReadBool(Root, 'blankLinesBetweenGroups', False);
      Result.BlankBeforeSections := ReadBool(Root, 'blankBeforeSections', False);
      Result.BlankAfterSections := ReadBool(Root, 'blankAfterSections', False);
      if ReadBool(Root, 'ungroupedFirst', False) then Result.UngroupedPosition := upFirst;
      if Root.GetValue('groups') <> nil then
      begin
        if not (Root.GetValue('groups') is TJSONArray) then raise EConvertError.Create(L(stErrCfgValue, ['groups']));
        Groups := TJSONArray(Root.GetValue('groups'));
        SetLength(Result.Groups, Groups.Count);
        for I := 0 to Groups.Count - 1 do
        begin
          if not (Groups.Items[I] is TJSONObject) then raise EConvertError.Create(L(stErrCfgGroup));
          Group := TJSONObject(Groups.Items[I]);
          if not (Group.GetValue('name') is TJSONString) then raise EConvertError.Create(L(stErrCfgGroupName));
          Result.Groups[I].Name := Group.GetValue('name').Value;
          Result.Groups[I].Selectors := ReadStrings(Group, 'selectors');
        end;
      end;
    end;
  finally Root.Free; end;
  Root := nil;
  if FProject <> nil then Root := FProject.Read;
  // Not saved in the shared folder yet: start from what an earlier build kept.
  // The old file is only read; the next save writes the new one.
  if (FProject <> nil) and (Root = nil) then Root := FLegacy.Read;
  try
    if Root <> nil then
    begin
      Result.ExcludedUnits := ReadStrings(Root, 'excludedUnits');
      Result.IgnoredPaths := ReadStrings(Root, 'ignoredPaths');
      if ReadBool(Root, 'excludeInterface', False) then Include(Result.ExcludedSections, usInterface);
      if ReadBool(Root, 'excludeImplementation', False) then Include(Result.ExcludedSections, usImplementation);
    end;
  finally Root.Free; end;
  ValidateUsesOptions(Result);
  FLoaded := True;
end;

procedure TProjectSettings.Save(const Options: TUsesOptions);
var Addon, Project, Group: TJSONObject; Groups: TJSONArray; G: TUsesGroup;

  procedure Bool(Root: TJSONObject; const Key: string; Value: Boolean);
  begin Root.AddPair(Key, TJSONBool.Create(Value)); end;

begin
  if not FLoaded then raise EInvalidOperation.Create(L(stErrCfgUnread));
  ValidateUsesOptions(Options);
  Addon := TJSONObject.Create; Project := TJSONObject.Create;
  try
    Addon.AddPair('schemaVersion', TJSONNumber.Create(1));
    Bool(Addon, 'autoSaveUnits', Options.AutoSaveUnits);
    Bool(Addon, 'backupUnits', Options.BackupUnits);
    // Absent means following the language of Windows.
    if Options.Language <> '' then Addon.AddPair('language', Options.Language);
    Addon.AddPair('shortcut', TJSONNumber.Create(Options.Shortcut));
    Bool(Addon, 'oneUnitPerLine', Options.OneUnitPerLine);
    Bool(Addon, 'wrapUnits', Options.WrapUnits);
    Addon.AddPair('maxLineWidth', TJSONNumber.Create(Options.MaxLineWidth));
    Bool(Addon, 'alphabetical', Options.Alphabetical);
    Bool(Addon, 'alphabeticalFirstNameOnly', Options.SortFirstNameOnly);
    Addon.AddPair('protectedUnits', StringsToJson(Options.ProtectedUnits));
    Bool(Addon, 'indentationEnabled', Options.IndentationEnabled);
    Addon.AddPair('indentation', Options.Indentation);
    Bool(Addon, 'prioritiesEnabled', Options.PrioritiesEnabled);
    Addon.AddPair('priorities', StringsToJson(Options.Priorities));
    Bool(Addon, 'groupingEnabled', Options.GroupingEnabled);
    Bool(Addon, 'blankLinesBetweenGroups', Options.BlankLinesBetweenGroups);
    Bool(Addon, 'blankBeforeSections', Options.BlankBeforeSections);
    Bool(Addon, 'blankAfterSections', Options.BlankAfterSections);
    Bool(Addon, 'ungroupedFirst', Options.UngroupedPosition = upFirst);
    Groups := TJSONArray.Create; Addon.AddPair('groups', Groups);
    for G in Options.Groups do
    begin
      Group := TJSONObject.Create; Groups.AddElement(Group);
      Group.AddPair('name', G.Name); Group.AddPair('selectors', StringsToJson(G.Selectors));
    end;
    Project.AddPair('schemaVersion', TJSONNumber.Create(1));
    // Informative only: lets a person recognize the file when backing it up.
    Project.AddPair('projectFile', FProjectFile);
    Bool(Project, 'excludeInterface', usInterface in Options.ExcludedSections);
    Bool(Project, 'excludeImplementation', usImplementation in Options.ExcludedSections);
    Project.AddPair('excludedUnits', StringsToJson(Options.ExcludedUnits));
    Project.AddPair('ignoredPaths', StringsToJson(Options.IgnoredPaths));
    FAddon.Write(Addon);
    if FProject <> nil then FProject.Write(Project);
  finally Project.Free; Addon.Free; end;
end;

end.
