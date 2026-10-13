unit CSCoder.Styler.About;

// The "About" window, with the same layout as the one of the CS.Coder Hub.
// It has no IDE dependency: colors and theming come from ControlHelp.

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Types, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Menus, CSCoder.Styler.Strings;

type
  TStylerAboutGlyph = record
    Bounds: TRect;
    Text: string;
    Height: Integer;
    Color: TColor;
  end;

  TStylerAboutForm = class(TForm)
  private
    FDataFile: string;
    FLanguage: TStylerLanguage;
    FBackColor, FTextColor, FDim, FLine, FAccent, FTile: TColor;
    FSemibold: Boolean;
    FGlyphFont: string;
    FBack: TPaintBox;
    FDataMenu: TPopupMenu;
    FIcon: TWICImage;
    FLicense: string;
    FIconRect, FBoxRect, FTileRect: TRect;
    FRules: TArray<TRect>;
    FGlyphs: TArray<TStylerAboutGlyph>;
    function P(Value: Integer): Integer;
    function NewLabel(const Text: string; X, Y, Height: Integer; Color: TColor;
      Semibold: Boolean = False; Width: Integer = 0): TLabel;
    function NewLink(const Text, Url: string; X, Y: Integer): TLabel;
    function NewButton(const Text, Help: string; X, Y, Width: Integer; Click: TNotifyEvent): TButton;
    procedure AddRule(const R: TRect);
    procedure AddGlyph(const Glyph: string; const R: TRect; Height: Integer; Color: TColor);
    procedure Build;
    procedure BackPaint(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure LinkClick(Sender: TObject);
    procedure LinkEnter(Sender: TObject);
    procedure LinkLeave(Sender: TObject);
    procedure LicenseClick(Sender: TObject);
    procedure SiteClick(Sender: TObject);
    procedure DataClick(Sender: TObject);
    procedure CopyPathClick(Sender: TObject);
    procedure OpenFolderClick(Sender: TObject);
  public
    // DataFile: the add-on settings file, shown with its folder one click away.
    constructor CreateAbout(Owner: TComponent; Language: TStylerLanguage; const DataFile: string);
    destructor Destroy; override;
  end;

const
  StylerProduct = 'Unit Styler';
  // Used while the package carries no version resource of its own.
  StylerVersion = '0.26.10.12d';
  StylerDeveloper = 'CS.Coder';
  StylerSiteUrl = 'https://www.cscoder.com.br';
  StylerSiteText = 'www.cscoder.com.br';
  // The tool has no repository of its own yet: support goes through the company site.
  StylerSupportUrl = StylerSiteUrl;
  StylerMail = 'contato@cscoder.com.br';
  // Where problems are reported: the issues of the public repository.
  StylerIssuesUrl = 'https://github.com/cscoder69/delphi-unit-styler/issues';

procedure ShowStylerAbout(Language: TStylerLanguage; const DataFile: string);

implementation

// Icon and license texts (CSCoder.Styler.About.rc), compiled by the build scripts.
{$R 'CSCoder.Styler.About.res'}

uses Winapi.ShellAPI, System.Math, System.IOUtils, Vcl.Themes, Vcl.Clipbrd, CSCoder.Styler.ControlHelp;

const
  FontName = 'Segoe UI';
  SemiboldName = 'Segoe UI Semibold';
  Compatibility = 'Delphi 11, 12, 13';
  IconResource = 'CSSTYLERICON';
  LicenseResource = 'CSSTYLERLICENSE';   // LICENSE.txt, the text that counts
  SummaryResource = 'CSSTYLERLICENCA';   // LICENCA.txt, the summary in Portuguese

function ResourceText(const Name: string): string;
var Stream: TResourceStream; Lines: TStringList;
begin
  Result := '';
  if FindResource(HInstance, PChar(Name), RT_RCDATA) = 0 then Exit;
  Stream := TResourceStream.Create(HInstance, Name, RT_RCDATA);
  Lines := TStringList.Create;
  try
    Lines.LoadFromStream(Stream, TEncoding.UTF8);
    Result := Lines.Text;
  finally Lines.Free; Stream.Free; end;
end;

function MixColor(A, B: TColor; PercentA: Integer): TColor;
var CA, CB: Cardinal;

  function Mix(ShiftBits: Integer): Cardinal;
  begin
    Result := ((((CA shr ShiftBits) and $FF) * Cardinal(PercentA) +
      ((CB shr ShiftBits) and $FF) * Cardinal(100 - PercentA)) div 100) shl ShiftBits;
  end;

begin
  CA := Cardinal(ColorToRGB(A)); CB := Cardinal(ColorToRGB(B));
  Result := TColor(Mix(0) or Mix(8) or Mix(16));
end;

// Both read from the package file itself, so the window never disagrees with it:
// the ProductVersion text of its version resource (it may end in a letter, which
// the four numbers cannot hold), and the day it was built.
procedure PackageVersion(out Version, Build: string);
type
  TTranslation = packed record
    Language, CodePage: Word;
  end;
var FileName: array[0..MAX_PATH] of Char;
  Size, Dummy, Len: DWORD;
  Buffer: TBytes;
  Info: PVSFixedFileInfo;
  Translation: ^TTranslation;
  Text: PChar;
begin
  Version := StylerVersion;
  Build := '';
  if GetModuleFileName(HInstance, FileName, Length(FileName)) = 0 then Exit;
  try
    Build := FormatDateTime('yyyymmdd', TFile.GetLastWriteTime(FileName));
  except
    // no date, no build line content
  end;
  Size := GetFileVersionInfoSize(FileName, Dummy);
  if Size = 0 then Exit;
  SetLength(Buffer, Size);
  if not GetFileVersionInfo(FileName, 0, Size, Buffer) then Exit;
  if VerQueryValue(Buffer, '\VarFileInfo\Translation', Pointer(Translation), Len) and (Len >= SizeOf(TTranslation)) and
    VerQueryValue(Buffer, PChar(Format('\StringFileInfo\%.4x%.4x\ProductVersion',
      [Translation.Language, Translation.CodePage])), Pointer(Text), Len) and (Len > 0) and (Trim(Text) <> '') then
  begin
    Version := Trim(Text);
    Exit;
  end;
  if not VerQueryValue(Buffer, '\', Pointer(Info), Len) then Exit;
  Version := Format('%d.%d.%d.%d', [HiWord(Info.dwFileVersionMS), LoWord(Info.dwFileVersionMS),
    HiWord(Info.dwFileVersionLS), LoWord(Info.dwFileVersionLS)]);
end;

procedure OpenUrl(const Url: string);
begin
  ShellExecute(0, 'open', PChar(Url), nil, nil, SW_SHOWNORMAL);
end;

procedure ShowStylerAbout(Language: TStylerLanguage; const DataFile: string);
var Form: TStylerAboutForm;
begin
  Form := TStylerAboutForm.CreateAbout(nil, Language, DataFile);
  try
    ApplyHostTheme(Form);
    Form.ShowModal;
  finally Form.Free; end;
end;

constructor TStylerAboutForm.CreateAbout(Owner: TComponent; Language: TStylerLanguage; const DataFile: string);
var Services: TCustomStyleServices;
begin
  inherited CreateNew(Owner);
  FDataFile := DataFile; FLanguage := Language;
  Services := nil;
  if Assigned(HostStyle) then Services := HostStyle;
  if Services = nil then Services := StyleServices;
  FBackColor := Services.GetSystemColor(clBtnFace);
  FTextColor := Services.GetSystemColor(clWindowText);
  // Every other color comes from these and the highlight color of the theme.
  FDim := MixColor(FTextColor, FBackColor, 60);
  FLine := MixColor(FTextColor, FBackColor, 18);
  // The highlight color alone can be too close to the background: pull it toward the text.
  FAccent := MixColor(Services.GetSystemColor(clHighlight), FTextColor, 65);
  FTile := MixColor(Services.GetSystemColor(clHighlight), FBackColor, 30);
  FSemibold := Screen.Fonts.IndexOf(SemiboldName) >= 0;
  if Screen.Fonts.IndexOf('Segoe Fluent Icons') >= 0 then FGlyphFont := 'Segoe Fluent Icons'
  else if Screen.Fonts.IndexOf('Segoe MDL2 Assets') >= 0 then FGlyphFont := 'Segoe MDL2 Assets';
  FIcon := TWICImage.Create;
  Build;
end;

destructor TStylerAboutForm.Destroy;
begin
  inherited;
  FIcon.Free;
end;

function TStylerAboutForm.P(Value: Integer): Integer;
begin
  Result := MulDiv(Value, CurrentPPI, 96);
end;

// Positions and sizes arrive already scaled. Width > 0 wraps the text in that width.
function TStylerAboutForm.NewLabel(const Text: string; X, Y, Height: Integer; Color: TColor;
  Semibold: Boolean; Width: Integer): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := Self;
  Result.ShowAccelChar := False;
  Result.Transparent := True;
  // Our own colors, not the font color of the style.
  Result.StyleElements := Result.StyleElements - [seFont];
  Result.Font.Name := FontName;
  if Semibold then
    if FSemibold then Result.Font.Name := SemiboldName else Result.Font.Style := [fsBold];
  Result.Font.Height := -Height;
  Result.Font.Color := Color;
  Result.Left := X;
  Result.Top := Y;
  if Width > 0 then
  begin
    // Width first, with auto-size off: an empty auto-sized label collapses and
    // would then wrap the text in almost no width.
    Result.AutoSize := False;
    Result.Width := Width;
    Result.WordWrap := True;
    Result.Caption := Text;
    Result.AutoSize := True; // now only the height follows the text
  end
  else Result.Caption := Text;
end;

function TStylerAboutForm.NewLink(const Text, Url: string; X, Y: Integer): TLabel;
begin
  Result := NewLabel(Text, X, Y, P(13), FAccent);
  Result.Cursor := crHandPoint;
  Explain(Result, Url); // where it goes, shown on hover and used by the click
  Result.OnClick := LinkClick;
  Result.OnMouseEnter := LinkEnter;
  Result.OnMouseLeave := LinkLeave;
end;

function TStylerAboutForm.NewButton(const Text, Help: string; X, Y, Width: Integer; Click: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := Self;
  Result.SetBounds(X, Y, Width, P(34));
  Result.Font.Name := FontName;
  Result.Font.Height := -P(13);
  Result.Caption := Text;
  Result.OnClick := Click;
  Explain(Result, Help);
end;

procedure TStylerAboutForm.AddRule(const R: TRect);
begin
  FRules := FRules + [R];
end;

procedure TStylerAboutForm.AddGlyph(const Glyph: string; const R: TRect; Height: Integer; Color: TColor);
var G: TStylerAboutGlyph;
begin
  G.Bounds := R; G.Text := Glyph; G.Height := Height; G.Color := Color;
  FGlyphs := FGlyphs + [G];
end;

procedure TStylerAboutForm.Build;
const
  ClientW = 820;
  FeatureGlyphs: array[0..3] of string = (#$E8B7, #$E890, #$E713, #$E943);
  FeatureTitles: array[0..3] of TStylerText = (stFeatOrgTitle, stFeatControlTitle, stFeatProdTitle, stFeatDelphiTitle);
  FeatureTexts: array[0..3] of TStylerText = (stFeatOrgText, stFeatControlText, stFeatProdText, stFeatDelphiText);
  LinkGlyphs: array[0..3] of string = (#$E774, #$E715, #$E897, #$EBE8);
  RowPitch = 28;
var Lbl: TLabel; Btn: TButton; Stream: TResourceStream;
  Version, BuildNo: string;
  X, Y, I, LeftEnd, TopEnd, ColumnW: Integer;

  function T(Id: TStylerText): string;
  begin Result := L(Id, FLanguage); end;

  procedure Row(LabelX, ValueX, ValueW: Integer; const Text, Value: string);
  var ValueLabel: TLabel;
  begin
    NewLabel(Text, LabelX, Y, P(13), FDim);
    ValueLabel := NewLabel(Value, ValueX, Y, P(13), FTextColor);
    if ValueLabel.Width > ValueW then
    begin
      // A long translation: cut it at the end, whole text in the hint.
      ValueLabel.AutoSize := False;
      ValueLabel.Width := ValueW;
      ValueLabel.EllipsisPosition := epEndEllipsis;
      Explain(ValueLabel, Value);
    end;
    Inc(Y, P(RowPitch));
  end;

  procedure NewMenuItem(const Text: string; Click: TNotifyEvent);
  var Item: TMenuItem;
  begin
    Item := TMenuItem.Create(FDataMenu);
    Item.Caption := Text;
    Item.OnClick := Click;
    FDataMenu.Items.Add(Item);
  end;

begin
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  Caption := T(stAbout);
  Color := FBackColor;
  Font.Name := FontName;
  KeyPreview := True;
  OnKeyPress := FormKeyPress;
  ClientWidth := P(ClientW);

  // Rules, the license frame, the icon and the glyphs are painted here, under the labels.
  FBack := TPaintBox.Create(Self);
  FBack.Parent := Self;
  FBack.Align := alClient;
  FBack.OnPaint := BackPaint;

  if FindResource(HInstance, IconResource, RT_RCDATA) <> 0 then
  begin
    Stream := TResourceStream.Create(HInstance, IconResource, RT_RCDATA);
    try
      FIcon.LoadFromStream(Stream);
      FIcon.InterpolationMode := wipmHighQualityCubic;
    finally Stream.Free; end;
  end;
  FLicense := ResourceText(LicenseResource);
  if (FLicense <> '') and (FLanguage = slPortuguese) and (ResourceText(SummaryResource) <> '') then
    FLicense := ResourceText(SummaryResource) + sLineBreak + StringOfChar('-', 60) + sLineBreak + sLineBreak + FLicense;
  PackageVersion(Version, BuildNo);

  { Left: the product }
  FIconRect := Rect(P(24), P(24), P(120), P(120));
  NewLabel(StylerProduct, P(140), P(22), P(28), FTextColor, True);
  Lbl := NewLabel(T(stAboutBy), P(140), P(62), P(15), FDim);
  NewLabel(StylerDeveloper, Lbl.BoundsRect.Right + P(5), P(62), P(15), FTextColor);
  Lbl := NewLabel(T(stAboutTagline), P(140), P(88), P(13), FDim, False, P(300));
  Y := Max(P(142), Lbl.BoundsRect.Bottom + P(14));
  AddRule(Rect(P(24), Y, P(440), Y + 1));
  Inc(Y, P(14));
  Row(P(24), P(170), P(270), T(stAboutVersion), Version);
  Row(P(24), P(170), P(270), T(stAboutBuild), BuildNo);
  Row(P(24), P(170), P(270), T(stAboutCompat), Compatibility);
  // Only the file name shows; the whole path is in the hint, and a click (either
  // button) offers to copy it or to open its folder.
  NewLabel(T(stAboutDataFile), P(24), Y, P(13), FDim);
  FDataMenu := TPopupMenu.Create(Self);
  FDataMenu.AutoHotkeys := maManual;
  NewMenuItem(T(stAboutCopyPath), CopyPathClick);
  NewMenuItem(T(stAboutOpenFolder), OpenFolderClick);
  Lbl := NewLink(ExtractFileName(FDataFile), FDataFile, P(170), Y);
  Lbl.OnClick := DataClick;
  Lbl.PopupMenu := FDataMenu;
  LeftEnd := Y + P(RowPitch);

  { Right: the license }
  FBoxRect := Rect(P(476), P(24), P(796), P(210));
  FTileRect := Rect(P(492), P(40), P(528), P(76));
  AddGlyph(#$E73E, FTileRect, P(18), FAccent);
  NewLabel(T(stAboutLicFree), P(540), P(38), P(15), FTextColor, True);
  NewLabel(T(stAboutLicSub), P(540), P(60), P(12), FDim);
  AddRule(Rect(P(492), P(90), P(780), P(90) + 1));
  Y := P(100);
  Row(P(492), P(640), P(140), T(stAboutLicType), T(stAboutLicTypeValue));
  Row(P(492), P(640), P(140), T(stAboutLicCommercial), T(stAboutAllowed));
  Row(P(492), P(640), P(140), T(stAboutLicSource), T(stAboutSourceOpen));
  Row(P(492), P(640), P(140), T(stAboutLicData), T(stAboutNone));
  // Side by side under the frame, short captions; the hints say what each one does.
  Btn := NewButton(T(stAboutLicenseTitle), T(stAboutLicenseDetails), P(476), P(222), P(154), LicenseClick);
  Btn.Enabled := FLicense <> '';
  NewButton(T(stAboutUpdates), T(stAboutCheckUpdates), P(642), P(222), P(154), SiteClick);

  TopEnd := Max(LeftEnd, P(256)) + P(20);
  AddRule(Rect(P(458), P(24), P(458) + 1, TopEnd - P(20)));
  AddRule(Rect(P(24), TopEnd, P(796), TopEnd + 1));

  { What it does }
  Y := TopEnd + P(18);
  ColumnW := (P(ClientW) - 2 * P(24)) div 4;
  for I := 0 to 3 do
  begin
    X := P(24) + I * ColumnW;
    AddGlyph(FeatureGlyphs[I], Rect(X, Y, X + P(32), Y + P(36)), P(24), FAccent);
    NewLabel(T(FeatureTitles[I]), X + P(44), Y, P(13), FTextColor, True);
    NewLabel(T(FeatureTexts[I]), X + P(44), Y + P(20), P(12), FDim, False, ColumnW - P(52));
  end;
  Inc(Y, P(58));
  AddRule(Rect(P(24), Y, P(796), Y + 1));

  { Who makes it }
  Inc(Y, P(18));
  NewLabel(StylerDeveloper, P(24), Y, P(26), FTextColor, True);
  NewLabel(T(stAboutSlogan), P(25), Y + P(40), P(10), FDim);
  for I := 0 to 3 do
    AddGlyph(LinkGlyphs[I], Rect(P(300), Y + I * P(24), P(320), Y + I * P(24) + P(20)), P(14), FAccent);
  NewLink(StylerSiteText, StylerSiteUrl, P(328), Y + P(1));
  NewLink(StylerMail, 'mailto:' + StylerMail, P(328), Y + P(25));
  NewLink(T(stAboutSupport), StylerSupportUrl, P(328), Y + P(49));
  NewLink(T(stAboutReport), StylerIssuesUrl, P(328), Y + P(73));
  AddRule(Rect(P(560), Y, P(560) + 1, Y + P(92)));
  NewLabel(Format(T(stAboutRights), [StylerProduct, StylerDeveloper]), P(580), Y + P(14), P(12), FDim, False, P(216));
  ClientHeight := Y + P(96) + P(20);
end;

procedure TStylerAboutForm.BackPaint(Sender: TObject);
var C: TCanvas; R: TRect; G: TStylerAboutGlyph;
begin
  C := FBack.Canvas;
  C.Brush.Style := bsSolid;
  C.Brush.Color := FLine;
  for R in FRules do C.FillRect(R);

  C.Pen.Width := 1;
  C.Pen.Color := FLine;
  C.Brush.Style := bsClear;
  C.RoundRect(FBoxRect.Left, FBoxRect.Top, FBoxRect.Right, FBoxRect.Bottom, P(10), P(10));
  C.Pen.Color := FTile;
  C.Brush.Style := bsSolid;
  C.Brush.Color := FTile;
  C.RoundRect(FTileRect.Left, FTileRect.Top, FTileRect.Right, FTileRect.Bottom, P(8), P(8));

  if not FIcon.Empty then C.StretchDraw(FIconRect, FIcon);

  if FGlyphFont = '' then Exit;
  C.Brush.Style := bsClear;
  C.Font.Name := FGlyphFont;
  C.Font.Style := [];
  for G in FGlyphs do
  begin
    C.Font.Height := -G.Height;
    C.Font.Color := G.Color;
    R := G.Bounds;
    DrawText(C.Handle, PChar(G.Text), Length(G.Text), R,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
  end;
end;

procedure TStylerAboutForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #27 then
  begin
    Key := #0;
    ModalResult := mrCancel;
  end;
end;

procedure TStylerAboutForm.LinkClick(Sender: TObject);
begin
  OpenUrl((Sender as TLabel).Hint);
end;

procedure TStylerAboutForm.LinkEnter(Sender: TObject);
begin
  (Sender as TLabel).Font.Style := [fsUnderline];
end;

procedure TStylerAboutForm.LinkLeave(Sender: TObject);
begin
  (Sender as TLabel).Font.Style := [];
end;

// There is nowhere to ask for the latest version and the tool never goes online
// by itself: the user's browser opens the site instead.
procedure TStylerAboutForm.SiteClick(Sender: TObject);
begin
  OpenUrl(StylerSiteUrl);
end;

procedure TStylerAboutForm.LicenseClick(Sender: TObject);
var Form: TStylerDialog; Bottom: TPanel; Button: TButton; Memo: TMemo;
begin
  Form := TStylerDialog.CreateNew(Self);
  try
    Form.BorderStyle := bsDialog;
    Form.Position := poOwnerFormCenter;
    Form.Caption := L(stAboutLicenseDetails, FLanguage);
    Form.Font.Name := FontName;
    Form.ClientWidth := P(640);
    Form.ClientHeight := P(480);

    Bottom := TPanel.Create(Form);
    Bottom.Parent := Form;
    Bottom.Align := alBottom;
    Bottom.Height := P(58);
    Bottom.BevelOuter := bvNone;
    Bottom.ShowCaption := False;
    Button := TButton.Create(Form);
    Button.Parent := Bottom;
    Button.Width := P(96);
    Button.AlignWithMargins := True;
    Button.Margins.SetBounds(0, P(12), P(16), P(14));
    Button.Align := alRight;
    Button.Caption := L(stClose, FLanguage);
    Button.Default := True;
    Button.Cancel := True;
    Button.ModalResult := mrOk;
    Explain(Button, L(stAboutLicenseCloseHint, FLanguage));

    Memo := TMemo.Create(Form);
    Memo.Parent := Form;
    Memo.AlignWithMargins := True;
    Memo.Margins.SetBounds(P(16), P(16), P(16), 0);
    Memo.Align := alClient;
    Memo.ReadOnly := True;
    Memo.ScrollBars := ssVertical;
    Memo.Font.Height := -P(13);
    Memo.Lines.Text := FLicense;
    Explain(Memo, L(stAboutLicenseDetails, FLanguage));

    ApplyHostTheme(Form);
    Form.ActiveControl := Button;
    Form.ShowModal;
  finally Form.Free; end;
end;

procedure TStylerAboutForm.DataClick(Sender: TObject);
begin
  FDataMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
end;

procedure TStylerAboutForm.CopyPathClick(Sender: TObject);
begin
  Clipboard.AsText := FDataFile;
end;

// The file only exists after the first save: fall back to its folder, and to
// the nearest one that does exist.
procedure TStylerAboutForm.OpenFolderClick(Sender: TObject);
var Dir, Params: string;
begin
  if TFile.Exists(FDataFile) then Params := '/select,"' + FDataFile + '"'
  else
  begin
    Dir := TPath.GetDirectoryName(FDataFile);
    while (Dir <> '') and not TDirectory.Exists(Dir) do Dir := TPath.GetDirectoryName(Dir);
    if Dir = '' then Exit;
    Params := '"' + Dir + '"';
  end;
  ShellExecute(0, 'open', 'explorer.exe', PChar(Params), nil, SW_SHOWNORMAL);
end;

end.
