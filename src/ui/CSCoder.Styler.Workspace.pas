unit CSCoder.Styler.Workspace;

interface

uses CSCoder.Styler.Types, CSCoder.Styler.Strings;

type
  IStylerWorkspace = interface
    ['{AE109A57-0D72-4410-9C3C-E11D3774A256}']
    function ProjectName: string;
    // Folder of the project file; empty when unit names are already relative.
    function ProjectDirectory: string;
    // Folder that holds the settings: one subfolder per Delphi version for the
    // rules of the add-on, and one for the files of the projects.
    function SettingsDirectory: string;
    function UnitNames: TArray<string>;
    function CurrentUnit: Integer;
    function OpenUnitIndices: TArray<Integer>;
    function SupportsBatch: Boolean;
    function IsDemo: Boolean;
    function ReadSource(Index: Integer): string;
    function LoadOptions: TUsesOptions;
    procedure SaveOptions(const Options: TUsesOptions);
    // Brings a closed unit into the editor so it can be changed and left unsaved.
    procedure OpenUnit(Index: Integer);
    // AutoSave applies only to units closed in the IDE; open ones are never saved.
    procedure Apply(Index: Integer; const Proposal: TStylerProposal; AutoSave: Boolean);
    // Starts one run. With Enabled, every unit changed from here on is first
    // copied, as it is saved on disk, to the backup folder of the run, open in
    // the editor or not. Without it nothing is copied.
    procedure StartBackup(Enabled: Boolean);
    // Backup folder of the current run; empty when it holds no copy.
    function BackupDirectory: string;
  end;

  TMemoryWorkspace = class(TInterfacedObject, IStylerWorkspace)
  private
    FNames, FSources: TArray<string>;
    FOptions: TUsesOptions;
    FSaved: TArray<Boolean>;
    FCurrentIndex: Integer;
    FHasOpenUnits: Boolean;
  public
    constructor Create(CurrentIndex: Integer = 0; HasOpenUnits: Boolean = True);
    function WasSaved(Index: Integer): Boolean;
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

// Unit paths relative to the project folder, as used by the ignored list.
function RelativeUnitPaths(const Workspace: IStylerWorkspace): TArray<string>;

implementation

uses System.SysUtils, CSCoder.Styler.UsesOrganizer, CSCoder.Styler.ProjectSettings;

function RelativeUnitPaths(const Workspace: IStylerWorkspace): TArray<string>;
var Base, Name: string;
begin
  Result := nil;
  Base := Workspace.ProjectDirectory;
  if Base <> '' then Base := IncludeTrailingPathDelimiter(Base);
  for Name in Workspace.UnitNames do
    if Base <> '' then Result := Result + [ExtractRelativePath(Base, Name)]
    else Result := Result + [Name];
end;

constructor TMemoryWorkspace.Create(CurrentIndex: Integer; HasOpenUnits: Boolean);
begin
  inherited Create;
  FCurrentIndex := CurrentIndex; FHasOpenUnits := HasOpenUnits;
  FNames := ['uClientes.pas', 'Vendas\uPedidos.pas', 'Vendas\Relatorios\uRelatorios.pas'];
  FSources := [
    'unit uClientes;'#13#10#13#10'interface'#13#10#13#10'uses'#13#10'  Vcl.Forms, System.Classes,'#13#10'  System.SysUtils, MinhaApp.Core;'#13#10#13#10'implementation'#13#10#13#10'end.',
    'unit uPedidos;'#13#10'interface'#13#10'uses System.SysUtils, Vcl.Controls, MinhaApp.Core;'#13#10'implementation'#13#10'uses System.Classes, System.Math;'#13#10'end.',
    'unit uRelatorios;'#13#10'interface'#13#10'uses // Relatorios'#13#10'  Vcl.Forms, System.SysUtils;'#13#10'implementation'#13#10'end.'];
  SetLength(FSaved, Length(FNames));
  FOptions := Default(TUsesOptions);
  FOptions.AutoSaveUnits := True;
  FOptions.BackupUnits := True;
  FOptions.Shortcut := DefaultOrganizeShortcut;
  FOptions.OneUnitPerLine := True;
  FOptions.MaxLineWidth := DefaultLineWidth;
  FOptions.IndentationEnabled := True;
  FOptions.Indentation := '  ';
  FOptions.Alphabetical := True;
  FOptions.PrioritiesEnabled := True;
  FOptions.Priorities := ['MinhaApp.Core'];
  FOptions.GroupingEnabled := True;
  FOptions.BlankLinesBetweenGroups := True;
  SetLength(FOptions.Groups, 2);
  FOptions.Groups[0].Name := 'System';
  FOptions.Groups[0].Selectors := ['System.*'];
  FOptions.Groups[1].Name := 'Vcl';
  FOptions.Groups[1].Selectors := ['Vcl.*'];
end;

function TMemoryWorkspace.ProjectName: string;
begin Result := 'MinhaAplicacao.dproj'; end;
function TMemoryWorkspace.ProjectDirectory: string;
begin Result := ''; end;
function TMemoryWorkspace.SettingsDirectory: string;
begin Result := ExtractFileDir(DefaultSettingsDirectory); end;
function TMemoryWorkspace.UnitNames: TArray<string>;
begin Result := Copy(FNames); end;
function TMemoryWorkspace.CurrentUnit: Integer;
begin Result := FCurrentIndex; end;
function TMemoryWorkspace.OpenUnitIndices: TArray<Integer>;
begin if FHasOpenUnits then Result := [0, 1] else Result := nil; end;
function TMemoryWorkspace.SupportsBatch: Boolean;
begin Result := True; end;
function TMemoryWorkspace.IsDemo: Boolean;
begin Result := True; end;
function TMemoryWorkspace.ReadSource(Index: Integer): string;
begin Result := FSources[Index]; end;
function TMemoryWorkspace.LoadOptions: TUsesOptions;
begin Result := FOptions; end;
procedure TMemoryWorkspace.SaveOptions(const Options: TUsesOptions);
begin ValidateUsesOptions(Options); FOptions := Options; end;
procedure TMemoryWorkspace.OpenUnit(Index: Integer);
begin end;
procedure TMemoryWorkspace.Apply(Index: Integer; const Proposal: TStylerProposal; AutoSave: Boolean);
begin FSources[Index] := Proposal.ApplyTo(FSources[Index]); FSaved[Index] := AutoSave; end;
procedure TMemoryWorkspace.StartBackup(Enabled: Boolean);
begin end;
function TMemoryWorkspace.BackupDirectory: string;
begin Result := ''; end;
function TMemoryWorkspace.WasSaved(Index: Integer): Boolean;
begin Result := FSaved[Index]; end;

end.
