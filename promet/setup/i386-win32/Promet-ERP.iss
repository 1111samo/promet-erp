[Defines]
#define AppName GetEnv('Progname')
#define AppVersion GetEnv('Version')
#define BaseAppVersion GetEnv('BaseVersion')
#define SetupDate GetEnv('DateStamp')
#define FullTarget GetEnv('FullTarget')
#define TargetCPU GetEnv('TARGETCPU')
[Setup]
AppID=CUPROMETERP7
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
DefaultDirName={pf}\Promet-ERP
DefaultGroupName=Promet-ERP
UninstallDisplayIcon={app}\prometerp.exe
OutputBaseFilename=promet-erp_{#AppVersion}_{#FullTarget}
OutputDir=../output
InternalCompressLevel=ultra
PrivilegesRequired=none
TimeStampsInUTC=true
Encryption=false
Compression=bzip
VersionInfoCopyright=C.Ulrich
AppPublisher=C.Ulrich
AppPublisherURL=http://www.free-erp.de
AppSupportURL=http://www.free-erp.de
AppUpdatesURL=http://www.free-erp.de
AppContact=http://www.free-erp.de

[Files]
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\prometerp.exe"; DestDir: "{app}"; Components: main
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\pstarter.exe"; DestDir: "{app}"; Components: main
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\messagemanager.exe"; DestDir: "{app}\tools"; Components: main
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\wizardmandant.exe"; DestDir: "{app}"; Components: main
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\cmdwizardmandant.exe"; DestDir: "{app}\tools"; Components: admin
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\clientmanagement.exe"; DestDir: "{app}"; Components: admin
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\*receiver.exe"; DestDir: "{app}\tools"; Components: main
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\*sender.exe"; DestDir: "{app}\tools"; Components: main
Source: "sqlite3.dll"; DestDir: "{app}"; Components: main
Source: "sqlite3.dll"; DestDir: "{app}\tools"; Components: main
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\sync_*.exe"; DestDir: "{app}\tools"; Components: main
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\linksender.exe"; DestDir: "{app}\tools"; Components: main
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\checkout.exe"; DestDir: "{app}"; Components: admin
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\checkin.exe"; DestDir: "{app}"; Components: admin
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\tableedit.exe"; DestDir: "{app}"; Components: admin
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\statistics.exe"; DestDir: "{app}"; Components: statistics
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\meetingminutes.exe"; DestDir: "{app}"; Components: meeting
Source: "..\..\importdata\*.*"; DestDir: "{app}\importdata"; Flags: recursesubdirs; Components: main
Source: "PrometERP.xml"; DestDir: "{localappdata}\prometerp"; Components: db;Flags: onlyifdoesntexist

;Source: "..\promet-erp.db"; DestDir: "{localappdata}"; Components: db;Flags: onlyifdoesntexist; AfterInstall: DoInstallDB('{localappdata}')

Source: "..\errors.txt"; DestDir: "{app}"; Components: main
Source: "..\warnings.txt"; DestDir: "{app}"; Components: main

Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\helpviewer.exe"; DestDir: "{app}"; Components: help
Source: "..\help\help.db"; DestDir: "{app}"; Components: help

Source: "tools\*.*"; DestDir: "{app}\tools"; Components: main

Source: "..\..\source\base\changes.txt"; DestDir: "{app}"; Components: main

Source: "..\..\languages\*.po"; DestDir: "{app}\languages"; Components: main
Source: "..\..\languages\*.txt"; DestDir: "{app}\languages"; Components: main

Source: "plugins\*.*"; DestDir: "{app}\plugins"; Components: main
Source: "..\executables\{#BaseAppVersion}\{#TargetCPU}\shipping_*.exe"; DestDir: "{app}\plugins"; Components: main

Source: "website.url"; DestDir: "{app}"

[Run]
Filename: "{app}\wizardmandant.exe"; Parameters: "--silent"; Flags: postinstall shellexec skipifsilent; Description: "Standartdatenbank erstellen"; Components: db

[Components]
Name: "main"; Description: "Main Program Components"; Types: full compact custom; Flags: fixed; Languages: en
Name: "help"; Description: "Help"; Types: full custom; Languages: en
Name: "statistics"; Description: "Statistic Tool"; Types: custom; Languages: en
Name: "meeting"; Description: "Meeting Minutes"; Types: custom; Languages: en
Name: "admin"; Description: "Admin Tools"; Types: custom; Languages: en
Name: "db"; Description: "Personal Database"; Types: full; Languages: en
Name: "db"; Description: "Pers�nliche Datenbank"; Types: full; Languages: de
Name: "main"; Description: "Hauptprogramm Komponenten"; Types: full compact custom; Flags: fixed; Languages: de
Name: "help"; Description: "Hilfe"; Types: full custom; Languages: de
Name: "statistics"; Description: "Statistik Tool"; Types: custom; Languages: de
Name: "meeting"; Description: "Besprechungsprotokoll"; Types: custom; Languages: de
Name: "admin"; Description: "Administrator Tools"; Types: full custom; Languages: de

[Tasks]
Name: desktopicon; Description: Create an Desktop Icon; GroupDescription: Additional Icons:; Languages: en
Name: desktopicon; Description: Ein Desktop Icon erstellen; GroupDescription: Zus�tzliche Icons:; Languages: de

[Icons]
Name: {group}\{#AppName}; Filename: {app}\prometerp.exe; Workingdir: {app}; Flags: createonlyiffileexists
Name: {group}\Administration\Update Database; Filename: {app}\updatedatabase.exe; Workingdir: {app}; Languages: en; Flags: createonlyiffileexists
Name: {group}\Administration\Datenbankupdate; Filename: {app}\updatedatabase.exe; Workingdir: {app}; Languages: de; Flags: createonlyiffileexists
Name: {group}\Statistics; Filename: {app}\statistics.exe; Workingdir: {app}; Languages: en; Components: statistics; Flags: createonlyiffileexists
Name: {group}\Statistik; Filename: {app}\statistics.exe; Workingdir: {app}; Languages: de; Components: statistics; Flags: createonlyiffileexists
Name: {group}\Meeting Minutes; Filename: {app}\meetingminutes.exe; Workingdir: {app}; Languages: en; Components: meeting; Flags: createonlyiffileexists
Name: {group}\Besprechungsprotokoll; Filename: {app}\meetingminutes.exe; Workingdir: {app}; Languages: de; Components: meeting; Flags: createonlyiffileexists
Name: {group}\Clientmanagement; Filename: {app}\clientmanagement.exe; Workingdir: {app}; Languages: en; Components: admin; Flags: createonlyiffileexists
Name: {group}\Clientmanagement; Filename: {app}\clientmanagement.exe; Workingdir: {app}; Languages: de; Components: admin; Flags: createonlyiffileexists
Name: {group}\Mandant anlegen/bearbeiten; Filename: {app}\wizardmandant.exe; Workingdir: {app}; Languages: de; Flags: createonlyiffileexists
Name: {group}\create/edit Mandant; Filename: {app}\wizardmandant.exe; Workingdir: {app}; Languages: en; Flags: createonlyiffileexists
Name: {group}\Online Hilfe; Filename: {app}\help\{#AppName}-helpde.html; Languages: de; Flags: createonlyiffileexists
Name: {group}\Online Help; Filename: {app}\help\{#AppName}-helpen.html; Languages: en; Flags: createonlyiffileexists
Name: {group}\Internet; Filename: {app}\website.url
Name: {userdesktop}\{#AppName}; Filename: {app}\prometerp.exe; Tasks: desktopicon; Flags: createonlyiffileexists
Name: {userdesktop}\Statistics; Filename: {app}\statistics.exe; Tasks: desktopicon; Flags: createonlyiffileexists
Name: {userdesktop}\Besprechungsprotokoll; Filename: {app}\meetingminutes.exe; Tasks: desktopicon; Flags: createonlyiffileexists

[Registry]
Root: HKCR; Subkey: ".plink"; ValueType: string; ValueName: ""; ValueData: "Promet-ERP-Link"; Flags: uninsdeletevalue
Root: HKCR; Subkey: "Promet-ERP-Link"; ValueType: string; ValueName: ""; ValueData: "Promet-ERP Verkn�pfung"; Flags: uninsdeletekey
Root: HKCR; Subkey: "Promet-ERP-Link\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\tools\linksender.exe,0"
Root: HKCR; Subkey: "Promet-ERP-Link\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\tools\linksender.exe"" ""%1"""

[UninstallDelete]
Type: filesandordirs; Name: {app}

[Languages]
Name: en; MessagesFile: compiler:Default.isl
Name: de; MessagesFile: German.isl

[Code]
#include "feedback.iss"

procedure DoInstallDB(InstallPath : String);
begin
  InstallPath := ExpandConstant(InstallPath);
  ForceDirectories(InstallPath+'\prometerp\');
  SaveStringToFile(InstallPath+'\prometerp\Standart.perml','SQL'+#13#10+'sqlite-3;localhost;'+InstallPath+'\promet-erp.db;;x',False);
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
if CurUninstallStep = usUninstall then
  begin
    UninstallFeedback('R�ckmeldung', 'Senden', 'Abbrechen',
    'Um das Programm zu verbessern, w�re es sch�n wenn Sie uns ein paar Worte zu den Gr�nden der Deinstallation und Ihrer Erfahrung mit dem Programm schreiben w�rden.'#13#10'Danke.',
    'support@free-erp.de', 'Deinstallations R�ckmeldung');
  end;
end;
