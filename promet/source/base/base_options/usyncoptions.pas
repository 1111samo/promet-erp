unit uSyncOptions;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, FileUtil, Forms, Controls, DBGrids, StdCtrls, DbCtrls,
  Buttons, SynMemo, SynHighlighterSQL, uOptionsFrame, db, uBaseDbClasses, uSync;
type

  { TfSyncOptions }

  TfSyncOptions = class(TOptionsFrame)
    DBMemo1: TDBMemo;
    DBNavigator1: TDBNavigator;
    dsTables: TDatasource;
    dsDatabases: TDatasource;
    dgDatabases: TDBGrid;
    dgTables: TDBGrid;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    lD: TLabel;
    smIn: TSynMemo;
    smOut: TSynMemo;
    SpeedButton1: TSpeedButton;
    SynSQLSyn1: TSynSQLSyn;
    procedure aSyncDbTablesDataSetAfterScroll(DataSet: TDataSet);
    procedure smInChange(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    { private declarations }
    aConnection: TComponent;
    aSyncDb: TSyncDB;
  public
    { public declarations }
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy;override;
    procedure StartTransaction;override;
    procedure CommitTransaction;override;
    procedure RollbackTransaction;override;
  end;
implementation
{$R *.lfm}
uses uData;
procedure TfSyncOptions.aSyncDbTablesDataSetAfterScroll(DataSet: TDataSet);
begin
  smIn.Lines.Text := dsTables.DataSet.FieldByName('FILTERIN').AsString;
  smOut.Lines.Text := dsTables.DataSet.FieldByName('FILTEROUT').AsString;
end;
procedure TfSyncOptions.smInChange(Sender: TObject);
begin
  if not aSyncDB.Tables.CanEdit then
    aSyncDB.Tables.DataSet.Edit;
  dsTables.DataSet.FieldByName('FILTERIN').AsString := smIn.Lines.Text;
  dsTables.DataSet.FieldByName('FILTEROUT').AsString := smOut.Lines.Text;
end;

procedure TfSyncOptions.SpeedButton1Click(Sender: TObject);
  procedure AddTable(aName : string;Active : Boolean = True;ActiveOut : Boolean = True);
  begin
    with dsTables.DataSet do
      begin
        Append;
        FieldByName('NAME').AsString := aName;
        if Active then
          FieldByName('ACTIVE').AsString := 'Y'
        else
          FieldByName('ACTIVE').AsString := 'N';
        if ActiveOut then
          FieldByName('ACTIVEOUT').AsString := 'Y'
        else
          FieldByName('ACTIVEOUT').AsString := 'N';
      end;
  end;
begin
  AddTable('USERS');
  AddTable('MANDANTDETAILS');
  AddTable('RIGHTS');
  AddTable('NUMBERS',False,False);
  AddTable('LANGUAGES');
  AddTable('TREE');
  AddTable('REPORTS');
  AddTable('DOCUMENTS');
  AddTable('TEMPLATES');
  AddTable('FILTERS');
  AddTable('PROJECTS');
  AddTable('LINKS');
  AddTable('FORMS');
  AddTable('USERFIELDDEFS');
  AddTable('OPTIONS');
  AddTable('PRICETYPES');
  AddTable('CURRENCY');
  AddTable('TASKS');
  AddTable('WIKI');
  AddTable('MESSAGEIDX');
  AddTable('MESSAGES');
  AddTable('CONVERSATIONITEMS');
  AddTable('CALENDAR');
  AddTable('TIMES');
  AddTable('CALLS');
  AddTable('CUSTOMERS');
  AddTable('CUSTOMERBANKING');
  AddTable('CUSTOMERCONT');
  AddTable('IMAGES');
  AddTable('ADDRESSES');
  AddTable('EMPLOYEES');
  AddTable('MASTERDATA');
  AddTable('TEXTS');
  AddTable('TEXTTYP');
  AddTable('PROPERTIES');
  AddTable('HISTORY');
  AddTable('VAT');
  AddTable('SUPPLIER');
  AddTable('SUPPLIERPRICES');
  AddTable('MDQUANTITIES');
  AddTable('MDPRICES');
  AddTable('MDPOSITIONS');
  AddTable('STORAGETYPE');
  AddTable('STORAGE');
  AddTable('SERIALS');
  AddTable('STORAGEJOURNAL');
  AddTable('ORDERTYPE');
  AddTable('ORDERS');
  AddTable('ORDERADDR');
  AddTable('ORDERPOSTYP');
  AddTable('ORDERPOS');
  AddTable('ORDERPOSCALC');
  AddTable('ORDERREPAIR');
  AddTable('ORDERREPAIRDETAIL');
  AddTable('QMTEST');
  AddTable('QMTESTDETAIL');
  AddTable('REPAIRPROBLEMS');
  AddTable('REPAIRASSEMBLY');
  AddTable('REPAIRPARTS');
  AddTable('ORDERQMTEST');
  AddTable('ORDERQMTESTDETAIL');
  AddTable('ACCOUNTS');
  AddTable('ACCOUNTEXCHANGE');
  AddTable('ACCOUNTINGJOURNAL');
  AddTable('PAYMENTTARGETS');
  AddTable('COUNTRYS');
  AddTable('CITIES');
  AddTable('DISPATCHTYPES');
  AddTable('INVENTORY');
  AddTable('INVENTORYPOS');
  AddTable('PREFIXES');
  AddTable('STATISTICS');
  AddTable('STATES');
  AddTable('PERMISSIONS');
  AddTable('UNITS');
  AddTable('LISTS');
  AddTable('LISTENTRYS');
  AddTable('DELETEDITEMS');
end;

constructor TfSyncOptions.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  aConnection := Data.GetNewConnection;
  aSyncDb := TSyncDB.Create(Self,Data,aConnection);
  dsDatabases.DataSet := aSyncDB.DataSet;
  dsTables.DataSet := aSyncDB.Tables.DataSet;
  aSyncDB.Tables.DataSet.AfterScroll:=@aSyncDbTablesDataSetAfterScroll;
end;
destructor TfSyncOptions.Destroy;
begin
  aSyncDB.Destroy;
  try
    aConnection.Destroy;
  except
  end;
  inherited Destroy;
end;
procedure TfSyncOptions.StartTransaction;
begin
  inherited StartTransaction;
  Data.StartTransaction(aConnection);
  aSyncDB.CreateTable;
  aSyncDb.Open;
  aSyncDB.Tables.Open;
end;
procedure TfSyncOptions.CommitTransaction;
begin
  Data.CommitTransaction(aConnection);
  inherited CommitTransaction;
end;
procedure TfSyncOptions.RollbackTransaction;
begin
  Data.RollbackTransaction(aConnection);
  inherited RollbackTransaction;
end;
end.
