{*******************************************************************************
Dieser Sourcecode darf nicht ohne gültige Geheimhaltungsvereinbarung benutzt werden
und ohne gültigen Vertriebspartnervertrag weitergegeben oder kommerziell verwertet werden.
You have no permission to use this Source without valid NDA
and copy it without valid distribution partner agreement
Christian Ulrich
info@cu-tec.de
Created 01.06.2006
*******************************************************************************}
unit ubasefcgiapplication;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, CustFCGI, uBaseApplication, uBaseDBInterface,
  PropertyStorage, uData, uSystemMessage, XMLPropStorage,HTTPDefs,fpHTTP,
  uBaseDbClasses,db,md5,fastcgi,eventlog;
type
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
uses FileUtil,Utils, uUserAgents, LCLProc,uBaseWebSession;
resourcestring
  strFailedtoLoadMandants    = 'Mandanten konnten nicht gelanden werden !';
  strLoginFailed             = 'Anmeldung fehlgeschlagen !';
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

