library serialport;

{$mode objfpc}{$H+}

uses
  Classes,sysutils,synaser;

type
  TParityType = (NoneParity, OddParity, EvenParity);

var
  Ports : TList = nil;

function SerOpen(const DeviceName: String): LongInt;
var
  aDev: TBlockSerial;
begin
  if not Assigned(Ports) then
    Ports := TList.Create;
  aDev := TBlockSerial.Create;
  aDev.Connect(DeviceName);
  Ports.Add(aDev);
  Result := aDev.Handle;
end;

procedure SerClose(Handle: LongInt);
var
  i: Integer;
  aDev: TBlockSerial;
begin
  for i := 0 to Ports.Count-1 do
    if TBlockSerial(Ports[i]).Handle=Handle then
      begin
        aDev := TBlockSerial(Ports[i]);
        Ports.Remove(aDev);
        aDev.Free;
        if Ports.Count=0 then
          FreeAndNil(Ports);
        exit;
      end;
end;

procedure SerFlush(Handle: LongInt);
var
  i: Integer;
begin
  for i := 0 to Ports.Count-1 do
    if TBlockSerial(Ports[i]).Handle=Handle then
      begin
        TBlockSerial(Ports[i]).Flush;
        exit;
      end;
end;

procedure SerParams(Handle: LongInt; BitsPerSec: LongInt; ByteSize: Integer; Parity: TParityType; StopBits: Integer);
var
  i: Integer;
begin
  for i := 0 to Ports.Count-1 do
    if TBlockSerial(Ports[i]).Handle=Handle then
      begin
        case Parity of
        NoneParity:TBlockSerial(Ports[i]).Config(BitsPerSec,ByteSize,'N',StopBits,false,true);
        OddParity:TBlockSerial(Ports[i]).Config(BitsPerSec,ByteSize,'O',StopBits,false,true);
        EvenParity:TBlockSerial(Ports[i]).Config(BitsPerSec,ByteSize,'E',StopBits,false,true);
        end;
        exit;
      end;
end;

function SerRead(Handle: LongInt;Count: LongInt) : PChar;
var
  Data: String;
  i: Integer;
begin
  for i := 0 to Ports.Count-1 do
    if TBlockSerial(Ports[i]).Handle=Handle then
      begin
        SetLength(Data,Count);
        TBlockSerial(Ports[i]).RecvBuffer(@Data[1],Count);
        Result := @Data[1];
        exit;
      end;
end;

function SerReadTimeout(Handle: LongInt;var Data : PChar;Timeout: Integer) : Integer;
var
  i: Integer;
  iData: String;
begin
  for i := 0 to Ports.Count-1 do
    if TBlockSerial(Ports[i]).Handle=Handle then
      begin
        iData := TBlockSerial(Ports[i]).RecvPacket(Timeout);
        Result := length(iData);
        Data := PChar(Data);
        exit;
      end;
end;

function SerGetCTS(Handle: LongInt) : Boolean;
var
  i: Integer;
begin
  for i := 0 to Ports.Count-1 do
    if TBlockSerial(Ports[i]).Handle=Handle then
      begin
        Result := TBlockSerial(Ports[i]).CTS;
        exit;
      end;
end;

function SerGetDSR(Handle: LongInt) : Boolean;
var
  i: Integer;
begin
  for i := 0 to Ports.Count-1 do
    if TBlockSerial(Ports[i]).Handle=Handle then
      begin
        Result := TBlockSerial(Ports[i]).DSR;
        exit;
      end;
end;

procedure SerSetRTS(Handle: LongInt;Value : Boolean);
var
  i: Integer;
begin
  for i := 0 to Ports.Count-1 do
    if TBlockSerial(Ports[i]).Handle=Handle then
      begin
        TBlockSerial(Ports[i]).RTS := Value;
        exit;
      end;
end;

procedure SerSetDTR(Handle: LongInt;Value : Boolean);
var
  i: Integer;
begin
  for i := 0 to Ports.Count-1 do
    if TBlockSerial(Ports[i]).Handle=Handle then
      begin
        TBlockSerial(Ports[i]).DTR := Value;
        exit;
      end;
end;

function SerWrite(Handle: LongInt; Data : PChar;Len : Integer): LongInt;
var
  i: Integer;
begin
  for i := 0 to Ports.Count-1 do
    if TBlockSerial(Ports[i]).Handle=Handle then
      begin
        TBlockSerial(Ports[i]).SendBuffer(Data,Len);
        Result := length(Data);
        exit;
      end;
end;

procedure ScriptCleanup;
var
  i: Integer;
begin
  if not Assigned(Ports) then exit;
  for i := 0 to Ports.Count-1 do
    TBlockSerial(Ports[i]).Free;
  Ports.Clear;
  FreeAndNil(Ports);
end;

function ScriptDefinition : PChar;stdcall;
begin
  Result := 'TParityType = (NoneParity, OddParity, EvenParity);'
       +#10+'function SerOpen(const DeviceName: String): LongInt;'
       +#10+'procedure SerClose(Handle: LongInt);'
       +#10+'procedure SerFlush(Handle: LongInt);'
       +#10+'function SerRead(Handle: LongInt; Count: LongInt): PChar;'
       +#10+'function SerReadTimeout(Handle: LongInt;var Data : PChar;Timeout: Integer) : Integer;'
       +#10+'function SerWrite(Handle: LongInt; Data : PChar;Len : Integer): LongInt;'
       +#10+'procedure SerParams(Handle: LongInt; BitsPerSec: LongInt; ByteSize: Integer; Parity: TParityType; StopBits: Integer);'
       +#10+'function SerGetCTS(Handle: LongInt) : Boolean;'
       +#10+'function SerGetDSR(Handle: LongInt) : Boolean;'
       +#10+'procedure SerSetRTS(Handle: LongInt;Value : Boolean);'
       +#10+'procedure SerSetDTR(Handle: LongInt;Value : Boolean);'
            ;
end;

exports
  SerOpen,
  SerClose,
  SerFlush,
  SerRead,
  SerReadTimeout,
  SerWrite,
  SerParams,
  SerGetCTS,
  SerGetDSR,
  SerSetRTS,
  SerSetDTR,

  ScriptDefinition,
  ScriptCleanup;

end.
