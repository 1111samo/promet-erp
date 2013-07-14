{*******************************************************************************
Dieser Sourcecode darf nicht ohne gültige Geheimhaltungsvereinbarung benutzt werden
und ohne gültigen Vertriebspartnervertrag weitergegeben werden.
You have no permission to use this Source without valid NDA
and copy it without valid distribution partner agreement
CU-TEC Christian Ulrich
info@cu-tec.de
*******************************************************************************}
{TODO : Encoding in Status Dialog stimmt nicht }
unit uAccountingque;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, Buttons,
  Grids,ProcessUtils,Utils,FileUtil,uIntfStrConsts, ComCtrls, Variants, types,
  md5,db,StdCtrls,LCLtype, LCLProc, LCLIntf,uAccounting;
type
  TAccountingInterface = class(TObject)
  public
    function AddTransfer(Sortcode,Accountno,RSortcode,RAccountno,Name,Value,Currency,Textkey : string;Purpose : TStrings) : Boolean;virtual;
    function AddRequest(SortCode,Accountno : string) : Boolean;virtual;
    function Execute : Boolean;virtual;abstract;
  end;
  TAccountingFinTSCmdInterface = class(TAccountingInterface)
  private
    output : TStringList;
    Proc: TExtendedProcess;
    DontHide: Boolean;
    procedure ProcLineWritten(Line: string);
  public
    constructor Create;
    function Execute : Boolean;override;
    destructor Destroy;override;
  end;
  TAccountingAQBankingCLICmdInterface = class(TAccountingInterface)
  private
    output : TStringList;
    Proc: TExtendedProcess;
    DontHide: Boolean;
    Dialog1,Dialog2 : string;
    LastDialogTime : LongWord;
    procedure ProcLineWritten(Line: string);
  public
    procedure ImportCTXData(Accounts : TAccounts;iData : TStringList;Ballance : real);
    function Execute : Boolean;override;
    constructor Create;
    destructor Destroy;override;
  end;
  TfAccountingQue = class(TForm)
    bClose: TBitBtn;
    bSend: TButton;
    lvQue: TListView;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure bCloseClick(Sender: TObject);
    procedure bSendClick(Sender: TObject);
    procedure fAccountingQueClose(Sender: TObject; var CloseAction: TCloseAction
      );
  private
    FIntf: TAccountingInterface;
    { private declarations }
    Commands : TStringList;
    fLog : TextFile;
    fLLog : TStringList;
    OldWaitSize : Integer;
    ClearCue : boolean;
  public
    { public declarations }
    property Intf : TAccountingInterface read FIntf;
    procedure Setlanguage;
  end;
var
  fAccountingQue: TfAccountingQue;

implementation
uses uLogWait,uData,uError,uBankingDialog,SecureUtils,uBaseApplication;
resourcestring
  strEnterPassword              = 'Geben Sie die Pin/Passwort an';
  strWaitingforCard             = 'Warte auf Chipkarte...';
  strErrorPerformingQue         = 'Einer oder mehrere Fehler traten beim bearbeiten der Warteschlange auf';
  strInputTANNumber             = 'Geben Sie die TAN Nummer an';
  strAddingJobs                 = 'füge Aufträge ein...';
  strRequest                    = 'Kontoabfrage';
  strGettingStartBallance       = 'hole Startwert...';
  strImportingData              = 'importiere Daten...';
  strJobsDone                   = 'Alles ausgeführt.';
  strImportComplete             = 'Import fertiggestellt';
  strTransfer                   = 'Überweisung';

procedure TAccountingAQBankingCLICmdInterface.ImportCTXData(Accounts : TAccounts;iData: TStringList;
  Ballance: real);
var
  tmp : string;
  chksum: String;
  StartBallance : real;
  i: Integer;
  a: Integer;
  iDate: Double;

  function RemoveQuotes(s : string) : string;
  begin
    Result := StringReplace(s,'"','',[rfreplaceAll]);
  end;

begin
  if iData.Count < 2 then exit;
  if copy(iData[0],0,191) <> '"transactionId";"localBankCode";"localAccountNumber";"remoteBankCode";"remoteAccountNumber";"date";"valutadate";"value_value";"value_currency";"localName";"remoteName";"remoteName1";"purpose"' then
    exit;
  iData.Delete(0);
  StartBallance := Ballance;
  for i := 0 to iData.Count-1 do
    begin
      tmp := iData[i];
      if not Data.Locate(Accounts.Exchange,'CHECKSUM',MD5Print(MD5String(tmp)),[loCaseInsensitive]) then
        begin
          for a := 0 to 6 do
            tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
          StartBallance := StartBallance-StrToFloat(StringReplace(copy(tmp,2,pos(';',tmp)-3),'.',DecimalSeparator,[]));
        end;
    end;
  while iData.Count > 0 do
    begin
      tmp := iData[0];
      chksum := MD5Print(MD5String(tmp));
      iData.Delete(0);
      Data.SetFilter(Accounts.Exchange,'"CHECKSUM"='''+chksum+'''',0,'','DESC',False,False);
      if not Data.Locate(Accounts.Exchange,'CHECKSUM',chksum,[loCaseInsensitive]) then
        with Accounts.Exchange.DataSet do
          begin
            Append;
            FieldByName('TYPE').AsString := 'B';
            tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
            if FieldDefs.IndexOf('SORTCODE') > -1 then
              FieldByName('SORTCODE').AsString := RemoveQuotes(copy(tmp,2,pos(';',tmp)-3));
            tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
            if FieldDefs.IndexOf('SORTCODE') > -1 then
              FieldByName('ACCOUNTNO').AsString := RemoveQuotes(copy(tmp,2,pos(';',tmp)-3));
            tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
            FieldByName('RSORTCODE').AsString := RemoveQuotes(copy(tmp,2,pos(';',tmp)-3));
            tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
            FieldByName('RACCOUNTNO').AsString := RemoveQuotes(copy(tmp,2,pos(';',tmp)-3));
            tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
            FieldByName('DATE').AsDateTime := ConvertUnknownStringdate(RemoveQuotes(copy(tmp,2,pos(';',tmp)-3)));
            tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
            FieldByName('VALUEDATE').AsDateTime := ConvertUnknownStringdate(RemoveQuotes(copy(tmp,2,pos(';',tmp)-3)));
            tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
            StartBallance := StartBallance+StrToFloat(StringReplace(RemoveQuotes(copy(tmp,2,pos(';',tmp)-3)),'.',DecimalSeparator,[]));
            FieldByName('BALLANCE').AsFloat := StartBallance;
            FieldByName('VALUE').AsFloat := StrToFloat(StringReplace(RemoveQuotes(copy(tmp,2,pos(';',tmp)-3)),'.',DecimalSeparator,[]));
            tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
            FieldByName('CURRENCY').AsString := RemoveQuotes(copy(tmp,2,pos(';',tmp)-3));
            tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
            tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
            FieldByName('NAME').AsString := RemoveQuotes(copy(tmp,2,pos(';',tmp)-3));
            tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
            if trim(RemoveQuotes(copy(tmp,2,pos(';',tmp)-3))) <> '' then
              FieldByName('NAME').AsString := FieldByName('NAME').AsString+lineending+RemoveQuotes(copy(tmp,2,pos(';',tmp)-3));
            tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
            FieldByName('PURPOSE').AsString := StringReplace(RemoveQuotes(copy(tmp,2,pos(';',tmp)-3)),'?',lineending,[rfReplaceAll]);
            for i := 0 to 10 do
              begin
                tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                if trim(copy(tmp,2,pos(';',tmp)-3)) <> '' then
                  FieldByName('PURPOSE').AsString := FieldByName('PURPOSE').AsString+lineending+StringReplace(RemoveQuotes(copy(tmp,2,pos(';',tmp)-3)),'?',lineending,[rfReplaceAll]);
              end;
            tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
            FieldByName('CATEGORY').AsString := RemoveQuotes(copy(tmp,2,pos(';',tmp)-3));   //8 lines but i imprt only 1
            FieldByName('CHECKED').AsString := 'N';
            FieldByName('CHECKSUM').AsString := chksum;
            Post;
          end;
    end;
  Data.SetFilter(Accounts.Exchange,'');
end;
function TAccountingAQBankingCLICmdInterface.Execute: Boolean;
var
  i: Integer;
  CmdLn: String;
  SL : TStringList;
  Showerr: Boolean;
  line: string;
  a: Integer;
  err: String;
  aRec: Integer;
  Accounts: TAccounts;
  aItem: TListItem;
  AllGood: Boolean;
  IData: TStringList;
  tmp,Value,tmp1: String;
  AValue: Extended;
  Btn : array of String;
  res : Integer;
  DelOK: Boolean;
begin
  SL := TStringList.Create;
  fLogWaitForm.SetLanguage;
  fLogwaitForm.bAbort.Kind:=bkAbort;
  fLogWaitForm.Show;
  fLogWaitform.ShowInfo(strAddingJobs);
  AllGood := True;
  i := 0;
  aRec := 0;
  Output.Clear;
  Accounts := TAccounts.Create(nil,Data);
  Accounts.Open;
  while i < fAccountingQue.lvQue.Items.Count do
    begin
      DontHide := False;
      Dialog1 := '';
      Dialog2 := '';
      aRec := Accounts.GetBookmark;
      aItem := fAccountingQue.lvQue.Items[i];
      if not Accounts.DataSet.Locate('SORTCODE;ACCOUNTNO',VarArrayOf([aItem.SubItems[3],aItem.SubItems[2]]),[]) then
        begin
          inc(i);
          break;
        end;
      err := '';
      if aItem.Caption = strRequest then
        begin
          Accounts.Exchange.DataSet.First;
          CmdLn := 'aqbanking-cli request --transactions --balance --sto';
          CmdLn := CmdLn+' --bank='+Accounts.FieldByName('SORTCODE').AsString;
          CmdLn := CmdLn+' --account='+Accounts.FieldByName('ACCOUNTNO').AsString;
          CmdLn := CmdLn+' --ctxfile='+AppendPathDelim(GetTempDir)+'output.ctx';
          CmdLn := CmdLn+' --fromdate='+FormatDateTime('YYYYMMDD',Accounts.Exchange.FieldByName('VALUEDATE').AsDateTime-1);
          if FileExists(AppendPathDelim(AppendPathDelim(AppendPathDelim(AppendPathDelim(ExtractFilePath(Application.Exename))+'tools')+'aqbanking')+'bin')+'aqbanking-cli'+ExtractFileExt(Application.Exename)) then
            CmdLn := AppendPathDelim(AppendPathDelim(AppendPathDelim(AppendPathDelim(ExtractFilePath(Application.Exename))+'tools')+'aqbanking')+'bin')+CmdLn;
          Proc := TExtendedProcess.Create(Cmdln);
          Proc.OnLineWritten :=@ProcLineWritten;
          while Proc.Running do
            begin
              Application.ProcessMessages;
              if (Dialog1 <> '') and (Dialog2 <> '') and (GetTickCount-LastDialogTime > 200) then
                begin
                  a := 1;
                  tmp := copy(Dialog2,rpos(lineending,Dialog2)+length(lineending),length(Dialog2));
                  if copy(tmp,0,1) = '(' then
                    begin
                      fBankingDialog.ClearButtons;
                      Dialog2 := copy(Dialog2,0,rpos(lineending,Dialog2)-1);
                      Setlength(Btn,0);
                      while pos('(',tmp) > 0 do
                        begin
                          Setlength(Btn,length(Btn)+1);
                          tmp := copy(tmp,pos(')',tmp)+1,length(tmp));
                          if pos('(',tmp) > 0 then
                            fBankingDialog.AddButton(trim(copy(tmp,0,pos('(',tmp)-1)),a)
                          else
                            fBankingDialog.AddButton(trim(tmp),a);
                          inc(a);
                          tmp := copy(tmp,pos('(',tmp),length(tmp));
                        end;
                      fBankingDialog.SetLabel(Dialog2);
                      fBankingDialog.Caption:=Dialog1;
                      res := fBankingDialog.Execute;
                      Proc.Writeln(IntToStr(res));
                    end
                  else if InputQuery(Dialog1,Dialog2,(pos('PIN',Dialog1) > 0) or (pos('Passw',Dialog1) > 0),Value) then
                    begin
                      Proc.WriteLn(Value);
                      Value := '';
                    end
                  else
                    begin
                      Proc.Free;
                      DontHide := True;
                    end;
                  Dialog1 := '';
                  Dialog2 := '';
                end;
            end;
          if not DontHide then
            begin
              IData := TStringList.Create;
              CmdLn := 'aqbanking-cli listbal --ctxfile='+AppendPathDelim(GetTempDir)+'output.ctx';
              if FileExists(AppendPathDelim(AppendPathDelim(AppendPathDelim(AppendPathDelim(ExtractFilePath(Application.Exename))+'tools')+'aqbanking')+'bin')+'aqbanking-cli'+ExtractFileExt(Application.Exename)) then
                CmdLn := AppendPathDelim(AppendPathDelim(AppendPathDelim(AppendPathDelim(ExtractFilePath(Application.Exename))+'tools')+'aqbanking')+'bin')+CmdLn;
              IData.Text := ExecProcessEx(CmdLn);
              if copy(IData.Text,0,7) = 'Account' then
                begin
                  tmp := IData.Text;
                  tmp := copy(IData[0],pos(#9,IData[0])+1,length(IData[0]));
                  while (trim(copy(tmp1,0,pos(#9,tmp1)-1)) <> 'EUR') and (pos(#9,tmp) > 0) do
                    begin
                      tmp := copy(tmp,pos(#9,tmp)+1,length(tmp));
                      tmp1 := copy(tmp,pos(#9,tmp)+1,length(tmp));
                    end;
                  CmdLn := 'aqbanking-cli listtrans --ctxfile='+AppendPathDelim(GetTempDir)+'output.ctx --outfile='+AppendPathDelim(GetTempDir)+'output.csv';
                  if FileExists(AppendPathDelim(AppendPathDelim(AppendPathDelim(AppendPathDelim(ExtractFilePath(Application.Exename))+'tools')+'aqbanking')+'bin')+'aqbanking-cli'+ExtractFileExt(Application.Exename)) then
                    CmdLn := AppendPathDelim(AppendPathDelim(AppendPathDelim(AppendPathDelim(ExtractFilePath(Application.Exename))+'tools')+'aqbanking')+'bin')+CmdLn;
                  ExecProcessEx(CmdLn);
                  IData.LoadFromFile(AppendPathDelim(GetTempDir)+'output.csv');
                  if TryStrToFloat(StringReplace(trim(copy(tmp,0,pos(#9,tmp)-1)),'.',DecimalSeparator,[rfReplaceAll]),AValue) then
                    ImportCTXData(Accounts,IData,AValue)
                  else
                    DontHide := True;
                end
              else
                begin
                  fLogWaitForm.lbLog.Items.Add('Error:'+IData.Text);
                  DontHide := True;
                end;
              with BaseApplication as IBaseApplication do
                begin
                  case Config.ReadInteger('DELETEMETHOD',0) of
                  0:DelOK := DeleteFileUTF8(AppendPathDelim(GetTempDir)+'output.ctx');
                  1:DelOK := DeleteSecure(AppendPathDelim(GetTempDir)+'output.ctx');
                  2:DelOK := DeleteSecure(AppendPathDelim(GetTempDir)+'output.ctx',dmDoD522022);
                  3:DelOK := DeleteSecure(AppendPathDelim(GetTempDir)+'output.ctx',dmOverride);
                  end;
                end;
            end;
        end
      else if aItem.Caption = strTransfer then
        begin
          CmdLn := 'aqbanking-cli transfer ';
          CmdLn := CmdLn+'--account='+aItem.SubItems[2];
          CmdLn := CmdLn+' --bank='+aItem.SubItems[3];
          CmdLn := CmdLn+' --raccount='+aItem.SubItems[0];
          CmdLn := CmdLn+' --rbank='+aItem.SubItems[1];
          CmdLn := CmdLn+' --rname="'+aItem.SubItems[4]+'"';
          CmdLn := CmdLn+' --value='+FormatFloat('0000.00',StrToFloat(aItem.SubItems[5]))+':'+aItem.SubItems[6];
          CmdLn := CmdLn+' --textkey='+aItem.SubItems[8];
          sl := TStringList.Create;
          sl.text := aItem.SubItems[7];
          for i := 0 to sl.Count-1 do
            CmdLn := CmdLn+' --purpose="'+sl[i]+'"';
          sl.Free;
          CmdLn := CmdLn+' --force-check';
          if FileExists(AppendPathDelim(AppendPathDelim(AppendPathDelim(AppendPathDelim(ExtractFilePath(Application.Exename))+'tools')+'aqbanking')+'bin')+'aqbanking-cli'+ExtractFileExt(Application.Exename)) then
            CmdLn := AppendPathDelim(AppendPathDelim(AppendPathDelim(AppendPathDelim(ExtractFilePath(Application.Exename))+'tools')+'aqbanking')+'bin')+CmdLn;
          Proc := TExtendedProcess.Create(Cmdln);
          Proc.OnLineWritten :=@ProcLineWritten;
          while Proc.Running do
            begin
              Application.ProcessMessages;
              if (Dialog1 <> '') and (Dialog2 <> '') and (GetTickCount-LastDialogTime > 200) then
                begin
                  a := 1;
                  tmp := copy(Dialog2,rpos(lineending,Dialog2)+length(lineending),length(Dialog2));
                  if copy(tmp,0,1) = '(' then
                    begin
                      fBankingDialog.ClearButtons;
                      Dialog2 := copy(Dialog2,0,rpos(lineending,Dialog2)-1);
                      Setlength(Btn,0);
                      while pos('(',tmp) > 0 do
                        begin
                          Setlength(Btn,length(Btn)+1);
                          tmp := copy(tmp,pos(')',tmp)+1,length(tmp));
                          if pos('(',tmp) > 0 then
                            fBankingDialog.AddButton(trim(copy(tmp,0,pos('(',tmp)-1)),a)
                          else
                            fBankingDialog.AddButton(trim(tmp),a);
                          inc(a);
                          tmp := copy(tmp,pos('(',tmp),length(tmp));
                        end;
                      fBankingDialog.SetLabel(Dialog2);
                      fBankingDialog.Caption:=Dialog1;
                      res := fBankingDialog.Execute;
                      Proc.Writeln(IntToStr(res));
                    end
                  else if InputQuery(Dialog1,Dialog2,(pos('PIN',Dialog1) > 0) or (pos('Passw',Dialog1) > 0),Value) then
                    begin
                      Proc.WriteLn(Value);
                      Value := '';
                    end
                  else
                    begin
                      Proc.Free;
                      DontHide := True;
                    end;
                  Dialog1 := '';
                  Dialog2 := '';
                end;
            end;
        end;
      if DontHide then
        begin
          inc(i);
          AllGood := False;
        end
      else
        begin
          fAccountingQue.lvQue.Items.Delete(i);
          Allgood := False;
        end;
    end;
  Accounts.Free;
  if Allgood then
    fLogWaitForm.Hide
  else
    begin
      fLogwaitForm.bAbort.Kind:=bkClose;
    end;
end;
constructor TAccountingAQBankingCLICmdInterface.Create;
begin
  Output := TStringList.Create;
end;
destructor TAccountingAQBankingCLICmdInterface.Destroy;
begin
  Output.Free;
  inherited Destroy;
end;
procedure TfAccountingQue.FormCreate(Sender: TObject);
begin
  FIntf := TAccountingAQBankingCLICmdInterface.Create;
end;
procedure TfAccountingQue.FormDestroy(Sender: TObject);
begin
end;
procedure TfAccountingQue.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    begin
      Key := 0;
      Close;
    end;
end;
procedure TAccountingAQBankingCLICmdInterface.ProcLineWritten(Line: string);
var
  Value : string;
begin
  if copy(Line,0,6) = '===== ' then
    begin
      Dialog1 := copy(Line,7,length(Line));
      Dialog1 := copy(Dialog1,0,pos(' =====',Dialog1)-1);
      fLogWaitForm.ShowInfo(Line);
      LastDialogTime := GetTickCount;
    end
  else if (Dialog1 <> '') then
    begin
      Dialog2 := Dialog2+lineending+Line;
      fLogWaitForm.ShowInfo(Line);
      LastDialogTime := GetTickCount;
    end
  else if pos(':',copy(line,0,3)) = 2 then
    begin
      if pos('Creating crypttoken (DDV)',line) > 0 then
        fLogWaitForm.ShowInfo(strWaitingforCard)
      else if pos('Error performing queue',line) > 0 then
        DontHide := True
      else if pos('Input',line) > 0 then
      else
        begin
          line := copy(line,pos(':',line)+1,length(line));
          line := copy(line,pos(':',line)+1,length(line));
          line := copy(line,pos(':',line)+1,length(line));
          line := copy(line,pos(':',line)+1,length(line));
          line := copy(line,pos(':',line)+1,length(line));
          fLogWaitForm.ShowInfo(trim(Line))
        end;
    end
  else if trim(line) <> '' then
    fLogWaitForm.ShowInfo(Line);
  Output.Add(line);
end;
procedure TfAccountingQue.bCloseClick(Sender: TObject);
begin
  Close;
end;
procedure TfAccountingQue.bSendClick(Sender: TObject);
begin
  if Intf.Execute then Close;
end;
procedure TfAccountingQue.fAccountingQueClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  fLogWaitForm.OnClose := nil;
end;
procedure TfAccountingQue.Setlanguage;
begin
  if not Assigned(Self) then
    begin
      Application.CreateForm(TfAccountingQue,fAccountingQue);
      Self := fAccountingQue;
    end;
  lvQue.Columns[0].Caption := strType;
  lvQue.Columns[1].Caption := strAccount;
  lvQue.Columns[2].Caption := strSortCode;
  lvQue.Columns[3].Caption := strAccount;
  lvQue.Columns[4].Caption := strSortCode;
  lvQue.Columns[5].Caption := strName;
end;
function CountPos(const subtext: string; Text: string): Integer;
begin
  if (Length(subtext) = 0) or (Length(Text) = 0) or (Pos(subtext, Text) = 0) then
    Result := 0
  else
    Result := (Length(Text) - Length(StringReplace(Text, subtext, '', [rfReplaceAll]))) div Length(subtext);
end;
procedure TAccountingFinTSCmdInterface.ProcLineWritten(Line: string);
var
  tmp: String;
  Value : string;
begin
  if trim(line) = '' then exit;
  if (pos(';',line) = -1) then
    fLogWaitForm.ShowInfo(SysToUTF8(Line))
  else if CountPos(';',Line) = 2 then
    begin
      tmp := copy(Line,pos(';',Line)+1,length(Line));
      tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
      fLogWaitForm.ShowInfo(SysToUTF8(tmp));
    end
  else if ((pos('TAN',Line) > 0) or (pos('Index',Line) > 0)) and (Pos(':',Line) > 0) then
    begin
      if InputQuery(strInputTANNumber,Line,False,Value) then
        Proc.WriteLn(Value)
      else
        Proc.WriteLn('');
    end
  else
    Output.Add(line);
  debugln(Line);
  if pos('nicht möglich',SysToUTF8(tmp)) > 0 then
    DontHide := True;
  if pos('ungültig',SysToUTF8(tmp)) > 0 then
    DontHide := True;
  if pos('zu lang',SysToUTF8(tmp)) > 0 then
    DontHide := True;
  if pos('Error',SysToUTF8(tmp)) > 0 then
    DontHide := True;
  if pos('error',SysToUTF8(tmp)) > 0 then
    DontHide := True;
end;
constructor TAccountingFinTSCmdInterface.Create;
begin
  Output := TStringlist.Create;
end;
function TAccountingFinTSCmdInterface.Execute: Boolean;
var
  i: Integer;
  aItem: TListItem;
  aPin: String = '';
  CmdLn: String;
  Value: Extended;
  tmp: string;
  a: Integer;
  b: Integer;
  StartBallance: Extended;
  chksum: String;
  tmp1: String;
  aRec: LongInt;
  Accounts: TAccounts;
begin
//  fWizardnewAccount.InitWizard;
  DontHide := true;
  fLogWaitForm.bAbort.Kind:=bkCancel;
  fLogWaitForm.Show;
  fLogWaitform.ShowInfo(strAddingJobs);
  i := 0;
  aRec := 0;
  Accounts := TAccounts.Create(nil,Data);
  Accounts.Open;
  while i < fAccountingQue.lvQue.Items.Count do
    begin
      aRec := Accounts.GetBookmark;
      aItem := fAccountingQue.lvQue.Items[i];
      if not Accounts.DataSet.Locate('SORTCODE;ACCOUNTNO',VarArrayOf([aItem.SubItems[3],aItem.SubItems[2]]),[]) then
        begin
          inc(i);
          break;
        end;
      if Accounts.GetBookmark <> aRec then aPin := '';
      if aItem.Caption = strRequest then
        begin
          if aPin = '' then InputQuery(strEnterPassword,'',True,aPin);
          if aPin = '' then
            begin
              inc(i);
              break;
            end;
          CmdLn := 'FinCmd.exe balance';
          CmdLn := CmdLn+' -contactname "'+Accounts.FieldByName('FTSNAME').AsString+'"';
          CmdLn := CmdLn+' -pin '+aPin;
          CmdLn := CmdLn+' -acctno '+aItem.SubItems[2];
          Output.Clear;
          Proc := TExtendedprocess.Create({fWizardNewAccount.SubSemblyPath+}CmdLn,False);
          Proc.OnLineWritten:=@ProcLineWritten;
          Proc.Start;
          while Proc.Active do Application.Processmessages;
          if not ((Output.Count > 1) and (Output[0] = 'BalanceType;BankCode;AcctNo;Date;Currency;Value')) then
            begin
              DontHide := True;
              inc(i);
              break;
            end;
          Value := -1.0;
          for a := 0 to Output.Count-1 do
            if copy(Output[a],0,pos(';',Output[a])-1) = 'BOOKED' then
              begin
                tmp := Output[a];
                tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                Value := StrToFloat(tmp);
              end;
          //All OK
          CmdLn := 'FinCmd.exe statement';
          CmdLn := CmdLn+' -contactname "'+Accounts.FieldByName('FTSNAME').AsString+'"';
          CmdLn := CmdLn+' -pin '+aPin;
          CmdLn := CmdLn+' -acctno '+aItem.SubItems[2];
          Output.Clear;
          Proc := TExtendedprocess.Create({fWizardNewAccount.SubSemblyPath+}CmdLn,False);
          Proc.OnLineWritten:=@ProcLineWritten;
          Proc.Start;
          while Proc.Active do Application.Processmessages;
          if not ((Output.Count > 1) and (Output[0] = 'EntryDate;ValueDate;Value;AcctNo;BankCode;Name1;Name2;PaymtPurpose;EntryText;PrimaNotaNo;TranTypeIdCode;ZkaTranCode;TextKeyExt;BankRef;OwnerRef;SupplementaryDetails')) then
            begin
              inc(i);
              break;
            end;
          fLogWaitform.ShowInfo(strGettingStartBallance);
          Output.Delete(0);
          StartBallance := Value;
          a := Output.Count-1;
          while a >= 0 do
            begin
              tmp := Output[a];
              Data.SetFilter(Accounts.Exchange,'',0,'','DESC',False,False);
              if not Data.Locate(Accounts.Exchange,'CHECKSUM',MD5Print(MD5String(tmp)),[loCaseInsensitive]) then
                begin
                  for b := 0 to 1 do
                    tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                  StartBallance := StartBallance-StrToFloat(copy(tmp,0,pos(';',tmp)-1));
                  dec(a);
                end
              else
                begin
                  while a >= 0 do
                    begin
                      Output.Delete(a);
                      dec(a);
                    end;
                end;
            end;
          fLogWaitform.ShowInfo(strImportingData);
          while Output.Count > 0 do
            begin
              tmp := SysToUTF8(Output[0]);
              chksum := MD5Print(MD5String(tmp));
              Output.Delete(0);
              if not Accounts.Exchange.DataSet.Locate('CHECKSUM',chksum,[loCaseInsensitive]) then
                with Accounts.Exchange.DataSet do
                  begin
                    Append;
                    FieldByName('TYPE').AsString := 'B';
                    FieldByName('DATE').AsDateTime := ConvertUnknownStringdate(copy(tmp,0,pos(';',tmp)-1));
                    tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                    FieldByName('VALUEDATE').AsDateTime := ConvertUnknownStringdate(copy(tmp,0,pos(';',tmp)-1));
                    tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                    FieldByName('VALUE').AsFloat := StrToFloat(copy(tmp,0,pos(';',tmp)-1));
                    StartBallance := StartBallance+StrToFloat(copy(tmp,0,pos(';',tmp)-1));
                    FieldByName('BALLANCE').AsFloat := StartBallance;
                    tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                    FieldByName('RACCOUNTNO').AsString := copy(tmp,0,pos(';',tmp)-1);
                    tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                    FieldByName('RSORTCODE').AsString := copy(tmp,0,pos(';',tmp)-1);
                    if FieldDefs.IndexOf('SORTCODE') > -1 then
                      begin
                        FieldByName('SORTCODE').AsString := aItem.SubItems[3];
                        FieldByName('ACCOUNTNO').AsString := aItem.SubItems[2];
                      end;
                    //TODO:Kontowährung von ballance abfrage merken
                    FieldByName('CURRENCY').AsString := 'EUR';//copy(tmp,2,pos(';',tmp)-3);
                    tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                    tmp1 := copy(tmp,0,pos(';',tmp)-1);
                    tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                    if trim(copy(tmp,0,pos(';',tmp)-1)) <> '' then
                      FieldByName('NAME').AsString := tmp1+lineending+copy(tmp,0,pos(';',tmp)-1)
                    else
                      FieldByName('NAME').AsString := tmp1;
                    tmp := copy(tmp,pos(';',tmp)+1,length(tmp));
                    FieldByName('PURPOSE').AsString := Stringreplace(copy(tmp,0,pos(';',tmp)-1),'|',lineending,[rfReplaceAll]);
                    FieldByName('CHECKED').AsString := 'N';
                    FieldByName('CHECKSUM').AsString := chksum;
                    Post;
                  end;
            end;
          fLogWaitform.ShowInfo(strImportComplete);
          fAccountingQue.lvQue.Items.Delete(i);
        end
      else if aItem.Caption = strTransfer then
        begin
          if aPin = '' then InputQuery(strEnterPassword,'',True,aPin);
          if aPin = '' then
            begin
              inc(i);
              break;
            end;
          CmdLn := 'FinCmd.exe remitt';
          CmdLn := CmdLn+' -contactname "'+Accounts.FieldByName('FTSNAME').AsString+'"';
          CmdLn := CmdLn+' -pin '+aPin;
          CmdLn := CmdLn+' -acctno '+aItem.SubItems[2];
          CmdLn := CmdLn+' -payeename "'+aItem.SubItems[4]+'"';
          CmdLn := CmdLn+' -payeeacctno '+aItem.SubItems[0];
          CmdLn := CmdLn+' -payeebankcode '+aItem.SubItems[1];
          CmdLn := CmdLn+' -amount '+FormatFloat('0000.00',StrToFloat(aItem.SubItems[5]));
          CmdLn := CmdLn+' -textkey '+aItem.SubItems[8];
          CmdLn := CmdLn+' -purpose "'+StringReplace(aItem.SubItems[7],lineending,'|',[rfreplaceAll])+'"';
          Output.Clear;
          Proc := TExtendedprocess.Create({fWizardNewAccount.SubSemblyPath+}CmdLn,False);
          Proc.OnLineWritten:=@ProcLineWritten;
          Proc.Start;
          while Proc.Active do Application.Processmessages;
          fAccountingQue.lvQue.Items.Delete(i);
        end
      else
        inc(i);
    end;
  Accounts.Free;
  fLogWaitform.ShowInfo(strJobsDone);
  if not DontHide then
    fLogWaitForm.Hide
  else
    fLogWaitForm.bAbort.Kind:=bkClose;
end;
destructor TAccountingFinTSCmdInterface.Destroy;
begin
  output.Free;
  inherited Destroy;
end;
function TAccountingInterface.AddTransfer(Sortcode, Accountno, RSortcode,
  RAccountno,Name, Value, Currency, Textkey: string; Purpose: TStrings): Boolean;
var
  Item: TListItem;
begin
  Item := fAccountingQue.lvQue.Items.Add;
  Item.Caption:=strTransfer;
  Item.SubItems.Add(RAccountNo);
  Item.SubItems.Add(RSortcode);
  Item.SubItems.Add(AccountNo);
  Item.SubItems.Add(Sortcode);
  Item.SubItems.Add(Name);
  Item.SubItems.Add(Value);
  Item.SubItems.Add(Currency);
  Item.SubItems.Add(Purpose.Text);
  Item.SubItems.Add(Textkey);
end;
function TAccountingInterface.Addrequest(SortCode, Accountno: string): Boolean;
var
  Item: TListItem;
begin
  Item := fAccountingQue.lvQue.Items.Add;
  Item.Caption:=strRequest;
  Item.SubItems.Add('');
  Item.SubItems.Add('');
  Item.SubItems.Add(AccountNo);
  Item.SubItems.Add(Sortcode);
end;
initialization
  {$I uaccountingque.lrs}

end.

