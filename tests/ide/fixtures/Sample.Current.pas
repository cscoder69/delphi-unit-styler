unit Sample.Current;

// Antes dos offsets: ação, café, Straße, français, español, 😀.
interface

uses Sample.Zulu, System.SysUtils, Sample.Alpha;

function CalculateAnswer: Integer;
function CheckUnicode: Boolean;

implementation

uses System.Classes, // Classe usada no cálculo; acompanha esta unit.
  System.Character;

function CalculateAnswer: Integer;
var
  Values: TStringList;
begin
  Values := TStringList.Create;
  try
    Values.Add(IntToStr(AlphaValue));
    Values.Add(IntToStr(ZuluValue));
    Result := StrToInt(Values[0]) + StrToInt(Values[1]);
  finally
    Values.Free;
  end;
end;

function CheckUnicode: Boolean;
const
  Text = 'ação 😀';
begin
  Result := (Length(Text) = 7) and (Ord(Text[2]) = $00E7) and
    Text[6].IsHighSurrogate and
    Text[7].IsLowSurrogate;
end;

end.
