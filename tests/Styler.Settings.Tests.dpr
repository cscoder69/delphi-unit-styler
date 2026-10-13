program StylerSettingsTests;
{$APPTYPE CONSOLE}
{$RANGECHECKS ON}

uses System.SysUtils, System.Classes, System.IOUtils,
  CSCoder.Styler.Types in '..\src\core\CSCoder.Styler.Types.pas',
  CSCoder.Styler.Strings in '..\src\i18n\CSCoder.Styler.Strings.pas',
  CSCoder.Styler.UsesOrganizer in '..\src\core\CSCoder.Styler.UsesOrganizer.pas',
  CSCoder.Styler.ProjectSettings in '..\src\config\CSCoder.Styler.ProjectSettings.pas';

var Settings, Other, Second, Global: TProjectSettings; Count: Integer; Options, Loaded: TUsesOptions;
  Id: TGUID; Root, Base, ProjectFile, SecondFile, Content: string; Checks: Integer; Rejected: Boolean;

procedure Check(Value: Boolean; const Message: string);
begin Inc(Checks); if not Value then raise Exception.Create(Message); end;

// A project is its .dproj identifier, not its folder, its file name or the
// Delphi version that opened it.
procedure ProjectIdentityCases(const Root: string);
const
  GuidA = '{1B2C3D4E-0000-4AAA-8BBB-123456789ABC}';
  GuidB = '{9F8E7D6C-1111-4CCC-8DDD-CBA987654321}';
  Dproj = '<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">'#13#10 +
    '  <PropertyGroup>'#13#10'    <ProjectGuid>%s</ProjectGuid>'#13#10'  </PropertyGroup>'#13#10'</Project>';
var S: TProjectSettings; O: TUsesOptions; First, Legacy, Name: string;

  function Project(const Folder, FileName, Guid: string): string;
  begin
    TDirectory.CreateDirectory(TPath.Combine(Root, Folder));
    Result := TPath.Combine(TPath.Combine(Root, Folder), FileName);
    if Guid <> '' then TFile.WriteAllText(ChangeFileExt(Result, '.dproj'), Format(Dproj, [Guid]), TEncoding.UTF8);
  end;

  function Open(const ProjectFile, Version: string): TUsesOptions;
  begin
    FreeAndNil(S);
    S := TProjectSettings.Create(ProjectFile, TPath.Combine(TPath.Combine(Root, 'cfg'), Version));
    Result := S.Load;
  end;

begin
  S := nil;
  try
    Check(ProjectIdentity(Project('a', 'Loja.dproj', GuidA)) = '1B2C3D4E-0000-4AAA-8BBB-123456789ABC', 'Identity is the ProjectGuid of the dproj');
    O := Open(Project('a', 'Loja.dproj', GuidA), 'D11');
    First := S.ProjectFileName;
    Check(Pos('Loja.1B2C3D4E-0000-4AAA-8BBB-123456789ABC.json', First) > 0, 'Project file named by project and identifier: ' + First);
    O.IgnoredPaths := ['vendor\']; O.ExcludedUnits := ['Anchor']; O.Alphabetical := True;
    S.Save(O);
    // Moved to another folder.
    O := Open(Project('outra\pasta', 'Loja.dproj', GuidA), 'D11');
    Check(SameText(S.ProjectFileName, First) and (Length(O.IgnoredPaths) = 1) and (O.IgnoredPaths[0] = 'vendor\') and
      (O.ExcludedUnits[0] = 'Anchor'), 'Moved project keeps its settings');
    // Opened by another Delphi version: same project file, that version's own rules.
    O := Open(Project('a', 'Loja.dproj', GuidA), 'D12');
    Check(SameText(S.ProjectFileName, First) and (Length(O.IgnoredPaths) = 1) and (O.ExcludedUnits[0] = 'Anchor'),
      'Project settings are the same in another Delphi version');
    Check(not O.Alphabetical, 'Add-on rules stay per Delphi version');
    O.IgnoredPaths := ['vendor\', 'lib\']; S.Save(O);
    O := Open(Project('a', 'Loja.dproj', GuidA), 'D11');
    Check((Length(O.IgnoredPaths) = 2) and O.Alphabetical, 'Change made in one version is seen by the other');
    // The project file renamed, or given as .dpr: still the same project.
    O := Open(Project('a', 'Vendas.dproj', GuidA), 'D11');
    Check(SameText(S.ProjectFileName, First) and (Length(O.IgnoredPaths) = 2), 'Renamed project file keeps its settings');
    O := Open(ChangeFileExt(Project('a', 'Loja.dproj', GuidA), '.dpr'), 'D11');
    Check(SameText(S.ProjectFileName, First), 'A .dpr is identified by the dproj beside it');
    // Another project with the same name does not share them.
    O := Open(Project('b', 'Loja.dproj', GuidB), 'D11');
    Check(not SameText(S.ProjectFileName, First) and (Length(O.IgnoredPaths) = 0), 'Same name, another identifier: own settings');
    // No dproj: the path identifies it, as before.
    Check(Length(ProjectIdentity(Project('c', 'Solto.dpr', ''))) = 8, 'Without a dproj the path identifies the project');
    Check(ProjectIdentity(Project('c', 'Solto.dpr', '')) <> ProjectIdentity(Project('d', 'Solto.dpr', '')), 'Path identity differs by folder');
    // Settings kept by an earlier build inside the version folder are picked up.
    O := Open(Project('c', 'Solto.dpr', ''), 'D11');
    Name := ExtractFileName(S.ProjectFileName);
    Legacy := TPath.Combine(TPath.Combine(S.Directory, 'projects'), Name);
    Check(not SameText(Legacy, S.ProjectFileName) and (Length(O.IgnoredPaths) = 0), 'New place differs from the old one');
    TDirectory.CreateDirectory(ExtractFileDir(Legacy));
    TFile.WriteAllText(Legacy, '{"schemaVersion":1,"ignoredPaths":["antigo\\"],"excludeInterface":true}', TEncoding.UTF8);
    O := Open(Project('c', 'Solto.dpr', ''), 'D11');
    Check((Length(O.IgnoredPaths) = 1) and (O.IgnoredPaths[0] = 'antigo\') and (usInterface in O.ExcludedSections),
      'Settings of an earlier build are read');
    S.Save(O);
    Check(TFile.Exists(S.ProjectFileName) and TFile.Exists(Legacy), 'Saved in the shared folder, old file left alone');
    TFile.Delete(Legacy);
    O := Open(Project('c', 'Solto.dpr', ''), 'D11');
    Check((Length(O.IgnoredPaths) = 1) and (usInterface in O.ExcludedSections), 'New file stands on its own');
    // Units of the project outside its folder follow the same ignored list.
    Check(IsIgnoredPath('..\Comum\uBase.pas', ['..\Comum\']) and not IsIgnoredPath('..\Comum\uBase.pas', ['Comum\']) and
      not IsIgnoredPath('..\Outra\uBase.pas', ['..\Comum\']), 'Ignored list reaches folders outside the project');
  finally S.Free; end;
end;

procedure Reload;
begin
  Other.Free;
  Other := TProjectSettings.Create(ProjectFile, Base);
  Loaded := Other.Load;
end;

begin
  Settings := nil; Other := nil; Second := nil; Global := nil;
  try
    CreateGUID(Id);
    // Every file of this run stays below the test output folder.
    Root := TPath.Combine(ExtractFilePath(ParamStr(0)), 'settings-' + GUIDToString(Id));
    // The add-on rules of one Delphi version; project files sit beside it.
    Base := TPath.Combine(Root, 'D11');
    ProjectFile := 'C:\Projetos\Loja\Loja.dproj';
    SecondFile := 'C:\Projetos\Outra\Loja.dproj';
    Check(SameText(ExtractFileDir(DefaultSettingsDirectory),
      TPath.Combine(GetEnvironmentVariable('LOCALAPPDATA'), 'CSCoder\UnitStyler')) and
      (Pos('D1', ExtractFileName(DefaultSettingsDirectory)) = 1), 'Default folder in the local profile, per Delphi version');
    Settings := TProjectSettings.Create(ProjectFile, Base);
    Check(Settings.AddonFileName = TPath.Combine(Base, 'settings.json'), 'Add-on file in the base folder');
    Check(ExtractFileDir(Settings.ProjectFileName) = TPath.Combine(Root, 'projects'), 'Project file in the projects folder, outside the version folder');
    Check(Settings.RootDirectory = Root, 'Root folder holds versions and projects');
    Check(Pos('Loja.', ExtractFileName(Settings.ProjectFileName)) = 1, 'Project file named after the project');
    Options := Settings.Load;
    Check(not TDirectory.Exists(Root), 'Loading creates nothing');
    Check(Options.AutoSaveUnits, 'Auto save defaults enabled');
    Check(Options.BackupUnits, 'Backup defaults enabled');
    Check((Length(Options.ProtectedUnits) = Length(DefaultProtectedUnits)) and (Options.ProtectedUnits[0] = 'Winapi.*') and
      (Options.ProtectedUnits[1] = 'System.*'), 'System units are protected out of the box');
    Check(not Options.Alphabetical and Options.SortFirstNameOnly, 'Sorting off by default, first name only when turned on');
    Check(Options.Shortcut = $C055, 'Shortcut defaults to Ctrl+Alt+U');
    Check(not Options.WrapUnits and (Options.MaxLineWidth = 100), 'Several per line off by default, width 100');
    Check(Options.OneUnitPerLine and Options.IndentationEnabled, 'Defaults');
    Check(not Options.BlankBeforeSections and not Options.BlankAfterSections, 'Section spacing defaults disabled');
    Options.AutoSaveUnits := False;
    Options.Alphabetical := True;
    Options.BlankBeforeSections := True; Options.BlankAfterSections := True;
    Options.PrioritiesEnabled := True; Options.Priorities := ['Z', 'System.*'];
    Options.GroupingEnabled := True; Options.BlankLinesBetweenGroups := True;
    Options.UngroupedPosition := upFirst; Options.ExcludedUnits := ['Anchor'];
    Options.ExcludedSections := [usImplementation];
    Options.IgnoredPaths := ['modules\', 'Lib\Terceiro.pas'];
    SetLength(Options.Groups, 1); Options.Groups[0].Name := 'System';
    Options.Groups[0].Selectors := ['System.*', 'App.Core'];
    Settings.Save(Options);
    Check(TFile.Exists(Settings.AddonFileName) and TFile.Exists(Settings.ProjectFileName), 'Both files written');
    Reload;
    Check(not Loaded.AutoSaveUnits, 'Auto save false persists');
    Check(Loaded.BackupUnits, 'Backup true persists');
    Options.BackupUnits := False; Settings.Save(Options);
    Reload;
    Check(not Loaded.BackupUnits, 'Backup false persists');
    // The language is a rule of the add-on, kept in its file and nowhere else.
    Check((Loaded.Language = '') and (Pos('"language"', TFile.ReadAllText(Settings.AddonFileName, TEncoding.UTF8)) = 0),
      'No language saved while it follows Windows');
    Options.Language := 'de'; Settings.Save(Options);
    Reload;
    Check((Loaded.Language = 'de') and (Pos('"language":"de"', StringReplace(TFile.ReadAllText(Settings.AddonFileName, TEncoding.UTF8), ' ', '', [rfReplaceAll])) > 0) and
      (Pos('language', TFile.ReadAllText(Settings.ProjectFileName, TEncoding.UTF8)) = 0), 'Chosen language persists in the add-on file');
    Options.Language := ''; Settings.Save(Options);
    Reload;
    Check(Loaded.Language = '', 'Back to automatic removes the choice');
    Check(Loaded.Shortcut = $C055, 'Shortcut persists');
    Check(Length(Loaded.ProtectedUnits) = Length(DefaultProtectedUnits), 'Protected list persists');
    Options.ProtectedUnits := ['Winapi.*', 'MinhaLib.Base']; Settings.Save(Options);
    Reload;
    Check((Length(Loaded.ProtectedUnits) = 2) and (Loaded.ProtectedUnits[1] = 'MinhaLib.Base'), 'Edited protected list persists');
    Options.ProtectedUnits := nil; Settings.Save(Options);
    Reload;
    Check(Length(Loaded.ProtectedUnits) = 0, 'Emptied protected list stays empty');
    Check(Pos('protectedUnits', TFile.ReadAllText(Settings.ProjectFileName, TEncoding.UTF8)) = 0, 'Protected list is not a project setting');
    Check(Loaded.Alphabetical and Loaded.SortFirstNameOnly, 'First name sorting persists');
    Options.SortFirstNameOnly := False; Settings.Save(Options);
    Reload;
    Check(Loaded.Alphabetical and not Loaded.SortFirstNameOnly, 'Second name sorting persists');
    Options.Shortcut := 0; Settings.Save(Options);
    Reload;
    Check(Loaded.Shortcut = 0, 'No shortcut persists');
    Options.OneUnitPerLine := False; Options.WrapUnits := True; Options.MaxLineWidth := 120; Settings.Save(Options);
    Reload;
    Check(Loaded.WrapUnits and not Loaded.OneUnitPerLine and (Loaded.MaxLineWidth = 120), 'Several per line and width persist');
    Options.OneUnitPerLine := True;
    Rejected := False;
    try Settings.Save(Options); except on E: Exception do Rejected := True; end;
    Check(Rejected, 'Both line layouts together are not saved');
    Options.OneUnitPerLine := False;
    Check(Pos('backupUnits', TFile.ReadAllText(Settings.AddonFileName, TEncoding.UTF8)) > 0, 'Backup belongs to the add-on file');
    Check(Pos('backupUnits', TFile.ReadAllText(Settings.ProjectFileName, TEncoding.UTF8)) = 0, 'Backup is not a project setting');
    Options.AutoSaveUnits := True; Settings.Save(Options);
    Reload;
    Check(Loaded.AutoSaveUnits, 'Auto save true persists');
    Check(Loaded.Alphabetical and Loaded.PrioritiesEnabled and Loaded.GroupingEnabled, 'Rule switches');
    Check(Loaded.BlankBeforeSections and Loaded.BlankAfterSections, 'Section spacing round-trip');
    Options.BlankAfterSections := False; Settings.Save(Options);
    Reload;
    Check(Loaded.BlankBeforeSections and not Loaded.BlankAfterSections, 'Before-only spacing persists');
    Options.BlankBeforeSections := False; Options.BlankAfterSections := True; Settings.Save(Options);
    Reload;
    Check(not Loaded.BlankBeforeSections and Loaded.BlankAfterSections, 'After-only spacing persists');
    Check(Loaded.Priorities[0] = 'Z', 'Priority order');
    Check(Loaded.Groups[0].Selectors[1] = 'App.Core', 'Groups round-trip');
    Check(Loaded.ExcludedUnits[0] = 'Anchor', 'Exclusion round-trip');
    Check(usImplementation in Loaded.ExcludedSections, 'Section exclusion');
    Check(Loaded.UngroupedPosition = upFirst, 'Ungrouped position');
    Check((Length(Loaded.IgnoredPaths) = 2) and (Loaded.IgnoredPaths[0] = 'modules\') and
      (Loaded.IgnoredPaths[1] = 'Lib\Terceiro.pas'), 'Ignored paths round-trip');
    Check(IsIgnoredPath('modules\horse\src\Horse.pas', Loaded.IgnoredPaths), 'Unit below ignored folder');
    Check(IsIgnoredPath('MODULES/x.pas', Loaded.IgnoredPaths), 'Ignored folder ignores case and slash');
    Check(IsIgnoredPath('.\lib\terceiro.pas', Loaded.IgnoredPaths), 'Ignored file');
    Check(not IsIgnoredPath('modules2\x.pas', Loaded.IgnoredPaths), 'Folder name prefix is not a match');
    Check(not IsIgnoredPath('Lib\Terceiro2.pas', Loaded.IgnoredPaths) and
      not IsIgnoredPath('Lib\Outro.pas', Loaded.IgnoredPaths), 'Other files in the folder stay');
    Check(not IsIgnoredPath('uMain.pas', nil), 'Empty list ignores nothing');

    // No project open: only the add-on rules are read and written.
    Global := TProjectSettings.Create('', Base);
    Check((Global.ProjectFileName = '') and (Global.AddonFileName = Settings.AddonFileName), 'No project: only the add-on file');
    Loaded := Global.Load;
    Check(Loaded.PrioritiesEnabled and (Loaded.Priorities[0] = 'Z') and not Loaded.BackupUnits, 'No project: add-on rules are loaded');
    Check((Length(Loaded.IgnoredPaths) = 0) and (Length(Loaded.ExcludedUnits) = 0) and
      (Loaded.ExcludedSections = []), 'No project: nothing of a project is loaded');
    Count := Integer(Length(TDirectory.GetFiles(TPath.Combine(Root, 'projects'))));
    Content := TFile.ReadAllText(Settings.ProjectFileName, TEncoding.UTF8);
    Loaded.BackupUnits := True; Global.Save(Loaded);
    Check((Integer(Length(TDirectory.GetFiles(TPath.Combine(Root, 'projects')))) = Count) and
      (TFile.ReadAllText(Settings.ProjectFileName, TEncoding.UTF8) = Content), 'No project: saving touches no project file');
    Options := Settings.Load;
    Check(Options.BackupUnits and (Length(Options.IgnoredPaths) = 2) and (usImplementation in Options.ExcludedSections),
      'Rule saved without a project reaches the project, which keeps its own settings');

    // Add-on rules are shared; what belongs to a project stays with that project.
    Second := TProjectSettings.Create(SecondFile, Base);
    Check(not SameText(Second.ProjectFileName, Settings.ProjectFileName), 'Same name in another folder gets its own file');
    Check(Second.AddonFileName = Settings.AddonFileName, 'One add-on file for every project');
    Loaded := Second.Load;
    Check(Loaded.PrioritiesEnabled and (Loaded.Priorities[0] = 'Z') and
      (Loaded.Groups[0].Name = 'System') and Loaded.BlankAfterSections, 'Add-on rules reach another project');
    Check((Length(Loaded.IgnoredPaths) = 0) and (Length(Loaded.ExcludedUnits) = 0) and
      (Loaded.ExcludedSections = []), 'Project settings do not leak to another project');
    Loaded.IgnoredPaths := ['vendor\']; Loaded.ExcludedSections := [usInterface];
    Second.Save(Loaded);
    Reload;
    Check((Length(Loaded.IgnoredPaths) = 2) and (usImplementation in Loaded.ExcludedSections) and
      not (usInterface in Loaded.ExcludedSections), 'First project keeps its own settings');
    Content := TFile.ReadAllText(Settings.ProjectFileName, TEncoding.UTF8);
    Check(Pos('Loja.dproj', Content) > 0, 'Project file records its project');
    Check((Pos('alphabetical', Content) = 0) and
      (Pos('ignoredPaths', TFile.ReadAllText(Settings.AddonFileName, TEncoding.UTF8)) = 0), 'Each file holds only its own settings');

    Options := Settings.Load;
    Options.Alphabetical := False; Settings.Save(Options);
    Check(TFile.Exists(Settings.AddonFileName + '.bak'), 'Previous add-on settings backup');
    Check(not TFile.Exists(Settings.ProjectFileName + '.bak'), 'Unchanged project file is not rewritten');
    Options.IgnoredPaths := ['modules\']; Settings.Save(Options);
    Check(TFile.Exists(Settings.ProjectFileName + '.bak'), 'Previous project settings backup');
    Content := TFile.ReadAllText(Settings.AddonFileName, TEncoding.UTF8);
    Rejected := False;
    Loaded.Alphabetical := True;
    try Other.Save(Loaded); except on E: Exception do Rejected := True; end;
    Check(Rejected, 'Concurrent overwrite rejected');
    Check(TFile.ReadAllText(Settings.AddonFileName, TEncoding.UTF8) = Content, 'Conflict preserved current settings');
    Other.Free; Other := nil;
    TFile.WriteAllText(Settings.AddonFileName, '{"schemaVersion":99}', TEncoding.UTF8);
    Rejected := False;
    try Settings.Load; except on E: Exception do Rejected := True; end;
    Check(Rejected, 'Future schema rejected');
    Rejected := False;
    try Settings.Save(Options); except on E: Exception do Rejected := True; end;
    Check(Rejected, 'Failed load cannot overwrite settings');
    TFile.WriteAllText(Settings.AddonFileName, '{"schemaVersion":1,"alphabetical":"yes"}', TEncoding.UTF8);
    Rejected := False;
    try Settings.Load; except on E: Exception do Rejected := True; end;
    Check(Rejected, 'Invalid type rejected');
    TFile.WriteAllText(Settings.AddonFileName, '{"schemaVersion":1}', TEncoding.UTF8);
    Loaded := Settings.Load;
    Check(not Loaded.BlankBeforeSections and not Loaded.BlankAfterSections, 'Missing fields use defaults');
    Check(Loaded.AutoSaveUnits, 'Missing auto save defaults enabled');
    Check(Loaded.BackupUnits, 'Missing backup defaults enabled');
    Check(Length(Loaded.ProtectedUnits) = Length(DefaultProtectedUnits), 'Missing protected list uses the factory one');
    Check(Loaded.SortFirstNameOnly, 'Missing sort depth uses first name only');
    Check(Loaded.Shortcut = $C055, 'Missing shortcut uses the default');
    Check(not Loaded.WrapUnits and (Loaded.MaxLineWidth = 100), 'Missing layout fields use defaults');
    Check(Length(Loaded.IgnoredPaths) = 1, 'Project file still read with a minimal add-on file');
    TFile.WriteAllText(Settings.AddonFileName, '{"schemaVersion":1,"autoSaveUnits":"yes"}', TEncoding.UTF8);
    Rejected := False;
    try Settings.Load; except on E: Exception do Rejected := True; end;
    Check(Rejected, 'Invalid auto save type rejected');
    TFile.WriteAllText(Settings.AddonFileName, '{"schemaVersion":1}', TEncoding.UTF8);
    TFile.WriteAllText(Settings.ProjectFileName, '{"schemaVersion":1,"ignoredPaths":"all"}', TEncoding.UTF8);
    Rejected := False;
    try Settings.Load; except on E: Exception do Rejected := True; end;
    Check(Rejected, 'Invalid project file rejected');
    Rejected := False;
    try Settings.Save(Options); except on E: Exception do Rejected := True; end;
    Check(Rejected, 'Invalid project file cannot be overwritten');
    ProjectIdentityCases(Root + '-id');
    Writeln('PASS: ', Checks, ' settings checks');
  except
    on E: Exception do begin Writeln('FAIL: ', E.Message); ExitCode := 1; end;
  end;
  Global.Free; Second.Free; Other.Free; Settings.Free;
end.
