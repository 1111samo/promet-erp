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
unit uProcessManagement;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils,uBaseDbClasses,db,UTF8Process;
type
  TProcProcess = class(TProcessUTF8)
  private
    FId: Variant;
    FInformed: Boolean;
    FName: string;
    FTimeout: TDateTime;
    procedure SetTimeout(AValue: TDateTime);
  public
    aOutput,aBuffer,aLogOutput : string;
    property Timeout : TDateTime read FTimeout write SetTimeout;
    property Informed : Boolean read FInformed write FInformed;
    property Name : string read FName write FName;
    property Id : Variant read FId write FId;
    procedure Execute; override;
    procedure DoExit;
  end;

  TProcessParameters = class(TBaseDBDataset)
  public
    procedure DefineFields(aDataSet: TDataSet); override;
  end;
  TProcesses = class(TBaseDBDataset)
  private
    FProcessParameters: TProcessParameters;
  public
    constructor Create(aOwner: TComponent; DM: TComponent;
      aConnection: TComponent=nil; aMasterdata: TDataSet=nil); override;
    destructor Destroy; override;
    function CreateTable : Boolean;override;
    procedure DefineFields(aDataSet: TDataSet); override;
    property Parameters : TProcessParameters read FProcessParameters;
  end;

  { TProcessClient }

  TProcessClient = class(TBaseDBDataset)
  private
    FLastRefresh: TDateTime;
    FProcesses: TProcesses;
    ProcessData : array of TProcProcess;
  public
    constructor Create(aOwner: TComponent; DM: TComponent;
       aConnection: TComponent=nil; aMasterdata: TDataSet=nil); override;
    destructor Destroy; override;
    function CreateTable : Boolean;override;
    procedure DefineFields(aDataSet: TDataSet); override;
    property Processes : TProcesses read FProcesses;
    property LastRefresh : TDateTime read FLastRefresh;
    procedure RefreshList;
    function Process : Boolean;
  end;

implementation
uses uBaseDBInterface,uData,FileUtil,uBaseApplication,uIntfStrConsts,math,
  process;
procedure TProcProcess.SetTimeout(AValue: TDateTime);
begin
  if FTimeout=AValue then Exit;
  FTimeout:=AValue;
end;
procedure TProcProcess.Execute;
var
  aProc: TProcesses;
begin
  aProc := uProcessManagement.TProcesses.Create(nil,Data);
  aProc.Select(Id);
  aProc.Open;
  if aProc.Count > 0 then
    begin
      aProc.DataSet.Edit;
      aProc.FieldByName('STATUS').AsString:='R';
      aProc.DataSet.Post;
    end;
  inherited Execute;
  aProc.Free;
end;

procedure TProcProcess.DoExit;
var
  aProc: TProcesses;
begin
  aProc := uProcessManagement.TProcesses.Create(nil,Data);
  aProc.Select(Id);
  aProc.Open;
  if aProc.Count > 0 then
    begin
      aProc.DataSet.Edit;
      aProc.FieldByName('STATUS').AsString:='N';
      aProc.DataSet.Post;
    end;
  aProc.Free;
end;
procedure TProcessParameters.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'PROCESSPARAMETERS';
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('NAME',ftString,60,True);
            Add('VALUE',ftString,60,False);
          end;
    end;
end;

constructor TProcesses.Create(aOwner: TComponent; DM: TComponent;
      aConnection: TComponent=nil; aMasterdata: TDataSet=nil);
begin
  inherited;
  FProcessParameters := TProcessParameters.Create(Self, DM,aConnection,DataSet);
end;

destructor TProcesses.Destroy;
begin
  FProcessParameters.Destroy;
  inherited Destroy;
end;

function TProcesses.CreateTable : Boolean;
begin
  Result := inherited CreateTable;
  FProcessParameters.CreateTable;
end;

procedure TProcesses.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'PROCESS';
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('NAME',ftString,250,True);
            Add('INTERVAL',ftInteger,0,False);
            Add('STATUS',ftString,4,False);
            Add('STARTED',ftDateTime,0,False);
            Add('STOPPED',ftDateTime,0,False);
            Add('LOG',ftMemo,0,False);
          end;
    end;
end;

constructor TProcessClient.Create(aOwner: TComponent; DM: TComponent;
  aConnection: TComponent; aMasterdata: TDataSet);
begin
  inherited;
  FProcesses := TProcesses.Create(Self, DM,aConnection,DataSet);
end;

destructor TProcessClient.Destroy;
var
  i: Integer;
begin
  for i := 0 to length(ProcessData)-1 do
    ProcessData[i].Free;
  FProcesses.Destroy;
  inherited Destroy;
end;

function TProcessClient.CreateTable : Boolean;
begin
  Result := inherited CreateTable;
  FProcesses.CreateTable;
end;

procedure TProcessClient.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'PROCESSCLIENTS';
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('NAME',ftString,60,True);
            Add('STATUS',ftString,4,True);
            Add('NOTES',ftString,200,False);
          end;
    end;
end;

procedure TProcessClient.RefreshList;
var
  aNow: TDateTime;
begin
  aNow := Now();
  if aNow>0 then
    begin
      //Refresh all Minute
      if aNow>(LastRefresh+((1/SecsPerDay)*60)) then
        begin
          DataSet.Refresh;
          Processes.DataSet.Refresh;
          FLastRefresh:=Now();
        end;
    end;
end;

function TProcessClient.Process: Boolean;
var
  aLog: TStringList;
  aProcess: String;
  Found: Boolean;
  cmd: String;
  i: Integer;
  bProcess: TProcProcess;
  sl: TStringList;
  a: Integer;
  aNow: TDateTime;
  NewProcess: TProcProcess;
  procedure DoLog(aStr: string;bLog : TStringList);
  begin
    with BaseApplication as IBaseApplication do
      Log(aStr);
    bLog.Add(aStr);
  end;
  function BuildCmdLine : string;
  begin
    with Data.ProcessClient.Processes.Parameters.DataSet do
      begin
        First;
        while not EOF do
          begin
            cmd := cmd+' "--'+FieldByName('NAME').AsString+'='+FieldByName('VALUE').AsString+'"';
            Next;
          end;
      end;
    if pos('--mandant',lowercase(cmd)) = 0 then
      cmd := cmd+' "--mandant='+BaseApplication.GetOptionValue('m','mandant')+'"';
    if Data.Users.DataSet.Active then
      cmd := cmd+' "--user='+Data.Users.FieldByName('NAME').AsString+'"';
    if BaseApplication.HasOption('c','config-path') then
      cmd := cmd+' "--config-path='+BaseApplication.GetOptionValue('c','config-path')+'"';
  end;
begin
  aNow := Now();
  if aNow>0 then
    begin
      aLog := TStringList.Create;
      Processes.DataSet.First;
      while not Processes.DataSet.EOF do
        begin
          aLog.Text := Processes.DataSet.FieldByName('LOG').AsString;
          aProcess := Processes.FieldByName('NAME').AsString;
          if FileExistsUTF8(ExpandFileNameUTF8(AppendPathDelim(BaseApplication.Location)+aProcess+ExtractFileExt(BaseApplication.ExeName))) then
            begin
              Found := False;
              cmd := AppendPathDelim(BaseApplication.Location)+aProcess+ExtractFileExt(BaseApplication.ExeName);
              cmd := cmd+BuildCmdLine;
              for i := 0 to length(ProcessData)-1 do
                if ProcessData[i].CommandLine = cmd then
                  begin
                    bProcess := ProcessData[i];
                    if bProcess.Active then
                      begin
                        Found := True;
                        sl := TStringList.Create;
                        sl.LoadFromStream(bProcess.Output);
                        for a := 0 to sl.Count-1 do
                          DoLog(aprocess+':'+sl[a],aLog);
                        sl.Free;
                      end
                    else
                      begin
                        sl := TStringList.Create;
                        sl.LoadFromStream(bProcess.Output);
                        for a := 0 to sl.Count-1 do
                          DoLog(aprocess+':'+sl[a],aLog);
                        sl.Free;
                        if not bProcess.Informed then
                          begin
                            DoLog(aprocess+':'+strExitted,aLog);
                            Processes.Edit;
                            Processes.DataSet.FieldByName('STOPPED').AsDateTime := Now();
                            Processes.Post;
                            if Processes.DataSet.FieldByName('LOG').AsString<>aLog.Text then
                              begin
                                if not Processes.CanEdit then Processes.DataSet.Edit;
                                Processes.DataSet.FieldByName('LOG').AsString:=aLog.Text;
                                Processes.DataSet.Post;
                              end;
                            bProcess.DoExit;
                            bProcess.Informed := True;
                          end;
                        if (aNow > bProcess.Timeout) {and (bProcess.Timeout > 0)} then
                          begin
                            DoLog(aprocess+':'+strStartingProcessTimeout+' '+DateTimeToStr(bProcess.Timeout)+'>'+DateTimeToStr(aNow),aLog);
                            bProcess.Timeout := aNow+(max(Processes.FieldByName('INTERVAL').AsInteger,2)/MinsPerDay);
                            DoLog(aProcess+':'+strStartingProcess+' ('+bProcess.CommandLine+')',aLog);
                            bProcess.Execute;
                            bProcess.Informed := False;
                            DoLog(aprocess+':'+strStartingNextTimeout+' '+DateTimeToStr(bProcess.Timeout),aLog);
                          end;
                        Found := True;
                      end;
                  end;
              if not Found then
                begin
                  aLog.Clear;
                  cmd := AppendPathDelim(BaseApplication.Location)+aProcess+ExtractFileExt(BaseApplication.ExeName);
                  cmd := cmd+BuildCmdLine;
                  DoLog(aProcess+':'+strStartingProcess+' ('+cmd+')',aLog);
                  NewProcess := TProcProcess.Create(Self);
                  {$if FPC_FULLVERSION<20400}
                  NewProcess.InheritHandles := false;
                  {$endif}
                  NewProcess.Id := Processes.Id.AsVariant;
                  NewProcess.Informed:=False;
                  Setlength(ProcessData,length(ProcessData)+1);
                  ProcessData[length(ProcessData)-1] := NewProcess;
                  NewProcess.CommandLine:=cmd;
                  NewProcess.CurrentDirectory:= CleanAndExpandDirectory(BaseApplication.Location+DirectorySeparator+'..'+DirectorySeparator);
                  NewProcess.Options := [poNoConsole,poUsePipes];
                  NewProcess.Execute;
                  NewProcess.Timeout := aNow+(max(Processes.FieldByName('INTERVAL').AsInteger,2)/MinsPerDay);
                  DoLog(aprocess+':'+strStartingNextTimeout+' '+DateTimeToStr(ProcessData[i].Timeout),aLog);
                  Processes.Edit;
                  Processes.DataSet.FieldByName('STARTED').AsDateTime := Now();
                  Processes.DataSet.FieldByName('STOPPED').Clear;
                  Processes.DataSet.FieldByName('LOG').AsString := aLog.Text;
                  Processes.Post;
                end;
            end
          else
            begin
              aLog.Clear;
              DoLog(ExpandFileNameUTF8(aProcess+ExtractFileExt(BaseApplication.ExeName))+':'+'File dosend exists',aLog);
            end;
          if Processes.DataSet.FieldByName('LOG').AsString<>aLog.Text then
            begin
              Processes.Edit;
              Processes.DataSet.FieldByName('LOG').AsString := aLog.Text;
              Processes.Post;
            end;
          Processes.DataSet.Next;
        end;
      aLog.Free;
    end;
end;

end.

