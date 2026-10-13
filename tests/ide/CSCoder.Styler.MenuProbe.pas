unit CSCoder.Styler.MenuProbe;

// Test only. Loaded beside the installed Unit Styler package, in an isolated
// IDE profile, by installer-test.ps1: it reports whether the IDE loaded that
// package and whether its menu is there. It holds no unit of the product.

interface

procedure Register;

implementation

uses System.SysUtils, System.Classes, Winapi.Windows, Vcl.Menus, Vcl.ExtCtrls, ToolsAPI;

type
  TMenuProbe = class
  private
    FTimer: TTimer;
    FTicks: Integer;
    FReport: string;
    procedure Tick(Sender: TObject);
  public
    constructor Create(const Report: string);
    destructor Destroy; override;
  end;

var Probe: TMenuProbe;

function Plain(const Caption: string): string;
begin
  Result := StringReplace(Caption, '&', '', [rfReplaceAll]);
end;

function Child(Parent: TMenuItem; const Caption: string): TMenuItem;
var I: Integer;
begin
  for I := 0 to Parent.Count - 1 do
    if SameText(Plain(Parent[I].Caption), Caption) then Exit(Parent[I]);
  Result := nil;
end;

constructor TMenuProbe.Create(const Report: string);
begin
  inherited Create;
  FReport := Report;
  FTimer := TTimer.Create(nil);
  FTimer.Interval := 1000; FTimer.OnTimer := Tick; FTimer.Enabled := True;
end;

destructor TMenuProbe.Destroy;
begin
  FTimer.Free;
  inherited;
end;

procedure TMenuProbe.Tick(Sender: TObject);
const Tags: array[0..2] of string = ('D11', 'D12', 'D13');
var Services: INTAServices; Root, Branch: TMenuItem; Lines: TStringList; I: Integer;
  Module: HMODULE; Name: array[0..MAX_PATH] of Char; Items: string;
begin
  Inc(FTicks);
  Root := nil; Branch := nil;
  if Supports(BorlandIDEServices, INTAServices, Services) and (Services.MainMenu <> nil) then
  begin
    Root := Child(Services.MainMenu.Items, 'CS.Coder');
    if Root <> nil then Branch := Child(Root, 'Unit Styler');
  end;
  // The package is loaded with the others at start: give the IDE a few seconds.
  if (Branch = nil) and (FTicks < 25) then Exit;
  FTimer.Enabled := False;
  Lines := TStringList.Create;
  try
    Lines.Add('ROOT=' + BoolToStr(Root <> nil, True));
    Lines.Add('BRANCH=' + BoolToStr(Branch <> nil, True));
    Items := '';
    if Branch <> nil then
      for I := 0 to Branch.Count - 1 do Items := Items + Plain(Branch[I].Caption) + '|';
    Lines.Add('ITEMS=' + Items);
    for I := Low(Tags) to High(Tags) do
    begin
      Module := GetModuleHandle(PChar('CSCoder.UnitStyler.' + Tags[I] + '.bpl'));
      if (Module <> 0) and (GetModuleFileName(Module, Name, Length(Name)) > 0) then Lines.Add('MODULE=' + Name);
    end;
    Lines.Add('DONE');
    Lines.SaveToFile(FReport, TEncoding.UTF8);
  finally Lines.Free; end;
end;

procedure Register;
var Report: string;
begin
  Report := GetEnvironmentVariable('CSCODER_STYLER_MENUPROBE');
  if (Report <> '') and (Probe = nil) then Probe := TMenuProbe.Create(Report);
end;

initialization

finalization
  FreeAndNil(Probe);

end.
