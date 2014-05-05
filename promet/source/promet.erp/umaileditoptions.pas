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

unit uMailEditoptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Buttons, uIntfStrConsts,LCLType, ButtonPanel,FileUtil,
  ProcessUtils,uProcessManager,uLogWait;

type

  { TfMailOptions }

  TfMailOptions = class(TForm)
    bpButtons: TButtonPanel;
    bCheckConnection: TButton;
    cbArchive: TCheckBox;
    cbDelete: TCheckBox;
    eName: TEdit;
    eMailAddr: TEdit;
    eServertype: TComboBox;
    eTargetFolder: TEdit;
    eUsername: TEdit;
    eServer: TEdit;
    ePassword: TEdit;
    Label1: TLabel;
    lName: TLabel;
    lMailAddr: TLabel;
    lServertype: TLabel;
    lUsername: TLabel;
    lServer: TLabel;
    lPassword: TLabel;
    pFeedOptions: TPanel;
    pPOPOptions: TPanel;
    pSMTPOptions: TPanel;
    procedure aProcessLineWritten(Line: string);
    procedure bCheckConnectionClick(Sender: TObject);
    procedure eServertypeSelect(Sender: TObject);
    procedure fLogWaitFormbAbortClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { private declarations }
    aProcess: TExtendedProcess;
  public
    { public declarations }
    function Execute : Boolean;
    procedure SetLanguage;
  end;

var
  fMailOptions: TfMailOptions;

implementation

resourcestring
  strFeed                       = 'Feed';
  strServiceNotInstalled        = 'Der Dienst %s ist derzeit nicht installiert !';


{ TfMailOptions }

procedure TfMailOptions.eServertypeSelect(Sender: TObject);
begin
  pSMTPOptions.Visible := eServertype.Text = 'SMTP';
  pPOPOptions.Visible := eServertype.Text = 'POP3';
  pFeedOptions.Visible := eServertype.Text = 'FEED';
  if eServertype.Text = 'FEED' then
    begin
      lServer.Caption := strFeed;
      eUsername.Visible:=False;
      ePassword.Visible:=False;
      lUsername.Visible:=False;
      lPassword.Visible:=False;
    end
  else
    begin
      lServer.Caption := strServer;
      eUsername.Visible:=True;
      ePassword.Visible:=True;
      lUsername.Visible:=True;
      lPassword.Visible:=True;
    end;
end;

procedure TfMailOptions.fLogWaitFormbAbortClick(Sender: TObject);
begin
  aProcess.Terminate(1);
end;

procedure TfMailOptions.bCheckConnectionClick(Sender: TObject);
var
  aPath: String;
  aFile: String;
begin
  aPath := AppendPathDelim(AppendPathDelim(Application.Location)+'tools');
  if FileExists(aPath+lowerCase(eServertype.Text)+'receiver') then
    aFile := aPath+lowerCase(eServertype.Text)+'receiver'
  else if FileExists(aPath+lowerCase(eServertype.Text)+'sender') then
    aFile := aPath+lowerCase(eServertype.Text)+'sender';
  if not FileExists(aFile) then
    begin
      Showmessage(Format(strServiceNotInstalled,[ExtractFileName(aFile)]));
      exit;
    end;
  fLogWaitForm.SetLanguage;
  fLogWaitForm.Show;
  fLogWaitForm.ShowInfo('Test wird gestartet:');
  fLogWaitForm.ShowInfo(aFile+' "--mandant='+ProcessMandant+'"'+' "--user='+ProcessUser+'" --onerun');
  fLogWaitForm.bAbort.OnClick:=@fLogWaitFormbAbortClick;
  aProcess := TExtendedProcess.Create(aFile+' "--mandant='+ProcessMandant+'"'+' "--user='+ProcessUser+'" --onerun',True);
  aProcess.OnLineWritten:=@aProcessLineWritten;
  while aProcess.Active and fLogWaitForm.Visible do
    Application.ProcessMessages;
  if not fLogWaitForm.Visible then
    aProcess.Terminate(1);
  fLogWaitForm.ShowInfo('Test abgeschlossen:'+IntToStr(aProcess.ExitStatus));
  fLogWaitForm.bAbort.Kind:=bkClose;
  fLogWaitForm.bAbort.OnClick:=nil;
  aProcess.Free;
end;

procedure TfMailOptions.aProcessLineWritten(Line: string);
begin
  fLogWaitForm.ShowInfo(Line);
end;

procedure TfMailOptions.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    begin
      Key := 0;
      Close;
    end;
end;

function TfMailOptions.Execute: Boolean;
var
  ActControl: TWinControl;
begin
  ActControl := Screen.ActiveControl;
  Result := Showmodal = mrOK;
  try
    if Assigned(ActControl) and ActControl.CanFocus then ActControl.SetFocus;
  except
  end;
end;

procedure TfMailOptions.SetLanguage;
begin
  if not Assigned(Self) then
    begin
      Application.CreateForm(TfMailOptions,fMailOptions);
      Self := fMailOptions;
    end;
end;

initialization
  {$I umaileditoptions.lrs}

end.

