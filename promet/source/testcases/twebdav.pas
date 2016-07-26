unit twebdav;

{$mode objfpc}{$H+}

//Checks according to http://sabre.io/dav/building-a-caldav-client/

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,udavserver,
  Sockets,uhttputil,uprometdavserver,uData;

type

  { TWebDAVTest }

  TWebDAVTest= class(TTestCase)
  private
    function SendRequest(aRequest: string): string;
  published
    procedure SetUp; override;
    procedure PropfindRoot;
    procedure FindPrincipal;
    procedure FindPrincipalOnWellKnown;
    procedure FindPrincipalCalendarHome;
    procedure FindPrincipalCalendars;
    procedure CheckNamespaceUsage;
    procedure AddEvent;
    procedure CheckReportWithoutRequest;
    procedure CheckReport2;
    procedure CheckOptionsSubPath;
    procedure CheckPropfindImplicitAllProp;
    procedure CheckPropfindAllprop;
    procedure MkCol;
  end;

  { TestSocket }

  TestSocket = class(TDAVSession)
  public
  end;

implementation

var
  Socket : TestSocket;
  aReq : TStringList;
  Server : TWebDAVMaster;
  ServerFunctions: TPrometServerFunctions;
  UserURL,UserCalenderURL : string;

{ TestSocket }

function TWebDAVTest.SendRequest(aRequest: string): string;
var
  aURL, tmp: String;
  aInStream: TMemoryStream;
  aOutStream: TMemoryStream;
  aHeader: TStringList;
begin
  aReq.Text:=aRequest;
  aURL := aReq[0];
  aReq.Delete(0);
  aHeader := TStringList.Create;
  aHeader.Clear;
  while (aReq.Count>0) and (aReq[0]<>'') do
    begin
      aHeader.Add(aReq[0]);
      aReq.Delete(0);
    end;
  if aReq.Count>0 then
    aReq.Delete(0);
  tmp := copy(aURL,pos(' ',aURL)+1,length(aURL));
  tmp := trim(copy(tmp,0,pos('HTTP',tmp)-1));
  aInStream := TMemoryStream.Create;
  aOutStream := TMemoryStream.Create;
  aReq.SaveToStream(aInStream);
  aInStream.Position:=0;
  Socket.ProcessHttpRequest(copy(aURL,0,pos(' ',aURL)-1),tmp,aHeader,aInStream,aOutStream);
  Result := IntToStr(Socket.Status)+LineEnding+MemoryStreamToString(aOutStream);
  aInStream.Free;
  aOutStream.Free;
  aHeader.Free;
end;
procedure TWebDAVTest.SetUp;
begin
  inherited SetUp;
  aReq := TStringList.Create;
  Server := TWebDAVMaster.Create;
  Socket := TestSocket.Create(Server,TStringList.Create);
  Socket.User:=Data.Users.Id.AsString;
  Data.Users.Locate('NAME','Administrator',[]);
  ServerFunctions := TPrometServerFunctions.Create;
  Server.OnGetDirectoryList:=@ServerFunctions.ServerGetDirectoryList;
  Server.OnMkCol:=@ServerFunctions.ServerMkCol;
  Server.OnDelete:=@ServerFunctions.ServerDelete;
  Server.OnPutFile:=@ServerFunctions.ServerPutFile;
  Server.OnGetFile:=@ServerFunctions.ServerGetFile;
  Server.OnReadAllowed:=@ServerFunctions.ServerReadAllowed;
  Server.OnWriteAllowed:=@ServerFunctions.ServerReadAllowed;
  Server.OnUserLogin:=@ServerFunctions.ServerUserLogin;
end;
procedure TWebDAVTest.PropfindRoot;
var
  aRes: String;
begin
  aRes := SendRequest(
   'PROPFIND / HTTP/1.1'+#13
  +'Depth: 0'+#13
  +'Prefer: return-minimal'+#13
  +'Content-Type: application/xml; charset=utf-8'+#13
  +#13
//  +'<?xml version="1.0" encoding="utf-8"?>'+#13
  +'<d:propfind xmlns:d="DAV:" xmlns:cs="http://calendarserver.org/ns/">'+#13
  +'  <d:prop>'+#13
  +'     <d:displayname />'+#13
  +'     <cs:getctag />'+#13
  +'  </d:prop>'+#13
  +'</d:propfind>'+#13
  );
  Check(copy(aRes,0,pos(LineEnding,aRes)-1)='207','Wrong Answer to PropfindRoot');
end;
procedure TWebDAVTest.FindPrincipal;
var
  aRes, tmp: String;
begin
  aRes := SendRequest(
    'PROPFIND / HTTP/1.1'+#13
  +'Depth: 0'+#13
  +'Prefer: return-minimal'+#13
  +'Content-Type: application/xml; charset=utf-8'+#13
  +''+#13
  +'<d:propfind xmlns:d="DAV:">'+#13
  +'  <d:prop>'+#13
  +'     <d:current-user-principal />'+#13
  +'  </d:prop>'+#13
  +'</d:propfind>'+#13);
  Check(copy(aRes,0,pos(LineEnding,aRes)-1)='207','Wrong Answer to Propfind Principal');
  tmp := copy(ares,pos('d:current-user-principal',aRes)+24,length(aRes));
  tmp := copy(tmp,2,pos('/d:current-user-principal',tmp)-3);
  tmp := trim(Stringreplace(tmp,#10,'',[rfReplaceAll]));
  Check(pos('d:href',tmp)>0,'Wrong Principal');
  tmp := copy(tmp,pos('>',tmp)+1,length(tmp));
  tmp := copy(tmp,0,pos('<',tmp)-1);
  UserURL := trim(tmp);
  Check(UserURL<>'','Wrong Principal URL');
end;
procedure TWebDAVTest.FindPrincipalOnWellKnown;
var
  aRes, tmp: String;
begin
  aRes := SendRequest(
    'PROPFIND /.well-known/caldav/ HTTP/1.1'+#13
  +'Depth: 0'+#13
  +'Prefer: return-minimal'+#13
  +'Content-Type: application/xml; charset=utf-8'+#13
  +''+#13
  +'<d:propfind xmlns:d="DAV:">'+#13
  +'  <d:prop>'+#13
  +'     <d:current-user-principal />'+#13
  +'  </d:prop>'+#13
  +'</d:propfind>'+#13);
  Check(copy(aRes,0,pos(LineEnding,aRes)-1)='207','Wrong Answer to Propfind Principal');
  tmp := copy(ares,pos('d:current-user-principal',aRes)+24,length(aRes));
  tmp := copy(tmp,2,pos('/d:current-user-principal',tmp)-3);
  tmp := trim(Stringreplace(tmp,#10,'',[rfReplaceAll]));
  Check(pos('d:href',tmp)>0,'Wrong Principal');
  tmp := copy(tmp,pos('>',tmp)+1,length(tmp));
  tmp := copy(tmp,0,pos('<',tmp)-1);
  UserURL := trim(tmp);
  Check(UserURL<>'','Wrong Principal URL');
end;
procedure TWebDAVTest.FindPrincipalCalendarHome;
var
  aRes, tmp: String;
begin
  aRes := SendRequest(
    'PROPFIND '+UserURL+' HTTP/1.1'+#13
  +'Depth: 0'+#13
  +'Prefer: return-minimal'+#13
  +'Content-Type: application/xml; charset=utf-8'+#13
  +''+#13
  +'<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">'+#13
  +'  <d:prop>'+#13
  +'     <c:calendar-home-set />'+#13
  +'  </d:prop>'+#13
  +'</d:propfind>'+#13);
  Check(copy(aRes,0,pos(LineEnding,aRes)-1)='207','Wrong Answer to Calendar Home Sets');
  tmp := copy(ares,pos('c:calendar-home-set',aRes)+20,length(aRes));
  tmp := copy(tmp,2,pos('/c:calendar-home-set',tmp)-3);
  tmp := trim(Stringreplace(tmp,#10,'',[rfReplaceAll]));
  Check(pos('d:href',tmp)>0,'Wrong Home Set');
  tmp := copy(tmp,pos('>',tmp)+1,length(tmp));
  tmp := copy(tmp,0,pos('<',tmp)-1);
  UserCalenderURL := trim(tmp);
  Check(UserCalenderURL<>'','Wrong Home Set URL');
end;
procedure TWebDAVTest.FindPrincipalCalendars;
var
  aRes: String;
begin
  aRes := SendRequest(
   'PROPFIND '+UserCalenderURL+' HTTP/1.1'+#13
  +'Depth: 1'+#13
  +'Prefer: return-minimal'+#13
  +'Content-Type: application/xml; charset=utf-8'+#13
  +''+#13
  +'<d:propfind xmlns:d="DAV:" xmlns:cs="http://calendarserver.org/ns/" xmlns:c="urn:ietf:params:xml:ns:caldav">'+#13
  +'  <d:prop>'+#13
  +'     <d:resourcetype />'+#13
  +'     <d:displayname />'+#13
  +'     <cs:getctag />'+#13
  +'     <c:supported-calendar-component-set />'+#13
  +'  </d:prop>'+#13
  +'</d:propfind>'+#13);
  Check(copy(aRes,0,pos(LineEnding,aRes)-1)='207','Wrong Answer to Calendar Home Sets');
end;

procedure TWebDAVTest.CheckNamespaceUsage;
var
  aRes: String;
begin
  aRes := SendRequest(
   'PROPFIND /caldav/ HTTP 1.1'+#13
  +'depth:1'+#13
  +'content-type:application/xml; charset=utf-8'+#13
  +''+#13
  +'<?xml version="1.0" encoding="UTF-8" ?>'+#13
  +'<propfind xmlns="DAV:" xmlns:CAL="urn:ietf:params:xml:ns:caldav" xmlns:CARD="urn:ietf:params:xml:ns:carddav"><prop><CAL:supported-calendar-component-set /><resourcetype /><displayname /><current-user-privilege-set /><n0:calendar-color xmlns:n0="http://apple.com/ns/ical/" /><CAL:calendar-description /><CAL:calendar-timezone /></prop></propfind>'+#13);
  Check(copy(aRes,0,pos(LineEnding,aRes)-1)='207','Wrong Answer to Calendar Home Sets');
  Check(pos('xmlns:D="DAV:"',aRes)>0,'DAV Namespace missing');
  Check(pos('xmlns:CAL="urn:ietf:params:xml:ns:caldav"',aRes)>0,'CalDAV Namespace missing');
  Check(pos('xmlns:CARD="urn:ietf:params:xml:ns:carddav"',aRes)>0,'CardDAV Namespace missing');
  //TODO:Check(pos('xmlns:n0="http://apple.com/ns/ical/"',aRes)>0,'ICal Namespace missing');
end;

procedure TWebDAVTest.AddEvent;
begin
end;

procedure TWebDAVTest.CheckReportWithoutRequest;
var
  aRes: String;
begin
  exit;
  aRes := SendRequest(
   'REPORT /caldav/home/ HTTP 1.1'+#13
  +'content-type:application/xml; charset=utf-8'+#13
  +'pragma:no-cache'+#13
  +'prefer:return-minimal'+#13
  +'depth:1'+#13
  +'cache-control:no-cache'+#13
  +'connection:keep-alive'+#13
  +''+#13
  +'<?xml version="1.0" encoding="utf-8" ?><A:calendar-query xmlns:A="urn:ietf:params:xml:ns:caldav" xmlns:B="DAV:"><B:prop><B:getcontenttype/><B:getetag/></B:prop><A:filter><A:comp-filter name="VCALENDAR"><A:comp-filter name="VTODO"/></A:comp-filter></A:filter></A:calendar-query>');
  Check(copy(aRes,0,pos(LineEnding,aRes)-1)='207','Wrong Answer to Calendar Home Sets');
  Check(pos('B:multistatus',aRes)>0,'Wrong Namespace');
end;

procedure TWebDAVTest.CheckReport2;
var
  aRes: String;
begin
  aRes := SendRequest(
   'REPORT /caldav/home/ HTTP 1.1'+#13
  +'content-type:application/xml; charset=utf-8'+#13
  +'depth:1'+#13
  +'accept-encoding:gzip'+#13
  +'cache-control:no-cache'+#13
  +'connection:keep-alive'+#13
  +''+#13
  +'<?xml version="1.0" encoding="utf-8" ?><A:calendar-query xmlns:A="urn:ietf:params:xml:ns:caldav" xmlns:B="DAV:"><B:prop><B:getcontenttype/><B:getetag/></B:prop><A:filter><A:comp-filter name="VCALENDAR"><A:comp-filter name="VTODO"/></A:comp-filter></A:filter></A:calendar-query>');
  Check(copy(aRes,0,pos(LineEnding,aRes)-1)='207','Wrong Answer to Calendar Home Sets');
  Check(pos('B:multistatus',aRes)>0,'Wrong Namespace');
end;

procedure TWebDAVTest.CheckOptionsSubPath;
var
  aRes: String;
begin
  aRes := SendRequest(
   'OPTIONS /caldav/Testkalender%20alle/ HTTP 1.1'+#13
  +'');
  Check(copy(aRes,0,pos(LineEnding,aRes)-1)='200','Wrong Answer to Subpath Option');
end;

procedure TWebDAVTest.CheckPropfindAllprop;
var
  aRes: String;
begin
  aRes := SendRequest(
   'PROPFIND /caldav/ HTTP 1.1'+#13
  +'depth:1'+#13
  +'content-type:application/xml; charset=utf-8'+#13
  +''+#13
  +'<?xml version="1.0" encoding="UTF-8" ?>'+#13
  +'<propfind xmlns="DAV:" xmlns:CAL="urn:ietf:params:xml:ns:caldav" xmlns:CARD="urn:ietf:params:xml:ns:carddav"><prop><allprop/></prop></propfind>'+#13);
  Check(copy(aRes,0,pos(LineEnding,aRes)-1)='207','Wrong Answer to Allprop');
  Check(pos('D:displayname',aRes)>0,'d:displayname missing');
  Check(pos('D:resourcetype',aRes)>0,'d:resourcetype missing');
  Check(pos('D:getetag',aRes)>0,'d:getetag missing');
end;

procedure TWebDAVTest.MkCol;
var
  aRes: String;
begin
  aRes := SendRequest('MKCOL /webdav/litmus/ HTTP 1.1'+#13
  +''+#13);
  Check(copy(aRes,0,pos(LineEnding,aRes)-1)='200','Wrong Answer to MkCol');
end;

procedure TWebDAVTest.CheckPropfindImplicitAllProp;
var
  aRes: String;
begin
  aRes := SendRequest(
   'PROPFIND /caldav/ HTTP 1.1'+#13
  +'depth:1'+#13
  +'content-type:application/xml; charset=utf-8'+#13
  +''+#13);
  Check(copy(aRes,0,pos(LineEnding,aRes)-1)='207','Wrong Answer to Allprop');
  Check(pos('D:displayname',aRes)>0,':displayname missing');
  Check(pos('D:resourcetype',aRes)>0,'d:resourcetype missing');
  Check(pos('D:getetag',aRes)>0,'d:getetag missing');
  Check(pos('xmlns:D="DAV:"',aRes)>0,'DAV Namespace missing');
  {
  curl -i -X PROPFIND http://192.168.177.120:10081/remote.php/webdav/
HTTP/1.1 207 Multi-Status
Server: nginx
Date: Tue, 26 Jul 2016 02:51:42 GMT
Content-Type: application/xml; charset=utf-8
Transfer-Encoding: chunked
Connection: keep-alive
X-Powered-By: PHP/7.0.8
Expires: Thu, 19 Nov 1981 08:52:00 GMT
Cache-Control: no-store, no-cache, must-revalidate
Pragma: no-cache
Set-Cookie: oc_sessionPassphrase=kPRtkW%2FtAas%2FOAkwJGudA55iNJOzaSWdYbynVIpJuwxryX0idpSidTEjLOFCVPqlvxNChxa1b1GoEuT4x%2F0ilw7qEPgqCpZBdD3MOWznxDmc6%2BcvdzdXAcRPZybJclAW; path=/; HttpOnly
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; frame-src *; img-src * data: blob:; font-src 'self' data:; media-src *; connect-src *
Set-Cookie: nc_sameSiteCookielax=true; path=/; httponly;expires=Fri, 31-Dec-2100 23:59:59 GMT; SameSite=lax
Set-Cookie: nc_sameSiteCookiestrict=true; path=/; httponly;expires=Fri, 31-Dec-2100 23:59:59 GMT; SameSite=strict
Set-Cookie: ocal0ualegse=ffcdldk13nj87pf9p7vr25rlu5; path=/; HttpOnly
Vary: Brief,Prefer
DAV: 1, 3, extended-mkcol

<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:s="http://sabredav.org/ns" xmlns:oc="http://owncloud.org/ns">
 <d:response>
  <d:href>/remote.php/webdav/</d:href>
  <d:propstat>
   <d:prop>
    <d:getlastmodified>Mon, 25 Jul 2016 21:28:04 GMT</d:getlastmodified>
    <d:resourcetype>
     <d:collection/>
    </d:resourcetype>
    <d:quota-used-bytes>714783</d:quota-used-bytes>
    <d:quota-available-bytes>-3</d:quota-available-bytes>
    <d:getetag>&quot;579684649174f&quot;</d:getetag>
   </d:prop>
   <d:status>HTTP/1.1 200 OK</d:status>
  </d:propstat>
 </d:response>
 <d:response>
  <d:href>/remote.php/webdav/Documents/</d:href>
  <d:propstat>
   <d:prop>
    <d:getlastmodified>Mon, 25 Jul 2016 21:28:04 GMT</d:getlastmodified>
    <d:resourcetype>
     <d:collection/>
    </d:resourcetype>
    <d:quota-used-bytes>36227</d:quota-used-bytes>
    <d:quota-available-bytes>-3</d:quota-available-bytes>
    <d:getetag>&quot;57968464839e7&quot;</d:getetag>
   </d:prop>
   <d:status>HTTP/1.1 200 OK</d:status>
  </d:propstat>
 </d:response>
 <d:response>
  <d:href>/remote.php/webdav/Photos/</d:href>
  <d:propstat>
   <d:prop>
    <d:getlastmodified>Mon, 25 Jul 2016 21:28:03 GMT</d:getlastmodified>
    <d:resourcetype>
     <d:collection/>
    </d:resourcetype>
    <d:quota-used-bytes>678556</d:quota-used-bytes>
    <d:quota-available-bytes>-3</d:quota-available-bytes>
    <d:getetag>&quot;579684639230b&quot;</d:getetag>
   </d:prop>
   <d:status>HTTP/1.1 200 OK</d:status>
  </d:propstat>
 </d:response>
</d:multistatus>

  }
end;

initialization

  RegisterTest(TWebDAVTest);
end.

