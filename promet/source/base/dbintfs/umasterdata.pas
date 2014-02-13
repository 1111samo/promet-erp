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
Created 01.06.2006
*******************************************************************************}
unit uMasterdata;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, db, uBaseDbClasses, uBaseERPDBClasses, uIntfStrConsts;
type

  { TMasterdataList }

  TMasterdataList = class(TBaseERPList)
  protected
    function GetMatchCodeFieldName: string;override;
    function GetTextFieldName: string;override;
    function GetNumberFieldName : string;override;
    function GetStatusFieldName : string;override;
  public
    constructor Create(aOwner: TComponent; DM: TComponent;
       aConnection: TComponent=nil; aMasterdata: TDataSet=nil); override;
    function GetTyp: string; override;
    procedure DefineFields(aDataSet : TDataSet);override;
    procedure Select(aID : string);overload;
    procedure Select(aID : string;aVersion : Variant;aLanguage : Variant);overload;
    procedure SelectFromLink(aLink : string);override;
  end;
  TMasterdataHistory = class(TBaseHistory)
  end;
  TMasterdata = class;
  TMDPos = class(TBaseDBPosition)
  private
    FMasterdata: TMasterdata;
  protected
    function GetCurrency : string;override;
    procedure PosPriceChanged(aPosDiff,aGrossDiff :Extended);override;
    procedure PosWeightChanged(aPosDiff :Extended);override;
  public
    constructor Create(aOwner : TComponent;DM : TComponent;aConnection : TComponent = nil;aMasterdata : TDataSet = nil);override;
    procedure DefineFields(aDataSet : TDataSet);override;
    property Masterdata : TMasterdata read FMasterdata write FMasterdata;
  end;
  TSerials = class(TBaseDbDataSet)
  public
    procedure DefineFields(aDataSet : TDataSet);override;
  end;
  TStorage = class(TBaseDBDataSet)
  public
    constructor Create(aOwner : TComponent;DM : TComponent;aConnection : TComponent = nil;aMasterdata : TDataSet = nil);override;
    destructor Destroy; override;
    function CreateTable : Boolean;override;
    procedure DefineFields(aDataSet : TDataSet);override;
    function DoPost(OrderType: TBaseDBDataset; Order: TBaseDBDataset;
      aStorage: string; aQuantity, aReserve: real; QuantityUnit, PosNo: string
  ): real;
  end;
  TSupplierPrices = class(TBaseDBDataSet)
  private
  public
    procedure DefineFields(aDataSet : TDataSet);override;
  end;
  TSupplier = class(TBaseDBDataSet)
  private
    FPrices: TSupplierPrices;
  public
    constructor Create(aOwner : TComponent;DM : TComponent;aConnection : TComponent = nil;aMasterdata : TDataSet = nil);override;
    destructor Destroy; override;
    function CreateTable : Boolean;override;
    procedure DefineFields(aDataSet : TDataSet);override;
    property Prices : TSupplierPrices read FPrices;
  end;
  TMasterdataLinks = class(TLinks)
  public
    procedure FillDefaults(aDataSet : TDataSet);override;
  end;

  { TMasterdataPrices }

  TMasterdataPrices = class(TBaseDbDataSet)
  public
    procedure DefineFields(aDataSet : TDataSet);override;
    procedure FillDefaults(aDataSet: TDataSet); override;
    function GetPriceType : Integer;
    function FormatCurrency(Value : real) : string;
  end;
  TMdProperties = class(TBaseDbDataSet)
  public
    procedure DefineFields(aDataSet : TDataSet);override;
  end;
  TMasterdataTexts = class(TBaseDbDataSet)
  public
    procedure DefineFields(aDataSet : TDataSet);override;
  end;
  TRepairParts = class(TBaseDbDataSet)
  public
    procedure DefineFields(aDataSet : TDataSet);override;
  end;
  TRepairAssembly = class(TBaseDbDataSet)
  private
    FParts: TRepairParts;
  public
    constructor Create(aOwner : TComponent;DM : TComponent;aConnection : TComponent = nil;aMasterdata : TDataSet = nil);override;
    destructor Destroy;override;
    procedure DefineFields(aDataSet : TDataSet);override;
    function CreateTable : Boolean;override;
    property Parts : TRepairParts read FParts;
  end;
  TMasterdata = class(TMasterdataList,IBaseHistory)
    procedure FDSDataChange(Sender: TObject; Field: TField);
  private
    FAssembly: TRepairAssembly;
    FHistory: TMasterdataHistory;
    FImages: TImages;
    FLinks: TMasterdataLinks;
    FPosition: TMDPos;
    FPrices: TMasterdataPrices;
    FProperties: TMdProperties;
    FSerials: TSerials;
    FStateChange: TNotifyEvent;
    FStorage: TStorage;
    FSupplier: TSupplier;
    FTexts: TMasterdataTexts;
    FDS: TDataSource;
    FSTatus : string;
    function GetHistory : TBaseHistory;
    function GetLanguage: TField;
    function GetVersion: TField;
  public
    constructor Create(aOwner : TComponent;DM : TComponent;aConnection : TComponent = nil;aMasterdata : TDataSet = nil);override;
    destructor Destroy;override;
    procedure Open;override;
    function CreateTable : Boolean;override;
    procedure DefineFields(aDataSet : TDataSet);override;
    procedure FillDefaults(aDataSet : TDataSet);override;
    procedure CascadicPost;override;
    procedure CascadicCancel;override;
    property Version : TField read GetVersion;
    property Language : TField read GetLanguage;
    property Positions : TMDPos read FPosition;
    property History : TMasterdataHistory read FHistory;
    property Images : TImages read FImages;
    property Links : TMasterdataLinks read FLinks;
    property Texts : TMasterdataTexts read FTexts;
    property Storage : TStorage read FStorage;
    property Supplier : TSupplier read FSupplier;
    property Prices : TMasterdataPrices read FPrices;
    property Properties : TMdProperties read FProperties;
    property Assembly : TRepairAssembly read FAssembly;
    property Serials : TSerials read FSerials;
    function Copy(aNewVersion : Variant;aNewLanguage : Variant;cPrices : Boolean = True;
                                                               cProperties : Boolean = True;
                                                               cTexts : Boolean = True;
                                                               cSupplier : Boolean = True) : Boolean;
    function Find(aIdent : string;Unsharp : Boolean = False) : Boolean;override;
    property OnStateChange : TNotifyEvent read FStateChange write FStateChange;
  end;
implementation
uses uBaseDBInterface, uBaseSearch, uBaseApplication, uBaseApplicationTools,
  uData, Utils,uOrder;
procedure TSupplierPrices.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'SUPPLIERPRICES';
      TableCaption:=strPrices;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('FROMUNIT',ftFloat,0,False);
            Add('QUANTITYU',ftString,10,False);
            Add('DISCOUNT',ftFloat,0,False);
            Add('PRICE',ftFloat,0,True);
            Add('CURRENCY',ftString,3,False);
          end;
    end;
end;
constructor TSupplier.Create(aOwner: TComponent; DM: TComponent;
  aConnection: TComponent; aMasterdata: TDataSet);
begin
  inherited Create(aOwner, DM, aConnection, aMasterdata);
  FPrices := TSupplierPrices.Create(Owner,DM,aConnection,DataSet);
end;
destructor TSupplier.Destroy;
begin
  FPrices.Free;
  inherited Destroy;
end;
function TSupplier.CreateTable : Boolean;
begin
  Result := inherited CreateTable;
  FPrices.CreateTable;
end;
procedure TSupplier.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'SUPPLIER';
      TableCaption:=strSupplier;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('ACCOUNTNO',ftString,60,True);
            Add('NAME',ftString,260,True);
            Add('DELIVERTM',ftInteger,0,False);
            Add('EID',ftString,30,False);
            Add('TRANSPORT',ftFloat,0,False);
            Add('TRANSCUR',ftString,3,False);
          end;
    end;
end;
procedure TRepairParts.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'REPAIRPARTS';
      TableCaption:=strRepairParts;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('PART',ftString,60,False);
          end;
    end;
end;
constructor TRepairAssembly.Create(aOwner: TComponent; DM: TComponent;
  aConnection: TComponent; aMasterdata: TDataSet);
begin
  inherited Create(aOwner, DM, aConnection, aMasterdata);
  FParts := TRepairParts.Create(Self,DM,aConnection,DataSet);
end;
destructor TRepairAssembly.Destroy;
begin
  FParts.Destroy;
  inherited Destroy;
end;
procedure TRepairAssembly.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'REPAIRASSEMBLY';
      TableCaption:=strRepairAssembly;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('ASSEMBLY',ftString,60,False);
          end;
    end;
end;

function TRepairAssembly.CreateTable : Boolean;
begin
  Result := inherited CreateTable;
  FParts.CreateTable;
end;

procedure TMasterdataTexts.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'TEXTS';
      TableCaption:=strTexts;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('TEXTTYPE',ftInteger,0,False);
            Add('TEXT',ftMemo,0,False);
          end;
    end;
end;
procedure TMdProperties.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'PROPERTIES';
      TableCaption:=strProperties;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('PROPERTY',ftString,50,false);
            Add('VALUE',ftString,50,false);
            Add('UNIT',ftString,10,false);
          end;
    end;
end;
procedure TMasterdataPrices.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'MDPRICES';
      TableCaption:=strPrices;
      UpdateFloatFields:=True;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('PTYPE',ftString,4,True);
            Add('PRICE',ftFloat,0,false);
            Add('CURRENCY',ftString,3,true);
            Add('MINCOUNT',ftFloat,0,False);
            Add('MAXCOUNT',ftFloat,0,False);
            Add('VALIDFROM',ftDate,0,False);
            Add('VALIDTO',ftDate,0,False);
            Add('CUSTOMER',ftString,20,False);
          end;
    end;
end;

procedure TMasterdataPrices.FillDefaults(aDataSet: TDataSet);
begin
  inherited FillDefaults(aDataSet);
  FieldByName('PTYPE').AsString:='SAP';
  if Data.Currency.DataSet.Active and Data.Currency.DataSet.Locate('DEFAULTCUR', 'Y', []) then
    FieldByName('CURRENCY').AsString := Data.Currency.FieldByName('SYMBOL').AsString;
end;

function TMasterdataPrices.GetPriceType: Integer;
begin
  Result := 0;
  Data.PriceTypes.Open;
  if Data.PriceTypes.DataSet.Locate('SYMBOL', trim(DataSet.FieldByName('PTYPE').AsString), []) then
    Result := StrToIntDef(copy(Data.Pricetypes.FieldByName('TYPE').AsString, 0, 2), 0);
end;
function TMasterdataPrices.FormatCurrency(Value: real): string;
begin
  Result := FormatFloat('0.00',Value)+' '+DataSet.FieldByName('CURRENCY').AsString;
end;
procedure TMasterdataLinks.FillDefaults(aDataSet: TDataSet);
begin
  inherited FillDefaults(aDataSet);
  aDataSet.FieldByName('RREF_ID').AsVariant:=(Parent as TMasterdata).Id.AsVariant;
end;
procedure TSerials.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'SERIALS';
      TableCaption:=strSerial;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('SERIAL',ftString,30,False);
            Add('NOTE',ftString,500,False);
          end;
    end;
end;
constructor TStorage.Create(aOwner: TComponent; DM : TComponent;aConnection: TComponent;
  aMasterdata: TDataSet);
begin
  inherited Create(aOwner, DM,aConnection, aMasterdata);
end;

destructor TStorage.Destroy;
begin
  inherited Destroy;
end;

function TStorage.CreateTable : Boolean;
begin
  Result := inherited CreateTable;
end;

procedure TStorage.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      UpdateFloatFields:=True;
      TableName := 'STORAGE';
      TableCaption:=strStorage;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('STORAGEID',ftString,3,True);
            Add('STORNAME',ftString,30,True);
            Add('PLACE',ftString,20,False);
            Add('QUANTITY',ftFloat,0,False);
            Add('RESERVED',ftFloat,0,False);
            Add('QUANTITYU',ftString,10,False);
            Add('CHARGE',ftInteger,0,False);
          end;
    end;
end;

function TStorage.DoPost(OrderType: TBaseDBDataset; Order: TBaseDBDataset;
  aStorage: string; aQuantity, aReserve: real; QuantityUnit,PosNo: string): real;
var
  JournalCreated: Boolean;
  r: Real;
  StorageJournal: TStorageJournal;
begin
  Result := 0;
  try
    if not Active then Open;
    //Lager selektieren oder anlegen
    if not Data.StorageType.Active then
      Data.StorageType.Open;
    if ((FieldByName('STORAGEID').AsString<>trim(copy(aStorage, 0, 3)))
    and (not Locate('STORAGEID', trim(copy(aStorage, 0, 3)), [loCaseInsensitive])))
    or ((Parent.FieldByName('USEBATCH').AsString='Y') and (aQuantity>0)) then
      begin
        //Kein Lager vorhanden ? dann Tragen wir das Hauptlager ein (sollte ja nicht zuoft vorkommen)
        Data.StorageType.DataSet.Locate('DEFAULTST', 'Y', [loCaseInsensitive]);
        Data.StorageType.DataSet.Locate('ID',trim(copy(aStorage, 0, 3)),[loCaseInsensitive]);
        with DataSet do
          begin
            Append;
            if DataSet.FieldDefs.IndexOf('TYPE') > -1 then
              begin
                FieldByName('TYPE').AsString := Parent.FieldByName('TYPE').AsString;
                FieldByName('ID').AsString := Parent.FieldByName('ID').AsString;
                FieldByName('VERSION').AsVariant := Parent.FieldByName('VERSION').AsString;
                FieldByName('LANGUAGE').AsVariant := Parent.FieldByName('LANGUAGE').AsString;
              end;
            FieldByName('STORAGEID').AsString := Data.StorageType.FieldByName('ID').AsString;
            FieldByName('STORNAME').AsString := Data.StorageType.FieldByName('NAME').AsString;
            FieldByName('QUANTITY').AsFloat := 0;
            FieldByName('QUANTITYU').AsString := QuantityUnit;
            if ((Parent.FieldByName('USEBATCH').AsString='Y') and (aQuantity>0)) then
              begin //new Batch
                FieldByName('CHARGE').AsString:=Order.FieldByName('ORDERNO').AsString;
              end;
            aStorage := FieldByName('STORAGEID').AsString;
            Post;
          end;
      end;
    //Buchen
    Edit;
    if (FieldByName('QUANTITY').AsFloat>0) and (FieldByName('QUANTITY').AsFloat - FieldByName('RESERVED').AsFloat + aQuantity < 0) then
      begin
        Result := aQuantity-(FieldByName('QUANTITY').AsFloat - FieldByName('RESERVED').AsFloat + aQuantity);
        aQuantity:=aQuantity-Result;
      end
    else Result := aQuantity;
    FieldByName('QUANTITY').AsFloat := FieldByName('QUANTITY').AsFloat + aQuantity;
    FieldByName('RESERVED').AsFloat := FieldByName('RESERVED').AsFloat + aReserve;
    DataSet.Post;
    JournalCreated := False;
    //Serienummern buchen
    if (OrderType.FieldByName('B_STORAGE').AsString <> '0') and (TMasterdata(Parent).FieldByName('USESERIAL').AsString = 'Y') then
      begin
        if OrderType.FieldByName('B_SERIALS').AsString = '+' then
          begin
            r := aQuantity;
            while r >= 1 do
              begin
                JournalCreated := False;
                if TOrder(Order).Positions.FieldByName('SERIAL').AsString='' then
                  begin
                    if Assigned(TOrder(Order).OnGetSerial) then
                      if TOrder(Order).OnGetSerial(TOrder(Order),TMasterdata(Parent),1) then
                        with Data.StorageJournal.DataSet do
                          begin
                            Insert;
                            FieldByName('STORAGEID').AsString := FieldByName('STORAGEID').AsString;
                            FieldByName('ORDERNO').AsString := Order.FieldByName('ORDERNO').AsString;
                            FieldByName('OSTATUS').AsString := Order.FieldByName('STATUS').AsString;
                            FieldByName('POSNO').AsString   := PosNo;
                            FieldByName('TYPE').AsString    := Parent.FieldByName('TYPE').AsString;
                            FieldByName('ID').AsString      := Parent.FieldByName('ID').AsString;
                            FieldByName('VERSION').AsString := Parent.FieldByName('VERSION').AsString;
                            FieldByName('LANGUAGE').AsString := Parent.FieldByName('LANGUAGE').AsString;
                            FieldByName('SERIAL').AsString  := TOrder(Order).Positions.FieldByName('SERIAL').AsString;
                            FieldByName('QUANTITY').AsFloat := 1;
                            FieldByName('QUANTITYU').AsString := QuantityUnit;
                            Post;
                            r := r - 1;
                            if not TMasterdata(Parent).Serials.Locate('SERIAL',TOrder(Order).Positions.FieldByName('SERIAL').AsString,[]) then
                              begin
                                TMasterdata(Parent).Serials.Insert;
                                TMasterdata(Parent).Serials.FieldByName('SERIAL').AsString:=TOrder(Order).Positions.FieldByName('SERIAL').AsString;
                                TMasterdata(Parent).Serials.Post;
                              end;
                            JournalCreated := True;
                          end;
                    if not JournalCreated then
                      begin
                        Result := 0;
                        exit;
                      end;
                  end
                else
                  begin
                    with Data.StorageJournal.DataSet do
                      begin
                        Insert;
                        FieldByName('STORAGEID').AsString := FieldByName('STORAGEID').AsString;
                        FieldByName('ORDERNO').AsString := Order.FieldByName('ORDERNO').AsString;
                        FieldByName('OSTATUS').AsString := Order.FieldByName('STATUS').AsString;
                        FieldByName('POSNO').AsString   := PosNo;
                        FieldByName('TYPE').AsString    := Parent.FieldByName('TYPE').AsString;
                        FieldByName('ID').AsString      := Parent.FieldByName('ID').AsString;
                        FieldByName('VERSION').AsString := Parent.FieldByName('VERSION').AsString;
                        FieldByName('LANGUAGE').AsString := Parent.FieldByName('LANGUAGE').AsString;
                        FieldByName('SERIAL').AsString  := TOrder(Order).Positions.FieldByName('SERIAL').AsString;
                        FieldByName('QUANTITY').AsFloat := 1;
                        FieldByName('QUANTITYU').AsString := QuantityUnit;
                        Post;
                        if not TMasterdata(Parent).Serials.Locate('SERIAL',TOrder(Order).Positions.FieldByName('SERIAL').AsString,[]) then
                          begin
                            TMasterdata(Parent).Serials.Insert;
                            TMasterdata(Parent).Serials.FieldByName('SERIAL').AsString:=TOrder(Order).Positions.FieldByName('SERIAL').AsString;
                            TMasterdata(Parent).Serials.Post;
                          end;
                        r := r - 1;
                        JournalCreated := True;
                      end;
                  end;
              end;
          end
        else if OrderType.FieldByName('B_SERIALS').AsString = '-' then
          begin
            r := aQuantity;
            while r >= 1 do
              begin
                JournalCreated := False;
                if TOrder(Order).Positions.FieldByName('SERIAL').AsString='' then
                  begin
                    if Assigned(TOrder(Order).OnGetSerial) then
                      if TOrder(Order).OnGetSerial(TOrder(Order),TMasterdata(Parent),-1) then
                        with Data.StorageJournal.DataSet do
                          begin
                            Insert;
                            FieldByName('STORAGEID').AsString := FieldByName('STORAGEID').AsString;
                            FieldByName('ORDERNO').AsString := Order.FieldByName('ORDERNO').AsString;
                            FieldByName('OSTATUS').AsString := Order.FieldByName('STATUS').AsString;
                            FieldByName('POSNO').AsString   := PosNo;
                            FieldByName('TYPE').AsString    := Parent.FieldByName('TYPE').AsString;
                            FieldByName('ID').AsString      := Parent.FieldByName('ID').AsString;
                            FieldByName('VERSION').AsString := Parent.FieldByName('VERSION').AsString;
                            FieldByName('LANGUAGE').AsString := Parent.FieldByName('LANGUAGE').AsString;
                            FieldByName('SERIAL').AsString  := TOrder(Order).Positions.FieldByName('SERIAL').AsString;
                            FieldByName('QUANTITY').AsFloat := -1;
                            FieldByName('QUANTITYU').AsString := QuantityUnit;
                            Post;
                            if TMasterdata(Parent).Serials.Locate('SERIAL',TOrder(Order).Positions.FieldByName('SERIAL').AsString,[]) then
                              TMasterdata(Parent).Serials.Delete;
                            r := r - 1;
                            JournalCreated := True;
                          end;
                    if not JournalCreated then
                      begin
                        Result := 0;
                        exit;
                      end;
                  end
                else
                  begin
                    with Data.StorageJournal.DataSet do
                      begin
                        Insert;
                        FieldByName('STORAGEID').AsString := FieldByName('STORAGEID').AsString;
                        FieldByName('ORDERNO').AsString := Order.FieldByName('ORDERNO').AsString;
                        FieldByName('OSTATUS').AsString := Order.FieldByName('STATUS').AsString;
                        FieldByName('POSNO').AsString   := PosNo;
                        FieldByName('TYPE').AsString    := Parent.FieldByName('TYPE').AsString;
                        FieldByName('ID').AsString      := Parent.FieldByName('ID').AsString;
                        FieldByName('VERSION').AsString := Parent.FieldByName('VERSION').AsString;
                        FieldByName('LANGUAGE').AsString := Parent.FieldByName('LANGUAGE').AsString;
                        FieldByName('SERIAL').AsString  := TOrder(Order).Positions.FieldByName('SERIAL').AsString;
                        FieldByName('QUANTITY').AsFloat := -1;
                        FieldByName('QUANTITYU').AsString := QuantityUnit;
                        Post;
                        if TMasterdata(Parent).Serials.Locate('SERIAL',TOrder(Order).Positions.FieldByName('SERIAL').AsString,[]) then
                          TMasterdata(Parent).Serials.Delete;
                        r := r - 1;
                        JournalCreated := True;
                      end;
                  end;
              end;
          end;
      end;
    //Journal erstellen falls nicht schon von den Serienummern gebucht wurde
    if (OrderType.FieldByName('B_STORAGE').AsString <> '0') then
      if not JournalCreated and (OrderType.FieldByName('B_STORAGE').AsString <> '0') then
        begin
          StorageJournal := TStorageJournal.Create(Owner,DataModule,Connection);
          StorageJournal.CreateTable;
          StorageJournal.Open;
          with StorageJournal.DataSet do
            begin
              Insert;
              FieldByName('STORAGEID').AsString := FieldByName('STORAGEID').AsString;
              FieldByName('ORDERNO').AsString := Order.FieldByName('ORDERNO').AsString;
              FieldByName('OSTATUS').AsString := Order.FieldByName('STATUS').AsString;
              FieldByName('POSNO').AsString := PosNo;
              FieldByName('TYPE').AsString    := Parent.FieldByName('TYPE').AsString;
              FieldByName('ID').AsString      := Parent.FieldByName('ID').AsString;
              FieldByName('VERSION').AsString := Parent.FieldByName('VERSION').AsString;
              FieldByName('LANGUAGE').AsString := Parent.FieldByName('LANGUAGE').AsString;
              FieldByName('QUANTITY').AsFloat := aQuantity;
              FieldByName('QUANTITYU').AsString := QuantityUnit;
              Post;
            end;
          StorageJournal.Free;
        end;
  except
    result := 0;
  end;
end;

function TMasterdata.GetVersion: TField;
begin
  Result := DataSet.FieldByName('VERSION');
end;

function TMasterdataList.GetTyp: string;
begin
  Result := 'M';
end;

procedure TMasterdata.FDSDataChange(Sender: TObject; Field: TField);
begin
  if not Assigned(Field) then exit;
  if DataSet.ControlsDisabled then exit;
  if Field.FieldName = 'STATUS' then
    begin
      History.Open;
      History.AddItem(Self.DataSet,Format(strStatusChanged,[FStatus,Field.AsString]),'','',nil,ACICON_STATUSCH);
      FStatus := Field.AsString;
      if Assigned(FStateChange) then
        FStateChange(Self);
    end;
  if (Field.FieldName = 'ID') then
    begin
      History.AddItem(Self.DataSet,Format(strNumberChanged,[Field.AsString]),'','',DataSet,ACICON_EDITED);
    end;
end;
function TMasterdata.GetHistory: TBaseHistory;
begin
  Result := History;
end;
function TMasterdata.GetLanguage: TField;
begin
  Result := DataSet.FieldByName('LANGUAGE');
end;
constructor TMasterdata.Create(aOwner: TComponent;DM : TComponent; aConnection: TComponent;
  aMasterdata: TDataSet);
begin
  inherited Create(aOwner, DM, aConnection, aMasterdata);
  with BaseApplication as IBaseDbInterface do
    begin
      with DataSet as IBaseDBFilter do
        begin
          UsePermissions:=False;
        end;
    end;
  FPosition := TMDPos.Create(Self, DM,aConnection,DataSet);
  FPosition.Masterdata:=Self;
  FStorage := TStorage.Create(Self,DM,aConnection,DataSet);
  FHistory := TMasterdataHistory.Create(Self,DM,aConnection,DataSet);
  FImages := TImages.Create(Self,DM,aConnection,DataSet);
  FLinks := TMasterdataLinks.Create(Self,DM,aConnection);
  FTexts := TMasterdataTexts.Create(Self,DM,aConnection,DataSet);
  FPrices := TMasterdataPrices.Create(Self,DM,aConnection,DataSet);
  FProperties := TMdProperties.Create(Self,DM,aConnection,DataSet);
  FAssembly := TRepairAssembly.Create(Self,DM,aConnection,DataSet);
  FSupplier := TSupplier.Create(Self,DM,aConnection,DataSet);
  FSerials := TSerials.Create(Self,DM,aConnection,DataSet);
  FDS := TDataSource.Create(Self);
  FDS.DataSet := DataSet;
  FDS.OnDataChange:=@FDSDataChange;
end;
destructor TMasterdata.Destroy;
begin
  FDS.Free;
  FSerials.Free;
  FPosition.Destroy;
  FStorage.Destroy;
  FHistory.Destroy;
  FImages.Destroy;
  FTexts.Destroy;
  FLinks.Destroy;
  FPrices.Destroy;
  FProperties.Destroy;
  FAssembly.Destroy;
  FSupplier.Destroy;
  inherited Destroy;
end;

procedure TMasterdata.Open;
begin
  inherited Open;
  FStatus := Status.AsString;
end;

function TMasterdata.CreateTable : Boolean;
var
  aUnits: TUnits;
begin
  Result := inherited CreateTable;
  FPosition.CreateTable;
  FStorage.CreateTable;
  FHistory.CreateTable;
  FTexts.CreateTable;
  FLinks.CreateTable;
  FPrices.CreateTable;
  FProperties.CreateTable;
  FSerials.CreateTable;
  FAssembly.CreateTable;
  FSupplier.CreateTable;
  aUnits := TUnits.Create(nil,DataModule,Connection);
  aUnits.CreateTable;
  aUnits.Free;
end;
procedure TMasterdata.DefineFields(aDataSet: TDataSet);
begin
  inherited DefineFields(aDataSet);
  with aDataSet as IBaseDbFilter, BaseApplication as IBaseDbInterface do
    BaseFilter := '';
end;
procedure TMasterdata.FillDefaults(aDataSet: TDataSet);
begin
  with aDataSet,BaseApplication as IBaseDBInterface do
    begin
      aDataSet.DisableControls;
      if FieldByName('ID').IsNull then
        FieldByName('ID').AsString      := Data.Numbers.GetNewNumber('ARTICLES');
      FieldByName('TYPE').AsString    := 'A';
      FieldByName('TREEENTRY').AsVariant := TREE_ID_MASTERDATA_UNSORTED;
      FieldByName('USESERIAL').AsString := 'N';
      FieldByName('OWNPROD').AsString := 'N';
      FieldByName('UNIT').AsInteger   := 1;
      FieldByName('LANGUAGE').AsString := 'de'; //TODO:find default language
      FieldByName('CRDATE').AsDateTime := Date;
      FieldByName('ACTIVE').AsString  := 'Y';
      if not Data.Vat.DataSet.Active then
        Data.Vat.Open;
      FieldByName('VAT').AsString     := Data.Vat.FieldByName('ID').AsString;
      FieldByName('CREATEDBY').AsString := Data.Users.IDCode.AsString;
      FieldByName('CHANGEDBY').AsString := Data.Users.IDCode.AsString;
      aDataSet.EnableControls;
    end;
end;
procedure TMasterdata.CascadicPost;
begin
  FPosition.CascadicPost;
  FStorage.CascadicPost;
  FHistory.CascadicPost;
  FTexts.CascadicPost;
  FLinks.CascadicPost;
  FPrices.CascadicPost;
  FProperties.CascadicPost;
  FAssembly.CascadicPost;
  inherited CascadicPost;
end;
procedure TMasterdata.CascadicCancel;
begin
  FPosition.CascadicCancel;
  FStorage.CascadicCancel;
  FHistory.CascadicCancel;
  FTexts.CascadicCancel;
  FLinks.CascadicCancel;
  FPrices.CascadicCancel;
  FProperties.CascadicCancel;
  FAssembly.CascadicCancel;
  inherited CascadicCancel;
end;
function TMasterdata.Copy(aNewVersion: Variant; aNewLanguage: Variant;
  cPrices: Boolean; cProperties: Boolean; cTexts: Boolean; cSupplier: Boolean
  ): Boolean;
var
  bMasterdata: TMasterdata;
begin
  Result := True;
  bMasterdata := TMasterdata.Create(Self,DataModule,Self.Connection);
  try
    try
      bMasterdata.Select(Id.AsVariant);
      bMasterdata.Append;
      FDS.DataSet:=Nil;
      bMasterdata.FDS.DataSet:=Nil;
      bMasterdata.DirectAssign(Self);
      if aNewVersion <> bMasterdata.Version.AsVariant then
        bMasterdata.Version.AsVariant:=aNewVersion;
      if aNewLanguage <> bMasterdata.Language.AsVariant then
        bMasterdata.Language.AsVariant:=aNewLanguage;
      bMasterdata.CascadicPost;
      FDS.DataSet:=DataSet;
      bMasterdata.FDS.DataSet:=DataSet;
      Self.Select(bMasterdata.Id.AsVariant);
      Self.Open;
    except
      Result := False;
    end;
  finally
    bMasterdata.Free;
  end;
  DataSet.Edit;
  Change;
end;
function TMasterdata.Find(aIdent: string;Unsharp : Boolean = False): Boolean;
begin
  with DataSet as IBaseDbFilter,BaseApplication as IBaseDbInterface do
    Filter := '('+Data.QuoteField(GetNumberFieldName)+'='+Data.QuoteValue(aIdent)+') OR ('+Data.QuoteField('MATCHCODE')+'='+Data.QuoteValue(aIdent)+') and ('+Data.QuoteField('ACTIVE')+'='+Data.QuoteValue('Y')+')';
  Open;
  Result := Count > 0;
  if (not Result) and Unsharp then
    begin
      with DataSet as IBaseDbFilter,BaseApplication as IBaseDbInterface do
        Filter := '('+Data.ProcessTerm(Data.QuoteField(GetNumberFieldName)+'='+Data.QuoteValue(aIdent+'*'))+') OR ('+Data.ProcessTerm(Data.QuoteField('MATCHCODE')+'='+Data.QuoteValue(aIdent+'*'))+')';
      Open;
      Result := Count > 0;
    end;
end;
function TMDPos.GetCurrency: string;
begin
  Result:=Masterdata.FieldByName('CURRENCY').AsString;
end;

procedure TMDPos.PosPriceChanged(aPosDiff, aGrossDiff: Extended);
begin
  //TODO: Implement me (Einkaufspreis anpassen)
end;
procedure TMDPos.PosWeightChanged(aPosDiff: Extended);
begin
  if not ((Masterdata.DataSet.State = dsEdit) or (Masterdata.DataSet.State = dsInsert)) then
    Masterdata.DataSet.Edit;
  Masterdata.FieldByName('WEIGHT').AsFloat := Masterdata.FieldByName('WEIGHT').AsFloat+aPosDiff;
end;
constructor TMDPos.Create(aOwner: TComponent; DM : TComponent;aConnection: TComponent;
  aMasterdata: TDataSet);
begin
  inherited Create(aOwner, DM,aConnection, aMasterdata);
end;
procedure TMDPos.DefineFields(aDataSet: TDataSet);
begin
  inherited DefineFields(aDataSet);
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'MDPOSITIONS';
    end;
end;
function TMasterdataList.GetMatchCodeFieldName: string;
begin
  Result:='MATCHCODE';
end;
function TMasterdataList.GetTextFieldName: string;
begin
  Result:='SHORTTEXT';
end;
function TMasterdataList.GetNumberFieldName: string;
begin
  Result:='ID';
end;
function TMasterdataList.GetStatusFieldName: string;
begin
  Result:='STATUS';
end;
constructor TMasterdataList.Create(aOwner: TComponent; DM: TComponent;
  aConnection: TComponent; aMasterdata: TDataSet);
begin
  inherited Create(aOwner, DM, aConnection, aMasterdata);
  with BaseApplication as IBaseDbInterface do
    begin
      with DataSet as IBaseDBFilter do
        begin
          UsePermissions:=True;
        end;
    end;
end;
procedure TMasterdataList.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'MASTERDATA';
      TableCaption := strMasterdata;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('TYPE',ftString,1,True);
            Add('ID',ftString,40,True);
            Add('VERSION',ftString,8,False);
            Add('LANGUAGE',ftString,3,False);
            Add('STATUS',ftString,4,false);
            Add('BARCODE',ftString,20,False);
            Add('MATCHCODE',ftString,20,False);
            Add('SHORTTEXT',ftString,100,False);
            Add('TREEENTRY',ftLargeint,0,True);
            Add('QUANTITYU',ftString,10,False);//Mengeneinheit
            Add('VAT',ftString,1,True);        //Mehrwertsteuer
            Add('USESERIAL',ftString,1,False);
            Add('OWNPROD',ftString,1,False);
            Add('SALEITEM',ftString,1,False);
            Add('USEBATCH',ftString,1,False);
            Add('NOSTORAGE',ftString,1,False);
            Add('PTYPE',ftString,1,False);
            Add('WEIGHT',ftFloat,0,False);
            Add('UNIT',ftInteger,0,False);     //Verpackungseinheit
            Add('WARRENTY',ftString,10,False);
            Add('MANUFACNR',ftString,20,False);
            Add('VALIDFROM',ftDate,0,False);   //Ein/Auslaufsteuerung
            Add('VALIDTO',ftDate,0,False);     //gültig bis Datum
            Add('VALIDTOME',ftInteger,0,False);//gültig bis Menge
            Add('COSTCENTRE',ftString,10,False);//Kostenstelle
            Add('ACCOUNT',ftString,10,False);
            Add('CATEGORY',ftString,60,False);
            Add('CURRENCY',ftString,5,False);
            Add('CRDATE',ftDate,0,False);
            Add('CHDATE',ftDate,0,False);
            Add('CHANGEDBY',ftString,4,False);
            Add('CREATEDBY',ftString,4,true);
            Add('ACTIVE',ftString,1,True);
          end;
      if Assigned(ManagedIndexdefs) then
        with ManagedIndexDefs do
          begin
            Add('ID','TYPE;ID;VERSION;LANGUAGE',[ixUnique]);
            Add('BARCODE','BARCODE',[]);
            Add('SHORTTEXT','SHORTTEXT',[]);
          end;
      DefineUserFields(aDataSet);
    end;
  with aDataSet as IBaseDbFilter, BaseApplication as IBaseDbInterface do
    BaseFilter := Data.QuoteField('ACTIVE')+'='+Data.QuoteValue('Y');
end;
procedure TMasterdataList.Select(aID: string);
begin
  with BaseApplication as IBaseDbInterface do
    begin
      with DataSet as IBaseDBFilter do
        begin
          Filter := Data.ProcessTerm(Data.QuoteField('ID')+'='+Data.QuoteValue(aID));
        end;
    end;
end;
procedure TMasterdataList.Select(aID: string; aVersion: Variant; aLanguage: Variant
  );
begin
  with BaseApplication as IBaseDbInterface do
    begin
      with DataSet as IBaseDBFilter do
        begin
          Filter := '('
                   +Data.ProcessTerm(Data.QuoteField('ID')+'='+Data.QuoteValue(aID))+' and '
                   +Data.ProcessTerm(Data.QuoteField('VERSION')+'='+VarToStr(aVersion))+' and '
                   +Data.ProcessTerm(Data.QuoteField('LANGUAGE')+'='+VarToStr(aLanguage))+')';
        end;
    end;
end;
procedure TMasterdataList.SelectFromLink(aLink: string);
var
  tmp1: String;
  tmp2: String;
  tmp3: String;
  tmp2v : Variant;
  tmp3v : Variant;
begin
  inherited SelectFromLink(aLink);
  tmp2v := Null;
  tmp3v := Null;
  if not (copy(aLink,0,pos('@',aLink)-1) = 'MASTERDATA') then exit;
  if rpos('{',aLink) > 0 then
    aLink := copy(aLink,0,rpos('{',aLink)-1)
  else if rpos('(',aLink) > 0 then
    aLink := copy(aLink,0,rpos('(',aLink)-1);
  aLink   := copy(aLink, pos('@', aLink) + 1, length(aLink));
  tmp1 := copy(aLink, 0, pos('&&', aLink) - 1);
  aLink   := copy(aLink, pos('&&', aLink) + 2, length(aLink));
  tmp2 := copy(aLink, 0, pos('&&', aLink) - 1);
  aLink   := copy(aLink, pos('&&', aLink) + 2, length(aLink));
  tmp3 := aLink;
  if tmp2 <> '' then tmp2v := tmp2;
  if tmp3 <> '' then tmp3v := tmp3;
  Select(tmp1,tmp2v,tmp3v);
end;
initialization
end.

