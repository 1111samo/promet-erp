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
Created 22.12.2013
*******************************************************************************}
unit uthumbnails;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uDocuments,Utils,Graphics,FileUtil,variants,
  FPImage,fpreadgif,FPReadPSD,FPReadPCX,FPReadTGA,FPReadJPEGintfd,fpthumbresize,
  FPWriteJPEG,UTF8Process,FPReadBMP,process,LCLProc;

function GetThumbnailPath(aDocument : TDocuments;aWidth : Integer=310;aHeight : Integer=428) : string;
function GetThumbnailBitmap(aDocument : TDocuments;aWidth : Integer=310;aHeight : Integer=428) : TBitmap;
function GetThumbTempDir : string;
function ClearThumbDir : Boolean;
function GenerateThumbNail(aName : string;aFullStream,aStream : TStream;aWidth : Integer=310;aHeight : Integer=428) : Boolean;
function GenerateThumbNail(aName : string;aFileName : string;aStream : TStream;aWidth : Integer=310;aHeight : Integer=428) : Boolean;

implementation

function GetThumbnailPath(aDocument: TDocuments;aWidth : Integer=310;aHeight : Integer=428): string;
var
  bDocument: TDocument;
  aFullStream: TMemoryStream;
  aFilename: String;
  aStream: TFileStream;
  aNumber: String;
  DelStream: Boolean;
begin
  Result := '';
  aFilename := AppendPathDelim(GetThumbTempDir)+VarToStr(aDocument.Ref_ID);
  aFilename := aFilename+'_'+IntToStr(aWidth)+'x'+IntToStr(aHeight);
  aFilename:=aFilename+'.jpg';
  if not FileExists(aFilename) then
    begin
      aNumber := aDocument.FieldByName('NUMBER').AsString;
      bDocument := TDocument.Create(nil,aDocument.DataModule);
      bDocument.SelectByNumber(aNumber);
      bDocument.Open;
      aFullStream := TMemoryStream.Create;
      bDocument.CheckoutToStream(aFullStream);
      bDocument.Free;
      try
        aStream := TFileStream.Create(aFilename,fmCreate);
        GenerateThumbNail(aFilename,aFullStream,aStream,aWidth,aHeight);
        DelStream := aStream.Size=0;
        aStream.Free;
      except
        DelStream:=True;
      end;
      try
        if DelStream then
          DeleteFileUTF8(aFilename)
        else Result := aFilename;
      except
      end;
    end
  else
    Result := aFilename;
end;

function GetThumbnailBitmap(aDocument: TDocuments;aWidth : Integer=310;aHeight : Integer=428): TBitmap;
var
  aJpg: TJPEGImage;
  aFilename: String;
begin
  Result := TBitmap.Create;
  try
    try
      aFilename := GetThumbNailPath(aDocument,aWidth,aHeight);
      if aFilename='' then exit;
      aJpg := TJPEGImage.Create;
      try
        aJpg.LoadFromFile(aFilename);
      except
        begin
          aJpg.Free;
          exit;
        end;
      end;
      Result.Width:=aJpg.Width;
      Result.Height:=aJpg.Height;
      Result.Canvas.Draw(0,0,aJpg);
    except
      FreeAndNil(Result);
    end;
  finally
    aJpg.Free;
  end;
end;

function GetThumbTempDir: string;
begin
  Result := GetTempDir+'promet_thumbs';
  ForceDirectoriesUTF8(Result);
end;

function ClearThumbDir: Boolean;
begin
  Result := RemoveDirUTF8(GetThumbTempDir);
end;

function GenerateThumbNail(aName: string; aFullStream, aStream: TStream;
  aWidth: Integer; aHeight: Integer): Boolean;
var
  e: String;
  r: Integer;
  s: String;
  d: TIHData;
  aFStream: TFileStream;
  aFilename: String;
begin
  Result := True;
  e := lowercase (ExtractFileExt(aName));
  if (e <> '') and (e[1] = '.') then
    System.delete (e,1,1);
  s := e + ';';
  aFilename := getTempDir+'rpv.'+e;
  aFStream := TFileStream.Create(getTempDir+'rpv.'+e,fmCreate);
  aFullStream.Position:=0;
  aFStream.CopyFrom(aFullStream,aFullStream.Size);
  aFStream.Free;
  Result := GenerateThumbNail(aName,aFilename,aStream,aWidth,aHeight);
  SysUtils.DeleteFile(aFileName);
end;

function GenerateThumbNail(aName: string; aFileName: string; aStream: TStream;
  aWidth: Integer; aHeight: Integer): Boolean;
var
  Img: TFPMemoryImage = nil;
  e: String;
  s: String;
  h: TFPCustomImageReaderClass = nil;
  reader: TFPCustomImageReader;
  Msg: String;
  iOut: TFPMemoryImage;
  wr: TFPWriterJPEG;
  area: TRect;
  aProcess: TProcessUTF8;
  i: Integer;

  function ConvertExec(aCmd,aExt : string) : Boolean;
  begin
    aProcess := TProcessUTF8.Create(nil);
    {$IFDEF WINDOWS}
    aProcess.Options:= [poNoConsole, poWaitonExit,poNewConsole, poStdErrToOutPut, poNewProcessGroup];
    {$ELSE}
    aProcess.Options:= [poWaitonExit,poStdErrToOutPut];
    {$ENDIF}
    aProcess.ShowWindow := swoHide;
    aProcess.CommandLine := aCmd;
    aProcess.CurrentDirectory := AppendPathDelim(ExtractFileDir(ParamStrUTF8(0)))+'tools';
    try
      aProcess.Execute;
    except
      on e : Exception do
        begin
          debugln(e.Message);
          result := False;
        end;
    end;
    Result := FileExists(aFileName+aExt);
    aProcess.Free;
    if Result then
      begin
        Img := TFPMemoryImage.Create(0, 0);
        Img.UsePalette := false;
        try
          Img.LoadFromFile(aFileName+aExt);
          SysUtils.DeleteFile(aFileName+aExt);
        except
          FreeAndNil(Img);
        end;
      end;
  end;

begin
  try
    e := lowercase (ExtractFileExt(aName));
    if (e <> '') and (e[1] = '.') then
      System.delete (e,1,1);
    s := e + ';';
    if (s = 'jpg;') or (s='jpeg;') then
      h := TFPReaderJPEG
    else
      for i := 0 to ImageHandlers.Count-1 do
        if pos(s,ImageHandlers.{$IF FPC_FULLVERSION>20604}Extensions{$ELSE}Extentions{$ENDIF}[ImageHandlers.TypeNames[i]]+';')>0 then
          begin
            h := ImageHandlers.ImageReader[ImageHandlers.TypeNames[i]];
            break;
          end;
    if assigned (h) then
      begin
        Img := TFPMemoryImage.Create(0, 0);
        Img.UsePalette := false;
        reader := h.Create;
        if reader is TFPReaderJPEG then
          begin
            TFPReaderJPEG(reader).MinHeight:=aHeight;
            TFPReaderJPEG(reader).MinWidth:=aWidth;
          end;
        try
          Img.LoadFromFile(aFilename, reader);
          if reader is TFPReaderJPEG then
            begin
            end;
        except
          FreeAndNil(Img);
        end;
        Reader.Free;
      end
    else if (s = 'pdf;') then
      begin
        Result := ConvertExec(Format({$IFDEF WINDOWS}AppendPathDelim(AppendPathDelim(ExtractFileDir(ParamStrUTF8(0)))+'tools')+'gswin32'+{$ELSE}'gs'+{$ENDIF}' -q -dBATCH -dMaxBitmap=300000000 -dNOPAUSE -dSAFER -sDEVICE=bmp16m -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -dFirstPage=1 -dLastPage=1 -sOutputFile=%s %s -c quit',[aFileName+'.bmp',aFileName]),'.bmp');
      end
    else
      begin
        Result := ConvertExec(Format({$IFDEF WINDOWS}AppendPathDelim(AppendPathDelim(ExtractFileDir(ParamStrUTF8(0)))+'tools')+{$ENDIF}'convert %s[1] -resize %d -alpha off +antialias "%s"',[aFileName,500,afileName+'.bmp']),'.bmp');
        if not Result then
          Result := ConvertExec(Format({$IFDEF WINDOWS}AppendPathDelim(AppendPathDelim(ExtractFileDir(ParamStrUTF8(0)))+'tools')+{$ENDIF}'ffmpeg -i "%s" -sameq -vframes 1 "%s"',[aFileName,aFileName+'.bmp']),'.bmp');
      end;
    SysUtils.DeleteFile(aFileName);
    if Assigned(Img) then
      begin
        iOut := ThumbResize(Img, aWidth, aHeight, area);
        wr := TFPWriterJPEG.Create;
        wr.ProgressiveEncoding:=True;
        iOut.SaveToStream(aStream,wr);
        wr.Free;
        iOut.Free;
        Img.Free;
      end;
  except
    Result := False;
  end;
end;

end.

