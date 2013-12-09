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
Created 04.12.2013
*******************************************************************************}
unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, ActnList, Clipbrd, Menus, Buttons, process, uclipp,
  uMainTreeFrame,DB,LCLType;

type
  TfMain = class(TForm)
    acLogin: TAction;
    acLogout: TAction;
    acAdd: TAction;
    acRestore: TAction;
    acDelete: TAction;
    acSave: TAction;
    acCancel: TAction;
    ActionList2: TActionList;
    Datasource: TDatasource;
    eSearch: TEdit;
    eName: TEdit;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    MainMenu: TMainMenu;
    mDesc: TMemo;
    miSet: TMenuItem;
    miGet: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    miClear: TMenuItem;
    miLanguage: TMenuItem;
    miMandant: TMenuItem;
    miOptions: TMenuItem;
    Panel1: TPanel;
    Panel3: TPanel;
    pTemp1: TPanel;
    pTemp2: TPanel;
    pTemp3: TPanel;
    pTemp4: TPanel;
    pClipboard: TPanel;
    pmTempBoards: TPopupMenu;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    Timer1: TTimer;
    tRefreshTemps: TTimer;
    tvMain: TPanel;
    Panel2: TPanel;
    Splitter1: TSplitter;
    ToolBar1: TToolBar;
    bNew: TToolButton;
    brestore: TToolButton;
    procedure acAddExecute(Sender: TObject);
    procedure acCancelExecute(Sender: TObject);
    procedure acDeleteExecute(Sender: TObject);
    procedure acLoginExecute(Sender: TObject);
    procedure acLogoutExecute(Sender: TObject);
    procedure acRestoreExecute(Sender: TObject);
    procedure acSaveExecute(Sender: TObject);
    procedure DatasourceStateChange(Sender: TObject);
    procedure eNameEditingDone(Sender: TObject);
    procedure eNameKeyPress(Sender: TObject; var Key: char);
    procedure eSearchKeyPress(Sender: TObject; var Key: char);
    function fMainTreeFrameOpen(aEntry: TTreeEntry): Boolean;
    procedure fMainTreeFrameSelectionChanged(aEntry: TTreeEntry);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure mDescEditingDone(Sender: TObject);
    procedure mDescKeyPress(Sender: TObject; var Key: char);
    procedure miClearClick(Sender: TObject);
    procedure miSetClick(Sender: TObject);
    procedure pmTempBoardsPopup(Sender: TObject);
    procedure pTemp1DblClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure tRefreshTempsTimer(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    DataSet : TClipp;
    TempDataSet : TClipp;
    SearchDS : TClipp;
    procedure DoCreate;
    procedure RefreshView;
  end;

var
  fMain: TfMain;
implementation
uses uBaseApplication, uData, uBaseDbInterface,
  uDocuments,uFilterFrame,uIntfStrConsts,uPrometFrames,uBaseDbClasses,
  uWikiFrame;
resourcestring
  strDirmustSelected                 = 'Wählen (oder erstellen) Sie ein Verzeichnis um den Eintrag abzulegen.';
  strRestoreCompleted                = 'in Zwischenablage';
  strRestorePartCompleted            = 'teilweise in Zwischenablage';
  strClear                           = '<leer>';
{$R *.lfm}
procedure TfMain.acAddExecute(Sender: TObject);
var
  aFormat: LongWord;
  i: Integer;
  aMime: String;
  aProc: TProcess;
  aExt: String;
  aStream: TFileStream;
  aMStream: TMemoryStream;
  aFStream: TFileStream;
  aOK: Boolean;
  aName: String;
  ParentID: String;
begin
  if Assigned(fMainTreeFrame.tvMain.Selected)
  and (TTreeEntry(fMainTreeFrame.tvMain.Selected.Data).Typ = etDir) then
    begin
      if InputQuery(strName,strName,aName) then
        begin
          DataSet.Insert;
          DataSet.FieldByName('NAME').AsString:=aName;
          Data.SetFilter(Data.Tree,'',0,'','ASC',False,True,False);
          Data.GotoBookmark(Data.Tree,TTreeEntry(fMainTreeFrame.tvMain.Selected.Data).Rec);
          ParentID := Data.Tree.Id.AsString;
          DataSet.FieldByName('TREEENTRY').AsString:=ParentID;
          DataSet.AddFromClipboard;
          RefreshView;
          DataSet.Post;
          fMainTreeFrame.tvMain.Selected.Collapse(False);
          fMainTreeFrame.tvMain.Selected.Expand(False);
        end;
    end
  else Showmessage(strDirmustSelected);
end;

procedure TfMain.acCancelExecute(Sender: TObject);
begin
  DataSet.DataSet.Cancel;
end;

procedure TfMain.acDeleteExecute(Sender: TObject);
begin
  if dataSet.Count>0 then
    begin
      DataSet.Delete;
      fMainTreeFrame.tvMain.Selected.Delete;
    end;
  RefreshView;
end;
procedure TfMain.acLoginExecute(Sender: TObject);
var
  WikiFrame: TfWikiFrame;
  Node: TTreeNode;
  miNew: TMenuItem;
  aDocuments: TDocuments;
  aStat: TTreeNode;
begin
  with Application as IBaseApplication do
    if not Login then
      begin
        Application.Terminate;
        exit;
      end;
  acLogin.Enabled:=False;
  acLogout.Enabled:=True;
  uClipp.AddToMainTree;
  if fMainTreeFrame.tvMain.Items.Count>0 then
    fMainTreeFrame.tvMain.Items[0].Expanded:=True;
  DataSet := TClipp.Create(nil,Data);
  TempDataSet := TClipp.Create(nil,Data);
  Datasource.DataSet := DataSet.DataSet;
  SearchDS := TClipp.Create(nil,Data);
end;
procedure TfMain.acLogoutExecute(Sender: TObject);
begin
  TempDataSet.Free;
  DataSet.Free;
  SearchDS.Free;
  with Application as IBaseApplication do
    Logout;
end;
procedure TfMain.acRestoreExecute(Sender: TObject);
var
  aRes: TRestoreResult;
begin
  if DataSet.Count>0 then
    begin
      aRes := DataSet.RestoreToClipboard;
      if aRes = rrFully then
        begin
          pClipboard.Caption:=strRestoreCompleted;
          pClipboard.Color:=clLime;
        end
      else if aRes = rrPartially then
        begin
          pClipboard.Caption:=strRestorePartCompleted;
          pClipboard.Color:=clYellow;
        end;
    end;
end;

procedure TfMain.acSaveExecute(Sender: TObject);
begin
  DataSet.Post;
end;

procedure TfMain.DatasourceStateChange(Sender: TObject);
begin
  acSave.Enabled:=DataSet.CanEdit;
  acCancel.Enabled:=DataSet.CanEdit;
end;

procedure TfMain.eNameEditingDone(Sender: TObject);
begin
  if DataSet.Count>0 then
    begin
      if not DataSet.CanEdit then DataSet.DataSet.Edit;
      DataSet.FieldByName('NAME').AsString := eName.Text;
    end;
end;

procedure TfMain.eNameKeyPress(Sender: TObject; var Key: char);
begin
  eNameEditingDone(Sender);
end;

procedure TfMain.eSearchKeyPress(Sender: TObject; var Key: char);
begin
  Timer1.Enabled:=True;
end;
function TfMain.fMainTreeFrameOpen(aEntry: TTreeEntry): Boolean;
begin
  if aEntry.Typ = etClipboardItem then
    begin
      DataSet.Filter(aEntry.Filter);
      DataSet.GotoBookmark(aEntry.Rec);
      if DataSet.Count>0 then
        acRestore.Execute;
    end;
end;
procedure TfMain.fMainTreeFrameSelectionChanged(aEntry: TTreeEntry);
begin
  DataSet.Close;
  if aEntry.Typ = etClipboardItem then
    begin
      DataSet.Filter(aEntry.Filter);
      DataSet.GotoBookmark(aEntry.Rec);
    end;
  RefreshView;
end;
procedure TfMain.FormCreate(Sender: TObject);
begin
  uMainTreeFrame.fMainTreeFrame := TfMainTree.Create(Self);
  fMainTreeFrame.Parent := tvMain;
  fMainTreeFrame.Align:=alClient;
  fMainTreeFrame.SearchOptions:='CLIPP';
  fMainTreeFrame.OnSelectionChanged:=@fMainTreeFrameSelectionChanged;
  fMainTreeFrame.OnOpen:=@fMainTreeFrameOpen;
end;
procedure TfMain.FormShow(Sender: TObject);
begin
  if not acLogin.Enabled then exit;
  with Application as IBaseApplication do
    RestoreConfig; //Must be called when Mainform is Visible
  acLogin.Execute;
  if Assigned(Data) then
    begin
    end;
end;
procedure TfMain.mDescEditingDone(Sender: TObject);
begin
  if DataSet.Count>0 then
    begin
      if not DataSet.CanEdit then DataSet.DataSet.Edit;
      DataSet.FieldByName('DESCRIPTION').AsString := mDesc.Lines.Text;
    end;
end;

procedure TfMain.mDescKeyPress(Sender: TObject; var Key: char);
begin
  mDescEditingDone(Sender);
end;

procedure TfMain.miClearClick(Sender: TObject);
var
  aCon: TComponent;
  aTag: PtrInt;
begin
  aTag := TComponent(Sender).Tag;
  TempDataSet.Filter(Data.QuoteField('NAME')+'='+Data.QuoteValue('Temp'+IntToStr(aTag)));
  while TempDataSet.Count>0 do
    TempDataSet.Delete;
  aCon := FindComponent('pTemp'+IntToStr(aTag));
  if Assigned(aCon) then
    TPanel(aCon).Caption:=strClear;
end;

procedure TfMain.miSetClick(Sender: TObject);
var
  aTag: PtrInt;
  aCon: TComponent;
begin
  aTag := TComponent(Sender).Tag;
  TempDataSet.Filter(Data.QuoteField('NAME')+'='+Data.QuoteValue('Temp'+IntToStr(aTag)));
  if TempDataSet.Count>0 then
    TempDataSet.DataSet.Edit
  else
    begin
      TempDataSet.Append;
      TempDataSet.FieldByName('NAME').AsString:='Temp'+IntToStr(aTag);
    end;
  TempDataSet.AddFromClipboard;
  TempDataSet.Post;
  aCon := FindComponent('pTemp'+IntToStr(aTag));
  if Assigned(aCon) then
    TPanel(aCon).Caption:=TempDataSet.FieldByName('CHANGEDBY').AsString;
end;

procedure TfMain.pmTempBoardsPopup(Sender: TObject);
var
  aCon: TControl;
begin
  aCon := ControlAtPos(Mouse.CursorPos,False,True);
  if Assigned(aCon) then
    pmTempBoards.Tag := aCon.Tag;
end;

procedure TfMain.pTemp1DblClick(Sender: TObject);
var
  aTag: PtrInt;
  aRes: TRestoreResult;
begin
  aTag := TComponent(Sender).Tag;
  TempDataSet.Filter(Data.QuoteField('NAME')+'='+Data.QuoteValue('Temp'+IntToStr(aTag)));
  if TempDataSet.Count>0 then
    begin
      aRes := DataSet.RestoreToClipboard;
      if aRes = rrFully then
        begin
          pClipboard.Caption:=strRestoreCompleted;
          pClipboard.Color:=clLime;
        end
      else if aRes = rrPartially then
        begin
          pClipboard.Caption:=strRestorePartCompleted;
          pClipboard.Color:=clYellow;
        end;
    end;
end;

procedure TfMain.Timer1Timer(Sender: TObject);
  function NodeThere(aRec : largeInt) : TTreeNode;
  var
    aNode: TTreeNode;
  begin
    Result := nil;
    if uMainTreeFrame.fMainTreeFrame.tvMain.Items.Count>0 then
      aNode := uMainTreeFrame.fMainTreeFrame.tvMain.Items[0];
    while Assigned(aNode) do
      begin
        if Assigned(aNode.Data) and (TTreeEntry(aNode.Data).Rec = aRec) then
          begin
            Result := aNode;
            break;
          end;
        aNode := aNode.GetNext;
      end;
  end;

  function ExpandDir(aRec : LargeInt) : TTReeNode;
  var
    bParent : Variant;
  begin
    Result := NodeThere(aRec);
    if not Assigned(Result) then
      begin
        if Data.Tree.DataSet.Locate('SQL_ID',aRec,[]) then
          begin
            bParent := Data.Tree.FieldByName('PARENT').AsVariant;
            ExpandDir(bParent);
          end;
        Result := NodeThere(aRec);
      end;
    Result.Expand(False);
  end;

var
  aParent: TTreeNode;
  i: Integer;
  aName: String;
begin
  Timer1.Enabled:=False;
  if eSearch.Text<>'' then
    begin
      SearchDS.Filter(data.ProcessTerm(Data.QuoteField('NAME')+'='+Data.QuoteValue('*'+eSearch.Text+'*')),1);
      if SearchDS.Count>0 then
        begin
          while not SearchDS.EOF do
            begin
              aParent := ExpandDir(SearchDS.FieldByName('TREEENTRY').AsVariant);
              if Assigned(aParent) then
                begin
                  for i := 0 to aParent.Count-1 do
                    begin
                      if Assigned(aParent.Items[i].Data) and (TTreeEntry(aParent.Items[i].Data).Rec = SearchDS.Id.AsVariant) then
                        begin
                          fMainTreeFrame.tvMain.Selected:=aParent.Items[i];
                          exit;
                        end;
                    end;
                end;
              SearchDS.Next;
            end;
        end;
    end;
end;

procedure TfMain.tRefreshTempsTimer(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to ToolBar1.ComponentCount-1 do
    if copy(ToolBar1.Components[i].Name,0,5) = 'pTemp' then
      TPanel(ToolBar1.Components[i]).Caption:=strClear;
  TempDataSet.Filter(Data.ProcessTerm(Data.QuoteField('NAME')+'='+Data.QuoteValue('Temp*')));
  while not TempDataSet.EOF do
    begin
      if Assigned(FindComponent('p'+TempDataSet.FieldByName('NAME').AsString)) then
        TPanel(FindComponent('p'+TempDataSet.FieldByName('NAME').AsString)).Caption:=TempDataSet.FieldByName('CHANGEDBY').AsString;
      TempDataSet.Next;
    end;
end;

procedure TfMain.DoCreate;
begin
  with Application as IBaseApplication do
    begin
      SetConfigName('Clipp');
    end;
  with Application as IBaseDbInterface do
    LoadMandants;
end;
procedure TfMain.RefreshView;
begin
  Panel2.Enabled := False;
  Image1.Picture.Clear;
  mDesc.Lines.Clear;
  eName.Text:='';
  if DataSet.Count>0 then
    begin
      eName.Text:=DataSet.FieldByName('NAME').AsString;
      mDesc.Lines.Text:=DataSet.FieldByName('DESCRIPTION').AsString;
      Panel2.Enabled:=True;
      pClipboard.Color:=clWindow;
      pClipboard.Caption:='';
    end;
end;
end.

