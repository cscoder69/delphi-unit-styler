unit CSCoder.Styler.Backup;

// Copies of units as they were saved on disk, taken right before a run changes
// them. One folder per run inside the project's .backup folder, repeating the
// project's folder structure. Independent of ToolsAPI.

interface

uses System.SysUtils, System.Classes;

type
  TBackupSession = class
  private
    FProjectDirectory, FDirectory: string;
    FStarted: TDateTime;
    FExternal: TStringList;
    procedure OpenDirectory;
    function ExternalDirectory: string;
    procedure SaveExternalIndex;
    procedure RemoveEmptyFolders(const Folder: string);
  public
    constructor Create(const ProjectDirectory: string);
    destructor Destroy; override;
    // Stores Bytes, the content of FileName as saved on disk, and returns the
    // path of the copy. Empty when this run already holds a copy of the unit.
    function Store(const FileName: string; const Bytes: TBytes): string;
    // Removes a copy whose unit ended up not being changed.
    procedure Discard(const CopyName: string);
    // Folder of this run; empty while it holds no copy.
    property Directory: string read FDirectory;
  end;

  // Run folders the tool left in the project's .backup, oldest first.
  TBackupRuns = record
    Folders: TArray<string>;
    Files: Integer;
    Bytes: Int64;
  end;

// Only folders named as the tool names a run are listed: anything else kept in
// .backup belongs to the user.
function FindBackupRuns(const ProjectDirectory: string): TBackupRuns;
// Removes the run folders, sparing the newest when asked, and .backup itself if
// nothing is left in it. Returns how many runs were removed.
function DeleteBackupRuns(const ProjectDirectory: string; KeepNewest: Boolean): Integer;

const
  BackupFolderName = '.backup';
  // Units of the project that sit outside the project folder.
  BackupExternalFolder = '_externas';
  BackupExternalIndex = 'origem.txt';

implementation

uses Winapi.Windows;

// Copies sit deeper than the units they come from: allow paths over MAX_PATH.
function LongPath(const Path: string): string;
begin
  if Path.StartsWith('\\?\') then Result := Path
  else if Path.StartsWith('\\') then Result := '\\?\UNC\' + Path.Substring(2)
  else Result := '\\?\' + Path;
end;

function Exists(const Path: string): Boolean;
begin
  Result := GetFileAttributes(PChar(LongPath(Path))) <> INVALID_FILE_ATTRIBUTES;
end;

procedure MakeFolders(const Path: string);
var Parent: string;
begin
  if (Path = '') or Exists(Path) then Exit;
  Parent := ExtractFileDir(Path);
  if Parent <> Path then MakeFolders(Parent);
  if not CreateDirectory(PChar(LongPath(Path)), nil) and (GetLastError <> ERROR_ALREADY_EXISTS) then
    RaiseLastOSError;
end;

procedure WriteBytes(const Path: string; const Bytes: TBytes);
var Handle: THandle; Stream: THandleStream;
begin
  // Opened here because TFileStream expands the name and breaks the long prefix.
  Handle := CreateFile(PChar(LongPath(Path)), GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
  if Handle = INVALID_HANDLE_VALUE then RaiseLastOSError;
  Stream := THandleStream.Create(Handle);
  try
    if Length(Bytes) > 0 then Stream.WriteBuffer(Bytes[0], Length(Bytes));
  finally Stream.Free; CloseHandle(Handle); end;
end;

function IsRunFolder(const Name: string): Boolean;
const Mask = '0000-00-00_00-00-00';
var I: Integer;
begin
  if Length(Name) < Length(Mask) then Exit(False);
  for I := 1 to Length(Mask) do
    if Mask[I] = '0' then
    begin
      if not CharInSet(Name[I], ['0'..'9']) then Exit(False);
    end
    else if Name[I] <> Mask[I] then Exit(False);
  // Another run of the same second: _2, _3...
  if Length(Name) = Length(Mask) then Exit(True);
  if (Name[Length(Mask) + 1] <> '_') or (Length(Name) = Length(Mask) + 1) then Exit(False);
  for I := Length(Mask) + 2 to Length(Name) do
    if not CharInSet(Name[I], ['0'..'9']) then Exit(False);
  Result := True;
end;

function IsFolder(const Data: TWin32FindData): Boolean;
begin Result := Data.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY <> 0; end;

// A link to a folder is not walked into: what it points to is not a copy.
function IsLink(const Data: TWin32FindData): Boolean;
begin Result := Data.dwFileAttributes and FILE_ATTRIBUTE_REPARSE_POINT <> 0; end;

procedure Measure(const Folder: string; var Files: Integer; var Bytes: Int64);
var Data: TWin32FindData; Handle: THandle; Name: string;
begin
  Handle := FindFirstFile(PChar(LongPath(Folder + PathDelim + '*')), Data);
  if Handle = INVALID_HANDLE_VALUE then Exit;
  try
    repeat
      Name := Data.cFileName;
      if (Name = '.') or (Name = '..') then Continue;
      if not IsFolder(Data) then
      begin Inc(Files); Inc(Bytes, Int64(Data.nFileSizeHigh) shl 32 or Data.nFileSizeLow); end
      else if not IsLink(Data) then Measure(Folder + PathDelim + Name, Files, Bytes);
    until not FindNextFile(Handle, Data);
  finally Winapi.Windows.FindClose(Handle); end;
end;

function RemoveTree(const Folder: string): Boolean;
var Data: TWin32FindData; Handle: THandle; Name, Path: string;
begin
  Handle := FindFirstFile(PChar(LongPath(Folder + PathDelim + '*')), Data);
  if Handle <> INVALID_HANDLE_VALUE then
    try
      repeat
        Name := Data.cFileName;
        if (Name = '.') or (Name = '..') then Continue;
        Path := Folder + PathDelim + Name;
        if IsFolder(Data) then
        begin
          if IsLink(Data) then RemoveDirectory(PChar(LongPath(Path))) else RemoveTree(Path);
        end
        else
        begin
          if Data.dwFileAttributes and FILE_ATTRIBUTE_READONLY <> 0 then
            SetFileAttributes(PChar(LongPath(Path)), FILE_ATTRIBUTE_NORMAL);
          Winapi.Windows.DeleteFile(PChar(LongPath(Path)));
        end;
      until not FindNextFile(Handle, Data);
    finally Winapi.Windows.FindClose(Handle); end;
  // Refused while something could not be removed from inside.
  Result := RemoveDirectory(PChar(LongPath(Folder)));
end;

function BackupRoot(const ProjectDirectory: string): string;
begin
  Result := IncludeTrailingPathDelimiter(ExpandFileName(ProjectDirectory)) + BackupFolderName;
end;

function FindBackupRuns(const ProjectDirectory: string): TBackupRuns;
var Data: TWin32FindData; Handle: THandle; Names: TStringList; Root, Name: string;
begin
  Result := Default(TBackupRuns);
  if ProjectDirectory = '' then Exit;
  Root := BackupRoot(ProjectDirectory);
  Handle := FindFirstFile(PChar(LongPath(Root + PathDelim + '*')), Data);
  if Handle = INVALID_HANDLE_VALUE then Exit;
  Names := TStringList.Create;
  try
    try
      repeat
        Name := Data.cFileName;
        if IsFolder(Data) and not IsLink(Data) and IsRunFolder(Name) then Names.Add(Name);
      until not FindNextFile(Handle, Data);
    finally Winapi.Windows.FindClose(Handle); end;
    // The name is the date and time of the run: sorted is oldest first.
    Names.Sort;
    for Name in Names do
    begin
      Result.Folders := Result.Folders + [Root + PathDelim + Name];
      Measure(Root + PathDelim + Name, Result.Files, Result.Bytes);
    end;
  finally Names.Free; end;
end;

function DeleteBackupRuns(const ProjectDirectory: string; KeepNewest: Boolean): Integer;
var Runs: TBackupRuns; I, Last: Integer;
begin
  Result := 0;
  Runs := FindBackupRuns(ProjectDirectory);
  Last := Integer(High(Runs.Folders));
  if KeepNewest then Dec(Last);
  for I := 0 to Last do
    if RemoveTree(Runs.Folders[I]) then Inc(Result);
  // Refused while .backup still holds a run or something of the user.
  if Length(Runs.Folders) > 0 then RemoveDirectory(PChar(LongPath(BackupRoot(ProjectDirectory))));
end;

constructor TBackupSession.Create(const ProjectDirectory: string);
begin
  inherited Create;
  FProjectDirectory := IncludeTrailingPathDelimiter(ExpandFileName(ProjectDirectory));
  FStarted := Now;
  FExternal := TStringList.Create;
end;

destructor TBackupSession.Destroy;
begin FExternal.Free; inherited; end;

procedure TBackupSession.OpenDirectory;
var Base, Name: string; N: Integer;
begin
  Base := FProjectDirectory + BackupFolderName + PathDelim + FormatDateTime('yyyy-mm-dd_hh-nn-ss', FStarted);
  // Two runs in the same second must not share a folder.
  Name := Base; N := 1;
  while Exists(Name) do
  begin Inc(N); Name := Format('%s_%d', [Base, N]); end;
  MakeFolders(Name);
  FDirectory := Name;
end;

function TBackupSession.ExternalDirectory: string;
begin Result := FDirectory + PathDelim + BackupExternalFolder; end;

procedure TBackupSession.SaveExternalIndex;
var Name: string;
begin
  Name := ExternalDirectory + PathDelim + BackupExternalIndex;
  if FExternal.Count > 0 then
    WriteBytes(Name, TEncoding.UTF8.GetPreamble + TEncoding.UTF8.GetBytes(FExternal.Text))
  else if Exists(Name) then Winapi.Windows.DeleteFile(PChar(LongPath(Name)));
end;

function TBackupSession.Store(const FileName: string; const Bytes: TBytes): string;
var Source, Relative, Name: string; N: Integer; IsExternal: Boolean;
begin
  Source := ExpandFileName(FileName);
  if FDirectory = '' then OpenDirectory;
  Relative := ExtractRelativePath(FProjectDirectory, Source);
  IsExternal := (Relative = Source) or Relative.StartsWith('..' + PathDelim) or
    Relative.StartsWith('\') or (ExtractFileDrive(Relative) <> '');
  if IsExternal then
  begin
    // No path relative to the project: kept by file name, origin written down.
    Name := ExtractFileName(Source); N := 1;
    while Exists(ExternalDirectory + PathDelim + Name) do
    begin
      Inc(N);
      Name := Format('%s (%d)%s', [ChangeFileExt(ExtractFileName(Source), ''), N, ExtractFileExt(Source)]);
    end;
    Result := ExternalDirectory + PathDelim + Name;
  end
  else
  begin
    Result := FDirectory + PathDelim + Relative;
    if Exists(Result) then Exit('');
  end;
  try
    MakeFolders(ExtractFileDir(Result));
    WriteBytes(Result, Bytes);
    if IsExternal then
    begin
      FExternal.Add(Name + #9 + Source);
      SaveExternalIndex;
    end;
  except
    Discard(Result);
    raise;
  end;
end;

procedure TBackupSession.Discard(const CopyName: string);
var I: Integer;
begin
  if (CopyName = '') or (FDirectory = '') then Exit;
  if Exists(CopyName) then Winapi.Windows.DeleteFile(PChar(LongPath(CopyName)));
  if SameText(ExtractFileDir(CopyName), ExternalDirectory) then
  begin
    for I := FExternal.Count - 1 downto 0 do
      if FExternal[I].StartsWith(ExtractFileName(CopyName) + #9) then FExternal.Delete(I);
    SaveExternalIndex;
  end;
  RemoveEmptyFolders(ExtractFileDir(CopyName));
  if not Exists(FDirectory) then FDirectory := '';
end;

procedure TBackupSession.RemoveEmptyFolders(const Folder: string);
var Current: string;
begin
  // RemoveDirectory refuses a folder that still holds something: that ends the walk.
  Current := Folder;
  while (Length(Current) > Length(FProjectDirectory)) and
    RemoveDirectory(PChar(LongPath(Current))) do Current := ExtractFileDir(Current);
end;

end.
