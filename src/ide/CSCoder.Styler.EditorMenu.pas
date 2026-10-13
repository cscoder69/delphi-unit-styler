unit CSCoder.Styler.EditorMenu;

// Adds the tool's command to the context menu of the code editor.
// ToolsAPI has no call for that menu: as other IDE tools do, the popup of each
// edit window is found by its component name and the command is added when
// the menu opens, after the IDE has filled it.
//
// The IDE rebuilds that menu each time it opens and counts on finding it as
// it left it: with a foreign item still inside, Delphi 11 and 12 raise
// "A component named ... already exists" on the third opening. So the command
// is taken out before the IDE's handler runs and put back after it. The item
// itself is kept, never freed while its menu lives: freeing it and hooking
// again on a change of language crashed the Delphi 13 IDE.

interface

uses System.Classes, System.Generics.Collections, Vcl.Menus, Vcl.Forms, ToolsAPI;

type
  TStylerEditorMenu = class(TComponent)
  private
    FExecute: TNotifyEvent;
    FCaption, FHint: string;
    FPopups: TList<TPopupMenu>;
    FOriginal: TList<TNotifyEvent>;
    // One item per hooked menu, owned here; nil once its menu destroyed it.
    FItems: TList<TMenuItem>;
    FNotifier: Integer;
    procedure Popup(Sender: TObject);
    procedure Detach(Index: Integer; Restore: Boolean);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor CreateMenu(const Caption, Hint: string; Execute: TNotifyEvent);
    destructor Destroy; override;
    // Hooks the editor popup of one edit window; harmless when already hooked.
    procedure Attach(Form: TCustomForm);
    // New texts for the command (the language changed), also where it is already
    // in a menu. The hooks stay as they are: nothing is removed from the IDE menus.
    procedure SetTexts(const Caption, Hint: string);
  end;

const
  EditorPopupName = 'EditorLocalMenu';
  EditorMenuItemName = 'CSCoderUnitStylerEditorItem';

implementation

uses System.SysUtils, Vcl.ComCtrls, DockForm;

type
  TEditWindowNotifier = class(TNotifierObject, INTAEditServicesNotifier)
  private
    FOwner: TStylerEditorMenu;
  public
    constructor Create(Owner: TStylerEditorMenu);
    procedure WindowShow(const EditWindow: INTAEditWindow; Show, LoadedFromDesktop: Boolean);
    procedure WindowNotification(const EditWindow: INTAEditWindow; Operation: TOperation);
    procedure WindowActivated(const EditWindow: INTAEditWindow);
    procedure WindowCommand(const EditWindow: INTAEditWindow; Command, Param: Integer; var Handled: Boolean);
    procedure EditorViewActivated(const EditWindow: INTAEditWindow; const EditView: IOTAEditView);
    procedure EditorViewModified(const EditWindow: INTAEditWindow; const EditView: IOTAEditView);
    procedure DockFormVisibleChanged(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
    procedure DockFormUpdated(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
    procedure DockFormRefresh(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
  end;

constructor TEditWindowNotifier.Create(Owner: TStylerEditorMenu);
begin
  inherited Create;
  FOwner := Owner;
end;

procedure TEditWindowNotifier.WindowShow(const EditWindow: INTAEditWindow; Show, LoadedFromDesktop: Boolean);
begin
  if (FOwner <> nil) and Show and (EditWindow <> nil) then FOwner.Attach(EditWindow.Form);
end;

procedure TEditWindowNotifier.WindowActivated(const EditWindow: INTAEditWindow);
begin
  if (FOwner <> nil) and (EditWindow <> nil) then FOwner.Attach(EditWindow.Form);
end;

procedure TEditWindowNotifier.EditorViewActivated(const EditWindow: INTAEditWindow; const EditView: IOTAEditView);
begin
  if (FOwner <> nil) and (EditWindow <> nil) then FOwner.Attach(EditWindow.Form);
end;

procedure TEditWindowNotifier.WindowNotification(const EditWindow: INTAEditWindow; Operation: TOperation);
begin end;
procedure TEditWindowNotifier.WindowCommand(const EditWindow: INTAEditWindow; Command, Param: Integer; var Handled: Boolean);
begin end;
procedure TEditWindowNotifier.EditorViewModified(const EditWindow: INTAEditWindow; const EditView: IOTAEditView);
begin end;
procedure TEditWindowNotifier.DockFormVisibleChanged(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
begin end;
procedure TEditWindowNotifier.DockFormUpdated(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
begin end;
procedure TEditWindowNotifier.DockFormRefresh(const EditWindow: INTAEditWindow; DockForm: TDockableForm);
begin end;

constructor TStylerEditorMenu.CreateMenu(const Caption, Hint: string; Execute: TNotifyEvent);
var Editors: IOTAEditorServices; View: IOTAEditView;
begin
  inherited Create(nil);
  FCaption := Caption; FHint := Hint; FExecute := Execute;
  FPopups := TList<TPopupMenu>.Create;
  FOriginal := TList<TNotifyEvent>.Create;
  FItems := TList<TMenuItem>.Create;
  FNotifier := -1;
  if not Supports(BorlandIDEServices, IOTAEditorServices, Editors) then Exit;
  FNotifier := Editors.AddNotifier(TEditWindowNotifier.Create(Self));
  // An edit window that is already open when the package loads.
  View := Editors.TopView;
  if (View <> nil) and (View.GetEditWindow <> nil) then Attach(View.GetEditWindow.Form);
end;

destructor TStylerEditorMenu.Destroy;
var Editors: IOTAEditorServices;
begin
  if (FNotifier >= 0) and Supports(BorlandIDEServices, IOTAEditorServices, Editors) then
    Editors.RemoveNotifier(FNotifier);
  if FPopups <> nil then
    while FPopups.Count > 0 do Detach(Integer(FPopups.Count) - 1, True);
  FItems.Free; FOriginal.Free; FPopups.Free;
  inherited;
end;

procedure TStylerEditorMenu.Attach(Form: TCustomForm);
var Component: TComponent; Menu: TPopupMenu; Mine: TNotifyEvent; Item: TMenuItem;
begin
  if Form = nil then Exit;
  Component := Form.FindComponent(EditorPopupName);
  if not (Component is TPopupMenu) then Exit;
  Menu := TPopupMenu(Component);
  if FPopups.Contains(Menu) then Exit;
  Mine := Popup;
  FPopups.Add(Menu);
  FOriginal.Add(Menu.OnPopup);
  // No owner: several edit windows mean several items with the same name.
  Item := TMenuItem.Create(nil);
  Item.Name := EditorMenuItemName;
  Item.Caption := FCaption;
  Item.Hint := FHint;
  Item.OnClick := FExecute;
  Item.FreeNotification(Self);
  FItems.Add(Item);
  Menu.FreeNotification(Self);
  Menu.OnPopup := Mine;
end;

procedure TStylerEditorMenu.SetTexts(const Caption, Hint: string);
var Item: TMenuItem;
begin
  FCaption := Caption; FHint := Hint;
  for Item in FItems do
    if Item <> nil then
    begin
      Item.Caption := Caption;
      Item.Hint := Hint;
    end;
end;

procedure TStylerEditorMenu.Detach(Index: Integer; Restore: Boolean);
var Menu: TPopupMenu; Item: TMenuItem; Mine: TNotifyEvent;
begin
  Menu := FPopups[Index];
  Item := FItems[Index];
  // Out of the lists first: freeing the item below comes back as a notification.
  FItems[Index] := nil;
  if Item <> nil then
  begin
    Item.RemoveFreeNotification(Self);
    if Item.Parent <> nil then Item.Parent.Remove(Item);
    Item.Free;
  end;
  if Restore then
  begin
    Mine := Popup;
    // Give the handler back only while it is still ours: a tool loaded later
    // may have chained its own in front.
    {$WARN UNSAFE_CAST OFF}
    if (TMethod(Menu.OnPopup).Code = TMethod(Mine).Code) and (TMethod(Menu.OnPopup).Data = TMethod(Mine).Data) then
      Menu.OnPopup := FOriginal[Index];
    {$WARN UNSAFE_CAST ON}
    Menu.RemoveFreeNotification(Self);
  end;
  FPopups.Delete(Index); FOriginal.Delete(Index); FItems.Delete(Index);
end;

procedure TStylerEditorMenu.Notification(AComponent: TComponent; Operation: TOperation);
var Index: Integer;
begin
  inherited;
  if Operation <> opRemove then Exit;
  // A menu being destroyed takes the item inside it along: forget it, do not free it.
  if (FItems <> nil) and (AComponent is TMenuItem) then
  begin
    Index := Integer(FItems.IndexOf(TMenuItem(AComponent)));
    if Index >= 0 then FItems[Index] := nil;
  end;
  if (FPopups <> nil) and (AComponent is TPopupMenu) then
  begin
    Index := Integer(FPopups.IndexOf(TPopupMenu(AComponent)));
    if Index >= 0 then Detach(Index, False);
  end;
end;

procedure TStylerEditorMenu.Popup(Sender: TObject);
var Index: Integer; Menu: TPopupMenu; Item: TMenuItem;
begin
  if not (Sender is TPopupMenu) then Exit;
  Menu := TPopupMenu(Sender);
  Index := Integer(FPopups.IndexOf(Menu));
  if Index < 0 then Exit;
  Item := FItems[Index];
  // The IDE gets its menu back exactly as it left it, fills it, and only then
  // the command goes in, after whatever the IDE built.
  if (Item <> nil) and (Item.Parent <> nil) then Item.Parent.Remove(Item);
  if Assigned(FOriginal[Index]) then FOriginal[Index](Sender);
  if Item <> nil then Menu.Items.Add(Item);
end;

end.
