unit CSCoder.Styler.Register;

interface

procedure Register;

implementation

uses System.SysUtils, System.Classes, Vcl.Forms, Vcl.Menus, Vcl.Themes, Vcl.Graphics, ToolsAPI, CSCoder.Styler.ControlHelp, CSCoder.Styler.Strings,
  CSCoder.Styler.Workspace, CSCoder.Styler.ExecutionForm, CSCoder.Styler.SettingsForm,
  CSCoder.Styler.EditorAdapter, CSCoder.Styler.Types, CSCoder.Styler.MenuIntegration,
  CSCoder.Styler.ProjectSettings, CSCoder.Styler.About, CSCoder.Styler.EditorMenu;

type
  // Opens Organize uses from the code editor by a key combination.
  TStylerKeyBinding = class(TNotifierObject, IOTAKeyboardBinding)
  private
    FKey: TShortCut;
    FExecute: TNotifyEvent;
    procedure Run(const Context: IOTAKeyContext; KeyCode: TShortCut; var BindingResult: TKeyBindingResult);
  public
    constructor Create(Key: TShortCut; Execute: TNotifyEvent);
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
  end;

  TStylerMenu = class
  private
    FRegistration: TStylerMenuRegistration;
    FEditorMenu: TStylerEditorMenu;
    FBinding, FKey: Integer;
    FTextsReady: Boolean;
    procedure ApplyShortcut;
    procedure Execute(Sender: TObject);
    procedure Settings(Sender: TObject);
    procedure About(Sender: TObject);
  public
    constructor Create;
    destructor Destroy; override;
  end;

var Menu: TStylerMenu;

// Windows of the tool follow the light or dark theme chosen in the IDE.
procedure ThemeIdeForm(Form: TCustomForm);
var Theming: IOTAIDEThemingServices;
begin
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) and Theming.IDEThemingEnabled then
  begin
    Theming.RegisterFormClass(TCustomFormClass(Form.ClassType));
    Theming.ApplyTheme(Form);
  end;
end;

// Font configured for the Pascal code editor in the IDE options.
procedure IdeEditorFont(Font: TFont);
var Editors: IOTAEditorServices; Options: IOTAEditOptions;
begin
  if not Supports(BorlandIDEServices, IOTAEditorServices, Editors) then Exit;
  Options := Editors.GetEditOptions(cDefEdPascal);
  if Options = nil then Options := Editors.EditOptions;
  if (Options = nil) or (Options.FontName = '') then Exit;
  Font.Name := Options.FontName;
  if Options.FontSize > 0 then Font.Size := Options.FontSize;
end;

function IdeStyle: TCustomStyleServices;
var Theming: IOTAIDEThemingServices;
begin
  Result := nil;
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) and Theming.IDEThemingEnabled then
    Result := Theming.StyleServices;
end;

constructor TStylerKeyBinding.Create(Key: TShortCut; Execute: TNotifyEvent);
begin
  inherited Create;
  FKey := Key; FExecute := Execute;
end;

procedure TStylerKeyBinding.Run(const Context: IOTAKeyContext; KeyCode: TShortCut;
  var BindingResult: TKeyBindingResult);
begin
  BindingResult := krHandled;
  FExecute(nil);
end;

function TStylerKeyBinding.GetBindingType: TBindingType;
begin Result := btPartial; end;
function TStylerKeyBinding.GetDisplayName: string;
begin Result := 'CS.Coder - Unit Styler'; end;
function TStylerKeyBinding.GetName: string;
begin Result := 'CSCoder.UnitStyler.Organize'; end;

procedure TStylerKeyBinding.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
  // The menu item name makes the IDE show the combination beside the command.
  BindingServices.AddKeyBinding([FKey], Run, nil, 0, '', OrganizeMenuItemName);
end;

constructor TStylerMenu.Create;
var Services: INTAServices;
begin
  inherited;
  FBinding := -1;
  if Supports(BorlandIDEServices, INTAServices, Services) then
    FRegistration := TStylerMenuRegistration.CreateMenu(Services.MainMenu, Execute, Settings, About);
  ApplyShortcut;
end;

destructor TStylerMenu.Destroy;
var Keyboard: IOTAKeyboardServices;
begin
  if (FBinding >= 0) and Supports(BorlandIDEServices, IOTAKeyboardServices, Keyboard) then
    Keyboard.RemoveKeyboardBinding(FBinding);
  FEditorMenu.Free;
  FRegistration.Free;
  inherited;
end;

// Registers the combination saved in the rules of the add-on, replacing the
// previous one. Called at load and whenever the settings may have changed.
procedure TStylerMenu.ApplyShortcut;
var Keyboard: IOTAKeyboardServices; Addon: TProjectSettings; Key: Integer; Code: string; Before: TStylerLanguage;
begin
  Key := DefaultOrganizeShortcut; Code := '';
  try
    Addon := TProjectSettings.Create('');
    try Key := Addon.Load.Shortcut; Code := Addon.Load.Language; finally Addon.Free; end;
  except
    // Unreadable settings: the default combination and the language of Windows.
  end;
  // The language kept with the rules; the menus follow it at once.
  Before := StylerLanguage;
  UseStylerLanguage(Code);
  if (StylerLanguage <> Before) or not FTextsReady then
  begin
    FTextsReady := True;
    if FRegistration <> nil then FRegistration.RefreshTexts;
    // Same command, one right click away in the code editor. Created once: taking
    // it out of the editor menu and hooking again crashed the Delphi 13 IDE.
    if FEditorMenu = nil then
      FEditorMenu := TStylerEditorMenu.CreateMenu('Unit Styler: ' + L(stOrganize) + '...', L(stEditorMenuHint), Execute)
    else FEditorMenu.SetTexts('Unit Styler: ' + L(stOrganize) + '...', L(stEditorMenuHint));
  end;
  if not Supports(BorlandIDEServices, IOTAKeyboardServices, Keyboard) then Exit;
  // Unchanged: leave the binding alone, it may be the one running right now.
  if Key = FKey then Exit;
  FKey := Key;
  if FBinding >= 0 then
  begin
    Keyboard.RemoveKeyboardBinding(FBinding);
    FBinding := -1;
  end;
  if Key <> 0 then
    FBinding := Keyboard.AddKeyboardBinding(TStylerKeyBinding.Create(TShortCut(Key), Execute));
end;

procedure TStylerMenu.Execute(Sender: TObject);
var Workspace: IStylerWorkspace; Form: TExecutionForm;
begin
  try
    Workspace := TIDEWorkspace.Create(False);
    Form := TExecutionForm.CreateWorkspace(nil, Workspace, StylerLanguage);
    try Form.ShowModal; finally Form.Free; end;
    // The settings can be changed from inside that window.
    Workspace := nil;
    ApplyShortcut;
  except
    on E: Exception do
      Application.MessageBox(PChar(L(stOpenOrganizeError) + sLineBreak + sLineBreak + E.Message),
        'CS.Coder - Unit Styler', 0);
  end;
end;

procedure TStylerMenu.Settings(Sender: TObject);
var Workspace: IStylerWorkspace; Options: TUsesOptions; Addon: TProjectSettings;
begin
  try
    if GetActiveProject = nil then
    begin
      // The rules of the add-on are global: editable with no project open.
      Addon := TProjectSettings.Create('');
      try
        Options := Addon.Load;
        if EditSettings(nil, StylerLanguage, Options, nil, Addon.RootDirectory, False) then Addon.Save(Options);
      finally Addon.Free; end;
      ApplyShortcut;
      Exit;
    end;
    Workspace := TIDEWorkspace.Create(False);
    Options := Workspace.LoadOptions;
    if EditSettings(nil, StylerLanguage, Options, RelativeUnitPaths(Workspace),
      Workspace.SettingsDirectory, True, Workspace.ProjectDirectory) then Workspace.SaveOptions(Options);
    ApplyShortcut;
  except
    on E: Exception do
      Application.MessageBox(PChar(L(stOpenSettingsError) + sLineBreak + sLineBreak + E.Message),
        'CS.Coder - Unit Styler', 0);
  end;
end;

procedure TStylerMenu.About(Sender: TObject);
begin
  // Needs no project: it only shows where the rules of the add-on are kept.
  ShowStylerAbout(StylerLanguage, IncludeTrailingPathDelimiter(DefaultSettingsDirectory) + 'settings.json');
end;

procedure Register;
begin
  HostThemeForm := ThemeIdeForm; HostStyle := IdeStyle; HostEditorFont := IdeEditorFont;
  if Menu = nil then Menu := TStylerMenu.Create;
end;

initialization

finalization
  HostThemeForm := nil; HostStyle := nil; HostEditorFont := nil;
  FreeAndNil(Menu);

end.
