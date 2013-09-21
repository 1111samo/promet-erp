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
unit uAddressFrame;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, FileUtil, Forms, Controls, ExtCtrls, DbCtrls, DBGrids,
  Buttons, StdCtrls, db, uPrometFramesInplaceDB, uExtControls, uBaseDbClasses,
  Clipbrd,uPerson;
type

  { TfAddressFrame }

  TfAddressFrame = class(TPrometInplaceDBFrame)
    Address: TDatasource;
    bCopyToClipboard: TSpeedButton;
    Bevel1: TBevel;
    Bevel2: TBevel;
    bPasteFromClipboard: TSpeedButton;
    cbActive: TDBCheckBox;
    cbLand: TExtDBCombobox;
    cbTitle: TDBComboBox;
    dnNavigator: TDBNavigator;
    eAdditional: TDBEdit;
    eCallingName: TDBEdit;
    eCity: TDBEdit;
    eName: TDBEdit;
    ExtRotatedLabel1: TExtRotatedLabel;
    ExtRotatedLabel2: TExtRotatedLabel;
    eZip: TDBEdit;
    gAdresses: TDBGrid;
    Image3: TImage;
    Label1: TLabel;
    lAdditional: TLabel;
    lCallingName: TLabel;
    lCity: TLabel;
    lLand: TLabel;
    lName: TLabel;
    lPostalCode: TLabel;
    lStreet: TLabel;
    lTitle: TLabel;
    mAddress: TDBMemo;
    pAddress: TGroupBox;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Splitter1: TSplitter;
    procedure bCopyToClipboardClick(Sender: TObject);
    procedure bPasteFromClipboardClick(Sender: TObject);
    procedure cbTitleEnter(Sender: TObject);
    procedure mAddressExit(Sender: TObject);
  private
    { private declarations }
    FPerson : TPerson;
    procedure SetPerson(const AValue: TPerson);
  public
    { public declarations }
    constructor Create(AOwner : TComponent);override;
    destructor Destroy;override;
    property Person : TPerson read FPerson write SetPerson;
    procedure SetDataSet(const AValue: TBaseDBDataSet);override;
    procedure SetRights(Editable : Boolean);override;
  end;

implementation
{$R *.lfm}
uses uImpClipboardContact,uData,Utils;
procedure TfAddressFrame.bCopyToClipboardClick(Sender: TObject);
var
  tmp:string;
begin
  with Address.Dataset do
    begin
      if FieldByName('TITLE').AsString <> '' then
        tmp := tmp+FieldByName('TITLE').AsString+lineending;
      if FieldByName('CNAME').AsString <> '' then
        tmp := tmp+FieldByName('CNAME').AsString+' '+FieldByName('NAME').AsString+lineending
      else
      tmp := tmp+FieldByName('NAME').AsString+lineending;
      tmp := tmp+FieldByName('ADDITIONAL').AsString+lineending+FieldByName('ADDRESS').AsString+lineending+FieldByName('ZIP').AsString+' '+FieldByName('CITY').AsString;
      Clipboard.AsText := tmp;
    end;
end;
procedure TfAddressFrame.bPasteFromClipboardClick(Sender: TObject);
begin
  ContClipBoardImport(FPerson,False);
end;
procedure TfAddressFrame.cbTitleEnter(Sender: TObject);
begin
  if (not DataSet.CanEdit) and (DataSet.Count = 0) then
    begin
      DataSet.DataSet.Append;
      if (pos(' ',trim(Person.Text.AsString)) > 0)
      and (pos(' ',trim(Person.Text.AsString)) = rpos(' ',trim(Person.Text.AsString))) then
        begin
          DataSet.FieldByName('NAME').AsString:=copy(Person.Text.AsString,rpos(' ',Person.Text.AsString)+1,length(Person.Text.AsString));
          DataSet.FieldByName('CNAME').AsString:=copy(Person.Text.AsString,0,rpos(' ',Person.Text.AsString)-1);
        end
      else
        DataSet.FieldByName('NAME').AsString:=Person.Text.AsString;
    end;
end;

procedure TfAddressFrame.mAddressExit(Sender: TObject);
begin
  if eZip.CanFocus then
    eZip.SetFocus;
end;

procedure TfAddressFrame.SetPerson(const AValue: TPerson);
begin
  if FPerson=AValue then exit;
  FPerson:=AValue;
  bPasteFromClipboard.Enabled:=Assigned(FPerson);
end;
constructor TfAddressFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  cbLand.Clear;
  Data.Countries.Open;
  with Data.Countries.DataSet do
    begin
      First;
      while not eof do
        begin
          cbLand.Items.Add(Format('%-4s%s',[FieldByName('ID').AsString,FieldByName('NAME').AsString]));
          next;
        end;
    end;
end;

destructor TfAddressFrame.Destroy;
begin
  FDataSet := nil;
  inherited Destroy;
end;

procedure TfAddressFrame.SetDataSet(const AValue: TBaseDBDataSet);
begin
  inherited SetDataSet(AValue);
  Address.DataSet := FDataSet.DataSet;
end;

procedure TfAddressFrame.SetRights(Editable: Boolean);
begin
  Enabled := Editable;
end;

end.

