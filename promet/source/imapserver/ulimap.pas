unit ulimap;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, lNet, lEvents, mimemess, db, dateutils,base64;
type
  TIMAPFolder = class(TComponent)
  private
    FMessageIdx: LargeInt;
    FUID: string;
  protected
    FFirstID: LargeInt;
    FName: string;
    function GetCount: Integer;virtual;
    function GetUnreadCount: Integer;virtual;
    function GetLastID: LargeInt;virtual;
    function GetFirstID: LargeInt;virtual;
    function GetNextID: LargeInt;virtual;
    function GetMessage(Idx : Integer): TMimeMess;virtual;
    function GetMessageByID(Idx : string): TMimeMess;virtual;
    function GetCreatedAt: TDateTime;virtual;
    function PostArticle(aArticle : TStrings;aUser : string;FPostFlags : string;
    FPostDateTime : string) : Boolean;virtual;abstract;
    function SelectMessages(aFilter : string;aUseUID : Boolean) : Boolean;virtual;
    function FetchOneEntry(aFetch: string): TStrings; virtual;
  public
    constructor Create(aName : string;UID : string);virtual;
    destructor Destroy;override;
    property UID : string read FUID;
    property Name : string read FName;
    property Count : Integer read GetCount;
    property FirstID : LargeInt read GetFirstID;
    property NextID  : LargeInt read GetNextID;
    property LastID : LargeInt read GetLastID;
    property Unseen : Integer read GetUnreadCount;
    property Message[Idx : Integer] : TMimeMess read GetMessage;
    property MessageByID[Idx : string] : TMimeMess read GetMessageByID;
    property MessageIdx : LargeInt read FMessageIdx write FmessageIdx;
    property CreatedAt : TDateTime read GetCreatedAt;
  end;
  TIMAPFolderClass = class of TIMAPFolder;
  TIMAPFolders = class(TList)
  private
    function Get(Idx : Integer): TIMAPFolder;
  public
    property Group[Idx : Integer] : TIMAPFolder read Get;
  end;
  TLIMAPSocket = class(TLSocket)
    procedure LIMAPSocketError(aHandle: TLHandle; const msg: string);
  private
    FBuffer: string;
    FId: Integer;
    FShouldSend: Boolean;
    FUser: string;
    FGroup : TIMAPFolder;
    FMessage : TMimeMess;
    FmessageIdx : Integer;
    FPostMode : Boolean;
    FPostMessage : TStringList;
    FPostLength : Integer;
    FSendBuffer : TStrings;
    FError : Boolean;
    FTerminated : Boolean;
    FAuthMode : Boolean;
    FAuthStr : string;
    FStopFetching :Boolean;
    FPostFlags : string;
    FPostDateTime : string;
  protected
    procedure DoSendBuffer;
  public
    DontLog : Boolean;
    property SendBuffer : TStrings read FSendBuffer;
    function Send(const aData; const aSize: Integer): Integer; override;
    property Buffer : string read FBuffer write FBuffer;
    procedure LineReceived(aLine : string);
    property User : string read FUser write FUser;
    property Id : Integer read FId write FId;
    property ShouldSend : Boolean read FShouldSend write FShouldSend;
    constructor Create;override;
    destructor Destroy;override;
  end;
  TLIMAPLoginEvent = function(aSocket : TLIMAPSocket;aUser,aPasswort : string) : Boolean of object;
  TLIMAPLogEvent = procedure(aSocket : TLIMAPSocket;DirectionIn : Boolean;aMessage : string) of object;

  { TLIMAPServer }

  TLIMAPServer = class(TLTcp)
  private
    FGroups: TIMAPFolders;
    FLog: TLIMAPLogEvent;
    FLogin: TLIMAPLoginEvent;
    FSocketCounter : Integer;
  protected
    procedure AcceptEvent(aSocket: TLHandle); override;
   procedure ReceiveEvent(aSocket: TLHandle); override;
    procedure CanSendEvent(aSocket: TLHandle); override;
  public
   constructor Create(aOwner: TComponent); override;
   destructor Destroy; override;
   procedure Start;
   property OnLogin : TLIMAPLoginEvent read FLogin write FLogin;
   property OnLog : TLIMAPLogEvent read FLog write FLog;
   property Groups : TIMAPFolders read FGroups;
   procedure CallAction; override;
  end;
implementation
uses lHTTPUtil;
const
  CRLF=#13#10;
function TIMAPFolders.Get(Idx : Integer): TIMAPFolder;
begin
  if Idx < Count then
    Result := TIMAPFolder(Items[Idx]);
end;
function TIMAPFolder.GetMessageByID(Idx : string): TMimeMess;
begin
  Result := nil;
end;
function TIMAPFolder.GetCreatedAt: TDateTime;
begin
  Result := Now();
end;

function TIMAPFolder.SelectMessages(aFilter: string;aUseUID : Boolean): Boolean;
begin
  Result := false;
end;

function TIMAPFolder.FetchOneEntry(aFetch: string): TStrings;
begin
  Result := nil;
end;

function TIMAPFolder.GetFirstID: LargeInt;
begin
  Result := FFirstID;
end;

function TIMAPFolder.GetUnreadCount: Integer;
begin
  result := 0;
end;

function TIMAPFolder.GetNextID: LargeInt;
begin
  Result := 0;
end;

function TIMAPFolder.GetCount: Integer;
begin
  Result := 0;
end;
function TIMAPFolder.GetLastID: LargeInt;
begin
  Result := 0;
end;
function TIMAPFolder.GetMessage(Idx : Integer): TMimeMess;
begin
  Result := nil;
end;
constructor TIMAPFolder.Create(aName: string;UID : string);
begin
  FName := aName;
  FUID := UID;
end;
destructor TIMAPFolder.Destroy;
begin
  inherited Destroy;
end;
procedure TLIMAPSocket.LIMAPSocketError(aHandle: TLHandle; const msg: string);
begin
  TLIMAPSocket(aHandle).FError:=True;
end;
procedure TLIMAPSocket.DoSendBuffer;
var
  tmp: String;
begin
  try
    if (SendBuffer.Count = 0) or (not FShouldSend) then exit;
    while (not Fterminated) and (SendBuffer.Count > 0) do
      begin
        tmp := SendBuffer[0];
        DontLog := True;
        if SendMessage(tmp+CRLF) > 0 then
          begin
            DontLog := False;
            if FTerminated then exit;
            SendBuffer.Delete(0);
            try
              if Assigned(Creator) then
                Creator.CallAction;
            except
            end;
          end
        else
          begin
            DontLog := False;
            break;
          end;
      end;
    if (SendBuffer.Count = 0) then
      FShouldSend := False;
  except //Client disconnects ??
  end;
end;
function TLIMAPSocket.Send(const aData; const aSize: Integer): Integer;
var
  aMessage : string;
begin
  if (not DontLog) and Assigned(TLIMAPServer(Creator).OnLog) then
    begin
      Setlength(aMessage,aSize);
      Move(aData,aMessage[1],aSize);
      Setlength(aMessage,aSize-2);
      TLIMAPServer(Creator).OnLog(Self,True,aMessage);
    end;
  Result:=inherited Send(aData, aSize);
end;
procedure TLIMAPSocket.LineReceived(aLine: string);
var
  aCommand : string;
  aParams : string = '';
  Answered : Boolean = False;
  tmp : string;
  aMessage : TMimeMess;
  i : Integer;
  aGroup : TIMAPFolder;
  Found : Boolean;
  sl : TStringList;
  agroupClass : TIMAPFolderClass;
  aDate: TDateTime;
  aTag: String;
  aGUID: TGUID;
  procedure Answer(aMsg : string;UseTag : Boolean = True);
  begin
    if UseTag then
      begin
        if SendMessage(aTag+' '+aMsg+CRLF) = 0 then
          FSendBuffer.Add(aMsg);
      end
    else
      begin
        if SendMessage(aMsg+CRLF) = 0 then
          FSendBuffer.Add(aMsg);
      end;
    Answered := True;
  end;
  function IsNumeric(s:String):Boolean;
  var i:Integer;
  begin
    Result:=False;
    for i := 1 to Length(s) do
      if (s[i] > '9') or (s[i] < '0') then exit;
    Result:=True;
  end;
  function SelectMessage : Boolean;
  begin
    Result := False;
    if not Assigned(FGroup) then exit;
    if IsNumeric(aParams) then
      begin
        if FMessageIdx = StrToInt(aParams) then
          begin
            aMessage := FMessage;
            Result := True;
          end
        else
          begin
            aMessage := FGroup.Message[StrToInt(aParams)];
            FMessageIdx := FGroup.MessageIdx;
            FMessage := aMessage;
            if Assigned(aMessage) then
              begin
                result := True;
              end;
          end;
      end
    else
      begin
        if Assigned(FMessage) and (FMessage.Header.MessageID = aParams) then
          begin
            aMessage := Fmessage;
            Result := True;
          end
        else
          begin
            aMessage := FGroup.MessageByID[aParams];
            FMessageIdx := FGroup.MessageIdx;
            Fmessage := aMessage;
            if Assigned(aMessage) then
              begin
                aMessage.Encodemessage;
                Result := True;
              end;
          end;
      end;
  end;
  procedure DoFetch(bParams : string;aUseUID : Boolean);
  var
    aCmd: String;
    aRange: String;
    aRes: TStrings;
    a: Integer;
  begin
    FStopFetching := False;
    aCmd := Uppercase(copy(bParams,0,pos(' ',bParams)-1));
    bParams:=copy(bParams,pos(' ',bParams)+1,length(bParams));
    if aCmd = 'FETCH' then
      begin
        DontLog:=True;
        aRange := copy(bParams,0,pos(' ',bParams)-1);
        bParams:=copy(bParams,pos(' ',bParams)+1,length(bParams));
        if copy(bParams,0,1)='(' then
          tmp := copy(bParams,2,length(bParams)-2);
        if bParams = 'ALL' then
          bParams := 'FLAGS INTERNALDATE RFC822.SIZE ENVELOPE';
        if bParams = 'FAST' then
          bParams := 'FLAGS INTERNALDATE RFC822.SIZE';
        if aUseUID and (pos('UID',bParams)=0) then
          bParams:='UID '+bParams;
        if FGroup.SelectMessages(aRange,aUseUID) then
          begin
            aRes := FGroup.FetchOneEntry(bParams);
            while Assigned(aRes) do
              begin
                for a := 0 to aRes.Count-1 do
                  begin
                    Creator.CallAction;
                    if not FStopFetching then
                      Answer(aRes[a],False)
                    else
                      begin
                        DontLog:=False;
                        exit;
                      end;
                  end;
                aRes := FGroup.FetchOneEntry(bParams);
              end;
            Answer('OK Success');
          end
        else Answer('NO failed.');
        DontLog:=False;
      end
    else
      Answer('BAD Comand not implemented.');
  end;

begin
  if Assigned(TLIMAPServer(Self.Creator).OnLog) and (not FPostMode) then
    begin
      if not (pos('LOGIN ',Uppercase(aLine)) > 0) then
        TLIMAPServer(Self.Creator).OnLog(Self,False,aLine)
      else
        TLIMAPServer(Self.Creator).OnLog(Self,False,copy(aLine,0,pos('LOGIN',Uppercase(aLine))+5));
    end;
  if FAuthMode then
    begin
      tmp := DecodeStringBase64(aLine);
      if tmp = FAuthStr then
        Answer('OK')
      else
        Answer('NO');
      FAuthMode:=False;
      exit;
    end
  else if FPostMode then
    begin
      dec(FPostLength,length(aLine)+2);
      FPostMessage.Add(aLine);
      if (FPostLength <= 0) then
        begin
          DontLog := false;
          FPostMode := False;
          if Assigned(FGroup) then
            begin
              if FGroup.PostArticle(FPostMessage,FUser,FPostFlags,FPostDateTime) then
                Answer('OK APPEND finished')
              else
                Answer('NO APPEND failed');
            end
          else
            begin
              aGroup := TLIMAPServer(Creator).Groups.Group[0];
              if Assigned(FGroup) then FGroup.Destroy;
              aGroupClass := TIMAPFolderClass(aGroup.ClassType);
              FGroup := aGroupClass.Create(aGroup.Name,aGroup.UID);
              if FGroup.PostArticle(FPostMessage,FUser,FPostFlags,FPostDateTime) then
                Answer('OK APPEND finished')
              else
                Answer('NO APPEND failed');
              FreeAndNil(FGroup);
            end;
        end;
      exit;
    end;
  if pos(' ',aLine) > 0 then
    begin
      aTag := copy(aLine,0,pos(' ',aLine)-1);
      aLine := trim(copy(aLine,pos(' ',aLine)+1,length(aLine)));
    end;
  if pos(' ',aLine) > 0 then
    begin
      aCommand := Uppercase(copy(aLine,0,pos(' ',aLine)-1));
      aParams := trim(copy(aLine,pos(' ',aLine)+1,length(aLine)));
    end
  else
    aCommand := Uppercase(aLine);
  if (aCommand = 'SELECT')
  or (aCommand = 'EXAMINE')
  then
    begin
      if (FUser = '') then
        begin
          Answer('NO Authentication required');
          exit;
        end;
      Found := False;
      if copy(aParams,0,1)='"' then
        aParams := copy(aParams,2,length(aParams)-2);
      for i := 0 to TLIMAPServer(Creator).Groups.Count-1 do
        begin
          if TLIMAPServer(Creator).Groups.Group[i].Name = aParams then
            begin
              aGroup := TLIMAPServer(Creator).Groups.Group[i];
              if Assigned(FGroup) then FGroup.Destroy;
              aGroupClass := TIMAPFolderClass(aGroup.ClassType);
              FGroup := aGroupClass.Create(aGroup.Name,aGroup.UID);
              Answer(Format('* %d EXISTS',[aGroup.Count]),False);
              Answer(Format('* %d RECENT',[0]),False);
              Answer('* FLAGS (\Answered \Flagged \Deleted \Seen \Draft)',False);
              Answer(Format('* OK [UNSEEN %d]',[aGroup.Unseen]),False);
              Answer(Format('* OK [UIDVALIDITY %s]',[aGroup.FUID]),False);
              Answer(Format('* OK [UIDNEXT %d] Predicted next UID.',[aGroup.NextID]),False);
              Answer('OK [READ-WRITE] '+aCommand+' completed');
              Found := True;
              break;
            end;
        end;
      if not Found then Answer('NO Folder not Found.');
    end
  else if aCommand = 'APPEND' then
    begin
      if (FUser = '') then
        begin
          Answer('BAD Authentication required');
          exit;
        end
      else
        begin
          tmp := copy(aParams,0,pos(' ',aParams)-1);
          if copy(tmp,0,1)='"' then
            tmp := copy(tmp,2,length(tmp)-2);
          if Assigned(FGroup) then FreeAndNil(FGroup);
          for i := 0 to TLIMAPServer(Creator).Groups.Count-1 do
            begin
              if TLIMAPServer(Creator).Groups.Group[i].Name = tmp then
                begin
                  aGroup := TLIMAPServer(Creator).Groups.Group[i];
                  aGroupClass := TIMAPFolderClass(aGroup.ClassType);
                  FGroup := aGroupClass.Create(aGroup.Name,aGroup.UID);
                end;
            end;
          if Assigned(FGroup) then
            begin
              tmp := copy(aParams,pos('{',aParams)+1,length(aParams));
              FPostLength := StrToIntDef(copy(tmp,0,pos('}',tmp)-1),0);
              tmp := trim(copy(aParams,pos(' ',aParams)+1,length(aParams)));
              if copy(tmp,0,1)='(' then
                begin
                  FPostFlags := copy(tmp,2,pos(')',tmp)-2);
                  tmp := copy(tmp,pos(')',tmp)+1,length(tmp))
                end;
              tmp := trim(copy(tmp,0,pos('{',tmp)-1));
              if copy(tmp,0,1)='"' then
                tmp := copy(tmp,2,length(tmp)-2);
              FPostDateTime:=tmp;
              FPostMode := True;
              FPostMessage.Clear;
              DontLog := True;
              SendMessage('+ OK'+CRLF)
            end
          else Answer('NO Folder not found !');
        end;
    end
{
  else if aCommand = 'STORE' then
    begin
      if (FUser = '') then
        begin
          Answer('BAD Authentication required');
          exit;
        end
      else
        begin
          Answer('OK Input article; end with <CR-LF>.<CR-LF>');
          FPostMode := True;
          FPostMessage.Clear;
          DontLog := True;
        end;
    end
}
  else if aCommand = 'LIST' then
    begin
      if copy(tmp,0,1)='"' then
        tmp := copy(tmp,2,length(tmp)-2);
      aParams:=copy(aParams,pos(' ',aParams)+1,length(aParams));
      if copy(aParams,0,1)='"' then
        aParams := copy(aParams,2,length(aParams)-2);
      //TODO:fix this
      aParams := StringReplace(aParams,'*','',[rfReplaceAll]);
      aParams := StringReplace(aParams,'?','',[rfReplaceAll]);
      for i := 0 to TLIMAPServer(Creator).Groups.Count-1 do
        begin
          aGroup := TLIMAPServer(Creator).Groups.Group[i];
          if (pos(aParams,aGroup.Name) >0) or (aParams='') then
            Answer(Format('* LIST (\Noinferiors) "/" "%s"',[aGroup.Name]),False);
        end;
      Answer('OK LIST completed');
    end
  else if aCommand = 'LSUB' then
    begin
      if copy(tmp,0,1)='"' then
        tmp := copy(tmp,2,length(tmp)-2);
      aParams:=copy(aParams,pos(' ',aParams)+1,length(aParams));
      if copy(aParams,0,1)='"' then
        aParams := copy(aParams,2,length(aParams)-2);
      //TODO:fix this
      aParams := StringReplace(aParams,'*','',[rfReplaceAll]);
      aParams := StringReplace(aParams,'?','',[rfReplaceAll]);
      for i := 0 to TLIMAPServer(Creator).Groups.Count-1 do
        begin
          aGroup := TLIMAPServer(Creator).Groups.Group[i];
          if (pos(aParams,aGroup.Name) >0) or (aParams='') then
            Answer(Format('* LSUB (\Noinferiors) "/" "%s"',[aGroup.Name]),False);
        end;
      Answer('OK LSUB completed');
    end
  else if aCommand = 'UID' then
    begin
      DoFetch(aParams,True);
    end
  else if aCommand = 'CREATE' then
    begin
      Answer('NO not permitted.');
    end
  else if (aCommand = 'FETCH')
       or (aCommand = 'SEARCH')
  then
    begin
      aParams := aCommand+' '+aParams;
      DoFetch(aParams,False);
    end
  else if aCommand = 'STATUS' then
    begin
      tmp := copy(aParams,pos('(',aParams),length(aParams));
      if pos('(',aParams)>0 then
        aParams:=copy(aParams,0,pos('(',aParams)-1);
      aParams:=trim(aParams);
      if copy(aParams,0,1)='"' then
        aParams := copy(aParams,2,length(aParams)-2);
      Found := False;
      for i := 0 to TLIMAPServer(Creator).Groups.Count-1 do
        begin
          if TLIMAPServer(Creator).Groups.Group[i].Name = aParams then
            begin
              aGroup := TLIMAPServer(Creator).Groups.Group[i];
              Answer(Format('* STATUS "%s" (MESSAGES %d UIDNEXT %d UNSEEN %d RECENT %d)',[aGroup.Name,aGroup.Count,aGroup.GetLastID,aGroup.Unseen,0]));
              Answer('OK STATUS Completed');
              Found := True;
              break;
            end;
        end;
      if not Found then
        Answer('NO STATUS Completed');
    end
  else if aCommand = 'CAPABILITY' then
    begin
      Answer('* CAPABILITY IMAP4rev1 AUTH=PLAIN',False);
      Answer('OK CAPABILITY Completed');
    end
  else if aCommand = 'AUTHENTICATE' then
    begin
      if Uppercase(trim(aParams)) = 'PLAIN' then
        begin
          FAuthStr:=' ';
          Answer('+ ');
          FAuthMode := True;
        end
      else Answer('NO');
    end
  else if aCommand = 'LOGIN' then
    begin
      tmp := copy(aParams,0,pos(' ',aParams)-1);
      if copy(tmp,0,1)='"' then
        tmp := copy(tmp,2,length(tmp)-2);
      aParams:=copy(aParams,pos(' ',aParams)+1,length(aParams));
      aParams := copy(aParams,2,length(aParams)-2);
      if Assigned(TLIMAPServer(Creator).OnLogin) then
        begin
          if TLIMAPServer(Creator).OnLogin(Self,tmp,aParams) then
            begin
              Answer('OK Login Ok.');
              FUser := tmp;
            end
          else
            begin
              Answer('NO');
              Disconnect;
            end;
        end;
    end
  else if aCommand = 'LOGOUT' then
    begin
      Answer('OK Closing connection.');
      Disconnect;
    end
  else if aCommand = 'NOOP' then
    begin
      Answer('OK NOOP');
    end
  else if aCommand = '' then
  else Answer('BAD Command not implemented.');
end;
constructor TLIMAPSocket.Create;
begin
  inherited Create;
  Fid := 0;
  FGroup := nil;
  FUser := '';
  FPostMode := False;
  FAuthMode := False;
  FPostMessage := TStringList.Create;
  DontLog := False;
  FSendBuffer := TStringList.Create;
  FError := False;
  FTerminated := False;
  FStopFetching := False;
  Self.OnError:=@LIMAPSocketError;
end;
destructor TLIMAPSocket.Destroy;
begin
  FTerminated := True;
  if Assigned(FGroup) then fGroup.Destroy;
  FSendBuffer.Free;
  FPostMessage.Destroy;
  inherited;
end;
procedure TLIMAPServer.AcceptEvent(aSocket: TLHandle);
begin
  inherited AcceptEvent(aSocket);
  TLSocket(aSocket).SendMessage('* OK Greets from IMAP Server'+CRLF);
  with TLIMAPSocket(aSocket) do
    if Id = 0 then
      begin
        Id := FSocketCounter+1;
        inc(FSocketCounter);
      end;
end;
procedure TLIMAPServer.ReceiveEvent(aSocket: TLHandle);
var
  aMessage : string;
begin
  inherited ReceiveEvent(aSocket);
  if TLSocket(aSocket).getMessage(aMessage) > 0 then
    begin
      TLIMAPSocket(aSocket).Buffer := TLIMAPSocket(aSocket).Buffer+aMessage;
      while pos(CRLF,TLIMAPSocket(aSocket).Buffer) > 0 do
        begin
          TLIMAPSocket(aSocket).LineReceived(copy(TLIMAPSocket(aSocket).Buffer,0,pos(CRLF,TLIMAPSocket(aSocket).Buffer)-1));
          TLIMAPSocket(aSocket).Buffer := copy(TLIMAPSocket(aSocket).Buffer,pos(CRLF,TLIMAPSocket(aSocket).Buffer)+2,length(TLIMAPSocket(aSocket).Buffer));
        end;
    end;
end;
procedure TLIMAPServer.CanSendEvent(aSocket: TLHandle);
var
  tmp: String;
  maxlen: Integer = 0;
  aSock: TLSocket;
begin
  inherited CanSendEvent(aSocket);
  TLIMAPSocket(aSocket).ShouldSend := True;
end;
constructor TLIMAPServer.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);
  FSocketCounter := 0;
  FGroups := TIMAPFolders.Create;
  SocketClass := TLIMAPSocket;
end;
destructor TLIMAPServer.Destroy;
begin
  FGroups.Destroy;
  inherited Destroy;
end;

procedure TLIMAPServer.Start;
begin
  if not Listen(Port) then raise Exception.Create('Listen failed');
end;

procedure TLIMAPServer.CallAction;
begin
  inherited CallAction;
  while IterNext do
    if Iterator is TLIMAPSocket then
      TLIMAPSocket(Iterator).DoSendBuffer;
end;

end.
