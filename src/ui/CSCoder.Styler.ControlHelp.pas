unit CSCoder.Styler.ControlHelp;

interface

uses Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Themes, CSCoder.Styler.Strings;

type
  // Secondary windows of the tool: a class of their own lets the host theme them.
  TStylerDialog = class(TForm);

var
  // Set by the IDE integration; nil in the demonstration, which keeps system colors.
  HostThemeForm: procedure(Form: TCustomForm);
  HostStyle: function: TCustomStyleServices;
  // Fills in the font of the host's code editor, so source shown by the tool
  // looks like the editor. Unassigned, the font given by the caller is kept.
  HostEditorFont: procedure(Font: TFont);

procedure Explain(Control: TControl; const Text: string);
function RuleHelp(Id: TStylerText): string;
// Gives the window the light or dark theme of the host, when there is one.
procedure ApplyHostTheme(Form: TCustomForm);
// Colors for source text shown by the tool, following the active theme.
procedure SourceColors(out Back, Text, Removed, Added: TColor);
// Font for source text: the host editor's font, or Consolas 11 without a host.
procedure SourceFont(Font: TFont);

implementation

type TExplainedControl = class(TControl);

procedure Explain(Control: TControl; const Text: string);
begin
  Control.Hint := Text;
  TExplainedControl(Control).ParentShowHint := False;
  TExplainedControl(Control).ShowHint := True;
end;

procedure ApplyHostTheme(Form: TCustomForm);
begin
  if Assigned(HostThemeForm) then HostThemeForm(Form);
end;

procedure SourceFont(Font: TFont);
begin
  Font.Name := 'Consolas'; Font.Size := 11;
  if Assigned(HostEditorFont) then HostEditorFont(Font);
end;

procedure SourceColors(out Back, Text, Removed, Added: TColor);
var Services: TCustomStyleServices; Value: Integer;
begin
  Services := nil;
  if Assigned(HostStyle) then Services := HostStyle;
  if Services = nil then Services := StyleServices;
  Back := Services.GetSystemColor(clWindow);
  Text := Services.GetSystemColor(clWindowText);
  Value := ColorToRGB(Back);
  // Perceived brightness of the background decides which highlights are legible.
  if ((Value and $FF) * 299 + ((Value shr 8) and $FF) * 587 + ((Value shr 16) and $FF) * 114) div 1000 < 128 then
  begin
    Removed := TColor($002C2C68); Added := TColor($00345824);
  end
  else
  begin
    Removed := TColor($00E8E8FF); Added := TColor($00E9F5E6);
  end;
end;

function RuleHelp(Id: TStylerText): string;
begin
  case Id of
    stOnePerLine: Result := L(stHlpOnePerLine);
    stWrapUnits: Result := L(stHlpWrapUnits);
    stColumns: Result := L(stHlpColumns);
    stAlphabetical: Result := L(stHlpAlphabetical);
    stAlphabeticalFull: Result := L(stHlpAlphabeticalFull);
    stIndent: Result := L(stHlpIndent);
    stSpaces: Result := L(stHlpSpaces);
    stPriorities: Result := L(stHlpPriorities);
    stPriorityNames: Result := L(stHlpPriorityNames);
    stGroups: Result := L(stHlpGroups);
    stBlankGroups: Result := L(stHlpBlankGroups);
    stBlankBeforeSections: Result := L(stHlpBlankBefore);
    stBlankAfterSections: Result := L(stHlpBlankAfter);
    stCurrentScope: Result := L(stHlpCurrentScope);
    stOpenScope: Result := L(stHlpOpenScope);
    stAllScope: Result := L(stHlpAllScope);
    stViewPreview: Result := L(stHlpViewPreview);
    stApply: Result := L(stHlpApply);
    stSettings: Result := L(stHlpSettings);
    stClose: Result := L(stHlpClose);
    else Result := '';
  end;
end;

end.
