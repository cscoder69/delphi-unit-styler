program StylerMenuTests;
{$APPTYPE CONSOLE}
uses System.SysUtils, Vcl.Menus,
  CSCoder.Styler.MenuIntegration in '..\src\ide\CSCoder.Styler.MenuIntegration.pas';
var Main: TMainMenu; Registration: TStylerMenuRegistration; Root, Other: TMenuItem;
  Checks: Integer;
procedure Check(Value: Boolean; const Message: string);
begin Inc(Checks); if not Value then raise Exception.Create(Message); end;
begin
  Main := TMainMenu.Create(nil); Registration := nil;
  try
    Registration := TStylerMenuRegistration.CreateMenu(Main, nil, nil, nil);
    Check(Main.Items.Count = 1, 'Single shared root');
    Root := Main.Items[0];
    Check(Root.Caption = 'CS.Coder', 'Root caption');
    Check((Root.Count = 1) and (Root.Items[0].Caption = 'Unit Styler'), 'Only installed tool');
    Check(Root.Items[0].Count = 3, 'Three commands in submenu');
    Check(Root.Items[0].Items[0].Hint <> '', 'Organize help');
    Check(Root.Items[0].Items[1].Hint <> '', 'Settings help');
    Check((Root.Items[0].Items[2].Caption = 'Sobre...') and (Root.Items[0].Items[2].Hint <> ''), 'About command with help');
    Other := TMenuItem.Create(Main); Other.Caption := 'Outra ferramenta'; Root.Add(Other);
    FreeAndNil(Registration);
    Check((Main.Items.Count = 1) and (Root.Count = 1) and (Root.Items[0] = Other), 'Keep other tool when unloading');
    Registration := TStylerMenuRegistration.CreateMenu(Main, nil, nil, nil);
    Check((Main.Items.Count = 1) and (Root.Count = 2), 'Reuse shared root on reload');
    Check(Root.Items[0].Caption = 'Unit Styler', 'Styler before other tools');
    Other.Free; FreeAndNil(Registration);
    Check(Main.Items.Count = 0, 'Remove empty owned root');
    Root := TMenuItem.Create(Main); Root.Caption := '&CS.Coder'; Main.Items.Add(Root);
    Registration := TStylerMenuRegistration.CreateMenu(Main, nil, nil, nil);
    Check(Main.Items.Count = 1, 'Reuse foreign root by caption');
    FreeAndNil(Registration);
    Check((Main.Items.Count = 1) and (Root.Count = 0), 'Preserve foreign root ownership');
    Registration := TStylerMenuRegistration.CreateMenu(Main, nil, nil, nil);
    FreeAndNil(Main); FreeAndNil(Registration);
    Inc(Checks); Writeln('PASS ', Checks, ' menu checks');
  except
    on E: Exception do begin Writeln(E.Message); ExitCode := 1; end;
  end;
  Registration.Free; Main.Free;
end.
