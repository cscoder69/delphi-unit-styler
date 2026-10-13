unit CSCoder.Styler.ExecutionForm;


interface

uses System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, CSCoder.Styler.Types, CSCoder.Styler.Strings, CSCoder.Styler.Workspace;

type
  TExecutionForm = class(TForm)
  private
    FWorkspace: IStylerWorkspace;
    FLanguage: TStylerLanguage;
    FOptions: TUsesOptions;
    FNames: TArray<string>;
    FPaths: TArray<string>;
    FOpenIndices: TArray<Integer>;
    FIndices: TArray<Integer>;
    FProposals: TArray<TStylerProposal>;
    FScope: TRadioGroup;
    FViewProposal: TStylerProposal;
    FViewIndex: Integer;
    FHasPreview: Boolean;
    FStatus, FCount, FRuleSummary, FSaveNote: TLabel;
    FPreviewBefore, FPreviewAfter: TRichEdit;
    FPreviewDiagnostics: TMemo;
    FApply, FCancel, FPreviewButton, FSettingsButton: TButton;
    FUnitErrors: TArray<string>;
    FBusy, FStop, FUnattended: Boolean;
    FSmokeDecision: Integer;
    FLastExecutionIssues, FExecutionUnit, FLastError: string;
    procedure SetBusy(Value: Boolean);
    procedure Step(const Action: string; Done, Total: Integer);
    procedure CancelClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ShowExecutionIssues(const Issues: string);
    procedure CopyExecutionIssues(Sender: TObject);
    procedure RefreshSummary;
    procedure RefreshPreview;
    procedure AnalyzeCurrentUnit;
    procedure SmokeConfirmation(Sender: TObject);
    procedure RefreshCount;
    procedure InvalidatePreview;
    procedure ScopeChange(Sender: TObject);
    function ScopeMember(Index: Integer): Boolean;
    function IsIgnored(Index: Integer): Boolean;
    function InScope(Index: Integer): Boolean;
    function WasOpen(Index: Integer): Boolean;
    procedure GeneratePreview(Sender: TObject);
    procedure ShowPreview(Sender: TObject);
    procedure SettingsClick(Sender: TObject);
    procedure ApplyClick(Sender: TObject);
    function ConfirmApply(Count: Integer): Boolean;
    function ChangedCount: Integer;
    procedure Preflight;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor CreateWorkspace(Owner: TComponent; const Workspace: IStylerWorkspace;
      Language: TStylerLanguage);
    function CreatePreviewForm: TForm;
    procedure PrepareDemoPreview;
    procedure SmokeTest;
    // Test seam for automated runs inside the IDE: applies one scope with the
    // given rules and a fixed answer, without dialogs. Returns the issue report.
    function RunUnattended(const Options: TUsesOptions; Scope: Integer; Confirm: Boolean): string;
    function StatusText: string;
    // Test seam: analyzes the current unit and returns its comparison window.
    function PreviewUnattended(const Options: TUsesOptions): TForm;
    // Test seam: opens the report window with the given text.
    procedure ShowReport(const Issues: string);
  end;

implementation

uses System.SysUtils, Winapi.Windows, Winapi.Messages, Winapi.RichEdit,
  Vcl.Graphics, Vcl.Themes,
  CSCoder.Styler.Engine, CSCoder.Styler.SettingsForm, CSCoder.Styler.ControlHelp, Vcl.Clipbrd;

type
  TPreviewLayout = class(TComponent)
  public
    Codes, LeftPane: TPanel;
    Divider: TSplitter;
    Ratio: Double;
    Updating: Boolean;
    procedure Resize(Sender: TObject);
    procedure Moved(Sender: TObject);
  end;

procedure TPreviewLayout.Resize(Sender: TObject);
var Available: Integer;
begin
  if Updating then Exit;
  Updating := True;
  try
    Available := Codes.ClientWidth - 2 * Codes.BorderWidth - Divider.Width;
    if Available > 0 then
    begin
      Codes.DisableAlign;
      try
        LeftPane.Left := Codes.BorderWidth;
        LeftPane.Width := Integer(Round(Available * Ratio));
        Divider.Left := LeftPane.Left + LeftPane.Width;
      finally Codes.EnableAlign; end;
    end;
  finally Updating := False; end;
end;

procedure TPreviewLayout.Moved(Sender: TObject);
var Available: Integer;
begin
  if Updating then Exit;
  Available := Codes.ClientWidth - 2 * Codes.BorderWidth - Divider.Width;
  if Available > 0 then Ratio := LeftPane.Width / Available;
end;

function SourceLineAt(const Source: string; Offset: NativeInt): Integer;
var I: NativeInt;
begin
  Result := 0; I := 1;
  while (I <= Offset) and (I <= Length(Source)) do
  begin
    if Source[I] = #13 then
    begin
      Inc(Result);
      if (I < Offset) and (I < Length(Source)) and (Source[I + 1] = #10) then Inc(I);
    end
    else if Source[I] = #10 then Inc(Result);
    Inc(I);
  end;
end;

procedure PreviewBackground(Control: TRichEdit; Color: TColor; All: Boolean; Text: TColor = clNone);
var Format: TCharFormat2; Scope: WPARAM;
begin
  Format := Default(TCharFormat2); Format.cbSize := SizeOf(Format);
  Format.dwMask := CFM_BACKCOLOR; Format.crBackColor := DWORD(ColorToRGB(Color));
  if Text <> clNone then
  begin
    Format.dwMask := Format.dwMask or CFM_COLOR; Format.crTextColor := DWORD(ColorToRGB(Text));
  end;
  Scope := SCF_SELECTION;
  if All then Scope := SCF_ALL;
  Control.Perform(EM_SETCHARFORMAT, Scope, PChar(@Format));
end;

procedure HighlightPreview(Control: TRichEdit; const Source: string;
  Start, Count: NativeInt; Color: TColor);
var FirstLine, LastLine, FirstChar, AfterChar: Integer;
begin
  FirstLine := SourceLineAt(Source, Start);
  if Count > 0 then LastLine := SourceLineAt(Source, Start + Count - 1)
  else LastLine := FirstLine;
  // Ask the control for its positions: its line endings can differ from the snapshot.
  FirstChar := Integer(SendMessage(Control.Handle, EM_LINEINDEX, WPARAM(FirstLine), 0));
  AfterChar := Integer(SendMessage(Control.Handle, EM_LINEINDEX, WPARAM(LastLine + 1), 0));
  if FirstChar < 0 then Exit;
  if AfterChar < 0 then AfterChar := Control.GetTextLen;
  Control.SelStart := FirstChar; Control.SelLength := AfterChar - FirstChar;
  PreviewBackground(Control, Color, False);
end;

constructor TExecutionForm.CreateWorkspace(Owner: TComponent;
  const Workspace: IStylerWorkspace; Language: TStylerLanguage);
var Title, Context: TLabel; Line: TBevel;

  function LabelAt(const Text: string; X, Y, W, H: Integer): TLabel;
  begin
    Result := TLabel.Create(Self); Result.Parent := Self;
    Result.AutoSize := False; Result.SetBounds(X, Y, W, H);
    Result.Caption := Text; Result.WordWrap := True;
    Explain(Result, LF(stExecInfoHint, Language, [Text]));
  end;

  function ButtonAt(Id: TStylerText; X, Y, W: Integer; Handler: TNotifyEvent): TButton;
  begin
    Result := TButton.Create(Self); Result.Parent := Self;
    Result.SetBounds(X, Y, W, 28); Result.Caption := L(Id, Language);
    Result.OnClick := Handler;
    Explain(Result, RuleHelp(Id));
    if Id = stCancel then Explain(Result, L(stCancelHint, Language));
  end;

begin
  inherited CreateNew(Owner);
  FWorkspace := Workspace; FLanguage := Language;
  FOptions := FWorkspace.LoadOptions; FNames := FWorkspace.UnitNames;
  FPaths := RelativeUnitPaths(FWorkspace);
  FOpenIndices := FWorkspace.OpenUnitIndices;
  Caption := 'CS.Coder - Unit Styler - ' + L(stExecCaption, Language); Font.Name := 'Segoe UI'; Font.Size := 9;
  Position := poScreenCenter; BorderStyle := bsDialog;
  ClientWidth := 420; ClientHeight := 346; Color := clBtnFace;
  Title := LabelAt(L(stOrganize, Language), 12, 10, 396, 24);
  Title.Font.Size := 12; Title.Font.Style := [fsBold];
  Context := LabelAt(L(stProject, Language) + ': ' + FWorkspace.ProjectName, 12, 38, 396, 18);
  if (FWorkspace.CurrentUnit >= 0) and (FWorkspace.CurrentUnit < Length(FNames)) then
    Context.Caption := Context.Caption + ' | ' + L(stCurrent, Language) + ': ' +
      ExtractFileName(FNames[FWorkspace.CurrentUnit]);
  Context.Hint := Context.Caption; Context.ShowHint := True;
  FScope := TRadioGroup.Create(Self); FScope.Parent := Self;
  // The heading is a label: IDE themes draw group captions in a larger font,
  // which would run over the first option of this compact group.
  Title := LabelAt(L(stWhereApply, Language), 12, 60, 396, 16); Title.Font.Style := [fsBold];
  FScope.SetBounds(12, 74, 396, 68); FScope.Caption := '';
  FScope.Items.Add(L(stCurrentScope, Language)); FScope.Items.Add(L(stOpenScope, Language));
  FScope.Items.Add(L(stAllScope, Language));
  FScope.ItemIndex := 0;
  FScope.Buttons[0].Enabled := FWorkspace.CurrentUnit >= 0;
  if FWorkspace.CurrentUnit < 0 then
  begin
    if Length(FOpenIndices) > 0 then FScope.ItemIndex := 1 else FScope.ItemIndex := 2;
  end;
  FScope.Buttons[1].Enabled := FWorkspace.SupportsBatch and (Length(FOpenIndices) > 0);
  FScope.Buttons[2].Enabled := FWorkspace.SupportsBatch;
  if not FWorkspace.SupportsBatch then
  begin
    FScope.Hint := L(stBatchLater, Language); FScope.ShowHint := True;
  end;
  Explain(FScope, L(stScopeHint, Language));
  Explain(FScope.Buttons[0], RuleHelp(stCurrentScope));
  Explain(FScope.Buttons[1], RuleHelp(stOpenScope));
  Explain(FScope.Buttons[2], RuleHelp(stAllScope));
  if not FWorkspace.SupportsBatch then
    Explain(FScope, FScope.Hint + L(stScopeNoBatchHint, Language));
  FScope.OnClick := ScopeChange;
  FCount := LabelAt('', 12, 146, 396, 18);
  Explain(FCount, L(stCountHint, Language));
  Line := TBevel.Create(Self); Line.Parent := Self; Line.Shape := bsTopLine;
  Line.SetBounds(12, 170, 396, 2);
  Title := LabelAt(L(stRunPattern, Language), 12, 180, 272, 18); Title.Font.Style := [fsBold];
  Explain(Title, L(stRunPatternHint, Language));
  FRuleSummary := LabelAt('', 12, 202, 272, 42);
  FSettingsButton := ButtonAt(stSettings, 292, 194, 116, SettingsClick);
  FStatus := LabelAt('', 12, 246, 396, 18); FStatus.Font.Color := clGrayText;
  Explain(FStatus, L(stStatusHint, FLanguage));
  FCancel := ButtonAt(stCancel, 12, 276, 88, CancelClick); FCancel.ModalResult := mrCancel; FCancel.Cancel := True;
  OnCloseQuery := FormCloseQuery;
  FPreviewButton := ButtonAt(stViewPreview, 224, 276, 88, ShowPreview);
  FApply := ButtonAt(stApply, 320, 276, 88, ApplyClick); FApply.Enabled := True;
  FSaveNote := LabelAt('', 12, 310, 396, 28);
  FViewIndex := -1;
  RefreshCount; RefreshSummary;
  ApplyHostTheme(Self);
  FStatus.Caption := '';
end;

procedure TExecutionForm.RefreshSummary;
var Parts: TArray<string>;
begin
  Parts := nil;
  if FOptions.OneUnitPerLine then Parts := Parts + [L(stSumOnePerLine, FLanguage)];
  if FOptions.WrapUnits then Parts := Parts + [LF(stSumWrap, FLanguage, [FOptions.MaxLineWidth])];
  if FOptions.Alphabetical and FOptions.SortFirstNameOnly then Parts := Parts + [L(stSumFirstName, FLanguage)]
  else if FOptions.Alphabetical then Parts := Parts + [L(stSumFullName, FLanguage)];
  if FOptions.IndentationEnabled then Parts := Parts + [LF(stSumSpaces, FLanguage, [Length(FOptions.Indentation)])];
  if FOptions.GroupingEnabled then Parts := Parts + [L(stSumGroups, FLanguage)];
  if FOptions.PrioritiesEnabled then Parts := Parts + [L(stSumPriorities, FLanguage)];
  if FOptions.BlankBeforeSections then Parts := Parts + [L(stSumBlankBefore, FLanguage)];
  if FOptions.BlankAfterSections then Parts := Parts + [L(stSumBlankAfter, FLanguage)];
  FRuleSummary.Caption := string.Join(' · ', Parts);
  if Length(Parts) = 0 then FRuleSummary.Caption := L(stSumNone, FLanguage);
  if FOptions.AutoSaveUnits then FSaveNote.Caption := L(stSaveNoteAuto, FLanguage)
  else FSaveNote.Caption := L(stSaveNoteOpen, FLanguage);
  Explain(FRuleSummary, LF(stSummaryHint, FLanguage, [FRuleSummary.Caption]));
  Explain(FSaveNote, L(stSaveNoteHint, FLanguage));
end;

procedure TExecutionForm.RefreshCount;
var I, Count, Ignored: Integer;
begin
  Count := 0; Ignored := 0;
  for I := 0 to Integer(High(FNames)) do
    if InScope(I) then Inc(Count)
    else if ScopeMember(I) then Inc(Ignored);
  FCount.Caption := LF(stCountMany, FLanguage, [Count]);
  if Count = 1 then FCount.Caption := L(stCountOne, FLanguage);
  if Ignored = 1 then FCount.Caption := FCount.Caption + L(stIgnoredOne, FLanguage)
  else if Ignored > 1 then FCount.Caption := FCount.Caption + LF(stIgnoredMany, FLanguage, [Ignored]);
end;

procedure TExecutionForm.InvalidatePreview;
begin
  FProposals := nil; FIndices := nil;
  FViewProposal := Default(TStylerProposal); FViewIndex := -1; FHasPreview := False;
  FApply.Enabled := True; FStatus.Caption := '';
  Explain(FStatus, L(stStatusHint, FLanguage));
end;
procedure TExecutionForm.ScopeChange(Sender: TObject);
begin FOpenIndices := FWorkspace.OpenUnitIndices; InvalidatePreview; RefreshCount; end;
function TExecutionForm.IsIgnored(Index: Integer): Boolean;
begin
  Result := IsIgnoredPath(FPaths[Index], FOptions.IgnoredPaths);
end;

function TExecutionForm.InScope(Index: Integer): Boolean;
begin
  // Ignored folders and files are never analyzed or changed, in any scope.
  Result := ScopeMember(Index) and not IsIgnored(Index);
end;

function TExecutionForm.ScopeMember(Index: Integer): Boolean;
var OpenIndex: Integer;
begin
  if FScope.ItemIndex = 0 then Exit(Index = FWorkspace.CurrentUnit);
  if FScope.ItemIndex = 2 then Exit(True);
  Result := False;
  for OpenIndex in FOpenIndices do
    if OpenIndex = Index then Exit(True);
end;

function TExecutionForm.WasOpen(Index: Integer): Boolean;
var OpenIndex: Integer;
begin
  Result := False;
  for OpenIndex in FOpenIndices do
    if OpenIndex = Index then Exit(True);
end;

function TExecutionForm.ChangedCount: Integer;
var P: TStylerProposal;
begin Result := 0; for P in FProposals do if Length(P.Edits) > 0 then Inc(Result); end;

procedure TExecutionForm.SetBusy(Value: Boolean);
begin
  FBusy := Value; FStop := False;
  FScope.Enabled := not Value; FApply.Enabled := not Value;
  FPreviewButton.Enabled := not Value; FSettingsButton.Enabled := not Value;
  // While working, the same button asks the loop to stop instead of closing.
  if Value then
  begin FCancel.Caption := L(stInterrupt, FLanguage); FCancel.ModalResult := mrNone; end
  else
  begin FCancel.Caption := L(stCancel, FLanguage); FCancel.ModalResult := mrCancel; end;
end;

procedure TExecutionForm.CancelClick(Sender: TObject);
begin
  if FBusy then FStop := True;
end;

procedure TExecutionForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not FBusy;
  if FBusy then FStop := True;
end;

procedure TExecutionForm.Step(const Action: string; Done, Total: Integer);
begin
  if (Done mod 10 <> 0) and (Done <> Total) then Exit;
  FStatus.Caption := LF(stProgress, FLanguage, [Action, Done, Total]);
  // Keeps the window painted and the stop button responsive in a long batch.
  if FBusy then Application.ProcessMessages;
end;

procedure TExecutionForm.GeneratePreview(Sender: TObject);
var I, N, Total: Integer;
begin
  FProposals := nil; FIndices := nil; FUnitErrors := nil;
  try
    for I := 0 to Integer(High(FNames)) do
      if InScope(I) then FIndices := FIndices + [I];
    Total := Integer(Length(FIndices));
    SetLength(FProposals, Total); SetLength(FUnitErrors, Total);
    for N := 0 to Total - 1 do
    begin
      if FStop then
        raise EInvalidOperation.Create(L(stAnalysisStopped, FLanguage));
      FProposals[N] := Default(TStylerProposal);
      try
        FProposals[N] := AnalyzeUses(FWorkspace.ReadSource(FIndices[N]), FOptions);
      except
        // Invalid rules concern every unit and stop the run. A unit that cannot
        // be read is reported and skipped, so one bad file does not block a batch.
        on E: EArgumentException do raise;
        on E: Exception do FUnitErrors[N] := E.Message;
      end;
      Step(L(stAnalyzing, FLanguage), N + 1, Total);
    end;
    if Length(FIndices) = 0 then FStatus.Caption := L(stNoUnitInScope, FLanguage)
    else if ChangedCount = 0 then FStatus.Caption := L(stNoChanges, FLanguage)
    else FStatus.Caption := Format(L(stChanges, FLanguage), [ChangedCount]);
    if not FBusy then FApply.Enabled := True;
  except
    InvalidatePreview;
    raise;
  end;
end;

procedure TExecutionForm.AnalyzeCurrentUnit;
var Selected: Integer;
begin
  Selected := FWorkspace.CurrentUnit;
  if (Selected < 0) or (Selected >= Length(FNames)) then
  begin InvalidatePreview; FStatus.Caption := L(stNoCurrentUnit, FLanguage); Exit; end;
  if IsIgnored(Selected) then
  begin InvalidatePreview; FStatus.Caption := L(stCurrentIgnored, FLanguage); Exit; end;
  // Exactly one source is read here, independently of the execution scope.
  FViewProposal := AnalyzeUses(FWorkspace.ReadSource(Selected), FOptions);
  FViewIndex := Selected; FHasPreview := True;
  FStatus.Caption := LF(stPreviewOf, FLanguage, [ExtractFileName(FNames[FViewIndex])]);
end;

procedure TExecutionForm.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if AComponent = FPreviewBefore then FPreviewBefore := nil;
    if AComponent = FPreviewAfter then FPreviewAfter := nil;
    if AComponent = FPreviewDiagnostics then FPreviewDiagnostics := nil;
  end;
end;

procedure TExecutionForm.RefreshPreview;
var D: TStylerDiagnostic; Edit: TSourceEdit; AfterSource: string; Delta: NativeInt;
  Back, Text, Removed, Added: TColor;
begin
  if (FPreviewBefore = nil) or (FPreviewAfter = nil) or
    not FHasPreview then Exit;
  AfterSource := FViewProposal.ApplyTo(FViewProposal.SourceSnapshot);
  FPreviewBefore.Text := FViewProposal.SourceSnapshot; FPreviewAfter.Text := AfterSource;
  SourceColors(Back, Text, Removed, Added);
  FPreviewBefore.Color := Back; FPreviewBefore.Font.Color := Text;
  FPreviewAfter.Color := Back; FPreviewAfter.Font.Color := Text;
  PreviewBackground(FPreviewBefore, Back, True, Text); PreviewBackground(FPreviewAfter, Back, True, Text);
  Delta := 0;
  for Edit in FViewProposal.Edits do
  begin
    HighlightPreview(FPreviewBefore, FViewProposal.SourceSnapshot,
      Edit.Range.Start, Edit.Range.Length, Removed);
    HighlightPreview(FPreviewAfter, AfterSource, Edit.Range.Start + Delta,
      Length(Edit.ReplacementText), Added);
    Inc(Delta, Length(Edit.ReplacementText) - Edit.Range.Length);
  end;
  FPreviewBefore.SelStart := 0; FPreviewBefore.SelLength := 0;
  FPreviewAfter.SelStart := 0; FPreviewAfter.SelLength := 0;
  SendMessage(FPreviewBefore.Handle, EM_SCROLLCARET, 0, 0);
  SendMessage(FPreviewAfter.Handle, EM_SCROLLCARET, 0, 0);
  if FPreviewDiagnostics <> nil then
  begin
    FPreviewDiagnostics.Clear;
    for D in FViewProposal.Diagnostics do
      // The line as the editor numbers it, not the character position.
      FPreviewDiagnostics.Lines.Add(LF(stDiagLine, FLanguage, [SourceLineAt(FViewProposal.SourceSnapshot, D.Range.Start) + 1,
        DiagnosticText(Ord(D.Code), FLanguage)]));
    FPreviewDiagnostics.Visible := FPreviewDiagnostics.Lines.Count > 0;
  end;
end;

function TExecutionForm.CreatePreviewForm: TForm;
var Codes, Pane, Footer: TPanel; Splitter: TSplitter;
  LabelControl: TLabel; B: TButton; Layout: TPreviewLayout;

  function CodePane(Parent: TWinControl; Id: TStylerText): TRichEdit;
  begin
    LabelControl := TLabel.Create(Parent.Owner); LabelControl.Parent := Parent;
    LabelControl.Align := alTop; LabelControl.Height := 22;
    LabelControl.Caption := L(Id, FLanguage); LabelControl.Font.Style := [fsBold];
    Result := TRichEdit.Create(Parent.Owner); Result.Parent := Parent; Result.Align := alClient;
    Result.PlainText := True; Result.ReadOnly := True;
    Result.WordWrap := False; Result.ScrollBars := ssBoth;
    SourceFont(Result.Font);
    // Text and background are set from the theme in RefreshPreview, with the highlights.
    Result.StyleElements := [seBorder];
    Result.FreeNotification(Self);
    if Id = stBefore then Explain(Result, L(stBeforeHint, FLanguage))
    else Explain(Result, L(stAfterHint, FLanguage));
    Explain(LabelControl, Result.Hint);
  end;

begin
  if not FHasPreview then
    raise EInvalidOperation.Create(L(stPreview, FLanguage));
  Result := TStylerDialog.CreateNew(Self);
  try
    Result.Caption := ExtractFileName(FNames[FViewIndex]) + ' | ' + L(stBeforeAfter, FLanguage);
    Result.Font.Assign(Font); Result.Position := poOwnerFormCenter;
    Result.ClientWidth := 1120; Result.ClientHeight := 700;
    Result.Constraints.MinWidth := 1000; Result.Constraints.MinHeight := 560;
    Footer := TPanel.Create(Result); Footer.Parent := Result; Footer.Align := alBottom;
    Footer.Height := 48; Footer.BevelOuter := bvNone;
    B := TButton.Create(Result); B.Parent := Footer;
    B.SetBounds(976, 8, 132, 32); B.Anchors := [akTop, akRight];
    B.Caption := L(stClose, FLanguage); B.ModalResult := mrCancel;
    B.Cancel := True; B.Default := True;
    Explain(B, RuleHelp(stClose));
    FPreviewDiagnostics := TMemo.Create(Result); FPreviewDiagnostics.Parent := Result;
    FPreviewDiagnostics.Align := alBottom; FPreviewDiagnostics.Height := 72;
    FPreviewDiagnostics.ReadOnly := True; FPreviewDiagnostics.ScrollBars := ssVertical;
    FPreviewDiagnostics.FreeNotification(Self);
    Explain(FPreviewDiagnostics, L(stDiagnosticsHint, FLanguage));
    Codes := TPanel.Create(Result); Codes.Parent := Result; Codes.Align := alClient;
    Codes.BevelOuter := bvNone; Codes.BorderWidth := 8;
    Pane := TPanel.Create(Result); Pane.Parent := Codes; Pane.Align := alLeft;
    Pane.Width := 548; Pane.BevelOuter := bvNone;
    Layout := TPreviewLayout.Create(Result); Layout.Codes := Codes;
    Layout.LeftPane := Pane; Layout.Ratio := 0.5;
    FPreviewBefore := CodePane(Pane, stBefore);
    Splitter := TSplitter.Create(Result); Splitter.Parent := Codes; Splitter.Align := alLeft;
    Splitter.Width := 6; Splitter.Color := clBtnShadow; Splitter.ParentColor := False;
    Splitter.ResizeStyle := rsUpdate; Splitter.MinSize := 200;
    Explain(Splitter, L(stSplitterHint, FLanguage));
    Layout.Divider := Splitter; Splitter.OnMoved := Layout.Moved;
    Codes.OnResize := Layout.Resize;
    Pane := TPanel.Create(Result); Pane.Parent := Codes; Pane.Align := alClient;
    Pane.BevelOuter := bvNone; FPreviewAfter := CodePane(Pane, stAfter);
    ApplyHostTheme(Result);
    Layout.Resize(nil); RefreshPreview;
  except Result.Free; raise; end;
end;

procedure TExecutionForm.ShowPreview(Sender: TObject);
var Preview: TForm; Timer: TTimer;
begin
  try AnalyzeCurrentUnit;
  except
    on E: Exception do
    begin
      InvalidatePreview;
      FLastError := E.Message;
      if not FUnattended then
        Application.MessageBox(PChar(L(stPreviewError, FLanguage) + sLineBreak + sLineBreak + E.Message),
          PChar(Caption), MB_ICONERROR);
      Exit;
    end;
  end;
  if not FHasPreview then Exit;
  Preview := CreatePreviewForm;
  try
    if FWorkspace.IsDemo and (FSmokeDecision <> 0) then
    begin
      Timer := TTimer.Create(Preview); Timer.Interval := 50;
      Timer.OnTimer := SmokeConfirmation; Timer.Enabled := True;
    end;
    Preview.ShowModal;
  finally Preview.Free; end;
end;

procedure TExecutionForm.SettingsClick(Sender: TObject);
var Options: TUsesOptions;
begin
  Options := FOptions;
  if not EditSettings(Self, FLanguage, Options, FPaths, FWorkspace.SettingsDirectory, True,
    FWorkspace.ProjectDirectory) then Exit;
  try
    FWorkspace.SaveOptions(Options); FOptions := Options; RefreshSummary; InvalidatePreview;
    RefreshCount;
  except
    on E: Exception do
      Application.MessageBox(PChar(L(stSaveSettingsError, FLanguage) + sLineBreak + sLineBreak + E.Message),
        PChar(Caption), MB_ICONERROR);
  end;
end;

function TExecutionForm.ConfirmApply(Count: Integer): Boolean;
var Question: string;
begin
  if (FWorkspace.IsDemo or FUnattended) and (FSmokeDecision <> 0) then Exit(FSmokeDecision = mrOk);
  Question := LF(stConfirmCount, FLanguage, [Count]);
  if FOptions.AutoSaveUnits then Question := Question + sLineBreak + L(stConfirmAuto, FLanguage)
  else Question := Question + sLineBreak + L(stConfirmOpen, FLanguage);
  Result := Application.MessageBox(PChar(Question), 'Unit Styler',
    MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2) = IDYES;
end;

procedure TExecutionForm.SmokeConfirmation(Sender: TObject);
begin
  TTimer(Sender).Enabled := False;
  TForm(TTimer(Sender).Owner).ModalResult := FSmokeDecision;
end;

procedure TExecutionForm.Preflight;
var I: Integer;
begin
  for I := 0 to Integer(High(FIndices)) do
    if (FUnitErrors[I] = '') and
      (FWorkspace.ReadSource(FIndices[I]) <> FProposals[I].SourceSnapshot) then
      raise EInvalidOperation.Create(L(stStale, FLanguage));
end;

procedure TExecutionForm.CopyExecutionIssues(Sender: TObject);
begin
  Clipboard.AsText := FLastExecutionIssues;
end;

procedure TExecutionForm.ShowExecutionIssues(const Issues: string);
var Dialog: TForm; Details: TMemo; Footer: TPanel; Button: TButton;
begin
  FLastExecutionIssues := Issues;
  if Trim(Issues) = '' then Exit;
  if (FWorkspace.IsDemo or FUnattended) and (FSmokeDecision <> 0) then Exit;
  Dialog := TStylerDialog.CreateNew(Self);
  try
    Dialog.Caption := 'Unit Styler - ' + L(stReportCaption, FLanguage);
    Dialog.Position := poOwnerFormCenter;
    Dialog.ClientWidth := 640; Dialog.ClientHeight := 360;
    Dialog.Constraints.MinWidth := 440; Dialog.Constraints.MinHeight := 260;
    Dialog.Font.Assign(Font);
    Footer := TPanel.Create(Dialog); Footer.Parent := Dialog;
    Footer.Align := alBottom; Footer.Height := 44; Footer.BevelOuter := bvNone;
    Details := TMemo.Create(Dialog); Details.Parent := Dialog;
    Details.Align := alClient; Details.ReadOnly := True;
    Details.ScrollBars := ssBoth; Details.WordWrap := False;
    Details.Text := Issues;
    Explain(Details, L(stReportHint, FLanguage));
    Button := TButton.Create(Dialog); Button.Parent := Footer;
    Button.SetBounds(8, 8, 88, 28); Button.Caption := L(stCopy, FLanguage);
    Button.OnClick := CopyExecutionIssues;
    Explain(Button, L(stCopyHint, FLanguage));
    Button := TButton.Create(Dialog); Button.Parent := Footer;
    Button.SetBounds(544, 8, 88, 28); Button.Anchors := [akRight, akBottom];
    Button.Caption := L(stClose, FLanguage); Button.ModalResult := mrClose; Button.Cancel := True;
    Explain(Button, L(stReportCloseHint, FLanguage));
    ApplyHostTheme(Dialog);
    Dialog.ShowModal;
  finally Dialog.Free; end;
end;

procedure TExecutionForm.ApplyClick(Sender: TObject);
var Issues: TStringList; Report: Boolean;

  function SourceLine(const Source: string; Offset: NativeInt): Integer;
  var Position: NativeInt;
  begin
    Result := 1; Position := 1;
    while (Position <= Length(Source)) and (Position <= Offset) do
    begin
      if Source[Position] = #13 then
      begin
        Inc(Result);
        if (Position < Length(Source)) and (Source[Position + 1] = #10) then Inc(Position);
      end
      else if Source[Position] = #10 then Inc(Result);
      Inc(Position);
    end;
  end;

  procedure Run;
  var I, Index, Applied, Failed, Total: Integer; D: TStylerDiagnostic; Current, Backup: string;
  begin
    Applied := 0; Failed := 0;
    try
      if (FScope.ItemIndex <> 0) and not FWorkspace.SupportsBatch then
        raise EInvalidOperation.Create(L(stBatchUnavailable, FLanguage));
      if FHasPreview and (FWorkspace.ReadSource(FViewIndex) <> FViewProposal.SourceSnapshot) then
        raise EInvalidOperation.Create(L(stStale, FLanguage));
      // Analyze only after Apply. Do not report warnings when the user cancels.
      FOpenIndices := FWorkspace.OpenUnitIndices;
      GeneratePreview(nil);
      for I := 0 to Integer(High(FIndices)) do
      begin
        if FUnitErrors[I] <> '' then
          Issues.Add(LF(stIssueUnitError, FLanguage, [FPaths[FIndices[I]], FUnitErrors[I]]));
        for D in FProposals[I].Diagnostics do
          Issues.Add(LF(stIssueWarning, FLanguage, [FPaths[FIndices[I]],
            DiagnosticText(Ord(D.Code), FLanguage), SourceLine(FProposals[I].SourceSnapshot, D.Range.Start)]));
      end;
      Report := True;
      if ChangedCount = 0 then Exit;
      Preflight;
      Report := False;
      if not ConfirmApply(ChangedCount) then Exit;
      Report := True;
      Preflight;
      FWorkspace.StartBackup(FOptions.BackupUnits);
      Total := ChangedCount;
      for I := 0 to Integer(High(FIndices)) do
      begin
        if Length(FProposals[I].Edits) = 0 then Continue;
        if FStop then
        begin
          Issues.Add(LF(stIssueStopped, FLanguage, [Applied, Total]));
          Break;
        end;
        Index := FIndices[I];
        FExecutionUnit := FPaths[Index];
        try
          // Closed unit that must stay unsaved: bring it into the editor first.
          // The editor is then the source, so the proposal follows its content.
          if not WasOpen(Index) and not FOptions.AutoSaveUnits then
          begin
            FWorkspace.OpenUnit(Index);
            Current := FWorkspace.ReadSource(Index);
            if Current <> FProposals[I].SourceSnapshot then
              FProposals[I] := AnalyzeUses(Current, FOptions);
          end;
          if Length(FProposals[I].Edits) > 0 then
          begin
            FWorkspace.Apply(Index, FProposals[I], FOptions.AutoSaveUnits and not WasOpen(Index));
            Inc(Applied);
          end;
        except
          // One unit failing does not stop the others.
          on E: Exception do
          begin
            Inc(Failed);
            Issues.Add(LF(stIssueApplyError, FLanguage, [FExecutionUnit, E.Message]));
          end;
        end;
        FExecutionUnit := '';
        Step(L(stApplying, FLanguage), Applied + Failed, Total);
      end;
      InvalidatePreview;
      Backup := FWorkspace.BackupDirectory;
      if Backup <> '' then
        Explain(FStatus, LF(stBackupHint, FLanguage, [Backup]));
      if FWorkspace.IsDemo then FStatus.Caption := L(stDoneDemo, FLanguage)
      else if Failed > 0 then FStatus.Caption := LF(stDoneFailed, FLanguage, [Applied, Failed])
      else if Backup <> '' then FStatus.Caption := LF(stDoneBackup, FLanguage, [Applied,
        ExtractRelativePath(IncludeTrailingPathDelimiter(FWorkspace.ProjectDirectory), Backup)])
      else if FOptions.AutoSaveUnits then FStatus.Caption := LF(stDoneAuto, FLanguage, [Applied])
      else FStatus.Caption := LF(stDoneOpen, FLanguage, [Applied]);
    except
      on E: Exception do
      begin
        Report := True;
        InvalidatePreview;
        FStatus.Caption := L(stRunAborted, FLanguage);
        if FExecutionUnit <> '' then Issues.Add(LF(stIssueError, FLanguage, [FExecutionUnit, E.Message]))
        else Issues.Add(LF(stIssueRunError, FLanguage, [E.Message]));
        if Applied > 0 then
          Issues.Add(LF(stIssueAppliedBefore, FLanguage, [Applied]));
      end;
    end;
  end;

begin
  if FBusy or not FApply.Enabled then Exit;
  FLastExecutionIssues := ''; FExecutionUnit := ''; Report := False;
  Issues := TStringList.Create;
  try
    SetBusy(True);
    try Run; finally SetBusy(False); end;
    if Report then ShowExecutionIssues(Issues.Text);
  finally Issues.Free; end;
end;

function TExecutionForm.RunUnattended(const Options: TUsesOptions; Scope: Integer; Confirm: Boolean): string;
begin
  FOptions := Options; FUnattended := True;
  if Confirm then FSmokeDecision := mrOk else FSmokeDecision := mrCancel;
  FScope.ItemIndex := Scope; ScopeChange(nil);
  ApplyClick(nil);
  Result := FLastExecutionIssues;
end;

function TExecutionForm.PreviewUnattended(const Options: TUsesOptions): TForm;
begin
  FOptions := Options;
  AnalyzeCurrentUnit;
  Result := CreatePreviewForm;
end;

procedure TExecutionForm.ShowReport(const Issues: string);
var Unattended: Boolean;
begin
  Unattended := FUnattended; FUnattended := False;
  try ShowExecutionIssues(Issues); finally FUnattended := Unattended; end;
end;

function TExecutionForm.StatusText: string;
begin Result := FStatus.Caption; end;

procedure TExecutionForm.PrepareDemoPreview;
begin
  if not FWorkspace.IsDemo then Exit;
  FScope.ItemIndex := 1;
  RefreshCount; AnalyzeCurrentUnit;
end;

procedure TExecutionForm.SmokeTest;
var Original, Other, Closed: string; Preview: TForm; I: Integer; Layout: TPreviewLayout;
  Direct: TExecutionForm; DirectWorkspace: IStylerWorkspace; Memory: TMemoryWorkspace; Mode: Integer;
  Injected: TStylerProposal; Sample: string;
begin
  if not FWorkspace.IsDemo then raise Exception.Create('Smoke tests require samples');
  for Mode := 0 to 3 do
  begin
    Memory := TMemoryWorkspace.Create; DirectWorkspace := Memory;
    Injected := Default(TStylerProposal);
    Injected.SourceSnapshot := DirectWorkspace.ReadSource(0);
    if Mode in [1, 2] then
      Sample := 'unit Sample; interface uses B, {for B} A; implementation uses Z, C; end.'
    else Sample := 'unit Sample; interface uses B, A; implementation end.';
    SetLength(Injected.Edits, 1);
    Injected.Edits[0].Range := TSourceRange.Create(0, Length(Injected.SourceSnapshot));
    Injected.Edits[0].ExpectedText := Injected.SourceSnapshot;
    Injected.Edits[0].ReplacementText := Sample;
    Memory.Apply(0, Injected, False);
    Direct := TExecutionForm.CreateWorkspace(nil, DirectWorkspace, FLanguage);
    try
      Direct.FOptions := Default(TUsesOptions); Direct.FOptions.Alphabetical := True;
      Direct.FSmokeDecision := mrOk;
      if Mode = 2 then Direct.FSmokeDecision := mrCancel;
      if Mode = 3 then
      begin
        Direct.FHasPreview := True; Direct.FViewIndex := 0;
        Direct.FViewProposal.SourceSnapshot := 'stale';
      end;
      Direct.ApplyClick(nil);
      case Mode of
        0: if Direct.FLastExecutionIssues <> '' then raise Exception.Create('Clean execution produced log');
        1: if (Pos('Aviso', Direct.FLastExecutionIssues) = 0) or (Pos('linha', Direct.FLastExecutionIssues) = 0) then
          raise Exception.Create('Preserved clause warning missing');
        2: if (Direct.FLastExecutionIssues <> '') or (DirectWorkspace.ReadSource(0) <> Sample) then
          raise Exception.Create('Cancelled application produced log or changes');
        3: if (Pos('Erro', Direct.FLastExecutionIssues) = 0) or (DirectWorkspace.ReadSource(0) <> Sample) then
          raise Exception.Create('Stale snapshot error missing or changed source');
      end;
    finally Direct.Free; DirectWorkspace := nil; end;
  end;

  Original := FWorkspace.ReadSource(0); Other := FWorkspace.ReadSource(1);
  Closed := FWorkspace.ReadSource(2);
  for Mode := 0 to 1 do
  begin
    Memory := TMemoryWorkspace.Create(-1, Mode = 0); DirectWorkspace := Memory;
    Direct := TExecutionForm.CreateWorkspace(nil, DirectWorkspace, FLanguage);
    try
      if Direct.FScope.Buttons[0].Enabled or (Direct.FScope.ItemIndex <> Mode + 1) then
        raise Exception.Create('Non-unit scope fallback');
    finally Direct.Free; DirectWorkspace := nil; end;
  end;
  Memory := TMemoryWorkspace.Create; DirectWorkspace := Memory;
  Direct := TExecutionForm.CreateWorkspace(nil, DirectWorkspace, FLanguage);
  try
    Direct.FSmokeDecision := mrOk; Direct.ApplyClick(nil);
    if (DirectWorkspace.ReadSource(0) = Original) or (DirectWorkspace.ReadSource(1) <> Other) then
      raise Exception.Create('Direct apply without preview/current scope');
    if Memory.WasSaved(0) then raise Exception.Create('Open unit was auto saved');
  finally Direct.Free; DirectWorkspace := nil; end;
  Memory := TMemoryWorkspace.Create; DirectWorkspace := Memory;
  Direct := TExecutionForm.CreateWorkspace(nil, DirectWorkspace, FLanguage);
  try
    Direct.FOptions.AutoSaveUnits := False; Direct.FSmokeDecision := mrOk; Direct.ApplyClick(nil);
    if (DirectWorkspace.ReadSource(0) = Original) or Memory.WasSaved(0) then
      raise Exception.Create('Disabled auto save policy not used');
  finally Direct.Free; DirectWorkspace := nil; end;
  for Mode := 0 to 1 do
  begin
    Memory := TMemoryWorkspace.Create; DirectWorkspace := Memory;
    Direct := TExecutionForm.CreateWorkspace(nil, DirectWorkspace, FLanguage);
    try
      Direct.FScope.ItemIndex := 2; Direct.ScopeChange(nil);
      Direct.FOptions.AutoSaveUnits := Mode = 1;
      Direct.FOptions.PrioritiesEnabled := False; Direct.FOptions.GroupingEnabled := False;
      Direct.FSmokeDecision := mrOk; Direct.ApplyClick(nil);
      if Memory.WasSaved(0) or Memory.WasSaved(1) then raise Exception.Create('Open units auto saved in batch');
      if DirectWorkspace.ReadSource(2) = Closed then raise Exception.Create('Closed sample not altered');
      if Memory.WasSaved(2) <> (Mode = 1) then raise Exception.Create('Closed unit save policy');
    finally Direct.Free; DirectWorkspace := nil; end;
  end;
  // Ignored folder: its units are counted apart and never analyzed or changed.
  Memory := TMemoryWorkspace.Create; DirectWorkspace := Memory;
  Direct := TExecutionForm.CreateWorkspace(nil, DirectWorkspace, FLanguage);
  try
    Direct.FOptions.IgnoredPaths := ['vendas/'];
    Direct.FScope.ItemIndex := 2; Direct.ScopeChange(nil);
    if Direct.FCount.Caption <> '1 unit será processada · 2 ignoradas' then
      raise Exception.Create('Ignored count: ' + Direct.FCount.Caption);
    Direct.FSmokeDecision := mrOk; Direct.ApplyClick(nil);
    if (DirectWorkspace.ReadSource(0) = Original) or (DirectWorkspace.ReadSource(1) <> Other) or
      (DirectWorkspace.ReadSource(2) <> Closed) then raise Exception.Create('Ignored folder was changed');
    Direct.FOptions.IgnoredPaths := ['uClientes.pas'];
    Direct.FScope.ItemIndex := 0; Direct.ScopeChange(nil);
    Direct.AnalyzeCurrentUnit;
    if Direct.FHasPreview or (Direct.FCount.Caption <> '0 units serão processadas · 1 ignorada') then
      raise Exception.Create('Ignored current unit: ' + Direct.FCount.Caption);
  finally Direct.Free; DirectWorkspace := nil; end;
  if not FApply.Enabled then raise Exception.Create('Apply disabled without preview');
  FSmokeDecision := mrCancel; ApplyClick(nil); FSmokeDecision := 0;
  if FHasPreview or (FWorkspace.ReadSource(0) <> Original) then raise Exception.Create('Direct apply cancellation');
  ScopeChange(nil);
  FScope.ItemIndex := 2; ScopeChange(nil);
  AnalyzeCurrentUnit;
  if (FViewIndex <> 0) or (Pos('unit uClientes;', FViewProposal.SourceSnapshot) <> 1) or
    (Length(FProposals) <> 0) then raise Exception.Create('Preview analyzed wrong unit or batch');
  Preview := CreatePreviewForm;
  try
    for I := 0 to Preview.ComponentCount - 1 do
      if Preview.Components[I] is TTabControl then raise Exception.Create('Preview contains unit tabs');
    Layout := nil;
    for I := 0 to Preview.ComponentCount - 1 do
      if Preview.Components[I] is TPreviewLayout then Layout := TPreviewLayout(Preview.Components[I]);
    if Layout = nil then raise Exception.Create('Missing preview splitter layout');
    Preview.ClientWidth := 1400; Layout.Resize(nil);
    if Abs(Layout.LeftPane.Width * 2 - (Layout.Codes.ClientWidth - 16 - Layout.Divider.Width)) > 1 then
      raise Exception.Create('Preview divider not centered after resize');
    Preview.ClientWidth := 1000; Layout.Resize(nil);
    if Abs(Layout.LeftPane.Width * 2 - (Layout.Codes.ClientWidth - 16 - Layout.Divider.Width)) > 1 then
      raise Exception.Create('Preview divider not centered after restore');
    Preview.Show; Preview.WindowState := wsMaximized; Application.ProcessMessages;
    Layout.Resize(nil);
    if Abs(Layout.LeftPane.Width * 2 - (Layout.Codes.ClientWidth - 16 - Layout.Divider.Width)) > 1 then
      raise Exception.Create('Preview divider not centered after maximize');
    if Layout.Divider.Left <> Layout.LeftPane.Left + Layout.LeftPane.Width then
      raise Exception.Create('Preview divider aligned on wrong side');
    Preview.WindowState := wsNormal; Preview.Hide;
    if Pos('unit uClientes;', FPreviewBefore.Text) <> 1 then raise Exception.Create('Wrong displayed unit');
  finally Preview.Free; end;
  if (FPreviewBefore <> nil) or (FPreviewAfter <> nil) or (FPreviewDiagnostics <> nil) then
    raise Exception.Create('Preview controls retained after close');
  ScopeChange(nil);
  if FHasPreview or not FApply.Enabled then raise Exception.Create('Scope change/Apply availability');
  GeneratePreview(nil);
  if Length(FIndices) <> 3 then raise Exception.Create('All project scope lost closed unit');
  InvalidatePreview; PrepareDemoPreview;
  if FCount.Caption <> '2 units serão processadas' then
    raise Exception.Create('Open units count');
  FSmokeDecision := mrCancel; ShowPreview(nil); FSmokeDecision := 0;
  if (FWorkspace.ReadSource(0) <> Original) or (FWorkspace.ReadSource(1) <> Other) or
    (Length(FProposals) <> 0) then raise Exception.Create('Preview mutated sources or analyzed batch');
  FOptions.AutoSaveUnits := False;
  FOptions.BlankBeforeSections := True; FOptions.BlankAfterSections := True;
  InvalidatePreview; PrepareDemoPreview;
  if Pos('uses' + sLineBreak + sLineBreak,
    FViewProposal.ApplyTo(FViewProposal.SourceSnapshot)) = 0 then raise Exception.Create('Section spacing missing');
  FSmokeDecision := mrCancel; ApplyClick(nil);
  if (Length(FIndices) <> 2) or (ChangedCount <> 2) then raise Exception.Create('Apply lost open units scope');
  if (FWorkspace.ReadSource(0) <> Original) or (FWorkspace.ReadSource(1) <> Other) then
    raise Exception.Create('Cancellation mutated sources');
  FSmokeDecision := mrOk; ApplyClick(nil); FSmokeDecision := 0;
  if (FWorkspace.ReadSource(0) = Original) or (FWorkspace.ReadSource(1) = Other) then
    raise Exception.Create('Confirmed scope not applied');
  if FWorkspace.ReadSource(2) <> Closed then raise Exception.Create('Open scope applied closed unit');
  if FHasPreview or not FApply.Enabled then raise Exception.Create('Apply availability after apply');
end;

end.
