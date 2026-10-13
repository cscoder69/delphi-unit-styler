unit CSCoder.Styler.SettingsForm;


interface

uses System.Classes, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.Grids, Vcl.ComCtrls,
  CSCoder.Styler.Types, CSCoder.Styler.Strings;

type
  TSettingsForm = class(TForm)
  private
    FLanguage: TStylerLanguage;
    FOneLine, FWrap, FAlpha, FAlphaFull, FIndent, FPriority, FGroupsEnabled, FBlank: TCheckBox;
    FColumns: TEdit;
    FShortcut: THotKey;
    FLanguageChoice: TComboBox;
    FPosition: TComboBox;
    FAutoSave, FBackup: TCheckBox;
    FExcludeInterface, FExcludeImplementation, FBeforeSections, FAfterSections: TCheckBox;
    FExcludedUnits, FProtected: TMemo;
    FSpaces: TEdit;
    FPriorities: TMemo;
    FGroups: TStringGrid;
    FEditingGroups: TStringGrid;
    FUnitPaths, FIgnored: TArray<string>;
    FSettingsFolder, FProjectDirectory: string;
    FBackupInfo: TLabel;
    FBackupKeep: TCheckBox;
    FBackupDelete: TButton;
    procedure OpenFolderClick(Sender: TObject);
    procedure CleanBackupsClick(Sender: TObject);
    procedure DeleteBackupsClick(Sender: TObject);
    procedure ShowBackups(const Done: string);
    procedure LayoutClick(Sender: TObject);
    procedure EditIgnoredClick(Sender: TObject);
    procedure EditListClick(Sender: TObject);
    procedure EditGroupsClick(Sender: TObject);
    procedure RestoreProtectedClick(Sender: TObject);
    procedure GroupAction(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    function ReadOptions: TUsesOptions;
  public
    Original: TUsesOptions;
    // UnitPaths: project unit files relative to the project folder; they feed
    // the folder list offered by the ignored paths editor.
    // HasProject False: no project is open, so only the rules of the add-on
    // can be edited and what belongs to a project stays disabled.
    // ProjectDirectory: folder whose .backup the clean up command looks at;
    // empty where there is none, as in the demonstration.
    constructor CreateSettings(Owner: TComponent; Language: TStylerLanguage;
      const Options: TUsesOptions; const UnitPaths: TArray<string> = nil;
      const SettingsFolder: string = ''; HasProject: Boolean = True;
      const ProjectDirectory: string = '');
  end;

function EditSettings(Owner: TComponent; Language: TStylerLanguage;
  var Options: TUsesOptions; const UnitPaths: TArray<string> = nil;
  const SettingsFolder: string = ''; HasProject: Boolean = True;
  const ProjectDirectory: string = ''): Boolean;

implementation

uses System.SysUtils, Winapi.Windows, Winapi.ShellAPI, Vcl.Graphics, Vcl.CheckLst, CSCoder.Styler.UsesOrganizer,
  CSCoder.Styler.ControlHelp, CSCoder.Styler.ProjectSettings, CSCoder.Styler.Backup;

function SplitSelectors(const Text: string): TArray<string>;
var Part: string;
begin
  Result := nil;
  for Part in Text.Split([';']) do
    if Trim(Part) <> '' then Result := Result + [Trim(Part)];
end;

constructor TSettingsForm.CreateSettings(Owner: TComponent;
  Language: TStylerLanguage; const Options: TUsesOptions; const UnitPaths: TArray<string>;
  const SettingsFolder: string; HasProject: Boolean; const ProjectDirectory: string);
var I: Integer; LabelControl: TLabel; B: TButton; Content, Formatting, Groups, Exclusions: TGroupBox; NoProject: string;

  function Check(Id: TStylerText; X, Y: Integer; Value: Boolean): TCheckBox;
  begin
    Result := TCheckBox.Create(Self); Result.Parent := Content;
    Result.SetBounds(X, Y, Content.ClientWidth - 16, 20);
    Result.Caption := L(Id, FLanguage); Result.Checked := Value;
    Explain(Result, RuleHelp(Id));
  end;

  procedure EditButton(const Text: string; Y, TagValue: Integer; Handler: TNotifyEvent);
  begin
    B := TButton.Create(Self); B.Parent := Content;
    B.SetBounds(8, Y, 140, 24); B.Caption := Text;
    B.Tag := TagValue; B.OnClick := Handler;
    if Text = L(stEditPriorities, FLanguage) then
    begin B.Name := 'btnEditPriority'; Explain(B, L(stEditPrioritiesHint, FLanguage)); end
    else if Text = L(stEditGroups, FLanguage) then
    begin B.Name := 'btnEditGroups'; Explain(B, L(stEditGroupsHint, FLanguage)); end;
  end;

begin
  inherited CreateNew(Owner);
  FLanguage := Language; Original := Options; NoProject := L(stNoProjectHint, Language);
  FUnitPaths := Copy(UnitPaths); FIgnored := Copy(Options.IgnoredPaths);
  FSettingsFolder := SettingsFolder; FProjectDirectory := ProjectDirectory;
  Caption := 'CS.Coder - Unit Styler | ' + L(stSettings, Language);
  Font.Name := 'Segoe UI'; Font.Size := 9;
  Position := poOwnerFormCenter; BorderStyle := bsDialog;
  ClientWidth := 420; ClientHeight := 650;
  LabelControl := TLabel.Create(Self); LabelControl.Parent := Self;
  LabelControl.SetBounds(12, 10, 396, 24); LabelControl.Caption := L(stSetTitle, FLanguage);
  Explain(LabelControl, L(stSetTitleHint, FLanguage));
  LabelControl.Font.Size := 12; LabelControl.Font.Style := [fsBold];
  LabelControl := TLabel.Create(Self); LabelControl.Parent := Self;
  LabelControl.SetBounds(12, 38, 396, 18); LabelControl.Caption := L(stSetSubtitle, FLanguage);
  if not HasProject then LabelControl.Caption := L(stSetSubtitleNoProject, FLanguage);
  Explain(LabelControl, L(stSetSubtitleHint, FLanguage));
  Formatting := TGroupBox.Create(Self); Formatting.Parent := Self;
  Formatting.SetBounds(12, 62, 194, 296); Formatting.Caption := L(stGrpFormatting, FLanguage);
  Explain(Formatting, L(stGrpFormattingHint, FLanguage));
  Groups := TGroupBox.Create(Self); Groups.Parent := Self;
  Groups.SetBounds(214, 62, 194, 296); Groups.Caption := L(stGrpGroups, FLanguage);
  Explain(Groups, L(stGrpGroupsHint, FLanguage));
  Exclusions := TGroupBox.Create(Self); Exclusions.Parent := Self;
  Exclusions.SetBounds(12, 366, 396, 100); Exclusions.Caption := L(stGrpProject, FLanguage);
  Explain(Exclusions, L(stGrpProjectHint, FLanguage));
  Content := Formatting;
  FOneLine := Check(stOnePerLine, 8, 22, Options.OneUnitPerLine);
  // The two line layouts exclude each other; with neither, line breaks are kept.
  FWrap := Check(stWrapUnits, 8, 46, Options.WrapUnits and not Options.OneUnitPerLine);
  FOneLine.OnClick := LayoutClick; FWrap.OnClick := LayoutClick;
  FColumns := TEdit.Create(Self); FColumns.Parent := Content;
  FColumns.SetBounds(26, 70, 44, 22); FColumns.NumbersOnly := True;
  FColumns.Text := IntToStr(Options.MaxLineWidth);
  if (Options.MaxLineWidth < MinLineWidth) or (Options.MaxLineWidth > MaxLineWidthLimit) then
    FColumns.Text := IntToStr(DefaultLineWidth);
  Explain(FColumns, RuleHelp(stColumns));
  LabelControl := TLabel.Create(Self); LabelControl.Parent := Content;
  LabelControl.SetBounds(76, 74, 100, 18); LabelControl.Caption := L(stColumns, Language);
  Explain(LabelControl, RuleHelp(stColumns));
  FAlpha := Check(stAlphabetical, 8, 98, Options.Alphabetical);
  FAlpha.WordWrap := True; FAlpha.Height := 34;
  // Only meaningful while sorting is on; the riskier of the two.
  FAlphaFull := Check(stAlphabeticalFull, 26, 134, Options.Alphabetical and not Options.SortFirstNameOnly);
  FAlphaFull.Width := 160;
  FAlpha.OnClick := LayoutClick;
  FIndent := Check(stIndent, 8, 158, Options.IndentationEnabled);
  FIndent.Width := 178;
  FSpaces := TEdit.Create(Self); FSpaces.Parent := Content;
  FSpaces.SetBounds(26, 182, 44, 22); FSpaces.NumbersOnly := True;
  FSpaces.Text := IntToStr(Length(Options.Indentation));
  Explain(FSpaces, RuleHelp(stSpaces));
  LabelControl := TLabel.Create(Self); LabelControl.Parent := Content;
  LabelControl.SetBounds(76, 186, 48, 18); LabelControl.Caption := L(stSpaces, Language);
  Explain(LabelControl, RuleHelp(stSpaces));
  FBeforeSections := Check(stBlankBeforeSections, 8, 214, Options.BlankBeforeSections);
  FAfterSections := Check(stBlankAfterSections, 8, 252, Options.BlankAfterSections);
  LayoutClick(nil);
  FBeforeSections.WordWrap := True; FBeforeSections.Height := 34;
  FAfterSections.WordWrap := True; FAfterSections.Height := 34;

  Content := Groups;
  FPriority := Check(stPriorities, 8, 22, Options.PrioritiesEnabled);
  EditButton(L(stEditPriorities, FLanguage), 46, 0, EditListClick);
  FPriorities := TMemo.Create(Self); FPriorities.Parent := Self; FPriorities.Visible := False;
  for I := 0 to Integer(High(Options.Priorities)) do FPriorities.Lines.Add(Options.Priorities[I]);
  FGroupsEnabled := Check(stGroups, 8, 74, Options.GroupingEnabled);
  EditButton(L(stEditGroups, FLanguage), 98, 0, EditGroupsClick);
  FGroups := TStringGrid.Create(Self); FGroups.Parent := Self; FGroups.Visible := False;
  FGroups.ColCount := 2; FGroups.FixedCols := 0;
  FGroups.RowCount := Integer(Length(Options.Groups)) + 1;
  if FGroups.RowCount < 2 then FGroups.RowCount := 2;
  FGroups.Cells[0, 0] := L(stGroupName, Language);
  FGroups.Cells[1, 0] := L(stSelectors, Language);
  for I := 0 to Integer(High(Options.Groups)) do
  begin
    FGroups.Cells[0, I + 1] := Options.Groups[I].Name;
    FGroups.Cells[1, I + 1] := string.Join('; ', Options.Groups[I].Selectors);
  end;
  FBlank := Check(stBlankGroups, 8, 126, Options.BlankLinesBetweenGroups);
  LabelControl := TLabel.Create(Self); LabelControl.Parent := Content;
  FBlank.WordWrap := True; FBlank.Height := 34;
  LabelControl.SetBounds(8, 177, 94, 18); LabelControl.Caption := L(stUngrouped, FLanguage);
  Explain(LabelControl, L(stUngroupedHint, FLanguage));
  FPosition := TComboBox.Create(Self); FPosition.Parent := Content;
  FPosition.SetBounds(102, 172, 84, 24); FPosition.Style := csDropDownList;
  FPosition.Items.Add(L(stPosFirst, FLanguage)); FPosition.Items.Add(L(stPosLast, FLanguage));
  Explain(FPosition, L(stPositionHint, FLanguage));
  FPosition.ItemIndex := 1;
  if Options.UngroupedPosition = upFirst then FPosition.ItemIndex := 0;
  // Advanced: what the tool never moves, in any project.
  B := TButton.Create(Self); B.Parent := Content;
  B.SetBounds(8, 212, 140, 24); B.Caption := L(stProtectedButton, FLanguage);
  B.Name := 'btnProtectedUnits'; B.Tag := 2; B.OnClick := EditListClick;
  Explain(B, L(stProtectedButtonHint, FLanguage));
  FProtected := TMemo.Create(Self); FProtected.Parent := Self; FProtected.Visible := False;
  for I := 0 to Integer(High(Options.ProtectedUnits)) do FProtected.Lines.Add(Options.ProtectedUnits[I]);
  Content := Exclusions;
  FExcludeInterface := Check(stExcludeInterface, 8, 20, usInterface in Options.ExcludedSections);
  FExcludeImplementation := Check(stExcludeImplementation, 8, 44, usImplementation in Options.ExcludedSections);
  FExcludeInterface.Hint := L(stExcludeInterfaceHint, FLanguage);
  FExcludeImplementation.Hint := L(stExcludeImplementationHint, FLanguage);
  FExcludeInterface.ParentShowHint := False; FExcludeInterface.ShowHint := True;
  FExcludeImplementation.ParentShowHint := False; FExcludeImplementation.ShowHint := True;
  EditButton(L(stPreserveButton, FLanguage), 68, 1, EditListClick);
  B.Name := 'btnPreservedUnits'; B.Width := 120;
  B.Hint := L(stPreserveButtonHint, FLanguage);
  B.ParentShowHint := False; B.ShowHint := True;
  B := TButton.Create(Self); B.Parent := Content;
  B.SetBounds(136, 68, 120, 24); B.Caption := L(stIgnoreButton, FLanguage);
  B.Name := 'btnIgnoredPaths'; B.OnClick := EditIgnoredClick;
  Explain(B, L(stIgnoreButtonHint, FLanguage));
  B := TButton.Create(Self); B.Parent := Content;
  B.SetBounds(264, 68, 120, 24); B.Caption := L(stCleanButton, FLanguage);
  B.Name := 'btnCleanBackups'; B.OnClick := CleanBackupsClick; B.Enabled := FProjectDirectory <> '';
  Explain(B, L(stCleanButtonHint, FLanguage));
  FExcludedUnits := TMemo.Create(Self); FExcludedUnits.Parent := Self; FExcludedUnits.Visible := False;
  for I := 0 to Integer(High(Options.ExcludedUnits)) do FExcludedUnits.Lines.Add(Options.ExcludedUnits[I]);
  if not HasProject then
  begin
    // Rules of the add-on are global; what belongs to a project needs one open.
    Exclusions.Caption := L(stGrpProjectNone, FLanguage);
    Explain(Exclusions, NoProject);
    for I := 0 to Exclusions.ControlCount - 1 do
    begin
      Exclusions.Controls[I].Enabled := False;
      Explain(Exclusions.Controls[I], NoProject);
    end;
  end;
  LabelControl := TLabel.Create(Self); LabelControl.Parent := Self;
  LabelControl.SetBounds(12, 528, 206, 18); LabelControl.Caption := L(stShortcutLabel, FLanguage);
  FShortcut := THotKey.Create(Self); FShortcut.Parent := Self;
  FShortcut.SetBounds(222, 524, 130, 22);
  FShortcut.InvalidKeys := [hcNone, hcShift]; FShortcut.Modifiers := [hkCtrl, hkAlt];
  FShortcut.HotKey := TShortCut(Options.Shortcut);
  Explain(FShortcut, L(stShortcutHint, FLanguage));
  Explain(LabelControl, FShortcut.Hint);
  // Same choices as the other CS.Coder tools: automatic, then each language in its own name.
  LabelControl := TLabel.Create(Self); LabelControl.Parent := Self;
  LabelControl.SetBounds(12, 556, 206, 18); LabelControl.Caption := L(stLanguage, FLanguage);
  FLanguageChoice := TComboBox.Create(Self); FLanguageChoice.Parent := Self;
  FLanguageChoice.SetBounds(222, 552, 130, 23); FLanguageChoice.Style := csDropDownList;
  FLanguageChoice.Name := 'cbLanguage';
  FLanguageChoice.Items.Add(L(stLanguageAuto, FLanguage));
  FLanguageChoice.ItemIndex := 0;
  for I := Ord(Low(TStylerLanguage)) to Ord(High(TStylerLanguage)) do
  begin
    FLanguageChoice.Items.Add(StylerLanguageNames[TStylerLanguage(I)]);
    if SameText(StylerLanguageCodes[TStylerLanguage(I)], Trim(Options.Language)) then FLanguageChoice.ItemIndex := I + 1;
  end;
  Explain(FLanguageChoice, L(stLanguageHint, FLanguage));
  Explain(LabelControl, FLanguageChoice.Hint);
  LabelControl := TLabel.Create(Self); LabelControl.Parent := Self;
  FAutoSave := TCheckBox.Create(Self); FAutoSave.Parent := Self;
  FAutoSave.SetBounds(12, 474, 396, 20);
  FAutoSave.Caption := L(stAutoSave, FLanguage); FAutoSave.Checked := Options.AutoSaveUnits;
  Explain(FAutoSave, L(stAutoSaveHint, FLanguage));
  FAutoSave.ShowHint := True;
  FBackup := TCheckBox.Create(Self); FBackup.Parent := Self;
  FBackup.SetBounds(12, 498, 396, 20);
  FBackup.Caption := L(stBackupCheck, FLanguage); FBackup.Checked := Options.BackupUnits;
  Explain(FBackup, L(stBackupCheckHint, FLanguage));
  LabelControl.SetBounds(12, 582, 396, 18);
  LabelControl.Caption := L(stSaveNote, FLanguage);
  Explain(LabelControl, L(stSaveNoteExplain, FLanguage));
  B := TButton.Create(Self); B.Parent := Self; B.SetBounds(12, 610, 150, 28);
  B.Caption := L(stFolderButton, FLanguage); B.Name := 'btnSettingsFolder';
  B.OnClick := OpenFolderClick; B.Enabled := FSettingsFolder <> '';
  Explain(B, L(stFolderButtonHint, FLanguage));
  B := TButton.Create(Self); B.Parent := Self; B.SetBounds(224, 610, 88, 28);
  B.Caption := L(stCancel, Language); B.ModalResult := mrCancel; B.Cancel := True;
  Explain(B, L(stSetCancelHint, FLanguage));
  B := TButton.Create(Self); B.Parent := Self; B.SetBounds(320, 610, 88, 28);
  B.Caption := L(stSave, FLanguage); B.OnClick := SaveClick;
  Explain(B, L(stSaveHint, FLanguage));
  if not HasProject then Explain(B, L(stSaveHintNoProject, FLanguage));
  ApplyHostTheme(Self);
end;

procedure TSettingsForm.EditListClick(Sender: TObject);
var Dialog: TForm; Memo, Model: TMemo; LabelControl: TLabel; B: TButton;
begin
  Model := FPriorities;
  if TButton(Sender).Tag = 1 then Model := FExcludedUnits;
  if TButton(Sender).Tag = 2 then Model := FProtected;
  Dialog := TStylerDialog.CreateNew(Self);
  try
    Dialog.Caption := L(stDlgPriority, FLanguage);
    if Model = FExcludedUnits then Dialog.Caption := L(stDlgPreserve, FLanguage);
    if Model = FProtected then Dialog.Caption := L(stDlgProtected, FLanguage);
    Dialog.Font.Assign(Font); Dialog.BorderStyle := bsDialog;
    Dialog.Position := poOwnerFormCenter; Dialog.ClientWidth := 440; Dialog.ClientHeight := 240;
    LabelControl := TLabel.Create(Dialog); LabelControl.Parent := Dialog;
    LabelControl.SetBounds(8, 8, 424, 18); LabelControl.Caption := L(stPriorityNames, FLanguage);
    if Model = FExcludedUnits then LabelControl.Caption := L(stExcludedUnits, FLanguage);
    if Model = FProtected then LabelControl.Caption := L(stProtectedLabel, FLanguage);
    Memo := TMemo.Create(Dialog); Memo.Parent := Dialog; Memo.SetBounds(8, 30, 424, 166);
    Memo.ScrollBars := ssVertical; Memo.Lines.Assign(Model.Lines);
    if Model = FExcludedUnits then
      Explain(Memo, L(stPreserveMemoHint, FLanguage))
    else if Model = FProtected then
      Explain(Memo, L(stProtectedMemoHint, FLanguage))
    else Explain(Memo, RuleHelp(stPriorityNames));
    Explain(LabelControl, Memo.Hint);
    if Model = FProtected then
    begin
      B := TButton.Create(Dialog); B.Parent := Dialog; B.SetBounds(8, 204, 176, 28);
      B.Caption := L(stRestoreDefault, FLanguage); B.OnClick := RestoreProtectedClick;
      Explain(B, L(stRestoreDefaultHint, FLanguage));
    end;
    B := TButton.Create(Dialog); B.Parent := Dialog; B.SetBounds(216, 204, 104, 28);
    B.Caption := L(stCancel, FLanguage); B.ModalResult := mrCancel; B.Cancel := True;
    Explain(B, L(stDlgCancelHint, FLanguage));
    B := TButton.Create(Dialog); B.Parent := Dialog; B.SetBounds(328, 204, 104, 28);
    B.Caption := 'OK'; B.ModalResult := mrOk;
    Explain(B, L(stDlgOkHint, FLanguage)); B.Default := True;
    ApplyHostTheme(Dialog);
    if Dialog.ShowModal = mrOk then Model.Lines.Assign(Memo.Lines);
  finally Dialog.Free; end;
end;

procedure TSettingsForm.LayoutClick(Sender: TObject);
begin
  if (Sender = FOneLine) and FOneLine.Checked then FWrap.Checked := False;
  if (Sender = FWrap) and FWrap.Checked then FOneLine.Checked := False;
  // The width only matters to the layout that fills lines.
  FColumns.Enabled := FWrap.Checked;
  if FAlphaFull <> nil then
  begin
    FAlphaFull.Enabled := FAlpha.Checked;
    if not FAlpha.Checked then FAlphaFull.Checked := False;
  end;
end;

procedure TSettingsForm.RestoreProtectedClick(Sender: TObject);
var I: Integer; Dialog: TComponent; Line: string;
begin
  Dialog := TButton(Sender).Owner;
  for I := 0 to Dialog.ComponentCount - 1 do
    if Dialog.Components[I] is TMemo then
    begin
      TMemo(Dialog.Components[I]).Lines.Clear;
      for Line in DefaultProtectedUnits do TMemo(Dialog.Components[I]).Lines.Add(Line);
    end;
end;

procedure TSettingsForm.OpenFolderClick(Sender: TObject);
begin
  // The folder may not exist before the first save; opening it is harmless.
  if not ForceDirectories(FSettingsFolder) then
  begin
    Application.MessageBox(PChar(L(stFolderOpenError, FLanguage) + sLineBreak + FSettingsFolder), PChar(Caption), MB_ICONERROR);
    Exit;
  end;
  ShellExecute(Handle, 'open', PChar(FSettingsFolder), nil, nil, SW_SHOWNORMAL);
end;

// Run folders are named yyyy-mm-dd_hh-nn-ss.
function RunDate(const Folder: string): string;
var Name: string;
begin
  Name := ExtractFileName(Folder);
  Result := Format('%s/%s/%s %s:%s', [Copy(Name, 9, 2), Copy(Name, 6, 2), Copy(Name, 1, 4), Copy(Name, 12, 2), Copy(Name, 15, 2)]);
end;

function SizeText(Bytes: Int64): string;
begin
  if Bytes >= 1024 * 1024 then Result := FormatFloat('0.0', Bytes / (1024 * 1024)) + ' MB'
  else Result := IntToStr((Bytes + 1023) div 1024) + ' KB';
end;

procedure TSettingsForm.ShowBackups(const Done: string);
var Runs: TBackupRuns; Count: Integer; Info, Files: string;
begin
  Runs := FindBackupRuns(FProjectDirectory);
  Count := Integer(Length(Runs.Folders));
  if Runs.Files = 1 then Files := L(stFileOne, FLanguage) else Files := LF(stFileMany, FLanguage, [Runs.Files]);
  if Count = 0 then Info := L(stBackupNone, FLanguage)
  else if Count = 1 then
    Info := LF(stBackupOne, FLanguage, [RunDate(Runs.Folders[0]), Files, SizeText(Runs.Bytes)])
  else
    Info := LF(stBackupMany, FLanguage,
      [Count, RunDate(Runs.Folders[0]), RunDate(Runs.Folders[Count - 1]), Files, SizeText(Runs.Bytes)]);
  if Count > 0 then Info := Info + sLineBreak + L(stBackupWhere, FLanguage);
  if Done <> '' then Info := Done + sLineBreak + Info;
  FBackupInfo.Caption := Info;
  // Keeping the newest only makes sense while there is an older one to remove.
  FBackupKeep.Enabled := Count > 1;
  if Count <= 1 then FBackupKeep.Checked := False;
  FBackupDelete.Enabled := Count > 0;
end;

procedure TSettingsForm.CleanBackupsClick(Sender: TObject);
var Dialog: TForm; B: TButton;
begin
  Dialog := TStylerDialog.CreateNew(Self);
  try
    Dialog.Caption := L(stDlgClean, FLanguage);
    Dialog.Font.Assign(Font); Dialog.BorderStyle := bsDialog;
    Dialog.Position := poOwnerFormCenter; Dialog.ClientWidth := 440; Dialog.ClientHeight := 152;
    FBackupInfo := TLabel.Create(Dialog); FBackupInfo.Parent := Dialog;
    FBackupInfo.AutoSize := False; FBackupInfo.WordWrap := True;
    FBackupInfo.SetBounds(8, 8, 424, 72);
    Explain(FBackupInfo, L(stBackupInfoHint, FLanguage) + sLineBreak +
      IncludeTrailingPathDelimiter(FProjectDirectory) + BackupFolderName);
    FBackupKeep := TCheckBox.Create(Dialog); FBackupKeep.Parent := Dialog;
    FBackupKeep.SetBounds(8, 86, 424, 20); FBackupKeep.Caption := L(stKeepNewest, FLanguage);
    FBackupKeep.Checked := True;
    Explain(FBackupKeep, L(stKeepNewestHint, FLanguage));
    FBackupDelete := TButton.Create(Dialog); FBackupDelete.Parent := Dialog;
    FBackupDelete.SetBounds(216, 116, 104, 28); FBackupDelete.Caption := L(stDelete, FLanguage);
    FBackupDelete.OnClick := DeleteBackupsClick;
    Explain(FBackupDelete, L(stDeleteHint, FLanguage));
    B := TButton.Create(Dialog); B.Parent := Dialog; B.SetBounds(328, 116, 104, 28);
    B.Caption := L(stClose, FLanguage); B.ModalResult := mrCancel; B.Cancel := True; B.Default := True;
    Explain(B, L(stCleanCloseHint, FLanguage));
    ShowBackups('');
    ApplyHostTheme(Dialog);
    Dialog.ShowModal;
  finally
    FBackupInfo := nil; FBackupKeep := nil; FBackupDelete := nil;
    Dialog.Free;
  end;
end;

procedure TSettingsForm.DeleteBackupsClick(Sender: TObject);
var Before, Removed, Expected: Integer; Done: string;
begin
  Before := Integer(Length(FindBackupRuns(FProjectDirectory).Folders));
  Expected := Before;
  if FBackupKeep.Checked then Dec(Expected);
  Screen.Cursor := crHourGlass;
  try Removed := DeleteBackupRuns(FProjectDirectory, FBackupKeep.Checked);
  finally Screen.Cursor := crDefault; end;
  if Removed = 1 then Done := L(stDeletedOne, FLanguage) else Done := LF(stDeletedMany, FLanguage, [Removed]);
  if Removed < Expected then
    Done := Done + LF(stDeleteFailed, FLanguage, [Expected - Removed]);
  ShowBackups(Done);
end;

procedure TSettingsForm.EditIgnoredClick(Sender: TObject);
var Dialog: TForm; List: TCheckListBox; Memo: TMemo; LabelControl: TLabel; B: TButton;
  Folders: TStringList; Path, Folder, Upper, Entry, Line: string; I: Integer;
  Listed: Boolean; Selected: TArray<string>;

  function SameEntry(const Entry, Folder: string): Boolean;
  begin
    Result := SameText(ExcludeTrailingPathDelimiter(StringReplace(Trim(Entry), '/', '\', [rfReplaceAll])),
      ExcludeTrailingPathDelimiter(Folder));
  end;

begin
  Folders := TStringList.Create; Dialog := TStylerDialog.CreateNew(Self);
  try
    // Every folder that holds project units, with its parent folders.
    Folders.Sorted := True; Folders.Duplicates := dupIgnore;
    for Path in FUnitPaths do
    begin
      Folder := ExtractFilePath(Path);
      while Folder <> '' do
      begin
        if (StringReplace(Folder, '..\', '', [rfReplaceAll]) <> '') and
          not ((Length(Folder) <= 3) and (Pos(':', Folder) > 0)) then Folders.Add(Folder);
        Upper := ExtractFilePath(ExcludeTrailingPathDelimiter(Folder));
        if Length(Upper) >= Length(Folder) then Break;
        Folder := Upper;
      end;
    end;
    Dialog.Caption := L(stDlgIgnored, FLanguage);
    Dialog.Font.Assign(Font); Dialog.BorderStyle := bsDialog;
    Dialog.Position := poOwnerFormCenter; Dialog.ClientWidth := 440; Dialog.ClientHeight := 360;
    LabelControl := TLabel.Create(Dialog); LabelControl.Parent := Dialog;
    LabelControl.SetBounds(8, 8, 424, 18);
    LabelControl.Caption := L(stIgnoredLabel, FLanguage);
    List := TCheckListBox.Create(Dialog); List.Parent := Dialog;
    List.SetBounds(8, 30, 424, 180); List.Items.Assign(Folders);
    Explain(List, L(stIgnoredListHint, FLanguage));
    Explain(LabelControl, List.Hint);
    for I := 0 to List.Items.Count - 1 do
      for Entry in FIgnored do
        if SameEntry(Entry, List.Items[I]) then List.Checked[I] := True;
    LabelControl := TLabel.Create(Dialog); LabelControl.Parent := Dialog;
    LabelControl.SetBounds(8, 218, 424, 18);
    LabelControl.Caption := L(stIgnoredOtherLabel, FLanguage);
    Memo := TMemo.Create(Dialog); Memo.Parent := Dialog; Memo.SetBounds(8, 240, 424, 76);
    Memo.ScrollBars := ssVertical;
    Explain(Memo, L(stIgnoredMemoHint, FLanguage));
    Explain(LabelControl, Memo.Hint);
    for Entry in FIgnored do
    begin
      Listed := False;
      for I := 0 to List.Items.Count - 1 do
        if SameEntry(Entry, List.Items[I]) then Listed := True;
      if not Listed then Memo.Lines.Add(Entry);
    end;
    B := TButton.Create(Dialog); B.Parent := Dialog; B.SetBounds(216, 324, 104, 28);
    B.Caption := L(stCancel, FLanguage); B.ModalResult := mrCancel; B.Cancel := True;
    Explain(B, L(stDlgCancelHint, FLanguage));
    B := TButton.Create(Dialog); B.Parent := Dialog; B.SetBounds(328, 324, 104, 28);
    B.Caption := 'OK'; B.ModalResult := mrOk;
    Explain(B, L(stDlgOkHint, FLanguage));
    ApplyHostTheme(Dialog);
    if Dialog.ShowModal = mrOk then
    begin
      Selected := nil;
      for I := 0 to List.Items.Count - 1 do
        if List.Checked[I] then Selected := Selected + [List.Items[I]];
      for Line in Memo.Lines do
        if Trim(Line) <> '' then Selected := Selected + [Trim(Line)];
      FIgnored := Selected;
    end;
  finally Dialog.Free; Folders.Free; end;
end;

procedure TSettingsForm.EditGroupsClick(Sender: TObject);
var Dialog: TForm; Grid: TStringGrid; B: TButton; I: Integer;
begin
  Dialog := TStylerDialog.CreateNew(Self);
  try
    Dialog.Caption := L(stDlgGroups, FLanguage); Dialog.Font.Assign(Font);
    Dialog.BorderStyle := bsDialog; Dialog.Position := poOwnerFormCenter;
    Dialog.ClientWidth := 600; Dialog.ClientHeight := 260;
    Grid := TStringGrid.Create(Dialog); Grid.Parent := Dialog;
    Grid.SetBounds(8, 8, 584, 172); Grid.ColCount := 2; Grid.FixedCols := 0;
    Grid.RowCount := FGroups.RowCount; Grid.ColWidths[0] := 140; Grid.ColWidths[1] := 418;
    Grid.Options := Grid.Options + [goEditing];
    Explain(Grid, L(stGroupsGridHint, FLanguage));
    for I := 0 to FGroups.RowCount - 1 do Grid.Rows[I].Assign(FGroups.Rows[I]);
    FEditingGroups := Grid;
    for I := 0 to 3 do
    begin
      B := TButton.Create(Dialog); B.Parent := Dialog;
      B.SetBounds(8 + I * 148, 186, 140, 26);
      B.Caption := L(TStylerText(Ord(stAdd) + I), FLanguage);
      B.Tag := I; B.OnClick := GroupAction;
      case I of
        0: Explain(B, L(stGroupAddHint, FLanguage));
        1: Explain(B, L(stGroupRemoveHint, FLanguage));
        2: Explain(B, L(stGroupUpHint, FLanguage));
        3: Explain(B, L(stGroupDownHint, FLanguage));
      end;
    end;
    B := TButton.Create(Dialog); B.Parent := Dialog; B.SetBounds(376, 224, 104, 28);
    B.Caption := L(stCancel, FLanguage); B.ModalResult := mrCancel; B.Cancel := True;
    Explain(B, L(stDlgCancelHint, FLanguage));
    B := TButton.Create(Dialog); B.Parent := Dialog; B.SetBounds(488, 224, 104, 28);
    B.Caption := 'OK'; B.ModalResult := mrOk;
    Explain(B, L(stDlgOkHint, FLanguage));
    // No default button: Enter remains available while editing grid cells.
    ApplyHostTheme(Dialog);
    if Dialog.ShowModal = mrOk then
    begin
      Grid.EditorMode := False;
      FGroups.RowCount := Grid.RowCount;
      for I := 0 to Grid.RowCount - 1 do FGroups.Rows[I].Assign(Grid.Rows[I]);
    end;
  finally FEditingGroups := nil; Dialog.Free; end;
end;

procedure TSettingsForm.GroupAction(Sender: TObject);
var Action, R, Target: Integer; A, B: string;
begin
  Action := Integer(TButton(Sender).Tag);
  R := FEditingGroups.Row;
  if Action = 0 then
  begin
    FEditingGroups.RowCount := FEditingGroups.RowCount + 1;
    FEditingGroups.Row := FEditingGroups.RowCount - 1;
  end
  else if Action = 1 then
  begin
    for Target := R to FEditingGroups.RowCount - 2 do FEditingGroups.Rows[Target].Assign(FEditingGroups.Rows[Target + 1]);
    FEditingGroups.Rows[FEditingGroups.RowCount - 1].Clear;
    if FEditingGroups.RowCount > 2 then FEditingGroups.RowCount := FEditingGroups.RowCount - 1;
  end
  else
  begin
    Target := R - 1;
    if Action = 3 then Target := R + 1;
    if (Target < 1) or (Target >= FEditingGroups.RowCount) then Exit;
    A := FEditingGroups.Cells[0, R]; B := FEditingGroups.Cells[1, R];
    FEditingGroups.Rows[R].Assign(FEditingGroups.Rows[Target]);
    FEditingGroups.Cells[0, Target] := A; FEditingGroups.Cells[1, Target] := B;
    FEditingGroups.Row := Target;
  end;
end;

function TSettingsForm.ReadOptions: TUsesOptions;
var I, N: Integer; Spaces: Integer; Line: string;
begin
  Result := Original;
  Result.AutoSaveUnits := FAutoSave.Checked;
  Result.BackupUnits := FBackup.Checked;
  Result.Shortcut := FShortcut.HotKey;
  Result.Language := '';
  if FLanguageChoice.ItemIndex > 0 then Result.Language := StylerLanguageCodes[TStylerLanguage(FLanguageChoice.ItemIndex - 1)];
  Result.IgnoredPaths := Copy(FIgnored);
  Result.BlankBeforeSections := FBeforeSections.Checked;
  Result.BlankAfterSections := FAfterSections.Checked;
  Result.OneUnitPerLine := FOneLine.Checked;
  Result.WrapUnits := FWrap.Checked;
  Result.MaxLineWidth := StrToIntDef(FColumns.Text, 0);
  // An unused width out of range is not worth an error: keep the previous one.
  if not Result.WrapUnits and ((Result.MaxLineWidth < MinLineWidth) or (Result.MaxLineWidth > MaxLineWidthLimit)) then
    Result.MaxLineWidth := Original.MaxLineWidth;
  Result.Alphabetical := FAlpha.Checked;
  Result.SortFirstNameOnly := not FAlphaFull.Checked;
  Result.IndentationEnabled := FIndent.Checked;
  // Keep existing tabs when the indentation setting has not been edited.
  Spaces := StrToIntDef(FSpaces.Text, -1);
  if (Spaces < 0) or (Spaces > 16) then
    raise EArgumentOutOfRangeException.Create(L(stIndentRange, FLanguage));
  if Spaces <> Length(Original.Indentation) then Result.Indentation := StringOfChar(' ', Spaces);
  Result.PrioritiesEnabled := FPriority.Checked;
  Result.Priorities := nil;
  for Line in FPriorities.Lines do
    if Trim(Line) <> '' then Result.Priorities := Result.Priorities + [Trim(Line)];
  Result.GroupingEnabled := FGroupsEnabled.Checked;
  Result.Groups := nil;
  for I := 1 to FGroups.RowCount - 1 do
  begin
    if (Trim(FGroups.Cells[0, I]) = '') and (Trim(FGroups.Cells[1, I]) = '') then Continue;
    N := Integer(Length(Result.Groups));
    SetLength(Result.Groups, N + 1);
    Result.Groups[N].Name := Trim(FGroups.Cells[0, I]);
    Result.Groups[N].Selectors := SplitSelectors(FGroups.Cells[1, I]);
  end;
  Result.BlankLinesBetweenGroups := FBlank.Checked;
  Result.UngroupedPosition := upLast;
  if FPosition.ItemIndex = 0 then Result.UngroupedPosition := upFirst;
  Result.ExcludedSections := [];
  if FExcludeInterface.Checked then Include(Result.ExcludedSections, usInterface);
  if FExcludeImplementation.Checked then Include(Result.ExcludedSections, usImplementation);
  Result.ProtectedUnits := nil;
  for Line in FProtected.Lines do
    if Trim(Line) <> '' then Result.ProtectedUnits := Result.ProtectedUnits + [Trim(Line)];
  Result.ExcludedUnits := nil;
  for Line in FExcludedUnits.Lines do
    if Trim(Line) <> '' then Result.ExcludedUnits := Result.ExcludedUnits + [Trim(Line)];
end;

procedure TSettingsForm.SaveClick(Sender: TObject);
begin
  try
    ValidateUsesOptions(ReadOptions);
    ModalResult := mrOk;
  except
    // Say what is wrong, so it can be corrected without guessing.
    on E: Exception do
      Application.MessageBox(PChar(L(stCannotSave, FLanguage) + sLineBreak + sLineBreak + E.Message),
        PChar(Caption), MB_ICONWARNING);
  end;
end;

function EditSettings(Owner: TComponent; Language: TStylerLanguage;
  var Options: TUsesOptions; const UnitPaths: TArray<string>;
  const SettingsFolder: string; HasProject: Boolean; const ProjectDirectory: string): Boolean;
var F: TSettingsForm;
begin
  F := TSettingsForm.CreateSettings(Owner, Language, Options, UnitPaths, SettingsFolder, HasProject, ProjectDirectory);
  try
    Result := F.ShowModal = mrOk;
    if Result then Options := F.ReadOptions;
  finally F.Free; end;
end;

end.
