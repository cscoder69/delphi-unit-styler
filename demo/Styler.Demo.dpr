program StylerDemo;


{$R Styler.Demo.res}

uses
  System.SysUtils, System.IOUtils, System.Classes, System.Types, Winapi.Windows, Winapi.Messages, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Grids, Vcl.ExtCtrls, Vcl.Graphics, Vcl.Imaging.pngimage,
  CSCoder.Styler.Types, CSCoder.Styler.Strings, CSCoder.Styler.Workspace,
  CSCoder.Styler.ExecutionForm, CSCoder.Styler.SettingsForm, CSCoder.Styler.About;

type
  TSettingsSmoke = class
  private
    FAccept: Boolean;
    procedure Answer(Sender: TObject);
  public
    procedure Run(Owner: TForm; const Options: TUsesOptions);
  end;

  // Opens the license text from the About window, checks it and closes it.
  TAboutSmoke = class
  private
    FText: string;
    procedure Answer(Sender: TObject);
  public
    procedure Run(Owner: TForm; Language: TStylerLanguage);
  end;

type THintControl = class(TControl);

procedure CheckControlHints(Parent: TWinControl);
var I: Integer; Control: TControl;
begin
  for I := 0 to Parent.ControlCount - 1 do
  begin
    Control := Parent.Controls[I];
    if not Control.Visible then Continue;
    if (Control is TButtonControl) or (Control is TCustomEdit) or
      (Control is TComboBox) or (Control is TStringGrid) then
      if (Trim(Control.Hint) = '') or not THintControl(Control).ShowHint then
        raise Exception.Create('Missing control hint: ' + Control.ClassName + ' ' + Control.Name);
    if Control is TWinControl then CheckControlHints(TWinControl(Control));
  end;
end;

procedure TSettingsSmoke.Answer(Sender: TObject);
var I: Integer; Dialog: TForm;
begin
  TTimer(Sender).Enabled := False;
  Dialog := Screen.ActiveForm;
  if Dialog = nil then raise Exception.Create('Missing settings editor');
  CheckControlHints(Dialog);
  for I := 0 to Dialog.ComponentCount - 1 do
    if Dialog.Components[I] is TMemo then
      TMemo(Dialog.Components[I]).Text := 'Smoke.Unit'
    else if Dialog.Components[I] is TStringGrid then
      TStringGrid(Dialog.Components[I]).Cells[0, 1] := 'SmokeGroup';
  if FAccept then Dialog.ModalResult := mrOk else Dialog.ModalResult := mrCancel;
end;

procedure TSettingsSmoke.Run(Owner: TForm; const Options: TUsesOptions);
var Form: TSettingsForm; Timer: TTimer; I, J, Attempt: Integer;
  Buttons: TArray<TButton>; Lists: TArray<TMemo>; Grid: TStringGrid; Before: string;
  Found: Boolean;
begin
  Found := False;
  Form := TSettingsForm.CreateSettings(Owner, slPortuguese, Options,
    ['uClientes.pas', 'Vendas\uPedidos.pas', 'Vendas\Relatorios\uRelatorios.pas']);
  Timer := TTimer.Create(Form);
  try
    CheckControlHints(Form);
    Buttons := nil; Lists := nil; Grid := nil;
    for I := 0 to Form.ComponentCount - 1 do
      if Form.Components[I] is TButton then
      begin
        // Same order as their hidden lists: priorities, protected, preserved.
        if (TButton(Form.Components[I]).Name = 'btnEditPriority') or
          (TButton(Form.Components[I]).Name = 'btnProtectedUnits') or
          (TButton(Form.Components[I]).Name = 'btnPreservedUnits') then
          Buttons := Buttons + [TButton(Form.Components[I])];
      end
      else if Form.Components[I] is TMemo then Lists := Lists + [TMemo(Form.Components[I])]
      else if Form.Components[I] is TStringGrid then Grid := TStringGrid(Form.Components[I]);
    if (Length(Buttons) <> 3) or (Length(Lists) <> 3) or (Grid = nil) then
      raise Exception.Create('Settings editors missing');
    Timer.Enabled := False; Timer.Interval := 50; Timer.OnTimer := Answer;
    for I := 0 to 2 do
      for Attempt := 0 to 1 do
      begin
        Before := Lists[I].Text; FAccept := Attempt = 1;
        Timer.Enabled := True; Buttons[I].Click;
        if FAccept then
        begin
          if Trim(Lists[I].Text) <> 'Smoke.Unit' then raise Exception.Create('List edit lost');
        end
        else if Lists[I].Text <> Before then raise Exception.Create('List cancel changed data');
      end;
    // The ignored paths editor opens, explains its controls and closes both ways.
    for J := 0 to Form.ComponentCount - 1 do
      if (Form.Components[J] is TButton) and
        (TButton(Form.Components[J]).Name = 'btnIgnoredPaths') then
      begin
        Found := True;
        for Attempt := 0 to 1 do
        begin
          FAccept := Attempt = 1; Timer.Enabled := True; TButton(Form.Components[J]).Click;
        end;
      end;
    if not Found then raise Exception.Create('Ignored paths editor missing');
    for J := 0 to Form.ComponentCount - 1 do
      if (Form.Components[J] is TButton) and
        (TButton(Form.Components[J]).Name = 'btnEditGroups') then
        for Attempt := 0 to 1 do
        begin
          Before := Grid.Cells[0, 1]; FAccept := Attempt = 1;
          Timer.Enabled := True; TButton(Form.Components[J]).Click;
          if FAccept then
          begin
            if Grid.Cells[0, 1] <> 'SmokeGroup' then raise Exception.Create('Group edit lost');
          end
          else if Grid.Cells[0, 1] <> Before then raise Exception.Create('Group cancel changed data');
        end;
  finally Form.Free; end;
end;

procedure TAboutSmoke.Answer(Sender: TObject);
var I: Integer; Dialog: TForm; Bitmap: TBitmap; Png: TPngImage; WindowDC: HDC;
begin
  TTimer(Sender).Enabled := False;
  Dialog := Screen.ActiveForm;
  if Dialog = nil then raise Exception.Create('Missing license window');
  try
    CheckControlHints(Dialog);
    for I := 0 to Dialog.ComponentCount - 1 do
      if Dialog.Components[I] is TMemo then FText := TMemo(Dialog.Components[I]).Text;
    // Picture of the window as shown, beside the executable.
    Dialog.Update;
    Bitmap := TBitmap.Create; Png := TPngImage.Create;
    try
      Bitmap.SetSize(Dialog.ClientWidth, Dialog.ClientHeight);
      WindowDC := GetDC(Dialog.Handle);
      try BitBlt(Bitmap.Canvas.Handle, 0, 0, Dialog.ClientWidth, Dialog.ClientHeight, WindowDC, 0, 0, SRCCOPY);
      finally ReleaseDC(Dialog.Handle, WindowDC); end;
      Png.Assign(Bitmap);
      Png.SaveToFile(ChangeFileExt(ParamStr(0), '.license.png'));
    finally Png.Free; Bitmap.Free; end;
  finally
    Dialog.ModalResult := mrOk;
  end;
end;

procedure TAboutSmoke.Run(Owner: TForm; Language: TStylerLanguage);
var Form: TStylerAboutForm; Timer: TTimer; I: Integer; License: TButton;
begin
  Form := TStylerAboutForm.CreateAbout(Owner, Language, 'settings.json');
  try
    CheckControlHints(Form);
    License := nil;
    for I := 0 to Form.ComponentCount - 1 do
      if (Form.Components[I] is TButton) and (TButton(Form.Components[I]).Caption = L(stAboutLicenseTitle, Language)) then
        License := TButton(Form.Components[I]);
    if (License = nil) or not License.Enabled then raise Exception.Create('License button missing or disabled');
    Timer := TTimer.Create(Form);
    Timer.Interval := 300; Timer.OnTimer := Answer; Timer.Enabled := True;
    License.Click;
    if Pos('MIT License', FText) = 0 then raise Exception.Create('License text missing');
    if Pos('Unit Styler', FText) = 0 then
    begin
      if Language = slPortuguese then raise Exception.Create('License summary in Portuguese missing');
    end
    else if Language <> slPortuguese then raise Exception.Create('Portuguese summary shown in another language');
  finally Form.Free; end;
end;

var Workspace: IStylerWorkspace; F: TExecutionForm; Bitmap: TBitmap; Png: TPngImage;
  Language: TStylerLanguage; WindowDC: HDC; RenderForm: TForm; SettingsSmoke: TSettingsSmoke; AboutSmoke: TAboutSmoke;
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Language := slPortuguese;
  if FindCmdLineSwitch('pt') then Language := slPortuguese;
  if FindCmdLineSwitch('en') then Language := slEnglish;
  if FindCmdLineSwitch('es') then Language := slSpanish;
  if FindCmdLineSwitch('de') then Language := slGerman;
  if FindCmdLineSwitch('fr') then Language := slFrench;
  UseStylerLanguage(StylerLanguageCodes[Language]);
  Workspace := TMemoryWorkspace.Create;
  F := TExecutionForm.CreateWorkspace(nil, Workspace, Language);
  try
    if FindCmdLineSwitch('smoke-about') then
    begin
      // Only the About window and its license text, in the language given.
      try
        AboutSmoke := TAboutSmoke.Create;
        try AboutSmoke.Run(F, Language); finally AboutSmoke.Free; end;
      except
        on E: Exception do
        begin
          TFile.WriteAllText(ChangeFileExt(ParamStr(0), '.smoke-error.txt'), E.ClassName + ': ' + E.Message);
          ExitCode := 1;
        end;
      end;
    end
    else if FindCmdLineSwitch('smoke-test') then
    begin
      try
        CheckControlHints(F);
        F.SmokeTest;
        F.PrepareDemoPreview;
        RenderForm := F.CreatePreviewForm;
        try CheckControlHints(RenderForm); finally RenderForm.Free; end;
        SettingsSmoke := TSettingsSmoke.Create;
        try SettingsSmoke.Run(F, Workspace.LoadOptions); finally SettingsSmoke.Free; end;
        AboutSmoke := TAboutSmoke.Create;
        try AboutSmoke.Run(F, Language); finally AboutSmoke.Free; end;
      except
        on E: Exception do
        begin
          TFile.WriteAllText(ChangeFileExt(ParamStr(0), '.smoke-error.txt'), E.ClassName + ': ' + E.Message);
          ExitCode := 1;
        end;
      end;
    end
    else if FindCmdLineSwitch('render-preview') or FindCmdLineSwitch('render-settings') or FindCmdLineSwitch('render-comparison') or
      FindCmdLineSwitch('render-about') then
    begin
      RenderForm := F;
      if FindCmdLineSwitch('render-about') then
        RenderForm := TStylerAboutForm.CreateAbout(F, Language,
          IncludeTrailingPathDelimiter(Workspace.SettingsDirectory) + 'settings.json')
      else if FindCmdLineSwitch('render-settings') then
        RenderForm := TSettingsForm.CreateSettings(F, Language, Workspace.LoadOptions,
          RelativeUnitPaths(Workspace), Workspace.SettingsDirectory)
      else
      begin
        F.PrepareDemoPreview;
        if FindCmdLineSwitch('render-comparison') then RenderForm := F.CreatePreviewForm;
      end;
      RenderForm.Show;
      RenderForm.Update;
      Application.ProcessMessages;

      Bitmap := TBitmap.Create;
      Png := TPngImage.Create;
      try
        Bitmap.SetSize(RenderForm.ClientWidth, RenderForm.ClientHeight);
        ShowWindow(RenderForm.Handle, SW_SHOWNOACTIVATE);
        RedrawWindow(RenderForm.Handle, nil, 0, RDW_INVALIDATE or RDW_UPDATENOW or RDW_ALLCHILDREN);
        Application.ProcessMessages;
        WindowDC := GetDC(RenderForm.Handle);
        try
          if not BitBlt(Bitmap.Canvas.Handle, 0, 0, RenderForm.ClientWidth, RenderForm.ClientHeight, WindowDC, 0, 0, SRCCOPY) then
            raise Exception.Create('Unable to render window');
        finally ReleaseDC(RenderForm.Handle, WindowDC); end;
        Png.Assign(Bitmap);
        Png.SaveToFile(ParamStr(ParamCount));
      finally Png.Free; Bitmap.Free; end;
      RenderForm.Hide;
      if RenderForm <> F then RenderForm.Free;
    end
    else F.ShowModal;
  finally F.Free; Workspace := nil; end;
end.
