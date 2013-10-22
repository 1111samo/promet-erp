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
Created 22.10.2013
*******************************************************************************}
unit ucameraimport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ButtonPanel, process, UTF8Process,ProcessUtils,uIntfStrConsts,
  umanagedocframe;

type

  { TfCameraimport }

  TfCameraimport = class(TForm)
    Button1: TButton;
    bImport: TButton;
    ButtonPanel1: TButtonPanel;
    cbCamera: TComboBox;
    cbDelete: TCheckBox;
    Label1: TLabel;
    lvPhotos: TListView;
    procedure bImportClick(Sender: TObject);
    procedure cbCameraSelect(Sender: TObject);
  private
    { private declarations }
    FDoc: TfManageDocFrame;
  public
    { public declarations }
    function ImportAvalibe : Boolean;
    function Execute(aDocMan : TfManageDocFrame) : Boolean;
  end;

var
  fCameraimport: TfCameraimport;

implementation
uses uBaseDocPages,Utils;
{$R *.lfm}

{ TfCameraimport }

procedure TfCameraimport.cbCameraSelect(Sender: TObject);
var
  aProcess: TProcessUTF8;
  sl: TStringList;
  i: Integer;
  aItem: TListItem;
begin
  aProcess := TProcessUTF8.Create(nil);
  sl := TStringList.Create;
  try
    aProcess.CommandLine:='gphoto2 -L';
    aProcess.Options:=[poUsePipes,poWaitOnExit];
    aProcess.Execute;
    sl.LoadFromStream(aProcess.Output);
  finally
    aProcess.Free;
  end;
  i := 0;
  lvPhotos.Clear;
  while i < sl.Count do
    begin
      if (copy(sl[i],0,1)='#') and (pos('image/',sl[i])>0) then
        begin
          aItem := lvPhotos.Items.Add;
          aItem.Caption:=sl[i];
          inc(i);
        end
      else
        sl.Delete(i);
    end;

end;

procedure TfCameraimport.bImportClick(Sender: TObject);
var
  aProcess: TProcessUTF8;
  AInfo: TSearchRec;
  atmp: String;
  aFile: String;
  NewFileName: String;
  sl: TStringList;
  extn: String;
  aSecFile: String;
begin
  if lvPhotos.Selected=nil then exit;
  If FindFirstUTF8(AppendPathDelim(GetTempDir)+'raw_*',faAnyFile,AInfo)=0 then
    Repeat
      With aInfo do
        begin
          If (Attr and faDirectory) <> faDirectory then
            DeleteFileUTF8(AppendPathDelim(GetTempDir)+AInfo.Name);
        end;
    Until FindNext(ainfo)<>0;
  FindClose(aInfo);
  atmp := lvPhotos.Selected.Caption;
  atmp := copy(atmp,2,pos(' ',atmp)-2);
  sl := TStringList.Create;
  aProcess := TProcessUTF8.Create(nil);
  aProcess.CurrentDirectory:=GetTempDir;
  try
    aProcess.CommandLine:='gphoto2 --get-raw-data='+atmp;
    aProcess.Options:=[poUsePipes,poWaitOnExit];
    aProcess.Execute;
    sl.LoadFromStream(aProcess.Output);
  finally
    aProcess.Free;
  end;
  If FindFirstUTF8(AppendPathDelim(GetTempDir)+'raw_*',faAnyFile,AInfo)=0 then
    Repeat
      With aInfo do
        begin
          If (Attr and faDirectory) <> faDirectory then
            begin
              aFile := AppendPathDelim(GetTempDir)+AInfo.Name;
            end;
        end;
    Until FindNext(ainfo)<>0;
  sl.Free;
  if not FileExists(aFile) then
    begin
      NewFileName := AppendPathDelim(GetTempDir)+ExtractFileName(aFile);
      {$ifdef linux}
      ExecProcess('gvfs-copy "'+aFile+'" "'+NewFileName+'"');
      {$endif}
      if not FileExists(NewFileName) then
        Showmessage(Format(strCantAccessFile,[aFile]));
    end
  else NewFileName:=aFile;
  if FileExists(NewFileName) then
    begin
      TDocPages(FDoc.DataSet).AddFromFile(NewFileName);
      if not TDocPages(FDoc.DataSet).CanEdit then TDocPages(FDoc.DataSet).DataSet.Edit;
      TDocPages(FDoc.DataSet).Post;
      if cbDelete.Checked then
        begin
          sl := TStringList.Create;
          aProcess := TProcessUTF8.Create(nil);
          aProcess.CurrentDirectory:=GetTempDir;
          try
            aProcess.CommandLine:='gphoto2 --delete-file='+atmp;
            aProcess.Options:=[poUsePipes,poWaitOnExit];
            aProcess.Execute;
            sl.LoadFromStream(aProcess.Output);
          finally
            aProcess.Free;
          end;
          sl.Free;
          aFile := NewFileName;
          extn :=  AnsiString(AnsiLowerCase(ExtractFileExt(aFile)));
          if (extn = '.cr2')
          or (extn = '.crw')
          or (extn = '.dng')
          or (extn = '.raw')
          or (extn = '.erf')
          or (extn = '.raf')
          or (extn = '.3fr')
          or (extn = '.fff')
          or (extn = '.dcr')
          or (extn = '.dcs')
          or (extn = '.kdc')
          or (extn = '.rwl')
          or (extn = '.mef')
          or (extn = '.mfw')
          or (extn = '.iiq')
          or (extn = '.mrw')
          or (extn = '.mdc')
          or (extn = '.nef')
          or (extn = '.nrw')
          or (extn = '.orf')
          or (extn = '.rw2')
          or (extn = '.pef')
          or (extn = '.srw')
          or (extn = '.x3f')
          or (extn = '.cs1')
          or (extn = '.cs4')
          or (extn = '.cs16')
          or (extn = '.srf')
          or (extn = '.sr2')
          or (extn = '.arw')
          then
            begin
              if FileExistsUTF8(copy(aFile,0,rpos('.',aFile)-1)+'.jpg') then
                aSecFile := copy(aFile,0,rpos('.',aFile)-1)+'.jpg'
              else if FileExistsUTF8(copy(aFile,0,rpos('.',aFile)-1)+'.JPG') then
                aSecFile := copy(aFile,0,rpos('.',aFile)-1)+'.JPG'
              else if FileExistsUTF8(copy(aFile,0,rpos('.',aFile)-1)+'.Jpg') then
                aSecFile := copy(aFile,0,rpos('.',aFile)-1)+'.Jpg'
              else aSecFile:='';
              if aSecFile <> '' then
                begin
                  {$ifdef linux}
                  try
                    ExecProcess('gvfs-rm "'+aSecFile+'"');
                  except
                    DeleteFileUTF8(aSecFile);
                  end;
                  {$else}
                  DeleteFileUTF8(aSecFile);
                  {$endif}
                end;
            end;
          if FileExistsUTF8(copy(NewFileName,0,length(NewFileName)-length(extn))+'.ufraw') then
            DeleteFileUTF8(copy(NewFileName,0,length(NewFileName)-length(extn))+'.ufraw');
          DeleteFileUTF8(NewFileName);
          if NewFileName<>aFile then
            begin
              {$ifdef linux}
              ExecProcess('gvfs-rm "'+aFile+'"');
              {$endif}
            end;
        end;
      FDoc.acRefresh.Execute;
      lvPhotos.Selected.Delete;
    end;
  cbCameraSelect(nil);
end;

function TfCameraimport.ImportAvalibe: Boolean;
var
  aProcess: TProcessUTF8;
  sl: TStringList;
begin
  if not Assigned(Self) then
    begin
      Application.CreateForm(TfCameraimport,fCameraimport);
      Self := fCameraimport;
    end;
  Result := False;
  aProcess := TProcessUTF8.Create(nil);
  sl := TStringList.Create;
  try
    aProcess.CommandLine:='gphoto2 --auto-detect';
    aProcess.Options:=[poUsePipes,poWaitOnExit];
    aProcess.Execute;
    sl.LoadFromStream(aProcess.Output);
  finally
    aProcess.Free;
  end;
  Result := sl.Count>0;
  if sl.Count>0 then
    sl.Delete(0);
  if sl.Count>0 then
    sl.Delete(0);
  cbCamera.Clear;
  cbCamera.Items.Assign(sl);
  sl.Free;
end;

function TfCameraimport.Execute(aDocMan: TfManageDocFrame): Boolean;
begin
  if not Assigned(Self) then
    begin
      Application.CreateForm(TfCameraimport,fCameraimport);
      Self := fCameraimport;
    end;
  FDoc := aDocMan;
  ImportAvalibe;//Check for Cameras
  Result := ShowModal=mrOK;
end;

end.

