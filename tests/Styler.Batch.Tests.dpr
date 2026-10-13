program StylerBatchTests;

// Rewriting of units that are closed in the IDE: encoding, byte order mark and
// line breaks must survive. Without parameters runs the fixed cases. With
// <source folder> <work folder> copies every .pas to the work folder and
// organizes the copies on disk, checking each rewritten file byte by byte.

{$APPTYPE CONSOLE}
{$RANGECHECKS ON}
{$WARN SYMBOL_PLATFORM OFF}

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Types, System.Diagnostics,
  System.Generics.Collections, Winapi.Windows,
  CSCoder.Styler.Types in '..\src\core\CSCoder.Styler.Types.pas',
  CSCoder.Styler.Lexer in '..\src\core\CSCoder.Styler.Lexer.pas',
  CSCoder.Styler.UsesParser in '..\src\core\CSCoder.Styler.UsesParser.pas',
  CSCoder.Styler.Strings in '..\src\i18n\CSCoder.Styler.Strings.pas',
  CSCoder.Styler.UsesOrganizer in '..\src\core\CSCoder.Styler.UsesOrganizer.pas',
  CSCoder.Styler.Engine in '..\src\core\CSCoder.Styler.Engine.pas',
  CSCoder.Styler.SourceFile in '..\src\ide\CSCoder.Styler.SourceFile.pas',
  CSCoder.Styler.Backup in '..\src\ide\CSCoder.Styler.Backup.pas';

var Checks: Integer;

procedure Check(Value: Boolean; const Message: string);
begin Inc(Checks); if not Value then raise Exception.Create(Message); end;

function SameBytes(const A, B: TBytes; Count: Integer = -1): Boolean;
begin
  if Count < 0 then
  begin
    if Length(A) <> Length(B) then Exit(False);
    Count := Integer(Length(A));
  end;
  Result := (Count = 0) or ((Length(A) >= Count) and (Length(B) >= Count) and
    CompareMem(@A[0], @B[0], Count));
end;

function Options: TUsesOptions;
begin
  Result := Default(TUsesOptions);
  Result.Alphabetical := True; Result.OneUnitPerLine := True;
  Result.IndentationEnabled := True; Result.Indentation := '  ';
end;

function EncodingName(Encoding: TSourceEncoding): string;
const Names: array[TSourceEncoding] of string = ('ANSI', 'UTF-8 sem BOM ou ASCII', 'UTF-8 com BOM', 'UTF-16 LE', 'UTF-16 BE');
begin Result := Names[Encoding]; end;

// Organizes one file on disk and proves that nothing but the proposed text
// changed. Returns False when the unit had nothing to change.
function OrganizeOnDisk(const FileName: string): Boolean;
var Original, Written: TSourceFile; Proposal: TStylerProposal; Expected: string;
  First, Last: TSourceEdit; PrefixBytes, SuffixBytes, Skip: Integer; Head, Tail: TBytes;
begin
  Original := LoadSourceFile(FileName);
  Proposal := AnalyzeUses(Original.Text, Options);
  if Length(Proposal.Edits) = 0 then Exit(False);
  Expected := Proposal.ApplyTo(Original.Text);
  SaveSourceFile(Original, Expected);
  Written := LoadSourceFile(FileName);
  Check(Written.Encoding = Original.Encoding, 'Encoding changed: ' + FileName);
  Check(Written.Text = Expected, 'Content differs from the proposal: ' + FileName);
  // Bytes before the first change and after the last one are the original bytes.
  First := Proposal.Edits[0]; Last := Proposal.Edits[High(Proposal.Edits)];
  Head := EncodeSource(Copy(Original.Text, 1, First.Range.Start), Original.Encoding);
  PrefixBytes := Integer(Length(Head));
  Check(SameBytes(Original.Bytes, Written.Bytes, PrefixBytes), 'Bytes before the uses changed: ' + FileName);
  Skip := Integer(Length(EncodeSource('', Original.Encoding)));
  Tail := EncodeSource(Copy(Original.Text, Last.Range.EndOffset + 1, MaxInt), Original.Encoding);
  SuffixBytes := Integer(Length(Tail)) - Skip;
  Check((SuffixBytes <= Length(Written.Bytes)) and (SuffixBytes <= Length(Original.Bytes)) and
    ((SuffixBytes = 0) or CompareMem(@Original.Bytes[Length(Original.Bytes) - SuffixBytes],
    @Written.Bytes[Length(Written.Bytes) - SuffixBytes], SuffixBytes)), 'Bytes after the uses changed: ' + FileName);
  Check(Length(AnalyzeUses(Written.Text, Options).Edits) = 0, 'Second run proposes changes: ' + FileName);
  Result := True;
end;

procedure FixedCases(const Folder: string);
const
  Body = 'unit U;%0:s// a'#$00E7#$00E3'o %1:s%0:sinterface%0:suses%0:s  Zeta, Alfa;%0:simplementation%0:s// fim '#$00E9'%0:send.';
  Sorted = 'uses%0:s  Alfa,%0:s  Zeta;';
var Encoding: TSourceEncoding; NL, Text, Name, Extra: string; Loaded: TSourceFile;
  Bytes: TBytes; Rejected: Boolean; Kind: Integer;
begin
  TDirectory.CreateDirectory(Folder);
  for Encoding := Low(TSourceEncoding) to High(TSourceEncoding) do
    for Kind := 0 to 1 do
    begin
      if Kind = 0 then NL := #13#10 else NL := #10;
      // A character outside the ANSI code page only where the encoding holds it.
      Extra := '';
      if Encoding <> seAnsi then Extra := #$D83D#$DE00;
      Text := Format(Body, [NL, Extra]);
      Name := TPath.Combine(Folder, Format('case-%d-%d.pas', [Ord(Encoding), Kind]));
      Bytes := EncodeSource(Text, Encoding);
      TFile.WriteAllBytes(Name, Bytes);
      Loaded := LoadSourceFile(Name);
      Check(Loaded.Encoding = Encoding, 'Detected encoding ' + EncodingName(Encoding));
      Check(Loaded.Text = Text, 'Decoded text ' + EncodingName(Encoding));
      Check(OrganizeOnDisk(Name), 'Unit organized ' + EncodingName(Encoding));
      Loaded := LoadSourceFile(Name);
      Check(Loaded.Encoding = Encoding, 'Encoding kept ' + EncodingName(Encoding));
      Check(Pos(Format(Sorted, [NL]), Loaded.Text) > 0, 'Uses organized with the same line break');
      Check((NL = #13#10) or (Pos(#13, Loaded.Text) = 0), 'LF file gained no CR');
      Check(Pos('a'#$00E7#$00E3'o ' + Extra, Loaded.Text) > 0, 'Accents and emoji intact ' + EncodingName(Encoding));
      Check(not OrganizeOnDisk(Name), 'Organized unit is left alone');
    end;
  // Pure ASCII has no mark to keep and gains none.
  Name := TPath.Combine(Folder, 'ascii.pas');
  TFile.WriteAllBytes(Name, TEncoding.ASCII.GetBytes('unit U; interface uses B, A; implementation end.'));
  Check(OrganizeOnDisk(Name), 'ASCII unit organized');
  Bytes := TFile.ReadAllBytes(Name);
  Check((Bytes[0] = Ord('u')) and (TEncoding.ASCII.GetString(Bytes) = 'unit U; interface uses'#13#10'  A,'#13#10'  B; implementation end.'),
    'ASCII unit stays without mark');
  // A UTF-8 mark over bytes that are not UTF-8 is never rewritten.
  Name := TPath.Combine(Folder, 'broken.pas');
  Bytes := TBytes.Create($EF, $BB, $BF) + TEncoding.ANSI.GetBytes('unit U; interface uses B, A; // a'#$00E7#$00E3'o'#13#10'implementation end.');
  TFile.WriteAllBytes(Name, Bytes);
  Rejected := False;
  try LoadSourceFile(Name); except on E: ESourceEncoding do Rejected := True; end;
  Check(Rejected and SameBytes(TFile.ReadAllBytes(Name), Bytes), 'Broken encoding rejected and untouched');
  // A file changed after the analysis is not overwritten.
  Name := TPath.Combine(Folder, 'changed.pas');
  TFile.WriteAllText(Name, 'unit U; interface uses B, A; implementation end.', TEncoding.ANSI);
  Loaded := LoadSourceFile(Name);
  TFile.WriteAllText(Name, 'unit U; interface uses C, B, A; implementation end.', TEncoding.ANSI);
  Rejected := False;
  try SaveSourceFile(Loaded, 'unit U; interface uses A, B; implementation end.'); except on E: Exception do Rejected := True; end;
  Check(Rejected and (Pos('uses C, B, A', TFile.ReadAllText(Name, TEncoding.ANSI)) > 0), 'Changed file not overwritten');
  // Text that the original encoding cannot hold is refused.
  Name := TPath.Combine(Folder, 'ansi.pas');
  TFile.WriteAllBytes(Name, EncodeSource('unit U; // a'#$00E7#$00E3'o'#13#10'interface uses B, A; implementation end.', seAnsi));
  Loaded := LoadSourceFile(Name);
  Check(Loaded.Encoding = seAnsi, 'ANSI detected by its accents');
  Rejected := False;
  try SaveSourceFile(Loaded, Loaded.Text + #$D83D#$DE00); except on E: ESourceEncoding do Rejected := True; end;
  Check(Rejected and SameBytes(TFile.ReadAllBytes(Name), Loaded.Bytes), 'Text outside the encoding refused');
  // A read-only file is reported, not forced.
  Name := TPath.Combine(Folder, 'readonly.pas');
  TFile.WriteAllText(Name, 'unit U; interface uses B, A; implementation end.', TEncoding.ANSI);
  Loaded := LoadSourceFile(Name);
  TFile.SetAttributes(Name, [TFileAttribute.faReadOnly]);
  Rejected := False;
  try SaveSourceFile(Loaded, 'unit U; interface uses A, B; implementation end.'); except on E: Exception do Rejected := True; end;
  TFile.SetAttributes(Name, []);
  Check(Rejected and SameBytes(TFile.ReadAllBytes(Name), Loaded.Bytes), 'Read-only file left as it was');
  Check(Length(TDirectory.GetFiles(Folder, '*.tmp')) = 0, 'No temporary file left behind');
end;

// Reads through the extended prefix: a backup copy may sit beyond MAX_PATH.
function ReadLong(const Name: string): TBytes;
var Handle: THandle; Stream: THandleStream;
begin
  Handle := FileOpen('\\?\' + Name, fmOpenRead or fmShareDenyNone);
  if Handle = INVALID_HANDLE_VALUE then RaiseLastOSError;
  Stream := THandleStream.Create(Handle);
  try
    SetLength(Result, Integer(Stream.Size));
    if Length(Result) > 0 then Stream.ReadBuffer(Result[0], Length(Result));
  finally Stream.Free; FileClose(Handle); end;
end;

// Copies taken before a run changes a unit: one folder per run in the project's
// .backup, same structure as the project, exact bytes, nothing left for a unit
// that ended up unchanged.
procedure BackupCases(const Folder: string);
var Project, Outside, Name, Inside, External, Again, Other, Deep, Index, Stamp: string;
  Session, Second: TBackupSession; A, B: TBytes; N: Integer;
begin
  Project := TPath.Combine(Folder, 'proj'); Outside := TPath.Combine(Folder, 'fora');
  TDirectory.CreateDirectory(TPath.Combine(Project, 'Vendas'));
  TDirectory.CreateDirectory(TPath.Combine(Outside, 'a'));
  TDirectory.CreateDirectory(TPath.Combine(Outside, 'b'));
  A := EncodeSource('unit uPedidos; // a'#$00E7#$00E3'o'#10'interface uses B, A; implementation end.', seAnsi);
  B := EncodeSource('unit uComum; interface implementation end.', seUtf8Bom);
  Name := TPath.Combine(Project, 'Vendas\uPedidos.pas');
  TFile.WriteAllBytes(Name, A);
  TFile.WriteAllBytes(TPath.Combine(Outside, 'a\uComum.pas'), B);
  TFile.WriteAllBytes(TPath.Combine(Outside, 'b\uComum.pas'), A);
  Session := TBackupSession.Create(Project);
  Second := TBackupSession.Create(Project);
  try
    Check((Session.Directory = '') and not TDirectory.Exists(TPath.Combine(Project, BackupFolderName)),
      'Nothing is created before the first copy');
    Inside := Session.Store(Name, A);
    Stamp := ExtractFileName(Session.Directory);
    Check(SameText(ExtractFileDir(Session.Directory), TPath.Combine(Project, BackupFolderName)) and
      (Length(Stamp) = 19) and (Stamp[11] = '_'), 'Run folder named by date and time inside .backup: ' + Session.Directory);
    Check(SameText(Inside, TPath.Combine(Session.Directory, 'Vendas\uPedidos.pas')), 'Copy repeats the project structure: ' + Inside);
    Check(SameBytes(TFile.ReadAllBytes(Inside), A) and SameBytes(TFile.ReadAllBytes(Name), A), 'Copy has the exact bytes, unit untouched');
    Check(Session.Store(Name, B) = '', 'A unit is copied once per run');
    Check(SameBytes(TFile.ReadAllBytes(Inside), A), 'First copy of the run is kept');
    // Units of the project outside its folder: by name, with the origin written down.
    External := Session.Store(TPath.Combine(Outside, 'a\uComum.pas'), B);
    Again := Session.Store(TPath.Combine(Outside, 'b\uComum.pas'), A);
    Check(SameText(External, TPath.Combine(Session.Directory, BackupExternalFolder + '\uComum.pas')), 'External unit copy: ' + External);
    Check(SameText(Again, TPath.Combine(Session.Directory, BackupExternalFolder + '\uComum (2).pas')), 'Same name from another folder: ' + Again);
    Check(SameBytes(TFile.ReadAllBytes(External), B) and SameBytes(TFile.ReadAllBytes(Again), A), 'External copies have the exact bytes');
    Index := TFile.ReadAllText(TPath.Combine(Session.Directory, BackupExternalFolder + '\' + BackupExternalIndex), TEncoding.UTF8);
    Check((Pos('uComum.pas'#9 + TPath.Combine(Outside, 'a\uComum.pas'), Index) > 0) and
      (Pos('uComum (2).pas'#9 + TPath.Combine(Outside, 'b\uComum.pas'), Index) > 0), 'Origin of external units written down: ' + Index);
    // Another run in the same second gets its own folder.
    Other := Second.Store(Name, A);
    Check((Second.Directory <> '') and not SameText(Second.Directory, Session.Directory) and
      SameBytes(TFile.ReadAllBytes(Other), A), 'Second run has its own folder: ' + Second.Directory);
    Second.Discard(Other);
    Check((Second.Directory = '') and not TFile.Exists(Other) and TDirectory.Exists(Session.Directory),
      'Run with every copy discarded leaves no folder');
    Session.Discard(Again);
    Index := TFile.ReadAllText(TPath.Combine(Session.Directory, BackupExternalFolder + '\' + BackupExternalIndex), TEncoding.UTF8);
    Check(not TFile.Exists(Again) and (Pos('(2)', Index) = 0) and (Pos('uComum.pas'#9, Index) > 0), 'Discarded external copy leaves the list');
    // A unit near the path limit: its copy is deeper and still has to be written.
    N := 236 - Integer(Length(Project));
    if N > 0 then
    begin
      Deep := TPath.Combine(Project, StringOfChar('p', N));
      TDirectory.CreateDirectory(Deep);
      Deep := TPath.Combine(Deep, 'uLonga.pas');
      TFile.WriteAllBytes(Deep, B);
      Other := Session.Store(Deep, B);
      Check((Length(Other) > 260) and SameBytes(ReadLong(Other), B), 'Copy beyond the path limit: ' + IntToStr(Length(Other)));
      Session.Discard(Other);
      Check(TDirectory.Exists(Session.Directory) and not FileExists('\\?\' + Other) and
        not DirectoryExists('\\?\' + ExtractFileDir(Other)), 'Long copy discarded with its folder');
    end;
    Session.Discard(External);
    Check(TFile.Exists(Inside) and not TDirectory.Exists(TPath.Combine(Session.Directory, BackupExternalFolder)),
      'Empty external folder removed, other copies kept');
    Session.Discard(Inside);
    Check((Session.Directory = '') and not TDirectory.Exists(TPath.Combine(Project, BackupFolderName)),
      'Nothing left when no unit was changed');
    Check(SameBytes(TFile.ReadAllBytes(Name), A) and TDirectory.Exists(TPath.Combine(Project, 'Vendas')), 'Project files are never removed');
  finally Second.Free; Session.Free; end;
end;

// Cleaning up: only the folders named as the tool names a run are removed.
// Whatever else sits in .backup belongs to the user and stays.
procedure CleanCases(const Folder: string);
var Project, Root, Own, Deep, Copied, Busy: string; Runs: TBackupRuns; Session: TBackupSession;
  Data: TBytes; N: Integer; Handle: THandle;
begin
  Project := TPath.Combine(Folder, 'limpar'); Root := TPath.Combine(Project, BackupFolderName);
  TDirectory.CreateDirectory(Project);
  Data := TEncoding.ASCII.GetBytes('0123456789');
  TFile.WriteAllBytes(TPath.Combine(Project, 'uProjeto.pas'), Data);
  Check((Length(FindBackupRuns(Project).Folders) = 0) and (DeleteBackupRuns(Project, False) = 0) and
    (Length(FindBackupRuns('').Folders) = 0), 'No .backup: nothing listed, nothing removed');
  TDirectory.CreateDirectory(TPath.Combine(Root, '2026-10-11_09-30-15'));
  TDirectory.CreateDirectory(TPath.Combine(Root, '2026-10-10_08-00-00\Vendas'));
  TDirectory.CreateDirectory(TPath.Combine(Root, '2026-10-11_09-30-15_2\' + BackupExternalFolder));
  TFile.WriteAllBytes(TPath.Combine(Root, '2026-10-10_08-00-00\Vendas\uPedidos.pas'), Data);
  TFile.WriteAllBytes(TPath.Combine(Root, '2026-10-11_09-30-15\uClientes.pas'), Data + Data);
  TFile.SetAttributes(TPath.Combine(Root, '2026-10-11_09-30-15\uClientes.pas'), [TFileAttribute.faReadOnly]);
  TFile.WriteAllBytes(TPath.Combine(Root, '2026-10-11_09-30-15_2\' + BackupExternalFolder + '\' + BackupExternalIndex), Data);
  // The user's own folders and look-alikes of a run name.
  Own := TPath.Combine(Root, '20261006_1304_registerclasses');
  TDirectory.CreateDirectory(Own);
  TFile.WriteAllBytes(TPath.Combine(Own, 'minha.pas'), Data);
  TDirectory.CreateDirectory(TPath.Combine(Root, '2026-10-11_09-30-15_x'));
  TDirectory.CreateDirectory(TPath.Combine(Root, '2026-10-11_09-30'));
  TDirectory.CreateDirectory(TPath.Combine(Root, '2026-10-11_09-30-15_'));
  TDirectory.CreateDirectory(TPath.Combine(Root, 'x2026-10-11_09-30-15'));
  TFile.WriteAllBytes(TPath.Combine(Root, '2026-10-12_10-00-00'), Data);
  Runs := FindBackupRuns(Project);
  Check((Length(Runs.Folders) = 3) and SameText(ExtractFileName(Runs.Folders[0]), '2026-10-10_08-00-00') and
    SameText(ExtractFileName(Runs.Folders[1]), '2026-10-11_09-30-15') and
    SameText(ExtractFileName(Runs.Folders[2]), '2026-10-11_09-30-15_2'), 'Runs listed oldest first, nothing else');
  Check((Runs.Files = 3) and (Runs.Bytes = 40), Format('Files and bytes of the runs: %d, %d', [Runs.Files, Runs.Bytes]));
  Check(DeleteBackupRuns(Project, True) = 2, 'Older runs removed');
  Runs := FindBackupRuns(Project);
  Check((Length(Runs.Folders) = 1) and SameText(ExtractFileName(Runs.Folders[0]), '2026-10-11_09-30-15_2') and
    (Runs.Files = 1), 'Newest run kept, read-only copy removed with the others');
  Check((DeleteBackupRuns(Project, True) = 0) and (Length(FindBackupRuns(Project).Folders) = 1), 'The only run is the newest: kept');
  // A copy held open by another program: its run stays and is reported as not removed.
  Busy := TPath.Combine(Runs.Folders[0], BackupExternalFolder + '\' + BackupExternalIndex);
  Handle := CreateFile(PChar(Busy), GENERIC_READ, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  Check(Handle <> INVALID_HANDLE_VALUE, 'Copy opened for the test');
  try
    Check((DeleteBackupRuns(Project, False) = 0) and TFile.Exists(Busy), 'Run with a file in use is not counted as removed');
  finally CloseHandle(Handle); end;
  Check((DeleteBackupRuns(Project, False) = 1) and (Length(FindBackupRuns(Project).Folders) = 0), 'Every run removed');
  Check(TFile.Exists(TPath.Combine(Own, 'minha.pas')) and TDirectory.Exists(TPath.Combine(Root, '2026-10-11_09-30-15_x')) and
    TDirectory.Exists(TPath.Combine(Root, '2026-10-11_09-30')) and TDirectory.Exists(TPath.Combine(Root, '2026-10-11_09-30-15_')) and
    TDirectory.Exists(TPath.Combine(Root, 'x2026-10-11_09-30-15')) and TFile.Exists(TPath.Combine(Root, '2026-10-12_10-00-00')),
    'What the tool did not create stays in .backup');
  Check(SameBytes(TFile.ReadAllBytes(TPath.Combine(Project, 'uProjeto.pas')), Data), 'Project files are never removed');
  // A run made by the tool itself, with a copy beyond the path limit.
  Project := TPath.Combine(Folder, 'limpar2');
  N := 236 - Integer(Length(Project));
  if N > 0 then
  begin
    Deep := TPath.Combine(Project, StringOfChar('p', N));
    TDirectory.CreateDirectory(Deep);
    Deep := TPath.Combine(Deep, 'uLonga.pas');
    TFile.WriteAllBytes(Deep, Data);
    Session := TBackupSession.Create(Project);
    try Copied := Session.Store(Deep, Data); finally Session.Free; end;
    Runs := FindBackupRuns(Project);
    Check((Length(Copied) > 260) and (Length(Runs.Folders) = 1) and (Runs.Files = 1) and (Runs.Bytes = 10), 'Run of the tool listed, long copy counted');
    Check((DeleteBackupRuns(Project, False) = 1) and not TDirectory.Exists(TPath.Combine(Project, BackupFolderName)) and
      TFile.Exists(Deep), 'Long copy removed, empty .backup removed, unit untouched');
  end;
end;

procedure RealFolders(const Source, Work: string);
var FileName, Target, Root: string; Copied, Changed, Same, Failed: Integer; Watch: TStopwatch;
  ByEncoding: array[TSourceEncoding] of Integer; Encoding: TSourceEncoding; Loaded: TSourceFile;
begin
  Root := ExcludeTrailingPathDelimiter(ExpandFileName(Source));
  Copied := 0; Changed := 0; Same := 0; Failed := 0;
  FillChar(ByEncoding, SizeOf(ByEncoding), 0);
  for FileName in TDirectory.GetFiles(Root, '*.pas', TSearchOption.soAllDirectories) do
  begin
    Target := TPath.Combine(Work, Copy(FileName, Length(Root) + 2, MaxInt));
    TDirectory.CreateDirectory(ExtractFileDir(Target));
    TFile.Copy(FileName, Target, True);
    // Copies of files marked read-only must still be writable in the work folder.
    TFile.SetAttributes(Target, []);
    Inc(Copied);
  end;
  Watch := TStopwatch.StartNew;
  for FileName in TDirectory.GetFiles(Work, '*.pas', TSearchOption.soAllDirectories) do
    try
      Loaded := LoadSourceFile(FileName);
      if OrganizeOnDisk(FileName) then
      begin Inc(Changed); Inc(ByEncoding[Loaded.Encoding]); end
      else Inc(Same);
    except
      on E: Exception do
      begin
        Inc(Failed);
        Writeln('FALHA | ', Copy(FileName, Length(Work) + 2, MaxInt), ' | ', E.ClassName, ': ', E.Message);
      end;
    end;
  Writeln(Format('Copias: %d  regravadas: %d  sem mudanca: %d  recusadas ou com falha: %d  tempo: %d ms',
    [Copied, Changed, Same, Failed, Watch.ElapsedMilliseconds]));
  for Encoding := Low(TSourceEncoding) to High(TSourceEncoding) do
    Writeln(Format('  regravadas em %-24s %d', [EncodingName(Encoding), ByEncoding[Encoding]]));
  Writeln('Conferencias por arquivo regravado: codificacao, conteudo, bytes antes e depois do uses, segunda execucao.');
end;

var Id: TGUID;
begin
  try
    if ParamCount >= 2 then RealFolders(ParamStr(1), ParamStr(2))
    else
    begin
      CreateGUID(Id);
      FixedCases(TPath.Combine(ExtractFilePath(ParamStr(0)), 'batch-' + GUIDToString(Id)));
      BackupCases(TPath.Combine(ExtractFilePath(ParamStr(0)), 'batch-' + GUIDToString(Id)));
      CleanCases(TPath.Combine(ExtractFilePath(ParamStr(0)), 'batch-' + GUIDToString(Id)));
      Writeln('PASS: ', Checks, ' batch checks');
    end;
  except
    on E: Exception do begin Writeln('FAIL: ', E.Message); ExitCode := 1; end;
  end;
end.
