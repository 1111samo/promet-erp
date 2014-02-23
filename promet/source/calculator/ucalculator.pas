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
Created 22.02.2014
*******************************************************************************}
unit ucalculator;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, DBGrids,
  Buttons, Menus, ActnList, XMLPropStorage, StdCtrls, Utils, uIntfStrConsts, db,
  memds, FileUtil, SynEdit, SynMemo, SynHighlighterSQL, Translations, md5,
  ComCtrls, ExtCtrls, DbCtrls, Grids, uSystemMessage,ucalc;
type

  { TfMain }

  TfMain = class(TForm)
    acLogin: TAction;
    acLogout: TAction;
    acDeleteEnviroment: TAction;
    ActionList1: TActionList;
    cbEnviroment: TComboBox;
    Enviroment: TDatasource;
    Label1: TLabel;
    MainMenu: TMainMenu;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    miLanguage: TMenuItem;
    miMandant: TMenuItem;
    miOptions: TMenuItem;
    Output: TSynMemo;
    Input: TSynMemo;
    SpeedButton1: TSpeedButton;
    SynSQLSyn1: TSynSQLSyn;
    procedure acDeleteEnviromentExecute(Sender: TObject);
    procedure acLoginExecute(Sender: TObject);
    procedure acLogoutExecute(Sender: TObject);
    procedure cbEnviromentExit(Sender: TObject);
    procedure cbEnviromentSelect(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure InputKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { private declarations }
  public
    { public declarations }
    CalcEnviroment : TCalcEnviroments;
    procedure DoCreate;
  end;
var
  fMain: TfMain;
implementation
uses uBaseApplication, uData, uBaseDbInterface, uOrder,uStatistic,LCLType,
  MathParser;
procedure TfMain.DoCreate;
begin
  with Application as IBaseApplication do
    begin
      SetConfigName('Calculator');
    end;
  with Application as IBaseDbInterface do
    LoadMandants;
end;
procedure TfMain.acLoginExecute(Sender: TObject);
begin
  with Application as IBaseApplication do
    if not Login then
      begin
        Application.Terminate;
        exit;
      end;
  acLogin.Enabled:=False;
  acLogout.Enabled:=True;
  CalcEnviroment := TCalcEnviroments.Create(nil,Data);
  CalcEnviroment.CreateTable;
  CalcEnviroment.Typ := 'CALC';
  CalcEnviroment.Open;
  if CalcEnviroment.Count=0 then
    begin
      CalcEnviroment.Insert;
      CalcEnviroment.FieldByName('NAME').AsString:=strStandard;
      CalcEnviroment.Post;
    end;
  cbEnviroment.Items.Clear;
  while not CalcEnviroment.EOF do
    begin
      cbEnviroment.AddItem(CalcEnviroment.FieldByName('NAME').AsString,nil);
      CalcEnviroment.Next;
    end;
  cbEnviroment.ItemIndex:=0;
  cbEnviromentSelect(nil);
end;

procedure TfMain.acDeleteEnviromentExecute(Sender: TObject);
begin
  cbEnviroment.Items.Delete(cbEnviroment.ItemIndex);
  CalcEnviroment.Delete;
end;

procedure TfMain.acLogoutExecute(Sender: TObject);
begin
  with Application as IBaseApplication do
    Logout;
end;

procedure TfMain.cbEnviromentExit(Sender: TObject);
begin
  if not CalcEnviroment.Locate('NAME',cbEnviroment.Text,[]) then
    begin
      CalcEnviroment.Insert;
      CalcEnviroment.FieldByName('NAME').AsString:=cbEnviroment.Text;
      CalcEnviroment.Post;
      cbEnviroment.Items.Add(cbEnviroment.Text);
    end;
  cbEnviromentSelect(nil);
end;

procedure TfMain.cbEnviromentSelect(Sender: TObject);
begin
  with CalcEnviroment.Variables do
    begin
      Active:=True;
      First;
      Output.Clear;
      while not EOF do
        begin
          Output.Append(FieldByName('NAME').AsString+'='+FieldByName('FORMULA').AsString+'='+FieldByName('RESULT').AsString);
          Next;
        end;
    end;
  Input.SetFocus;
end;

procedure TfMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  FreeAndNil(CalcEnviroment);
  with Application as IBaseApplication do
    begin
      Data.ActiveUsers.DataSet.AfterScroll:=nil;
      SaveConfig;
      DoExit;
    end;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  CalcEnviroment := nil;
end;

procedure TfMain.FormShow(Sender: TObject);
begin
  if not acLogin.Enabled then exit;
  with Application as IBaseApplication do
    RestoreConfig; //Must be called when Mainform is Visible
  acLogin.Execute;
end;

procedure TfMain.InputKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
  );
var
  sl: TStringList;
  i: Integer;
begin
  if Key = VK_RETURN then
    begin
      Key := 0;
      sl := TStringList.Create;
      CalcEnviroment.Calculate(Input.Text,sl);
      for i := 0 to sl.Count-1 do
        Output.Append(sl[i]);
      Input.Clear;
      sl.Free;
    end;
end;

initialization
  {$I ucalculator.lrs}
end.
