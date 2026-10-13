unit CSCoder.Styler.SourceFile;

// Reads and rewrites a unit that is closed in the IDE without changing its
// encoding, byte order mark or line breaks. Independent of ToolsAPI.

interface

uses System.SysUtils;

type
  TSourceEncoding = (seAnsi, seUtf8, seUtf8Bom, seUtf16LE, seUtf16BE);

  TSourceFile = record
    FileName: string;
    Bytes: TBytes;
    Encoding: TSourceEncoding;
    Text: string;
  end;

  ESourceEncoding = class(Exception);

// Raises ESourceEncoding when the bytes cannot be decoded and encoded back to
// exactly the same file, because then a rewrite could damage the content.
function LoadSourceFile(const FileName: string): TSourceFile;
function EncodeSource(const Text: string; Encoding: TSourceEncoding): TBytes;
// Replaces the file with NewText in the original encoding. Refuses when the
// file changed on disk since it was loaded or NewText does not fit the encoding.
procedure SaveSourceFile(const Original: TSourceFile; const NewText: string);

implementation

uses System.Classes, System.IOUtils, Winapi.Windows, CSCoder.Styler.Strings;

function SameBytes(const A, B: TBytes): Boolean;
begin
  Result := (Length(A) = Length(B)) and
    ((Length(A) = 0) or CompareMem(@A[0], @B[0], Length(A)));
end;

function ValidUtf8(const B: TBytes; First: Integer): Boolean;
var I, Need: Integer;
begin
  I := First;
  while I < Length(B) do
  begin
    if B[I] < $80 then Need := 0
    else if (B[I] and $E0) = $C0 then Need := 1
    else if (B[I] and $F0) = $E0 then Need := 2
    else if (B[I] and $F8) = $F0 then Need := 3
    else Exit(False);
    Inc(I);
    while Need > 0 do
    begin
      if (I >= Length(B)) or ((B[I] and $C0) <> $80) then Exit(False);
      Inc(I); Dec(Need);
    end;
  end;
  Result := True;
end;

function Preamble(Encoding: TSourceEncoding): TBytes;
begin
  case Encoding of
    seUtf8Bom: Result := TBytes.Create($EF, $BB, $BF);
    seUtf16LE: Result := TBytes.Create($FF, $FE);
    seUtf16BE: Result := TBytes.Create($FE, $FF);
    else Result := nil;
  end;
end;

function EncodingOf(Encoding: TSourceEncoding): TEncoding;
begin
  case Encoding of
    seUtf8, seUtf8Bom: Result := TEncoding.UTF8;
    seUtf16LE: Result := TEncoding.Unicode;
    seUtf16BE: Result := TEncoding.BigEndianUnicode;
    else Result := TEncoding.ANSI;
  end;
end;

function EncodeSource(const Text: string; Encoding: TSourceEncoding): TBytes;
begin
  Result := Preamble(Encoding) + EncodingOf(Encoding).GetBytes(Text);
end;

function LoadSourceFile(const FileName: string): TSourceFile;
var B: TBytes; Skip: Integer;
begin
  Result := Default(TSourceFile);
  Result.FileName := FileName;
  B := TFile.ReadAllBytes(FileName);
  Result.Bytes := B;
  Skip := 0;
  if (Length(B) >= 3) and (B[0] = $EF) and (B[1] = $BB) and (B[2] = $BF) then
  begin Result.Encoding := seUtf8Bom; Skip := 3; end
  else if (Length(B) >= 2) and (B[0] = $FF) and (B[1] = $FE) then
  begin Result.Encoding := seUtf16LE; Skip := 2; end
  else if (Length(B) >= 2) and (B[0] = $FE) and (B[1] = $FF) then
  begin Result.Encoding := seUtf16BE; Skip := 2; end
  else if ValidUtf8(B, 0) then Result.Encoding := seUtf8
  else Result.Encoding := seAnsi;
  if (Result.Encoding = seUtf8Bom) and not ValidUtf8(B, Skip) then
    raise ESourceEncoding.Create(L(stErrUtf8Invalid));
  if (Result.Encoding in [seUtf16LE, seUtf16BE]) and Odd(Length(B) - Skip) then
    raise ESourceEncoding.Create(L(stErrUtf16Size));
  if Length(B) > Skip then
    Result.Text := EncodingOf(Result.Encoding).GetString(B, Skip, Integer(Length(B)) - Skip);
  // Pure ASCII is reported as UTF-8 without mark; both encodings give the same bytes.
  if not SameBytes(EncodeSource(Result.Text, Result.Encoding), B) then
    raise ESourceEncoding.Create(L(stErrEncodingUnknown));
end;

procedure SaveSourceFile(const Original: TSourceFile; const NewText: string);
var NewBytes: TBytes; TempName: string; Id: TGUID; Stream: TFileStream; Skip: Integer;
begin
  NewBytes := EncodeSource(NewText, Original.Encoding);
  // Characters that do not exist in the file's encoding would be replaced.
  Skip := Integer(Length(Preamble(Original.Encoding)));
  if EncodingOf(Original.Encoding).GetString(NewBytes, Skip,
    Integer(Length(NewBytes)) - Skip) <> NewText then
    raise ESourceEncoding.Create(L(stErrEncodingFit));
  if not SameBytes(TFile.ReadAllBytes(Original.FileName), Original.Bytes) then
    raise EInOutError.Create(L(stErrChangedOnDisk));
  if FileIsReadOnly(Original.FileName) then
    raise EInOutError.Create(L(stErrReadOnly));
  // Short name in the same folder: a long unit path must not exceed the limit.
  CreateGUID(Id);
  TempName := TPath.Combine(ExtractFileDir(Original.FileName), '~' + IntToHex(Id.D1, 8) + '.tmp');
  try
    Stream := TFileStream.Create(TempName, fmCreate);
    try
      if Length(NewBytes) > 0 then Stream.WriteBuffer(NewBytes[0], Length(NewBytes));
    finally Stream.Free; end;
    // One step on the same volume: the unit is never left half written.
    if not MoveFileEx(PChar(TempName), PChar(Original.FileName),
      MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then RaiseLastOSError;
  finally
    if TFile.Exists(TempName) then TFile.Delete(TempName);
  end;
end;

end.
