program local_appbase;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cwstring,cthreads,{$ENDIF}
  pfcgiprometapp,
  ubasehttpapplication,
  Interfaces,uBaseApplication,umain;
begin
  Application.DefaultModule:='main';
  with BaseApplication as IBaseApplication do
    begin
      with Application as IBaseApplication do
        begin
          AppVersion:={$I ../base/version.inc};
          AppRevision:={$I ../base/revision.inc};
        end;
      SetConfigName('appconfig');
      RestoreConfig;
      Login;
    end;
  Application.Initialize;
  Application.Port:=8086;
  Application.DefaultModule:='main';
  Application.Run;
  Application.DoExit;
end.

