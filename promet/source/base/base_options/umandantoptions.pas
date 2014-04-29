unit uMandantOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, ExtCtrls, StdCtrls, DbCtrls,
  Dialogs, Buttons, ExtDlgs, db, uOptionsFrame, uBaseDBClasses,uBaseDBInterface;

type

  { TfMandantOptions }

  TfMandantOptions = class(TOptionsFrame)
    bExportConfiguration: TButton;
    bTreeEntrys: TButton;
    iImage: TDBImage;
    eAccount: TDBEdit;
    eFax: TDBEdit;
    eInstitute: TDBEdit;
    eInternet: TDBEdit;
    eMail: TDBEdit;
    eName: TDBEdit;
    eSortcode: TDBEdit;
    eTel1: TDBEdit;
    eTel2: TDBEdit;
    eTel3: TDBEdit;
    eTel4: TDBEdit;
    iPreview: TDBImage;
    Label1: TLabel;
    lAccount: TLabel;
    lAdress: TLabel;
    lFax: TLabel;
    lInstitute: TLabel;
    lInternet: TLabel;
    lMail: TLabel;
    lMandantDetails: TLabel;
    lName: TLabel;
    lSortCode: TLabel;
    lTel1: TLabel;
    lTel2: TLabel;
    lTel3: TLabel;
    lTel4: TLabel;
    mAdress: TDBMemo;
    MandantDetailDS: TDatasource;
    OpenPictureDialog: TOpenPictureDialog;
    Panel1: TPanel;
    pMandantDetails: TPanel;
    sbAddImage: TSpeedButton;
    SelectDirectoryDialog: TSelectDirectoryDialog;
    procedure bExportConfigurationClick(Sender: TObject);
    procedure bTreeEntrysClick(Sender: TObject);
    procedure sbAddImageClick(Sender: TObject);
  private
    { private declarations }
    aConnection: TComponent;
    aMandant: TMandantDetails;
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
uses uData,uImpCSV,uOrder;

procedure TfMandantOptions.bExportConfigurationClick(Sender: TObject);
var
  OutputDir: String;
  aOrder: TOrder;
begin
  if SelectDirectoryDialog.Execute then
    begin
      OutputDir := SelectDirectoryDialog.FileName;
      ForceDirectoriesUTF8(OutputDir);
      CSVExport(OutputDir+DirectorySeparator+'countries.csv',';',Data.Countries.DataSet);
      CSVExport(OutputDir+DirectorySeparator+'currency.csv',';',Data.Currency.DataSet);
      CSVExport(OutputDir+DirectorySeparator+'dispatchtypes.csv',';',Data.Dispatchtypes.DataSet);
      CSVExport(OutputDir+DirectorySeparator+'filters.csv',';',Data.Filters.DataSet);
      CSVExport(OutputDir+DirectorySeparator+'forms.csv',';',Data.Forms.DataSet);
      CSVExport(OutputDir+DirectorySeparator+'languages.csv',';',Data.Languages.DataSet);
      CSVExport(OutputDir+DirectorySeparator+'numbers.csv',';',Data.Numbers.DataSet);
      CSVExport(OutputDir+DirectorySeparator+'orderpostyp.csv',';',Data.orderPosTyp.DataSet);
      aOrder := TOrder.Create(Self,Data);
      aOrder.Select(0);
      aOrder.Open;
      aOrder.OrderType.Open;
      CSVExport(OutputDir+DirectorySeparator+'ordertype.csv',';',aOrder.OrderType.DataSet);
      aOrder.Free;
      CSVExport(OutputDir+DirectorySeparator+'paymenttargets.csv',';',Data.PaymentTargets.DataSet);
      CSVExport(OutputDir+DirectorySeparator+'numbers.csv',';',Data.Numbers.DataSet);
      CSVExport(OutputDir+DirectorySeparator+'pricetypes.csv',';',Data.Pricetypes.DataSet);
      CSVExport(OutputDir+DirectorySeparator+'reports.csv',';',Data.Reports.DataSet);
      try
        CSVExport(OutputDir+DirectorySeparator+'templates.csv',';',Data.Templates.DataSet);
      except
      end;
      CSVExport(OutputDir+DirectorySeparator+'texttyp.csv',';',Data.Texttyp.DataSet);
      try
        CSVExport(OutputDir+DirectorySeparator+'userfielddefs.csv',';',Data.Userfielddefs.DataSet);
      except
      end;
      CSVExport(OutputDir+DirectorySeparator+'vat.csv',';',Data.Vat.DataSet);
      try
        CSVExport(OutputDir+DirectorySeparator+'statistic.csv',';',Data.Statistic.DataSet);
      except
      end;
      CSVExport(OutputDir+DirectorySeparator+'states.csv',';',Data.States.DataSet);
      CSVExport(OutputDir+DirectorySeparator+'units.csv',';',Data.Units.DataSet);
      CSVExport(OutputDir+DirectorySeparator+'storagetype.csv',';',Data.StorageType.DataSet);
    end;
end;

procedure TfMandantOptions.bTreeEntrysClick(Sender: TObject);
var
  aTree: TTree;
begin
  aTree := TTree.Create(nil,Data);
  with aTree.DataSet as IBaseDBFilter do
    begin
      UsePermissions:=False;
    end;
  aTree.Open;
  aTree.ImportStandartEntrys;
  aTree.Free;
end;

procedure TfMandantOptions.sbAddImageClick(Sender: TObject);
begin
  if OpenpictureDialog.Execute then
    begin
      if not aMandant.CanEdit then
        MandantDetailDS.DataSet.Edit;
      iPreview.Picture.LoadFromFile(OpenPictureDialog.FileName);
    end;
end;

constructor TfMandantOptions.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  aConnection := Data.GetNewConnection;
  aMandant := TMandantDetails.Create(Self,Data,aConnection);
  MandantDetailDS.DataSet := aMandant.DataSet;
end;

destructor TfMandantOptions.Destroy;
begin
  aMandant.Destroy;
  aConnection.Destroy;
  inherited Destroy;
end;

procedure TfMandantOptions.StartTransaction;
begin
  inherited StartTransaction;
  Data.StartTransaction(aConnection);
  aMandant.CreateTable;
  aMandant.Open;
end;

procedure TfMandantOptions.CommitTransaction;
begin
  if aMandant.CanEdit then aMandant.DataSet.Post;
  Data.CommitTransaction(aConnection);
  inherited CommitTransaction;
end;

procedure TfMandantOptions.RollbackTransaction;
begin
  Data.RollbackTransaction(aConnection);
  inherited RollbackTransaction;
end;

end.

