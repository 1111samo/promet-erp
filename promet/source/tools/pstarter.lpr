program pstarter;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  Process,UTF8Process,
  SysUtils,
  Dialogs,
  Utils,
  FileUtil
  { add your units here }, uprogramended, general,uLanguageUtils;

var
  Proc : TProcessUTF8;
  tmp: string;

{$R pstarter.res}

begin
  Application.Initialize;
  Proc := TProcessUTF8.Create(nil);
  Proc.Options := [poNoConsole, poNewProcessGroup, poWaitOnExit];
  tmp := SysToUTF8(CmdLine);
  tmp := copy(tmp,pos(' ',tmp)+1,length(tmp));
  LoadLanguage(copy(tmp,0,pos(' ',tmp)));
  tmp := trim(copy(tmp,pos(' ',tmp)+1,length(tmp)));
  if length(tmp)>0 then
    if byte(tmp[length(tmp)])>128 then
      tmp := copy(tmp,0,length(tmp)-1);
  if (copy(tmp,0,1)='"') and (copy(tmp,length(tmp)-1,1) = '"') then
    tmp := copy(tmp,2,length(tmp)-2);
  Proc.CommandLine := tmp;
  if Proc.CommandLine = '' then exit;
  Proc.Execute;
  Application.CreateForm(TfProgramEnded, fProgramEnded);
  fProgramEnded.Filename := ExtractFilename(tmp);
  Application.Run;
  if fProgramEnded.cbDontShowthisDialogAgain.Checked then
    ExitCode := 1
  else
    ExitCode := 0;
end.
