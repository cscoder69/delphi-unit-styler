unit CSCoder.Styler.IdeSelfTest;

// Automated check of the IDE integration. It is compiled only into the test
// package and runs only when CSCODER_STYLER_SELFTEST names a report file.
// The driving script opens a prepared copy of a project in an isolated IDE
// profile; this unit exercises the three scopes and writes what it observed.

interface

procedure Register;
implementation

uses System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, Winapi.Windows, Winapi.Messages,
  Vcl.Graphics, Vcl.Controls, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.Imaging.pngimage, CSCoder.Styler.SettingsForm, CSCoder.Styler.About, Vcl.Forms, Vcl.ExtCtrls, Vcl.Menus, Vcl.ActnPopup, ToolsAPI,
  CSCoder.Styler.Types, CSCoder.Styler.Engine, CSCoder.Styler.Strings, CSCoder.Styler.Workspace,
  CSCoder.Styler.EditorAdapter, CSCoder.Styler.ExecutionForm, CSCoder.Styler.SourceFile, CSCoder.Styler.EditorMenu,
  CSCoder.Styler.ProjectSettings, CSCoder.Styler.ControlHelp;

type
  TSelfTest = class
  private
    FTimer: TTimer;
    FReport: TStringList;
    FReportFile, FMode, FRoot, FOriginals: string;
    FTicks, FFailures: Integer;
    FRunning, FOpening: Boolean;
    FModalTimer: TTimer;
    FModalName: string;
    FLanguagePick: Integer;
    FPopupMenu: TPopupMenu;
    FPopupShot: string;
    FPopupAt: TPoint;
    FWatch: TTimer;
    FWatchWindow: HWND;
    FWatchTicks, FWatchAttempts, FWatchPatience: Integer;
    procedure WatchDialogs(Sender: TObject);
    procedure Tick(Sender: TObject);
    procedure Run;
    procedure RunRealProject;
    procedure RunShots;
    procedure Shot(Form: TCustomForm; const Name: string);
    procedure Capture(Form: TCustomForm; const Name: string);
    procedure CaptureModal(Sender: TObject);
    procedure ClosePopup(Sender: TObject);
    procedure ShotOfModal(const Name: string; const Open: TProc);
    procedure Check(Value: Boolean; const Name: string; const Detail: string = '');
    procedure Note(const Text: string);
    function Editor(const UnitFile: string): IOTASourceEditor;
    function Buffer(const UnitFile: string): string;
    function IsOpen(const UnitFile: string): Boolean;
    function DiskEqualsOriginal(const UnitFile: string): Boolean;
    function DiskEqualsOrganized(const UnitFile: string; const Options: TUsesOptions): Boolean;
    function Organized(const Text: string; const Options: TUsesOptions): string;
    procedure OpenInEditor(const UnitFile: string);
    function BackupHolds(const Directory, UnitFile: string): Boolean;
    function BackupCount(const Directory: string): Integer;
  public
    constructor Create(const ReportFile: string);
    destructor Destroy; override;
  end;

var SelfTest: TSelfTest;

function SourceEditorOf(const Module: IOTAModule): IOTASourceEditor;
var I: Integer;
begin
  Result := nil;
  if Module = nil then Exit;
  for I := 0 to Module.ModuleFileCount - 1 do
    if Supports(Module.ModuleFileEditors[I], IOTASourceEditor, Result) and
      SameText(ExtractFileExt(Result.FileName), '.pas') then Exit;
  Result := nil;
end;

function ReadEditor(const Editor: IOTASourceEditor): string;
var Reader: IOTAEditReader; Chunk: array[0..8191] of AnsiChar; Count, Position: Integer; Bytes: UTF8String;
begin
  Reader := Editor.CreateReader; Bytes := ''; Position := 0;
  repeat
    Count := Reader.GetText(Position, @Chunk[0], Length(Chunk));
    if Count > 0 then
    begin
      SetLength(Bytes, Position + Count);
      Move(Chunk[0], Bytes[Position + 1], Count);
      Inc(Position, Count);
    end;
  until Count <= 0;
  Reader := nil;
  Result := UTF8ToString(Bytes);
end;

// Through the extended prefix: a backup copy may sit beyond MAX_PATH.
function ReadLong(const Name: string; out Bytes: TBytes): Boolean;
var Handle: THandle; Stream: THandleStream;
begin
  Bytes := nil;
  Handle := FileOpen('\\?\' + Name, fmOpenRead or fmShareDenyNone);
  if Handle = INVALID_HANDLE_VALUE then Exit(False);
  Stream := THandleStream.Create(Handle);
  try
    SetLength(Bytes, Integer(Stream.Size));
    if Length(Bytes) > 0 then Stream.ReadBuffer(Bytes[0], Length(Bytes));
  finally Stream.Free; FileClose(Handle); end;
  Result := True;
end;

function LineOfText(const Text, Marker: string): Integer;
var P, I: Integer;
begin
  P := Pos(Marker, Text);
  if P = 0 then Exit(0);
  Result := 1;
  for I := 1 to P - 1 do
    if Text[I] = #10 then Inc(Result);
end;

// What the IDE is showing, to explain a run that could not proceed.
function ActiveWindows: string;
var I: Integer;
begin
  Result := '';
  if Screen.ActiveForm <> nil then
    Result := 'ativa=' + Screen.ActiveForm.ClassName + ' "' + Screen.ActiveForm.Caption + '"';
  for I := 0 to Screen.FormCount - 1 do
    if Screen.Forms[I].Visible then
      Result := Result + ' [' + Screen.Forms[I].ClassName + ' "' + Screen.Forms[I].Caption + '"]';
end;

// Filled by the window enumeration callbacks below.
var WatchFound: HWND; WatchTexts: TStrings;

function FindDialog(Window: HWND; Param: LPARAM): BOOL; stdcall;
var Name: array[0..63] of Char; Control: TWinControl;
begin
  Result := True;
  if not IsWindowVisible(Window) or not IsWindowEnabled(Window) then Exit;
  GetClassName(Window, Name, Length(Name));
  Control := FindControl(Window);
  if (StrComp(Name, '#32770') = 0) or
    ((Control is TCustomForm) and (fsModal in TCustomForm(Control).FormState)) then
  begin
    WatchFound := Window;
    Result := False;
  end;
end;

function CollectText(Window: HWND; Param: LPARAM): BOOL; stdcall;
var Text: array[0..511] of Char;
begin
  Result := True;
  if IsWindowVisible(Window) and (GetWindowText(Window, Text, Length(Text)) > 0) then
    WatchTexts.Add(Text);
end;

// Nobody is there to answer a dialog of the test IDE: one that stays open is
// written to the report with its text and closed, so the run always finishes.
procedure TSelfTest.WatchDialogs(Sender: TObject);
const Answers: array[0..2] of Integer = (IDOK, IDNO, IDCANCEL);
var Found: HWND; Texts: TStringList; Caption: array[0..255] of Char; Control: TWinControl;
begin
  WatchFound := 0;
  EnumThreadWindows(MainThreadID, @FindDialog, 0);
  Found := WatchFound;
  if (Found = 0) or (Found <> FWatchWindow) then
  begin
    FWatchWindow := Found; FWatchTicks := 0; FWatchAttempts := 0;
    Exit;
  end;
  Inc(FWatchTicks);
  // A dialog that is only passing by, such as compile progress, closes by itself.
  if FWatchTicks < FWatchPatience then Exit;
  if FWatchAttempts = 0 then
  begin
    Texts := TStringList.Create;
    try
      Caption[0] := #0; GetWindowText(Found, Caption, Length(Caption));
      WatchTexts := Texts;
      EnumChildWindows(Found, @CollectText, 0);
      Note('INFO | Dialogo fechado pelo autoteste: "' + Caption + '" | ' +
        StringReplace(Trim(Texts.Text), sLineBreak, ' // ', [rfReplaceAll]));
    finally Texts.Free; end;
  end;
  Control := FindControl(Found);
  if (Control is TCustomForm) and (fsModal in TCustomForm(Control).FormState) and (FWatchAttempts = 0) then
    TCustomForm(Control).ModalResult := mrNo
  else if FWatchAttempts <= High(Answers) then PostMessage(Found, WM_COMMAND, WPARAM(Answers[FWatchAttempts]), 0)
  else PostMessage(Found, WM_CLOSE, 0, 0);
  Inc(FWatchAttempts);
end;

constructor TSelfTest.Create(const ReportFile: string);
begin
  inherited Create;
  // The checks read Portuguese texts, whatever the language of this Windows.
  // Mode shots can ask for another language to picture the windows in it.
  UseStylerLanguage('pt');
  if GetEnvironmentVariable('CSCODER_STYLER_SELFTEST_LANG') <> '' then
    UseStylerLanguage(GetEnvironmentVariable('CSCODER_STYLER_SELFTEST_LANG'));
  FReportFile := ReportFile;
  FMode := GetEnvironmentVariable('CSCODER_STYLER_SELFTEST_MODE');
  FReport := TStringList.Create;
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 1000; FTimer.OnTimer := Tick; FTimer.Enabled := True;
  FWatch := TTimer.Create(FTimer);
  FWatch.Interval := 1000; FWatch.OnTimer := WatchDialogs; FWatch.Enabled := False;
end;

destructor TSelfTest.Destroy;
begin FTimer.Free; FReport.Free; inherited; end;

procedure TSelfTest.Note(const Text: string);
var Attempt: Integer;
begin
  FReport.Add(Text);
  // Written at every step so a hang still leaves what was observed so far.
  // The driving script reads the file while waiting: try again when it is busy.
  for Attempt := 1 to 10 do
    try
      FReport.SaveToFile(FReportFile, TEncoding.UTF8);
      Break;
    except
      on E: EFCreateError do
        if Attempt = 10 then raise else Sleep(100);
    end;
end;

procedure TSelfTest.Check(Value: Boolean; const Name, Detail: string);
begin
  if Value then Note('PASS | ' + Name)
  else
  begin
    Inc(FFailures);
    Note('FAIL | ' + Name + ' | ' + Detail);
  end;
end;

procedure TSelfTest.Tick(Sender: TObject);
var Project: IOTAProject;
begin
  if FRunning then Exit;
  Inc(FTicks);
  Project := GetActiveProject;
  // Wait for the project given on the command line; give up after two minutes.
  if (Project = nil) or (Project.GetModuleCount = 0) then
  begin
    // The command line may not open the project in a fresh profile: ask the IDE.
    if FOpening then
    begin
      // A dialog raised by the project being opened keeps this timer running.
      if FTicks mod 20 = 0 then Note('INFO | Abrindo projeto, IDE mostra: ' + ActiveWindows);
    end
    else if FTicks = 15 then
    begin
      FOpening := True;
      try
        try
          (BorlandIDEServices as IOTAActionServices).OpenProject(
            GetEnvironmentVariable('CSCODER_STYLER_SELFTEST_PROJECT'), True);
        except
          on E: Exception do Note('INFO | OpenProject: ' + E.Message);
        end;
      finally FOpening := False; end;
    end;
    if FTicks > 120 then
    begin
      FTimer.Enabled := False;
      Note('FAIL | Projeto de teste nao carregou na IDE | ' + ActiveWindows);
      Note('DONE | 1');
    end;
    Exit;
  end;
  if FOpening or (FTicks < 5) then Exit;
  FRunning := True; FTimer.Enabled := False;
  // The pictures open and close their own modal windows.
  FWatch.Enabled := not SameText(FMode, 'shots');
  try
    if FWatch.Enabled then
    begin
      // Proof that a forgotten dialog does not hold the run: nobody answers this one.
      FWatchPatience := 2;
      Application.MessageBox('Teste do fechamento automatico de dialogos.', 'Unit Styler - autoteste', MB_OK);
      FWatchPatience := 15;
      Check(True, 'Dialogo sem resposta e fechado pelo autoteste');
    end;
    if SameText(FMode, 'real') then RunRealProject
    else if SameText(FMode, 'shots') then RunShots
    else Run;
  except
    on E: Exception do Check(False, 'Execucao do autoteste', E.ClassName + ': ' + E.Message);
  end;
  FWatch.Enabled := False;
  Note('DONE | ' + IntToStr(FFailures));
end;

function TSelfTest.Editor(const UnitFile: string): IOTASourceEditor;
begin
  Result := SourceEditorOf((BorlandIDEServices as IOTAModuleServices).FindModule(TPath.Combine(FRoot, UnitFile)));
end;

function TSelfTest.IsOpen(const UnitFile: string): Boolean;
begin Result := Editor(UnitFile) <> nil; end;

function TSelfTest.Buffer(const UnitFile: string): string;
begin Result := ReadEditor(Editor(UnitFile)); end;

procedure TSelfTest.OpenInEditor(const UnitFile: string);
begin
  (BorlandIDEServices as IOTAActionServices).OpenFile(TPath.Combine(FRoot, UnitFile));
end;

function TSelfTest.Organized(const Text: string; const Options: TUsesOptions): string;
begin Result := AnalyzeUses(Text, Options).ApplyTo(Text); end;

function TSelfTest.DiskEqualsOriginal(const UnitFile: string): Boolean;
var A, B: TBytes;
begin
  A := TFile.ReadAllBytes(TPath.Combine(FRoot, UnitFile));
  B := TFile.ReadAllBytes(TPath.Combine(FOriginals, UnitFile));
  Result := (Length(A) = Length(B)) and ((Length(A) = 0) or CompareMem(@A[0], @B[0], Length(A)));
end;

function TSelfTest.DiskEqualsOrganized(const UnitFile: string; const Options: TUsesOptions): Boolean;
var Original: TSourceFile; Expected, Actual: TBytes;
begin
  // Expected bytes come from the untouched copy, independently of the adapter.
  Original := LoadSourceFile(TPath.Combine(FOriginals, UnitFile));
  Expected := EncodeSource(Organized(Original.Text, Options), Original.Encoding);
  Actual := TFile.ReadAllBytes(TPath.Combine(FRoot, UnitFile));
  Result := (Length(Actual) = Length(Expected)) and (Length(Actual) > 0) and
    CompareMem(@Actual[0], @Expected[0], Length(Actual)) and not DiskEqualsOriginal(UnitFile);
end;

// The copy in the run's backup folder is the file as it was saved before the run.
function TSelfTest.BackupHolds(const Directory, UnitFile: string): Boolean;
var A, B: TBytes;
begin
  if (Directory = '') or not ReadLong(TPath.Combine(Directory, UnitFile), A) then Exit(False);
  B := TFile.ReadAllBytes(TPath.Combine(FOriginals, UnitFile));
  Result := (Length(A) = Length(B)) and ((Length(A) = 0) or CompareMem(@A[0], @B[0], Length(A)));
end;

function TSelfTest.BackupCount(const Directory: string): Integer;
begin
  if (Directory = '') or not TDirectory.Exists(Directory) then Exit(0);
  Result := Integer(Length(TDirectory.GetFiles(Directory, '*', TSearchOption.soAllDirectories)));
end;

procedure TSelfTest.Run;
const
  Current = 'U_Open1.pas';
  OtherOpen = 'U_Open2.pas';
  Closed: array[0..4] of string = ('U_ClosedAnsi.pas', 'U_ClosedUtf8Bom.pas', 'U_ClosedLf.pas',
    'U_ClosedDirective.pas', 'Forms\U_Form.pas');
  Ignored = 'Terceiros\U_Third.pas';
  ReadOnlyUnit = 'U_ReadOnly.pas';
  Marker = 'CursorAqui';
var
  Project: IOTAProject; Workspace: IStylerWorkspace; IDE: TIDEWorkspace; Form: TExecutionForm;
  Options: TUsesOptions; Before, After, Issues, Name: string; Writer: IOTAEditWriter;
  View: IOTAEditView; Position: TOTAEditPos; EditBuffer: IOTAEditBuffer; Names: TArray<string>;
  CurrentEditor: IOTASourceEditor; ColumnBefore, I, Expected: Integer; SaveMode: Boolean;
  BackupRoot, FirstBackup, Backup: string;
begin
  Project := GetActiveProject;
  FRoot := ExtractFileDir(Project.FileName);
  FOriginals := TPath.Combine(ExtractFileDir(FRoot), 'orig');
  SaveMode := not SameText(FMode, 'nosave');
  Note('INFO | Projeto ' + Project.FileName + ' | modo ' + FMode);
  Options := Default(TUsesOptions);
  Options.Alphabetical := True; Options.OneUnitPerLine := True;
  Options.IndentationEnabled := True; Options.Indentation := '  ';
  Options.AutoSaveUnits := SaveMode; Options.BackupUnits := True;
  Options.IgnoredPaths := ['Terceiros\'];

  OpenInEditor(OtherOpen); OpenInEditor(Current);
  Application.ProcessMessages;
  CurrentEditor := Editor(Current);
  Check((CurrentEditor <> nil) and IsOpen(OtherOpen), 'Duas units abertas no editor');
  if CurrentEditor = nil then Exit;

  // Unsaved text in the buffer must be what the tool reads.
  Writer := CurrentEditor.CreateUndoableWriter;
  Writer.Insert(PAnsiChar(UTF8String('// nao salvo'#13#10)));
  Writer := nil;
  View := CurrentEditor.EditViews[0];
  Before := Buffer(Current);
  Position.Line := LineOfText(Before, Marker); Position.Col := 7;
  View.CursorPos := Position;
  ColumnBefore := View.CursorPos.Col;

  IDE := TIDEWorkspace.Create(False); Workspace := IDE;
  Names := Workspace.UnitNames;
  Check(Length(Names) = 10, 'Somente as units do projeto sao listadas', IntToStr(Length(Names)));
  Check(not TFile.Exists(TPath.Combine(FRoot, 'ForaDoProjeto.pas')) or (Length(Names) = 10),
    'Arquivo da pasta que nao esta no projeto fica de fora');
  Check((Workspace.CurrentUnit >= 0) and SameText(ExtractFileName(Names[Workspace.CurrentUnit]), Current),
    'Unit atual identificada');
  Check(Length(Workspace.OpenUnitIndices) = 2, 'Units abertas identificadas', IntToStr(Length(Workspace.OpenUnitIndices)));
  Check(Workspace.SupportsBatch, 'Lote habilitado na IDE');
  Check(Pos('// nao salvo', Workspace.ReadSource(Workspace.CurrentUnit)) = 1, 'Leitura do buffer nao salvo');

  Form := TExecutionForm.CreateWorkspace(nil, Workspace, StylerLanguage);
  try
    // Scope: current unit.
    Form.RunUnattended(Options, 0, False);
    Check(Buffer(Current) = Before, 'Responder Nao mantem o buffer');
    BackupRoot := TPath.Combine(FRoot, '.backup');
    Check(not TDirectory.Exists(BackupRoot), 'Responder Nao nao cria backup');
    Issues := Form.RunUnattended(Options, 0, True);
    After := Buffer(Current);
    Check(After = Organized(Before, Options), 'Unit atual organizada no buffer', Issues);
    Check(After <> Before, 'Unit atual tinha o que organizar');
    Check(DiskEqualsOriginal(Current), 'Unit atual nao foi salva em disco');
    // The buffer had unsaved text: the copy must be the saved file, not the buffer.
    FirstBackup := Workspace.BackupDirectory;
    Check(SameText(ExtractFileDir(FirstBackup), BackupRoot) and BackupHolds(FirstBackup, Current) and
      (BackupCount(FirstBackup) = 1), 'Backup da unit aberta: arquivo como estava gravado', FirstBackup);
    Check(CurrentEditor.Modified, 'Unit atual fica marcada como modificada');
    Check(Buffer(OtherOpen) <> Organized(Buffer(OtherOpen), Options), 'Escopo Unit atual nao toca outra unit aberta');
    Check((View.CursorPos.Line = LineOfText(After, Marker)) and (View.CursorPos.Col = ColumnBefore),
      'Cursor acompanha a linha e mantem a coluna', Format('linha %d (esperada %d), coluna %d (esperada %d)',
      [View.CursorPos.Line, LineOfText(After, Marker), View.CursorPos.Col, ColumnBefore]));
    if Supports(CurrentEditor, IOTAEditBuffer, EditBuffer) then
    begin
      EditBuffer.Undo;
      Check(Buffer(Current) = Before, 'Um Desfazer restaura as duas clausulas');
      EditBuffer.Redo;
      Check(Buffer(Current) = After, 'Refazer reaplica a organizacao');
    end
    else Check(False, 'Desfazer disponivel', 'IOTAEditBuffer indisponivel');
    Form.RunUnattended(Options, 0, True);
    Check(Buffer(Current) = After, 'Segunda execucao na unit atual nao muda nada');
    Check(Length(TDirectory.GetDirectories(BackupRoot)) = 1, 'Execucao sem mudancas nao cria pasta de backup');

    // Scope: open units.
    Before := Buffer(OtherOpen);
    Issues := Form.RunUnattended(Options, 1, True);
    Check(Buffer(OtherOpen) = Organized(Before, Options), 'Units abertas: segunda unit organizada no buffer', Issues);
    Check(DiskEqualsOriginal(OtherOpen) and DiskEqualsOriginal(Current), 'Units abertas nao foram salvas');
    Backup := Workspace.BackupDirectory;
    Check(not SameText(Backup, FirstBackup) and BackupHolds(Backup, OtherOpen) and (BackupCount(Backup) = 1),
      'Units abertas: backup em pasta propria da execucao, so da unit alterada', Backup);
    for Name in Closed do
      Check(DiskEqualsOriginal(Name) and not IsOpen(Name), 'Units abertas: fechada intacta ' + Name);

    // Scope: whole project.
    Issues := Form.RunUnattended(Options, 2, True);
    Note('INFO | Relatorio do lote: ' + StringReplace(Trim(Issues), sLineBreak, ' // ', [rfReplaceAll]));
    Note('INFO | Status: ' + Form.StatusText);
    for Name in Closed do
      if SaveMode then
      begin
        Check(DiskEqualsOrganized(Name, Options), 'Fechada regravada na codificacao original ' + Name);
        Check(not IsOpen(Name), 'Fechada continua fechada no Delphi ' + Name);
      end
      else
      begin
        Check(IsOpen(Name), 'Sem salvar: fechada foi aberta no editor ' + Name);
        Check(DiskEqualsOriginal(Name), 'Sem salvar: disco intacto ' + Name);
        if IsOpen(Name) then
        begin
          Check(Editor(Name).Modified, 'Sem salvar: unit fica modificada ' + Name);
          Check(Buffer(Name) = Organized(Buffer(Name), Options), 'Sem salvar: buffer organizado ' + Name);
        end;
      end;
    Backup := Workspace.BackupDirectory;
    Note('INFO | Backup do lote: ' + Backup);
    for Name in Closed do
      Check(BackupHolds(Backup, Name), 'Backup da unit fechada, bytes originais ' + Name);
    // Only what was changed is copied: not the ignored folder, the preserved unit,
    // the units already organized or a file that refused the rewrite.
    Expected := Length(Closed);
    if not SaveMode and IsOpen(ReadOnlyUnit) and Editor(ReadOnlyUnit).Modified then Inc(Expected);
    Check(BackupCount(Backup) = Expected, 'Backup do lote tem somente as units alteradas',
      Format('%d arquivos, esperados %d', [BackupCount(Backup), Expected]));
    Check(Length(TDirectory.GetDirectories(BackupRoot)) = 3, 'Uma pasta de backup por execucao',
      IntToStr(Length(TDirectory.GetDirectories(BackupRoot))));
    Check(DiskEqualsOriginal(Ignored) and not IsOpen(Ignored), 'Pasta ignorada nao foi tocada');
    Check(Pos('U_Third', Issues) = 0, 'Unit ignorada nao aparece no relatorio');
    Check(DiskEqualsOriginal(Current) and DiskEqualsOriginal(OtherOpen), 'Lote nao salva units que ja estavam abertas');
    if SaveMode then
    begin
      Check(DiskEqualsOriginal(ReadOnlyUnit), 'Arquivo somente leitura nao foi alterado');
      Check((Pos('U_ReadOnly', Issues) > 0) and (Pos('Erro', Issues) > 0), 'Somente leitura aparece como erro no relatorio', Issues);
    end;
    I := Pos('U_Comment', Issues);
    Check((I > 0) and DiskEqualsOriginal('U_Comment.pas'), 'Comentario no meio do uses: unit preservada e avisada', Issues);
    // The comment written beside SysUtils went with it to the last line.
    if SaveMode then
      Check((Pos('System.SysUtils; // ', TEncoding.ANSI.GetString(TFile.ReadAllBytes(TPath.Combine(FRoot, 'U_ClosedAnsi.pas')))) > 0) and
        (Pos('U_ClosedAnsi', Issues) = 0), 'Comentario de fim de linha acompanha a unit, sem aviso', Issues)
    else if IsOpen('U_ClosedAnsi.pas') then
      Check(Pos('System.SysUtils; // ', Buffer('U_ClosedAnsi.pas')) > 0, 'Comentario de fim de linha acompanha a unit no editor');

    Issues := Form.RunUnattended(Options, 2, True);
    for Name in Closed do
      if SaveMode then Check(DiskEqualsOrganized(Name, Options), 'Segundo lote nao muda ' + Name);
    Check(Length(TDirectory.GetDirectories(BackupRoot)) = 3, 'Segundo lote nao cria pasta de backup');

    // Backup turned off in the settings: the unit is changed and nothing is copied.
    if Supports(CurrentEditor, IOTAEditBuffer, EditBuffer) then
    begin
      EditBuffer.Undo;
      Check(Buffer(Current) <> After, 'Desfazer devolve a unit atual para o teste sem backup');
      Options.BackupUnits := False;
      Issues := Form.RunUnattended(Options, 0, True);
      Options.BackupUnits := True;
      Check(Buffer(Current) = After, 'Sem copia de seguranca: unit organizada', Issues);
      Check((Workspace.BackupDirectory = '') and (Length(TDirectory.GetDirectories(BackupRoot)) = 3),
        'Sem copia de seguranca: nenhuma pasta criada', Workspace.BackupDirectory);
      Note('INFO | Status sem backup: ' + Form.StatusText);
    end;
  finally
    Form.Free;
  end;
  Workspace := nil;

  // The organized project, open buffers included, must still compile.
  Check(Project.ProjectBuilder.BuildProject(cmOTAMake, True, True), 'Projeto compila na IDE depois do lote');
end;

// Pictures of the tool's windows as the IDE draws them, for a visual review of
// the active theme without anyone clicking through the screens.
procedure TSelfTest.Capture(Form: TCustomForm; const Name: string);
var Bounds: TRect; Bitmap: TBitmap; Png: TPngImage; Screen: HDC;
begin
  // Above every other window: the picture is taken from the screen.
  SetWindowPos(Form.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
  Form.BringToFront; Form.Update;
  Application.ProcessMessages; Sleep(700); Application.ProcessMessages;
  GetWindowRect(Form.Handle, Bounds);
  Bitmap := TBitmap.Create; Png := TPngImage.Create;
  try
    Bitmap.SetSize(Bounds.Width, Bounds.Height);
    // Copied from the screen, exactly as the user would see it.
    Bitmap.PixelFormat := pf24bit;
    Screen := GetDC(0);
    try
      BitBlt(Bitmap.Canvas.Handle, 0, 0, Bounds.Width, Bounds.Height, Screen, Bounds.Left, Bounds.Top, SRCCOPY);
    finally ReleaseDC(0, Screen); end;
    Png.Assign(Bitmap);
    Png.SaveToFile(TPath.Combine(GetEnvironmentVariable('CSCODER_STYLER_SELFTEST_SHOTS'), Name + '.png'));
    Note('INFO | Captura ' + Name + '.png');
  finally Png.Free; Bitmap.Free; end;
end;

procedure TSelfTest.Shot(Form: TCustomForm; const Name: string);
begin
  TForm(Form).FormStyle := fsStayOnTop;
  Form.Show;
  Capture(Form, Name);
  Form.Hide;
end;

// A modal window is pictured from a timer while it is open, then dismissed.
procedure TSelfTest.CaptureModal(Sender: TObject);
var Form: TCustomForm; I, Missing: Integer; Text: string; Combo: TComboBox;
begin
  FModalTimer.Enabled := False;
  Form := Vcl.Forms.Screen.ActiveCustomForm;
  if Form = nil then begin Check(False, 'Janela modal aberta', FModalName); Exit; end;
  Capture(Form, FModalName);
  if FModalName = 'menu-do-editor' then
    Check(Form is TExecutionForm, 'O item do menu de contexto abre Organizar uses', Form.ClassName + ' "' + Form.Caption + '"');
  if FModalName = 'atalho' then
    Check(Form is TExecutionForm, 'A combinacao de teclas abre Organizar uses', Form.ClassName + ' "' + Form.Caption + '"');
  if FModalName = 'sobre' then
  begin
    Check(Form is TStylerAboutForm, 'O menu abre a tela Sobre, mesmo sem projeto', Form.ClassName + ' "' + Form.Caption + '"');
    Missing := 0;
    for I := 0 to Form.ComponentCount - 1 do
      if (Form.Components[I] is TButton) or ((Form.Components[I] is TLabel) and Assigned(TLabel(Form.Components[I]).OnClick)) then
        if (TControl(Form.Components[I]).Hint = '') or not TControl(Form.Components[I]).ShowHint then Inc(Missing);
    Check(Missing = 0, 'Sobre: botoes e links com hint', IntToStr(Missing) + ' sem hint');
    // The license text, opened by its button while the About window is up.
    Missing := 0;
    for I := 0 to Form.ComponentCount - 1 do
      if (Form.Components[I] is TButton) and (TButton(Form.Components[I]).Caption = L(stAboutLicenseTitle, StylerLanguage)) then
      begin
        Inc(Missing);
        Check(TButton(Form.Components[I]).Enabled, 'Sobre: botao Licenca habilitado');
        FModalName := 'sobre-licenca';
        FModalTimer.Enabled := True;
        TButton(Form.Components[I]).Click;
        FModalTimer.Enabled := False;
        FModalName := 'sobre';
      end;
    Check(Missing = 1, 'Sobre: botao Licenca encontrado');
  end
  else if FModalName = 'sobre-licenca' then
  begin
    Text := '';
    for I := 0 to Form.ComponentCount - 1 do
      if Form.Components[I] is TMemo then Text := TMemo(Form.Components[I]).Text;
    Check((Form is TStylerDialog) and (Pos('MIT License', Text) > 0), 'Sobre: a janela da licenca mostra o texto MIT',
      Form.ClassName + ' "' + Form.Caption + '"');
    Check((Pos('Resumo da licen', Text) > 0) = (StylerLanguage = slPortuguese), 'Sobre: resumo em portugues so quando o idioma e portugues');
  end;
  if Pos('idioma-', FModalName) = 1 then
  begin
    // Picks a language and saves: the window closes by its own Save button.
    Check(Form is TSettingsForm, 'Idioma: o menu abre as Configuracoes', Form.ClassName + ' "' + Form.Caption + '"');
    Combo := Form.FindComponent('cbLanguage') as TComboBox;
    if (Form is TSettingsForm) and (Combo <> nil) then
    begin
      Combo.ItemIndex := FLanguagePick;
      for I := 0 to Form.ComponentCount - 1 do
        if (Form.Components[I] is TButton) and (TButton(Form.Components[I]).Caption = L(stSave, StylerLanguage)) then
        begin
          TButton(Form.Components[I]).Click;
          Exit;
        end;
    end;
    Check(False, 'Idioma: campo Idioma e botao Salvar encontrados');
  end;
  if FModalName = 'dialogo-CleanBackups' then
  begin
    // Two runs and a folder of the user were left in .backup before the click.
    Check(TDirectory.Exists(FRoot + '\.backup\2026-10-10_08-00-00') and TDirectory.Exists(FRoot + '\.backup\2026-10-11_09-00-00'),
      'Limpar backups: abrir o dialogo nao apaga nada');
    for I := 0 to Form.ComponentCount - 1 do
      if (Form.Components[I] is TButton) and (TButton(Form.Components[I]).Caption = L(stDelete, StylerLanguage)) then
      begin
        TButton(Form.Components[I]).Click;
        Check(not TDirectory.Exists(FRoot + '\.backup\2026-10-10_08-00-00') and TDirectory.Exists(FRoot + '\.backup\2026-10-11_09-00-00'),
          'Limpar backups: apaga as antigas e mantem a mais recente');
        Application.ProcessMessages;
        Capture(Form, FModalName + '-depois');
        TButton(Form.Components[I]).Click;
        Check(not TDirectory.Exists(FRoot + '\.backup\2026-10-11_09-00-00') and TFile.Exists(FRoot + '\.backup\20261006_1304_do_usuario\minha.pas') and
          not TButton(Form.Components[I]).Enabled, 'Limpar backups: apaga a ultima e nao toca na pasta do usuario');
      end;
  end;
  if FModalName = 'configuracoes-sem-projeto' then
  begin
    Check(Form is TSettingsForm, 'Sem projeto: o menu abre as Configuracoes', Form.ClassName + ' "' + Form.Caption + '"');
    if Form is TSettingsForm then
    begin
      Check(not TButton(Form.FindComponent('btnPreservedUnits')).Enabled and
        not TButton(Form.FindComponent('btnIgnoredPaths')).Enabled, 'Sem projeto: configuracoes do projeto bloqueadas');
      Check(TButton(Form.FindComponent('btnEditPriority')).Enabled and TButton(Form.FindComponent('btnEditGroups')).Enabled and
        TButton(Form.FindComponent('btnSettingsFolder')).Enabled, 'Sem projeto: regras globais editaveis');
    end;
  end;
  Form.ModalResult := mrCancel;
end;

// The editor context menu is open, as after a right click: pictured from the
// screen, then closed.
procedure TSelfTest.ClosePopup(Sender: TObject);
var Bitmap: TBitmap; Png: TPngImage; Screen: HDC; Top: Integer;
begin
  TTimer(Sender).Enabled := False;
  if FPopupShot <> '' then
  begin
    Top := FPopupAt.Y - 700; if Top < 0 then Top := 0;
    Bitmap := TBitmap.Create; Png := TPngImage.Create;
    try
      Bitmap.PixelFormat := pf24bit; Bitmap.SetSize(520, 1040);
      Screen := GetDC(0);
      try BitBlt(Bitmap.Canvas.Handle, 0, 0, 520, 1040, Screen, FPopupAt.X - 20, Top, SRCCOPY);
      finally ReleaseDC(0, Screen); end;
      Png.Assign(Bitmap);
      Png.SaveToFile(TPath.Combine(GetEnvironmentVariable('CSCODER_STYLER_SELFTEST_SHOTS'), FPopupShot + '.png'));
      Note('INFO | Captura ' + FPopupShot + '.png');
    finally Png.Free; Bitmap.Free; end;
  end;
  if (FPopupMenu is TPopupActionBar) and (TPopupActionBar(FPopupMenu).PopupMenu <> nil) then
    TPopupActionBar(FPopupMenu).PopupMenu.CloseMenu
  else if FPopupMenu <> nil then FPopupMenu.CloseMenu;
  EndMenu;
end;

procedure TSelfTest.ShotOfModal(const Name: string; const Open: TProc);
begin
  if FModalTimer = nil then
  begin
    FModalTimer := TTimer.Create(FTimer);
    FModalTimer.Enabled := False; FModalTimer.Interval := 600; FModalTimer.OnTimer := CaptureModal;
  end;
  FModalName := Name;
  FModalTimer.Enabled := True;
  Open;
  FModalTimer.Enabled := False;
end;

// A command of the tool's own submenu, as registered in the IDE menu.
function ToolMenuItem(Parent: TMenuItem; const Caption: string): TMenuItem;
var I: Integer;
begin
  for I := 0 to Parent.Count - 1 do
  begin
    if SameText(StringReplace(Parent.Caption, '&', '', [rfReplaceAll]), 'Unit Styler') and
      SameText(StringReplace(Parent[I].Caption, '&', '', [rfReplaceAll]), Caption) then Exit(Parent[I]);
    Result := ToolMenuItem(Parent[I], Caption);
    if Result <> nil then Exit;
  end;
  Result := nil;
end;

procedure TSelfTest.RunShots;
var Workspace: IStylerWorkspace; Form: TExecutionForm; Preview: TForm; Settings: TSettingsForm;
  Options: TUsesOptions; Theming: IOTAIDEThemingServices; EditOptions: IOTAEditOptions; I: Integer;
  Button: TButton; Item: TMenuItem; Binding: TKeyBindingRec; Popup: TPopupMenu; View: IOTAEditView; Count: Integer;
  MainItems: TMenuItem;

  function SavedLanguage: string;
  var Addon: TProjectSettings;
  begin
    Addon := TProjectSettings.Create('');
    try Result := Addon.Load.Language; finally Addon.Free; end;
  end;

  function MenuIn(Language: TStylerLanguage): Boolean;
  begin
    Result := (ToolMenuItem(MainItems, L(stOrganize, Language) + '...') <> nil) and
      (ToolMenuItem(MainItems, L(stSettings, Language)) <> nil) and (ToolMenuItem(MainItems, L(stAbout, Language) + '...') <> nil);
  end;

  // Opens the editor context menu as a right click does, and closes it. The
  // command must be there once, last, and the IDE must not complain: with a
  // foreign item left inside, Delphi 11 and 12 failed on the third opening.
  procedure OpenEditorMenu(const Tag: string);
  var J, Mine, Times: Integer; S: string; Closer: TTimer; Started: Cardinal;
  begin
    if Popup = nil then Exit;
    S := 'ok';
    Closer := TTimer.Create(nil);
    try
      Closer.Interval := 900; Closer.OnTimer := ClosePopup;
      FPopupMenu := Popup; FPopupShot := ''; if Tag = '1' then FPopupShot := 'menu-botao-direito';
      View := (BorlandIDEServices as IOTAEditorServices).TopView;
      FPopupAt := View.GetEditWindow.Form.ClientToScreen(Point(260, 120));
      Started := GetTickCount;
      Closer.Enabled := True;
      try Popup.Popup(FPopupAt.X, FPopupAt.Y); except on E: Exception do S := E.ClassName + ': ' + E.Message; end;
      S := S + Format(' (%d ms, classe %s)', [GetTickCount - Started, Popup.ClassName]);
    finally Closer.Free; end;
    Mine := -1; Times := 0;
    for J := 0 to Popup.Items.Count - 1 do
      if Popup.Items[J].Name = EditorMenuItemName then begin Mine := J; Inc(Times); end;
    Check((Pos('ok', S) = 1) and (Times = 1) and (Mine = Popup.Items.Count - 1), 'Menu de contexto, abertura ' + Tag + ': sem erro, comando uma vez e por ultimo',
      Format('%s | itens=%d | posicao=%d | vezes=%d', [S, Popup.Items.Count, Mine, Times]));
  end;

  function EditorItemCaption: string;
  var J: Integer;
  begin
    Result := '';
    if Popup = nil then Exit;
    for J := 0 to Popup.Items.Count - 1 do
      if Popup.Items[J].Name = EditorMenuItemName then Result := StringReplace(Popup.Items[J].Caption, '&', '', [rfReplaceAll]);
  end;

begin
  FRoot := ExtractFileDir(GetActiveProject.FileName);
  MainItems := (BorlandIDEServices as INTAServices).MainMenu.Items;
  if Supports(BorlandIDEServices, IOTAIDEThemingServices, Theming) then
    Note('INFO | Tema da IDE: ' + Theming.ActiveTheme);
  Options := Default(TUsesOptions);
  Options.Alphabetical := True; Options.OneUnitPerLine := True;
  Options.IndentationEnabled := True; Options.Indentation := '  ';
  Options.AutoSaveUnits := True; Options.BackupUnits := True;
  // A font different from the default proves the preview follows the editor.
  EditOptions := (BorlandIDEServices as IOTAEditorServices).GetEditOptions(cDefEdPascal);
  EditOptions.FontName := 'Courier New'; EditOptions.FontSize := 13;
  OpenInEditor('U_Open1.pas');
  Application.ProcessMessages;
  Workspace := TIDEWorkspace.Create(False);
  Form := TExecutionForm.CreateWorkspace(nil, Workspace, StylerLanguage);
  try
    Shot(Form, 'execucao');
    Preview := Form.PreviewUnattended(Options);
    try
      EditOptions := (BorlandIDEServices as IOTAEditorServices).GetEditOptions(cDefEdPascal);
      Note(Format('INFO | Fonte do editor da IDE: %s %d', [EditOptions.FontName, EditOptions.FontSize]));
      for I := 0 to Preview.ComponentCount - 1 do
        if Preview.Components[I] is TRichEdit then
          Check(SameText(TRichEdit(Preview.Components[I]).Font.Name, EditOptions.FontName) and
            (TRichEdit(Preview.Components[I]).Font.Size = EditOptions.FontSize), 'Previa usa a fonte do editor',
            Format('%s %d', [TRichEdit(Preview.Components[I]).Font.Name, TRichEdit(Preview.Components[I]).Font.Size]));
      Shot(Preview, 'previa');
    finally Preview.Free; end;
  finally Form.Free; end;
  Settings := TSettingsForm.CreateSettings(nil, StylerLanguage, Options, RelativeUnitPaths(Workspace),
    Workspace.SettingsDirectory, True, Workspace.ProjectDirectory);
  try
    TDirectory.CreateDirectory(FRoot + '\.backup\2026-10-10_08-00-00\Vendas');
    TDirectory.CreateDirectory(FRoot + '\.backup\2026-10-11_09-00-00');
    TDirectory.CreateDirectory(FRoot + '\.backup\20261006_1304_do_usuario');
    TFile.WriteAllText(FRoot + '\.backup\2026-10-10_08-00-00\Vendas\uPedidos.pas', 'unit uPedidos;');
    TFile.WriteAllText(FRoot + '\.backup\2026-10-11_09-00-00\uClientes.pas', 'unit uClientes;');
    TFile.WriteAllText(FRoot + '\.backup\20261006_1304_do_usuario\minha.pas', 'unit minha;');
    Shot(Settings, 'configuracoes');
    // Every secondary window of the settings, opened by its own button.
    Settings.Show;
    for I := 0 to Settings.ComponentCount - 1 do
      if (Settings.Components[I] is TButton) and (Pos('btn', Settings.Components[I].Name) = 1) and
        (Settings.Components[I].Name <> 'btnSettingsFolder') then
      begin
        Button := TButton(Settings.Components[I]);
        ShotOfModal('dialogo-' + Copy(Button.Name, 4, MaxInt), procedure begin Button.Click; end);
      end;
    Settings.Hide;
  finally Settings.Free; end;
  Form := TExecutionForm.CreateWorkspace(nil, Workspace, StylerLanguage);
  try
    ShotOfModal('relatorio', procedure
      begin
        Form.ShowReport('U_Comment.pas | Aviso | Comentario no meio do uses: secao uses preservada. (linha 6)' + sLineBreak +
          'U_ReadOnly.pas | Erro | O arquivo e somente leitura. Confira o estado dessa unit.');
      end);
  finally Form.Free; end;
  if StylerLanguage <> slPortuguese then
  begin
    // The menus stay in the language of the settings: only the windows are pictured.
    ShotOfModal('sobre', procedure
      begin
        ShowStylerAbout(StylerLanguage, IncludeTrailingPathDelimiter(Workspace.SettingsDirectory) + 'settings.json');
      end);
    Check(True, 'Capturas das telas geradas em ' + StylerLanguageCodes[StylerLanguage], '');
    Exit;
  end;
  // The key combination: registered in the editor, shown in the menu, and its
  // procedure opens Organize uses. Called through the IDE, no key is sent.
  Item := ToolMenuItem((BorlandIDEServices as INTAServices).MainMenu.Items, L(stOrganize, StylerLanguage) + '...');
  Check((Item <> nil) and (Item.ShortCut = TShortCut(DefaultOrganizeShortcut)), 'Menu mostra Ctrl+Alt+U em Organizar uses',
    ShortCutToText(Item.ShortCut));
  if (BorlandIDEServices as IOTAKeyboardServices).LookupKeyBinding([TShortCut(DefaultOrganizeShortcut)], Binding) then
    ShotOfModal('atalho', procedure
      var Handled: TKeyBindingResult;
      begin
        // The procedure the IDE holds for the combination, called directly:
        // CallKeyBindingProc fails inside the 64-bit IDEs.
        Handled := krUnhandled;
        Binding.KeyProc(nil, TShortCut(DefaultOrganizeShortcut), Handled);
      end)
  else Check(False, 'Ctrl+Alt+U registrado no editor');
  // Context menu of the code editor: opened as the IDE opens it, the command
  // must be there, once, and open Organize uses.
  Popup := nil;
  View := (BorlandIDEServices as IOTAEditorServices).TopView;
  if (View <> nil) and (View.GetEditWindow <> nil) then
    Popup := View.GetEditWindow.Form.FindComponent(EditorPopupName) as TPopupMenu;
  Check(Popup <> nil, 'Menu de contexto do editor encontrado');
  if Popup <> nil then
  begin
    OpenEditorMenu('1'); OpenEditorMenu('2'); OpenEditorMenu('3'); OpenEditorMenu('4');
    Item := nil; Count := 0;
    for I := 0 to Popup.Items.Count - 1 do
      if Popup.Items[I].Name = EditorMenuItemName then begin Item := Popup.Items[I]; Inc(Count); end;
    Check((Count = 1) and (Item.Hint <> ''), 'Menu de contexto tem o comando do Unit Styler, uma vez so',
      Format('%d itens de %d no menu', [Count, Popup.Items.Count]));
    if Item <> nil then
    begin
      Note('INFO | Item do menu de contexto: ' + Item.Caption + ' | itens no menu: ' + IntToStr(Popup.Items.Count));
      ShotOfModal('menu-do-editor', procedure begin Item.Click; end);
    end;
  end;
  // Language picked in the settings window: kept in the settings file, and the
  // menus of the tool follow at once. Then back to Automatic.
  Item := ToolMenuItem(MainItems, L(stSettings, StylerLanguage));
  if Item <> nil then
  begin
    FLanguagePick := Ord(slGerman) + 1;
    ShotOfModal('idioma-para-alemao', procedure begin Item.Click; end);
    Check((StylerLanguage = slGerman) and (SavedLanguage = 'de'), 'Idioma: alemao gravado em language e em uso', SavedLanguage);
    Check(MenuIn(slGerman), 'Idioma: menu do Unit Styler refeito em alemao');
    OpenEditorMenu('em alemao');
    Check(EditorItemCaption = 'Unit Styler: ' + L(stOrganize, slGerman) + '...', 'Idioma: item do menu de contexto do editor em alemao', EditorItemCaption);
    Item := ToolMenuItem(MainItems, L(stSettings, slGerman));
    if Item <> nil then
    begin
      FLanguagePick := 0;
      ShotOfModal('idioma-para-automatico', procedure begin Item.Click; end);
    end;
    Check((StylerLanguage = AutomaticLanguage) and (SavedLanguage = ''), 'Idioma: Automatico gravado e idioma do Windows em uso', SavedLanguage);
    Check(MenuIn(AutomaticLanguage), 'Idioma: menu do Unit Styler de volta ao idioma do Windows');
    OpenEditorMenu('de volta ao idioma do Windows');
    Check(EditorItemCaption = 'Unit Styler: ' + L(stOrganize, AutomaticLanguage) + '...', 'Idioma: item do menu de contexto de volta ao idioma do Windows', EditorItemCaption);
  end;
  // No project open: the menu still opens the settings, project part disabled.
  Workspace := nil;
  FWatchPatience := 3; FWatch.Enabled := True;
  (BorlandIDEServices as IOTAModuleServices).CloseAll;
  Application.ProcessMessages;
  FWatch.Enabled := False;
  Check(GetActiveProject = nil, 'Projeto fechado para o teste sem projeto');
  Item := ToolMenuItem((BorlandIDEServices as INTAServices).MainMenu.Items, L(stSettings, StylerLanguage));
  Check(Item <> nil, 'Menu Unit Styler > Configuracoes encontrado');
  if (GetActiveProject = nil) and (Item <> nil) then
    ShotOfModal('configuracoes-sem-projeto', procedure begin Item.Click; end);
  Item := ToolMenuItem((BorlandIDEServices as INTAServices).MainMenu.Items, 'Sobre...');
  Check(Item <> nil, 'Menu Unit Styler > Sobre encontrado');
  if Item <> nil then ShotOfModal('sobre', procedure begin Item.Click; end);
  Check(True, 'Capturas das telas geradas');
end;

// A real project, opened from a copy: organizes every closed unit on disk and
// compares each file with what the untouched original says it should become.
procedure TSelfTest.RunRealProject;
var Project: IOTAProject; Workspace: IStylerWorkspace; Form: TExecutionForm; Options: TUsesOptions;
  Names: TArray<string>; Name, Relative, Issues, Line: string; Original: TSourceFile; Proposal: TStylerProposal;
  Expected, Actual, Untouched: TBytes; Rewritten, Same, Wrong, Missing, Unreadable, Outside, OpenNow: Integer;
  Errors, Warnings, InEditor: Integer; Started: TDateTime; Lines: TStringList; ShouldChange: Boolean;
  WasOpen: TDictionary<string, string>; BufferBefore, Backup: string; Open: IOTASourceEditor;
  Saved: TBytes; NoCopy: Integer; WithBuild, BuiltBefore: Boolean;

  function Equal(const A, B: TBytes): Boolean;
  begin
    Result := (Length(A) = Length(B)) and ((Length(A) = 0) or CompareMem(@A[0], @B[0], Length(A)));
  end;

begin
  Project := GetActiveProject;
  FRoot := ExcludeTrailingPathDelimiter(GetEnvironmentVariable('CSCODER_STYLER_SELFTEST_ROOT'));
  FOriginals := ExcludeTrailingPathDelimiter(GetEnvironmentVariable('CSCODER_STYLER_SELFTEST_ORIG'));
  Note('INFO | Projeto real ' + Project.FileName);
  Options := Default(TUsesOptions);
  Options.Alphabetical := True; Options.OneUnitPerLine := True;
  Options.IndentationEnabled := True; Options.Indentation := '  ';
  Options.AutoSaveUnits := True; Options.BackupUnits := True;
  if SameText(GetEnvironmentVariable('CSCODER_STYLER_SELFTEST_RULES'), 'groups') then
  begin
    // The order most Delphi code is written in: system units first, own units last.
    Options.GroupingEnabled := True; SetLength(Options.Groups, 4);
    Options.Groups[0].Name := 'Winapi'; Options.Groups[0].Selectors := ['Winapi.*', 'Windows', 'Messages'];
    Options.Groups[1].Name := 'System'; Options.Groups[1].Selectors := ['System.*', 'SysUtils', 'Classes', 'Variants'];
    Options.Groups[2].Name := 'Data'; Options.Groups[2].Selectors := ['Data.*', 'FireDAC.*', 'Datasnap.*', 'DB'];
    Options.Groups[3].Name := 'UI'; Options.Groups[3].Selectors := ['Vcl.*', 'FMX.*', 'Graphics', 'Controls', 'Forms', 'Dialogs'];
    Options.UngroupedPosition := upLast;
    Note('INFO | Regras: grupos Winapi, System, Data, Vcl/FMX, demais; A-Z dentro de cada grupo');
  end
  else if SameText(GetEnvironmentVariable('CSCODER_STYLER_SELFTEST_RULES'), 'first') then
  begin
    Options.SortFirstNameOnly := True;
    Note('INFO | Regras: A-Z so pelo primeiro nome');
  end
  else if SameText(GetEnvironmentVariable('CSCODER_STYLER_SELFTEST_RULES'), 'protected') then
  begin
    // System units stay where they are; everything else is sorted by the whole name.
    Options.ProtectedUnits := DefaultProtectedUnits;
    Note('INFO | Regras: A-Z pelo nome completo, lista de fabrica de units protegidas');
  end
  else Note('INFO | Regras: A-Z pelo nome completo');
  Workspace := TIDEWorkspace.Create(False);
  Names := Workspace.UnitNames;
  Note('INFO | Units do projeto: ' + IntToStr(Length(Names)));
  Check(Length(Names) > 0, 'Projeto real lista suas units');
  // Safety: a unit outside the copied folder would be a real file of the user.
  Outside := 0;
  for Name in Names do
    if not SameText(Copy(Name, 1, Length(FRoot) + 1), FRoot + '\') then Inc(Outside);
  Check(Outside = 0, 'Todas as units ficam dentro da copia de teste', IntToStr(Outside) + ' fora');
  if Outside > 0 then Exit;

  // The IDE may open units by itself when loading the project. Those follow
  // the rule for open units: changed in the editor, never written to disk.
  WasOpen := TDictionary<string, string>.Create;
  for Name in Names do
  begin
    Open := SourceEditorOf((BorlandIDEServices as IOTAModuleServices).FindModule(Name));
    if Open <> nil then WasOpen.Add(Name, ReadEditor(Open));
  end;
  Note('INFO | Units que a IDE ja tinha abertas: ' + IntToStr(WasOpen.Count));
  // With the user's own components available: the untouched copy is built
  // first, so a failure afterwards can only come from the batch.
  WithBuild := GetEnvironmentVariable('CSCODER_STYLER_SELFTEST_BUILD') = '1';
  BuiltBefore := False;
  if WithBuild then
  begin
    Started := Now;
    BuiltBefore := Project.ProjectBuilder.BuildProject(cmOTABuild, True, True);
    Note(Format('INFO | Compilacao antes do lote: %s (%d s)', [BoolToStr(BuiltBefore, True), Round((Now - Started) * 86400)]));
    // A failed build makes the IDE open the unit with the error: count again.
    WasOpen.Clear;
    for Name in Names do
    begin
      Open := SourceEditorOf((BorlandIDEServices as IOTAModuleServices).FindModule(Name));
      if Open <> nil then WasOpen.Add(Name, ReadEditor(Open));
    end;
    Note('INFO | Units abertas depois da compilacao inicial: ' + IntToStr(WasOpen.Count));
  end;
  Form := TExecutionForm.CreateWorkspace(nil, Workspace, StylerLanguage);
  try
    Started := Now;
    Issues := Form.RunUnattended(Options, 2, True);
    Note(Format('INFO | Lote levou %d ms | %s', [Round((Now - Started) * 86400000), Form.StatusText]));
    Errors := 0; Warnings := 0;
    Lines := TStringList.Create;
    try
      Lines.Text := Issues;
      for Line in Lines do
        if Pos(' | Erro | ', Line) > 0 then
        begin Inc(Errors); Note('INFO | ' + Line); end
        else if Pos(' | Aviso | ', Line) > 0 then Inc(Warnings);
    finally Lines.Free; end;
    Note(Format('INFO | Relatorio: %d erros, %d avisos', [Errors, Warnings]));

    Backup := Workspace.BackupDirectory;
    Note('INFO | Backup do lote: ' + Backup);
    Rewritten := 0; Same := 0; Wrong := 0; Missing := 0; Unreadable := 0; OpenNow := 0; InEditor := 0; NoCopy := 0;
    for Name in Names do
    begin
      Relative := Copy(Name, Length(FRoot) + 2, MaxInt);
      if not TFile.Exists(Name) then begin Inc(Missing); Continue; end;
      Open := SourceEditorOf((BorlandIDEServices as IOTAModuleServices).FindModule(Name));
      Untouched := TFile.ReadAllBytes(TPath.Combine(FOriginals, Relative));
      Actual := TFile.ReadAllBytes(Name);
      if WasOpen.TryGetValue(Name, BufferBefore) then
      begin
        if (Open <> nil) and Equal(Actual, Untouched) and
          (ReadEditor(Open) = AnalyzeUses(BufferBefore, Options).ApplyTo(BufferBefore)) then
        begin
          Inc(InEditor);
          if (ReadEditor(Open) <> BufferBefore) and
            not (ReadLong(TPath.Combine(Backup, Relative), Saved) and Equal(Saved, Untouched)) then Inc(NoCopy);
        end
        else
        begin
          Inc(Wrong);
          Note('INFO | Unit aberta fora do esperado: ' + Relative);
        end;
        Continue;
      end;
      if Open <> nil then Inc(OpenNow);
      ShouldChange := False;
      try
        Original := LoadSourceFile(TPath.Combine(FOriginals, Relative));
        Proposal := AnalyzeUses(Original.Text, Options);
        ShouldChange := Length(Proposal.Edits) > 0;
        if ShouldChange then Expected := EncodeSource(Proposal.ApplyTo(Original.Text), Original.Encoding);
      except
        on E: ESourceEncoding do Inc(Unreadable);
      end;
      if ShouldChange and Equal(Actual, Expected) then
      begin
        Inc(Rewritten);
        if not (ReadLong(TPath.Combine(Backup, Relative), Saved) and Equal(Saved, Untouched)) then
        begin
          Inc(NoCopy);
          if NoCopy <= 10 then Note('INFO | Sem copia fiel no backup: ' + Relative);
        end;
      end
      else if not ShouldChange and ReadLong(TPath.Combine(Backup, Relative), Saved) then
      begin
        Inc(Wrong);
        Note('INFO | Backup de unit que nao mudou: ' + Relative);
      end
      else if not ShouldChange and Equal(Actual, Untouched) then Inc(Same)
      else
      begin
        Inc(Wrong);
        if Wrong <= 10 then Note('INFO | Diferente do esperado: ' + Relative);
      end;
    end;
    Note(Format('INFO | Regravadas como esperado: %d | intactas como esperado: %d | abertas, alteradas so no editor: %d | codificacao recusada: %d | arquivo ausente: %d',
      [Rewritten, Same, InEditor, Unreadable, Missing]));
    Check(Wrong = 0, 'Cada unit ficou exatamente como o original manda', IntToStr(Wrong) + ' diferentes');
    Check(Rewritten > 0, 'O lote alterou units do projeto real');
    Check(NoCopy = 0, 'Cada unit alterada tem no backup os bytes originais', IntToStr(NoCopy) + ' sem copia fiel');
    if WithBuild then
    begin
      if BuiltBefore then
      begin
        Started := Now;
        Check(Project.ProjectBuilder.BuildProject(cmOTABuild, True, True), 'Projeto real compila depois do lote, como compilava antes');
        Note(Format('INFO | Compilacao depois do lote levou %d s', [Round((Now - Started) * 86400)]));
      end
      else Note('INFO | O projeto original nao compila neste ambiente; a compilacao depois do lote nao pode ser avaliada.');
    end;
    Check(OpenNow = 0, 'Nenhuma unit foi aberta no Delphi pelo lote', IntToStr(OpenNow));

    Issues := Form.RunUnattended(Options, 2, True);
    Wrong := 0;
    for Name in Names do
      if TFile.Exists(Name) and not WasOpen.ContainsKey(Name) then
      begin
        Relative := Copy(Name, Length(FRoot) + 2, MaxInt);
        try
          Original := LoadSourceFile(Name);
          if Length(AnalyzeUses(Original.Text, Options).Edits) > 0 then Inc(Wrong);
        except
          on E: ESourceEncoding do ;
        end;
      end;
    Check(Wrong = 0, 'Segundo lote nao tem mais nada a mudar', IntToStr(Wrong));
  finally
    Form.Free; WasOpen.Free;
  end;
end;

procedure Register;var ReportFile: string;
begin
  ReportFile := GetEnvironmentVariable('CSCODER_STYLER_SELFTEST');
  if (ReportFile <> '') and (SelfTest = nil) then SelfTest := TSelfTest.Create(ReportFile);
end;

initialization

finalization
  FreeAndNil(SelfTest);

end.
