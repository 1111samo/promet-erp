program clipp;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, richmemopackage, umain, pvisualprometapp,uBaseVisualApplication
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Free;
  Application := TBaseVisualApplication.Create(nil);
  Application.Initialize;
  Application.CreateForm(TfMain, fMain);
  fMain.DoCreate;
  Application.Run;
end.

