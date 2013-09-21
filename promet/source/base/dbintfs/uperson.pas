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
unit uPerson;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, db, uBaseDbClasses, uBaseERPDBClasses, uIntfStrConsts;
type

  { TPersonList }

  TPersonList = class(TBaseERPList)
  public
    function GetMatchCodeFieldName: string;override;
    function GetTextFieldName: string;override;
    function GetNumberFieldName : string;override;
    function GetStatusFieldName : string;override;
    function GetTyp: string; override;
    constructor Create(aOwner: TComponent; DM: TComponent;
       aConnection: TComponent=nil; aMasterdata: TDataSet=nil); override;
    procedure DefineFields(aDataSet : TDataSet);override;
    procedure SelectByAccountNo(aAccountNo : string);overload;
  end;
  TPersonHistory = class(TBaseHistory)
  end;
  TBaseDbAddress = class(TBaseDBList)
  public
    procedure DefineFields(aDataSet : TDataSet);override;
    procedure Assign(Source: TPersistent); override;
    procedure FillDefaults(aDataSet : TDataSet);override;
    function ToString: ansistring;override;
    procedure FromString(aStr : AnsiString);
  end;
  TPerson = class;
  TPersonAddress = class(TBaseDBAddress)
  public
    procedure DefineFields(aDataSet : TDataSet);override;
    procedure FillDefaults(aDataSet : TDataSet);override;
    function GetTextFieldName: string;override;
    function GetNumberFieldName : string;override;
    function GetDescriptionFieldName : string;override;
  end;
  TPersonContactData = class(TBaseDBList)
  public
    procedure DefineFields(aDataSet : TDataSet);override;
    procedure FillDefaults(aDataSet : TDataSet);override;
    function GetNumberFieldName : string;override;
    function GetTextFieldName: string;override;
  end;
  TPersonBanking = class(TBaseDBDataSet)
  public
    procedure DefineFields(aDataSet : TDataSet);override;
  end;
  TPersonLinks = class(TLinks)
  public
    procedure FillDefaults(aDataSet : TDataSet);override;
  end;
  TPersonEmployees = class(TBaseDbDataSet)
  public
    procedure DefineFields(aDataSet : TDataSet);override;
  end;
  TPerson = class(TPersonList,IBaseHistory)
    procedure FDSDataChange(Sender: TObject; Field: TField);
  private
    FBanking: TPersonBanking;
    FCustomerCont: TPersonContactData;
    FEmployees: TPersonEmployees;
    FHistory: TPersonHistory;
    FImages: TImages;
    FLinks: TPersonLinks;
    FPersonAddress: TPersonAddress;
    FSTatus : string;
    FDS : TDataSource;
    FStateChange: TNotifyEvent;
    function GetHistory: TBaseHistory;
  public
    constructor Create(aOwner : TComponent;DM : TComponent;aConnection : TComponent = nil;aMasterdata : TDataSet = nil);override;
    destructor Destroy;override;
    procedure Open; override;
    function CreateTable : Boolean;override;
    procedure CascadicPost;override;
    procedure CascadicCancel;override;
    procedure FillDefaults(aDataSet : TDataSet);override;
    function Find(aIdent : string;Unsharp : Boolean = False) : Boolean;override;
    property Address : TPersonAddress read FPersonAddress;
    property CustomerCont : TPersonContactData read FCustomerCont;
    property History : TPersonHistory read FHistory;
    property Images : TImages read FImages;
    property Banking : TPersonBanking read FBanking;
    property Links : TPersonLinks read FLinks;
    property Employees : TPersonEmployees read FEmployees;
    procedure SelectFromLink(aLink : string);override;
    property OnStateChange : TNotifyEvent read FStateChange write FStateChange;
  end;

implementation
uses uBaseDBInterface, uBaseSearch, uBaseApplication, uData, Utils;
procedure TPersonEmployees.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'EMPLOYEES';
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('EMPLOYEE',ftString,20,True);
            Add('NAME',ftString,40,True);
            Add('DEPARTMENT',ftString,30,False);
            Add('POSITION',ftString,30,False);
          end;
    end;
end;
procedure TPersonLinks.FillDefaults(aDataSet: TDataSet);
begin
  inherited FillDefaults(aDataSet);
  aDataSet.FieldByName('RREF_ID').AsVariant:=(Parent as TPerson).Id.AsVariant;
end;
procedure TPersonBanking.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'CUSTOMERBANKING';
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('SORTCODE',ftString,8,False);
            Add('ACCOUNT',ftString,10,False);
            Add('INSTITUTE',ftString,40,false);
          end;
    end;
end;
procedure TPersonContactData.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'CUSTOMERCONT';
      TableCaption := strCustomerCont;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('ACCOUNTNO',ftString,20,True);
            Add('DESCR',ftString,30,False);
            Add('TYPE',ftString,4,False);
            Add('DATA',ftString,80,False);
            Add('LINK',ftString,200,False);
            Add('ACTIVE',ftString,1,False);
          end;
    end;
end;
procedure TPersonContactData.FillDefaults(aDataSet: TDataSet);
begin
  with aDataSet,BaseApplication as IBaseDBInterface do
    begin
      if DataSet.FieldDefs.IndexOf('ACCOUNTNO') > -1 then
        FieldByName('ACCOUNTNO').AsString := TPerson(Parent).FieldByName('ACCOUNTNO').AsString;
    end;
end;

function TPersonContactData.GetNumberFieldName: string;
begin
  Result := 'LINK';
end;

function TPersonContactData.GetTextFieldName: string;
begin
  Result := 'DATA';
end;
procedure TPersonAddress.DefineFields(aDataSet: TDataSet);
begin
  inherited DefineFields(aDataSet);
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'ADDRESSES';
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('ADDRNO',ftString,2,True);
            Add('DESCR',ftString,30,False);
            Add('ACTIVE',ftString,1,False);
          end;
    end;
end;
procedure TPersonAddress.FillDefaults(aDataSet: TDataSet);
begin
  inherited FillDefaults(aDataSet);
  with aDataSet,BaseApplication as IBaseDBInterface do
    begin
      if DataSet.FieldDefs.IndexOf('ACCOUNTNO') > -1 then
        FieldByName('ACCOUNTNO').AsString := TPerson(Parent).FieldByName('ACCOUNTNO').AsString;
      FieldByName('ADDRNO').AsInteger := DataSet.RecordCount+1;
      FieldByName('COUNTRY').AsString := UpperCase(TPerson(Parent).FieldByName('LANGUAGE').AsString);
    end;
end;
function TPersonAddress.GetTextFieldName: string;
begin
  Result := 'NAME';
end;
function TPersonAddress.GetNumberFieldName: string;
begin
  Result := 'ZIP';
end;
function TPersonAddress.GetDescriptionFieldName: string;
begin
  Result:= 'ADDRESS';
end;
procedure TBaseDbAddress.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableCaption := strAdresses;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('TYPE',ftString,3,True);
            Add('TITLE',ftString,8,False);
            Add('NAME',ftString,200,false);
            Add('CNAME',ftString,30,false);
            Add('ADDITIONAL',ftString,200,False);
            Add('ADDRESS',ftMemo,0,False);
            Add('CITY',ftString,30,False);
            Add('ZIP',ftString,8,False);
            Add('STATE',ftString,30,False);
            Add('COUNTRY',ftString,3,False);
            Add('POBOX',ftInteger,0,False);
          end;
    end;
end;
procedure TBaseDbAddress.Assign(Source: TPersistent);
var
  Address: TBaseDbAddress;
  Person: TPerson;
begin
  if Source is TBaseDBAddress then
    begin
      if (DataSet.State <> dsInsert) and (DataSet.State <> dsEdit) then
        DataSet.Edit;
      Address := Source as TBaseDbAddress;
      DataSet.FieldByName('TITLE').AsString := Address.FieldByName('TITLE').AsString;
      DataSet.FieldByName('NAME').AsString := Address.FieldByName('NAME').AsString;
      DataSet.FieldByName('ADDITIONAL').AsString := Address.FieldByName('ADDITIONAL').AsString;
      DataSet.FieldByName('ADDRESS').AsString := Address.FieldByName('ADDRESS').AsString;
      DataSet.FieldByName('CITY').AsString := Address.FieldByName('CITY').AsString;
      DataSet.FieldByName('ZIP').AsString := Address.FieldByName('ZIP').AsString;
      DataSet.FieldByName('STATE').AsString := Address.FieldByName('STATE').AsString;
      DataSet.FieldByName('COUNTRY').AsString := Address.FieldByName('COUNTRY').AsString;
    end
  else if Source is TPerson then
    begin
      Self.Assign(Tperson(Source).Address);
      Person := Source as TPerson;
      if (DataSet.State <> dsInsert) and (DataSet.State <> dsEdit) then
        DataSet.Edit;
      DataSet.FieldByName('ACCOUNTNO').AsString := Person.FieldByName('ACCOUNTNO').AsString;
    end
  else
    inherited Assign(Source);
end;

procedure TBaseDbAddress.FillDefaults(aDataSet: TDataSet);
begin
  with aDataSet,BaseApplication as IBaseDBInterface do
    begin
      if aDataSet.RecordCount = 0 then
        DataSet.FieldByName('TYPE').AsString:='IAD'
      else
        DataSet.FieldByName('TYPE').AsString:='DAD';
    end;
end;
function TBaseDbAddress.ToString: ansistring;
var
  aAddress : TStringList;
begin
  aAddress := TStringList.Create;
  aAddress.Add(DataSet.FieldbyName('TITLE').AsString);
  if aAddress[aAddress.Count-1] = '' then aAddress.Delete(aAddress.Count-1);
  aAddress.Add(DataSet.FieldbyName('CNAME').AsString+' ');
  if aAddress[aAddress.Count-1] = ' ' then aAddress[aAddress.Count-1] := '';
  aAddress[aAddress.Count-1] := aAddress[aAddress.Count-1]+DataSet.FieldbyName('NAME').AsString;
  if DataSet.FieldbyName('ADDITIONAL').AsString <> '' then
    aAddress.Add(DataSet.FieldbyName('ADDITIONAL').AsString);
  aAddress.Add(DataSet.FieldbyName('ADDRESS').AsString);
  aAddress.Add(DataSet.FieldbyName('COUNTRY').AsString+' ');
  if aAddress[aAddress.Count-1] = ' ' then aAddress[aAddress.Count-1] := '';
  aAddress[aAddress.Count-1] := aAddress[aAddress.Count-1]+DataSet.FieldbyName('ZIP').AsString+' ';
  if aAddress[aAddress.Count-1] = ' ' then aAddress[aAddress.Count-1] := '';
  aAddress[aAddress.Count-1] := aAddress[aAddress.Count-1]+DataSet.FieldbyName('CITY').AsString+' ';
  while (aAddress.Count > 0) and (trim(aAddress[aAddress.Count-1]) = '') do aAddress.Delete(aAddress.Count-1);
  Result := aAddress.Text;
  aAddress.Free;
end;
procedure TBaseDbAddress.FromString(aStr: AnsiString);
var
  Addr: TStringList;
  tmp: String;
  i: Integer;
  tmp1: String;
  function CountPos(const subtext: string; Text: string): Integer;
  begin
    if (Length(subtext) = 0) or (Length(Text) = 0) or (Pos(subtext, Text) = 0) then
      Result := 0
    else
      Result := (Length(Text) - Length(StringReplace(Text, subtext, '', [rfReplaceAll]))) div
        Length(subtext);
  end;
  function HasTitle(aTitle : string) : Boolean;
  begin
    Result :=
       (lowercase(copy(Addr[0],0,length(aTitle)+1)) = aTitle+#10)
    or (lowercase(copy(Addr[0],0,length(aTitle)+1)) = aTitle+#13)
    or (lowercase(copy(Addr[0],0,length(aTitle)+1)) = aTitle+' ')
    or (lowercase(copy(Addr[0],0,length(aTitle)+1)) = aTitle+'.');
  end;
begin
  Addr := TStringList.Create;
  tmp := StringReplace(aStr,',',lineending,[rfReplaceAll]);
  Addr.Text := tmp;
  if (Addr.Count = 0) then exit;
  //Delete clear lines
  i := 0;
  while i < Addr.Count do
    if Addr[i] = '' then
      Addr.Delete(i)
    else
      inc(i);
  if (Addr.Count = 0) then
    begin
      Addr.Free;
      exit;
    end;
  //Check and Remove for Contact propertys
  i := 0;
  while i < Addr.Count do
    begin
      if (pos('tel ',lowercase(Addr[i])) > 0)
      or (pos('phone ',lowercase(Addr[i])) > 0)
      or (pos('mobile ',lowercase(Addr[i])) > 0)
      or (pos('tel:',lowercase(Addr[i])) > 0)
      or (pos('phone:',lowercase(Addr[i])) > 0)
      or (pos('mobile:',lowercase(Addr[i])) > 0)
      then
        begin
          Addr.Delete(i);
        end
      else if (pos('fax ',lowercase(Addr[i])) > 0)
           or (pos('fax:',lowercase(Addr[i])) > 0) then
        begin
          Addr.Delete(i);
        end
      else if (pos('mail ',lowercase(Addr[i])) > 0)
           or (pos('mail:',lowercase(Addr[i])) > 0)
           then
        begin
          Addr.Delete(i);
        end
      else
        inc(i);
    end;
  //The rest should be the adress
  DataSet.FieldByName('TITLE').Clear;
  if Addr.Count > 0 then
    if HasTitle('firm')
    or HasTitle('herr')
    or HasTitle('frau')
    or HasTitle('mr')
    or HasTitle('dr')
    or HasTitle('prof')
    then
      begin
        DataSet.FieldByName('TITLE').AsString := trim(Addr[0]);
        Addr.Delete(0);
      end;
  if Addr.Count > 0 then
    if HasTitle('dr')
    or HasTitle('prof')
    then
      begin
        Addr.Delete(0);
      end;
  if Addr.Count > 0 then
    begin
      DataSet.FieldByName('NAME').AsString := trim(Addr[0]);
      Addr.Delete(0);
    end;
  DataSet.FieldByName('ADDITIONAL').Clear;
  DataSet.FieldByName('CITY').Clear;
  DataSet.FieldByName('ZIP').Clear;
  DataSet.FieldByName('ADDRESS').Clear;
  i := Addr.Count-1;
  if Addr.Count = 0 then exit;
  while i > 0 do
    begin
      tmp := trim(Addr[i]);
      tmp1 := copy(tmp,pos(' ',tmp)+1,length(tmp));
      if not IsNumeric(copy(tmp1,0,pos(' ',tmp1)-1)) then
        tmp1 := copy(tmp,pos('-',tmp)+1,length(tmp));
      if IsNumeric(copy(trim(tmp),0,pos(' ',trim(tmp))-1)) and (CountPos(' ',tmp) = 1) then
        begin
          DataSet.FieldByName('ZIP').AsString := copy(trim(tmp),0,pos(' ',trim(tmp))-1);
          DataSet.FieldByName('CITY').AsString := copy(trim(tmp),pos(' ',trim(tmp))+1,length(trim(tmp)));
          Addr.Delete(i);
          break;
        end
      else if (CountPos(' ',tmp) = 2)
           and IsNumeric(copy(tmp1,0,pos(' ',tmp1)-1)) then
        begin
          DataSet.FieldByName('ZIP').AsString := copy(tmp1,0,pos(' ',tmp1)-1);
          tmp := copy(tmp,pos(DataSet.FieldByName('ZIP').AsString,tmp)+length(DataSet.FieldByName('ZIP').AsString)+1,length(tmp));
          DataSet.FieldByName('CITY').AsString := tmp;
          Addr.Delete(i);
          break;
        end;
      dec(i);
    end;
  i := Addr.Count-1;
  if i > -1 then
    begin
      DataSet.FieldByName('ADDRESS').AsString := Addr[i];
      Addr.Delete(i);
    end;
  if Addr.Count > 0 then
    DataSet.FieldByName('ADDITIONAL').AsString := Addr[0];
  Addr.Free;
end;
procedure TPerson.FDSDataChange(Sender: TObject; Field: TField);
begin
  if not Assigned(Field) then exit;
  if Field.FieldName = 'STATUS' then
    begin
      History.Open;
      History.AddItem(Self.DataSet,Format(strStatusChanged,[FStatus,Field.AsString]),'','',nil,ACICON_STATUSCH);
      FStatus := Field.AsString;
      if Assigned(FStateChange) then
        FStateChange(Self);
    end;
end;
function TPerson.GetHistory: TBaseHistory;
begin
  Result := History;
end;
constructor TPerson.Create(aOwner: TComponent; DM : TComponent;aConnection: TComponent;
  aMasterdata: TDataSet);
begin
  inherited Create(aOwner, DM,aConnection, aMasterdata);
  with BaseApplication as IBaseDbInterface do
    begin
      with DataSet as IBaseDBFilter do
        begin
          UsePermissions:=False;
        end;
    end;
  FHistory := TPersonHistory.Create(Self,DM,aConnection,DataSet);
  FPersonAddress := TPersonAddress.Create(Self,DM,aConnection,DataSet);
  FCustomerCont := TPersonContactData.Create(Self,DM,aConnection,DataSet);
  FImages := TImages.Create(Self,DM,aConnection,DataSet);
  FBanking := TPersonBanking.Create(Self,DM,aConnection,DataSet);
  FLinks := TPersonLinks.Create(Self,DM,aConnection);
  FEmployees := TPersonEmployees.Create(Self,DM,aConnection,DataSet);
  FDS := TDataSource.Create(Self);
  FDS.DataSet := DataSet;
  FDS.OnDataChange:=@FDSDataChange;
end;
destructor TPerson.Destroy;
begin
  FDS.Free;
  FreeAndNil(FEmployees);
  FreeAndNil(FLinks);
  FreeAndNil(FBanking);
  FreeAndNil(FImages);
  FreeAndNil(FCustomerCont);
  FreeAndNil(FPersonAddress);
  FreeAndNil(FHistory);
  inherited Destroy;
end;

procedure TPerson.Open;
begin
  inherited Open;
  FStatus := Status.AsString;
end;
function TPerson.CreateTable : Boolean;
begin
  Result := inherited CreateTable;
  FHistory.CreateTable;
  FPersonAddress.CreateTable;
  FCustomerCont.CreateTable;
  FBanking.CreateTable;
  FLinks.CreateTable;
  FEmployees.CreateTable;
end;
procedure TPerson.FillDefaults(aDataSet: TDataSet);
begin
  with aDataSet,BaseApplication as IBaseDBInterface do
    begin
      FieldByName('ACCOUNTNO').AsString := Data.Numbers.GetNewNumber('CUSTOMERS');
      FieldByName('TYPE').AsString      := 'C';
      FieldByName('DISCOUNT').AsFloat   := 0;
      FieldByName('TREEENTRY').AsVariant := TREE_ID_CUSTOMER_UNSORTED;
      FieldByName('CRDATE').AsDateTime  := Date;
      FieldByName('CREATEDBY').AsString := Data.Users.FieldByName('IDCODE').AsString;
      FieldByName('CHANGEDBY').AsString := Data.Users.FieldByName('IDCODE').AsString;
      if Data.Currency.DataSet.Active and Data.Currency.DataSet.Locate('DEFAULTCUR', 'Y', []) then
        FieldByName('CURRENCY').AsString := Data.Currency.FieldByName('SYMBOL').AsString;
      if Data.Languages.DataSet.Active and Data.Languages.DataSet.Locate('DEFAULTLNG', 'Y', []) then
        FieldByName('LANGUAGE').AsString := Data.Languages.FieldByName('ISO6391').AsString;

    end;
end;
function TPerson.Find(aIdent: string;Unsharp : Boolean = False): Boolean;
begin
  with DataSet as IBaseDbFilter,BaseApplication as IBaseDbInterface do
    Filter := '('+Data.QuoteField(GetNumberFieldName)+'='+Data.QuoteValue(aIdent)+') OR ('+Data.QuoteField(GetTextFieldName)+'='+Data.QuoteValue(aIdent)+')';
  Open;
  Result := Count > 0;
  if (not Result) and Unsharp then
    begin
      with DataSet as IBaseDbFilter,BaseApplication as IBaseDbInterface do
        Filter := '('+Data.ProcessTerm(Data.QuoteField(GetNumberFieldName)+'='+Data.QuoteValue(aIdent+'*'))+') OR ('+Data.ProcessTerm(Data.QuoteField(GetTextFieldName)+'='+Data.QuoteValue(aIdent+'*'))+')';
      Open;
      Result := Count > 0;
    end;
end;
procedure TPerson.SelectFromLink(aLink: string);
begin
  inherited SelectFromLink(aLink);
  if (not (copy(aLink,0,pos('@',aLink)-1) = 'CUSTOMERS'))
  and (not (copy(aLink,0,pos('@',aLink)-1) = 'CUSTOMERS.ID')) then exit;
  if rpos('{',aLink) > 0 then
    aLink := copy(aLink,0,rpos('{',aLink)-1)
  else if rpos('(',aLink) > 0 then
    aLink := copy(aLink,0,rpos('(',aLink)-1);
  if (copy(aLink,0,pos('@',aLink)-1) = 'CUSTOMERS') then
    begin
      with DataSet as IBaseDBFilter do
        Filter := Data.QuoteField('ACCOUNTNO')+'='+Data.QuoteValue(copy(aLink,pos('@',aLink)+1,length(aLink)));
    end
  else
    begin
      Select(copy(aLink,pos('@',aLink)+1,length(aLink)));
    end;
end;
procedure TPerson.CascadicPost;
begin
  FHistory.CascadicPost;
  FPersonAddress.CascadicPost;
  FCustomerCont.CascadicPost;
  FImages.CascadicPost;
  FBanking.CascadicPost;
  FLinks.CascadicPost;
  inherited CascadicPost;
end;
procedure TPerson.CascadicCancel;
begin
  FHistory.CascadicCancel;
  FPersonAddress.CascadicCancel;
  FCustomerCont.CascadicCancel;
  FImages.CascadicCancel;
  FBanking.CascadicCancel;
  FLinks.CascadicCancel;
  inherited CascadicCancel;
end;
function TPersonList.GetMatchCodeFieldName: string;
begin
  Result:='MATCHCODE';
end;
function TPersonList.GetTextFieldName: string;
begin
  Result:='NAME';
end;
function TPersonList.GetNumberFieldName: string;
begin
  Result:='ACCOUNTNO';
end;
function TPersonList.GetStatusFieldName: string;
begin
  Result:='STATUS';
end;

function TPersonList.GetTyp: string;
begin
  Result := 'C';
end;

constructor TPersonList.Create(aOwner: TComponent; DM: TComponent;
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
procedure TPersonList.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'CUSTOMERS';
      TableCaption := strCustomers;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('ACCOUNTNO',ftString,20,True);
            Add('MATCHCODE',ftString,20,False);
            Add('STATUS',ftString,4,false);
            Add('NAME',ftString,200,False);
            Add('TREEENTRY',ftLargeInt,0,True);
            Add('DISCOUNT',ftFloat,0,False);
            Add('DISCOUNTGR',ftString,2,False);
            Add('DEFPRICE',ftString,2,False);
            Add('LANGUAGE',ftString,3,False);
            Add('CURRENCY',ftString,5,False);
            Add('EACCOUNT',ftString,20,False);
            Add('PAYMENTTAR',ftString,2,False);
            Add('TYPE',ftString,1,True);
            Add('INFO',ftMemo,0,False);
            Add('CATEGORY',ftString,60,False);
            Add('CRDATE',ftDate,0,False);
            Add('CHDATE',ftDate,0,False);
            Add('CREATEDBY',ftString,4,True);
            Add('CHANGEDBY',ftString,4,False);
          end;
      if Assigned(ManagedIndexdefs) then
        with ManagedIndexDefs do
          begin
            Add('ACCOUNTNO','ACCOUNTNO',[ixUnique]);
            Add('MATCHCODE','MATCHCODE',[]);
            Add('NAME','NAME',[]);
          end;
      DefineUserFields(aDataSet);
    end;
end;
procedure TPersonList.SelectByAccountNo(aAccountNo: string);
begin
  with BaseApplication as IBaseDbInterface do
    begin
      with DataSet as IBaseDBFilter do
        begin
          Filter := Data.ProcessTerm(Data.QuoteField('ACCOUNTNO')+'='+Data.QuoteValue(aAccountNo));
        end;
    end;
end;
initialization
end.