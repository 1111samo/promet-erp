{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit pPrometDBIntfs;

interface

uses
  uBaseDBInterface, uBaseDbClasses, uZeosDBDM, uOrder, uOrderQM, uTimes, 
  uStatistic, uIntfStrConsts, uData, uBaseERPDBClasses, uBaseSearch, 
  uProjects, uDocuments, uImpCSV, uImpVCard, uMasterdata, uPerson, 
  uAccounting, uMessages, uBaseApplication, uCalendar, uSystemMessage, 
  ubaseapplicationtools, uWiki, uEncrypt, usync, uSessionDBClasses, utask, 
  uvtools, uimpvcal, uDocumentProcess, uProcessManager, uProcessManagement, 
  uprometipc, umeeting, uBaseDocPages, FPReadJPEGintfd, uthumbnails, 
  fpthumbresize, ucalc, uimport, uPasswordSave, uzugferd, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('pPrometDBIntfs', @Register);
end.
