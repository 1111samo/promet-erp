{*******************************************************************************
Dieser Sourcecode darf nicht ohne gültige Geheimhaltungsvereinbarung benutzt werden
und ohne gültigen Vertriebspartnervertrag weitergegeben werden.
You have no permission to use this Source without valid NDA
and copy it without valid distribution partner agreement
Christian Ulrich
info@cu-tec.de
Created 03.12.2011
*******************************************************************************}
unit utreeview;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, DBGrids,
  ExtCtrls, Buttons, ComCtrls, uExtControls, db, Grids, ActnList,
  Menus, uBaseDBClasses, uBaseDbInterface;
type
  TDBTreeEntry = class
  public
    Rec : LargeInt;
    Data : TStrings;
    constructor Create(aBM : LargeInt);
    destructor Destroy;override;
  end;
  TfTreeView = class(TFrame)
    acCopyLink: TAction;
    acFilter: TAction;
    acOpen: TAction;
    ActionList: TActionList;
    ActionList1: TActionList;
    Datasource: TDatasource;
    DblClickTimer: TIdleTimer;
    FilterImage: TImage;
    gHeader: TExtStringgrid;
    dgFake: TExtDBGrid;
    ImageList1: TImageList;
    MenuItem1: TMenuItem;
    miExport: TMenuItem;
    miImport: TMenuItem;
    miOpen: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    bEditRows: TSpeedButton;
    pmAction: TPopupMenu;
    pmPopup: TPopupMenu;
    sbGrids: TPanel;
    SpeedButton2: TSpeedButton;
    ToolBar: TToolBar;
    tvPositions: TTreeView;
    procedure bEditRowsClick(Sender: TObject);
    procedure DatasetAfterScroll(aDataSet: TDataSet);
    procedure gHeaderColRowMoved(Sender: TObject; IsColumn: Boolean; sIndex,
      tIndex: Integer);
    procedure gHeaderHeaderSized(Sender: TObject; IsColumn: Boolean;
      Index: Integer);
    procedure tvPositionsDeletion(Sender: TObject; Node: TTreeNode);
  private
    { private declarations }
    FAutoFilter : string;
    FBaseName: string;
    FSortDirection: TSortDirection;
    FSortField: string;
    FDataSet : TBaseDBDataSet;
    procedure SetDataSet(const AValue: TBaseDBDataSet);
    procedure SetSortDirecion(AValue: TSortDirection);
    procedure SetSortField(AValue: string);
    procedure UpdateTitle;
    procedure SetupPosControls;
  public
    { public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property  BaseName : string read FBaseName write FBaseName;
    procedure SyncActiveRow(aParent : TTreeNode;Bookmark : LargeInt;DoInsert,UpdateData : Boolean);
    procedure SyncDataSource;
    property SortDirection : TSortDirection read FSortDirection write SetSortDirecion;
    property SortField : string read FSortField write SetSortField;
    procedure ClearFilters;
    property DataSet : TBaseDBDataSet read FDataSet write SetDataSet;
  end;
implementation
uses uRowEditor,ubasevisualapplicationtools;
constructor TDBTreeEntry.Create(aBM : LargeInt);
begin
  Data := TStringList.Create;
  Rec := aBM;
end;
destructor TDBTreeEntry.Destroy;
begin
  Data.Free;
  inherited Destroy;
end;
procedure TfTreeView.gHeaderColRowMoved(Sender: TObject; IsColumn: Boolean;
  sIndex, tIndex: Integer);
begin
  if IsColumn then
    begin
      dgFake.Columns[sIndex-1].Index:=tIndex-1;
      fRowEditor.SetGridSizes(FBaseName,dgFake.DataSource,dgFake);
    end;
end;
procedure TfTreeView.bEditRowsClick(Sender: TObject);
begin
  fRowEditor.Execute(FBaseName,dgFake.DataSource,dgFake);
  gHeader.Columns.Assign(dgFake.Columns);
  Self.ClearFilters;
  gHeaderHeaderSized(nil,True,1);
  UpdateTitle;
end;
procedure TfTreeView.DatasetAfterScroll(aDataSet: TDataSet);
begin

end;
procedure TfTreeView.gHeaderHeaderSized(Sender: TObject; IsColumn: Boolean;
  Index: Integer);
var
  aWidth: Integer;
  i: Integer;
begin
  if not IsColumn then exit;
  if dgFake.Columns.Count > Index-1 then
    dgFake.Columns[Index-1].Width:=gHeader.Columns[Index-1].Width;
  for i := 0 to gHeader.Columns.Count-1 do
    gHeader.Columns[i].ReadOnly:=false;
  if Assigned(Sender) then
    fRowEditor.SetGridSizes(FBaseName,dgFake.DataSource,dgFake);
end;
procedure TfTreeView.tvPositionsDeletion(Sender: TObject; Node: TTreeNode);
begin
  if Assigned(Node.Data) then
    TDBTreeEntry(Node.Data).Free;
end;
procedure TfTreeView.SetDataSet(const AValue: TBaseDBDataSet);
begin
  try
    if Assigned(FDataSet) and Assigned(FDataSet.DataSet) then
      FDataSet.DataSet.AfterScroll:=nil;
  except
  end;
  FDataSet := AValue;
  if not Assigned(fDataSet) then exit;
  with FDataSet.DataSet as IBaseDbFilter do
    begin
    end;
  Datasource.DataSet := FDataset.DataSet;
  DataSet.DataSet.AfterScroll:=@DatasetAfterScroll;
  fRowEditor.GetGridSizes(FBaseName,DataSource,dgFake,'');
  gHeader.Columns.Assign(dgFake.Columns);
  SyncDataSource;
  UpdateTitle;
end;
procedure TfTreeView.SetSortDirecion(AValue: TSortDirection);
begin
  if FSortDirection=AValue then Exit;
  FSortDirection:=AValue;
end;
procedure TfTreeView.SetSortField(AValue: string);
begin
  if FSortField=AValue then Exit;
  FSortField:=AValue;
end;
procedure TfTreeView.UpdateTitle;
var
  i: Integer;
  tmp: string;
begin
  for i := 0 to dgFake.Columns.Count-1 do
    begin
      gHeader.Columns[i].ButtonStyle:=cbsAuto;
      if SortField = TColumn(dgFake.Columns[i]).FieldName then
        begin
          if SortDirection = sdAscending then
            begin
              dgFake.Columns[i].Title.ImageIndex := 0;
              gHeader.Columns[i].Title.ImageIndex := 0;
            end
          else if SortDirection = sdDescending then
            begin
              dgFake.Columns[i].Title.ImageIndex := 1;
              gHeader.Columns[i].Title.ImageIndex := 1;
            end
          else
            begin
              dgFake.Columns[i].Title.ImageIndex := -1;
              gHeader.Columns[i].Title.ImageIndex := -1;
            end;
        end
      else
        begin
          dgFake.Columns[i].Title.ImageIndex := -1;
          gHeader.Columns[i].Title.ImageIndex := -1;
        end;
    end;
  gHeaderHeaderSized(nil,True,1);
end;
procedure TfTreeView.SetupPosControls;
begin
end;
constructor TfTreeView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;
destructor TfTreeView.Destroy;
begin
  inherited Destroy;
end;
procedure TfTreeView.SyncActiveRow(aParent : TTreeNode;Bookmark: LargeInt; DoInsert,
  UpdateData: Boolean);
var
  aNode : TTreeNode;
begin
  aNode := tvPositions.Selected;
  if (not Assigned(aNode)) or (TDBTreeEntry(aNode.Data).Rec <> Bookmark) then
    begin
      if DoInsert then
        begin
          aNode := tvPositions.Items.AddChildObject(aParent,IntToStr(Bookmark),TDBTreeEntry.Create(Bookmark));
          UpdateData := True;
        end
      else if Assigned(aNode) then
        TDBTreeEntry(aNode.Data).Rec := Bookmark;
    end;
  if UpdateData then
    begin

    end;
end;
procedure TfTreeView.SyncDataSource;
var
  Bm: Int64;
  CanSelect: Boolean;
begin
  if (not Assigned(DataSource.DataSet))
  or (not DataSource.DataSet.Active) then exit;
  fRowEditor.GetGridSizes(FBaseName,dgFake.DataSource,dgFake,'',False,FBaseName);
  SetupPosControls;
  Self.Visible:=False;
  tvPositions.BeginUpdate;
  with DataSource.DataSet do
    begin
      DisableControls;
      tvPositions.Items.Clear;
      First;
      while not EOF do
        begin
          Bm := DataSet.GetBookmark;
          SyncActiveRow(nil,Bm,True,True);
          Next;
        end;
      EnableControls;
    end;
  tvPositions.EndUpdate;
  Self.Visible:=True;
end;
procedure TfTreeView.ClearFilters;
var
  a: Integer;
begin
  for a := 0 to dgFake.Columns.Count-1 do
    begin
      gHeader.Cells[a+1,1] := '';
    end;
  FAutoFilter := BuildAutofilter(dgFake,gHeader);
  acFilter.Execute;
end;
initialization
  {$I utreeview.lrs}
end.

