{*******************************************************************************
  Copyright (C) Christian Ulrich info@cu-tec.de

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or commercial alternative
  contact us for more information

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
*******************************************************************************}
unit uprometdavserver;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, udavserver, uDocuments, uBaseDbClasses, uCalendar,
  utask,Utils,uData,variants,uBaseDatasetInterfaces,synautil,
  DateUtils, uimpvcal,uhttputil,math,uBaseDBInterface;

type

  { TPrometServerFunctions }

  TPrometServerFunctions = class
  private
    function FindVirtualDocumentPath(var aRemovedDir, aDir: string;
      var aID: Variant; var aType: string; var aLevel: Integer=0): Boolean;
  public
    function AddDocumentsToFileList(aFileList: TDAVDirectoryList;
      aDocuments: TDocuments; aPath,aFilter: string) : Boolean;
    procedure AddDocumentToFileList(aFileList: TDAVDirectoryList;
      aDocuments: TDocuments; FullPath: string);
    function ServerDelete(aSocket: TDAVSession; aDir: string): Boolean;
    function ServerGetDirectoryList(aSocket: TDAVSession; aDir: string;
      aDepth: Integer; var aDirList: TDAVDirectoryList): Boolean;
    function ServerGetFile(aSocket: TDAVSession; aDir: string; Stream: TStream;
      var LastModified: TDateTime; var MimeType: string; var eTag: string
  ): Boolean;
    function ServerMkCol(aSocket: TDAVSession; aDir: string): Boolean;
    function ServerPutFile(aSocket: TDAVSession; aDir: string; Stream: TStream;
      var eTag: string; var FStatus: Integer): Boolean;
    function ServerReadAllowed(aSocket: TDAVSession; aDir: string): Boolean;
    function ServerUserLogin(aSocket: TDAVSession; aUser, aPassword: string
      ): Boolean;
  end;

implementation

const
  WebFormatSettings : TFormatSettings = (
    CurrencyFormat: 1;
    NegCurrFormat: 5;
    ThousandSeparator: ',';
    DecimalSeparator: '.';
    CurrencyDecimals: 2;
    DateSeparator: '-';
    TimeSeparator: ':';
    ListSeparator: ',';
    CurrencyString: '$';
    ShortDateFormat: 'd/m/y';
    LongDateFormat: 'dd" "mmmm" "yyyy';
    TimeAMString: 'AM';
    TimePMString: 'PM';
    ShortTimeFormat: 'hh:nn';
    LongTimeFormat: 'hh:nn:ss';
    ShortMonthNames: ('Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec');
    LongMonthNames: ('January','February','March','April','May','June',
                     'July','August','September','October','November','December');
    ShortDayNames: ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
    LongDayNames:  ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
    TwoDigitYearCenturyWindow: 50;
  );
function BuildISODate(aDate : TDateTime) : string;
var
  bias: Integer;
  h, m: Integer;
begin
  bias := TimeZoneBias;
  if bias >= 0 then
    Result := '+'
  else
    Result := '-';
  bias := Abs(bias);
  h := bias div 60;
  m := bias mod 60;
  Result := FormatDateTime('yyyy-mm-dd',aDate)+'T'+FormatDateTime('hh:nn:ss',aDate,WebFormatSettings)+ Result + SysUtils.Format('%.2d:%.2d', [h, m]);
end;
function TPrometServerFunctions.ServerDelete(aSocket: TDAVSession; aDir: string): Boolean;
var
  aDocuments: TDocuments;
  aDocument: TDocument;
  aFullDir: String;
  aFile: String;
  aParent,aDirPar : Variant;
  aDirs: TTree;
  aCal: TCalendar;
  aTasks: TTaskList;
  aID: Variant;
  aType: string;
  aLevel: Integer;
  aRemovedDir: string;
begin
  Result := False;
  if aSocket.User='' then exit;
  if not Data.Users.Locate('SQL_ID',aSocket.User,[]) then
    begin
      Data.Users.Filter('',0);
      if not Data.Users.Locate('SQL_ID',aSocket.User,[]) then exit;
    end;
  Data.RefreshUsersFilter;
  Result:=True;
  if copy(aDir,0,1)<>'/' then
    aDir := '/'+aDir;
  if copy(aDir,0,7) = '/caldav' then
    begin
      aFullDir := aDir;
      aDir := copy(aDir,9,length(aDir));
      if copy(aDir,length(aDir),1) = '/' then
        aDir := copy(aDir,0,length(aDir)-1);
      aFile := StringReplace(copy(aDir,rpos('/',aDir)+1,length(aDir)),'.ics','',[]);
      aDir := copy(aDir,0,rpos('/',aDir)-1);
      if aDir = 'home' then
        begin
          aParent := Data.Users.Id.AsVariant;
          result := True;
        end
      else
        begin
          aDirs := TTree.Create(nil);
          aDirs.Filter(Data.QuoteField('TYPE')+'='+Data.QuoteValue('A'));
          aDirPar := null;
          Result := True;
          while pos('/',aDir)>0 do
            begin
              if aDirs.Locate('PARENT;NAME',VarArrayOf([aDirPar,copy(aDir,0,pos('/',aDir)-1)]),[]) then
                begin
                  aDirPar := aDirs.FieldByName('PARENT').AsVariant;
                  aDir := copy(aDir,pos('/',aDir)+1,length(aDir));
                end
              else
                begin
                  Result := False;
                  aDirs.Free;
                  exit;
                end;
            end;
          aParent := aDirs.Id.AsVariant;
        end;
      aCal := TCalendar.Create(nil);
      aCal.Filter(Data.QuoteField('ORIGID')+'='+Data.QuoteValue(aFile));
      if (aCal.Count=0) and IsNumeric(aFile) then
        begin
          aCal.Select(aFile);
          aCal.Open;
        end;
      Result := aCal.Count=1;
      if Result then
        begin
          aCal.Delete;
        end
      else
        begin
          aTasks := TTaskList.Create(nil);
          aTasks.Filter(Data.QuoteField('ORIGIDS')+'='+Data.QuoteValue(aFile));
          if (aTasks.Count=0) and IsNumeric(aFile) then
            begin
              aTasks.Select(aFile);
              aTasks.Open;
              Result := aTasks.Count=1;
              if Result then  //edit task
                begin
                  atasks.Delete;
                end
            end;
          Result := aTasks.Count=1;
          if Result then
            begin
              aTasks.Delete;
            end;
          aTasks.Free;
        end;
      aCal.Free;
    end
  else if FindVirtualDocumentPath(aRemovedDir,aDir,aID,aType,aLevel) then
    begin
      if aLevel = 6 then
        begin
          aDocuments := TDocuments.Create(nil);
          aDocuments.Select(aId,aType,0);
          aDocuments.Open;
          if copy(aDir,length(aDir),1) = '/' then
            aDir := copy(aDir,0,length(aDir)-1);
          if rpos('/',aDir) > 1 then
            Result := aDocuments.OpenPath(copy(aDir,0,rpos('/',aDir)),'/')
          else Result := True;
          if Result then
            begin
              Result := False;
              aDir := copy(aDir,rpos('/',aDir)+1,length(aDir));
              if aDocuments.SelectFile(aDir) then
                begin
                  aDocument := TDocument.Create(nil);
                  aDocument.SelectByNumber(aDocuments.DataSet.FieldByName('NUMBER').AsVariant);
                  aDocument.Open;
                  if aDocument.Count > 0 then
                    begin
                      aDocument.Delete;
                      Result := True;
                    end;
                  aDocument.Free;
                end;
            end;
          aDocuments.Free;
        end;
    end;
end;
function TPrometServerFunctions.ServerGetDirectoryList(aSocket: TDAVSession; aDir: string;
  aDepth: Integer; var aDirList: TDAVDirectoryList): Boolean;
var
  aItem: TDAVFile;
  aDocuments: TDocuments;
  aFile: String;
  aCal: TCalendar;
  sl: TStringList;
  Stream: TMemoryStream;
  aDirs: TTree;
  aFullDir, aBaseDir, TmpPath, tmp2, tmp3: String;
  IsCalendarUser: Boolean = false;
  aTasks: TTaskList;
  aDel: TDeletedItems;
  aID: Variant;
  aType: string;
  i: Integer;
  aLevel: Integer;
  aRemovedDir: string;
begin
  Result := false;
  if aSocket.User='' then exit;
  try
  aDir := HTTPDecode(aDir);
  if not Data.Users.Locate('SQL_ID',aSocket.User,[]) then
    begin
      Data.Users.Filter('',0);
      if not Data.Users.Locate('SQL_ID',aSocket.User,[]) then exit;
    end;
  aFullDir := aDir;
  Data.RefreshUsersFilter;
  //Root
  if aDir = '/' then
    begin
      Result := True;
      aItem := TDAVFile.Create('/',True);
      if Data.Users.FieldByName('EMAIL').AsString<>'' then
        aItem.UserAdressSet.Add('mailto:'+Data.Users.FieldByName('EMAIL').AsString);
      aItem.UserAdressSet.Add('/caldav/');
      aItem.CalendarHomeSet:='/caldav/';
      aItem.CurrentUserPrincipal:='/users/'+Data.Users.FieldByName('NAME').AsString;
      aDirList.Add(aItem);
      if aDepth>0 then
        begin
          aItem := TDAVFile.Create('/webdav',True);
          aDirList.Add(aItem);
          aItem := TDAVFile.Create('/caldav',True);
          aDirList.Add(aItem);
          aItem := TDAVFile.Create('/carddav',True);
          aDirList.Add(aItem);
          aItem := TDAVFile.Create('/ical',True);
          aDirList.Add(aItem);
          for i := 0 to length(DatasetClasses)-1 do
            if DatasetClasses[i].aClass.InheritsFrom(TBaseDBList) and (
               (DatasetClasses[i].aName='MASTERDATA')
            or (DatasetClasses[i].aName='MEETING')
            or (DatasetClasses[i].aName='PROJECTS')
                ) then
              begin
                aItem := TDAVFile.Create('/'+lowercase(DatasetClasses[i].aName),True);
                aDirList.Add(aItem);
              end;
        end;
    end
  //Principals
  else if (copy(aDir,0,7) = '/users/')
  then
    begin
      Result := True;
      aFullDir := aDir;
      if copy(aFullDir,length(aFullDir),1) <> '/' then
        aFullDir := aFullDir+'/';
      aItem := TDAVFile.Create(aFullDir,True);
      aDirList.Add(aItem);
      aItem.CalendarHomeSet:='/caldav/';
    end
  //Standard CalDAV Paths
  else if (copy(aDir,0,7) = '/caldav')
       or (copy(aDir,0,19) = '/.well-known/caldav')
  then
    begin
      aFullDir := aDir;
      if copy(aFullDir,length(aFullDir),1) <> '/' then
        aFullDir := aFullDir+'/';
      if (copy(aDir,0,7) = '/caldav') then aBaseDir := '/caldav/';
      if (copy(aDir,0,19) = '/.well-known/caldav') then aBaseDir := '/.well-known/caldav/';
      if copy(aDir,0,7)='/caldav' then
        aDir := copy(aDir,9,length(aDir))
      else if (copy(aDir,0,19) = '/.well-known/caldav') then
        aDir := copy(aDir,21,length(aDir));
      if copy(aDir,length(aDir),1) = '/' then
        aDir := copy(aDir,0,length(aDir)-1);
      aItem := TDAVFile.Create(aFullDir,True);
      aItem.CurrentUserPrincipal:='/users/'+Data.Users.FieldByName('NAME').AsString;
      aDirList.Add(aItem);
      if Data.Users.DataSet.Active then
        begin
          if (copy(aDir,RPos('/',aDir)+1,length(aDir)) = 'user') then
            begin
              IsCalendarUser := True;
              aDir := copy(aDir,0,rpos('/',aDir)-1);
            end;
          //Add CalDAV Calendars
          aDirs := TTree.Create(nil);
          aDirs.Filter(Data.QuoteField('TYPE')+'='+Data.QuoteValue('A'));
          if not (Assigned(aItem) and (aItem.Path = aBaseDir+aDir+'/')) then
            begin
              aItem := TDAVFile.Create(aBaseDir+'home'+'/',True);
              if Assigned(aDirList) then
                aDirList.Add(aItem)
              else aDirList := aItem;
            end;
          if (aBaseDir+'home'+'/' = aItem.Path) or (aDir = '') then
            begin
              aItem.IsCalendar:=True;
              aItem.IsTodoList:=True;
              aItem.IsCalendarUser:=IsCalendarUser;
              aItem.CurrentUserPrincipal:='/users/'+Data.Users.FieldByName('NAME').AsString;
              //Select last SQL_ID as ctag
              aDel := TDeletedItems.Create(nil);
              aDel.ActualLimit:=1;
              aDel.SortFields:='TIMESTAMPD';
              aDel.SortDirection:= sdDescending;
              aDel.Open;
              aCal := TCalendar.Create(nil);
              aCal.SelectByUser(Data.Users.Accountno.AsString);
              aCal.ActualLimit:=1;
              aCal.SortFields:='TIMESTAMPD';
              aCal.SortDirection:= sdDescending;
              aCal.Open;
              if aCal.TimeStamp.AsDateTime>aDel.TimeStamp.AsDateTime then
                aItem.Properties.Values['getctag'] := StringReplace(aCal.TimeStamp.AsString,' ','',[rfReplaceAll])
              else
                aItem.Properties.Values['getctag'] := StringReplace(aDel.TimeStamp.AsString,' ','',[rfReplaceAll]);
              aItem.Properties.Values['getetag'] := Data.Users.Id.AsString;
              aItem.Properties.Values['getcontenttype'] := 'text/calendar';
              aItem.Properties.Values['displayname'] := aItem.Name;
              aDel.Free;
              if (aDepth>0) and (aDir <> '') then
                begin
                  aCal.SelectByIdAndTime(Data.Users.Id.AsVariant,Now()-30,Now()+180);
                  aCal.ActualLimit:=100;
                  aCal.Open;
                  while not aCal.EOF do
                    begin
                      if aCal.FieldByName('ORIGID').AsString<>'' then
                        aItem := TDAVFile.Create(aFullDir+aCal.FieldByName('ORIGID').AsString+'.ics')
                      else
                        aItem := TDAVFile.Create(aFullDir+aCal.Id.AsString+'.ics');
                      aItem.Properties.Values['getetag'] := aCal.Id.AsString+IntToStr(trunc(frac(aCal.TimeStamp.AsDateTime)*1000));
                      aItem.Properties.Values['getcontenttype'] := 'text/calendar; component=vevent';
                      aDirList.Add(aItem);
                      aCal.Next;
                    end;
                  aTasks := TTaskList.Create(nil);
                  aTasks.SelectActiveByUser(Data.Users.Accountno.AsString);
                  aTasks.Open;
                  while not aTasks.EOF do
                    begin
                      if aTasks.FieldByName('ORIGIDS').AsString<>'' then
                        aItem := TDAVFile.Create(aFullDir+aTasks.FieldByName('ORIGIDS').AsString+'.ics')
                      else
                        aItem := TDAVFile.Create(aFullDir+aTasks.Id.AsString+'.ics');
                      aItem.Properties.Values['getetag'] := aTasks.Id.AsString+IntToStr(trunc(frac(aTasks.TimeStamp.AsDateTime)*1000));
                      aItem.Properties.Values['getcontenttype'] := 'text/calendar; component=vtodo';
                      aDirList.Add(aItem);
                      aTasks.Next;
                    end;
                  aTasks.Free;
                end;
              aCal.Free;
            end
          else
            begin
              aDirList.Remove(aItem);
              aItem.Free;
            end;
          while not aDirs.EOF do
            begin
              TmpPath := aBaseDir+aDirs.Text.AsString;
              tmp2 := copy(aFullDir,0,length(TmpPath));
              tmp3 := copy(TmpPath,0,length(tmp2));
              if tmp2=tmp3 then
                begin
                  if not (Assigned(aItem) and (aItem.Path = aBaseDir+aDirs.Text.AsString+'/')) then
                    begin
                      aItem := TDAVFile.Create(aBaseDir+aDirs.Text.AsString+'/',True);
                      if Assigned(aDirList) then
                        aDirList.Add(aItem)
                      else aDirList := aItem;
                    end;
                  if (aBaseDir+aDirs.Text.AsString+'/' = aItem.Path) or (aDir = '') then
                    begin
                      aItem.IsCalendar:=True;
                      aItem.IsCalendarUser:=IsCalendarUser;
                      aItem.CurrentUserPrincipal:='/users/'+Data.Users.FieldByName('NAME').AsString;
                      aDel := TDeletedItems.Create(nil);
                      aDel.ActualLimit:=1;
                      aDel.SortFields:='TIMESTAMPD';
                      aDel.SortDirection:= sdDescending;
                      aDel.Open;
                      aCal := TCalendar.Create(nil);
                      aCal.ActualLimit:=1;
                      aCal.Filter(Data.QuoteField('REF_ID_ID')+'='+Data.QuoteValue(aDirs.Id.AsString));
                      aCal.SortFields:='TIMESTAMPD';
                      aCal.SortDirection:= sdDescending;
                      aCal.Open;
                      if aCal.TimeStamp.AsDateTime>aDel.TimeStamp.AsDateTime then
                        aItem.Properties.Values['getctag'] := StringReplace(aCal.TimeStamp.AsString,' ','',[rfReplaceAll])
                      else
                        aItem.Properties.Values['getctag'] := StringReplace(aDel.TimeStamp.AsString,' ','',[rfReplaceAll]);
                      aItem.Properties.Values['getetag'] := aDirs.Id.AsString;
                      aItem.Properties.Values['getcontenttype'] := 'text/calendar';
                      aItem.Properties.Values['displayname'] := aItem.Name;
                      aItem.CalendarHomeSet:='/caldav/';
                      aDel.Free;
                      if aDepth>0 then
                        begin
                          aCal.SelectByIdAndTime(aDirs.Id.AsVariant,Now(),Now()+90); //3 month in future
                          aCal.ActualLimit:=100;
                          aCal.Open;
                          while not aCal.EOF do
                            begin
                              if aCal.FieldByName('ORIGID').AsString<>'' then
                                aItem := TDAVFile.Create(aFullDir+aCal.FieldByName('ORIGID').AsString+'.ics')
                              else
                                aItem := TDAVFile.Create(aFullDir+aCal.Id.AsString+'.ics');
                              aItem.Properties.Values['D:getetag'] := aCal.Id.AsString+IntToStr(trunc(frac(aCal.TimeStamp.AsDateTime)*1000));
                              aItem.Properties.Values['D:getcontenttype'] := 'text/calendar; component=vevent';
                              aDirList.Add(aItem);
                              aCal.Next;
                            end;
                        end;
                      aCal.Free;
                    end
                  else aItem.Free;
                end;
              aDirs.Next;
            end;
          aDirs.Free;
          Result:=True;
        end
      else Result := False;
    end
  //Standard CardDAV Paths
  else if (copy(aDir,0,8) = '/carddav')
       or (copy(aDir,0,20) = '/.well-known/carddav')
    then
    begin
      aFullDir := aDir;
      if copy(aFullDir,length(aFullDir),1) <> '/' then
        aFullDir := aFullDir+'/';
      aDir := copy(aDir,10,length(aDir));
      if copy(aDir,length(aDir),1) = '/' then
        aDir := copy(aDir,0,length(aDir)-1);
      if Data.Users.DataSet.Active then
        begin
          if aDir = '' then
            aDirList := TDAVDirectoryList.Create
          else aDirList:=nil;
          if (copy(aDir,RPos('/',aDir)+1,length(aDir)) = 'user') then
            begin
              IsCalendarUser := True;
              aDir := copy(aDir,0,rpos('/',aDir)-1);
            end;
          //Add CardDAV Books
          aDirs := TTree.Create(nil);
          aDirs.Filter(Data.QuoteField('TYPE')+'='+Data.QuoteValue('F'));
          while not aDirs.EOF do
            begin
              aItem := TDAVFile.Create(aFullDir+aDirs.Text.AsString,True);
              if (aDir = aItem.Name) or (aDir = '') then
                begin
                  aItem.IsCalendar:=True;
                  aItem.IsCalendarUser:=IsCalendarUser;
                  aCal := TCalendar.Create(nil);
                  aCal.Filter(Data.QuoteField('REF_ID_ID')+'='+Data.QuoteValue(aDirs.Id.AsString));
                  //if aCal.TimeStamp.AsDateTime<aDel.TimeStamp.AsDateTime then
                    aItem.Properties.Values['getctag'] := StringReplace(aCal.TimeStamp.AsString,' ','',[rfReplaceAll])
                  //else
                  //  aItem.Properties.Values['getctag'] := Stringreplace(aDel.TimeStamp.AsString,' ','',[rfReplaceAll])
                  ;
                  aItem.Properties.Values['getetag'] := aDirs.Id.AsString;
                  aItem.Properties.Values['getcontenttype'] := 'text/calendar';
                  aItem.Properties.Values['displayname'] := aItem.Name;
                  aItem.CalendarHomeSet:='/caldav/';
                  if Assigned(aDirList) then
                    aDirList.Add(aItem)
                  else aDirList := aItem;
                  if aDepth>0 then
                    begin
                      aCal.SelectByIdAndTime(aDirs.Id.AsVariant,Now(),Now()+90); //3 month in future
                      aCal.ActualLimit:=100;
                      aCal.Open;
                      while not aCal.EOF do
                        begin
                          if aCal.FieldByName('ORIGID').AsString<>'' then
                            aItem := TDAVFile.Create(aFullDir+aCal.FieldByName('ORIGID').AsString+'.ics')
                          else
                            aItem := TDAVFile.Create(aFullDir+aCal.Id.AsString+'.ics');
                          aItem.Properties.Values['D:getetag'] := aCal.Id.AsString+IntToStr(trunc(frac(aCal.TimeStamp.AsDateTime)*1000));
                          aItem.Properties.Values['D:getcontenttype'] := 'text/calendar; component=vevent';
                          aDirList.Add(aItem);
                          aCal.Next;
                        end;
                    end;
                  aCal.Free;
                end
              else aItem.Free;
              aDirs.Next;
            end;
          aDirs.Free;
          Result:=True;
        end
      else Result := False;
    end
  //Ical Calendar
  else if copy(aDir,0,5) = '/ical' then
    begin
      if Data.Users.DataSet.Active then
        begin
          aFullDir := aDir;
          if copy(aFullDir,length(aFullDir),1) <> '/' then
            aFullDir := aFullDir+'/';
          aDir := copy(aDir,7,length(aDir));
          //Add ics file
          aItem := TDAVFile.Create(aFullDir+Data.Users.Text.AsString+'.ics',False);
          if (aDir = aItem.Name) or (aDir = '') then
            begin
              aItem.Properties.Values['getcontenttype'] := 'text/calendar';
              aItem.Properties.Values['creationdate'] := BuildISODate(Now());
              aItem.Properties.Values['getlastmodified'] := FormatDateTime('ddd, dd mmm yyyy hh:nn:ss',LocalTimeToGMT(Now()),WebFormatSettings)+' GMT';
              sl := TStringList.Create;
              {
              aCal := TCalendar.Create(nil);
              aCal.SelectByUser(Data.Users.Accountno.AsString);
              aCal.Open;
              VCalExport(aCal,sl);
              aCal.Free;
              Stream := TMemoryStream.Create;
              sl.SaveToStream(Stream);
              aItem.Properties.Values['getcontentlength'] := IntToStr(Stream.Size);
              Stream.Free;
              sl.Free;
              }
              if Assigned(aDirList) then
                aDirList.Add(aItem)
              else aDirList := aItem;
            end
          else aItem.Free;
        end
      else Result:=False;
    end
  //Files from Documents/Files
  else if FindVirtualDocumentPath(aRemovedDir,aDir,aID,aType,aLevel) then
    begin
      if aLevel = 6 then
        begin
          aDocuments := TDocuments.Create(nil);
          aDocuments.Select(aId,aType,0);
          aDocuments.Open;
          aFile := '';
          if copy(aDir,length(aDir),1) <> '/' then
            begin
              aFile := ExtractFileName(aDir);
              aDir := copy(aDir,0,rpos('/',aDir)-1);
            end;
          if aDocuments.OpenPath(aDir,'/') then
            Result := AddDocumentsToFileList(aDirList,aDocuments,aRemovedDir+aDir,aFile)
          else
            begin
              aDir := copy(aDir,0,length(aDir)-1);
              aFile := HTTPDecode(copy(aDir,rpos('/',aDir)+1,length(aDir)));
              aDir := copy(aDir,0,rpos('/',aDir));
              if ((aDir = '') or (aDir = '/') or aDocuments.OpenPath(aDir,'/')) and (aDocuments.Active) then
                begin
                  aDocuments.DataSet.First;
                  while not aDocuments.DataSet.EOF do
                    begin
                      if aDocuments.FileName = aFile then
                        AddDocumentToFileList(aDirList,aDocuments,aRemovedDir+aDir+aFile);
                      aDocuments.DataSet.Next;
                    end;
                end;
              Result := True;
            end;
          aDocuments.Free;
        end
      else if aLevel=1 then
        begin
          if copy(aFullDir,length(aFullDir),1) <> '/' then
            aFullDir := aFullDir+'/';
          aItem := TDAVFile.Create(aFullDir+'by-id',True);
          aDirList.Add(aItem);
          Result:=True;
        end
      else if aLevel=2 then //by-id
        begin
          if copy(aFullDir,length(aFullDir),1) <> '/' then
            aFullDir := aFullDir+'/';
          Result:=True;
        end;
    end;
  except
    Result:=False;
  end;
end;
function TPrometServerFunctions.ServerGetFile(aSocket: TDAVSession; aDir: string;
  Stream: TStream; var LastModified: TDateTime; var MimeType: string;
  var eTag: string): Boolean;
var
  aDocuments: TDocuments;
  aDocument: TDocument;
  aFileName: String;
  lIndex: Integer;
  sl: TStringList;
  aCal: TCalendar;
  aFullDir: String;
  aFile: String;
  aParent,aDirPar : Variant;
  aDirs: TTree;
  aTasks: TTaskList;
  aID: Variant;
  aType: string;
  aLevel: Integer;
  aRemovedDir: string;
begin
  Result := False;
  if aSocket.User='' then exit;
  if not Data.Users.Locate('SQL_ID',aSocket.User,[]) then
    begin
      Data.Users.Filter('',0);
      if not Data.Users.Locate('SQL_ID',aSocket.User,[]) then exit;
    end;
  if aDir = 'ical/'+Data.Users.Text.AsString+'.ics' then
    begin
      sl := TStringList.Create;
      aCal := TCalendar.Create(nil);
      aCal.SelectByUser(Data.Users.Accountno.AsString);
      aCal.Open;
      VCalExport(aCal,sl);
      sl.SaveToStream(Stream);
      aCal.Free;
      sl.Free;
      Result := True;
    end
  else if (copy(aDir,0,7) = 'caldav/')
       or (copy(aDir,0,7) = '/caldav')
       or (copy(aDir,0,19) = '/.well-known/caldav')
       then
    begin
      aFullDir := aDir;
      if copy(aFullDir,0,1) = '/' then
        aFullDir := copy(aFullDir,2,length(aFullDir)-1);
      aDir := copy(aDir,8,length(aDir));
      if copy(aDir,0,1) = '/' then
        aDir := copy(aDir,2,length(aDir)-1);
      if copy(aDir,length(aDir),1) = '/' then
        aDir := copy(aDir,0,length(aDir)-1);
      aFile := StringReplace(copy(aDir,rpos('/',aDir)+1,length(aDir)),'.ics','',[]);
      aDir := copy(aDir,0,rpos('/',aDir)-1);
      if aDir = 'home' then
        begin
          aParent := Data.Users.Id.AsVariant;
          result := True;
        end
      else
        begin
          aDirs := TTree.Create(nil);
          aDirs.Filter(Data.QuoteField('TYPE')+'='+Data.QuoteValue('A'));
          aDirPar := null;
          Result := True;
          while pos('/',aDir)>0 do
            begin
              if aDirs.Locate('PARENT;NAME',VarArrayOf([aDirPar,copy(aDir,0,pos('/',aDir)-1)]),[]) then
                begin
                  aDirPar := aDirs.FieldByName('PARENT').AsVariant;
                  aDir := copy(aDir,pos('/',aDir)+1,length(aDir));
                end
              else
                begin
                  Result := False;
                  aDirs.Free;
                  exit;
                end;
            end;
          aParent := aDirs.Id.AsVariant;
        end;
      aCal := TCalendar.Create(nil);
      aCal.Filter(Data.QuoteField('ORIGID')+'='+Data.QuoteValue(aFile));
      if (aCal.Count=0) and IsNumeric(aFile) then
        begin
          aCal.Select(aFile);
          aCal.Open;
        end;
      Result := aCal.Count>=1;
      if Result then
        begin
          eTag:=aCal.Id.AsString+IntToStr(trunc(frac(aCal.TimeStamp.AsDateTime)*1000));
          sl := TStringList.Create;
          VCalExport(aCal,sl);
          sl.SaveToStream(Stream);
          sl.Free;
        end;
      aCal.Free;
      if (not result) and (aDir = 'home') then //check for taks
        begin
          aTasks := TTaskList.Create(nil);
          aTasks.Filter(Data.QuoteField('ORIGIDS')+'='+Data.QuoteValue(aFile));
          if (aTasks.Count=0) and IsNumeric(aFile) then
            begin
              aTasks.Select(aFile);
              aTasks.Open;
            end;
          Result := aTasks.Count>=1;
          if Result then
            begin
              eTag:=aTasks.Id.AsString+IntToStr(trunc(frac(aTasks.TimeStamp.AsDateTime)*1000));
              sl := TStringList.Create;
              VTodoExport(aTasks,sl);
              sl.SaveToStream(Stream);
              sl.Free;
            end;
          aTasks.Free;
        end;
    end
  else if FindVirtualDocumentPath(aRemovedDir,aDir,aID,aType,aLevel) then
    begin
      Mimetype := '';
      if aLevel=6 then
        begin
          aDocuments := TDocuments.Create(nil);
          try
          aDocuments.Select(aId,aType,0);
          aDocuments.Open;
          if rpos('/',aDir) > 1 then
            Result := aDocuments.OpenPath(copy(aDir,0,rpos('/',aDir)),'/')
          else Result := True;
          if Result then
            begin
              Result := False;
              aDir := copy(aDir,rpos('/',aDir)+1,length(aDir));
              if aDocuments.SelectFile(aDir) then
                begin
                  aDocument := TDocument.Create(nil);
                  try
                  aDocument.SelectByNumber(aDocuments.DataSet.FieldByName('NUMBER').AsVariant);
                  aDocument.Open;
                  if aDocument.Count > 0 then
                    begin
                      aDocument.CheckoutToStream(Stream);
                      LastModified:=aDocument.LastModified;
                      if MimeType = '' then
                        MimeType := GetMimeTypeforExtension(ExtractFileExt(aDocuments.FileName));
                      Result := True;
                    end;
                  finally
                    aDocument.Free;
                  end;
                end;
            end;
          finally
            aDocuments.Free;
          end;
        end;
    end;
end;
function TPrometServerFunctions.ServerMkCol(aSocket: TDAVSession; aDir: string): Boolean;
var
  aDocuments: TDocuments;
  aDocument: TDocument;
  Subfolder: Boolean = False;
  aId: Variant;
  aType: string;
  aLevel: Integer;
  aRemovedDir: string;
begin
  Result := False;
  if aSocket.User='' then exit;
  if not Data.Users.Locate('SQL_ID',aSocket.User,[]) then
    begin
      Data.Users.Filter('',0);
      if not Data.Users.Locate('SQL_ID',aSocket.User,[]) then exit;
    end;
  Data.RefreshUsersFilter;
  if FindVirtualDocumentPath(aRemovedDir,aDir,aId,aType,aLevel) then
    begin
      if aLevel=6 then
        begin
          aDocuments := TDocuments.Create(nil);
          aDocuments.Select(aId,aType,0);
          aDocuments.Open;
          if copy(aDir,length(aDir),1)='/' then
            aDir := copy(aDir,0,length(aDir)-1);
          if (rpos('/',aDir) > 1) then
            begin
              Result := aDocuments.OpenPath(copy(aDir,0,rpos('/',aDir)-1),'/');
              Subfolder := True;
            end
          else Result := True;
          if Result then
            begin
              Result := False;
              aDir := copy(aDir,rpos('/',aDir)+1,length(aDir));
              aDocument := TDocument.Create(nil);
              if SubFolder then
                aDocument.BaseParent := aDocuments
              else
                begin
                  aDocument.Ref_ID := aDocuments.Ref_ID;
                  aDocument.BaseTyp:=aDocuments.BaseTyp;
                  aDocument.BaseID:=aDocuments.BaseID;
                  aDocument.BaseVersion:=aDocuments.BaseVersion;
                  aDocument.BaseLanguage:=aDocuments.BaseLanguage;
                end;
              aDocument.Insert;
              aDocument.CreateDirectory(aDir);
              aDocument.Free;
              Result := True;
            end;
          aDocuments.Free;
        end;
    end;
end;
function TPrometServerFunctions.ServerPutFile(aSocket: TDAVSession; aDir: string;
  Stream: TStream; var eTag: string; var FStatus: Integer): Boolean;
var
  aDocuments: TDocuments;
  aDocument: TDocument;
  aFileName: String;
  aFStream: TFileStream;
  aFiles: TStrings;
  aDocuments2: TDocuments;
  aFullDir: String;
  aParent,aDirPar : Variant;
  aDirs: TTree;
  aFile: String;
  aCal: TCalendar;
  sl: TStringList;
  aTasks: TTaskList;
  aID: Variant;
  aType: string;
  aLevel: Integer;
  aRemovedDir: string;
begin
  Result := False;
  if aSocket.User='' then exit;
  if not Data.Users.Locate('SQL_ID',aSocket.User,[]) then
    begin
      Data.Users.Filter('',0);
      if not Data.Users.Locate('SQL_ID',aSocket.User,[]) then exit;
    end;
  Result := True;
  Data.RefreshUsersFilter;
  if copy(aDir,0,1)<>'/' then
    aDir := '/'+aDir;
  if (copy(aDir,0,7) = '/caldav')
  or (copy(aDir,0,19) = '.well-known/caldav')
  then
    begin
      aFullDir := aDir;
      aDir := copy(aDir,9,length(aDir));
      if copy(aDir,length(aDir),1) = '/' then
        aDir := copy(aDir,0,length(aDir)-1);
      aFile := StringReplace(copy(aDir,rpos('/',aDir)+1,length(aDir)),'.ics','',[]);
      aDir := copy(aDir,0,rpos('/',aDir)-1);
      if aDir = 'home' then
        begin
          aParent := Data.Users.Id.AsVariant;
          result := True;
        end
      else
        begin
          aDirs := TTree.Create(nil);
          aDirs.Filter(Data.QuoteField('TYPE')+'='+Data.QuoteValue('A'));
          aDirPar := null;
          Result := True;
          while pos('/',aDir)>0 do
            begin
              if aDirs.Locate('PARENT;NAME',VarArrayOf([aDirPar,copy(aDir,0,pos('/',aDir)-1)]),[]) then
                begin
                  aDirPar := aDirs.FieldByName('PARENT').AsVariant;
                  aDir := copy(aDir,pos('/',aDir)+1,length(aDir));
                end
              else
                begin
                  Result := False;
                  aDirs.Free;
                  exit;
                end;
            end;
          if not aDirs.Locate('PARENT;NAME',VarArrayOf([aDirPar,aDir]),[]) then
            aDirs.Locate('NAME',VarArrayOf([aDir]),[]);
          aParent := aDirs.Id.AsVariant;
        end;
      sl := TStringList.Create;
      Stream.Position:=0;
      sl.LoadFromStream(Stream);
      aCal := TCalendar.Create(nil);
      aCal.Filter(Data.QuoteField('ORIGID')+'='+Data.QuoteValue(aFile));
      if (aCal.Count=0) and IsNumeric(aFile) then
        begin
          aCal.Select(aFile);
          aCal.Open;
        end;
      Result := aCal.Count>=1;
      if Result then
        begin
          eTag:=aCal.Id.AsString+IntToStr(trunc(frac(aCal.TimeStamp.AsDateTime)*1000));
          aCal.Edit;
          if aCal.FieldByName('REF_ID_ID').AsVariant<>aParent then
            aCal.FieldByName('REF_ID_ID').AsVariant:=aParent;
          if not VCalImport(aCal,sl,True) then
            Result := False
          else
            FStatus:=200;
        end
      else
        begin
          //todo ???
          aTasks := TTaskList.Create(nil);
          aTasks.Filter(Data.QuoteField('ORIGIDS')+'='+Data.QuoteValue(aFile));
          if (aTasks.Count=0) and IsNumeric(aFile) then
            begin
              aTasks.Select(aFile);
              aTasks.Open;
            end;
          Result := aTasks.Count>=1;
          if Result then  //edit task
            begin
              eTag:=aTasks.Id.AsString+IntToStr(trunc(frac(atasks.TimeStamp.AsDateTime)*1000));
              aTasks.Edit;
              if not VTodoImport(aTasks,sl,True) then
                Result := False
              else
                FStatus:=200;
            end;
          if (not Result) and (pos(':vtodo',lowercase(sl.Text))>0) then //new task
            begin
              Result := True;
              aTasks.Insert;
              if not VTodoImport(aTasks,sl,True) then
                result := False;
              eTag:=aTasks.Id.AsString+IntToStr(trunc(frac(aTasks.TimeStamp.AsDateTime)*1000));
              FStatus:=201;
            end;
          atasks.Free;
          if not result then //New file
            begin
              Result := True;
              aCal.Insert;
              aCal.FieldByName('REF_ID_ID').AsVariant:=aParent;
              if not VCalImport(aCal,sl,True) then
                result := False;
              eTag:=aCal.Id.AsString+IntToStr(trunc(frac(aCal.TimeStamp.AsDateTime)*1000));
              FStatus:=201;
            end;
        end;
      aCal.Free;
      sl.Free;
    end
  else if FindVirtualDocumentPath(aRemovedDir,aDir,aID,aType,aLevel) then
    begin
      if aLevel=6 then
        begin
          aDocuments := TDocuments.Create(nil);
          aDocuments.Select(aID,aType,0);
          aDocuments.Open;
          if rpos('/',aDir) > 1 then
            Result := aDocuments.OpenPath(copy(aDir,0,rpos('/',aDir)-1),'/')
          else Result := True;
          aDocuments2 := TDocuments.Create(nil);
          aDocuments2.Select(aID,aType,0);
          aDocuments2.Open;
          if rpos('/',aDir) > 1 then
            Result := aDocuments2.OpenPath(copy(aDir,0,rpos('/',aDir)),'/')
          else Result := True;
          if Result then
            begin
              Result := False;
              aDocument := TDocument.Create(nil);
              aFileName := ExtractFileName(aDir);
              if ADocuments2.SelectFile(aFileName) then //Checkin existing File
                begin
                  aDocument.SelectByNumber(aDocuments2.DataSet.FieldByName('NUMBER').AsString);
                  aDocument.Open;
                  ForceDirectories(GetTempDir+'promettemp');
                  aFStream := TFileStream.Create(AppendPathDelim(GetTempDir+'promettemp')+aDocuments2.FileName,fmCreate);
                  Stream.Position:=0;
                  aFStream.CopyFrom(Stream,Stream.Size);
                  aFStream.Free;
                  aFiles := aDocument.CollectCheckInFiles(GetTempDir+'promettemp');
                  aDocument.CheckinFiles(aFiles,GetTempDir+'promettemp');
                  Result := True;
                end
              else
                begin //Create new file
                  aDocument.BaseParent := aDocuments;
                  if rpos('.',aFileName) > 0 then
                    aDocument.AddFromStream(copy(aFileName,0,rpos('.',aFileName)-1),copy(ExtractFileExt(aFileName),2,length(aFileName)),Stream)
                  else
                    aDocument.AddFromStream(aFileName,'',Stream);
                  Result := True;
                end;
                aDocument.Free;
            end;
          aDocuments.Free;
          aDocuments2.Free;
        end;
    end;
end;
function TPrometServerFunctions.ServerReadAllowed(aSocket: TDAVSession; aDir: string
  ): Boolean;
begin
  Result := aSocket.User<>'';
end;
function TPrometServerFunctions.ServerUserLogin(aSocket: TDAVSession; aUser,
  aPassword: string): Boolean;
begin
  Data.Users.Open;
  Result := (Data.Users.DataSet.Locate('NAME',aUser,[]) or Data.Users.DataSet.Locate('LOGINNAME',aUser,[])) and (Data.Users.Leaved.IsNull);
  if Result then
    Result := Data.Users.CheckPasswort(trim(aPassword));
  if not Result then
    begin
      aSocket.User:='';
      writeln('Auth from "'+aUser+'" failed !');
    end
  else aSocket.User:=Data.Users.Id.AsString;
end;

function TPrometServerFunctions.FindVirtualDocumentPath(var aRemovedDir,aDir: string;
  var aID: Variant; var aType: string; var aLevel : Integer = 0): Boolean;
var
  i: Integer;
  DataSet: TBaseDBList;
  tmp: String;
begin
  Result := False;
  if copy(aDir,0,7)='/webdav' then
    begin
      aRemovedDir:='/webdav/';
      aDir := copy(aDir,9,length(aDir));
      aId := 1;
      aType := 'D';
      aLevel:=6;
      Result := True;
    end
  else
    begin
      for i := 0 to length(DatasetClasses)-1 do
        begin
          tmp := DatasetClasses[i].aName;
          tmp := copy(aDir,0,length(tmp)+1);
          if (DatasetClasses[i].aClass.InheritsFrom(TBaseDBList)
          and (tmp='/'+lowercase(DatasetClasses[i].aName))) then
            begin
              aLevel := 1;
              Result:=True;
              if pos('/',copy(aDir,2,length(aDir)))>0 then
                aRemovedDir:=copy(aDir,0,pos('/',copy(aDir,2,length(aDir)))+2)
              else aRemovedDir:=aDir;
              aDir := copy(aDir,pos('/',copy(aDir,2,length(aDir)))+2,length(aDir));
              if (copy(aDir,0,pos('/',aDir)-1)='by-id') or (aDir = 'by-id') then
                begin
                  aLevel:=2;
                  aRemovedDir+='by-id/';
                  aDir := copy(aDir,pos('/',aDir)+1,length(aDir));
                  if length(aDir)>0 then
                    begin
                      DataSet := TBaseDbList(TBaseDbListClass(DatasetClasses[i].aClass).Create(nil));
                      if Assigned(DataSet) then
                        begin
                          DataSet.SelectFromNumber(copy(aDir,0,pos('/',aDir)-1));
                          DataSet.Open;
                          Result := DataSet.Count>0;
                          aID:=DataSet.Id.AsVariant;
                          aType:= DataSet.GetTyp;
                          DataSet.Free;
                          if Result then aLevel:=6;
                        end;
                    end;
                end;
              break;
            end;
        end;
    end;
end;

function TPrometServerFunctions.AddDocumentsToFileList(
  aFileList: TDAVDirectoryList; aDocuments: TDocuments; aPath, aFilter: string
  ): Boolean;
var
  aFile: TDAVFile;
  lIndex: Integer;
begin
  Result := False;
  aDocuments.DataSet.First;
  while not aDocuments.DataSet.EOF do
    begin
      if (aFilter = '') or (aDocuments.FileName=aFilter) then
        begin
          AddDocumentToFileList(aFileList,aDocuments,aPath+aDocuments.FileName);
          Result := True;
        end;
      aDocuments.DataSet.Next;
    end;
end;
procedure TPrometServerFunctions.AddDocumentToFileList(aFileList: TDAVDirectoryList;
  aDocuments: TDocuments;FullPath : string);
var
  aFile: TDAVFile;
  lIndex: Integer;
begin
  aFile := TDAVFile.Create(FullPath,aDocuments.IsDir);
  if not aDocuments.IsDir then
    begin
      //TODO:fix this
      {
      if Assigned(MimeList) then
        begin
          lIndex := MimeList.IndexOf(ExtractFileExt(aDocuments.FileName));
          if lIndex >= 0 then
            aFile.Properties.Values['getcontenttype'] := TStringObject(MimeList.Objects[lIndex]).Str;
        end;
      }
      if aFile.Properties.Values['getcontenttype'] = '' then
        aFile.Properties.Values['getcontenttype'] := GetMimeTypeforExtension(ExtractFileExt(aDocuments.FileName));
      if aFile.Properties.Values['getcontenttype'] = '' then
        aFile.Properties.Values['getcontenttype'] := 'text/plain';
      aFile.Properties.Values['creationdate'] := BuildISODate(aDocuments.CreationDate);
      aFile.Properties.Values['getlastmodified'] := FormatDateTime('ddd, dd mmm yyyy hh:nn:ss',LocalTimeToGMT(aDocuments.LastModified),WebFormatSettings)+' GMT';
      aFile.Properties.Values['getcontentlength'] := IntToStr(max(aDocuments.Size,0));
      aFile.Properties.Values['getetag'] := aDocuments.Number.AsString+IntToStr(trunc(frac(aDocuments.TimeStamp.AsDateTime)*1000));
      aFile.CurrentUser:='/users/'+Data.Users.FieldByName('NAME').AsString;
    end;
  aFile.Properties.Values['creationdate'] := BuildISODate(aDocuments.CreationDate);
  aFileList.Add(aFile);
end;

end.

