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
unit uBaseSearch;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, uBaseDBClasses,uIntfStrConsts,variants,db;
resourcestring
  strMatchcode                  = 'Suchbegriffe';
  strShortnames                 = 'Kurztexte';
  strIdents                     = 'Idents';
  strFulltext                   = 'Volltext';
const
  SearchLocations : array[0..7] of string  = (strMatchcode,strIdents,strShortnames,strSerial,strCommission,strBarcode,strDescription,strFulltext);
  SearchLocDefault: array[0..7] of Boolean = (True        ,True     ,True         ,True     ,True         ,True      ,True         ,False);
type
  TSearchLocations = array of string;
  TFullTextSearchType = (fsMatchcode=0,fsIdents=1,fsShortnames=2,fsSerial=3,fsCommission=4,fsBarcode=5,fsDescription=6,fsFulltext=7);
  TFullTextSearchTypes = set of TFullTextSearchType;
  TSearchResultItem= procedure(aIdent : string;aName : string;aStatus : string;aActive : Boolean;aLink : string;aItem : TBaseDBList = nil) of object;
  TSearch = class(TComponent)
  private
    FActive: Boolean;
    FBeginSearch: TNotifyEvent;
    FCount: Integer;
    FEndSearch: TNotifyEvent;
    FFullEndSearch: TNotifyEvent;
    FItemFound: TSearchResultItem;
    FSearchTypes: TFullTextSearchTypes;
    FSearchLocations: TSearchLocations;
    FSender: TComponent;
    FUseContains: Boolean;
    FMaxResults: LongInt;
    Lists : array of TBaseDBList;
  public
    constructor Create(aSearchTypes : TFullTextSearchTypes;aSearchLocations : TSearchLocations;aUseContains : Boolean = False;aMaxresults : Integer = 0);
    destructor Destroy;override;
    procedure Start(SearchText: string; SearchUnsharp: Boolean=True);
    procedure Abort;
    property Active : Boolean read FActive;
    property OnBeginItemSearch : TNotifyEvent read FBeginSearch write FBeginSearch;
    property OnItemFound : TSearchResultItem read FItemFound write FItemFound;
    property OnEndItemSearch : TNotifyEvent read FEndSearch write FEndSearch;
    property OnEndSearch : TNotifyEvent read FFullEndSearch write FFullEndSearch;
    property Sender : TComponent read FSender write FSender;
    property Count : Integer read FCount;
  end;
  TLinkObject = class(TObject)
  private
    FLink: string;
  public
    constructor Create(aLink : string);
    property Link : string read FLink write FLink;
  end;
  procedure AddSearchAbleDataSet(aClass : TBaseDBListClass);
  function GetSearchAbleItems : TSearchLocations;
implementation
uses uBaseApplication, uBaseDbInterface,uOrder;
var SearchAble : array of TBaseDBListClass;
procedure AddSearchAbleDataSet(aClass: TBaseDBListClass);
begin
  Setlength(SearchAble,length(SearchAble)+1);
  SearchAble[length(SearchAble)-1] := aClass;
end;
function GetSearchAbleItems: TSearchLocations;
var
  aSearchAble: TBaseDbList;
  i: Integer;
begin
  for i := 0 to length(SearchAble)-1 do
    begin
      with BaseApplication as IBaseDBInterface do
        aSearchAble := SearchAble[i].Create(nil,Data);
      Setlength(Result,length(Result)+1);
      Result[length(Result)-1] := aSearchAble.Caption;
      aSearchAble.Free;
    end;
end;
constructor TLinkObject.Create(aLink: string);
begin
  FLink := aLink;
end;
constructor TSearch.Create(aSearchTypes: TFullTextSearchTypes; aSearchLocations: TSearchLocations;
  aUseContains: Boolean; aMaxresults: Integer);
var
  i: Integer;
  a: Integer;
  aSearchAble: TBaseDbList;
  Found: Boolean;
begin
  SetLength(Lists,0);
  FSearchTypes := aSearchTypes;
  FSearchLocations := aSearchLocations;
  FUseContains := aUseContains;
  FMaxResults := aMaxResults;
  with BaseApplication as IBaseDBInterface do
    begin
      for i := 0 to length(SearchAble)-1 do
        begin
          aSearchAble := SearchAble[i].Create(nil,Data);
          Found := False;
          for a := 0 to length(FSearchLocations)-1 do
            begin
              if FSearchLocations[a] = aSearchAble.Caption then
                begin
                  Setlength(Lists,length(Lists)+1);
                  Lists[length(Lists)-1] := aSearchAble;
                  aSearchable.CreateTable;
                  Found := True;
                  break;
                end
            end;
          if not Found then
            aSearchAble.Free;
        end;
    end;
end;
destructor TSearch.Destroy;
var
  i: Integer;
begin
  for i := 0 to length(Lists)-1 do
    Lists[i].Free;
  inherited Destroy;
end;
procedure TSearch.Start(SearchText : string;SearchUnsharp : Boolean = True);
  function EncodeField(Data : TBaseDBModule;Val : string) : string;
  begin
    Result := 'UPPER('+Data.QuoteField(Val)+')';
  end;

  function EncodeValue(Data : TBaseDBModule;Val : string) : string;
  begin
    if FUseContains and SearchUnsharp then
      Result := Data.QuoteValue('*'+Data.EscapeString(Val)+'*')
    else
      Result := Data.QuoteValue(Data.EscapeString(Val));
    Result := 'UPPER('+Result+')';
  end;

  function CastText(Data : TBaseDBModule;Val : string) : string;
  begin
    Result := 'UPPER(CAST('+Data.QuoteField(Val)+' as VARCHAR(1000)))';
  end;
var
  i: Integer;
  aFilter: String;
  tmp: String;
  aType: TFullTextSearchType;
  aActive: Boolean;
  aPos: TOrderPos;
  aOrder: TOrder;
begin
  if not Assigned(FItemFound) then exit;
  FActive := True;
  FCount := 0;
  with BaseApplication as IBaseDBInterface do
    begin
      //Search for registered Searchtytpes
      for i := 0 to length(Lists)-1 do
        begin
          if Assigned(FBeginSearch) then FBeginSearch(Self);
          aFilter := '';
          tmp := Lists[i].Caption;
          with Lists[i].DataSet as IBaseDbFilter do
            begin
              for aType := low(TFullTextSearchTypes) to High(TFullTextSearchTypes) do
                begin
                  aFilter := '';
                  if not FActive then
                    begin
                      if Assigned(FEndSearch) then FEndSearch(Self);
                      break;
                    end;
                  if (aType = fsMatchcode) and (fsMatchcode in FSearchTypes) and (Lists[i].GetMatchcodeFieldName <> '') then
                    aFilter += ' OR ('+Data.ProcessTerm(EncodeField(Data,Lists[i].GetMatchcodeFieldName)+' = '+EncodeValue(Data,SearchText))+')';
                  if (aType = fsIdents) and (fsIdents in FSearchTypes) then
                    begin
                      aFilter += ' OR ('+Data.ProcessTerm(CastText(Data,Lists[i].GetNumberFieldName)+' = '+EncodeValue(Data,SearchText))+')';
                      if Lists[i].GetBookNumberFieldName <> '' then
                        aFilter += ' OR ('+Data.ProcessTerm(CastText(Data,Lists[i].GetBookNumberFieldName)+' = '+EncodeValue(Data,SearchText))+')';
                    end;
                  if (aType = fsBarcode) and (fsBarcode in FSearchTypes) and (Lists[i].GetBarcodeFieldName <> '') then
                    aFilter += ' OR ('+Data.ProcessTerm(CastText(Data,Lists[i].GetBarcodeFieldName)+' = '+EncodeValue(Data,SearchText))+')';
                  if (aType = fsCommission) and (fsCommission in FSearchTypes) and (Lists[i].GetCommissionFieldName <> '') then
                    aFilter += ' OR ('+Data.ProcessTerm(EncodeField(Data,Lists[i].GetCommissionFieldName)+' = '+EncodeValue(Data,SearchText))+')';
                  if SearchUnsharp then
                    begin
                      if (aType = fsShortnames) and (aType = fsShortnames) and (fsShortnames in FSearchTypes) then
                        aFilter += ' OR ('+Data.ProcessTerm(CastText(Data,Lists[i].GetTextFieldName)+' = '+EncodeValue(Data,SearchText))+')';
                      if (aType = fsDescription) and (fsDescription in FSearchTypes) and (Lists[i].GetDescriptionFieldName <> '') then
                        aFilter += ' OR ('+Data.ProcessTerm(CastText(Data,Lists[i].GetDescriptionFieldName)+' = '+EncodeValue(Data,SearchText))+')';
                      if Lists[i] is TBaseHistory then
                        aFilter += ' AND (('+Data.ProcessTerm(Data.QuoteField('OBJECT')+'='+Data.QuoteValue('PROJECTS@*'))+') OR ('+Data.ProcessTerm(Data.QuoteField('OBJECT')+'='+Data.QuoteValue('MASTERDATA@*'))+'))';
                    end;
                  aFilter := copy(aFilter,pos(' ',aFilter)+1,length(aFilter));
                  aFilter := copy(aFilter,pos(' ',aFilter)+1,length(aFilter));
                  if aFilter <> '' then
                    begin
                      SortFields:='';
                      Filter := aFilter;
                      Limit := FMaxResults;
                      FetchRows:=1;
                      Lists[i].Open;
                      if Assigned(Lists[i].Status) then
                        Data.SetFilter(Data.States,Data.QuoteField('TYPE')+'='+Data.QuoteValue(Lists[i].Typ));
                      while not Lists[i].DataSet.EOF do
                        begin
                          if Assigned(Lists[i].Status) then
                            begin
                              aActive := Data.States.DataSet.Locate('STATUS',Lists[i].Status.AsString,[loCaseInsensitive]);
                              if aActive then
                                begin
                                  aActive := aActive and (Data.States.FieldByName('ACTIVE').AsString='Y');
                                  FItemFound(Lists[i].Number.AsString,Lists[i].Text.AsString,Lists[i].Status.AsString,aActive,Data.BuildLink(Lists[i].DataSet),Lists[i])
                                end
                              else
                                FItemFound(Lists[i].Number.AsString,Lists[i].Text.AsString,Lists[i].Status.AsString,True,Data.BuildLink(Lists[i].DataSet),Lists[i]);
                            end
                          else
                            FItemFound(Lists[i].Number.AsString,Lists[i].Text.AsString,'',True,Data.BuildLink(Lists[i].DataSet),Lists[i]);
                          inc(FCount);
                          if not FActive then break;
                          Lists[i].DataSet.Next;
                        end;
                    end;
                end;
            end;
          if Assigned(FEndSearch) then FEndSearch(Self);
        end;
      //Search for Serial Number
      if fsSerial in FSearchTypes then
        begin
          aPos := TOrderPos.Create(nil,Data);
          try
            Data.SetFilter(aPos,Data.QuoteField('SERIAL')+'='+Data.QuoteValue(SearchText),FMaxResults);
            while not aPos.EOF do
              begin
                aOrder := Torder.Create(nil,Data);
                aOrder.Select(aPos.FieldByName('REF_ID').AsVariant);
                aOrder.Open;
                if aOrder.Count>0 then
                  FItemFound(aOrder.Number.AsString,aOrder.Text.AsString,aOrder.Status.AsString,True,Data.BuildLink(aOrder.DataSet),aOrder);
                aOrder.Free;
                aPos.Next;
              end;
          except  //maybe table dont exists
          end;
          aPos.Free;
        end;

    end;
  if Assigned(FFullEndSearch) then FFullEndSearch(Self);
  FActive := False;
end;
procedure TSearch.Abort;
begin
  FActive := False;
end;
finalization
  Setlength(SearchAble,0);
end.

