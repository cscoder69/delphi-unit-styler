program Styler.IDE.Sample;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Sample.Current in 'Sample.Current.pas',
  Sample.Zulu in 'Sample.Zulu.pas',
  Sample.Alpha in 'Sample.Alpha.pas';

begin
  try
    if CalculateAnswer <> 42 then
      raise Exception.Create('Unexpected calculation');
    if not CheckUnicode then
      raise Exception.Create('Unicode text changed');
    Writeln('PASS: IDE fixture calculation and Unicode');
  except
    on E: Exception do
    begin
      Writeln('FAIL: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
