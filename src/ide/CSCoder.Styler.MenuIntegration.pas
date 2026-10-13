unit CSCoder.Styler.MenuIntegration;

interface

uses System.Classes, Vcl.Menus;

const OrganizeMenuItemName = 'CSCoderUnitStylerOrganize';

type
  TStylerMenuRegistration = class(TComponent)
  private
    FRoot, FBranch, FOrganize, FSettings, FAbout: TMenuItem;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor CreateMenu(MainMenu: TMainMenu; Execute, Settings, About: TNotifyEvent);
    destructor Destroy; override;
    // Captions and hints again, in the language in use.
    procedure RefreshTexts;
  end;

implementation

uses System.SysUtils, CSCoder.Styler.Strings;

const SharedRootName = 'CSCoderSharedMenu';

constructor TStylerMenuRegistration.CreateMenu(MainMenu: TMainMenu;
  Execute, Settings, About: TNotifyEvent);
var I: Integer; Item: TMenuItem;
begin
  inherited Create(nil);
  if MainMenu = nil then Exit;
  for I := 0 to MainMenu.Items.Count - 1 do
    if SameText(MainMenu.Items[I].Name, SharedRootName) or
      SameText(StringReplace(MainMenu.Items[I].Caption, '&', '', [rfReplaceAll]), 'CS.Coder') then
    begin
      FRoot := MainMenu.Items[I];
      Break;
    end;
  if FRoot = nil then
  begin
    // The IDE owns the shared root, so unloading this package cannot destroy
    // another installed tool's submenu. Each tool owns only its own branch.
    FRoot := TMenuItem.Create(MainMenu);
    FRoot.Name := SharedRootName;
    FRoot.Caption := 'CS.Coder';
    MainMenu.Items.Add(FRoot);
  end;
  FRoot.FreeNotification(Self);
  FBranch := TMenuItem.Create(Self);
  FBranch.Caption := 'Unit Styler';
  FBranch.FreeNotification(Self);
  Item := TMenuItem.Create(FBranch);
  FOrganize := Item;
  // Named so the IDE can show the key binding beside the command.
  Item.Name := OrganizeMenuItemName;
  Item.OnClick := Execute;
  FBranch.Add(Item);
  Item := TMenuItem.Create(FBranch);
  FSettings := Item;
  Item.OnClick := Settings;
  FBranch.Add(Item);
  Item := TMenuItem.Create(FBranch);
  FAbout := Item;
  Item.OnClick := About;
  FBranch.Add(Item);
  FRoot.Insert(0, FBranch);
  RefreshTexts;
end;

procedure TStylerMenuRegistration.RefreshTexts;
begin
  if FBranch = nil then Exit;
  FBranch.Hint := L(stMenuBranchHint);
  FOrganize.Caption := L(stOrganize) + '...';
  FOrganize.Hint := L(stMenuOrganizeHint);
  FSettings.Caption := L(stSettings);
  FSettings.Hint := L(stMenuSettingsHint);
  FAbout.Caption := L(stAbout) + '...';
  FAbout.Hint := L(stMenuAboutHint);
end;

procedure TStylerMenuRegistration.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if AComponent = FBranch then FBranch := nil;
    if AComponent = FRoot then FRoot := nil;
  end;
end;

destructor TStylerMenuRegistration.Destroy;
begin
  FreeAndNil(FBranch);
  // Never delete an existing foreign root or a root with other tools in it.
  if (FRoot <> nil) and (FRoot.Count = 0) and
    SameText(FRoot.Name, SharedRootName) then FreeAndNil(FRoot);
  inherited;
end;

end.
