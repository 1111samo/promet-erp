{*******************************************************************************
Dieser Sourcecode darf nicht ohne gültige Geheimhaltungsvereinbarung benutzt werden
und ohne gültigen Vertriebspartnervertrag weitergegeben oder kommerziell verwertet werden.
You have no permission to use this Source without valid NDA
and copy it without valid distribution partner agreement
Christian Ulrich
info@cu-tec.de
Created 01.06.2006
*******************************************************************************}
unit uPassword;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Buttons,ComCtrls,LCLType, ButtonPanel, Menus, uBaseApplication,
  uBaseDBInterface,FileUtil;
resourcestring
  strNoMandants         = 'keine Mandanten gefunden !';
  strStartmandantWizard = 'Es wurde kein Mandant gefunden.'+lineending+'Möchten Sie jetzt einen anlegen ?';
  strFirstLogin         = 'Sie müssen ein neues Passwort vergeben, das Passwort welches Sie eingeben wird ab nun Ihr Passwort sein.';
type

  { TfPassword }

  TfPassword = class(TForm)
    ButtonPanel1: TButtonPanel;
    cbAutomaticLogin: TCheckBox;
    cbMandant: TComboBox;
    cbUser: TComboBox;
    ePasswort: TEdit;
    IdleTimer1: TIdleTimer;
    lFirstLogin: TLabel;
    lPassword: TLabel;
    lUser: TLabel;
    lMandant: TLabel;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    procedure cbMandantSelect(Sender: TObject);
    procedure cbUserSelect(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure IdleTimer1Timer(Sender: TObject);
    procedure lFirstLoginResize(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
  private
    { private declarations }
    procedure StartWizardMandant;
  public
    { public declarations }
    function Execute(aHint : string = '';UserSelectable : Boolean = True) : Boolean;
  end; 

var
  fPassword: TfPassword;

implementation
uses
  uMashineID,uData,UTF8Process,Process;
{ TfPassword }

procedure TfPassword.cbMandantSelect(Sender: TObject);
var
  aUser: TCaption;
  function DoOpenMandant(aMandantPath : string) : Boolean;
  var
    mSettings: TStringList;
  begin
    Result := False;
    if FileExistsUTF8(aMandantPath) then
      begin
        mSettings := TStringList.Create;
        mSettings.LoadFromFile(UTF8ToSys(aMandantPath));
        if mSettings.Count = 2 then
          begin
            aUser := cbUser.Text;
            cbUser.Clear;
            with Application as IBaseDBInterface do
              begin
                if not OpenMandant(mSettings[0],mSettings[1]) then
                  begin
                    lFirstLogin.AutoSize:=True;
                    lFirstLogin.Caption:=LastError;
                    lFirstLogin.Visible:=True;
                    mSettings.Free;
                    exit;
                  end;
              end;
          end
        else
          begin
            lFirstLogin.AutoSize:=True;
            lFirstLogin.Caption:='Invalid Config file';
            lFirstLogin.Visible:=True;
            exit;
          end;
        mSettings.Free;
      end
    else
      begin
        lFirstLogin.AutoSize:=True;
        lFirstLogin.Caption:='Config File dosend exists';
        lFirstLogin.Visible:=True;
        mSettings.Free;
        exit;
      end;
    Result := True;
  end;
begin
  lFirstLogin.Caption := '';
  lFirstLogin.AutoSize:=False;
  lFirstLogin.Height := 0;
  lFirstLogin.Visible:=False;
  with Application as IBaseDBInterface do
    begin
      if not DirectoryExistsUTF8(MandantPath) then
        begin
          if not DoOpenMandant(MandantPath) then exit;
        end
      else if DirectoryExistsUTF8(MandantPath) then
        begin
          if not DoOpenMandant(AppendPathDelim(MandantPath)+cbMandant.Text+MandantExtension) then exit;
        end;
      Data.Users.Open;
      while not Data.Users.DataSet.EOF do
        begin
          if Data.Users.Leaved.IsNull and (Data.Users.FieldByName('TYPE').AsString <> 'G') then
            cbUser.Items.Add(Data.Users.UserName.AsString);
          Data.Users.DataSet.Next;
        end;
      cbUser.Enabled:=cbUser.Items.Count > 0;
      if cbUSer.Items.IndexOf(aUSer) > 0 then
        begin
          cbUser.ItemIndex:=cbUSer.Items.IndexOf(aUSer);
          cbUserSelect(nil);
        end;
    end;
  lFirstLoginResize(nil);
end;
procedure TfPassword.cbUserSelect(Sender: TObject);
begin
  ePasswort.Enabled := True;
  if Visible then
    ePasswort.SetFocus;
  with Application as IBaseDBInterface do
    lFirstLogin.Visible:=Data.Users.DataSet.Locate('NAME',cbUser.text,[])
                         and (Data.Users.Passwort.IsNull or (Data.Users.Passwort.AsString = ''));
  if lFirstLogin.Visible then
    begin
      lFirstLogin.AutoSize:=True;
      lFirstLogin.Caption:=strFirstLogin;
    end;
end;
procedure TfPassword.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    begin
      Key := 0;
      Close;
    end;
end;
procedure TfPassword.FormShow(Sender: TObject);
begin
  if Visible and (cbMandant.Text <> '') and (cbUser.Text <> '') then
    begin
      ePasswort.SetFocus;
      //Self.BringToFront;
      //IdleTimer1.Enabled:=True;
    end;
end;

procedure TfPassword.IdleTimer1Timer(Sender: TObject);
begin
  IdleTimer1.Enabled:=False;
  SetFocus;
end;

procedure TfPassword.lFirstLoginResize(Sender: TObject);
begin
  Height := ((ePasswort.Height+8)*3)+ButtonPanel1.Height+lFirstLogin.Height+40+20;
end;

procedure TfPassword.MenuItem1Click(Sender: TObject);
begin
  StartWizardMandant;
end;

procedure TfPassword.OKButtonClick(Sender: TObject);
var
  BaseApplication : IBaseApplication;
begin
  if Supports(Application, IBaseApplication, BaseApplication) then
    begin
      if cbAutomaticLogin.Checked then
        BaseApplication.Config.WriteInteger('AUTOMATICLOGIN',CreateUserID)
      else
        BaseApplication.Config.WriteString('AUTOMATICLOGIN','NO');
      BaseApplication.Config.WriteString('LOGINMANDANT',cbMandant.Text);
      BaseApplication.Config.WriteString('LOGINUSER',cbUser.Text);
    end;
end;

procedure TfPassword.StartWizardMandant;
var
  aProcess: TProcessUTF8;
begin
  aProcess := TProcessUTF8.Create(Self);
  aProcess.CommandLine:=AppendPathDelim(Application.Location)+'wizardmandant'+ExtractFileExt(Application.ExeName);
  if Application.HasOption('c','config-path') then
    aProcess.CommandLine:=aProcess.CommandLine+' "--config-path='+Application.GetOptionValue('c','config-path')+'"';
  aProcess.CommandLine:=aProcess.CommandLine+' "--execute='+Application.ExeName+'"';
  aProcess.Options := [poNoConsole];
  try
    aProcess.Execute;
    Application.Terminate;
  except
    aProcess.Free;
    raise Exception.Create(strNoMandants);
  end;
end;

function TfPassword.Execute(aHint : string = '';UserSelectable : Boolean = True): Boolean;
var
  AInfo: TSearchRec;
begin
  Result := False;
  if not Assigned(Self) then
    begin
      Application.CreateForm(TfPassword,fPassword);
      Self := fPassword;
    end;
  lFirstLogin.Caption:='';
  lFirstLogin.Visible:=False;
  lFirstLogin.Height:=0;
  lFirstLoginResize(nil);
  with Application as IBaseApplication do
    begin
      if cbMandant.Items.Count = 0 then
        begin
          with Application as IBaseDbInterface do
            begin
              If FindFirstUTF8(AppendPathDelim(MandantPath)+'*'+MandantExtension,faAnyFile,AInfo)=0 then
                Repeat
                  With aInfo do
                    begin
                      If (Attr and faDirectory) <> faDirectory then
                        cbMandant.Items.Add(copy(Name,0,length(Name)-length(MandantExtension)));
                    end;
                Until FindNext(ainfo)<>0;
              FindClose(aInfo);
              if cbMandant.Items.Count = 0 then
                begin
                  if FileExistsUTF8(AppendPathDelim(Application.Location)+'wizardmandant'+ExtractFileExt(Application.ExeName)) then
                    begin
                      if MessageDlg(strStartmandantWizard,mtInformation,[mbYes,mbNo],0) = mrYes then
                        begin
                          StartWizardMandant;
                        end
                      else  raise Exception.Create(strNoMandants);
                    end
                  else raise Exception.Create(strNoMandants);
                  exit;
                end;
            end;
        end;
      if (cbMandant.Text = '') then
        begin
          cbUser.Text:='';
          cbMandant.Text := '';
          if cbMandant.Items.IndexOf(Config.ReadString('LOGINMANDANT','')) > -1 then
            begin
              cbMandant.ItemIndex:=cbMandant.Items.IndexOf(Config.ReadString('LOGINMANDANT',''));
              cbMandantSelect(nil);
            end;
          if (cbMandant.Text = '') and (cbMandant.Items.Count = 1) then
            begin
              cbMandant.ItemIndex := 0;
              cbMandantSelect(nil);
            end;
          if cbUser.Items.IndexOf(Config.ReadString('LOGINUSER','')) > -1 then
            begin
              cbUser.Text := Config.ReadString('LOGINUSER','');
              cbUserSelect(nil);
            end;
        end;
    end;
  cbMandant.Enabled:=UserSelectable;
  cbUser.Enabled:=UserSelectable;
  ePasswort.Text:='';
  if aHint <> '' then
    begin
      lFirstLogin.AutoSize:=True;
      lFirstLogin.Visible:=True;
      lFirstLogin.Caption:=aHint;
      lFirstLoginResize(nil);
    end;
  Result := Showmodal = mrOK;
end;
initialization
  {$I upassword.lrs}
end.
