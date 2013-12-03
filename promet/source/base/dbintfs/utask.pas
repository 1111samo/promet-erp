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

info@cu-tec.de
*******************************************************************************}
unit utask;
//TODO:Trigger for updating sum(hours)
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, uBaseDbClasses, uBaseDbInterface, db, uBaseERPDBClasses,Math;
type
  TDependencies = class;
  TTaskSnapshots = class(TBaseDbDataSet)
    procedure DefineFields(aDataSet : TDataSet);override;
  end;
  TTaskList = class(TBaseERPList,IBaseHistory)
    procedure DataSetAfterPost(aDataSet: TDataSet);
    procedure DataSetBeforeDelete(aDataSet: TDataSet);
    procedure FDSDataChange(Sender: TObject; Field: TField);
  private
    FAddProjectOnPost : Boolean;
    FAddSummaryOnPost : Boolean;
    FHistory: TBaseHistory;
    FSnapshots: TTaskSnapshots;
    FTempUsers : TUser;
    FDependencies: TDependencies;
    FDS: TDataSource;
    DoCheckTask : Boolean;
    FUserID: String;
    function GetownerName: string;
    function GetUserName: string;
    function GetHistory: TBaseHistory;
  public
    procedure DefineFields(aDataSet : TDataSet);override;
    procedure FillDefaults(aDataSet : TDataSet);override;
    procedure SelectActiveByUser(AccountNo : string);
    procedure SelectActive;
    procedure SelectByUser(AccountNo : string);
    procedure SelectByDept(aDept : Variant);
    procedure SelectByParent(aParent : Variant);
    procedure SelectUncompletedByParent(aParent : Variant);
    constructor Create(aOwner : TComponent;DM : TComponent;aConnection : TComponent = nil;aMasterdata : TDataSet = nil);override;
    destructor Destroy; override;
    procedure SetDisplayLabels(aDataSet: TDataSet); override;
    function CreateTable : Boolean;override;
    procedure CascadicPost;override;
    procedure CascadicCancel;override;
    function GetTextFieldName: string;override;
    function GetNumberFieldName : string;override;
    procedure CheckChilds;
    procedure CheckDependTasks;
    procedure MoveDependTasks;
    procedure Open; override;
    function CalcDates(var aStart, aDue: TDateTime): Boolean;
    procedure MakeSnapshot(aName : string);
    procedure DisableDS;
    property OwnerName : string read GetownerName;
    property UserName : string read GetUserName;
    property History : TBaseHistory read FHistory;
    property UserID : String read FUserID write FUserID;
    property Snapshots : TTaskSnapshots read FSnapshots;
  end;

  { TTaskLinks }

  TTaskLinks = class(TLinks)
  private
  public
    procedure FillDefaults(aDataSet : TDataSet);override;
  end;

  { TDependencies }

  TDependencies = class(TBaseDBDataset)
    procedure DataSetAfterDelete(aDataSet: TDataSet);
  private
    FTask: TTaskList;
  protected
    property Task : TTaskList read FTask write FTask;
  public
    constructor Create(aOwner: TComponent; DM: TComponent;
       aConnection: TComponent=nil; aMasterdata: TDataSet=nil); override;
    procedure DefineFields(aDataSet : TDataSet);override;
    procedure Add(aLink : string);
    procedure SelectByLink(aLink : string);
  end;
  TTask = class(TTaskList)
  private
    FLinks: TTaskLinks;
  public
    constructor Create(aOwner : TComponent;DM : TComponent;aConnection : TComponent = nil;aMasterdata : TDataSet = nil);override;
    destructor Destroy;override;
    procedure CheckDependencies;
    property Links : TTaskLinks read FLinks;
    property Dependencies : TDependencies read FDependencies;
  end;
  TMoveTasksEvent = procedure(Sender: TObject;var Allowed : Boolean);

var
  OnMoveTasks : TMoveTasksEvent;
implementation
uses uBaseApplication,uIntfStrConsts,uProjects,uData,LCLProc;
resourcestring
  strTaskCompleted          = 'Aufgabe fertiggestellt';
  strTaskreopened           = 'Aufgabe wiedereröffnet';
  strTaskUDelegated         = '%s - wurde Ihnen delegiert';
  strTaskSCompleted         = '%s - erledigt';
  strTaskSChecked           = '%s - geprüft';
  strTaskSreopened          = '%s - wiedereröffnet';
  strTaskChecked            = 'Aufgabe geprüft';
  strProjectChanged         = 'Project geändert';
  strDelegated              = 'an %s delegiert';
  strPlantime               = 'Planzeit';
  strBuffertime             = 'Wartezeit';
  strCompletedAt            = 'fertiggestellt';
  strCompleted              = 'fertig';
  strStarted                = 'gestartet';
  strTaskAdded              = '%s - hinzugefügt';
  strTaskDeleted            = '%s - gelöscht';
  strHasChilds              = 'hat Untereinträge';
  strPercentDone            = '% erledigt';
  strWorkstatus             = 'Bearbeitungsstatus';
  strRenamed                = 'umbenannt in "%s"';

procedure TTaskSnapshots.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'TASKSNAPSHOTS';
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('NAME',ftString,100,True);
            Add('STARTDATE',ftDateTime,0,True);
            Add('ENDDATE',ftDateTime,0,True);
          end;
    end;
end;

procedure TDependencies.DataSetAfterDelete(aDataSet: TDataSet);
begin
  if DataSet.RecordCount = 0 then
    begin
      if not FTask.CanEdit then
        FTask.DataSet.Edit;
      FTask.FieldByName('DEPDONE').AsString := 'Y';
    end;
end;
constructor TDependencies.Create(aOwner: TComponent; DM: TComponent;
  aConnection: TComponent; aMasterdata: TDataSet);
begin
  inherited Create(aOwner, DM, aConnection, aMasterdata);
  DataSet.AfterDelete:=@DataSetAfterDelete;
end;
procedure TDependencies.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'DEPENDENCIES';
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('REF_ID_ID',ftLargeint,0,False);
            Add('LINK',ftString,120,False); //Link
            Add('ICON',ftInteger,0,False); //LinkIcon
            Add('NAME',ftString,100,True);
          end;
      if Assigned(ManagedIndexdefs) then
        with ManagedIndexDefs do
          begin
            Add('REF_ID_ID','REF_ID_ID',[]);
            Add('LINK','LINK',[]);
          end;
    end;
end;
procedure TDependencies.Add(aLink: string);
var
  tmp: String;
begin
  Open;
  if not Task.CanEdit then
    Task.DataSet.Edit;
  Task.FieldByName('DEPDONE').AsString:='N';
  Task.DataSet.Post;
  with DataSet do
    begin
      Append;
      with BaseApplication as IBaseDbInterface do
        begin
          tmp := copy(aLink,7,length(aLink));
          if pos('{',tmp)>0 then tmp := copy(tmp,0,pos('{',tmp)-1);
          FieldByName('REF_ID_ID').AsString := tmp;
          FieldByName('NAME').AsString:=Data.GetLinkDesc(aLink);
          FieldByName('LINK').AsString:=aLink;
          FieldByName('ICON').AsInteger:=Data.GetLinkIcon(aLink);
        end;
      Post;
    end;
end;

procedure TDependencies.SelectByLink(aLink: string);
begin
  with  DataSet as IBaseDBFilter, BaseApplication as IBaseDBInterface, DataSet as IBaseManageDB do
    begin
      Filter := '('+QuoteField('LINK')+'='+QuoteValue(aLink)+')';
    end;
end;
procedure TTaskLinks.FillDefaults(aDataSet: TDataSet);
begin
  inherited FillDefaults(aDataSet);
  aDataSet.FieldByName('RREF_ID').AsVariant:=(Parent as TTask).Id.AsVariant;
end;
constructor TTask.Create(aOwner: TComponent; DM: TComponent;
  aConnection: TComponent; aMasterdata: TDataSet);
begin
  inherited Create(aOwner, DM, aConnection, aMasterdata);
  FLinks := TTaskLinks.Create(Self,DM,aConnection);
end;
destructor TTask.Destroy;
begin
  FLinks.Free;
  inherited Destroy;
end;
procedure TTask.CheckDependencies;
var
  aTask: TTask;
  aCompCount : Double = 0;
  AllCompleted : String = 'Y';
  aPercentage: Extended;
  aTime: TDateTime;
begin
  if not Dependencies.DataSet.Active then
    Dependencies.Open;
  Dependencies.DataSet.First;
  while not Dependencies.DataSet.EOF do
    begin
      aTask := TTask.Create(Self,DataModule,Connection);
      aTask.SelectFromLink(Dependencies.FieldByName('LINK').AsString);
      aTask.Open;
      aTask.CheckDependencies;
      aCompCount:=aCompCount+(aTask.FieldByName('PERCENT').AsInteger/100);
      if aTask.FieldByName('COMPLETED').AsString <> 'Y' then AllCompleted:='N';
      aTask.Free;
      Dependencies.DataSet.Next;
    end;
  if not CanEdit then
    DataSet.Edit;
  DataSet.FieldByName('DEPDONE').AsString := AllCompleted;
  DataSet.Post;
end;

procedure TTaskList.MakeSnapshot(aName: string);
var
  aStart: TDateTime;
  aEnd: TDateTime;
begin
  CalcDates(aStart,aEnd);
  Snapshots.Append;
  Snapshots.FieldByName('NAME').AsString:=aName;
  Snapshots.FieldByName('STARTDATE').AsDateTime:=aStart;
  Snapshots.FieldByName('ENDDATE').AsDateTime:=aEnd;
  Snapshots.Post;
end;

procedure TTaskList.CheckChilds;
var
  aTasks: TTaskList;
  aCompCount : Double = 0;
  AllCompleted : String = 'Y';
  aPercentage: Extended;
begin
  if Id.IsNull then exit;
  aTasks := TTaskList.Create(Self,DataModule,Connection);
  aTasks.SelectByParent(Id.AsVariant);
  aTasks.Open;
  with aTasks.DataSet do
    begin
      First;
      if not EOF then
        begin
          while not EOF do
            begin
//              aTasks.CheckChilds;
              aCompCount:=aCompCount+(aTasks.FieldByName('PERCENT').AsInteger/100);
              if aTasks.FieldByName('COMPLETED').AsString <> 'Y' then AllCompleted:='N';
              Next;
            end;
          aPercentage := 100*(aCompCount/aTasks.Count);
          if (DataSet.FieldByName('COMPLETED').AsString <> AllCompleted)
          or (DataSet.FieldByName('PERCENT').AsInteger <> round(aPercentage)) then
            begin
              if not CanEdit then
                DataSet.Edit;
              if (DataSet.FieldByName('PERCENT').AsInteger <> round(aPercentage)) then
                DataSet.FieldByName('PERCENT').AsInteger := round(aPercentage);
              if (DataSet.FieldByName('COMPLETED').AsString <> AllCompleted) then
                DataSet.FieldByName('COMPLETED').AsString := AllCompleted;
              DataSet.Post;
            end;
        end;
    end;
  aTasks.Free;
end;
procedure TTaskList.CheckDependTasks;
var
  aDeps: TDependencies;
  aTask: TTask;
  AllCompleted: Char = 'Y';
  HasTrigger: Boolean;
  aTime: TDateTime;
begin
  HasTrigger := Data.TriggerExists('TASKS_INS_DEPEND');
  aDeps := TDependencies.Create(Self,DataModule,Connection);
  aDeps.SelectByLink(Data.BuildLink(DataSet));
  aDeps.Open;
  aDeps.DataSet.First;
  while not aDeps.DataSet.EOF do
    begin
      aTask := TTask.Create(Self,DataModule,Connection);
      aTask.Select(aDeps.FieldByName('REF_ID').AsVariant);
      aTask.Open;
      if (FieldByName('COMPLETED').AsString='Y') and (FieldByName('BUFFERTIME').AsFloat>0) then
        begin  //set Earlyes begin when Buffertime was > 0
          if FieldByName('COMPLETEDAT').IsNull then
            aTime := Now()
          else
            aTime := FieldByName('COMPLETEDAT').AsDateTime;
          if not aTask.CanEdit then aTask.DataSet.Edit;
          aTask.FieldByName('EARLIEST').AsDateTime := aTime+FieldByName('BUFFERTIME').AsFloat;
          aTask.Post;
        end;
      if (not HasTrigger) then
        begin
          aTask.CheckDependencies;
          if aTask.FieldByName('DEPDONE').AsString <> 'Y' then AllCompleted:='N';
        end;
      aTask.Free;
      aDeps.DataSet.Next;
    end;
  aDeps.Free;
end;

procedure TTaskList.MoveDependTasks;
var
  aDeps: TDependencies;
  aTask: TTask;
begin
  aDeps := TDependencies.Create(Self,DataModule,Connection);
  aDeps.SelectByLink(Data.BuildLink(DataSet));
  aDeps.Open;
  with aDeps.DataSet do
    begin
      First;
      while not EOF do
        begin
          aTask := TTask.Create(Self,DataModule,Connection);
          aTask.Select(aDeps.FieldByName('REF_ID').AsVariant);
          aTask.Open;
          if aTask.FieldByName('STARTDATE').AsDateTime<DataSet.FieldByName('DUEDATE').AsDateTime then
            begin
              if not aTask.CanEdit then aTask.DataSet.Edit;
              aTask.FieldByName('STARTDATE').AsDateTime:=DataSet.FieldByName('DUEDATE').AsDateTime;
              aTask.Post;
            end;
          aTask.Free;
          Next;
        end;
    end;
  aDeps.Free;
end;

procedure TTaskList.Open;
begin
  inherited Open;
end;

function TTaskList.CalcDates(var aStart, aDue: TDateTime) : Boolean;
var
  MinimalTaskLength: Extended;
  aDur: Extended;
begin
  Result := False;//Changed
  aDue := FieldByName('DUEDATE').AsDateTime;
  aStart := FieldByName('STARTDATE').AsDateTime;
  MinimalTaskLength := StrToFloatDef(FieldByName('PLANTIME').AsString,1);
  if (aStart>0) and (aDue>0) then
    aDur := aDue-aStart
  else aDur := MinimalTaskLength;
  if (aStart < Now()) and (aDue=0) then
    aStart := Now();
  if aStart < FieldByName('EARLIEST').AsDateTime then
    begin
      aStart := FieldByName('EARLIEST').AsDateTime;
      Result := True;
    end;
  if FieldByName('COMPLETED').AsString = 'Y' then
    begin
      if FieldByName('STARTEDAT').AsDAteTime > 0 then
        aStart := FieldByName('STARTEDAT').AsDateTime
      else if (FieldByName('COMPLETEDAT').AsDAteTime > 0) then
        aStart := 0;
      if FieldByName('COMPLETEDAT').AsDAteTime > 0 then
        aDue := FieldByName('COMPLETEDAT').AsDAteTime;
    end;
  if (aDue=0) and (aStart=0) then
    begin
      aStart := Now();
      aDue := aStart+StrToFloatDef(FieldByName('PLANTIME').AsString,1);
    end
  else if aStart = 0 then
    aStart := aDue-StrToFloatDef(FieldByName('PLANTIME').AsString,1)
  else if aDue=0 then
    aDue := aStart+StrToFloatDef(FieldByName('PLANTIME').AsString,1);
  if aDur>MinimalTaskLength then MinimalTaskLength:=aDur;
  if aDue<aStart+MinimalTaskLength then
    begin
      aDue := aStart+MinimalTaskLength;
      result := True;
    end;
end;

procedure TTaskList.DisableDS;
begin
  FDS.Enabled:=False;
  FDS.DataSet := nil;
end;
procedure TTaskList.DataSetAfterPost(aDataSet: TDataSet);
var
  aParent: TTask;
  aProject: TProject;
begin
  if DoCheckTask then
    begin
      if not DataSet.FieldByName('PARENT').IsNull then
        begin
          aParent := TTask.Create(Self,DataModule,Connection);
          aParent.Select(DataSet.FieldByName('PARENT').AsVariant);
          aParent.Open;
          if aParent.Count > 0 then
            aParent.CheckChilds;
          aParent.Free;
        end;
      CheckDependTasks;
      DoCheckTask := False;
    end;
  if FAddProjectOnPost then
    begin
      if trim(FDS.DataSet.FieldByName('SUMMARY').AsString)<>'' then
        begin
          aProject := TProject.Create(Self,Data,Connection);
          aProject.Select(FDS.DataSet.FieldByName('PROJECTID').AsVariant);
          aProject.Open;
          if (aProject.Count>0) then
            begin
              History.AddItem(Self.DataSet,strProjectChanged,'',DataSet.FieldByName('PROJECT').AsString,DataSet,ACICON_EDITED);
              aProject.History.Open;
              aProject.History.AddItem(aProject.DataSet,Format(strTaskAdded,[FDS.DataSet.FieldByName('SUMMARY').AsString]),Data.BuildLink(FDS.DataSet),'',DataSet,ACICON_TASKADDED);
            end;
          aProject.Free;
          FAddProjectOnPost:=False;
        end;
    end;
  if FAddSummaryOnPost then
    begin
      DataSet.DisableControls;
      if not History.DataSet.Active then History.Open;
      History.AddItem(Self.DataSet,Format(strRenamed,[Field.AsString]),'','',nil,ACICON_RENAMED);
      DataSet.EnableControls;
      FAddSummaryOnPost:=false;
    end;
end;
procedure TTaskList.DataSetBeforeDelete(aDataSet: TDataSet);
var
  aParent: TTask;
  aTasks: TTaskList;
  Clean: Boolean;
  i: Integer;
  aProject: TProject;
begin
  if trim(FDS.DataSet.FieldByName('SUMMARY').AsString)<>'' then
    begin
      aProject := TProject.Create(Self,Data,Connection);
      aProject.Select(FDS.DataSet.FieldByName('PROJECTID').AsVariant);
      aProject.Open;
      if (aProject.Count>0) then
        begin
          aProject.History.Open;
          aProject.History.AddItem(aProject.DataSet,Format(strTaskDeleted,[FDS.DataSet.FieldByName('SUMMARY').AsString]),Data.BuildLink(FDS.DataSet),'',DataSet,ACICON_TASKCLOSED);
        end;
      aProject.Free;
    end;
  if  (Data.TriggerExists('TASKS_DEL_CHILD')) then exit;
  aParent := TTask.Create(Self,DataModule,Connection);
  aParent.Select(DataSet.FieldByName('PARENT').AsVariant);
  aParent.Open;
  if aParent.Count > 0 then
    begin
      aTasks := TTaskList.Create(Self,DataModule,Connection);
      aTasks.SelectByParent(aParent.Id.AsVariant);
      aTasks.Open;
      if (aTasks.Count = 1)
      and (aTasks.Id.AsVariant = Self.Id.AsVariant) then
        begin
          aParent.DataSet.Edit;
          aParent.FieldByName('HASCHILDS').AsString:='N';
          aParent.DataSet.Post;
        end;
      Clean := True;
      for i := 0 to aTasks.Count-1 do
        begin
          if (aTasks.FieldByName('CHECKED').AsString = 'N') and (aTasks.Id.AsVariant <> Self.Id.AsVariant) then
            Clean := False;
          aTasks.Next;
        end;
      if Clean then
        begin
          aParent.DataSet.Edit;
          aParent.FieldByName('CHECKED').AsString:='Y';
          aParent.DataSet.Post;
        end;
      aTasks.Free;
    end;
  aParent.Free;
end;

procedure TTaskList.FDSDataChange(Sender: TObject; Field: TField);
var
  aParent: TTask;
  aProject: TProject;
  aUser: TUser;
begin
  if not Assigned(Field) then exit;
  if DataSet.ControlsDisabled then
    exit;
  if Field.FieldName='COMPLETED' then
    begin
      DataSet.DisableControls;
      if Field.AsString='Y' then
        begin
          DataSet.FieldByName('PERCENT').AsInteger:=100;
          DataSet.FieldByName('COMPLETEDAT').AsDateTime:=Now();
          if not History.DataSet.Active then History.Open;
          History.AddItem(Self.DataSet,strTaskCompleted,Data.BuildLink(FDS.DataSet),'',nil,ACICON_STATUSCH);
          aProject := TProject.Create(Self,Data,Connection);
          aProject.Select(FDS.DataSet.FieldByName('PROJECTID').AsVariant);
          aProject.Open;
          if aProject.Count>0 then
            begin
              aProject.History.Open;
              aProject.History.AddItem(aProject.DataSet,Format(strTaskSCompleted,[FDS.DataSet.FieldByName('SUMMARY').AsString]),Data.BuildLink(FDS.DataSet),'',aProject.DataSet,ACICON_TASKCLOSED);
            end;
          if DataSet.FieldByName('USER').AsString<>DataSet.FieldByName('OWNER').AsString then
            begin
              aUser := TUser.Create(Self,Data,Connection);
              aUser.SelectByAccountno(DataSet.FieldByName('OWNER').AsString);
              aUser.Open;
              if aUser.Count>0 then
                begin
                  if Assigned(aProject) then
                    aUser.History.AddItem(aProject.DataSet,Format(strTaskSCompleted,[FDS.DataSet.FieldByName('SUMMARY').AsString]),Data.BuildLink(FDS.DataSet),'',aProject.DataSet,ACICON_TASKCLOSED)
                  else
                    aUser.History.AddItem(Self.DataSet,Format(strTaskSCompleted,[FDS.DataSet.FieldByName('SUMMARY').AsString]),Data.BuildLink(FDS.DataSet),'',nil,ACICON_TASKCLOSED);

                end;
              aUser.Free;
            end;
          aProject.Free;
        end
      else if (Field.AsString='N') and (DataSet.State <> dsInsert) then
        begin
          if DataSet.FieldByName('PERCENT').AsInteger = 100 then
            DataSet.FieldByName('PERCENT').AsInteger:=0;
          DataSet.FieldByName('COMPLETEDAT').Clear;
          DataSet.FieldByName('CHECKED').AsString:='N';
          DataSet.FieldByName('DUEDATE').Clear;
          DataSet.FieldByName('PLANTIME').Clear;
          DataSet.FieldByName('BUFFERTIME').Clear;
          if not History.DataSet.Active then History.Open;
          History.AddItem(Self.DataSet,strTaskReopened,Data.BuildLink(FDS.DataSet),'',nil,ACICON_STATUSCH);
          aProject := TProject.Create(Self,Data,Connection);
          aProject.Select(FDS.DataSet.FieldByName('PROJECTID').AsVariant);
          aProject.Open;
          if aProject.Count>0 then
            begin
              aProject.History.Open;
              aProject.History.AddItem(aProject.DataSet,Format(strTaskSReopened,[FDS.DataSet.FieldByName('SUMMARY').AsString]),Data.BuildLink(FDS.DataSet),'',aProject.DataSet,ACICON_TASKADDED);
            end;
          aProject.Free;
        end;
      //Check Parent Task
      DataSet.EnableControls;
      DoCheckTask := True;
    end
  else if (Field.FieldName='CHECKED') and (Field.AsString='Y') then
    begin
      DataSet.DisableControls;
      if not History.DataSet.Active then History.Open;
      History.AddItem(Self.DataSet,strTaskChecked,Data.BuildLink(FDS.DataSet),'',nil,ACICON_STATUSCH);
      if DataSet.FieldByName('USER').AsString<>DataSet.FieldByName('OWNER').AsString then
        begin
          aUser := TUser.Create(Self,Data,Connection);
          aUser.SelectByAccountno(DataSet.FieldByName('USER').AsString);
          aUser.Open;
          if aUser.Count>0 then
            aUser.History.AddItem(Self.DataSet,Format(strTaskSChecked,[FDS.DataSet.FieldByName('SUMMARY').AsString]),Data.BuildLink(FDS.DataSet),'',nil,ACICON_TASKCLOSED);
          aUser.Free;
        end;
      DataSet.EnableControls;
    end
  else if (Field.FieldName='SUMMARY') then
    begin
      FAddSummaryOnPost:=True;
    end
  else if (Field.FieldName='PROJECT') and (DataSet.State <> dsInsert) then
    begin
      DataSet.DisableControls;
      if not History.DataSet.Active then History.Open;
      aProject := TProject.Create(Self,Data,Connection);
      aProject.Select(FDS.DataSet.FieldByName('PROJECTID').AsVariant);
      aProject.Open;
      if aProject.Count>0 then
        begin
          aProject.History.Open;
          if FDS.DataSet.FieldByName('SUMMARY').AsString<>'' then
            aProject.History.AddItem(aProject.DataSet,Format(strTaskAdded,[FDS.DataSet.FieldByName('SUMMARY').AsString]),Data.BuildLink(FDS.DataSet),'',aProject.DataSet,ACICON_TASKADDED);
          History.AddItem(Self.DataSet,strProjectChanged,Data.BuildLink(aProject.DataSet),Field.AsString,aProject.DataSet,ACICON_EDITED);
        end;
      aProject.Free;
      DataSet.FieldByName('SEEN').AsString:='N';
      DataSet.EnableControls;
    end
  else if (Field.FieldName='PROJECT') and (DataSet.State = dsInsert) then
    begin
      FAddProjectOnPost := true;
    end
  else if (Field.FieldName='USER') then
    begin
      DataSet.DisableControls;
      DataSet.FieldByName('SEEN').AsString:='N';
      if DataSet.FieldByName('USER').AsString<>DataSet.FieldByName('OWNER').AsString then
        begin
          aUser := TUser.Create(Self,Data,Connection);
          aUser.SelectByAccountno(DataSet.FieldByName('USER').AsString);
          aUser.Open;
          if aUser.Count>0 then
            begin
              if not History.DataSet.Active then History.Open;
              History.AddItem(Self.DataSet,Format(strDelegated,[aUser.Text.AsString]),'','',nil,ACICON_TASKADDED,'',False);
              aProject := TProject.Create(Self,Data,Connection);
              aProject.Select(FDS.DataSet.FieldByName('PROJECTID').AsVariant);
              aProject.Open;
              if aProject.Count>0 then
                aUser.History.AddItem(aProject.DataSet,Format(strTaskUDelegated,[FDS.DataSet.FieldByName('SUMMARY').AsString]),Data.BuildLink(FDS.DataSet),'',aProject.DataSet,ACICON_TASKADDED,'',False)
              else
                aUser.History.AddItem(Self.DataSet,Format(strTaskUDelegated,[FDS.DataSet.FieldByName('SUMMARY').AsString]),Data.BuildLink(FDS.DataSet),'',nil,ACICON_TASKADDED,'',False);
              aProject.Free;
            end;
          aUser.Free;
        end;
      DataSet.EnableControls;
    end
  else if (Field.FieldName='DUEDATE') then
    begin
      DataSet.DisableControls;
      if not History.DataSet.Active then History.Open;
      History.AddItem(Self.DataSet,Format(strDueDateChanged,[Field.AsString]),'','',nil,ACICON_DATECHANGED);
      if (DataSet.FieldByName('CLASS').AsString = 'M') then
        begin
          aProject := TProject.Create(Self,Data,Connection);
          aProject.Select(FDS.DataSet.FieldByName('PROJECTID').AsVariant);
          aProject.Open;
          if aProject.Count>0 then
            begin
              aProject.History.Open;
              aProject.History.AddItem(aProject.DataSet,Format(strDueDateChanged,[Field.AsString]),Data.BuildLink(aProject.DataSet),FDS.DataSet.FieldByName('SUMMARY').AsString,nil,ACICON_DATECHANGED);
            end;
          aProject.Free;
        end;
      DataSet.FieldByName('SEEN').AsString:='N';
      DataSet.EnableControls;
      if not Field.IsNull then
        MoveDependTasks;
    end
  else if (Field.FieldName='STARTDATE') then
    begin
      if not DataSet.FieldByName('DUEDATE').IsNull then
        begin
          if ((DataSet.FieldByName('DUEDATE').AsDateTime-Max(StrToFloatDef(DataSet.FieldByName('PLANTIME').AsString,0)+StrToFloatDef(DataSet.FieldByName('BUFFERTIME').AsString,0),1)) < DataSet.FieldByName('STARTDATE').AsDateTime) then
            begin
              if not Canedit then DataSet.Edit;
                DataSet.FieldByName('DUEDATE').AsDateTime := DataSet.FieldByName('STARTDATE').AsDateTime+Max(StrToFloatDef(DataSet.FieldByName('PLANTIME').AsString,0)+StrToFloatDef(DataSet.FieldByName('BUFFERTIME').AsString,0),1);
            end;
        end;
    end
  else if (Field.FieldName='PLANTIME') then
    begin
      {
      if not DataSet.FieldByName('DUEDATE').IsNull then
        begin
          if trim(DataSet.FieldByName('PLANTIME').AsString)<>'' then
            if (DataSet.FieldByName('DUEDATE').AsDateTime-Max(DataSet.FieldByName('PLANTIME').AsFloat+DataSet.FieldByName('BUFFERTIME').AsFloat,1)) < DataSet.FieldByName('STARTDATE').AsDateTime then
              begin
                if not Canedit then DataSet.Edit;
                  DataSet.FieldByName('DUEDATE').AsDateTime := DataSet.FieldByName('STARTDATE').AsDateTime+Max(DataSet.FieldByName('PLANTIME').AsFloat+DataSet.FieldByName('BUFFERTIME').AsFloat,1);
              end;
        end;
      }
    end
  else if (Field.FieldName <> 'SEEN') and (Field.FieldName <> 'TIMESTAMPD') and (Field.FieldName <> 'CHANGEDBY') then
    begin
      DataSet.DisableControls;
      DataSet.FieldByName('SEEN').AsString:='N';
      DataSet.EnableControls;
    end;
end;
function TTaskList.GetownerName: string;
begin
  Result := '';
  if not FTempUsers.DataSet.Active then FTempUsers.Open;
  if FTempUsers.DataSet.Locate('ACCOUNTNO',DataSet.FieldByName('OWNER').AsString,[]) then
    Result := FTempUsers.FieldByName('NAME').AsString;
end;
function TTaskList.GetUserName: string;
begin
  Result := '';
  if not FTempUsers.DataSet.Active then FTempUsers.Open;
  if FTempUsers.DataSet.Locate('ACCOUNTNO',DataSet.FieldByName('USER').AsString,[]) then
    Result := FTempUsers.FieldByName('NAME').AsString;
end;
function TTaskList.GetHistory: TBaseHistory;
begin
  Result := FHistory;
end;
procedure TTaskList.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'TASKS';
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('COMPLETED',ftString,1,True);
            Add('ACTIVE',ftString,1,True);
            Add('CHECKED',ftString,1,True);
            Add('HASCHILDS',ftString,1,True);
            Add('SEEN',ftString,1,False);
            Add('SUMMARY',ftString,220,False);
            Add('GPRIORITY',ftLargeint,0,False);
            Add('LPRIORITY',ftInteger,0,False);
            Add('PLANTIME',ftFloat,0,False);
            Add('PLANTASK',ftString,1,False);
            Add('BUFFERTIME',ftFloat,0,False);
            Add('CATEGORY',ftString,60,False);
            Add('PERCENT',ftInteger,0,False);
            Add('OWNER',ftString,20,True);
            Add('USER',ftString,20,False);
            Add('PARENT',ftLargeInt,0,False);
            Add('LPARENT',ftLargeInt,0,False);
            Add('PROJECTID',ftLargeInt,0,False);
            Add('PROJECT',ftString,260,False);
            Add('ORIGID',ftLargeInt,0,False);
            Add('CLASS',ftString,1,True);
            Add('DEPDONE',ftString,1,True);
            Add('PRIORITY',ftString,1,True);
            Add('STARTDATE',ftDateTime,0,False);
            Add('DUEDATE',ftDateTime,0,False);
            Add('EARLIEST',ftDateTime,0,False);
            Add('PLANED',ftDateTime,0,False);
            Add('WORKSTATUS',ftString,4,False);
            Add('STARTEDAT',ftDateTime,0,False);
            Add('COMPLETEDAT',ftDateTime,0,False);
            Add('DESC',ftMemo,0,False);
            Add('CREATEDBY',ftString,4,False);
          end;
      if Assigned(ManagedIndexdefs) then
        with ManagedIndexDefs do
          begin
            Add('COMPLETED','COMPLETED',[]);
            Add('ACTIVE','ACTIVE',[]);
            Add('CHECKED','CHECKED',[]);
            Add('OWNER','OWNER',[]);
            Add('USER','USER',[]);
            Add('PARENT','PARENT',[]);
            Add('PROJECTID','PROJECTID',[]);
            Add('CLASS','CLASS',[]);
            Add('WORKSTATUS','WORKSTATUS',[]);
          end;
      UpdateChangedBy:=False;
    end;
end;
procedure TTaskList.FillDefaults(aDataSet: TDataSet);
begin
  with aDataSet,BaseApplication as IBaseDbInterface do
    begin
      DataSet.DisableControls;
      FieldByName('ACTIVE').AsString := 'Y';
      FieldByName('COMPLETED').AsString := 'N';
      FieldByName('DEPDONE').AsString := 'Y';
      FieldByName('CHECKED').AsString := 'N';
      FieldByName('HASCHILDS').AsString := 'N';
      FieldByName('CLASS').AsString := 'T';
      FieldByName('PERCENT').AsInteger := 0;
      FieldByName('PARENT').AsInteger := 0;
      FieldByName('PRIORITY').AsString := '0';
      FieldByName('OWNER').AsString := Data.Users.FieldByName('ACCOUNTNO').AsString;
      FieldByName('GPRIORITY').AsString := '999999';
      if (not (Self is TProjectTasks)) then
        begin
          if FUserID = Null then
            FieldByName('USER').AsString := Data.Users.FieldByName('ACCOUNTNO').AsString
          else
            FieldByName('USER').AsString := FUserID;
        end;
      DataSet.EnableControls;
    end;
end;

procedure TTaskList.SelectActiveByUser(AccountNo: string);
begin
  with  DataSet as IBaseDBFilter, BaseApplication as IBaseDBInterface, DataSet as IBaseManageDB do
    begin
      Filter := '('+QuoteField('USER')+'='+QuoteValue(AccountNo)+') and ('+QuoteField('COMPLETED')+'='+QuoteValue('N')+') and ('+QuoteField('ACTIVE')+'='+QuoteValue('Y')+')';
    end;
end;

procedure TTaskList.SelectActive;
begin
  with  DataSet as IBaseDBFilter, BaseApplication as IBaseDBInterface, DataSet as IBaseManageDB do
    begin
      Filter := '('+QuoteField('COMPLETED')+'='+QuoteValue('N')+') and ('+QuoteField('ACTIVE')+'='+QuoteValue('Y')+')';
      SortFields:='SQL_ID';
      SortDirection:=sdAscending;
    end;
end;

procedure TTaskList.SelectByUser(AccountNo: string);
begin
  with  DataSet as IBaseDBFilter, BaseApplication as IBaseDBInterface, DataSet as IBaseManageDB do
    begin
      Filter := '('+QuoteField('USER')+'='+QuoteValue(AccountNo)+') or ('+QuoteField('OWNER')+'='+QuoteValue(AccountNo)+')';
    end;
end;

procedure TTaskList.SelectByDept(aDept: Variant);
var
  aUsers: TUser;
  aFilter: String;
  procedure RecourseUsers(aParent : Variant);
  var
    bUsers: TUser;
  begin
    bUsers := TUser.Create(nil,DataModule);
    bUsers.SelectByParent(aParent);
    bUsers.Open;
    while not bUsers.EOF do
      begin
        RecourseUsers(bUsers.Id.AsVariant);
        with  DataSet as IBaseDBFilter, BaseApplication as IBaseDBInterface, DataSet as IBaseManageDB do
          begin
            with  DataSet as IBaseDBFilter, BaseApplication as IBaseDBInterface, DataSet as IBaseManageDB do
              Filter := Filter+' or (('+QuoteField('USER')+'='+QuoteValue(bUsers.FieldByName('ACCOUNTNO').AsString)+') and (('+Data.ProcessTerm(QuoteField('DUEDATE')+'='+QuoteValue(''))+') or ('+Data.ProcessTerm(QuoteField('PLANTIME')+'='+QuoteValue(''))+')))';
          end;
        bUsers.Next;
      end;
    bUsers.Free;
  end;

begin
  aUsers := TUser.Create(nil,DataModule);
  aUsers.Select(aDept);
  aUsers.Open;
  with  DataSet as IBaseDBFilter, BaseApplication as IBaseDBInterface, DataSet as IBaseManageDB do
    begin
      Filter := '('+QuoteField('COMPLETED')+'<>'+QuoteValue('Y')+')';
      Filter := Filter+' and ('+QuoteField('PLANTASK')+'='+Data.ProcessTerm(QuoteValue('Y')+' or '+QuoteField('PLANTASK')+'='+Data.QuoteValue(''))+')';
      Filter := Filter+' and ('+QuoteField('ACTIVE')+'<>'+QuoteValue('N')+') and (';
      Filter := Filter+'('+QuoteField('USER')+'='+QuoteValue(aUsers.FieldByName('ACCOUNTNO').AsString)+')';
    end;
  RecourseUsers(aDept);
  with  DataSet as IBaseDBFilter, BaseApplication as IBaseDBInterface, DataSet as IBaseManageDB do
    begin
      Filter := Filter+')';
      aFilter := Filter;
    end;
  aUsers.Free;
end;

procedure TTaskList.SelectByParent(aParent: Variant);
begin
  with  DataSet as IBaseDBFilter, BaseApplication as IBaseDBInterface, DataSet as IBaseManageDB do
    begin
      Filter := '('+QuoteField('PARENT')+'='+QuoteValue(aParent)+')';
    end;
end;
procedure TTaskList.SelectUncompletedByParent(aParent: Variant);
begin
  with  DataSet as IBaseDBFilter, BaseApplication as IBaseDBInterface, DataSet as IBaseManageDB do
    begin
      Filter := '('+QuoteField('PARENT')+'='+QuoteValue(aParent)+') AND ('+QuoteField('COMPLETED')+'='+QuoteValue('N')+')';
    end;
end;
constructor TTaskList.Create(aOwner: TComponent; DM: TComponent;
  aConnection: TComponent; aMasterdata: TDataSet);
begin
  inherited Create(aOwner, DM, aConnection, aMasterdata);
  FAddProjectOnPost := false;
  FAddSummaryOnPost:=false;
  DoCheckTask:=False;
  FDS := TDataSource.Create(Self);
  FDS.DataSet := DataSet;
  FDS.OnDataChange:=@FDSDataChange;
  DataSet.AfterPost:=@DataSetAfterPost;
  DataSet.BeforeDelete:=@DataSetBeforeDelete;
  with BaseApplication as IBaseDbInterface do
    begin
      with DataSet as IBaseDBFilter do
        begin
          SortFields:='SQL_ID';
          BaseSortFields:='SQL_ID';
          BaseSortDirection:=sdAscending;
          Limit := 500;
        end;
    end;
  FTempUsers := TUser.Create(aOwner,DM);
  FHistory := TBaseHistory.Create(Self,DM,aConnection,DataSet);
  FSnapshots := TTaskSnapshots.Create(Self,DM,aConnection,DataSet);
  FDependencies := TDependencies.Create(Self,DM,aConnection,DataSet);
  FDependencies.FTask:=Self;
end;

destructor TTaskList.Destroy;
begin
  FDependencies.Free;
  FSnapshots.Free;
  FDS.Free;
  FHistory.Free;
  FTempUsers.Free;
  inherited Destroy;
end;
procedure TTaskList.SetDisplayLabels(aDataSet: TDataSet);
begin
  inherited SetDisplayLabels(aDataSet);
  SetDisplayLabelName(aDataSet,'STARTDATE',strStart);
  SetDisplayLabelName(aDataSet,'PLANTIME',strPlantime);
  SetDisplayLabelName(aDataSet,'COMPLETEDAT',strCompletedAt);
  SetDisplayLabelName(aDataSet,'COMPLETED',strCompleted);
  SetDisplayLabelName(aDataSet,'STARTEDAT',strStarted);
  SetDisplayLabelName(aDataSet,'TARGET',strStarted);
  SetDisplayLabelName(aDataSet,'HASCHILDS',strHasChilds);
  SetDisplayLabelName(aDataSet,'BUFFERTIME',strBuffertime);
  SetDisplayLabelName(aDataSet,'PERCENT',strPercentDone);
  SetDisplayLabelName(aDataSet,'USER',strWorker);
  SetDisplayLabelName(aDataSet,'OWNER',strResponsable);
  SetDisplayLabelName(aDataSet,'WORKSTATUS',strWorkstatus);
end;
function TTaskList.CreateTable : Boolean;
begin
  Result := inherited CreateTable;
  FHistory.CreateTable;
  FSnapshots.CreateTable;
  FDependencies.CreateTable;
  try
    if Data.ShouldCheckTable('TASKS',False) then
      begin
        Data.CreateTrigger('DEL_CHILD','TASKS','DELETE',
         'UPDATE '+Data.QuoteField('TASKS')
        +' SET '+Data.QuoteField('HASCHILDS')+'=(CASE WHEN EXISTS(SELECT * FROM '+Data.QuoteField('TASKS')+' AS '+Data.QuoteField('PAR')+' WHERE '+Data.QuoteField('TASKS')+'.'+Data.QuoteField('SQL_ID')+'='+Data.QuoteField('PAR')+'.'+Data.QuoteField('PARENT')+') THEN '+Data.QuoteValue('Y')+' ELSE '+Data.QuoteValue('N')+' END)'
        +' WHERE $OLD$.'+Data.QuoteField('PARENT')+'='+Data.QuoteField('SQL_ID')+';');

        Data.CreateTrigger('INS_CHILD','TASKS','UPDATE',
        'UPDATE '+Data.QuoteField('TASKS')
       +' SET '+Data.QuoteField('HASCHILDS')+'=(CASE WHEN EXISTS(SELECT * FROM '+Data.QuoteField('TASKS')+' AS '+Data.QuoteField('PAR')+' WHERE '+Data.QuoteField('TASKS')+'.'+Data.QuoteField('SQL_ID')+'='+Data.QuoteField('PAR')+'.'+Data.QuoteField('PARENT')+') THEN '+Data.QuoteValue('Y')+' ELSE '+Data.QuoteValue('N')+' END)'
       +' WHERE $NEW$.'+Data.QuoteField('PARENT')+'='+Data.QuoteField('SQL_ID')+';');

        Data.CreateTrigger('INS_COMPL','TASKS','UPDATE',
        'UPDATE '+Data.QuoteField('TASKS')
       +' SET '+Data.QuoteField('COMPLETED')+'=(CASE WHEN EXISTS(SELECT * FROM '+Data.QuoteField('TASKS')+' AS '+Data.QuoteField('PAR')+' WHERE '+Data.QuoteField('TASKS')+'.'+Data.QuoteField('SQL_ID')+'='+Data.QuoteField('PAR')+'.'+Data.QuoteField('PARENT')+' AND '+Data.QuoteField('COMPLETED')+'='+Data.QuoteValue('N')+') THEN '+Data.QuoteValue('N')+' ELSE '+Data.QuoteValue('Y')+' END)'
       +' WHERE $NEW$.'+Data.QuoteField('PARENT')+'='+Data.QuoteField('SQL_ID')+';');

        Data.CreateTrigger('INS_DEPEND','TASKS','UPDATE',
        ' UPDATE '+Data.QuoteField('TASKS')
       +' SET '+Data.QuoteField('DEPDONE')+'=(CASE WHEN EXISTS(SELECT * FROM '+Data.QuoteField('DEPENDENCIES')+' inner join '+Data.QuoteField('TASKS')+' as '+Data.QuoteField('TP')+' on '+Data.QuoteField('DEPENDENCIES')+'.'+Data.QuoteField('REF_ID_ID')+'='+Data.QuoteField('TP')+'.'+Data.QuoteField('SQL_ID')+' and '+Data.QuoteField('COMPLETED')+'='+Data.QuoteValue('N')+' WHERE '+Data.QuoteField('TASKS')+'.'+Data.QuoteField('SQL_ID')+'='+Data.QuoteField('DEPENDENCIES')+'.'+Data.QuoteField('REF_ID')+') THEN '+Data.QuoteValue('N')+' ELSE '+Data.QuoteValue('Y')+' END)'
       +' WHERE '+Data.QuoteField('COMPLETED')+'='+Data.QuoteValue('N')+' AND '+Data.QuoteField('ACTIVE')+'='+Data.QuoteValue('Y')+';'+LineEnding,'COMPLETED');
      end;
  except
  end;
end;
procedure TTaskList.CascadicPost;
begin
  inherited CascadicPost;
  FHistory.CascadicPost;
end;

procedure TTaskList.CascadicCancel;
begin
  FHistory.CascadicCancel;
  inherited CascadicCancel;
end;
function TTaskList.GetTextFieldName: string;
begin
  Result := 'SUMMARY';
end;
function TTaskList.GetNumberFieldName: string;
begin
  Result := 'SQL_ID';
end;
end.

