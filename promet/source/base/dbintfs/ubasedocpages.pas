{*******************************************************************************
Dieser Sourcecode darf nicht ohne gültige Geheimhaltungsvereinbarung benutzt werden
und ohne gültigen Vertriebspartnervertrag weitergegeben werden.
You have no permission to use this Source without valid NDA
and copy it without valid distribution partner agreement
Christian Ulrich
info@cu-tec.de
Created 26.03.2013
*******************************************************************************}
unit uBaseDocPages;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils,uDocuments,uBaseDbClasses,uBaseDBInterface,db,uIntfStrConsts,
  FPImage,fpreadgif,FPReadPSD,FPReadPCX,FPReadTGA,FPReadJPEGintfd,fpthumbresize,
  FPWriteJPEG,Utils;
type
  TDocPages = class(TBaseDBDataset)
  private
    FUsedFields : string;
    procedure SetParamsFromExif(extn : string;aFullStream : TStream);
  public
    function GetUsedFields : string;
    procedure PrepareDataSet;
    procedure Open; override;
    procedure Select(aID: Variant); override;
    procedure DefineFields(aDataSet: TDataSet); override;
    procedure Add(aDocuments: TDocuments);
    procedure AddFromFile(aFile : UTF8String);
    procedure GenerateThumbNail(aName : string;aFullStream,aStream : TStream;aWidth : Integer=310;aHeight : Integer=428);
  end;

implementation
uses uData,uBaseApplication,dEXIF,UTF8Process,process,LCLProc,ProcessUtils;

procedure TDocPages.SetParamsFromExif(extn: string; aFullStream: TStream);
var
  exif: TImgData;
  aTime: TDateTime;
begin
  exif := TImgData.Create;
  aFullStream.Position:=0;
  if (extn = '.jpg') or (extn = '.jpeg') or (extn = '.jpe') then
    begin
      exif.ReadJpegSections(tStream(aFullStream));
    end;
  if (extn = '.tif') or (extn = '.tiff') or (extn = '.nef') then
    begin
      exif.ReadTiffSections(tStream(aFullStream));
    end;
  if Assigned(exif.ExifObj) then
    begin
      if exif.ExifObj.dt_orig_oset > 0 then
        aTime := exif.ExifObj.ExtrDateTime(exif.ExifObj.dt_orig_oset)
      else
        aTime := exif.ExifObj.GetImgDateTime;
      if aTime > 0 then
        FieldByName('ORIGDATE').AsDateTime:=aTime;
    end;
  if Assigned(exif.IptcObj) then
    begin
      aTime := exif.IptcObj.GetDateTime;
      if aTime > 0 then
        FieldByName('ORIGDATE').AsDateTime:=aTime;
    end;
  exif.Free;
end;

function TDocPages.GetUsedFields: string;
var
  tmpFields : string = '';
  i: Integer;
  aOldLimit: Integer;
  OldUseP: Boolean;
begin
  if FUsedFields = '' then
    begin
      with BaseApplication as IBaseDbInterface do
        begin
          with Self.DataSet as IBaseDBFilter,Self.DataSet as IBaseManageDB do
            begin
              Filter := ProcessTerm(Data.QuoteField(TableName)+'.'+Data.QuoteField('SQL_ID')+'='+Data.QuoteValue(''));
              Fields := '';
              aOldLimit := Limit;
              Limit := 1;
              OldUseP := UsePermissions;
              UsePermissions:=False;
              Open;
              for i := 0 to DataSet.FieldDefs.Count-1 do
                if  (DataSet.FieldDefs[i].Name <> 'THUMBNAIL')
                and (DataSet.FieldDefs[i].Name <> 'FULLTEXT') then
                  tmpfields := tmpfields+','+Data.QuoteField(TableName)+'.'+Data.QuoteField(DataSet.FieldDefs[i].Name);
              tmpFields := copy(tmpFields,2,length(tmpFields));
              FUsedFields := tmpFields;
              Limit := aOldLimit;
              UsePermissions:=OldUseP;
              Filter := '';
            end;
        end;
    end;
  Result := FUsedFields;
end;

procedure TDocPages.PrepareDataSet;
begin
  if FUsedFields = '' then
    GetUsedFields;
  with DataSet as IBaseDBFilter do
    begin
      Fields:=FUsedFields;
    end;
end;

procedure TDocPages.Open;
begin
  inherited Open;
end;

procedure TDocPages.Select(aID: Variant);
var
  tmp: String;
begin
  with DataSet as IBaseDBFilter do
    begin
      tmp := GetUsedFields;
      Fields := tmp;
    end;
  inherited Select(aID);
end;

procedure TDocPages.DefineFields(aDataSet: TDataSet);
begin
  with aDataSet as IBaseManageDB do
    begin
      TableName := 'DOCPAGES';
      TableCaption:=strDocuments;
      if Assigned(ManagedFieldDefs) then
        with ManagedFieldDefs do
          begin
            Add('PAGE',ftInteger,0,False);
            Add('TAGS',ftString,500,False);
            Add('NAME',ftString,100,False);
            Add('ORIGDATE',ftDateTime,0,False);
            Add('CHANGEDBY',ftString,4,False);
            Add('FULLTEXT',ftString,500,False);
            Add('THUMBNAIL',ftBlob,0,False);
          end;
    end;
end;

procedure TDocPages.Add(aDocuments: TDocuments);
var
  aDocument: TDocument;
  aStream: TMemoryStream;
  aFullStream: TMemoryStream;
  extn: String;
  aTime: TDateTime;
  bDocument: TDocument;
begin
  aDocument := TDocument.Create(nil,Data);
  aDocument.SelectByID(aDocuments.Id.AsVariant);
  aDocument.Open;
  if aDocument.Count>0 then
    begin
      Insert;
      FieldByName('NAME').AsString:=aDocuments.FileName;
      aStream := TMemoryStream.Create;
      aFullStream := TMemoryStream.Create;
      aDocument.CheckoutToStream(aFullStream);
      extn :=  AnsiString(AnsiLowerCase(ExtractFileExt(aDocuments.filename)));
      aFullStream.Position:=0;
      SetParamsFromExif(extn,aFullStream);
      GenerateThumbNail(ExtractFileExt(aDocument.FileName),aFullStream,aStream);
      if FieldByName('ORIGDATE').IsNull then
        FieldByName('ORIGDATE').AsDateTime:=aDocument.FieldByName('DATE').AsDateTime;
      if FieldByName('ORIGDATE').IsNull then
        FieldByName('ORIGDATE').AsDateTime:=Now();
      Post;
      if aStream.Size>0 then
        Data.StreamToBlobField(aStream,Self.DataSet,'THUMBNAIL');
      bDocument := TDocument.Create(nil,Data);
      bdocument.Ref_ID:=Id.AsVariant;
      bDocument.BaseTyp:='S';
      bDocument.AddFromLink(Data.BuildLink(aDocument.DataSet));
      bDocument.Free;
      aStream.Free;
      aFullStream.Free;
    end;
  aDocument.Free;
end;

procedure TDocPages.AddFromFile(aFile: UTF8String);
var
  aDocument: TDocument;
  aStream: TMemoryStream;
  aFullStream: TMemoryStream;
  extn: String;
  aTime: TDateTime;
  aSecFile: String = '';
  aProc: TProcess;
  aSL: TStringList;
begin
  if FileExists(aFile) then
    begin
      Insert;
      FieldByName('NAME').AsString:=ExtractFileName(aFile);
      Post;
      DataSet.Edit;
      aDocument := TDocument.Create(nil,Data);
      adocument.Ref_ID:=Id.AsVariant;
      aDocument.BaseTyp:='S';
      aDocument.AddFromFile(aFile);
      aStream := TMemoryStream.Create;
      aFullStream := TMemoryStream.Create;
      extn :=  AnsiString(AnsiLowerCase(ExtractFileExt(aDocument.filename)));
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
          if FileExists(copy(aFile,0,rpos('.',aFile)-1)+'.jpg') then
            aSecFile := copy(aFile,0,rpos('.',aFile)-1)+'.jpg'
          else if FileExists(copy(aFile,0,rpos('.',aFile)-1)+'.JPG') then
            aSecFile := copy(aFile,0,rpos('.',aFile)-1)+'.JPG'
          else if FileExists(copy(aFile,0,rpos('.',aFile)-1)+'.Jpg') then
            aSecFile := copy(aFile,0,rpos('.',aFile)-1)+'.Jpg';
          if aSecFile = '' then
            begin
              ExecProcessEx('ufraw-batch --silent --create-id=also --out-type=jpg --exif "--output='+copy(aFile,0,rpos('.',aFile)-1)+'.jpg"'+' "'+aFile+'"');
              if FileExists(copy(aFile,0,rpos('.',aFile)-1)+'.jpg') then
                aSecFile := copy(aFile,0,rpos('.',aFile)-1)+'.jpg'
            end;
          if aSecFile <> '' then
            begin
              aDocument.Free;
              aDocument := TDocument.Create(nil,Data);
              adocument.Ref_ID:=Id.AsVariant;
              aDocument.BaseTyp:='S';
              aDocument.AddFromFile(aSecFile);
              aDocument.CheckoutToStream(aFullStream);
              extn :=  AnsiString(AnsiLowerCase(ExtractFileExt(aDocument.filename)));
            end;
        end;
      if aFullStream.Size=0 then
        aDocument.CheckoutToStream(aFullStream);
      SetParamsFromExif(extn,aFullStream);
      if FieldByName('ORIGDATE').IsNull then
        FieldByName('ORIGDATE').AsDateTime:=aDocument.FieldByName('DATE').AsDateTime;
      if FieldByName('ORIGDATE').IsNull then
        FieldByName('ORIGDATE').AsDateTime:=Now();
      GenerateThumbNail(ExtractFileExt(aDocument.FileName),aFullStream,aStream);
      Post;
      if aStream.Size>0 then
        Data.StreamToBlobField(aStream,Self.DataSet,'THUMBNAIL');
      aStream.Free;
      aFullStream.Free;
      aDocument.Free;
    end;
end;

procedure TDocPages.GenerateThumbNail(aName : string;aFullStream, aStream: TStream;aWidth : Integer;aHeight : Integer);
var
  Img: TFPMemoryImage = nil;
  i: Integer;
  e: String;
  r: Integer;
  s: String;
  d: TIHData;
  h: TFPCustomImageReaderClass;
  reader: TFPCustomImageReader;
  Msg: String;
  iOut: TFPMemoryImage;
  wr: TFPWriterJPEG;
  area: TRect;
begin
  e := lowercase (ExtractFileExt(aName));
  if (e <> '') and (e[1] = '.') then
    System.delete (e,1,1);
  s := e + ';';
  if (s = 'jpg;') or (s='jpeg;') then
    h := TFPReaderJPEG
  else
    for i := 0 to ImageHandlers.Count-1 do
      if pos(s,ImageHandlers.Extentions[ImageHandlers.TypeNames[i]]+';')>0 then
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
        Img.LoadFromStream(aFullStream, reader);
        if reader is TFPReaderJPEG then
          begin
          end;
      finally
        Reader.Free;
      end;
    end;
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
end;

end.

