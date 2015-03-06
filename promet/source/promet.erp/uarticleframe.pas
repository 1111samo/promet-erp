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
unit uArticleFrame;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, FileUtil, LR_DBSet, LR_Class, Forms, Controls, ExtCtrls,
  ActnList, ComCtrls, StdCtrls, DbCtrls, Buttons, Menus, db, uPrometFrames,
  uExtControls, uFilterFrame, uIntfStrConsts, Utils, Dialogs, variants,
  uMeasurement;
type

  { TfArticleFrame }

  TfArticleFrame = class(TPrometMainFrame)
    acCancel: TAction;
    acSave: TAction;
    acSetTreeDir: TAction;
    acShowTreeDir: TAction;
    acClose: TAction;
    acStartTimeRegistering: TAction;
    acCopy: TAction;
    acPaste: TAction;
    acDelete: TAction;
    acRights: TAction;
    acPrint: TAction;
    acPasteImage: TAction;
    acAddImage: TAction;
    acScreenshot: TAction;
    acNew: TAction;
    ActionList1: TActionList;
    bAssignTree: TSpeedButton;
    bChangeNumber: TSpeedButton;
    Bevel3: TBevel;
    Bevel4: TBevel;
    Bevel5: TBevel;
    Bevel6: TBevel;
    Bevel7: TBevel;
    bExecute: TSpeedButton;
    bShowTree: TSpeedButton;
    cbActive: TDBCheckBox;
    cbLanguage: TComboBox;
    cbNoStorage: TDBCheckBox;
    cbNoStorage1: TDBCheckBox;
    cbOwnProduction: TDBCheckBox;
    cbQuantityUnit: TDBComboBox;
    cbSaleItem: TDBCheckBox;
    cbStatus: TComboBox;
    cbUseSerial: TDBCheckBox;
    cbVAT: TExtDBCombobox;
    cbCategory: TExtDBCombobox;
    cbVersion: TComboBox;
    cbWarrenty: TDBComboBox;
    DBCheckBox4: TDBCheckBox;
    eArticleNumber: TDBEdit;
    eBarcode: TDBEdit;
    eManufacturerNR: TDBEdit;
    eMatchCode: TDBEdit;
    eRepairTime: TDBEdit;
    eUnit: TDBEdit;
    eWeight: TExtDBEdit;
    gbTree: TGroupBox;
    History: TDatasource;
    iArticle: TImage;
    Image3: TImage;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    lBarcode: TLabel;
    lLanguage: TLabel;
    lManufacturerNr: TLabel;
    lMatchCode: TLabel;
    lQuantityUnit: TLabel;
    lRepairtime: TLabel;
    lShortText: TLabel;
    lUnit: TLabel;
    lVAT: TLabel;
    lVAT1: TLabel;
    lWarrenty: TLabel;
    lWeight: TLabel;
    MandantDetails: TDatasource;
    Masterdata: TDatasource;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    miCopy: TMenuItem;
    miDelete: TMenuItem;
    miPaste: TMenuItem;
    miStartTimeregistering: TMenuItem;
    mShortText: TDBMemo;
    Panel4: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    pCommon: TPanel;
    pComponents: TPanel;
    pcPages: TExtMenuPageControl;
    PHistory: TfrDBDataSet;
    PList: TfrDBDataSet;
    pmAction: TPopupMenu;
    pNav1: TPanel;
    pmImage: TPopupMenu;
    pPreviewImage: TPanel;
    Report: TfrReport;
    sbAddImage: TSpeedButton;
    sbClipboardToImage: TSpeedButton;
    sbClipboardToImage1: TSpeedButton;
    sbMenue: TSpeedButton;
    ToolBar1: TPanel;
    ToolButton1: TSpeedButton;
    ToolButton2: TSpeedButton;
    tsCommon: TTabSheet;
    procedure acCancelExecute(Sender: TObject);
    procedure acCloseExecute(Sender: TObject);
    procedure acDeleteExecute(Sender: TObject);
    procedure acPasteImageExecute(Sender: TObject);
    procedure acPrintExecute(Sender: TObject);
    procedure acRightsExecute(Sender: TObject);
    procedure acSaveExecute(Sender: TObject);
    procedure acScreenshotExecute(Sender: TObject);
    procedure acSetTreeDirExecute(Sender: TObject);
    procedure bChangeNumberClick(Sender: TObject);
    procedure cbNoStorageChange(Sender: TObject);
    procedure cbStatusSelect(Sender: TObject);
    procedure cbVersionExit(Sender: TObject);
    procedure cbVersionSelect(Sender: TObject);
    procedure FrameEnter(Sender: TObject);
    procedure FrameExit(Sender: TObject);
    procedure MasterdataStateChange(Sender: TObject);
    procedure mShortTextChange(Sender: TObject);
    procedure mShortTextExit(Sender: TObject);
    procedure sbMenueClick(Sender: TObject);
  private
    { private declarations }
    FEditable : Boolean;
    FMeasurement: TMeasurement;
    procedure AddMeasurement(Sender: TObject);
    procedure AddDocuments(Sender: TObject);
    procedure AddHistory(Sender: TObject);
    procedure AddImages(Sender: TObject);
    procedure AddLinks(Sender: TObject);
    procedure AddPositions(Sender: TObject);
    procedure AddList(Sender: TObject);
    procedure AddStorage(Sender: TObject);
    procedure AddSupplier(Sender: TObject);
    procedure AddRepair(Sender: TObject);
    procedure AddTexts(Sender: TObject);
    procedure AddFinance(Sender: TObject);
  protected
    procedure DoOpen(RefreshVersions : Boolean = True);
    function SetRights : Boolean;
  public
    { public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy;override;
    function CanHandleLink(aLink : string) : Boolean;override;
    function OpenFromLink(aLink : string) : Boolean;override;
    procedure ListFrameAdded(aFrame: TObject); override;
    procedure New;override;
    procedure SetLanguage;override;
  end;
implementation
{$R *.lfm}
uses uMasterdata,uData,uArticlePositionFrame,uDocuments,uDocumentFrame,
  uHistoryFrame,uImageFrame,uLinkFrame,uBaseDbInterface,uListFrame,
  uArticleStorageFrame,uArticleRepairFrame,uArticleText,uCopyArticleData,
  uMainTreeFrame,uPrometFramesInplace,uBaseDBClasses,uarticlesupplierframe,
  uNRights,uSelectReport,uBaseVisualApplication,uWikiFrame,uWiki,ufinance,
  uthumbnails,Clipbrd,uscreenshotmain,uBaseApplication,uBaseERPDBClasses,
  umeasurements;
resourcestring
  strPrices                                  = 'Preise';
  strProperties                              = 'Eigenschaften';
  strStorage                                 = 'Lager';
  strSupplier                                = 'Lieferant';
  strRepair                                  = 'Reparatur';
  strTexts                                   = 'Texte';
  strChangeNumer                             = 'Nummer ändern';
  strNewArticle                              = 'neuer Artikel';
procedure TfArticleFrame.acSaveExecute(Sender: TObject);
begin
  if Assigned(FConnection) then
    begin
      FDataSet.CascadicPost;
      if UseTransactions then
        begin
          Data.CommitTransaction(FConnection);
          Data.StartTransaction(FConnection);
        end;
    end;
end;
procedure TfArticleFrame.acScreenshotExecute(Sender: TObject);
var
  aSheet: TTabSheet;
  aThumbnails: TThumbnails;
  aStream: TMemoryStream;
begin
  Application.ProcessMessages;
  Application.MainForm.Hide;
  Application.ProcessMessages;
  Application.CreateForm(TfScreenshot,fScreenshot);
  with BaseApplication as IBaseApplication do
    fScreenshot.SaveTo:=AppendPathDelim(GetInternalTempDir)+'screenshot.jpg';
  fScreenshot.Show;
  while fScreenshot.Visible do Application.ProcessMessages;
  fScreenshot.Destroy;
  fScreenshot := nil;
  if DataSet.State=dsInsert then
    begin
      DataSet.Post;
      DataSet.Edit;
    end;
  pcPages.AddTab(TfImageFrame.Create(Self),False);
  aSheet := pcPages.GetTab(TfImageFrame);
  if Assigned(aSheet) then
    begin
      Application.ProcessMessages;
      with TfImageFrame(aSheet.Controls[0]) do
        begin
          if not DataSet.CanEdit then
            DataSet.Insert;
          with BaseApplication as IBaseApplication do
            iPreview.Picture.LoadFromFile(AppendPathDelim(GetInternalTempDir)+'screenshot.jpg');
          DataSet.Post;
        end;
      aThumbnails := TThumbnails.Create(nil);
      aThumbnails.SelectByRefId(DataSet.Id.AsVariant);
      aThumbnails.Open;
      while aThumbnails.Count>0 do
        aThumbnails.Delete;
      TMasterdata(DataSet).GenerateThumbnail;
      aThumbnails.SelectByRefId(DataSet.Id.AsVariant);
      aThumbnails.Open;
      if aThumbnails.Count>0 then
        begin
          aStream := TMemoryStream.Create;
          Data.BlobFieldToStream(aThumbnails.DataSet,'THUMBNAIL',aStream);
          aStream.Position:=0;
          iArticle.Picture.LoadFromStreamWithFileExt(aStream,'jpg');
          aStream.Free;
          acPasteImage.Visible:=False;
          acAddImage.Visible:=False;
          acScreenshot.Visible:=False;
        end
      else
        begin
          iArticle.Picture.Clear;
          acPasteImage.Visible:=True;
          acAddImage.Visible:=True;
          acScreenshot.Visible:=True;
        end;
      aThumbnails.Free;
    end;

  Application.MainForm.Show;
end;
procedure TfArticleFrame.acSetTreeDirExecute(Sender: TObject);
begin
  if fMainTreeFrame.GetTreeEntry = -1 then exit;
  with DataSet.DataSet do
    begin
      Edit;
      FieldbyName('TREEENTRY').AsVariant:=fMainTreeFrame.GetTreeEntry;
      fMainTreeFrame.tvMain.Selected.Collapse(true);
    end;
end;
procedure TfArticleFrame.bChangeNumberClick(Sender: TObject);
var
  str: String;
begin
  str := DataSet.FieldByName('ID').AsString;
  if InputQuery(strChangeNumer,strnewNumber,str) and (str <> DataSet.FieldByName('ID').AsString) then
    begin
      with DataSet.DataSet do
        begin
          Edit;
          FieldbyName('ID').AsString:=str;
        end;
    end;
end;

procedure TfArticleFrame.cbNoStorageChange(Sender: TObject);
begin
  cbNoStorage1.Enabled:=not cbNoStorage.Checked;
  cbUseSerial.Enabled:=not cbNoStorage.Checked;
end;

procedure TfArticleFrame.cbStatusSelect(Sender: TObject);
var
  tmp: String;
begin
  tmp := copy(cbStatus.text,pos('(',cbStatus.text)+1,length(cbStatus.text));
  tmp := copy(tmp,0,pos(')',tmp)-1);
  if not FDataSet.CanEdit then FDataSet.DataSet.Edit;
  FDataSet.FieldByName('STATUS').AsString:=tmp;
  acSave.Execute;
  DoOpen;
end;

procedure TfArticleFrame.cbVersionExit(Sender: TObject);
var
  TargetVer: String;
  Version : Variant;
begin
  Version := NULL;
  if cbVersion.Text <> '' then
    Version := cbVersion.Text;
  if Dataset.FieldByName('VERSION').AsVariant <> Version then
    begin //New Version
      if not fCopyArticleData.Execute(TMasterdata(DataSet),Version,DataSet.FieldByName('LANGUAGE').AsVariant) then
        cbVersion.Text := DataSet.FieldByName('VERSION').AsString
      else
        begin
          cbVersion.Items.Add(TargetVer);
          cbVersion.Text:=TargetVer;
          DoOpen;
          FDataSet.Change;
        end;
    end;
end;
procedure TfArticleFrame.cbVersionSelect(Sender: TObject);
var
  aId: String;
  aLanguage : Variant;
begin
  aId := TMasterdata(DataSet).Number.AsString;
  aLanguage := TMasterdata(DataSet).Language.AsVariant;
  CloseConnection;
  Screen.Cursor:=crHourglass;
  application.ProcessMessages;
  if UseTransactions then
    Data.StartTransaction(FConnection);
  TMasterdata(DataSet).Select(aId,cbVersion.Text,aLanguage);
  DataSet.DataSet.DisableControls;
  DataSet.Open;
  if DataSet.Count = 0 then
    begin
      TMasterdata(DataSet).Select(aId,cbVersion.Text,Null);
      DataSet.Open;
      if DataSet.Count = 0 then
        begin
          Screen.Cursor:=crDefault;
          acClose.Execute;
          exit;
        end;
    end;
  pcPages.CloseAll;
  DoOpen(False);
  DataSet.DataSet.EnableControls;
  Screen.Cursor:=crDefault;
end;

procedure TfArticleFrame.FrameEnter(Sender: TObject);
begin
  ActionList1.State:=asNormal;
end;
procedure TfArticleFrame.FrameExit(Sender: TObject);
begin
  ActionList1.State:=asSuspended;
end;
procedure TfArticleFrame.MasterdataStateChange(Sender: TObject);
begin
  acSave.Enabled := DataSet.CanEdit or DataSet.Changed;
  acCancel.Enabled:= DataSet.CanEdit or DataSet.Changed;
end;
procedure TfArticleFrame.mShortTextChange(Sender: TObject);
var
  tmp: AnsiString;
begin
  if mShortText.Lines.Count > 0 then
    TabCaption := mShortText.Lines[0];
  tmp := StringReplace(UpperCase(StringReplace(ValidateFileName(mShorttext.Text),'_','',[rfReplaceAll])),' ','',[rfReplaceAll]);
  tmp := StringReplace(tmp,'-','',[rfReplaceAll]);
  if (copy(tmp,0,length(eMatchCode.Text)) = eMatchCode.Text)
  or ((length(tmp) < length(eMatchCode.text)) and (copy(eMatchCode.Text,0,length(tmp)) = tmp)) then
    if Assigned(eMatchCode.Field) then
      begin
        tmp := copy(tmp,0,eMatchCode.Field.Size);
        eMatchCode.Text := tmp;
      end;
  acSave.Enabled := DataSet.CanEdit or DataSet.Changed;
  acCancel.Enabled:= DataSet.CanEdit or DataSet.Changed;
end;
procedure TfArticleFrame.mShortTextExit(Sender: TObject);
begin
  if pcPages.CanFocus then
    pcPages.SetFocus;
end;
procedure TfArticleFrame.sbMenueClick(Sender: TObject);
begin
  TSpeedButton(Sender).PopupMenu.PopUp(TSpeedButton(Sender).ClientOrigin.x,TSpeedButton(Sender).ClientOrigin.y+TSpeedButton(Sender).Height);
end;

procedure TfArticleFrame.AddMeasurement(Sender: TObject);
begin
  TfMeasurementFrame(Sender).DataSet := FMeasurement;
  TPrometInplaceFrame(Sender).SetRights(FEditable);
end;

procedure TfArticleFrame.AddDocuments(Sender: TObject);
var
  aDocuments: TDocuments;
begin
  if not Assigned(TfDocumentFrame(Sender).DataSet) then
    begin
      aDocuments := TDocuments.CreateEx(Self,Data);
      TfDocumentFrame(Sender).DataSet := aDocuments;
      TfDocumentFrame(Sender).Refresh(DataSet.Id.AsVariant,'M',DataSet.FieldByName('ID').AsString,DataSet.FieldByName('VERSION').AsVariant,DataSet.FieldByName('LANGUAGE').AsVariant);
    end;
  TfDocumentFrame(Sender).BaseElement := FDataSet;
  TPrometInplaceFrame(Sender).SetRights(FEditable);
end;
procedure TfArticleFrame.AddHistory(Sender: TObject);
begin
  TfHistoryFrame(Sender).BaseName:='MD';
  TfHistoryFrame(Sender).DataSet := TMasterdata(FDataSet).History;
  TPrometInplaceFrame(Sender).SetRights(FEditable);
end;
procedure TfArticleFrame.AddImages(Sender: TObject);
begin
  TfImageFrame(Sender).DataSet := TMasterdata(FDataSet).Images;
  TMasterdata(FDataSet).Images.Open;
  TPrometInplaceFrame(Sender).SetRights(FEditable);
end;
procedure TfArticleFrame.AddLinks(Sender: TObject);
begin
  TfLinkFrame(Sender).BaseName:='MD';
  TfLinkFrame(Sender).DataSet := TMasterdata(FDataSet).Links;
  TPrometInplaceFrame(Sender).SetRights(FEditable);
end;
procedure TfArticleFrame.acCancelExecute(Sender: TObject);
begin
  if Assigned(FConnection) then
    begin
      FDataSet.CascadicCancel;
      if UseTransactions then
        begin
          Data.RollbackTransaction(FConnection);
          Data.StartTransaction(FConnection);
        end;
    end;
end;
procedure TfArticleFrame.acCloseExecute(Sender: TObject);
begin
  CloseFrame;
end;
procedure TfArticleFrame.acDeleteExecute(Sender: TObject);
begin
  if MessageDlg(strRealdelete,mtInformation,[mbYes,mbNo],0) = mrYes then
    begin
      Screen.Cursor := crHourglass;
      Application.ProcessMessages;
      DataSet.Delete;
      FDataSet.CascadicCancel;
      if UseTransactions then
        begin
          Data.CommitTransaction(FConnection);
          Data.StartTransaction(FConnection);
        end;
      acClose.Execute;
      Screen.Cursor := crDefault;
    end;
end;

procedure TfArticleFrame.acPasteImageExecute(Sender: TObject);
var
  aSheet: TTabSheet;
  aThumbnails: TThumbnails;
  aStream: TMemoryStream;
begin
  if Clipboard.HasPictureFormat then
    begin
      pcPages.AddTab(TfImageFrame.Create(Self),False);
      aSheet := pcPages.GetTab(TfImageFrame);
      if Assigned(aSheet) then
        begin
          Application.ProcessMessages;
          TfImageFrame(aSheet.Controls[0]).acPaste.Execute;
          TfImageFrame(aSheet.Controls[0]).DataSet.Post;
          aThumbnails := TThumbnails.Create(nil);
          aThumbnails.SelectByRefId(DataSet.Id.AsVariant);
          aThumbnails.Open;
          while aThumbnails.Count>0 do
            aThumbnails.Delete;
          TMasterdata(DataSet).GenerateThumbnail;
          aThumbnails.SelectByRefId(DataSet.Id.AsVariant);
          aThumbnails.Open;
          if aThumbnails.Count>0 then
            begin
              aStream := TMemoryStream.Create;
              Data.BlobFieldToStream(aThumbnails.DataSet,'THUMBNAIL',aStream);
              aStream.Position:=0;
              iArticle.Picture.LoadFromStreamWithFileExt(aStream,'jpg');
              aStream.Free;
              acPasteImage.Visible:=False;
              acAddImage.Visible:=False;
              acScreenshot.Visible:=False;
            end
          else
            begin
              iArticle.Picture.Clear;
              acPasteImage.Visible:=True;
              acAddImage.Visible:=True;
              acScreenshot.Visible:=True;
            end;
          aThumbnails.Free;
        end;
    end;
end;

procedure TfArticleFrame.acPrintExecute(Sender: TObject);
var
  Hist : IBaseHistory;
begin
  fSelectReport.Report := Report;
  fSelectReport.SetLanguage;
  if Supports(FDataSet, IBaseHistory, Hist) then
    History.DataSet := Hist.GetHistory.DataSet;
  MandantDetails.DataSet:=Data.MandantDetails.DataSet;
  Data.MandantDetails.Open;
  PList.DataSet := DataSet.DataSet;
  with FDataSet.DataSet as IBaseManageDB do
    begin
      fSelectReport.ReportType := 'MAS';
    end;
  fSelectReport.Showmodal;
end;

procedure TfArticleFrame.acRightsExecute(Sender: TObject);
begin
  fNRights.Execute(DataSet.Id.AsVariant);
end;
procedure TfArticleFrame.DoOpen(RefreshVersions : Boolean = True);
var
  aDocuments: TDocuments;
  s: TStream;
  GraphExt: String;
  aDocFrame: TfDocumentFrame;
  Rec: LargeInt;
  aFilter: String;
  aType: Char;
  tmp: String;
  aFound: Boolean;
  aWiki: TWikiList;
  aWikiPage: TfWikiFrame;
  aWikiIdx: Integer;
  aID: String;
  aThumbnails: TThumbnails;
  aStream: TMemoryStream;
begin
  pcPages.CloseAll;
  TMasterdata(DataSet).OpenItem;
  TabCaption := TMasterdata(FDataSet).Text.AsString;
  Masterdata.DataSet := DataSet.DataSet;
  SetRights;
  if Masterdata.DataSet.State <> dsInsert then
    begin
      if Refreshversions then
        begin
          Rec := DataSet.GetBookmark;
          Masterdata.DataSet.DisableControls;
          with DataSet.DataSet as IBaseDbFilter do
            begin
              aFilter := Filter;
              Filter := Data.QuoteField('ID')+'='+Data.QuoteValue(DataSet.FieldByName('ID').AsString);
            end;
          DataSet.Open;
          DataSet.DataSet.First;
          cbVersion.Items.Clear;
          while not DataSet.DataSet.EOF do
            begin
              cbVersion.Items.Add(DataSet.FieldByName('VERSION').AsString);
              DataSet.DataSet.Next;
            end;
          DataSet.GotoBookmark(Rec);
          cbVersion.Text:=DataSet.FieldByName('VERSION').AsString;
          Masterdata.DataSet.EnableControls;
        end;
    end;

  aType := 'M';
  cbStatus.Items.Clear;
  if not Data.States.DataSet.Locate('TYPE;STATUS',VarArrayOf([aType,FDataSet.FieldByName('STATUS').AsString]),[loCaseInsensitive]) then
    begin
      Data.SetFilter(Data.States,'');
      aFound := Data.States.DataSet.Locate('TYPE;STATUS',VarArrayOf([aType,FDataSet.FieldByName('STATUS').AsString]),[loCaseInsensitive]);
    end
  else aFound := True;
  if aFound then
    begin
      cbStatus.Items.Add(Data.States.FieldByName('STATUSNAME').AsString+' ('+Data.States.FieldByName('STATUS').AsString+')');
      cbStatus.Text := Data.States.FieldByName('STATUSNAME').AsString+' ('+Data.States.FieldByName('STATUS').AsString+')';
    end
  else cbStatus.Text:=FDataSet.FieldByName('STATUS').AsString;
  tmp := trim(Data.States.FieldByName('DERIVATIVE').AsString);
  if (length(tmp) = 0) or (tmp[length(tmp)] <> ';') then
    tmp := tmp+';';
  if tmp <> ';' then
    begin
      while pos(';',tmp) > 0 do
        begin
          if Data.States.DataSet.Locate('TYPE;STATUS',VarArrayOf([aType,copy(tmp,0,pos(';',tmp)-1)]),[loCaseInsensitive]) then
            cbStatus.Items.Add(Data.States.FieldByName('STATUSNAME').AsString+' ('+Data.States.FieldByName('STATUS').AsString+')');
          tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
        end;
    end
  else
    begin
      Data.SetFilter(Data.States,Data.QuoteField('TYPE')+'='+Data.QuoteValue(aType));
      with Data.States.DataSet do
        begin
          First;
          while not eof do
            begin
              if cbStatus.Items.IndexOf(Data.States.FieldByName('STATUSNAME').AsString+' ('+Data.States.FieldByName('STATUS').AsString+')') = -1 then
                cbStatus.Items.Add(Data.States.FieldByName('STATUSNAME').AsString+' ('+Data.States.FieldByName('STATUS').AsString+')');
              Next;
            end;
        end;
    end;

  pcPages.AddTabClass(TfArticlePositionFrame,strPositions,@AddPositions);
  TMasterdata(DataSet).Positions.Open;
  if TMasterdata(DataSet).Positions.Count > 0 then
    pcPages.AddTab(TfArticlePositionFrame.Create(Self),False);
  pcPages.AddTabClass(TfDocumentFrame,strFiles,@AddDocuments);
  if (FDataSet.State <> dsInsert) and (fDataSet.Count > 0) then
    begin
      aDocuments := TDocuments.CreateEx(Self,Data);
      aDocuments.CreateTable;
      aDocuments.Select(DataSet.Id.AsLargeInt,'M',DataSet.FieldByName('ID').AsString,DataSet.FieldByName('VERSION').AsVariant,DataSet.FieldByName('LANGUAGE').AsVariant);
      aDocuments.Open;
      if aDocuments.Count = 0 then
        aDocuments.Free
      else
        begin
          aDocFrame := TfDocumentFrame.Create(Self);
          pcPages.AddTab(aDocFrame,False);
          aDocFrame.DataSet := aDocuments;
          aDocFrame.BaseElement := FDataSet;
        end;
    end;
  pcPages.AddTabClass(TfListFrame,strProperties,@AddList);
  TMasterdata(DataSet).Properties.Open;
  if (FDataSet.State = dsInsert) or (TMasterdata(DataSet).Properties.Count > 0) then
    pcPages.AddTab(TfListFrame.Create(nil),False,strProperties);
  pcPages.AddTabClass(TfArticleStorageFrame,strStorage,@AddStorage);
  TMasterdata(DataSet).Storage.Open;
  if TMasterdata(DataSet).Storage.Count > 0 then
    pcPages.AddTab(TfArticleStorageFrame.Create(nil),False);
  pcPages.AddTabClass(TfArticleSupplierFrame,strSupplier,@AddSupplier);
  TMasterdata(DataSet).Supplier.Open;
  if (FDataSet.State = dsInsert) or (TMasterdata(DataSet).Supplier.Count > 0) then
    pcPages.AddTab(TfArticleSupplierFrame.Create(nil),False);
  pcPages.AddTabClass(TfHistoryFrame,strHistory,@AddHistory);
  TMasterdata(DataSet).History.Open;
  if TMasterdata(DataSet).History.Count > 0 then
    pcPages.AddTab(TfHistoryFrame.Create(Self),False);
  if not TMasterdata(DataSet).Images.DataSet.Active then
    TMasterdata(DataSet).Images.DataSet.Open;
  pcPages.AddTabClass(TfImageFrame,strImages,@AddImages);
  if (FDataSet.State = dsInsert) or (TMasterdata(DataSet).Images.Count > 0) then
    pcPages.AddTab(TfImageFrame.Create(Self),False);
  TMasterdata(DataSet).Images.DataSet.Close;
  aThumbnails := TThumbnails.Create(nil);
  aThumbnails.SelectByRefId(DataSet.Id.AsVariant);
  aThumbnails.Open;
  if aThumbnails.Count>0 then
    begin
      aStream := TMemoryStream.Create;
      Data.BlobFieldToStream(aThumbnails.DataSet,'THUMBNAIL',aStream);
      aStream.Position:=0;
      iArticle.Picture.LoadFromStreamWithFileExt(aStream,'jpg');
      aStream.Free;
      acPasteImage.Visible:=False;
      acAddImage.Visible:=False;
      acScreenshot.Visible:=False;
    end
  else
    begin
      iArticle.Picture.Clear;
      acPasteImage.Visible:=True;
      acAddImage.Visible:=True;
      acScreenshot.Visible:=True;
    end;
  aThumbnails.Free;
  pcPages.AddTabClass(TfArticleTextFrame,strTexts,@AddTexts);
  TMasterdata(DataSet).Texts.Open;
  if (FDataSet.State = dsInsert) or (TMasterdata(DataSet).Texts.Count > 0) then
    pcPages.AddTab(TfArticleTextFrame.Create(Self),False);
  pcPages.AddTabClass(TfListFrame,strPrices,@AddList);
  TMasterdata(DataSet).Prices.Open;
  if (FDataSet.State = dsInsert) or (TMasterdata(DataSet).Prices.Count > 0) then
    pcPages.AddTab(TfListFrame.Create(nil),False,strPrices);
  pcPages.AddTabClass(TfLinkFrame,strLinks,@AddLinks);
  TMasterdata(DataSet).Links.Open;
  if TMasterdata(DataSet).Links.Count > 0 then
    pcPages.AddTab(TfLinkFrame.Create(Self),False);
  pcPages.AddTabClass(TfArticleRepairFrame,strRepair,@AddRepair);
  TMasterdata(DataSet).Assembly.Open;
  if TMasterdata(DataSet).Assembly.Count > 0 then
    pcPages.AddTab(TfArticleRepairFrame.Create(Self),False);
  pcPages.AddTabClass(TfFinance,strFinance,@AddFinance);
  if (not DataSet.FieldByName('COSTCENTRE').IsNull)
  or (not DataSet.FieldByName('ACCOUNT').IsNull)
  or (not DataSet.FieldByName('ACCOUNTINGINFO').IsNull) then
    pcPages.AddTab(TfFinance.Create(Self),False);

  mShorttext.SetFocus;
  with Application as TBaseVisualApplication do
    AddTabClasses('ART',pcPages);
  with Application as TBaseVisualApplication do
    AddTabs(pcPages);
  if (DataSet.State<> dsInsert) and (DataSet.Id.AsVariant<>Null) then
    begin
      aWiki := TWikiList.Create(nil);
      if aWiki.FindWikiFolder('Promet-ERP-Help/forms/'+Self.ClassName+'/') then
        begin
          while not aWiki.EOF do
            begin
              aWikiPage := TfWikiFrame.Create(Self);
              aID := IntToStr(Int64(DataSet.Id.AsVariant));
              aWikiPage.Variables.Values['SQL_ID'] := aID;
              aWikiPage.Variables.Values['ID'] := TBaseDbList(DataSet).Number.AsString;
              aWikiPage.Variables.Values['TEXT'] := TBaseDbList(DataSet).Text.AsString;
              aWikiIdx := -1;
              if Assigned(TBaseDbList(DataSet).Status) then
                aWikiPage.Variables.Values['STATUS'] := TBaseDbList(DataSet).Status.AsString;
              if aWikiPage.OpenWikiPage('Promet-ERP-Help/forms/'+Self.ClassName+'/'+aWiki.Text.AsString) then
                begin
                  aWikiIdx := pcPages.AddTab(aWikiPage,False,aWiki.FieldByName('CAPTION').AsString);
                  aWikiPage.SetRights(FEditable);
                end
              else aWikiPage.Free;
              if aWiki.FieldByName('CAPTION').AsString = strOverview then
                begin
                  pcPages.Pages[aWikiIdx+1].PageIndex:=0;
                  pcPages.PageIndex:=0;
                end;
              aWikiPage.LeftBar:=True;
              aWiki.Next;
            end;
        end;
      aWiki.Free;
    end;
  if HasHelp then AddHelp(Self);
end;
function TfArticleFrame.SetRights: Boolean;
begin
  FEditable := (Data.Users.Rights.Right('MASTERDATA') > RIGHT_READ) or (Data.Users.Rights.Right('ARTICLES') > RIGHT_READ) or (Data.Users.Rights.Right('BENEFITS') > RIGHT_READ) or (Data.Users.Rights.Right('PARTSLIST') > RIGHT_READ);
  Result := FEditable;
  acDelete.Enabled:=FEditable and ((Data.Users.Rights.Right('MASTERDATA') > RIGHT_WRITE) or (Data.Users.Rights.Right('ARTICLES') > RIGHT_WRITE) or (Data.Users.Rights.Right('BENEFITS') > RIGHT_WRITE) or (Data.Users.Rights.Right('PARTSLIST') > RIGHT_WRITE));
  acPaste.Enabled:=FEditable;
  acRights.Enabled:=Data.Users.Rights.Right('MASTERDATA') >= RIGHT_PERMIT;

  pComponents.Enabled := FEditable;
end;
procedure TfArticleFrame.AddPositions(Sender: TObject);
begin
  TfArticlePositionFrame(Sender).SetDataSet(TMasterdata(FDataSet).Positions);
  TPrometInplaceFrame(Sender).SetRights(FEditable);
  TfArticlePositionFrame(Sender).SetFocus;
end;
procedure TfArticleFrame.AddList(Sender: TObject);
var
  i: Integer;
begin
  if TfListFrame(Sender).TabCaption = strPrices then
    begin
      with TfListFrame(Sender) do
        begin
          FList.FilterType:='MDPRICES';
          FList.DefaultRows:='GLOBALWIDTH:%;PTYPE:60;PRICE:120;CURRENCY:70;CUSTOMER:70;MINCOUNT:70;MAXCOUNT:70;VALIDFROM:80;VALIDTO:80;NOTE:200;';
          FList.DestroyDataSet:=False;
          TMasterdata(DataSet).Prices.Open;
          FList.DataSet := TMasterdata(DataSet).Prices;
          FList.pTop.Visible:=False;
          DataSource.DataSet := TMasterdata(DataSet).Prices.DataSet;
          for i := 0 to FList.gList.Columns.Count-1 do
            begin
              if FList.gList.Columns[i].FieldName = 'PTYPE' then
                begin
                  if not Assigned(PriceTypes) then
                    PriceTypes := TPriceTypes.Create(nil);
                  if not Pricetypes.DataSet.Active then
                    Pricetypes.Open;
                  FList.gList.Columns[i].PickList.Clear;
                  with Pricetypes.DataSet do
                    begin
                      First;
                      while not Eof do
                        begin
                          FList.gList.Columns[i].PickList.Add(Format('%-5s%s',[FieldByName('SYMBOL').AsString,FieldByName('NAME').AsString]));
                          next;
                        end;
                    end;
                end;
              if FList.gList.Columns[i].FieldName = 'CURRENCY' then
                begin
                  if not Data.Currency.DataSet.Active then
                    Data.Currency.Open;
                  FList.gList.Columns[i].PickList.Clear;
                  with Data.Currency.DataSet do
                    begin
                      First;
                      while not Eof do
                        begin
                          FList.gList.Columns[i].PickList.Add(Format('%-5s%s',[FieldByName('SYMBOL').AsString,FieldByName('NAME').AsString]));
                          next;
                        end;
                    end;
                end;
            end;
        end;
    end
  else if TfListFrame(Sender).TabCaption = strProperties then
    begin
      with TfListFrame(Sender) do
        begin
          FList.FilterType:='MDPROPERTIES';
          FList.DefaultRows:='GLOBALWIDTH:%;PROPERTY:150;VALUE:200;UNIT:70;';
          FList.DestroyDataSet:=False;
          TMasterdata(DataSet).Properties.Open;
          FList.DataSet := TMasterdata(DataSet).Properties;
          FList.pTop.Visible:=False;
          DataSource.DataSet := TMasterdata(DataSet).Properties.DataSet;
        end;
    end;
  TPrometInplaceFrame(Sender).SetRights(FEditable);
end;
procedure TfArticleFrame.AddStorage(Sender: TObject);
var
  i: Integer;
begin
  with TfArticleStorageFrame(Sender) do
    begin
      FList.FilterType:='STORAGE';
      FList.DefaultRows:='GLOBALWIDTH:%;STORAGEID:70;STORNAME:120;PLACE:100;QUANTITY:70;RESERVED:70;QUANTITYU:70';
      FList.pTop.Visible:=False;
      FList.DataSet := TMasterdata(DataSet).Storage;
      DataSource.DataSet := TMasterdata(DataSet).Properties.DataSet;
      for i := 0 to FList.gList.Columns.Count-1 do
        if FList.gList.Columns[i].FieldName = 'RESERVED' then
          FList.gList.Columns[i].ReadOnly:=False;
    end;
  TPrometInplaceFrame(Sender).SetRights(FEditable);
end;
procedure TfArticleFrame.AddSupplier(Sender: TObject);
begin
  TMasterdata(DataSet).Supplier.Open;
  TfArticleSupplierFrame(Sender).Supplier.DataSet := TMasterdata(DataSet).Supplier.DataSet;
  TMasterdata(DataSet).Supplier.Prices.Open;
  TfArticleSupplierFrame(Sender).SupplierPrices.DataSet := TMasterdata(DataSet).Supplier.Prices.DataSet;
  TfArticleSupplierFrame(Sender).SetRights(FEditable);
end;
procedure TfArticleFrame.AddRepair(Sender: TObject);
begin
  with TfArticleRepairFrame(Sender) do
    begin
      Masterdata := TMasterdata(Self.DataSet);
    end;
  TPrometInplaceFrame(Sender).SetRights(FEditable);
end;
procedure TfArticleFrame.AddTexts(Sender: TObject);
begin
  with TfArticleTextFrame(Sender) do
    begin
      Masterdata := TMasterdata(Self.DataSet);
    end;
  TPrometInplaceFrame(Sender).SetRights(FEditable);
end;

procedure TfArticleFrame.AddFinance(Sender: TObject);
begin
  TfFinance(Sender).DataSet := FDataSet;
  TPrometInplaceFrame(Sender).SetRights(FEditable);
end;

constructor TfArticleFrame.Create(AOwner: TComponent);
var
  aType: Char;
begin
  inherited Create(AOwner);
  mShortText.WantTabs:=False;
  if not Assigned(Units) then
    Units := TUnits.Create(nil);
  Units.Open;
  with Units.DataSet do
    begin
      First;
      while not Eof do
        begin
          cbQuantityUnit.Items.Add(FieldByName('NAME').AsString);
          next;
        end;
    end;
  Data.Languages.Open;
  with Data.Languages.DataSet do
    begin
      First;
      while not eof do
        begin
          cbLanguage.Items.Add(Format('%-4s%s',[FieldByName('ISO6391').AsString,FieldByName('LANGUAGE').AsString]));
          next;
        end;
    end;
  if not Assigned(Vat) then Vat := TVat.Create(Data);
  Vat.Open;
  with Vat.DataSet do
    begin
      First;
      while not eof do
        begin
          cbVat.Items.Add(Format('%-2s%s',[FieldByName('ID').AsString,FieldByName('NAME').AsString]));
          next;
        end;
    end;
  cbCategory.Items.Clear;
  aType := 'M';
  Data.Categories.CreateTable;
  Data.Categories.Open;
  Data.Categories.DataSet.Filter:=Data.QuoteField('TYPE')+'='+Data.QuoteValue(aType);
  Data.Categories.DataSet.Filtered:=True;
  Data.Categories.First;
  while not Data.Categories.EOF do
    begin
      if Data.Categories.FieldByName('ACTIVE').AsString<>'N' then
        cbCategory.Items.Add(Data.Categories.FieldByName('NAME').AsString);
      Data.Categories.DataSet.Next;
    end;
  {$ifdef DARWIN}
  cbStatus.Style:=csDropdown;
  {$endif}
end;
destructor TfArticleFrame.Destroy;
begin
  if Assigned(FConnection) then
    begin
      CloseConnection(acSave.Enabled);
      DataSet.Destroy;
      DataSet := nil;
      FreeAndNil(FConnection);
    end;
  inherited Destroy;
end;

function TfArticleFrame.CanHandleLink(aLink: string): Boolean;
begin
  Result := copy(aLink,0,10)='MASTERDATA';
end;

function TfArticleFrame.OpenFromLink(aLink: string) : Boolean;
begin
  inherited;
  if not CanHandleLink(aLink) then exit;
  CloseConnection;
  if not Assigned(FConnection) then
    FConnection := Data.GetNewConnection;
  if UseTransactions then
    Data.StartTransaction(FConnection);
  DataSet := TMasterdata.CreateEx(Self,Data,FConnection);
  DataSet.OnChange:=@MasterdataStateChange;
  TBaseDbList(DataSet).SelectFromLink(aLink);
  Dataset.Open;
  Result := DataSet.Count>0;
  if Result then
    DoOpen;
end;

procedure TfArticleFrame.ListFrameAdded(aFrame: TObject);
begin
  with aFrame as TfFilter do
    begin
      TabCaption := strArticleList;
      FilterType:='M';
      DefaultRows:='GLOBALWIDTH:%;ID:150;VERSION:100;LANGUAGE:60;MATCHCODE:200;SHORTTEXT:400;';
      Dataset := TMasterdataList.Create(nil);
      //gList.OnDrawColumnCell:=nil;
      if (Data.Users.Rights.Right('MASTERDATA') > RIGHT_READ) or (Data.Users.Rights.Right('ARTICLES') > RIGHT_READ) or (Data.Users.Rights.Right('BENEFITS') > RIGHT_READ) or (Data.Users.Rights.Right('PARTSLIST') > RIGHT_READ) then
        begin
          AddToolbarAction(NewAction);
        end;
    end;
end;

procedure TfArticleFrame.New;
begin
  CloseConnection;
  if not Assigned(FConnection) then
    FConnection := Data.GetNewConnection;
  TabCaption := strNewArticle;
  if UseTransactions then
    Data.StartTransaction(FConnection);
  DataSet := TMasterdata.CreateEx(Self,Data,FConnection);
  DataSet.OnChange:=@MasterdataStateChange;
  DataSet.Select(0);
  DataSet.Open;
  DataSet.DataSet.Insert;
  DoOpen;
  acSave.Enabled := False;
  acCancel.Enabled:= False;
end;
procedure TfArticleFrame.SetLanguage;
begin
end;
end.
