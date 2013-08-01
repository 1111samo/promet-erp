{*******************************************************************************
Dieser Sourcecode darf nicht ohne gültige Geheimhaltungsvereinbarung benutzt werden
und ohne gültigen Vertriebspartnervertrag weitergegeben oder kommerziell verwertet werden.
You have no permission to use this Source without valid NDA
and copy it without valid distribution partner agreement
Christian Ulrich
info@cu-tec.de
Created 01.06.2006
*******************************************************************************}
unit uProcessOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, DBGrids, ExtCtrls, StdCtrls,
  DbCtrls, uOptionsFrame, db;

type

  { TfProcessOptions }

  TfProcessOptions = class(TOptionsFrame)
    Clients: TDatasource;
    DBGrid1: TDBGrid;
    DBMemo1: TDBMemo;
    DBNavigator1: TDBNavigator;
    DBNavigator2: TDBNavigator;
    gProcesses1: TDBGrid;
    lProcesses1: TLabel;
    Panel1: TPanel;
    ProcessParameters: TDatasource;
    Label1: TLabel;
    lProcesses: TLabel;
    Processes: TDatasource;
    gProcesses: TDBGrid;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
  private
    { private declarations }
  public
    { public declarations }
    procedure StartTransaction;override;
    procedure CommitTransaction;override;
    procedure RollbackTransaction;override;
  end;

implementation

uses uData, uBaseDbInterface;
{$R *.lfm}
procedure TfProcessOptions.StartTransaction;
begin
  inherited StartTransaction;
  Clients.DataSet := Data.ProcessClient.DataSet;
  Processes.DataSet := Data.ProcessClient.Processes.DataSet;
  Data.ProcessClient.Open;
  Data.ProcessClient.Processes.Open;
  ProcessParameters.DataSet := Data.ProcessClient.Processes.Parameters.DataSet;
  Data.ProcessClient.Processes.Parameters.DataSet.Open;
end;
procedure TfProcessOptions.CommitTransaction;
begin
  if (Processes.State = dsEdit) or (Processes.State = dsInsert) then
    Processes.DataSet.Post;
  inherited CommitTransaction;
end;
procedure TfProcessOptions.RollbackTransaction;
begin
  if (Processes.State = dsEdit) or (Processes.State = dsInsert) then
    Processes.DataSet.Cancel;
  inherited RollbackTransaction;
end;

end.
