program clientmanagement;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, uerror, richmemopackage
  { you can add units after this },
uclientmnmtmain,
  upassword, udata, pvisualprometapp, uBaseVisualApplication;

{$R *.res}

begin
  Application.Free;
  Application := TBaseVisualApplication.Create(nil);
  Application.Initialize;
  Application.CreateForm(TfMain, fMain);
  fMain.DoCreate;
  Application.Run;
end.
