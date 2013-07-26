{*******************************************************************************
Dieser Sourcecode darf nicht ohne gültige Geheimhaltungsvereinbarung benutzt werden
und ohne gültigen Vertriebspartnervertrag weitergegeben werden.
You have no permission to use this Source without valid NDA
and copy it without valid distribution partner agreement
Christian Ulrich
info@cu-tec.de
Created 05.05.2013
*******************************************************************************}
unit uTaskPlan;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Buttons, Menus, ActnList, gsGanttCalendar, uTask, Math, types,
  uPrometFrames, uIntfStrConsts, Variants,ugridview,grids,dbgrids,utasks;

type

  { TPInterval }

  TPInterval = class(TInterval)
  private
    FCalcUsage : Extended;
    FUser: string;
    FUserID : Variant;
    FWorkTime: Extended;
    FUsage : Extended;
    procedure CalcUsage(aConnection : TComponent);
    function GetWorkTime: Extended;
  protected
    procedure SetStartDate(const Value: TDateTime); override;
    procedure SetFinishDate(const Value: TDateTime); override;
    procedure SetNetTime(AValue: TDateTime); override;
    function GetPercentMoveRect: TRect; override;
    function GetUsage: Extended; override;
  public
    procedure SetUser(AValue: string;aConnection : TComponent);
    property User : string read FUser;
    property WorkTime : Extended read GetWorkTime;
  end;

  { TRessource }

  TRessource = class(TInterval)
  private
    FAccountno: string;
    FUserI: TPInterval;
    procedure SetAccountno(AValue: string);
  public
    property Accountno : string read FAccountno write SetAccountno;
    property User : TPInterval read FUserI write FUserI;
  end;

  { TBackInterval }

  TBackInterval = class(TPInterval)
  protected
    function GetUsage: Extended; override;
  end;

  { TfTaskPlan }

  TfTaskPlan = class(TPrometMainFrame)
    acShowProject: TAction;
    acShowInProjectGantt: TAction;
    acOpen: TAction;
    acCancel: TAction;
    acUse: TAction;
    ActionList1: TActionList;
    bDayView: TSpeedButton;
    Bevel5: TBevel;
    Bevel7: TBevel;
    bMonthView: TSpeedButton;
    bRefresh: TSpeedButton;
    bToday: TSpeedButton;
    bWeekView: TSpeedButton;
    Label1: TLabel;
    Label3: TLabel;
    lDate: TLabel;
    Label5: TLabel;
    Label7: TLabel;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    miUserOptions: TMenuItem;
    pTasks: TPanel;
    Panel4: TPanel;
    Panel9: TPanel;
    pgantt: TPanel;
    Panel7: TPanel;
    pmAction: TPopupMenu;
    pmUSer: TPopupMenu;
    pmTask: TPopupMenu;
    spTasks: TSplitter;
    tbTop: TPanel;
    ToolButton1: TSpeedButton;
    ToolButton2: TSpeedButton;
    procedure acCancelExecute(Sender: TObject);
    procedure acOpenExecute(Sender: TObject);
    procedure acShowInProjectGanttExecute(Sender: TObject);
    procedure acShowProjectExecute(Sender: TObject);
    procedure acUseExecute(Sender: TObject);
    procedure aIGroupDrawBackground(Sender: TObject; aCanvas: TCanvas;
      aRect: TRect; aStart, aEnd: TDateTime; aDayWidth: Double);
    procedure aINewDrawBackground(Sender: TObject; aCanvas: TCanvas;
      aRect: TRect; aStart, aEnd: TDateTime; aDayWidth: Double);
    procedure aIDrawBackground(Sender: TObject; aCanvas: TCanvas;
      aRect: TRect; aStart, aEnd: TDateTime; aDayWidth: Double;RectColor,FillColor,ProbemColor : TColor);
    procedure aIDrawBackgroundWeekends(Sender: TObject; aCanvas: TCanvas;
      aRect: TRect; aStart, aEnd: TDateTime; aDayWidth: Double);
    procedure aIntervalChanged(Sender: TObject);
    procedure aItemClick(Sender: TObject);
    procedure aSubItemClick(Sender: TObject);
    procedure bDayViewClick(Sender: TObject);
    procedure bMonthViewClick(Sender: TObject);
    procedure bRefreshClick(Sender: TObject);
    procedure bShowTasksClick(Sender: TObject);
    procedure bTodayClick(Sender: TObject);
    procedure bWeekViewClick(Sender: TObject);
    procedure FGanttCalendarClick(Sender: TObject);
    procedure FGanttCalendarDblClick(Sender: TObject);
    procedure FGanttCalendarMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FGanttCalendarMoveOverInterval(Sender: TObject;
      aInterval: TInterval; X, Y: Integer);
    procedure FGanttCalendarShowHint(Sender: TObject; HintInfo: PHintInfo);
    procedure FGanttTreeAfterUpdateCommonSettings(Sender: TObject);
    procedure miUserOptionsClick(Sender: TObject);
    procedure pmActionPopup(Sender: TObject);
    procedure TIntervalChanged(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);
  private
    { private declarations }
    FGantt: TgsGantt;
    FTasks : TTaskList;
    FHintRect : TRect;
    FRow : Integer;
    FUsers : TStringList;
    FOwners : TStringList;
    aClickPoint: types.TPoint;
    FSelectedUser : TInterval;
    FTaskView: TfTaskFrame;
  public
    { public declarations }
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure Populate(aParent : Variant;aUser : Variant);
    procedure CollectResources(aResource : TRessource;asUser : string;aConnection : TComponent = nil);
    function GetIntervalFromCoordinates(Gantt: TgsGantt; X, Y, Index: Integer): TInterval;
    function GetTaskIntervalFromCoordinates(Gantt: TgsGantt; X, Y, Index: Integer): TInterval;
    function GetTaskFromCoordinates(Gantt : TgsGantt;X,Y,Index : Integer) : string;
  end;

  { TCollectThread }

  TCollectThread = class(TThread)
  private
    FResource: uTaskPlan.TRessource;
    FUser: String;
    FPlan: TfTaskPlan;
    FAttatchTo: TInterval;
    procedure Attatch;
    procedure Plan;
  public
    procedure Execute; override;
    constructor Create(aPlan : TfTaskPlan;aResource : TRessource;asUser : string;AttatchTo : TInterval = nil);
  end;
procedure ChangeTask(aTasks: TTaskList;aTask : TInterval);

implementation
uses uData,LCLIntf,uBaseDbClasses,uProjects,uTaskEdit,LCLProc,uGanttView,uColors,
  uCalendar,uTaskPlanOptions;
{$R *.lfm}

{ TCollectThread }

procedure TCollectThread.Attatch;
begin
  FAttatchTo.Pointer:=FResource;
  FPlan.Invalidate;
  Application.ProcessMessages;
end;

procedure TCollectThread.Plan;
var
  aConnection: Classes.TComponent;
begin
  aConnection := Data.GetNewConnection;
  FPlan.CollectResources(FResource,FUser,aConnection);
  aConnection.Free;
end;

procedure TCollectThread.Execute;
begin
  Synchronize(@Plan);
  Synchronize(@Attatch);
end;

constructor TCollectThread.Create(aPlan : TfTaskPlan;aResource: TRessource; asUser: string;AttatchTo : TInterval);
begin
  FPlan := aPlan;
  FResource := aResource;
  FUser := asUser;
  FAttatchTo := AttatchTo;
  FreeOnTerminate:=True;
  //Execute;
  inherited Create(False);
end;

{ TRessource }

procedure TRessource.SetAccountno(AValue: string);
var
  aUser: TUser;
begin
  FAccountno:=AValue;
end;

{ TBackInterval }

function TBackInterval.GetUsage: Extended;
begin
  Result:=0;
end;

procedure TPInterval.CalcUsage(aConnection : TComponent);
var
  aCal: TEvent;
  aRange: Extended;
  aDay: Integer;
  aUser: TUser;
begin
  aUser := TUser.Create(nil,Data,aConnection);
  aUser.SelectByAccountno(FUser);
  aUser.Open;
  FUsage := aUser.FieldByName('USEWORKTIME').AsInteger/100;
  if FUsage = 0 then FUsage := 1;
  FWorkTime:=aUser.WorkTime*FUsage;
  FUsage := FWorkTime/8;
  FUserID:=aUser.Id.AsVariant;
  aUser.Free;
  if FinishDate-StartDate > 0 then
    FCalcUsage := (FinishDate-StartDate)
  else FCalcUsage := 0;
  if FCalcUsage=0 then exit;
  if FUser <> '' then
    begin
      aCal := TEvent.Create(nil,Data,aConnection);
      if FUserID<>Null then
        begin
          aCal.SelectPlanedByUserIdAndTime(FUserId,StartDate,FinishDate);
          aCal.Open;
          while not aCal.EOF do
            begin
              for aDay := trunc(StartDate) to trunc(FinishDate-0.01) do
                begin
                  aRange := aCal.GetTimeInRange(aDay,aDay+1);
                  if (aRange > 1) then
                    aRange := 1;
                  FCalcUsage := FCalcUsage-aRange;
                end;
              aCal.Next;
            end;
        end;
      for aDay := trunc(StartDate) to trunc(FinishDate-0.01) do
        if ((DayOfWeek(aDay) = 1) or (DayOfWeek(aDay) = 7)) then
          FCalcUsage := FCalcUsage-1;
      aCal.Free;
    end;
  if FCalcUsage>0 then
    FCalcUsage:=((NetTime*8)/WorkTime)/FCalcUsage
  else if FCalcUsage=0 then
    FCalcUsage := 1
  else
    FCalcUsage := 10;
end;

function TPInterval.GetWorkTime: Extended;
begin
  if FCalcUsage=-1 then
    CalcUsage(nil);
  Result := FWorkTime;
end;

procedure TPInterval.SetUser(AValue: string;aConnection : TComponent);
begin
  FUser:=AValue;
  FCalcUsage:=-1;
end;

procedure TPInterval.SetStartDate(const Value: TDateTime);
begin
  inherited SetStartDate(Value);
  FCalcUsage:=-1;
end;

procedure TPInterval.SetFinishDate(const Value: TDateTime);
begin
  inherited SetFinishDate(Value);
  FCalcUsage:=-1;
end;

procedure TPInterval.SetNetTime(AValue: TDateTime);
begin
  inherited SetNetTime(AValue);
  FCalcUsage:=-1;
end;

function TPInterval.GetPercentMoveRect: TRect;
begin
  Result:=inherited GetPercentMoveRect;
  Result.Right:=Result.Left;
end;

function TPInterval.GetUsage: Extended;
begin
  if FCalcUsage = -1 then
    CalcUsage(nil);
  Result:=FCalcUsage;
end;

procedure ChangeTask(aTasks: TTaskList;aTask : TInterval);
var
  aTaskI: TTask;
  aTaskI2: TTask;
  i: Integer;
begin
  if aTasks.DataSet.Locate('SQL_ID',aTask.Id,[]) then
    begin
      for i := 0 to aTask.ConnectionCount-1 do
        begin
          aTaskI2 := TTask.Create(nil,Data);
          aTaskI2.Select(aTask.Connection[i].Id);
          aTaskI2.Open;
          aTaskI2.Dependencies.Open;
          if not aTaskI2.Dependencies.DataSet.Locate('REF_ID_ID',aTasks.Id.AsVariant,[]) then
            begin
              aTaskI := TTask.Create(nil,Data);
              aTaskI.Select(aTasks.Id.AsVariant);
              aTaskI.Open;
              aTaskI2.Dependencies.Add(Data.BuildLink(aTaskI.DataSet));
              aTaskI.Free;
            end;
          aTaskI2.Free;
        end;
      if aTasks.FieldByName('CLASS').AsString<>'M' then
        begin
          if not aTasks.CanEdit then
            aTasks.DataSet.Edit;
          aTasks.DataSet.DisableControls;
          if aTasks.FieldByName('SUMMARY').AsString <> aTask.Task then
            aTasks.FieldByName('SUMMARY').AsString := aTask.Task;
          if not aTasks.CanEdit then
            aTasks.DataSet.Edit;
          aTasks.FieldByName('STARTDATE').AsDateTime := aTask.StartDate;
          if not aTasks.CanEdit then
            aTasks.DataSet.Edit;
          if (trim(aTasks.FieldByName('DUEDATE').AsString)='') or (aTasks.FieldByName('DUEDATE').AsDateTime <> aTask.FinishDate) then
            aTasks.FieldByName('DUEDATE').AsDateTime := aTask.FinishDate;
          if aTasks.CanEdit then
            aTasks.DataSet.Post;
        end;
      aTasks.DataSet.EnableControls;
    end;
end;
procedure TfTaskPlan.FGanttTreeAfterUpdateCommonSettings(Sender: TObject);
begin
  fgantt.Tree.ColWidths[0]:=0;
  fgantt.Tree.ColWidths[1]:=0;
  fgantt.Tree.ColWidths[2]:=180;
  fgantt.Tree.Cells[2,0]:=strUsers;
  fgantt.Tree.ColWidths[3]:=0;
  fgantt.Tree.ColWidths[4]:=0;
  fgantt.Tree.ColWidths[5]:=0;
  fgantt.Tree.ColWidths[6]:=0;
  fgantt.Tree.ColWidths[7]:=0;
  FGantt.Tree.Width:=190;
end;

procedure TfTaskPlan.miUserOptionsClick(Sender: TObject);
var
  aUser: TUser;
  CurrInterval: TInterval;
begin
  aUser := TUser.Create(nil,Data);
  CurrInterval := TInterval(FGantt.Tree.Objects[0, FGantt.Tree.Row]);
  if Assigned(CurrInterval) and (CurrInterval is TPInterval) and (TPInterval(CurrInterval).User<>'') then
    begin
      aUser.SelectByAccountno(TPInterval(CurrInterval).User);
      aUser.Open;
      if fUserPlanOptions.Execute(aUser) then
        TPInterval(CurrInterval).SetUser(aUser.FieldByName('ACCOUNTNO').AsString,nil);
    end;
  aUser.Free;
end;

procedure TfTaskPlan.pmActionPopup(Sender: TObject);
var
  aInt: TInterval;
  aItem: TMenuItem;
  aSubItem: TMenuItem;
  i: Integer;
  bItem: TMenuItem;
begin
  aClickPoint := FGantt.Calendar.ScreenToClient(Mouse.CursorPos);
  pmAction.Items.Clear;
  for i := 0 to 100 do
    begin
      aInt := GetIntervalFromCoordinates(FGantt,FGantt.Calendar.ScreenToClient(Mouse.CursorPos).X,FGantt.Calendar.ScreenToClient(Mouse.CursorPos).Y,i);
      if Assigned(aInt) then
        begin
          aItem := TMenuItem.Create(pmAction);
          aItem.Caption:=aInt.Task;
          aItem.Tag:=i;
          pmAction.Items.Add(aItem);
          aSubItem := TMenuItem.Create(pmAction);
          aSubItem.Action:=acOpen;
          aSubItem.Tag:=i;
          aSubItem.OnClick:=@aSubItemClick;
          aItem.Add(aSubItem);
          if aInt.Project<>'' then
            begin
              aSubItem := TMenuItem.Create(pmAction);
              aSubItem.Action:=acShowInProjectGantt;
              aSubItem.Tag:=i;
              aSubItem.OnClick:=@aSubItemClick;
              aItem.Add(aSubItem);
              aSubItem := TMenuItem.Create(pmAction);
              aSubItem.Action:=acShowProject;
              aSubItem.Tag:=i;
              aSubItem.OnClick:=@aSubItemClick;
              aItem.Add(aSubItem);
            end;
        end
      else break;
    end;
  if pmAction.Items.Count=1 then
    begin
      pmAction.Items.Remove(aItem);
      while aItem.Count>0 do
        begin
          bItem := aItem.Items[0];
          aItem.Remove(bItem);
          pmAction.Items.Add(bItem);
        end;
    end;
end;

procedure TfTaskPlan.TIntervalChanged(Sender: TObject);
begin
  TInterval(TInterval(Sender).Pointer2).StartDate:=TInterval(Sender).StartDate;
  TInterval(TInterval(Sender).Pointer2).FinishDate:=TInterval(Sender).FinishDate;
  acUse.Enabled:=True;
  acCancel.Enabled:=True;
end;

procedure TfTaskPlan.ToolButton1Click(Sender: TObject);
begin

end;

function TfTaskPlan.GetTaskFromCoordinates(Gantt: TgsGantt; X, Y,Index: Integer
  ): string;
var
  aInt: gsGanttCalendar.TInterval;
begin
  aInt := GetTaskIntervalFromCoordinates(Gantt,X,Y,Index);
  if aInt = nil then
    aInt := GetIntervalFromCoordinates(Gantt,X,Y,Index);
  if Assigned(aInt) then
    if aInt.Id <> Null then
      begin
        Result := 'TASKS@'+VarToStr(aInt.Id);
      end;
end;

procedure TfTaskPlan.bDayViewClick(Sender: TObject);
begin
  FGantt.MinorScale:=tsDay;
  FGantt.MajorScale:=tsWeekNum;
  FGantt.Calendar.StartDate:=FGantt.Calendar.StartDate;
end;

procedure TfTaskPlan.aIntervalChanged(Sender: TObject);
var
  i: Integer;
  oD: TDateTime;
  a: Integer;
begin
  with TInterval(Sender) do
    begin
      if FinishDate<(StartDate+Duration) then
        FinishDate := (StartDate+Duration);
      IntervalDone:=StartDate;
      for i := 0 to ConnectionCount-1 do
        begin
          oD := Connection[i].Duration;
          if Connection[i].StartDate<FinishDate+Buffer then
            Connection[i].StartDate:=FinishDate+Buffer;
          if Connection[i].FinishDate<Connection[i].StartDate+oD then
            Connection[i].FinishDate:=Connection[i].StartDate+oD;
          Connection[i].IntervalDone:=Connection[i].StartDate;
        end;
    end;
end;

procedure TfTaskPlan.aItemClick(Sender: TObject);
var
  List: TList;
  i: Integer;
  ay: Integer;
begin
  List := TList.Create;
  FGantt.MakeIntervalList(List);
  for i := 0 to List.Count-1 do
    begin
      TInterval(List[i]).StartDate:=Now()-(365*10);
      TInterval(List[i]).FinishDate:=Now()-(365*10);
    end;
  ay := aClickPoint.Y-FGantt.Calendar.StartDrawIntervals;
  ay := ay div max(FGantt.Calendar.PixelsPerLine,1);
  ay := ay+(FGantt.Tree.TopRow-1);
  if (ay<List.Count) and (ay>-1) then
    if (Assigned(TInterval(List[ay]).Pointer)) and (TInterval(List[ay]).Pointer2<>Pointer(TMenuItem(Sender).Tag)) then
      begin
        TInterval(List[ay]).StartDate:=TInterval(TMenuItem(Sender).Tag).StartDate;
        TInterval(List[ay]).FinishDate:=TInterval(TMenuItem(Sender).Tag).FinishDate;
        TInterval(List[ay]).Pointer2 := TInterval(TMenuItem(Sender).Tag);
        FSelectedUser := TInterval(List[ay]);
        TInterval(List[ay]).OnChanged:=@TIntervalChanged;
        FGantt.Invalidate;
      end;
  List.Free;
end;

procedure TfTaskPlan.aSubItemClick(Sender: TObject);
begin
  TMenuItem(Sender).Action.Tag:=TMenuItem(Sender).Tag;
  //TMenuItem(Sender).Action.Execute;
end;

procedure TfTaskPlan.aINewDrawBackground(Sender: TObject; aCanvas: TCanvas;
  aRect: TRect; aStart, aEnd: TDateTime; aDayWidth: Double);
begin
  aIDrawBackgroundWeekends(Sender,aCanvas,aRect,aStart,aEnd,aDayWidth);
  aIDrawBackground(Sender,aCanvas,aRect,aStart,aEnd,aDayWidth,clBlue,clLime,clRed);
end;

procedure TfTaskPlan.aIDrawBackground(Sender: TObject; aCanvas: TCanvas;
  aRect: TRect; aStart, aEnd: TDateTime; aDayWidth: Double;RectColor,FillColor,ProbemColor : TColor);
var
  i: Integer;
  aDay: TDateTime;
  aResource: TRessource;
  aIStart: TDateTime;
  aIEnd: TDateTime;
  aRowTop: Integer;
  aAddTop : Integer = 0;
  aDst: TRect;
  a: Integer;
  Rect1: Classes.TRect;
  Rect2: Classes.TRect;
  cRect: TRect;
  WholeUsage: Extended;
  cHeight: Integer;
  procedure PaintRect(bCanvas : TCanvas;bRect : Trect;aInterval : TInterval);
  var
    cRect: types.TRect;
    aUsage: Extended;
  begin
    with bCanvas do
      begin
        Pen.Style := psSolid;
        Brush.Style := bsSolid;
        Brush.Color:=clWindow;
        Pen.Color:=RectColor;
        Rectangle(bRect);
        cRect := bRect;
        aUsage := (aInterval.PercentUsage);
        if aUsage>1 then
          Brush.Color:=ProbemColor
        else
          Brush.Color:=FillColor;
        if Assigned(aInterval.Parent) and (aInterval.Parent is TRessource) and Assigned(TRessource(aInterval.Parent).User) then
          aUsage := aUsage*(1/TRessource(aInterval.Parent).User.FUsage);
        cRect.Top := cRect.Bottom-round((cRect.Bottom-cRect.Top-1)*aUsage);
        if cRect.Top<=bRect.Top then
          begin
            cRect.Top := bRect.Top+1;
          end;
        cRect.left := bRect.Left+1;
        pen.Style:=psClear;
        Rectangle(cRect);
      end;
  end;
  procedure MarkRect(bCanvas : TCanvas;bRect : Trect);
  begin
    with bCanvas do
      begin
        Pen.Style := psSolid;
        Brush.Color:=RectColor;
        pen.Color:=RectColor;
        Brush.Style:=bsFDiagonal;
        FillRect(aDst);
        Brush.Style:=bsSolid;
      end;
  end;
begin
  if Assigned(TInterval(Sender).Pointer) then
    begin
      aResource := TRessource(TInterval(Sender).Pointer);
      for i := 0 to aResource.IntervalCount-1 do
        if not (aResource.Interval[i] is TBackInterval) then
        begin
          aResource.Interval[i].ClearDrawRect;
          if ((aResource.Interval[i].StartDate>aStart) and (aResource.Interval[i].StartDate<aEnd))
          or ((aResource.Interval[i].FinishDate>aStart) and (aResource.Interval[i].FinishDate<aEnd))
          or ((aResource.Interval[i].StartDate<=aStart) and (aResource.Interval[i].FinishDate>=aEnd))
          then
            begin
              aIStart := aResource.Interval[i].StartDate;
              if aStart > aIStart then aIStart := aStart;
              aIEnd := aResource.Interval[i].FinishDate;
              if aEnd < aIEnd then aIEnd := aEnd;
              if aIEnd<=aIStart then aIEnd := aIStart+1;
              aResource.Interval[i].DrawRect:=Rect(round((aIStart-aStart)*aDayWidth),(aRect.Top+((aRect.Bottom-aRect.Top) div 4)-1)+aAddTop,round((aIEnd-aStart)*aDayWidth)-1,(aRect.Bottom-((aRect.Bottom-aRect.Top) div 4)-1)+aAddTop);
              PaintRect(aCanvas,aResource.Interval[i].DrawRect,aResource.Interval[i]);
              WholeUsage := aResource.Interval[i].PercentUsage;
              for a := 0 to i-1 do
                begin
                  if (not aResource.Interval[a].IsDrawRectClear) and (not (aResource.Interval[a] is TBackInterval)) then
                    begin
                      Rect1 := aResource.Interval[i].DrawRect;
                      Rect2 := aResource.Interval[a].DrawRect;
                      if IntersectRect(aDst,Rect1,Rect2) then
                        begin
                          WholeUsage := WholeUsage+(aResource.Interval[a]).PercentUsage;
                          cRect := aDst;
                          cHeight := cRect.Bottom-cRect.Top;
                          cHeight := round(cHeight*WholeUsage);
                          cRect.Top := cRect.Bottom-cHeight;
                          if cRect.Top<=aDst.Top then
                            cRect.Top := aDst.Top+1;
                          cRect.left := aDst.Left+1;
                          aCanvas.pen.Style:=psClear;
                          if WholeUsage>1 then
                            aCanvas.Brush.Color:=ProbemColor
                          else
                            aCanvas.Brush.Color:=FillColor;
                          aCanvas.Rectangle(cRect);
                          {$IFDEF LINUX}
                          MarkRect(aCanvas,aDst);
                          {$ENDIF}
                        end;
                    end;
                end;
            end;
        end;
    end;
end;

procedure TfTaskPlan.aIDrawBackgroundWeekends(Sender: TObject;
  aCanvas: TCanvas; aRect: TRect; aStart, aEnd: TDateTime; aDayWidth: Double);
var
  i: Integer;
  aDay: Extended;
  aResource: TRessource;
  aIStart: TDateTime;
  aIEnd: TDateTime;
  bRect : Trect;
begin
  aCanvas.Brush.Style:=bsSolid;
  aCanvas.Brush.Color:=clWindow;
  aCanvas.FillRect(aRect);
  aCanvas.Brush.Color:=$e0e0e0;
  if Assigned(TInterval(Sender).Gantt) then
    aCanvas.Pen.Color:=TInterval(Sender).Gantt.Tree.GridLineColor
  else
    aCanvas.Pen.Color:=clBtnFace;
  aCanvas.Pen.Style:=psSolid;
  aCanvas.MoveTo(aRect.Left,aRect.Top);
  aCanvas.LineTo(aRect.Right,aRect.Top);
  for i := 0 to round(aEnd-aStart) do
    begin
      aDay := aStart+i;
      if (DayOfWeek(aDay) = 1) or (DayOfWeek(aDay) = 7) then
        aCanvas.FillRect(round(i*aDayWidth),aRect.Top+1,round((i*aDayWidth)+aDayWidth),aRect.Bottom);
    end;
  if Assigned(TInterval(Sender).Pointer) then
    begin
      aResource := TRessource(TInterval(Sender).Pointer);
      for i := 0 to aResource.IntervalCount-1 do
        if aResource.Interval[i] is TBackInterval then
          begin
            aResource.Interval[i].ClearDrawRect;
            if ((aResource.Interval[i].StartDate>aStart) and (aResource.Interval[i].StartDate<aEnd))
            or ((aResource.Interval[i].FinishDate>aStart) and (aResource.Interval[i].FinishDate<aEnd))
            or ((aResource.Interval[i].StartDate<=aStart) and (aResource.Interval[i].FinishDate>=aEnd))
            then
              begin
                aIStart := aResource.Interval[i].StartDate;
                if aStart > aIStart then aIStart := aStart;
                aIEnd := aResource.Interval[i].FinishDate;
                if aEnd < aIEnd then aIEnd := aEnd;
                if aIEnd<=aIStart then aIEnd := aIStart+1;
                bRect :=Rect(round((aIStart-aStart)*aDayWidth),aRect.Top+1,round((aIEnd-aStart)*aDayWidth),aRect.Bottom);
                aResource.Interval[i].DrawRect:=bRect;
                aCanvas.FillRect(aResource.Interval[i].DrawRect);
              end;
          end;

    end;
end;

procedure TfTaskPlan.acShowProjectExecute(Sender: TObject);
var
  aTask: TTask;
  aProject: TProject;
  aLink: String;
begin
  aLink := GetTaskFromCoordinates(FGantt,aClickPoint.X,aClickPoint.Y,TMenuItem(Sender).Tag);
  aTask := TTask.Create(nil,Data);
  aTask.SelectFromLink(aLink);
  aTask.Open;
  if aTask.Count>0 then
    begin
      aProject := TProject.Create(nil,Data);
      aProject.Select(aTask.FieldByName('PROJECTID').AsVariant);
      aProject.Open;
      if aProject.Count>0 then
        Data.GotoLink(Data.BuildLink(aProject.DataSet));
      aProject.Free;
    end;
  aTask.Free;
end;

procedure TfTaskPlan.acUseExecute(Sender: TObject);
  procedure RecoursiveChange(aParent : TInterval);
  var
    i: Integer;
    aTasks: TTask;
  begin
    for i := 0 to aParent.IntervalCount-1 do
      begin
        RecoursiveChange(aParent.Interval[i]);
      end;
    if Assigned(aParent.Pointer) then
      begin
        for i := 0 to TInterval(aParent.Pointer).IntervalCount-1 do
          begin
            if TRessource(aParent.Pointer).Interval[i].Changed then
              begin
                aTasks := TTask.Create(nil,Data);
                aTasks.Select(TRessource(aParent.Pointer).Interval[i].Id);
                aTasks.Open;
                debugln('changing '+TRessource(aParent.Pointer).Interval[i].Task);
                ChangeTask(aTasks,TRessource(aParent.Pointer).Interval[i]);
                aTasks.Free;
              end;
          end;
      end;
  end;
var
  i: Integer;
begin
  for i := 0 to FGantt.IntervalCount-1 do
    begin
      RecoursiveChange(FGantt.Interval[i]);
    end;
  acUse.Enabled:=False;
  acCancel.Enabled:=False;
end;

procedure TfTaskPlan.aIGroupDrawBackground(Sender: TObject; aCanvas: TCanvas;
  aRect: TRect; aStart, aEnd: TDateTime; aDayWidth: Double);
var
  aDay: Integer;
  aInt: TInterval;
  WorkTimes: Extended;
  b: Integer;
  aTime: Extended;
  aUsage: Extended;
  function CollectWorkTimes(aInt : TInterval) : Extended;
  var
    i: Integer;
  begin
    Result := 0;
    for i := 0 to aInt.IntervalCount-1 do
      begin
        if aInt.Interval[i].IntervalCount>0 then
          Result := Result+CollectWorkTimes(aInt.Interval[i])
        else if aInt.Interval[i] is TPInterval then
          Result := Result+TPInterval(aInt.Interval[i]).WorkTime;
      end;
  end;
  function CollectTimeAtDay(Day : Integer;aInt : TInterval) : Extended;
  var
    aResource: TRessource;
    i: Integer;
    a: Integer;
    bTime: Extended;
  begin
    Result := 0;
    for i := 0 to aInt.IntervalCount-1 do
      begin
        if aInt.Interval[i].IntervalCount>0 then
          Result := Result+CollectTimeAtDay(Day,aInt.Interval[i])
        else if aInt.Interval[i] is TPInterval then
          begin
            if Assigned(TInterval(aInt.Interval[i]).Pointer) then
              begin
                aResource := TRessource(TInterval(aInt.Interval[i]).Pointer);
                for a := 0 to aResource.IntervalCount-1 do
                  begin
                    if aResource.Interval[a].FinishDate-aResource.Interval[a].StartDate>0 then
                      begin
                        bTime :=TPInterval(aResource.Interval[a]).PercentUsage*(aResource.Interval[a].FinishDate-aResource.Interval[a].StartDate);
                        bTime := bTime*TimeRangeOverlap(Day,Day+1,aResource.Interval[a].StartDate,aResource.Interval[a].FinishDate)/(aResource.Interval[a].FinishDate-aResource.Interval[a].StartDate);
                        bTime := bTime*TPInterval(aInt.Interval[i]).WorkTime;
                        //bTime := bTime*(1/TPInterval(aInt.Interval[i]).FUsage);
                        //if bTime>TPInterval(aInt.Interval[i]).WorkTime then
                        //  bTime := TPInterval(aInt.Interval[i]).WorkTime;
                        Result := Result+bTime;
                      end;
                  end;
              end;
          end;
      end;
  end;
begin
  aCanvas.Brush.Style:=bsSolid;
  aCanvas.Brush.Color:=$00FFE6E6;
  aCanvas.FillRect(aRect);
  aInt := TInterval(Sender);
  WorkTimes := CollectWorkTimes(TInterval(Sender));
  for aDay := trunc(aStart) to trunc(aEnd) do
    if ((DayOfWeek(aDay) <> 1) and (DayOfWeek(aDay) <> 7)) then
      begin
        b := aDay-trunc(aStart);
        aTime := CollectTimeAtDay(aDay,aInt);
        aCanvas.Brush.Color:=clLime;
        if aTime>WorkTimes then
          begin
            aTime := WorkTimes;
            aCanvas.Brush.Color:=clred;
          end;
        if WorkTimes>0 then
          aUsage := (aTime/WorkTimes)
        else aUsage := 0;
        aCanvas.FillRect(round(b*aDayWidth),aRect.Bottom-round(aUsage*(aRect.Bottom-aRect.Top)),round((b*aDayWidth)+aDayWidth),aRect.Bottom);
      end;
  if Assigned(TInterval(Sender).Gantt) then
    aCanvas.Pen.Color:=TInterval(Sender).Gantt.Tree.GridLineColor
  else
    aCanvas.Pen.Color:=clBtnFace;
  aCanvas.Pen.Style:=psSolid;
  aCanvas.MoveTo(aRect.Left,aRect.Top);
  aCanvas.LineTo(aRect.Right,aRect.Top);
end;

procedure TfTaskPlan.acShowInProjectGanttExecute(Sender: TObject);
var
  aTask: TTask;
  aProject: TProject;
  aLink: String;
begin
  aLink := GetTaskFromCoordinates(FGantt,aClickPoint.X,aClickPoint.Y,TMenuItem(Sender).Tag);
  aTask := TTask.Create(nil,Data);
  aTask.SelectFromLink(aLink);
  aTask.Open;
  if aTask.Count>0 then
    begin
      aProject := TProject.Create(nil,Data);
      aProject.Select(aTask.FieldByName('PROJECTID').AsVariant);
      aProject.Open;
      if aProject.Count>0 then
        begin
          aProject.Tasks.SelectActive;
          aProject.Tasks.Open;
          fGanttView.Execute(aProject,aLink);
        end;
      aProject.Free;
    end;
  aTask.Free;
end;

procedure TfTaskPlan.acOpenExecute(Sender: TObject);
var
  aLink: String;
  aEdit: TfTaskEdit;
  aInt: gsGanttCalendar.TInterval;
  aTask: TTask;
  gView : TfGanttView;
begin
  aLink := GetTaskFromCoordinates(FGantt,aClickPoint.X,aClickPoint.Y,TMenuItem(Sender).Tag);
  if aLink <> '' then
    begin
      aEdit :=TfTaskEdit.Create(nil);
      if aEdit.Execute(aLink) then
        begin
          aInt := GetIntervalFromCoordinates(FGantt,aClickPoint.X,aClickPoint.Y,TMenuItem(Sender).Tag);
          if Assigned(aInt) then
            begin
              aTask := TTask.Create(nil,Data);
              aTask.SelectFromLink(aLink);
              aTask.Open;
              gView.FillInterval(TPInterval(aInt),aTask);
              aTask.Free;
              FGantt.Calendar.Invalidate;
            end;
        end;
      aEdit.Free;
    end;
end;

procedure TfTaskPlan.acCancelExecute(Sender: TObject);
begin
  bRefreshClick(Sender);
end;

procedure TfTaskPlan.bMonthViewClick(Sender: TObject);
begin
  FGantt.MinorScale:=tsDay;
  FGantt.MajorScale:=tsQuarter;
  FGantt.MinorScale:=tsMonth;
  FGantt.Calendar.StartDate:=FGantt.Calendar.StartDate;
end;

procedure TfTaskPlan.bRefreshClick(Sender: TObject);
  procedure RefreshRes(aInt : TInterval);
  var
    i: Integer;
    aUser: String;
    tmpRes: TRessource;
  begin
    for i := 0 to aInt.IntervalCount-1 do
      RefreshRes(aInt.Interval[i]);
    if Assigned(aInt.Pointer) then
      begin
        aUser := TPInterval(aInt).User;
        TInterval(aInt.Pointer).Free;
        aInt.Pointer := nil;
        tmpRes := TRessource.Create(nil);
        tmpRes.User:=TPInterval(aInt);
        TCollectThread.Create(Self,tmpRes,aUser,aInt);
      end;
  end;
var
  i: Integer;
begin
  for i := 0 to FGantt.IntervalCount-1 do
    RefreshRes(FGantt.Interval[i]);
end;

procedure TfTaskPlan.bShowTasksClick(Sender: TObject);
begin
  FGantt.Calendar.Invalidate;
end;

procedure TfTaskPlan.bTodayClick(Sender: TObject);
begin
  FGantt.StartDate:=Now();
end;

procedure TfTaskPlan.bWeekViewClick(Sender: TObject);
begin
  FGantt.MinorScale:=tsDay;
  FGantt.MajorScale:=tsMonth;
  FGantt.MinorScale:=tsWeekNumPlain;
  FGantt.Calendar.StartDate:=FGantt.Calendar.StartDate;
end;

procedure TfTaskPlan.FGanttCalendarClick(Sender: TObject);
var
  aInt: TInterval;
  List: TList;
  ay: Integer;
  i: Integer;
  aItem: TMenuItem;
begin
  pmTask.Items.Clear;
  aClickPoint := FGantt.Calendar.ScreenToClient(Mouse.CursorPos);
  for i := 0 to 100 do
    begin
      aInt := GetIntervalFromCoordinates(FGantt,aClickPoint.X,aClickPoint.Y,i);
      if not Assigned(aInt) then break;
      if Assigned(aInt) then
        begin
          aItem := TMenuItem.Create(pmTask);
          aItem.Caption:=aInt.Task+' ('+IntToStr(round(aInt.PercentUsage*100))+'%)';
          aItem.Tag:=PtrInt(aInt);
          aItem.OnClick:=@aItemClick;
          pmTask.Items.Add(aItem);
        end;
      if Assigned(FSelectedUser) and (aInt = TInterval(FSelectedUser.Pointer2)) then exit;
    end;
  if Assigned(FSelectedUser) then
    begin
      FSelectedUser.OnChanged:=nil;
      FSelectedUser.StartDate:=Now()-(365*10);
      FSelectedUser.FinishDate:=Now()-(365*10);
      FSelectedUser.Pointer2 := nil;
      FSelectedUser := nil;
      Invalidate;
    end;
  List := TList.Create;
  FGantt.MakeIntervalList(List);
  if pmTask.Items.Count=1 then
    begin
      aInt := GetIntervalFromCoordinates(FGantt,aClickPoint.X,aClickPoint.Y,0);
      ay := aClickPoint.Y-FGantt.Calendar.StartDrawIntervals;
      ay := ay div max(FGantt.Calendar.PixelsPerLine,1);
      ay := ay+(FGantt.Tree.TopRow-1);
      if (ay<List.Count) and (ay>-1) then
        if (Assigned(TInterval(List[ay]).Pointer)) and Assigned(aInt) and (TInterval(List[ay]).Pointer2<>Pointer(aInt)) then
          begin
            TInterval(List[ay]).StartDate:=aInt.StartDate;
            TInterval(List[ay]).FinishDate:=aInt.FinishDate;
            TInterval(List[ay]).OnChanged:=@TIntervalChanged;
            TInterval(List[ay]).Pointer2:=aInt;
            FSelectedUser := TInterval(List[ay]);
            FGantt.Invalidate;
          end;
    end
  else
    begin
      pmTask.PopUp(Mouse.CursorPos.X,Mouse.CursorPos.Y);
    end;
  List.Free;
end;

procedure TfTaskPlan.FGanttCalendarDblClick(Sender: TObject);
begin
  aClickPoint := FGantt.Calendar.ScreenToClient(Mouse.CursorPos);
  acOpen.Execute;
end;

procedure TfTaskPlan.FGanttCalendarMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  ay: Integer;
begin
  lDate.Caption := DateToStr(FGantt.Calendar.VisibleStart+trunc((X/FGantt.Calendar.GetIntervalWidth)));

  if fHintRect.Left>-1 then
    begin
      if (X<FHintRect.Left)
      or (X>FHintRect.Right)
      then
        begin
          FHintRect.Left:=-1;
          Application.CancelHint;
        end;
    end;
end;

procedure TfTaskPlan.FGanttCalendarMoveOverInterval(Sender: TObject;
  aInterval: TInterval; X, Y: Integer);
begin
  if (not Assigned(aInterval)) then
    begin
      FGantt.Calendar.Hint:='';
      exit;
    end;
  if FGantt.Calendar.Hint=aInterval.Task then exit;
  FHintRect:=aInterval.DrawRect;
  FGantt.Calendar.Hint:=aInterval.Task+LineEnding+aInterval.Resource;
  FGantt.Calendar.ShowHint:=True;
end;

procedure TfTaskPlan.FGanttCalendarShowHint(Sender: TObject;
  HintInfo: PHintInfo);
  function IsInRect(X, Y: Integer; R: TRect): Boolean;
  begin
    Result := (X >= R.Left) and (X <= R.Right); //and (Y >= R.Top) and (Y <= R.Bottom);
    FHintRect := R;
  end;
  function IsInRow(X, Y: Integer; R: TRect): Boolean;
  begin
    Result := (Y >= R.Top) and (Y <= R.Bottom);
  end;
var
  ay: Integer;
  i: Integer;
  List : TList;
  aPercent : Integer = 0;
  DD: String;
begin
  if HintInfo^.HintStr='' then
    begin
      List := TList.Create;
      FGantt.MakeIntervalList(List);
      ay := HintInfo^.CursorPos.Y-FGantt.Calendar.StartDrawIntervals;
      ay := ay div max(FGantt.Calendar.PixelsPerLine,1);
      ay := ay+(FGantt.Tree.TopRow-1);
      HintInfo^.HintStr := '';
      HintInfo^.HideTimeout:=30000;
      if (ay<List.Count) and (ay>-1) then
        if Assigned(TInterval(List[ay]).Pointer) then
          begin
            for i := 0 to TRessource(TInterval(List[ay]).Pointer).IntervalCount-1 do
              if not TRessource(TInterval(List[ay]).Pointer).Interval[i].IsDrawRectClear then
                if IsInRect(HintInfo^.CursorPos.X,HintInfo^.CursorPos.Y,TRessource(TInterval(List[ay]).Pointer).Interval[i].DrawRect) then
                  begin
                    aPercent := aPercent+round(TRessource(TInterval(List[ay]).Pointer).Interval[i].PercentUsage*100);
                    if not (TRessource(TInterval(List[ay]).Pointer).Interval[i] is TBackInterval) then
                      begin
                        if HintInfo^.HintStr <> '' then HintInfo^.HintStr := HintInfo^.HintStr+lineending;
                        if TRessource(TInterval(List[ay]).Pointer).Interval[i].DepDone then
                          DD := ' '
                        else DD := 'x';
                        HintInfo^.HintStr := HintInfo^.HintStr+IntToStr(round(TRessource(TInterval(List[ay]).Pointer).Interval[i].PercentUsage*100))+'% '+DD+' '+TRessource(TInterval(List[ay]).Pointer).Interval[i].Task+'-'+TRessource(TInterval(List[ay]).Pointer).Interval[i].Project;
                      end
                    else
                      begin
                        if HintInfo^.HintStr <> '' then HintInfo^.HintStr := HintInfo^.HintStr+lineending;
                        HintInfo^.HintStr := HintInfo^.HintStr+TRessource(TInterval(List[ay]).Pointer).Interval[i].Task;
                      end;
                  end;
          end;
      if HintInfo^.HintStr <> '' then
        HintInfo^.HintStr := TRessource(TInterval(List[ay]).Pointer).Resource+' '+Format(strFullPercent,[aPercent])+LineEnding+HintInfo^.HintStr;
      List.Free;
    end;
end;

constructor TfTaskPlan.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FOwners := TStringList.Create;
  FUsers := TStringList.Create;
  FGantt := TgsGantt.Create(Self);
  FSelectedUser := nil;
  FGantt.Parent := pgantt;
  FGantt.Align:=alClient;
  FGantt.Tree.AfterUpdateCommonSettings:=@FGanttTreeAfterUpdateCommonSettings;
  FGantt.Calendar.OnMoveOverInterval:=@FGanttCalendarMoveOverInterval;
  FGantt.Calendar.OnShowHint:=@FGanttCalendarShowHint;
  FGantt.Calendar.OnMouseMove:=@FGanttCalendarMouseMove;
  FGantt.Calendar.OnDblClick:=@FGanttCalendarDblClick;
  FGantt.Calendar.OnClick:=@FGanttCalendarClick;
  FGantt.Calendar.PopupMenu := pmAction;
  FGantt.Tree.PopupMenu := pmUSer;
  bDayViewClick(nil);
  FGantt.Calendar.ShowHint:=True;
  FTaskView := TfTaskFrame.Create(Self);
  FTaskView.BaseName:='TPTASKS';
  FTaskView.Parent := pTasks;
  FTaskView.Align:=alClient;
  FTaskView.Panel9.Visible:=True;
end;

destructor TfTaskPlan.Destroy;
  procedure RefreshRes(aInt : TInterval);
  var
    i: Integer;
  begin
    for i := 0 to aInt.IntervalCount-1 do
      RefreshRes(aInt.Interval[i]);
    if Assigned(aInt.Pointer) then
      begin
        TInterval(aInt.Pointer).Free;
        aInt.Pointer := nil;
      end;
  end;
var
  i: Integer;
begin
  for i := 0 to FGantt.IntervalCount-1 do
    RefreshRes(FGantt.Interval[i]);
  if Assigned(FDataSet) then
    begin
      FreeAndNil(FDataSet);
    end;
  FOwners.Free;
  FUsers.Free;
  FTaskView.Free;
  inherited Destroy;
end;

procedure TfTaskPlan.Populate(aParent: Variant;aUser : Variant);
var
  aTasks: TTaskList;
var
  aNewInterval: TInterval;
  aTask: TTask;
  aInterval: TInterval;
  aDep: TInterval;
  i: Integer;
  aUserFilter : string ='';
  aRoot: TUser;
  aIRoot: TInterval;

  procedure CollectUsers(aIParent : TInterval;bParent : Variant);
  var
    aUsers: TUser;
    aINew: TPInterval;
    tmpRes: TRessource;
  begin
    aUsers := TUser.Create(nil,Data);
    Data.SetFilter(aUsers,Data.QuoteField('PARENT')+'='+Data.QuoteValue(bParent));
    aUsers.First;
    while not aUsers.EOF do
      begin
        if aUsers.FieldByName('TYPE').AsString='G' then
          begin
            aINew := TPInterval.Create(FGantt);
            aINew.Task:=aUsers.FieldByName('NAME').AsString;
            aINew.StartDate:=Now()-(365*10);
            aINew.FinishDate:=Now()-(365*10);
            aINew.Visible:=True;
            aINew.Style:=isNone;
            aIParent.AddInterval(aINew);
            CollectUsers(aINew,aUsers.Id.AsVariant);
            aINew.OnDrawBackground:=@aIGroupDrawBackground;
          end
        else if not ((aUsers.FieldByName('LEAVED').AsString<>'') and (aUsers.FieldByName('LEAVED').AsDateTime<Now())) and ((aUser = Null) or (aUser = aUsers.id.AsVariant)) then
          begin
            aINew := TPInterval.Create(FGantt);
            aINew.Task:=aUsers.FieldByName('NAME').AsString;
            aINew.StartDate:=Now()-(365*10);
            aINew.FinishDate:=Now()-(365*10);
            aINew.SetUser(aUsers.FieldByName('ACCOUNTNO').AsString,nil);
            aINew.Visible:=True;
            aIParent.AddInterval(aINew);
            tmpRes := TRessource.Create(nil);
            tmpRes.User:=aINew;
            TCollectThread.Create(Self,tmpRes,aUsers.FieldByName('ACCOUNTNO').AsString,aINew);
            aINew.OnDrawBackground:=@aINewDrawBackground;
          end;
        aUsers.Next;
      end;
  end;
begin
  if Data.Users.FieldByName('PARENT').AsVariant = Null then exit;
  if Data.Users.FieldByName('POSITION').AsString='LEADER' then
    begin
      if not Assigned(FDataSet) then
        begin
          FDataSet := TTaskList.Create(nil,Data);
          TTaskList(FDataSet).SelectByDept(Data.Users.FieldByName('PARENT').AsVariant);
          FDataSet.Open;
          FTaskView.GridView.DefaultRows:='GLOBALWIDTH:590;COMPLETED:30;SUMMARY:200;STARTDATE:60;DUEDATE:60;USER:100;OWNER:100;PERCENT:40';
          FTaskView.bDelegated1.Down:=True;
          FTaskView.bDependencies1.Down:=True;
          FTaskView.bFuture1.Down:=True;
          FTaskView.UserID := Data.Users.Id.AsVariant;
          FTaskView.IgnoreUser := True;
          FTaskView.DataSet := FDataSet;
        end;
    end
  else
    begin
      pTasks.Visible:=False;
      spTasks.Visible:=False;
    end;
  while FGantt.IntervalCount>0 do
    FGantt.DeleteInterval(0);
  aIRoot := TInterval.Create(FGantt);
  aRoot := TUser.Create(nil,Data);
  aRoot.Open;
  FGantt.BeginUpdate;
  if aRoot.DataSet.Locate('SQL_ID',aParent,[]) then
    begin
      aIRoot.Task:=aRoot.FieldByName('NAME').AsString;
      aIRoot.Visible:=True;
      aIRoot.StartDate:=Now()-1;
      aIRoot.FinishDate:=Now()-1;
      aIRoot.OnDrawBackground:=@aIGroupDrawBackground;
      FGantt.AddInterval(aIRoot);
      CollectUsers(aIRoot,aParent);
    end;
  aRoot.Free;
  FGantt.EndUpdate;
  FGantt.Tree.TopRow:=1;
  FGantt.StartDate:=Now();
  acUse.Enabled:=False;
  acCancel.Enabled:=False;
end;

procedure TfTaskPlan.CollectResources(aResource: TRessource; asUser: string;aConnection : TComponent = nil);
var
  aUser: TUser;
  bTasks: TTaskList;
  bInterval: TPInterval;
  aDue: System.TDateTime;
  aStart: System.TDateTime;
  aCalendar: TCalendar;
  gView : TfGanttView;
begin
  aUser := TUser.Create(nil,Data,aConnection);
  aUser.SelectByAccountno(asUser);
  aUser.Open;
  aResource.Resource := aUser.Text.AsString;
  aUser.Free;
  aResource.Accountno := asUSer;
  bTasks := TTaskList.Create(nil,Data,aConnection);
  bTasks.SelectActiveByUser(asUser);
  bTasks.Open;
  with bTasks.DataSet do
    begin
      while not EOF do
        begin
          bInterval := nil;
          if  (not bTasks.FieldByName('DUEDATE').IsNull)
          and (not bTasks.FieldByName('PLANTIME').IsNull)
          and (not (bTasks.FieldByName('PLANTASK').AsString='N'))
          then
            begin
              bInterval := TPInterval.Create(nil);
              gView.FillInterval(bInterval,bTasks);
            end;
          if Assigned(bInterval) then
            begin
              bInterval.SetUser(asUser,aConnection);
              bInterval.Changed:=False;
              aResource.AddInterval(bInterval);
            end;
          Next;
        end;
    end;
  bTasks.Free;
  aCalendar := TCalendar.Create(nil,Data,aConnection);
  aCalendar.SelectPlanedByUser(asUser);
  aCalendar.Open;
  with aCalendar.DataSet do
    begin
      First;
      while not EOF do
        begin
          bInterval := TBackInterval.Create(nil);
          bInterval.StartDate:=aCalendar.FieldByName('STARTDATE').AsDateTime;
          bInterval.FinishDate:=aCalendar.FieldByName('ENDDATE').AsDateTime;
          if aCalendar.FieldByName('ALLDAY').AsString = 'Y' then
            begin
              bInterval.StartDate := trunc(bInterval.StartDate);
              bInterval.FinishDate := trunc(bInterval.FinishDate+1);
            end;
          bInterval.Task:=aCalendar.FieldByName('SUMMARY').AsString;
          aResource.AddInterval(bInterval);
          bInterval.Changed:=False;
          Next;
        end;
    end;
  aCalendar.Free;
  aResource.Sort;
end;

function TfTaskPlan.GetIntervalFromCoordinates(Gantt: TgsGantt; X, Y,Index : Integer): TInterval;
var
  List: TList;
  aId : Variant;
  ay: Integer;
  i: Integer;
  aIdx : Integer = 0;
  function IsInRect(aX, aY: Integer; R: TRect): Boolean;
  begin
    Result := (aX >= R.Left) and (aX <= R.Right);
  end;
begin
  Result := nil;
  aId := Null;
  List := TList.Create;
  Gantt.MakeIntervalList(List);
  ay := Y-Gantt.Calendar.StartDrawIntervals;
  ay := ay div max(Gantt.Calendar.PixelsPerLine,1);
  ay := ay+(Gantt.Tree.TopRow-1);
  if (ay<List.Count) and (ay>-1) then
    begin
      if IsInRect(X,Y,TInterval(List[ay]).DrawRect) then
        aId := TInterval(List[ay]).Id;
      if Assigned(TInterval(List[ay]).Pointer) then
        begin
          for i := 0 to TRessource(TInterval(List[ay]).Pointer).IntervalCount-1 do
            if not TRessource(TInterval(List[ay]).Pointer).Interval[i].IsDrawRectClear then
              if IsInRect(X,Y,TRessource(TInterval(List[ay]).Pointer).Interval[i].DrawRect)
              and (not (TRessource(TInterval(List[ay]).Pointer).Interval[i] is TBackInterval))
              then
                begin
                  if aIdx = Index then
                    begin
                      Result := TRessource(TInterval(List[ay]).Pointer).Interval[i];
                      break;
                    end;
                  inc(aIdx);
                end;
        end;
    end;
  List.Free;
end;

function TfTaskPlan.GetTaskIntervalFromCoordinates(Gantt: TgsGantt; X, Y,
  Index: Integer): TInterval;
var
  List: TList;
  aId : Variant;
  ay: Integer;
  i: Integer;
  aIdx : Integer = 0;
  function IsInRect(aX, aY: Integer; R: TRect): Boolean;
  begin
    Result := (aX >= R.Left) and (aX <= R.Right);
  end;
begin
  Result := nil;
  aId := Null;
  List := TList.Create;
  Gantt.MakeIntervalList(List);
  ay := Y-Gantt.Calendar.StartDrawIntervals;
  ay := ay div max(Gantt.Calendar.PixelsPerLine,1);
  ay := ay+(Gantt.Tree.TopRow-1);
  if (ay<List.Count) and (ay>-1) then
    begin
      if IsInRect(X,Y,TInterval(List[ay]).DrawRect) then
        Result := TInterval(List[ay]);
    end;
  List.Free;
end;

end.

