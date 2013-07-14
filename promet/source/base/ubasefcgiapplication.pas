unit ubasefcgiapplication;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, CustFCGI, uBaseApplication, uBaseDBInterface,
  PropertyStorage, uData, uSystemMessage, XMLPropStorage,HTTPDefs,fpHTTP,
  uBaseDbClasses,db,md5,uSessionDBClasses,fastcgi,eventlog;
type
  TBaseWebSession = class(TCustomSession)
  private
    SID : String;
    FSessionStarted: Boolean;
    FTerminated: Boolean;
    FSession : TSessions;
  protected
    Function GetSessionID : String; override;
    Function GetSessionVariable(VarName : String) : String; override;
    procedure SetSessionVariable(VarName : String; const AValue: String); override;
  public
    Constructor Create(AOwner : TComponent); override;
    Destructor Destroy; override;
    Procedure Terminate; override;
    Procedure UpdateResponse(AResponse : TResponse); override;
    Procedure InitSession(ARequest : TRequest; OnNewSession, OnExpired: TNotifyEvent); override;
    Procedure InitResponse(AResponse : TResponse); override;
    Procedure RemoveVariable(VariableName : String); override;
  end;
  TBaseSessionFactory = Class(TSessionFactory)
  private
  protected
    Procedure DoDoneSession(Var ASession : TCustomSession); override;
    Function SessionExpired(aSession : TSessions) : boolean;
    Function DoCreateSession(ARequest : TRequest) : TCustomSession; override;
    procedure DoCleanupSessions; override;
  end;

  { TBaseFCGIApplication }

  TBaseFCGIApplication = class(TCustomFCGIApplication, IBaseApplication, IBaseDbInterface)
    procedure BaseFCGIApplicationException(Sender: TObject; E: Exception);
    procedure BaseFCGIApplicationGetModule(Sender: TObject; ARequest: TRequest;
      var ModuleClass: TCustomHTTPModuleClass);
    procedure BaseFCGIApplicationUnknownRecord(ARequest: TFCGIRequest;
      AFCGIRecord: PFCGI_Header);
  private
    FDBInterface: IBaseDbInterface;
    FDefaultModule: string;
    FMessageHandler: TMessageHandler;
    Properties: TXMLPropStorage;
    FLogger : TEventLog;
    FAppName : string;
    FAppRevsion : Integer;
    FAppVersion : Real;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetOurConfigDir: string;
    function GetAppName: string;
    function GetApprevision: Integer;
    function GetAppVersion: real;
    procedure SetConfigName(aName : string);
    procedure RestoreConfig;
    procedure SaveConfig;
    function GetConfig: TCustomPropertyStorage;
    function GetLanguage: string;
    procedure SetLanguage(const AValue: string);
    procedure SetAppname(AValue: string);virtual;
    procedure SetAppRevision(AValue: Integer);virtual;
    procedure SetAppVersion(AValue: real);virtual;
    function GetQuickHelp: Boolean;
    procedure SetQuickhelp(AValue: Boolean);

    function GetLog: TEventLog;
    procedure Log(aType : string;aMsg : string);virtual;
    procedure Log(aMsg : string);
    procedure Info(aMsg : string);
    procedure Warning(aMsg : string);
    procedure Error(aMsg : string);
    procedure Debug(aMsg : string);

    function ChangePasswort : Boolean;
    function GetSingleInstance : Boolean;
    function Login : Boolean;
    procedure Logout;
    procedure DoExit;
    property IData : IBaseDbInterface read FDBInterface implements IBaseDBInterface;
    property MessageHandler : TMessageHandler read FMessageHandler;
    property DefaultModule : string read FDefaultModule write FDefaultModule;
  end;
Var
  Application : TBaseFCGIApplication;
implementation
uses FileUtil,Utils,BlckSock, uUserAgents, LCLProc;
resourcestring
  strFailedtoLoadMandants    = 'Mandanten konnten nicht gelanden werden !';
  strLoginFailed             = 'Anmeldung fehlgeschlagen !';
procedure TBaseSessionFactory.DoDoneSession(var ASession: TCustomSession);
begin
  FreeAndNil(ASession);
end;
function TBaseSessionFactory.SessionExpired(aSession: TSessions): boolean;
Var
  L : TDateTime;
  T : Integer;
begin
  L:=aSession.FieldByName('LASTACCESS').AsDateTime;
  T:=aSession.FieldByName('TIMEOUT').AsInteger;
  Result:=((Now-L)>(T/(24*60)))
end;
function TBaseSessionFactory.DoCreateSession(ARequest: TRequest
  ): TCustomSession;
var
  S: TBaseWebSession;
begin
  S:=TBaseWebSession.Create(Nil);
  Result:=S;
end;
procedure TBaseSessionFactory.DoCleanupSessions;
var
  aSessions: TSessions;
  aFilter: String;
begin
  aSessions := TSessions.Create(Self,Data);
  aSessions.CreateTable;
  aFilter := Data.DateTimeToFilter(Now()-(DefaultTimeOutMinutes/(24*60)));
  aFilter := Data.QuoteField('LASTACCESS')+' < '+aFilter;
  with aSessions.DataSet as IBaseDbFilter do
    aFilter := aFilter+' and '+ProcessTerm(Data.QuoteField('ISACTIVE')+'='+Data.QuoteValue(''));
  Data.SetFilter(aSessions,aFilter);
  with aSessions.DataSet do
    begin
      while not EOF do
        begin
          if SessionExpired(aSessions) then
            begin
              if not aSessions.CanEdit then
                aSessions.DataSet.Edit;
              aSessions.FieldByName('ISACTIVE').AsString := 'N';
              aSessions.DataSet.Post;
            end;
          Next;
        end;
    end;
  aSessions.Destroy;
end;
function TBaseWebSession.GetSessionID: String;
begin
  If (SID='') then
    SID:=inherited GetSessionID;
  Result:=SID;
end;
function TBaseWebSession.GetSessionVariable(VarName: String): String;
begin
  Result := '';
  if FSession.Count = 0 then exit;
  FSession.Variables.Select(Varname);
  FSession.Variables.Open;
  if FSession.Variables.Count > 0 then
    Result := FSession.Variables.FieldByName('VALUE').AsString;
end;
procedure TBaseWebSession.SetSessionVariable(VarName: String;
  const AValue: String);
begin
  if FSession.Count = 0 then exit;
  FSession.Variables.Select(Varname);
  FSession.Variables.Open;
  try
    if FSession.Variables.Count = 0 then
      FSession.Variables.DataSet.Insert
    else if not FSession.Variables.CanEdit then
      FSession.Variables.DataSet.Edit;
    FSession.Variables.FieldByName('VALUE').AsString := AValue;
    FSession.Variables.FieldByName('NAME').AsString := VarName;
    FSession.Variables.DataSet.Post;
  except
    FSession.Variables.DataSet.Cancel;
  end;
end;
constructor TBaseWebSession.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSession := TSessions.Create(Self,Data);
  TimeOutMinutes := 25;
end;
destructor TBaseWebSession.Destroy;
begin
  try
    FSession.Destroy;
  except
  end;
  inherited Destroy;
end;
procedure TBaseWebSession.Terminate;
begin
end;
procedure TBaseWebSession.UpdateResponse(AResponse: TResponse);
begin
end;
procedure TBaseWebSession.InitSession(ARequest: TRequest; OnNewSession,
  OnExpired: TNotifyEvent);
Var
  S : String;
  FExpired: Boolean = False;
  Sock: TBlockSocket;
begin
  // First initialize all session-dependent properties to their default, because
  // in Apache-modules or fcgi programs the session-instance is re-used
  SID := '';
  FSessionStarted := False;
  FTerminated := False;
  // If a exception occured during a prior request FIniFile is still not freed
//  if assigned(FIniFile) then FreeIniFile;
  If (SessionCookie='') then
    SessionCookie:='PWSID';
  S:=ARequest.CookieFields.Values[SessionCookie];
  // have session cookie ?
  If (S<>'') then
    begin
      FSession.Select(S);
      FSession.Open;
      if (FSession.Count > 0) and (SessionFactory as TBaseSessionFactory).SessionExpired(FSession) then
        begin
          if not FSession.CanEdit then
            FSession.DataSet.Edit;
          FSession.FieldByName('ISACTIVE').AsString := 'N';
          FSession.DataSet.Post;
          // Expire session.
          If Assigned(OnExpired) then
            OnExpired(Self);
          S:='';
          FExpired := True;
        end
      else if (FSession.Count > 0) then
        SID:=S
      else
        begin
          if ARequest.CookieFields.IndexOf(S) > -1 then
            ARequest.CookieFields.Delete(ARequest.CookieFields.IndexOf(S));
          S := '';
        end;
    end;
  If (S='') and (not FExpired) then
    begin
      FSession.Select(ARequest.RemoteAddress,ARequest.UserAgent);
      FSession.Open;
      if FSession.Count > 0 then
        begin
          if (SessionFactory as TBaseSessionFactory).SessionExpired(FSession) then
            begin
              if not FSession.CanEdit then
                FSession.DataSet.Edit;
              FSession.FieldByName('ISACTIVE').AsString := 'N';
              FSession.DataSet.Post;
              // Expire session.
              If Assigned(OnExpired) then
                OnExpired(Self);
              S:='';
              FExpired := True;
            end
          else
            begin
              S := FSession.FieldByName('SID').AsString;
              SID := S;
            end;
        end;
    end;
  If (S='') then
    begin
      If Assigned(OnNewSession) then
        OnNewSession(Self);
      GetSessionID;
      FSession.Select(0);
      FSession.Open;
      with FSession.DataSet do
        begin
          Insert;
          FieldByName('SID').AsString := SID;
          FieldByName('TIMEOUT').AsInteger := Self.TimeOutMinutes;
          FieldByName('STARTED').AsDateTime := Now();
          FieldByName('HOST').AsString := ARequest.RemoteAddress;
          FieldByName('CLIENT').AsString := MD5Print(MD5String(ARequest.UserAgent));
          Post;
        end;
      if ARequest.Referer <> '' then
        Self.Variables['REFERER'] := ARequest.Referer;
      if Self.Variables['HostName'] = '' then
        begin
          Sock := TBlockSocket.Create;
          Self.Variables['HostName'] := AnsiToUTF8(Sock.ResolveIPToName(ARequest.RemoteAddress));
          Sock.Free;
        end;
      Self.Variables['UserAgent'] := AnsiToUTF8(ARequest.UserAgent);
      Self.Variables['OS'] := OSFromUserAgent(AnsiToUTF8(ARequest.UserAgent));
//      Self.Variables['AGENT'] := AgentFromUserAgent(AnsiToUTF8(ARequest.UserAgent));
//      Self.Variables['TYP'] := TypeFromUserAgent(AnsiToUTF8(ARequest.UserAgent));
      Self.Variables['Host'] := AnsiToUTF8(ARequest.Host);
      FSessionStarted:=True;
    end;
  if not FSession.CanEdit then
    FSession.DataSet.Edit;
  FSession.FieldByName('LASTACCESS').AsDateTime := Now();
  FSession.DataSet.Post;
  if ARequest.GetFieldByName('X-Forwarded-For') <> '' then
    begin
      Self.Variables['Forwarded'] := AnsiToUTF8(ARequest.GetFieldByName('X-Forwarded-For'));
    end
  else if ARequest.GetFieldByName('HTTP_X_FORWARDED_FOR') <> '' then
    begin
      Self.Variables['Forwarded'] := AnsiToUTF8(ARequest.GetFieldByName('HTTP_X_FORWARDED_FOR'));
    end;
  if ARequest.PathInfo <> '' then
    begin
      FSession.History.Select(0);
      FSession.History.Open;
      with FSession.History.DataSet do
        begin
          try
            if FSession.History.CanEdit then
              Cancel;
            Insert;
            FieldByName('URL').AsString := ARequest.PathInfo;
            Post;
          except
            Cancel;
          end;
        end;
    end;
end;
procedure TBaseWebSession.InitResponse(AResponse: TResponse);
Var
  C : TCookie;
begin
  If FSessionStarted then
    begin
      C:=AResponse.Cookies.FindCookie(SessionCookie);
      If (C=Nil) then
        begin
        C:=AResponse.Cookies.Add;
        C.Name:=SessionCookie;
        end;
      C.Value:=SID;
      C.Path:=SessionCookiePath;
    end
  else If FTerminated then
    begin
      C:=AResponse.Cookies.Add;
      C.Name:=SessionCookie;
      C.Value:='';
    end;
end;
procedure TBaseWebSession.RemoveVariable(VariableName: String);
begin
  if FSession.Count = 0 then exit;
  FSession.Variables.Select(VariableName);
  FSession.Variables.Open;
  if FSession.Variables.Count > 0 then
    FSession.Variables.DataSet.Delete;
end;
procedure TBaseFCGIApplication.BaseFCGIApplicationException(Sender: TObject;
  E: Exception);
begin
  writeln('Error:'+e.Message);
  FLogger.Error(e.Message);
  Application.Terminate;
end;
procedure TBaseFCGIApplication.BaseFCGIApplicationGetModule(Sender: TObject;
  ARequest: TRequest; var ModuleClass: TCustomHTTPModuleClass);
var
  MN: String;
  MI: TModuleItem;
  S: String;
  I: Integer;
begin
  S:=ARequest.PathInfo;
  If (Length(S)>0) and (S[1]='/') then
    Delete(S,1,1);                      //Delete the leading '/' if exists
  I:=Length(S);
  If (I>0) and (S[I]='/') then
    Delete(S,I,1);                      //Delete the trailing '/' if exists
  I:=Pos('/',S);
  if (I>0) then
    MN:=ARequest.GetNextPathInfo;
  if S = '' then
    MI := ModuleFactory.FindModule(DefaultModule)
  else
    MI:=ModuleFactory.FindModule(MN);
  if (MI=Nil) then
    MI:=ModuleFactory.FindModule(S);
  if (MI=Nil) then
    MI:=ModuleFactory.FindModule('error');
  ModuleClass := MI.ModuleClass;
end;
procedure TBaseFCGIApplication.BaseFCGIApplicationUnknownRecord(
  ARequest: TFCGIRequest; AFCGIRecord: PFCGI_Header);
begin
end;
constructor TBaseFCGIApplication.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAppName:='Promet-ERP';
  FAppVersion := 7.0;
  FAppRevsion := 0;
  BaseApplication := Self;
  FLogger := TEventLog.Create(Self);
  FLogger.Active:=false;
  if HasOption('l','logfile') then
    begin
      FLogger.FileName := GetOptionValue('l','logfile');
      FLogger.Active:=True;
    end;
  {.$Warnings Off}
  FDBInterface := TBaseDBInterface.Create;
  FDBInterface.SetOwner(Self);
  {.$Warnings On}
  Properties := TXMLPropStorage.Create(AOwner);
  Properties.FileName := GetOurConfigDir+'config.xml';
  Properties.RootNodePath := 'Config';
  AllowDefaultModule := True;
  Self.OnGetModule:=@BaseFCGIApplicationGetModule;
  Self.OnException:=@BaseFCGIApplicationException;
  Self.OnUnknownRecord :=@BaseFCGIApplicationUnknownRecord;
end;
destructor TBaseFCGIApplication.Destroy;
begin
  Properties.Free;
  DoExit;
  if Assigned(FmessageHandler) then
    begin
      FMessagehandler.Terminate;
      sleep(20);
    end;
  FDBInterface.Data.Free;
  FLogger.Free;
  inherited Destroy;
end;
function TBaseFCGIApplication.GetOurConfigDir: string;
begin
  Result := GetConfigDir(StringReplace(lowercase(GetAppname),'-','',[rfReplaceAll]));
end;
function TBaseFCGIApplication.GetAppName: string;
begin
  Result := FAppName;
end;
function TBaseFCGIApplication.GetApprevision: Integer;
begin
  Result := FAppRevsion;
end;
function TBaseFCGIApplication.GetAppVersion: real;
begin
  Result := FAppVersion;
end;
procedure TBaseFCGIApplication.SetConfigName(aName: string);
var
  aDir: String;
begin
  aDir := GetOurConfigDir;
//  aDir := Application.Location;
  if aDir <> '' then
    begin
      if not DirectoryExistsUTF8(aDir) then
        ForceDirectoriesUTF8(aDir);
    end;
  Properties.FileName := aDir+aName+'.xml';
  Properties.RootNodePath := 'Config';
end;
procedure TBaseFCGIApplication.RestoreConfig;
begin
  Properties.Restore;
  DefaultModule := Properties.ReadString('DEFAULTMODULE',DefaultModule);
end;
procedure TBaseFCGIApplication.SaveConfig;
begin
  Properties.Save;
end;
function TBaseFCGIApplication.GetConfig: TCustomPropertyStorage;
begin
  Result := Properties;
end;
function TBaseFCGIApplication.GetLanguage: string;
begin

end;
procedure TBaseFCGIApplication.SetLanguage(const AValue: string);
begin
end;
procedure TBaseFCGIApplication.SetAppname(AValue: string);
begin
  FAppName:=AValue;
end;
procedure TBaseFCGIApplication.SetAppRevision(AValue: Integer);
begin
  FAppRevsion:=AValue;
end;
procedure TBaseFCGIApplication.SetAppVersion(AValue: real);
begin
  FAppVersion:=AValue;
end;

function TBaseFCGIApplication.GetQuickHelp: Boolean;
begin

end;

procedure TBaseFCGIApplication.SetQuickhelp(AValue: Boolean);
begin

end;

function TBaseFCGIApplication.GetLog: TEventLog;
begin
  Result := FLogger;
end;
procedure TBaseFCGIApplication.Log(aType: string; aMsg: string);
begin
  writeln(aType+':'+aMsg);
  {
  if Assigned(FLogger) then
    begin
      if aType = 'INFO' then
        FLogger.Info(aMsg)
      else if aType = 'WARNING' then
        FLogger.Warning(aMsg)
      else if aType = 'ERROR' then
        FLogger.Error(aMsg);
    end;
  }
end;
procedure TBaseFCGIApplication.Log(aMsg: string);
begin
  Log('INFO',aMsg);
end;
procedure TBaseFCGIApplication.Info(aMsg: string);
begin
  Log(aMsg)
end;
procedure TBaseFCGIApplication.Warning(aMsg: string);
begin
  Log('WARNING',aMsg);
end;
procedure TBaseFCGIApplication.Error(aMsg: string);
begin
  Log('ERROR',aMsg);
end;
procedure TBaseFCGIApplication.Debug(aMsg: string);
begin
  if HasOption('debug') then
    debugln('DEBUG:'+aMsg);
end;
function TBaseFCGIApplication.ChangePasswort: Boolean;
begin
  Result := False;
end;
function TBaseFCGIApplication.GetSingleInstance: Boolean;
begin
  Result := False;
end;
function TBaseFCGIApplication.Login: Boolean;
var
  aMandant: String;
begin
  writeln('Login...');
  Result := False;
  with Self as IBaseDbInterface do
    begin
      if not LoadMandants('') then
        raise Exception.Create(strFailedtoLoadMandants);
      aMandant := GetOptionValue('m','mandant');
      if aMandant = '' then
        aMandant := Properties.ReadString('MANDANT','');
      if not DBLogin(aMandant,'') then
        begin
          FLogger.Error(strLoginFailed+':'+LastError);
          raise Exception.Create(strLoginFailed+':'+LastError);
        end;
      uData.Data := Data;
    end;
  SessionFactory.CleanupSessions;
  if Properties.ReadInteger('PORT',-1) <> -1 then
    Port:=Properties.ReadInteger('PORT',9998);
  Result := True;
end;
procedure TBaseFCGIApplication.Logout;
begin
end;
procedure TBaseFCGIApplication.DoExit;
begin
  with Self as IBaseDbInterface do
    DBLogout;
end;
initialization
  Application := TBaseFCGIApplication.Create(nil);
  SessionFactoryClass:=TBaseSessionFactory;
finalization
  Application.Destroy;
end.

