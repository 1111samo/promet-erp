{*******************************************************************************
Dieser Sourcecode darf nicht ohne gültige Geheimhaltungsvereinbarung benutzt werden
und ohne gültigen Vertriebspartnervertrag weitergegeben werden.
You have no permission to use this Source without valid NDA
and copy it without valid distribution partner agreement
CU-TEC Christian Ulrich
info@cu-tec.de
*******************************************************************************}
{-TODO : Encoding in HTML Mails stimmt nicht }
unit uViewMessage;
{$mode objfpc}{$H+}
interface
uses
  Classes, SysUtils, FileUtil, LResources, Forms, ExtCtrls, StdCtrls, IpHtml,
  uData, Graphics, Menus, uIntfStrConsts, DB, Variants, Utils, LCLIntf,
  uMessages, lconvencoding;
type
  TSimpleIpHtml = class(TIpHtml)
  public
    property OnGetImageX;
  end;
  TfViewMessage = class(TFrame)
    iContent: TScrollBox;
    iiContent: TImage;
    ipHTMLContent: TIpHtmlPanel;
    mContent: TMemo;
    moCopy: TMenuItem;
    pmCopy: TPopupMenu;
    procedure FrameResize(Sender: TObject);
    procedure ipHTMLContentHotClick(Sender: TObject);
    procedure moCopyClick(Sender: TObject);
    procedure OnGetImage(Sender: TIpHtmlNode; const URL: string;
      var Picture: TPicture);
  private
    { private declarations }
    FActiveList : TDataSet;
    Messages: TMessage;
  public
    { public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy;override;
    procedure ShowMessage(ListDataSet : TDataSet;ShowLetter : Boolean = False);
    property Message : TMessage read Messages;
  end;
  TLoadHTMLProcess = class(TThread)
  private
    FDone: Boolean;
    FExcept: Boolean;
    FHTML : TSimpleIPHTML;
    ss : TStream;
    FView : TfViewMessage;
  public
    constructor Create(View : TfViewMessage;HTML : TSimpleIPHTML;sss : TStream);
    procedure Execute;override;
    property Done : Boolean read FDone;
  end;
implementation
uses uDocuments,LCLProc,wikitohtml;
resourcestring
  strMessagenotDownloaded       = 'Die Naricht wurde aus Sicherheitsgründen nicht heruntergeladen !';
  strOpenToViewItem             = 'Bitte klicken Sie doppelt auf diesen Eintrag um ihn anzuzeigen';

procedure TfViewMessage.OnGetImage(Sender: TIpHtmlNode; const URL: string;
  var Picture: TPicture);
var
  ss: TStringStream;
  tmp: String;
  aDocument: TDocument;
begin
  Picture := TPicture.Create;
  Picture.Bitmap.Height:=0;
  Picture.Bitmap.Width := 0;
  Picture.Bitmap.Transparent:=True;
  if Uppercase(copy(url,0,4)) = 'CID:' then
    begin
      try
        try
          aDocument := TDocument.Create(Self,Data);
          Data.SetFilter(aDocument,Data.QuoteField('TYPE')+'='+Data.QuoteValue('N')+' and '+Data.QuoteField('REF_ID_ID')+'='+Data.QuoteValue(Messages.Content.Id.AsString));
          if aDocument.DataSet.Locate('TYPE;REF_ID_ID',VarArrayOf(['N',Messages.Content.id.AsString]),[loPartialKey]) then
            begin
              aDocument.DataSet.First;
              while not aDocument.DataSet.EOF do
                begin
                  ss := TStringStream.Create('');
                  Data.BlobFieldToStream(aDocument.DataSet,'FULLTEXT',ss);
                  tmp := StringReplace(StringReplace(ss.DataString,'<','',[]),'>','',[]);
                  if ValidateFileName(tmp) = copy(ValidateFileName(URL),5,length(ValidateFileName(URL))) then
                    begin
                      Data.BlobFieldToFile(aDocument.DataSet,'DOCUMENT',GetTempDir+copy(url,5,length(url))+'.'+aDocument.FieldByName('EXTENSION').AsString);
                      try
                        Picture.LoadFromFile(GetTempDir+copy(url,5,length(url))+'.'+aDocument.FieldByName('EXTENSION').AsString);
                      except
                        FreeAndnil(Picture);
                      end;
                      DeleteFileUTF8(GetTempDir+copy(url,5,length(url))+'.'+aDocument.FieldByName('EXTENSION').AsString);
                      if Assigned(Picture) and (Picture.Width = 0) then
                        FreeAndNil(Picture);
                    end;
                  ss.Free;
                  aDocument.DataSet.Next;
                end;
            end;
        except
        end;
      finally
        aDocument.Free;
      end;
    end
  else
    begin
      try
        try
          aDocument := TDocument.Create(Self,Data);
          Data.SetFilter(aDocument,Data.QuoteField('TYPE')+'='+Data.QuoteValue('N')+' and '+Data.QuoteField('REF_ID_ID')+'='+Data.QuoteValue(Messages.Content.Id.AsString));
          if aDocument.Count>0 then
            begin
              aDocument.DataSet.First;
              while not aDocument.DataSet.EOF do
                begin
                  if aDocument.FileName = url then
                    begin
                      ss := TStringStream.Create('');
                      Data.BlobFieldToFile(aDocument.DataSet,'DOCUMENT',GetTempDir+copy(url,5,length(url))+'.'+aDocument.FieldByName('EXTENSION').AsString);
                      try
                        Picture.LoadFromFile(GetTempDir+copy(url,5,length(url))+'.'+aDocument.FieldByName('EXTENSION').AsString);
                      except
                        FreeAndnil(Picture);
                      end;
                      DeleteFileUTF8(GetTempDir+copy(url,5,length(url))+'.'+aDocument.FieldByName('EXTENSION').AsString);
                      if Assigned(Picture) and (Picture.Width = 0) then
                        FreeAndNil(Picture);
                    end;
                  ss.Free;
                  aDocument.DataSet.Next;
                end;
            end;
        except
        end;
      finally
        aDocument.Free;
      end;
    end;
end;
constructor TfViewMessage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Messages := TSpecialMessage.Create(Self,Data);
end;
destructor TfViewMessage.Destroy;
begin
  Messages.Free;
  inherited Destroy;
end;
procedure TfViewMessage.moCopyClick(Sender: TObject);
begin
  ipHTMLContent.CopyToClipboard;
end;
procedure TfViewMessage.ipHTMLContentHotClick(Sender: TObject);
begin
  if ipHTMLContent.HotNode is TIpHtmlNodeA then
    begin
      Application.ProcessMessages;
      debugln(TIpHtmlNodeA(IpHtmlContent.HotNode).HRef);
      OpenURL(TIpHtmlNodeA(IpHtmlContent.HotNode).HRef);
      Application.ProcessMessages;
    end;
end;
procedure TfViewMessage.FrameResize(Sender: TObject);
begin
  {
  if Assigned(Data) then
    if Assigned(Data.MessageIdx) then
      if Assigned(Data.MessageIdx.DataSet) then
        if (Data.MessageIdx.DataSet.Active) then
          if (Data.MessageIdx.FieldByName('TYPE').AsString = 'LETTE') then
            if iiContent.Picture.Width > 0 then
              iiContent.Height:=(iiContent.Width*iiContent.Picture.Height) div iiContent.Picture.Width;
  }
end;
procedure TfViewMessage.ShowMessage(ListDataSet : TDataSet;ShowLetter : Boolean = False);
var
  ss: TStringStream;
  NewHTML: TSimpleIpHtml;
  ID: String;
  proc: TLoadHTMLProcess;
  i: Integer;
  sl: TStringList;
  tmp: String;
  aEncoding: String;
begin
  FActiveList := ListDataSet;
  if Messages.DataSet.ControlsDisabled then exit;
  Messages.Select(ListDataSet.FieldByName('SQL_ID').AsVariant);
  Messages.Open;
  if not Messages.DataSet.Active then exit;
  Messages.Content.Open;
  if Data.RecordCount(Messages.Content) > 0 then
   begin
     if Uppercase(Messages.Content.FieldByName('DATATYP').AsString) = 'PLAIN' then
       begin
         try
         ipHTMLContent.Visible:=false;
         ss := TStringStream.Create('');
         Data.BlobFieldToStream(Messages.Content.DataSet,'DATA',ss);
         sl := TStringList.Create;
         sl.Text:=SysToUTF8(ConvertEncoding(ss.DataString,GuessEncoding(ss.DataString),EncodingUTF8));
         sl.TextLineBreakStyle := tlbsCRLF;
         mContent.Lines.Assign(sl);
         sl.Free;
         ss.Free;
         mContent.Visible:=True;
         except
         end;
       end
     else if UpperCase(Messages.Content.FieldByName('DATATYP').AsString) = 'HTML' then
       begin
         mContent.Visible:=false;
         try
           ss:=TStringStream.Create('');
           Data.BlobFieldToStream(Messages.Content.DataSet,'DATA',ss);
           ss.Position := 0;
           tmp := ss.DataString;
           aEncoding := GuessEncoding(tmp);
           if pos('ENCODING',Uppercase(tmp)) = 0 then
             tmp := char($EF)+char($BB)+char($BF)+SysToUTF8(ConvertEncoding(tmp,aEncoding,EncodingUTF8));
           ss.Free;
           ss:=TStringStream.Create(tmp);
{
           sl := TStringList.Create;
           sl.Text:=tmp;
           sl.SaveToFile(GetTempDir+'amessage.html');
           sl.Free;
           exit;
}
           NewHTML:=TSimpleIpHtml.Create; // Beware:Will be freed automatically by IpHtmlPanel1
           proc := TLoadHTMLProcess.Create(Self,NewHTML,ss);
           for i := 0 to 1000 do
             begin
               if Proc.Done then
                 break;
               if Assigned(proc.FatalException) then
                 begin
                   Proc.Terminate;
                   FreeAndNil(NewHTML);
                   break;
                 end;
               Application.ProcessMessages;
               sleep(1);
             end;
           if i > 100 then
             begin
               proc.Terminate;
               NewHTML := nil;
               exit;
             end;
           Proc.Free;
           ss.Free;
           try
             ipHTMLContent.SetHtml(NewHTML);
           except
             FreeAndNil(NewHTML);
             try
               ipHTMLContent.SetHtml(nil);
             except
             end;
           end;
         except
           ss.Free;
         end;
         ipHTMLContent.Visible:=true;
       end
     else if UpperCase(Messages.FieldByName('TYPE').AsString) = 'WIKI' then
       begin
         mContent.Visible:=false;
         try
           ss:=TStringStream.Create('');
           Data.BlobFieldToStream(Messages.Content.DataSet,'DATA',ss);
           ss.Position := 0;
           tmp := '<html><body>'+WikiText2HTML(ss.DataString,'','',True)+'</body></html>';

           aEncoding := GuessEncoding(tmp);
           if pos('ENCODING',Uppercase(tmp)) = 0 then
             tmp := char($EF)+char($BB)+char($BF)+SysToUTF8(ConvertEncoding(tmp,aEncoding,EncodingUTF8));
           ss.Free;
           ss:=TStringStream.Create(tmp);
           NewHTML:=TSimpleIpHtml.Create; // Beware:Will be freed automatically by IpHtmlPanel1
           proc := TLoadHTMLProcess.Create(Self,NewHTML,ss);
           for i := 0 to 1000 do
             begin
               if Proc.Done then
                 break;
               if Assigned(proc.FatalException) then
                 begin
                   Proc.Terminate;
                   FreeAndNil(NewHTML);
                   break;
                 end;
               Application.ProcessMessages;
               sleep(1);
             end;
           if i > 100 then
             begin
               proc.Terminate;
               NewHTML := nil;
               exit;
             end;
           Proc.Free;
           ss.Free;
           try
             ipHTMLContent.SetHtml(NewHTML);
           except
             FreeAndNil(NewHTML);
             try
               ipHTMLContent.SetHtml(nil);
             except
             end;
           end;
         except
           ss.Free;
         end;
         ipHTMLContent.Visible:=true;
       end
     else
       begin
         ipHTMLContent.Visible:=false;
         ss := TStringStream.Create('');
         Data.BlobFieldToStream(Messages.Content.DataSet,'DATA',ss);
         mContent.Lines.Text:='Unknown Datatype ('+Messages.Content.FieldByName('DATATYP').AsString+'):'+ss.DataString;
         ss.Free;
         mContent.Visible:=True;
       end;
   end
  else
   begin
     ipHTMLContent.Visible:=false;
     mContent.Visible:=false;
     if ListDataSet.FieldByName('TYPE').AsString = 'LETTE' then
       begin
         if ShowLetter then
           begin
             Data.SetFilter(Messages.Documents,'');
             {
             if Data.GotoID(Data.MessageIdx.FieldByName('ID').AsString) then
               begin
                 iContent.Visible := True;
                 ID := Data.Documents.FieldByName('NUMBER').AsString;
                 Data.SetFilter(Data.Documents,'"NUMBER"='+ID);
                 Data.Documents.DataSet.Last;
                 Data.DataModule.BlobFieldToFile(Data.Documents.DataSet,'DOCUMENT',GetTempDir+'messagetmp.jpg');
                 iiContent.Picture.LoadFromFile(GetTempDir+'messagetmp.jpg');
                 iiContent.Height:=(iiContent.Width*iiContent.Picture.Height) div iiContent.Picture.Width;
                 iiContent.Stretch:=True;
                 DeleteFileUTF8(GetTempDir+'messagetmp.jpg');
               end;
             }
           end;
       end;
   end;
end;
constructor TLoadHTMLProcess.Create(View : TfViewMessage;HTML: TSimpleIPHTML; sss: TStream);
begin
  FView := View;
  FHTML := HTML;
  ss := sss;
  FDone := False;
  FExcept := False;
  inherited Create(false);
end;
procedure TLoadHTMLProcess.Execute;
begin
  FHTML.OnGetImageX:=@FView.OnGetImage;
  FHTML.LoadFromStream(ss);
  FDone := True;
end;
initialization
  {$I uviewmessage.lrs}

end.
