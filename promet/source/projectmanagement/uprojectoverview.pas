unit uprojectoverview;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, ComCtrls, uprometframesinplace,
  uMainTreeFrame,uIntfStrConsts,uProjects,uBaseDBInterface,uBaseDbClasses;

type
  TfProjectOverviewFrame = class(TPrometInplaceFrame)
    procedure FrameEnter(Sender: TObject);
    function FTreeOpen(aEntry: TTreeEntry): Boolean;
  private
    FProject: TProject;
    { private declarations }
    FTree : TfMainTree;
    procedure SetProject(AValue: TProject);
  public
    { public declarations }
    property ParentProject : TProject read FProject write SetProject;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

implementation
{$R *.lfm}
uses uData;
procedure TfProjectOverviewFrame.FrameEnter(Sender: TObject);
begin
end;

function TfProjectOverviewFrame.FTreeOpen(aEntry: TTreeEntry): Boolean;
var
  aDataSet: TBaseDBDataset;
begin
  case aEntry.Typ of
  etCustomer,etEmployee,etArticle,etProject,etProcess:
    begin
      aDataSet := aEntry.DataSourceType.Create(Self,Data);
      with aDataSet.DataSet as IBaseDBFilter do
        Filter := aEntry.Filter;
      aDataSet.Open;
      if aDataSet.Count > 0 then
        fMainTreeFrame.OpenLink(Data.BuildLink(aDataSet.DataSet),Self);
      aDataSet.Free;
    end;
  end;
end;

procedure TfProjectOverviewFrame.SetProject(AValue: TProject);
var
  Node1: TTreeNode;
begin
  if FProject=AValue then Exit;
  FProject:=AValue;
  FTree.tvMain.Items.Clear;
  with FTree do
    begin
      Node1 := tvMain.Items.AddChildObject(nil,'',TTreeEntry.Create);
      TTreeEntry(Node1.Data).Rec := Fproject.GetBookmark;
      with Fproject.DataSet as IBaseManageDB do
        TTreeEntry(Node1.Data).Filter:=Data.QuoteField(TableName)+'.'+Data.QuoteField('SQL_ID')+'='+Data.QuoteValue(IntToStr(Fproject.GetBookmark));
      TTreeEntry(Node1.Data).DataSourceType := TBaseDBDataSetClass(Fproject.ClassType);
      TTreeEntry(Node1.Data).Text[0] := Fproject.Text.AsString+' ('+fPROJECT.Number.AsString+')';
      TTreeEntry(Node1.Data).Typ := etProject;
      Node1.HasChildren:=True;
      Node1.Expanded:=True;
    end;
end;

constructor TfProjectOverviewFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTree :=TfMainTree.Create(Self);
  Ftree.Parent := Self;
  FTree.Align := alClient;
  FTree.OnOpen:=@FTreeOpen;
  Caption:=strOverview;
end;

destructor TfProjectOverviewFrame.Destroy;
begin
  FTree.Free;
  inherited Destroy;
end;

end.

