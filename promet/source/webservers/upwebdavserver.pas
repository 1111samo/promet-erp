unit upwebdavserver;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, dom, xmlread, xmlwrite, uappserverhttp;
type
  TLFile = class;
  TLDirectoryList = class(TList)
  private
    function Get(Index: Integer): TLFile;
    procedure Put(Index: Integer; AValue: TLFile);
  public
    constructor Create;
    property Files[Index: Integer]: TLFile read Get write Put; default;
    destructor Destroy;override;
  end;

  { TLFile }

  TLFile = class(TLDirectoryList)
  private
    FASet: TStringList;
    FCHS: string;
    FFath: string;
    FIsCal: Boolean;
    FIsCalU: Boolean;
    FIsDir: Boolean;
    FIsTodo: Boolean;
    FName: string;
    FPath: string;
    FProperties: TStringList;
    procedure SetName(AValue: string);
  public
    constructor Create(aName : string;aIsDir : Boolean = False);
    destructor Destroy;override;
    property Name : string read FName write SetName;
    property Properties : TStringList read FProperties;
    property IsDir : Boolean read FIsDir;
    property IsCalendar : Boolean read FIsCal write FIsCal;
    property IsCalendarUser : Boolean read FIsCalU write FIsCalU;
    property IsTodoList : Boolean read FIsTodo write FIsTodo;
    property CalendarHomeSet : string read FCHS write FCHS;
    property UserAdressSet : TStringList read FASet;
    property Path : string read FFath write FPath;
  end;
  TLGetDirectoryList = function(aDir : string;aDepth : Integer;var aDirList : TLDirectoryList) : Boolean of object;
  TLGetCTag = function(aDir : string;var aCTag : Int64) : Boolean of object;
  TLFileEvent = function(aDir : string) : Boolean of object;
  TLFileStreamEvent = function(aDir : string;Stream : TStream;var eTag : string;var Result : Integer) : Boolean of object;
  TLFileStreamDateEvent = function(aDir : string;Stream : TStream;var FLastModified : TDateTime;var MimeType : string;var eTag : string) : Boolean of object;
  TLLoginEvent = function(aUser,aPassword : string) : Boolean of object;

  { TWebDAVServerSocket }

  TWebDAVServerSocket = class(TObject)
  end;

var
  OnGetDirectoryList : TLGetDirectoryList;
  OnMkCol : TLFileEvent;
  OnDelete : TLFileEvent;
  OnPutFile : TLFileStreamEvent;
  OnPostFile : TLFileStreamEvent;
  OnGetFile : TLFileStreamDateEvent;
  OnReadAllowed : TLFileEvent;
  OnWriteAllowed : TLFileEvent;
  OnUserLogin : TLLoginEvent;
  OnGetCTag : TLGetCTag;

{
  TXmlOutput = class(TMemoryStreamOutput)
  private
    FIn: TStringStream;
    FOut : TMemoryStream;
    ADoc: TXMLDocument;
  protected
    procedure DoneInput; override;
    function BuildStatus(aStatus : TLHTTPStatus) : string;
    function  HandleInput(ABuffer: pchar; ASize: integer): integer; override;
    function HandleXMLRequest(aDocument : TXMLDocument) : Boolean;virtual;abstract;
  public
    constructor Create(ASocket: TLHTTPSocket);
    destructor Destroy; override;
  end;
  TFileStreamInput = class(TStreamOutput)
  private
    FEvent: TLFileStreamEvent;
  protected
    function  HandleInput(ABuffer: pchar; ASize: integer): integer; override;
    procedure DoneInput; override;
  public
    property Event : TLFileStreamEvent read FEvent write FEvent;
  end;
  TFileStreamOutput = class(TStreamOutput)
  private
    FEvent: TLFileStreamDateEvent;
  protected
    procedure DoneInput; override;
  public
    property Event : TLFileStreamDateEvent read FEvent write FEvent;
  end;
  TDAVOptionsOutput = class(TXmlOutput)
  protected
    function HandleXMLRequest(aDocument : TXMLDocument) : Boolean;override;
  end;
  TDAVReportOutput = class(TXmlOutput)
  protected
    function HandleXMLRequest(aDocument : TXMLDocument) : Boolean;override;
  end;
  TDAVFindPropOutput = class(TXmlOutput)
  protected
    function HandleXMLRequest(aDocument : TXMLDocument) : Boolean;override;
  end;
  TDAVLockOutput = class(TXmlOutput)
  protected
  end;
  TDAVMkColOutput = class(TXmlOutput)
  protected
    function HandleXMLRequest(aDocument : TXMLDocument) : Boolean;override;
  end;
  TDAVDeleteOutput = class(TXmlOutput)
  protected
    function HandleXMLRequest(aDocument : TXMLDocument) : Boolean;override;
  end;
}
implementation
{
uses lHTTPUtil,lMimeTypes,Base64;

procedure TFileStreamOutput.DoneInput;
var
  FModified : TDateTime;
  FMimeType,FeTag : string;
begin
  TLHTTPServerSocket(FSocket).FResponseInfo.Status:=hsNotFound;
  if Assigned(Event) then
    if Event(HTTPDecode(TLHTTPServerSocket(FSocket).FRequestInfo.Argument),FStream,FModified,FMimeType,FEtag) then
      begin
        TLHTTPServerSocket(FSocket).FResponseInfo.Status:=hsOK;
        TLHTTPServerSocket(FSocket).FHeaderOut.ContentLength := FStream.Size;
        TLHTTPServerSocket(FSocket).FResponseInfo.LastModified:=LocalTimeToGMT(FModified);
      end;
  FStream.Position:=0;
  TLHTTPServerSocket(FSocket).StartResponse(Self);
end;
function TFileStreamInput.HandleInput(ABuffer: pchar; ASize: integer
  ): integer;
begin
  Result := FStream.Write(ABuffer^,ASize);
end;

procedure TFileStreamInput.DoneInput;
var
  FeTag : string;
  FStatus: TLHTTPStatus;
begin
  TLHTTPServerSocket(FSocket).FResponseInfo.Status:=hsNotAllowed;
  FStatus := hsOK;
  if Assigned(Event) then
    if Event(HTTPDecode(TLHTTPServerSocket(FSocket).FRequestInfo.Argument),FStream,FeTag,FStatus) then
      TLHTTPServerSocket(FSocket).FResponseInfo.Status:=FStatus;
  TMemoryStream(FStream).Clear;
  TLHTTPServerSocket(FSocket).StartResponse(Self);
end;
constructor TLWebDAVFileHandler.Create;
begin
  Methods := [hmHead, hmGet, hmPost, hmPut];
end;
function TLWebDAVFileHandler.HandleURI(ASocket: TLHTTPServerSocket
  ): TOutputItem;
begin
  Result := nil;
  case ASocket.FRequestInfo.RequestType of
  hmHead,hmGet:
    begin
      if Assigned(TLWebDAVServer(ASocket.Creator).OnReadAllowed)
      and (not TLWebDAVServer(ASocket.Creator).OnReadAllowed(HTTPDecode(TLHTTPServerSocket(ASocket).FRequestInfo.Argument))) then
        begin
          ASocket.FResponseInfo.Status:=hsUnauthorized;
          exit;
        end;
      Result := TFileStreamOutput.Create(ASocket,TmemoryStream.Create,True);
      TFileStreamOutput(Result).Event:=TLWebDAVServer(ASocket.Creator).FGet;
    end;
  hmPut:
    begin
      if Assigned(TLWebDAVServer(ASocket.Creator).OnWriteAllowed)
      and (not TLWebDAVServer(ASocket.Creator).OnWriteAllowed(HTTPDecode(TLHTTPServerSocket(ASocket).FRequestInfo.Argument))) then
        begin
          ASocket.FResponseInfo.Status:=hsUnauthorized;
          exit;
        end;
      Result := TFileStreamInput.Create(ASocket,TmemoryStream.Create,True);
      TFileStreamInput(Result).Event:=TLWebDAVServer(ASocket.Creator).FPut;
    end;
  hmPost:
    begin
      if Assigned(TLWebDAVServer(ASocket.Creator).OnWriteAllowed)
      and (not TLWebDAVServer(ASocket.Creator).OnWriteAllowed(HTTPDecode(TLHTTPServerSocket(ASocket).FRequestInfo.Argument))) then
        begin
          ASocket.FResponseInfo.Status:=hsUnauthorized;
          exit;
        end;
      Result := TFileStreamInput.Create(ASocket,TmemoryStream.Create,True);
      TFileStreamInput(Result).Event:=TLWebDAVServer(ASocket.Creator).FPost;
    end;
  end;
end;
function TDAVDeleteOutput.HandleXMLRequest(aDocument: TXMLDocument): Boolean;
begin
  Result := False;
  if Assigned(TLWebDAVServer(FSocket.Creator).OnDelete) then
    Result := TLWebDAVServer(FSocket.Creator).OnDelete(HTTPDecode(TLHTTPServerSocket(FSocket).FRequestInfo.Argument));
end;
function TDAVMkColOutput.HandleXMLRequest(aDocument: TXMLDocument): Boolean;
begin
  Result := False;
  if Assigned(TLWebDAVServer(FSocket.Creator).OnMkCol) then
    Result := TLWebDAVServer(FSocket.Creator).OnMkCol(HTTPDecode(TLHTTPServerSocket(FSocket).FRequestInfo.Argument));
end;

function TDAVOptionsOutput.HandleXMLRequest(aDocument: TXMLDocument): Boolean;
var
  aOptionsRes: TDOMElement;
  tmp: DOMString = 'D:options';
  aActivityCollection: TDOMElement = nil;
  aHref: TDOMElement;
  aDirList : TLDirectoryList;
  Path: string;
  aDepth: Integer;
  aUser: string;
begin
  Result := False;
  if FSocket.Parameters[hpAuthorization] <> '' then
    begin
      aUser := FSocket.Parameters[hpAuthorization];
      aUser := DecodeStringBase64(copy(aUser,pos(' ',aUser)+1,length(aUser)));
      if Assigned(TLWebDAVServer(FSocket.Creator).OnUserLogin) then
        TLWebDAVServer(FSocket.Creator).OnUserLogin(copy(aUser,0,pos(':',aUser)-1),copy(aUser,pos(':',aUser)+1,length(aUser)));
    end;
  aOptionsRes := aDocument.CreateElementNS('DAV:','D:options-response');
  if Assigned(aDocument.DocumentElement) then
    aActivityCollection := TDOMElement(aDocument.DocumentElement.FirstChild);
  if not Assigned(aActivityCollection) then
    aActivityCollection := aDocument.CreateElement('D:activity-collection-set');
  aOptionsRes.AppendChild(aActivityCollection);
  aHref := aDocument.CreateElement('D:href');
  Path := TLHTTPServerSocket(FSocket).FRequestInfo.Argument;
  if copy(Path,0,1) <> '/' then Path := '/'+Path;
  if pos('trunk',Path) > 0 then
    Path := StringReplace(Path,'trunk','!svn/act',[]);
  aDepth := StrToIntDef(TLHTTPServerSocket(FSocket).Parameters[hpDepth],0);
  if Assigned(TLWebDAVServer(FSocket.Creator).OnGetDirectoryList) then
    Result := TLWebDAVServer(FSocket.Creator).OnGetDirectoryList(Path,aDepth,aDirList)
  else Result:=True;

  aHRef.AppendChild(aDocument.CreateTextNode(Path));
  aActivityCollection.AppendChild(aHref);
  if Assigned(aDocument.DocumentElement) then
    aDocument.DocumentElement.Free;
  aDocument.AppendChild(aOptionsRes);
  TLHTTPServerSocket(FSocket).FResponseInfo.Status:=hsOK;
  if Assigned(TLWebDAVServer(FSocket.Creator).OnReadAllowed) and (not TLWebDAVServer(FSocket.Creator).OnReadAllowed(Path)) then
    begin
      TLHTTPServerSocket(FSocket).FResponseInfo.Status:=hsUnauthorized;
      AppendString(TLHTTPServerSocket(FSocket).FHeaderOut.ExtraHeaders, 'WWW-Authenticate: Basic realm="Promet-ERP"'+#13#10);
      Result := True;
    end;
end;
function TDAVFindPropOutput.HandleXMLRequest(aDocument: TXMLDocument): Boolean;
var
  tmp: DOMString;
  aMSRes: TDOMElement;
  Path: string;
  aDirList : TLDirectoryList = nil;
  i: Integer;
  pfNode: TDOMElement;
  aNs : string = 'DAV:';
  aPrefix : string = 'D';
  aProperties: TStringList;
  aPropNode: TDOMElement;
  aUser: String;
  aDepth: Integer;
  tmp1: DOMString;
  a: Integer;
  Attr: TDOMNode;
  aAttrPrefix: String;
  aLocalName,aNSName: String;
  Attr1: TDOMAttr;
  tmp2: DOMString;

  function AddNS(anPrefix,aNS : string) : string;
  var
    a : Integer;
    aFound: Boolean;
  begin
    aFound:=False;
    for a := 0 to aDocument.DocumentElement.Attributes.Length-1 do
      begin
        Attr := aDocument.DocumentElement.Attributes[a];
        aAttrPrefix := copy(Attr.NodeName,0,pos(':',Attr.NodeName)-1);
        aLocalName := copy(Attr.NodeName,pos(':',Attr.NodeName)+1,length(Attr.NodeName));
        aNSName := Attr.NodeValue;
        if (aAttrPrefix = 'xmlns') and (aNSName=aNS) then
          begin
            aFound:=True;
            Result := aLocalName;
            exit;
          end;
      end;
    if not aFound then
      begin
        Attr := TDomElement(aDocument.DocumentElement).OwnerDocument.CreateAttribute('xmlns:'+anPrefix);
        Attr.NodeValue:=aNS;
        aDocument.DocumentElement.Attributes.setNamedItem(Attr);
        Result := anPrefix;
        writeln('New NS:'+anPrefix+'='+aNS);
      end;
  end;
  procedure CreateResponse(aPath : string;aParent : TDOMElement;Properties : TStrings;ns : string = 'DAV:';prefix : string = 'D';aFile : TLFile = nil);
  var
    aResponse: TDOMElement;
    aHref: TDOMElement;
    aPropStat: TDOMElement;
    aStatus: TDOMElement;
    aPropC: TDOMElement;
    aProp: TDOMElement;
    a: Integer;
    aLock: TDOMElement;
    aLockEntry: TDOMElement;
    aNotFoundProp : TStrings;
    aPropD: TDOMNode;
    aPropE: TDOMNode;
    aPropF: TDOMNode;
    b: Integer;
    aPropG: TDOMNode;
    bPrefix: String;
    function FindProp(aprop : string) : Integer;
    var
      b : Integer;
    begin
      b := 0;
      while b < aNotFoundProp.Count do
        begin
          if pos(lowercase(aProp),lowercase(aNotFoundProp.Names[b])) > 0 then
            begin
              Result := b;
              exit;
            end
          else inc(b);
        end;
      Result := -1;
    end;
    procedure RemoveProp(aProp : string);
    var
      b : Integer;
    begin
      b := 0;
      while b < aNotFoundProp.Count do
        begin
          if pos(lowercase(aProp),lowercase(aNotFoundProp.Names[b])) > 0 then
            aNotFoundProp.Delete(b)
          else inc(b);
        end;
    end;
  begin
    writeln('CreateResponse:'+aPath+' '+prefix);
    aNotFoundProp := TStringList.Create;
    aNotFoundProp.AddStrings(Properties);
    aResponse := aDocument.CreateElement(prefix+':response');
    aParent.AppendChild(aResponse);
    aHref := aDocument.CreateElement(prefix+':href');
    RemoveProp(':href');
    aResponse.AppendChild(aHref);
    if not (Assigned(aFile) and (not aFile.IsDir)) then
      if copy(aPath,length(aPath),1) <> '/' then aPath := aPath+'/';
    aHRef.AppendChild(aDocument.CreateTextNode(aPath));
    aPropStat := aDocument.CreateElement(prefix+':propstat');
    aResponse.AppendChild(aPropStat);
    aProp := aDocument.CreateElement(prefix+':'+'prop');
    aPropStat.AppendChild(aProp);
    if Assigned(aFile) then
      begin
        aPropC := nil;
        if (FindProp(':resourcetype') > -1)  then
          begin
            tmp := aNotFoundProp.ValueFromIndex[FindProp(':resourcetype')];
            aPropC := aDocument.CreateElement(tmp);
            RemoveProp(prefix+':resourcetype');
            aProp.AppendChild(aPropC);
          end;
        if aFile.IsCalendar then
          begin
            if (FindProp(':owner') > -1)  then
              begin
                aPropD := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(':owner')]);
                aProp.AppendChild(apropD);
                aHref := aDocument.CreateElement(prefix+':href');
                aPropD.AppendChild(aHref);
                aHRef.AppendChild(aDocument.CreateTextNode(aPath+'user/'));
                RemoveProp(':owner');
              end;
            if (FindProp(':current-user-principal') > -1)  then
              begin
                aPropD := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(':current-user-principal')]);
                aProp.AppendChild(apropD);
                aHref := aDocument.CreateElement(prefix+':href');
                aPropD.AppendChild(aHref);
                aHRef.AppendChild(aDocument.CreateTextNode(aPath+'user/'));
                RemoveProp(':current-user-principal');
              end;
            if (FindProp(':calendar-user-address-set') > -1)  then
              begin
                aPropD := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(':calendar-user-address-set')]);
                aProp.AppendChild(apropD);
                aHref := aDocument.CreateElement(prefix+':href');
                aPropD.AppendChild(aHref);
                aHRef.AppendChild(aDocument.CreateTextNode(aPath+'user/'));
                RemoveProp(':calendar-user-address-set');
              end;
            if (FindProp(':calendar-home-set') > -1) then
              begin
                tmp := aNotFoundProp.ValueFromIndex[FindProp(':calendar-home-set')];
                AddNS(copy(tmp,0,pos(':',tmp)-1),'urn:ietf:params:xml:ns:caldav');
                aPropD := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(':calendar-home-set')]);
                aProp.AppendChild(apropD);
                aHref := aDocument.CreateElement(prefix+':href');
                aPropD.AppendChild(aHref);
                aHRef.AppendChild(aDocument.CreateTextNode(aFile.CalendarHomeSet));
                RemoveProp(':calendar-home-set');
              end;

            if (aFile.UserAdressSet.Count>0) and (FindProp(':calendar-user-address-set') > -1) then
              begin
                tmp := aNotFoundProp.ValueFromIndex[FindProp(':calendar-user-address-set')];
                AddNS(copy(tmp,0,pos(':',tmp)-1),'urn:ietf:params:xml:ns:caldav');
                aPropD := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(':calendar-user-address-set')]);
                aProp.AppendChild(apropD);
                for b := 0 to aFile.UserAdressSet.Count-1 do
                  begin
                    aHref := aDocument.CreateElement(prefix+':href');
                    aPropD.AppendChild(aHref);
                    aHRef.AppendChild(aDocument.CreateTextNode(aFile.UserAdressSet[b]));
                  end;
                RemoveProp(':calendar-user-address-set');
              end;
            if FindProp(':schedule-inbox-URL') > -1  then
              begin
                tmp := aNotFoundProp.ValueFromIndex[FindProp(':schedule-inbox-URL')];
                AddNS(copy(tmp,0,pos(':',tmp)-1),'urn:ietf:params:xml:ns:caldav');
                aPropD := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(':schedule-inbox-URL')]);
                aProp.AppendChild(apropD);
                aHref := aDocument.CreateElement(prefix+':href');
                aPropD.AppendChild(aHref);
                aHRef.AppendChild(aDocument.CreateTextNode(aPath+'outbox/'));
                RemoveProp(':schedule-inbox-URL');
              end;
            if FindProp(':schedule-outbox-URL') > -1  then
              begin
                tmp := aNotFoundProp.ValueFromIndex[FindProp(':schedule-outbox-URL')];
                AddNS(copy(tmp,0,pos(':',tmp)-1),'urn:ietf:params:xml:ns:caldav');
                aPropD := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(':schedule-outbox-URL')]);
                aProp.AppendChild(apropD);
                aHref := aDocument.CreateElement(prefix+':href');
                aPropD.AppendChild(aHref);
                aHRef.AppendChild(aDocument.CreateTextNode(aPath+'inbox/'));
                RemoveProp(':schedule-outbox-URL');
              end;

            if not aFile.IsCalendarUser then
              begin
                if Assigned(aPropC) then
                  aPropC.AppendChild(aDocument.CreateElement(AddNS('C','urn:ietf:params:xml:ns:caldav')+':calendar'));
                if FindProp(':supported-report-set') > -1 then
                  begin
                    aPropD := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(':supported-report-set')]);
                    bPrefix := copy(aPropD.NodeName,0,pos(':',aPropD.NodeName)-1);
                    aProp.AppendChild(aPropD);
                    aPropE := aPropD.AppendChild(aDocument.CreateElement(prefix+':supported-report'));
                    aPropF := aPropE.AppendChild(aDocument.CreateElement(prefix+':report'));
                    aPropG := aPropF.AppendChild(aDocument.CreateElement(bPrefix+':calendar-multiget'));
                    RemoveProp(':supported-report-set');
                  end;
                if FindProp(':current-user-privilege-set') > -1 then
                  begin
                    tmp := aNotFoundProp.ValueFromIndex[FindProp(':current-user-privilege-set')];
                    aPropD := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(':current-user-privilege-set')]);
                    aProp.AppendChild(aPropD);
                    aPropE := aPropD.AppendChild(aDocument.CreateElement(prefix+':privilege'));
                    aPropF := aPropE.AppendChild(aDocument.CreateElement(prefix+':read'));
                    aPropE := aPropD.AppendChild(aDocument.CreateElement(prefix+':privilege'));
                    aPropF := aPropE.AppendChild(aDocument.CreateElement(prefix+':read-acl'));
                    aPropE := aPropD.AppendChild(aDocument.CreateElement(prefix+':privilege'));
                    aPropF := aPropE.AppendChild(aDocument.CreateElement(prefix+':read-current-user-privilege-set'));
                    aPropE := aPropD.AppendChild(aDocument.CreateElement(prefix+':privilege'));
                    aPropF := aPropE.AppendChild(aDocument.CreateElement(prefix+':write'));
                    aPropE := aPropD.AppendChild(aDocument.CreateElement(prefix+':privilege'));
                    aPropF := aPropE.AppendChild(aDocument.CreateElement(prefix+':write-acl'));
                    RemoveProp(':current-user-privilege-set');
                  end;
                if FindProp(':supported-calendar-component-set') > -1 then
                  begin
                    tmp := aNotFoundProp.ValueFromIndex[FindProp(':supported-calendar-component-set')];
                    AddNS(copy(tmp,0,pos(':',tmp)-1),'urn:ietf:params:xml:ns:caldav');
                    aPropD := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(':supported-calendar-component-set')]);
                    aProp.AppendChild(aPropD);
                    aPropE := aPropD.AppendChild(aDocument.CreateElement(aPrefix+':comp'));
                    TDOMElement(aPropE).SetAttribute('name','VEVENT');
                    if aFile.IsTodoList then
                      begin
                        aPropE := aPropD.AppendChild(aDocument.CreateElement(aPrefix+':comp'));
                        TDOMElement(aPropE).SetAttribute('name','VTODO');
                      end;
                    RemoveProp(':supported-calendar-component-set');
                  end;
              end;
          end;
        if aFile.IsDir then
          begin
            if Assigned(aPropC) then
              aPropC.AppendChild(aDocument.CreateElement(prefix+':collection'));
            if not aFile.IsCalendar then
              begin
                if (FindProp('getcontenttype') > -1)  then
                  begin
                    aPropC := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp('getcontenttype')]);
                    RemoveProp('getcontenttype');
                    aPropC.AppendChild(aDocument.CreateTextNode('httpd/unix-directory'));
                    aProp.AppendChild(apropC);
                  end;
              end;
          end;
        for a := 0 to aFile.Properties.Count-1 do
          begin
            if (FindProp(aFile.Properties.Names[a]) > -1) then
              begin
                if (aFile.Properties.Names[a] = 'getcontenttype')
                then
                  aPropC := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(aFile.Properties.Names[a])])
                else if pos(':',aFile.Properties.Names[a])=-1 then
                  aPropC := aDocument.CreateElement(prefix+':'+aFile.Properties.Names[a])
                else
                  begin
                    tmp := aNotFoundProp.ValueFromIndex[FindProp(aFile.Properties.Names[a])];
                    case copy(aFile.Properties.Names[a],0,pos(':',aFile.Properties.Names[a])-1) of
                    'C':
                      begin
                        AddNS(copy(tmp,0,pos(':',tmp)-1),'urn:ietf:params:xml:ns:caldav');
                        aPropC := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(aFile.Properties.Names[a])]);
                      end;
                    'CS':
                      begin
                        AddNS(copy(tmp,0,pos(':',tmp)-1),'http://calendarserver.org/ns/');
                        aPropC := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(aFile.Properties.Names[a])]);
                      end;
                    else
                      aPropC := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(aFile.Properties.Names[a])]);
                    end;
                  end;
                RemoveProp(aFile.Properties.Names[a]);
                aPropC.AppendChild(aDocument.CreateTextNode(aFile.Properties.ValueFromIndex[a]));
                aProp.AppendChild(aPropC);
              end;
          end;
      end
    else //root dir
      begin
        if (FindProp(':getcontenttype') > -1)  then
          begin
            aPropC := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(':getcontenttype')]);
            aPropC.AppendChild(aDocument.CreateTextNode('httpd/unix-directory'));
            aProp.AppendChild(apropC);
          end;
        if (FindProp('resourcetype') > -1)  then
          begin
            aPropC := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp('resourcetype')]);
            RemoveProp('resourcetype');
            aProp.AppendChild(aPropC);
            aPropC.AppendChild(aDocument.CreateElement(prefix+':collection'));
          end;
      end;
    if (FindProp(':supportedlock') > -1)  then
      begin
        aLock := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(':supportedlock')]);
        aLockEntry := aDocument.CreateElement(prefix+':lockentry');
        aLock.AppendChild(aLockEntry);
        aLockEntry.AppendChild(aDocument.CreateElement(prefix+':lockscope').AppendChild(aDocument.CreateElement(prefix+':exclusive')));
        aLockEntry.AppendChild(aDocument.CreateElement(prefix+':locktype').AppendChild(aDocument.CreateElement(prefix+':write')));
        aProp.AppendChild(aLock);
      end;
    aStatus := aDocument.CreateElement(prefix+':status');
    aPropStat.AppendChild(aStatus);
    aStatus.AppendChild(aDocument.CreateTextNode(BuildStatus(hsOK)));
    if aNotFoundProp.Count>0 then
      begin
        aPropStat := aDocument.CreateElement(prefix+':propstat');
        aResponse.AppendChild(aPropStat);
        aProp := aDocument.CreateElement(prefix+':'+'prop');
        aPropStat.AppendChild(aProp);
        for a := 0 to aNotFoundProp.Count-1 do
          begin
            if FindProp(aNotFoundProp.ValueFromIndex[a])>-1 then
              tmp := aNotFoundProp.ValueFromIndex[FindProp(aNotFoundProp.ValueFromIndex[a])]
            else tmp := '';
            case copy(aNotFoundProp.ValueFromIndex[a],0,pos(':',aNotFoundProp.ValueFromIndex[a])-1) of
            'C':
              begin
                AddNS(copy(tmp,0,pos(':',tmp)-1),'urn:ietf:params:xml:ns:caldav');
                aPropC := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[a]);
              end;
            'CS':
              begin
                AddNS(copy(tmp,0,pos(':',tmp)-1),'http://calendarserver.org/ns/');
                aPropC := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[a]);
              end;
            else
              aPropC := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[a]);
            end;
            aProp.AppendChild(aPropC);
            writeln('Property not found:'+aNotFoundProp.ValueFromIndex[a]);
          end;
        aStatus := aDocument.CreateElement(prefix+':status');
        aPropStat.AppendChild(aStatus);
          aStatus.AppendChild(aDocument.CreateTextNode(BuildStatus(hsNotFound)));
      end;
    aNotFoundProp.Free;
  end;

begin
  Result := False;
  writeln('***PROPFIND:'+HTTPDecode(TLHTTPServerSocket(FSocket).FRequestInfo.Argument));
  aProperties := TStringList.Create;
  if FSocket.Parameters[hpAuthorization] <> '' then
    begin
      aUser := FSocket.Parameters[hpAuthorization];
      aUser := DecodeStringBase64(copy(aUser,pos(' ',aUser)+1,length(aUser)));
      if Assigned(TLWebDAVServer(FSocket.Creator).OnUserLogin) then
        TLWebDAVServer(FSocket.Creator).OnUserLogin(copy(aUser,0,pos(':',aUser)-1),copy(aUser,pos(':',aUser)+1,length(aUser)));
    end;
  if Assigned(aDocument.DocumentElement) then
    begin
      if trim(copy(aDocument.DocumentElement.NodeName,0,pos(':',aDocument.DocumentElement.NodeName)-1)) <> '' then
        aPrefix := trim(copy(aDocument.DocumentElement.NodeName,0,pos(':',aDocument.DocumentElement.NodeName)-1));
      aMSRes := aDocument.CreateElement(aPrefix+':multistatus');
      for a := 0 to aDocument.DocumentElement.Attributes.Length-1 do
        begin
          Attr := aDocument.DocumentElement.Attributes[a];
          aAttrPrefix := copy(Attr.NodeName,0,pos(':',Attr.NodeName)-1);
          aLocalName := copy(Attr.NodeName,pos(':',Attr.NodeName)+1,length(Attr.NodeName));
          aNSName := Attr.NodeValue;
          if (aAttrPrefix = 'xmlns') and (aLocalName<>'') then
            begin
              Attr1 := aDocument.DocumentElement.OwnerDocument.CreateAttribute('xmlns:'+aLocalName);
              Attr1.NodeValue:=aNSName;
              aMSRes.Attributes.setNamedItem(Attr1);
              writeln('Old NS:'+aLocalName+'='+aNSName);
            end;
        end;
      aPropNode := TDOMElement(aDocument.DocumentElement.FirstChild);
      for i := 0 to aPropNode.ChildNodes.Count-1 do
        begin
          tmp := aPropNode.ChildNodes.Item[i].NodeName;
          tmp := copy(tmp,pos(':',tmp)+1,length(tmp));
          tmp1 := copy(aPropNode.ChildNodes.Item[i].NodeName,0,pos(':',aPropNode.ChildNodes.Item[i].NodeName)-1);
          if aPropNode.ChildNodes.Item[i].NamespaceURI<>'' then
            tmp := aPropNode.ChildNodes.Item[i].NamespaceURI+':'+tmp
          else
            begin
              if pos(':',tmp)=0 then
                tmp := tmp1+':'+tmp;
            end;
          aProperties.Values[lowercase(tmp)]:=aPropNode.ChildNodes.Item[i].NodeName;
          writeln('Wanted:'+tmp+'='+aPropNode.ChildNodes.Item[i].NodeName);
        end;
      aDocument.DocumentElement.Free;
    end
  else
    aMSRes := aDocument.CreateElement(aPrefix+':multistatus');
  aDocument.AppendChild(aMSRes);
  Path := HTTPDecode(TLHTTPServerSocket(FSocket).FRequestInfo.Argument);
  if copy(Path,0,1) <> '/' then Path := '/'+Path;
  aDepth := StrToIntDef(TLHTTPServerSocket(FSocket).Parameters[hpDepth],0);
  if Assigned(TLWebDAVServer(FSocket.Creator).OnGetDirectoryList) then
    Result := TLWebDAVServer(FSocket.Creator).OnGetDirectoryList(Path,aDepth,aDirList)
  else Result:=True;
  if Assigned(aDirList) and (aDirList.Count > 0) then
    begin
      Createresponse(Path,aMSres,aProperties,aNS,aPrefix);
      if copy(Path,length(Path),1) <> '/' then
        Path := Path+'/';
      for i := 0 to aDirList.Count-1 do
        begin
          if aDirList[i].Path='' then
            Createresponse(Path+aDirList[i].Name,aMSres,aProperties,aNs,aPrefix,aDirList[i])
          else
            Createresponse(aDirList[i].Path+'/'+aDirList[i].Name,aMSres,aProperties,aNs,aPrefix,aDirList[i]);
        end;
    end
  else if Assigned(aDirList) and (aDirList is TLFile) then
    begin
      Createresponse(Path,aMSres,aProperties,aNs,aPrefix,TLFile(aDirList));
    end;
  TLHTTPServerSocket(FSocket).FResponseInfo.Status:=hsMultiStatus;
  if Assigned(TLWebDAVServer(FSocket.Creator).OnReadAllowed) and (not TLWebDAVServer(FSocket.Creator).OnReadAllowed(Path)) then
    begin
      TLHTTPServerSocket(FSocket).FResponseInfo.Status:=hsUnauthorized;
      AppendString(TLHTTPServerSocket(FSocket).FHeaderOut.ExtraHeaders, 'WWW-Authenticate: Basic realm="Promet-ERP"'+#13#10);
      Result := True;
    end;
  aProperties.Free;
end;
constructor TXmlOutput.Create(ASocket: TLHTTPSocket);
begin
  ADoc := TXMLDocument.Create;
  FIn := TStringStream.Create('');
  FOut := TMemoryStream.Create;
  inherited Create(ASocket, FOut, False);
end;
procedure TXmlOutput.DoneInput;
var
  tmp: String;
begin
  FIn.Position:=0;
  try
    if Fin.DataString <> '' then
      ReadXMLFile(ADoc,FIn);
  except
  end;
  FOut.Clear;
  if HandleXMLRequest(ADoc) then
    begin
      WriteXML(ADoc,FOut);
      Self.FBufferSize := FOut.Size;
      FOut.Position:=0;
      TLHTTPServerSocket(FSocket).FHeaderOut.ContentLength := FOut.Size;
      TLHTTPServerSocket(FSocket).Startmemoryresponse(TMemoryOutput(Self));
    end
  else
    begin
      TLHTTPServerSocket(FSocket).FHeaderOut.ContentLength := 0;
      TLHTTPServerSocket(FSocket).FResponseInfo.Status:=hsForbidden;
      FOut.Clear;
      TLHTTPServerSocket(FSocket).Startmemoryresponse(TMemoryOutput(Self));
    end;
end;
function TXmlOutput.HandleInput(ABuffer: pchar; ASize: integer): integer;
begin
  FIn.WriteString(ABuffer);
  Result := ASize;
end;
destructor TXmlOutput.Destroy;
begin
  FIn.Free;
  FOut.Free;
  inherited Destroy;
end;
function TLWebDAVURIHandler.HandleURI(ASocket: TLHTTPServerSocket
  ): TOutputItem;
  procedure AddDAVheaders;
  begin
    AppendString(ASocket.FHeaderOut.ExtraHeaders, 'DAV: 1,2, access-control, calendar-access'+#13#10);
    AppendString(ASocket.FHeaderOut.ExtraHeaders, 'DAV: <http://apache.org/dav/propset/fs/1>'+#13#10);
    AppendString(ASocket.FHeaderOut.ExtraHeaders, 'MS-Author-Via: DAV'+#13#10);
    AppendString(ASocket.FHeaderOut.ExtraHeaders, 'Vary: Accept-Encoding'+#13#10);
  end;
begin
  ASocket.FResponseInfo.ContentType:='text/xml';
  ASocket.FResponseInfo.ContentCharset:='utf-8';
  Result := nil;
  if ASocket.FRequestInfo.RequestType = hmOptions then
    begin
      AddDAVheaders;
      AppendString(ASocket.FHeaderOut.ExtraHeaders,'DAV: version-control,checkout,working-resource'+#13#10);
      AppendString(ASocket.FHeaderOut.ExtraHeaders,'DAV: 1, calendar-access, calendar-schedule, calendar-proxy'+#13#10);
      AppendString(ASocket.FHeaderOut.ExtraHeaders,'allow: GET, HEAD, POST, OPTIONS, MKCOL, DELETE, PUT, LOCK, UNLOCK, COPY, MOVE, PROPFIND, SEARCH, REPORT, MKCALENDAR, ACL'+#13#10);
      Result := TDAVOptionsOutput.Create(ASocket);
    end
  else if ASocket.FRequestInfo.RequestType = hmReport then
    begin
      AddDAVheaders;
      AppendString(ASocket.FHeaderOut.ExtraHeaders,'DAV: version-control,checkout,working-resource'+#13#10);
      AppendString(ASocket.FHeaderOut.ExtraHeaders,'allow: GET, HEAD, POST, OPTIONS, MKCOL, DELETE, PUT, LOCK, UNLOCK, COPY, MOVE, PROPFIND, SEARCH, REPORT, MKCALENDAR, ACL'+#13#10);
      Result := TDAVReportOutput.Create(ASocket);
    end
  else if ASocket.FRequestInfo.RequestType = hmPropFind then
    begin
      AddDAVheaders;
      Result := TDAVFindPropOutput.Create(ASocket);
    end
  else if (ASocket.FRequestInfo.RequestType = hmLock)
       or (ASocket.FRequestInfo.RequestType = hmUnLock) then
    begin
      AddDAVheaders;
      Result := TDAVLockOutput.Create(ASocket);
    end
  else if (ASocket.FRequestInfo.RequestType = hmMkCol) then
    begin
      AddDAVheaders;
      Result := TDAVMkColOutput.Create(ASocket);
    end
  else if (ASocket.FRequestInfo.RequestType = hmDelete) then
    begin
      AddDAVheaders;
      Result := TDAVDeleteOutput.Create(ASocket);
    end
  ;
  if Assigned(Result) then
    begin
      try
        ASocket.FResponseInfo.ContentType := ASocket.FResponseInfo.ContentType;
      finally
      end;
    end;
end;
function TLWebDAVURIHandler.CreateDocument(ASocket: TLHTTPServerSocket;
  var ContentType: String): TXMLDocument;
begin
  Result := TXMLDocument.Create;
//  Result.Encoding:='utf-8';
end;
procedure TLWebDAVURIHandler.DestroyDocument(ADocument: TXMLDocument);
begin
  if Assigned(ADocument) then
    ADocument.Free;
end;
}
function BuildStatus(aStatus: TLHTTPStatus): string;
begin
  Result := 'HTTP/1.1 '+IntToStr(HTTPStatusCodes[aStatus])+' '+HTTPTexts[aStatus];
end;

function DAVReportHandleXMLRequest(aDocument: TXMLDocument): Boolean;
var
  aProperties: TStringList;
  aUser: string;
  aPrefix: String;
  aItems: TStringList;
  aPropNode: TDOMElement;
  i: Integer;
  aMSRes: TDOMElement;
  aDepth: Integer;
  bProperties: TStringList;
  tmp: DOMString;
  tmp1: String;
  a: Integer;
  Attr: TDOMNode;
  aAttrPrefix: String;
  aLocalName: String;
  Attr1: TDOMAttr;
  aNSName: String;
  tmp2: DOMString;
  Path: string;
  aDirList : TLDirectoryList;
  aNode: TDOMNode;
  aFilter : string = '';

  procedure CreateResponse(aPath : string;aParent : TDOMElement;Properties : TStrings;ns : string = 'DAV:';prefix : string = 'D');
  var
    aResponse: TDOMElement;
    aHref: TDOMElement;
    aPropStat: TDOMElement;
    aStatus: TDOMElement;
    aPropC: TDOMElement;
    aProp: TDOMElement;
    a: Integer;
    aLock: TDOMElement;
    aLockEntry: TDOMElement;
    aNotFoundProp : TStrings;
    aPropD: TDOMNode;
    aPropE: TDOMNode;
    aPropF: TDOMNode;
    b: Integer;
    aPropG: TDOMNode;
    aStream : TStringStream;
    FLastModified : TDateTime;
    FMimeType,FeTag : string;
    function FindProp(aprop : string) : Integer;
    var
      b : Integer;
    begin
      b := 0;
      while b < aNotFoundProp.Count do
        begin
          if pos(lowercase(aProp),lowercase(aNotFoundProp.Names[b])) > 0 then
            begin
              Result := b;
              exit;
            end
          else inc(b);
        end;
      Result := -1;
    end;
    procedure RemoveProp(aProp : string);
    var
      b : Integer;
    begin
      b := 0;
      while b < aNotFoundProp.Count do
        begin
          if pos(lowercase(aProp),lowercase(aNotFoundProp.Names[b])) > 0 then
            aNotFoundProp.Delete(b)
          else inc(b);
        end;
    end;
  begin
    writeln('CreateResponse:'+aPath+' '+prefix);
    aNotFoundProp := TStringList.Create;
    aNotFoundProp.AddStrings(Properties);
    aResponse := aDocument.CreateElement(prefix+':response');
    aParent.AppendChild(aResponse);
    aHref := aDocument.CreateElement(prefix+':href');
    aResponse.AppendChild(aHref);
    aHRef.AppendChild(aDocument.CreateTextNode(aPath));
    aPropStat := aDocument.CreateElement(prefix+':propstat');
    aResponse.AppendChild(aPropStat);
    aProp := aDocument.CreateElement(prefix+':'+'prop');
    aPropStat.AppendChild(aProp);

    aStream := TStringStream.Create('');
    if Assigned(OnGetFile) then
      OnGetFile(aPath,aStream,FLastModified,FMimeType,FeTag);
    if (FindProp(':getetag') > -1) and (FeTag<>'')  then
      begin
        aPropC := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(':getetag')]);
        aPropC.AppendChild(aDocument.CreateTextNode(FeTag));
        aProp.AppendChild(apropC);
        removeProp(':getetag');
      end;
    if (FindProp(':calendar-data') > -1) and (aStream.DataString<>'')  then
      begin
        aPropC := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[FindProp(':calendar-data')]);
        aPropC.AppendChild(aDocument.CreateTextNode(aStream.DataString));
        aProp.AppendChild(apropC);
        removeProp(':calendar-data');
      end;

    aStream.Free;
    aStatus := aDocument.CreateElement(prefix+':status');
    aPropStat.AppendChild(aStatus);
    aStatus.AppendChild(aDocument.CreateTextNode(BuildStatus(hsOK)));
    if aNotFoundProp.Count>0 then
      begin
        aPropStat := aDocument.CreateElement(prefix+':propstat');
        aResponse.AppendChild(aPropStat);
        aProp := aDocument.CreateElement(prefix+':'+'prop');
        aPropStat.AppendChild(aProp);
        for a := 0 to aNotFoundProp.Count-1 do
          begin
            aPropC := aDocument.CreateElement(aNotFoundProp.ValueFromIndex[a]);
            aProp.AppendChild(aPropC);
            writeln('Property not found:'+aNotFoundProp.ValueFromIndex[a]);
          end;
        aStatus := aDocument.CreateElement(prefix+':status');
        aPropStat.AppendChild(aStatus);
        aStatus.AppendChild(aDocument.CreateTextNode(BuildStatus(hsNotFound)));
      end;
    aNotFoundProp.Free;
  end;
  procedure RecourseFilter(aNode : TDOMNode);
  var
    b: Integer;
  begin
    if pos(':vevent',lowercase(aNode.NodeName))>0 then

    for b := 0 to aNode.ChildNodes.Count-1 do
      RecourseFilter(aNode.ChildNodes[i]);
  end;

begin
  aProperties := TStringList.Create;
  bProperties := TStringList.Create;
  writeln('***REPORT:'+HTTPDecode(TLHTTPServerSocket(FSocket).FRequestInfo.Argument));
  aItems := TStringList.Create;
  if FSocket.Parameters[hpAuthorization] <> '' then
    begin
      aUser := FSocket.Parameters[hpAuthorization];
      aUser := DecodeStringBase64(copy(aUser,pos(' ',aUser)+1,length(aUser)));
      if Assigned(TLWebDAVServer(FSocket.Creator).OnUserLogin) then
        TLWebDAVServer(FSocket.Creator).OnUserLogin(copy(aUser,0,pos(':',aUser)-1),copy(aUser,pos(':',aUser)+1,length(aUser)));
    end;
  Path := TLHTTPServerSocket(FSocket).FRequestInfo.Argument;
  if copy(Path,0,1) <> '/' then Path := '/'+Path;
  if Assigned(aDocument.DocumentElement) then
    begin
      if trim(copy(aDocument.DocumentElement.FirstChild.NodeName,0,pos(':',aDocument.DocumentElement.FirstChild.NodeName)-1)) <> '' then
        aPrefix := trim(copy(aDocument.DocumentElement.FirstChild.NodeName,0,pos(':',aDocument.DocumentElement.NodeName)-1));
      aMSRes := aDocument.CreateElement(aPrefix+':multistatus');
      for a := 0 to aDocument.DocumentElement.Attributes.Length-1 do
        begin
          Attr := aDocument.DocumentElement.Attributes[a];
          aAttrPrefix := copy(Attr.NodeName,0,pos(':',Attr.NodeName)-1);
          aLocalName := copy(Attr.NodeName,pos(':',Attr.NodeName)+1,length(Attr.NodeName));
          aNSName := Attr.NodeValue;
          if (aAttrPrefix = 'xmlns') and (aLocalName<>'') then
            begin
              Attr1 := aDocument.DocumentElement.OwnerDocument.CreateAttribute('xmlns:'+aLocalName);
              Attr1.NodeValue:=aNSName;
              aMSRes.Attributes.setNamedItem(Attr1);
            end;
        end;
      aPropNode := TDOMElement(aDocument.DocumentElement.FindNode(aPrefix+':prop'));
      if Assigned(aPropNode) then
      for i := 0 to aPropNode.ChildNodes.Count-1 do
        begin
          tmp := aPropNode.ChildNodes.Item[i].NodeName;
          tmp := copy(tmp,pos(':',tmp)+1,length(tmp));
          tmp1 := copy(aPropNode.ChildNodes.Item[i].NodeName,0,pos(':',aPropNode.ChildNodes.Item[i].NodeName)-1);
          if aPropNode.ChildNodes.Item[i].NamespaceURI<>'' then
            tmp := aPropNode.ChildNodes.Item[i].NamespaceURI+':'+tmp
          else
            begin
              for a := 0 to aDocument.DocumentElement.Attributes.Length-1 do
                begin
                  Attr := aDocument.DocumentElement.Attributes[a];
                  aAttrPrefix := copy(Attr.NodeName,0,pos(':',Attr.NodeName)-1);
                  aLocalName := copy(Attr.NodeName,pos(':',Attr.NodeName)+1,length(Attr.NodeName));
                  if (aAttrPrefix = 'xmlns') and (aLocalName = tmp1) then
                    begin
                      case lowercase(Attr.NodeValue) of
                      'dav:':tmp := 'D:'+tmp;
                      'urn:ietf:params:xml:ns:caldav':tmp := 'C:'+tmp;
                      'http://calendarserver.org/ns/':tmp := 'CS:'+tmp;
                      end;
                    end;
                  if (aAttrPrefix = 'xmlns') then
                    begin
                      Attr1 := aDocument.DocumentElement.OwnerDocument.CreateAttribute('xmlns:'+aLocalName);
                      Attr1.Value:=Attr.NodeValue;
                      aMSRes.Attributes.setNamedItemNS(Attr1);
                    end;
                end;
              if pos(':',tmp)=0 then
                tmp := tmp1+':'+tmp;
            end;
          aProperties.Values[lowercase(tmp)]:=aPropNode.ChildNodes.Item[i].NodeName;
          writeln('Wanted:'+tmp+'='+aPropNode.ChildNodes.Item[i].NodeName);
        end;
      aPropNode := TDOMElement(aDocument.DocumentElement);
      for i := 0 to aPropNode.ChildNodes.Count-1 do
        begin
          tmp := aPropNode.ChildNodes.Item[i].NodeName;
          if pos(':href',lowercase(tmp)) > 0 then
            aItems.Add(aPropNode.ChildNodes.Item[i].FirstChild.NodeValue);
          if pos(':filter',lowercase(tmp)) > 0 then
            begin
              RecourseFilter(aPropNode.ChildNodes.Item[i]);
            end;
        end;
      if aItems.Count=0 then
        begin //we report all ??!
          aDirList := TLDirectoryList.Create;
          if TLWebDAVServer(TLWebDAVServerSocket(FSocket).Creator).FGetDirList(Path,1,aDirList) then
            for i := 0 to aDirList.Count-1 do
              begin
                aItems.Add(Path+aDirList[i].Name);
              end;
          aDirList.Free;
        end;
      aDocument.DocumentElement.Free;
    end
  else
    aMSRes := aDocument.CreateElement(aPrefix+':multistatus');
  aDocument.AppendChild(aMSRes);
  aDepth := StrToIntDef(TLHTTPServerSocket(FSocket).Parameters[hpDepth],0);
  for i := 0 to aItems.Count-1 do
    begin
      bProperties.Assign(aProperties);
      CreateResponse(aItems[i],aMSRes,bProperties);
    end;
  aProperties.Free;
  bProperties.Free;
  aItems.Free;
  TLHTTPServerSocket(FSocket).FResponseInfo.Status:=hsMultiStatus;
  Result:=True;
end;

function HandleDAVRequest(Sender : TObject;Method, URL: string;Headers : TStringList;Input,Output : TStream): Integer;
var
  ADoc: TXMLDocument;
begin
  Result := 500;
  try
    case Uppercase(Method) of //Plain Request
    'GET','PUT','POST':
      begin

      end
    else //XML Request
      begin
        ADoc := TXMLDocument.Create;
        try
          if Input.Size>0 then
            ReadXMLFile(ADoc,Input);
          case Uppercase(Method) of
          'OPTIONS':
            begin

            end;
          'PROPFIND':
            begin

            end;
          'REPORT':
            begin
              if DAVReportHandleXMLRequest(ADoc) then
                begin
                end;
            end;
          'LOCK','UNLOCK':
            begin

            end;
          'MKCOL':
            begin

            end;
          'DELETE':
            begin

            end;
          end;
        finally
          aDoc.Free;
        end;
      end;
    end;
  except
    on e : Exception do
      begin
        Result := 500;
      end;
  end;
end;

function TLDirectoryList.Get(Index: Integer): TLFile;
begin
  Result := TLFile(Items[Index]);
end;

procedure TLDirectoryList.Put(Index: Integer; AValue: TLFile);
begin
  Items[Index] := Pointer(AValue);
end;
constructor TLDirectoryList.Create;
begin
  inherited;
end;
destructor TLDirectoryList.Destroy;
var
  i: Integer;
begin
  for i := 0 to Count-1 do
    Files[i].Free;
  inherited Destroy;
end;

procedure TLFile.SetName(AValue: string);
begin
  if FName=AValue then Exit;
  FName:=AValue;
end;
constructor TLFile.Create(aName: string;aIsDir : Boolean = False);
begin
  inherited Create;
  FName := aName;
  FIsDir := aIsDir;
  FIsCal:=False;
  FIsTodo:=False;
  FProperties := TStringList.Create;
  FASet := TStringList.Create;
  FPath := '';
end;

destructor TLFile.Destroy;
begin
  FASet.Free;
  FProperties.Free;
  inherited Destroy;
end;


initialization
  uappserverhttp.RegisterHTTPHandler(@HandleDAVRequest);

end.

