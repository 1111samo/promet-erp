unit ushop; 
{$mode objfpc}{$H+}
interface
uses
  SysUtils, Classes, httpdefs, fpHTTP, fpWeb, uMasterdata,
  fpTemplate, uOrder,uerror,uBaseSearch,uBaseDbClasses;
type

  { TfmShop }

  TfmShop = class(TFPWebModule)
    procedure addtobasketRequest(Sender: TObject; ARequest: TRequest;
      AResponse: TResponse; var Handled: Boolean);
    procedure basketactionRequest(Sender: TObject; ARequest: TRequest;
      AResponse: TResponse; var Handled: Boolean);
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure DataModuleGetAction(Sender: TObject; ARequest: TRequest;
      var ActionName: String);
    procedure FSearchItemFound(aIdent: string; aName: string; aStatus: string;aActive : Boolean;
      aLink: string; aItem: TBaseDBList=nil);
    procedure ReplaceBasketDetailTags(Sender: TObject; const TagString: String;
      TagParams: TStringList; out ReplaceText: String);
    procedure ReplaceDetailTags(Sender: TObject; const TagString: String;
      TagParams: TStringList; out ReplaceText: String);
    procedure ReplaceShopDetailTags(Sender: TObject; const TagString: String;
      TagParams: TStringList; out ReplaceText: String);
    procedure ReplaceShopTags(Sender: TObject; const TagString: String;
      TagParams: TStringList; out ReplaceText: String);
    procedure ReplaceMenueTags(Sender: TObject; const TagString: String;
      TagParams: TStringList; out ReplaceText: String);
    procedure ReplaceBasketTags(Sender: TObject; const TagString: String;
      TagParams: TStringList; out ReplaceText: String);
    procedure ReplaceOverviewTags(Sender: TObject; const TagString: String;
      TagParams: TStringList; out ReplaceText: String);
    procedure searchRequest(Sender: TObject; ARequest: TRequest;
      AResponse: TResponse; var Handled: Boolean);
    procedure SearchTagreplace(Sender: TObject; const TagString: String;
      TagParams: TStringList; out ReplaceText: String);
    procedure showbasketRequest(Sender: TObject; ARequest: TRequest;
      AResponse: TResponse; var Handled: Boolean);
    procedure showdetailRequest(Sender: TObject; ARequest: TRequest;
      AResponse: TResponse; var Handled: Boolean);
    procedure showRequest(Sender: TObject; ARequest: TRequest;
      AResponse: TResponse; var Handled: Boolean);
  private
    { private declarations }
    Menue : TStringList;
    aParent : Variant;
    SelectedPath : string;
    SelectedParent : Integer;
    SelectedArticle : string;
    FSearch: TSearch;
    FSearchResult : TStringList;
  public
    { public declarations }
    Masterdata : TMasterdataList;
    aMasterdata : TMasterdata;
    aOrder : TOrder;
  end;
var
  fmShop: TfmShop;
implementation
{$R *.lfm}
uses uBaseApplication,uData,Variants,db,FileUtil, Utils,
  uWebWiki, uBaseFCGIApplication,fpImage, FPReadJPEGintfd, fpCanvas,fpImgCanv,
  uIntfStrConsts;
resourcestring
  strCategory                                 = 'Kategorien';
  strClickToEnlarge                           = 'zum vergrössern klicken';
procedure TfmShop.addtobasketRequest(Sender: TObject; ARequest: TRequest;
  AResponse: TResponse; var Handled: Boolean);
var
  aBasket: Variant;
begin
  SelectedArticle := '';
  if ARequest.QueryFields.Values['Id'] <> '' then
    begin
      fmWikiPage.SetTemplateParams(TFPWebAction(Sender).Template);
      SelectedArticle := ARequest.QueryFields.Values['Id'];
      aMasterdata := TMasterdata.Create(Self,Data);
      if copy(SelectedArticle,pos('_',SelectedArticle)+1,length(SelectedArticle)) = '' then
        aMasterdata.Select(copy(SelectedArticle,0,pos('_',SelectedArticle)-1),Null,'de')
      else
        aMasterdata.Select(copy(SelectedArticle,0,pos('_',SelectedArticle)-1),copy(SelectedArticle,pos('_',SelectedArticle)+1,length(SelectedArticle)),'de');
      aMasterdata.Open;
      if aMasterdata.Count > 0 then
        begin
          if Session.Variables['BASKET'] = '' then
            begin
              aOrder.Insert;
              aOrder.DataSet.Post;
              uerror.fmError.GetGeoData(Session,ARequest);
              aOrder.Address.Insert;
              if Data.Countries.DataSet.Locate('NAME',Session.Variables['Country'],[loCaseInsensitive]) then
                aOrder.Address.FieldByName('COUNTRY').AsString:=Data.Countries.FieldByName('ID').AsString
              else aOrder.Address.FieldByName('COUNTRY').AsString:='DE';//TODO:Dont hardcode that
              aOrder.Address.FieldByName('NAME').AsString := '';
              aOrder.Address.FieldByName('ACCOUNTNO').AsString := '';
              aOrder.Address.DataSet.Post;
              Session.Variables['BASKET'] := aOrder.Id.AsString;
            end
          else
            begin
              aBasket := StrToInt(Session.Variables['BASKET']);
              aOrder.Select(aBasket);
              aOrder.Open;
              if aOrder.Count = 0 then
                Session.Variables['BASKET'] := '';
            end;
          aOrder.Positions.Open;
          if aOrder.Positions.DataSet.Locate('IDENT',aMasterdata.FieldByName('ID').AsString,[]) then
            begin
              if not aOrder.Positions.CanEdit then
                aOrder.Positions.DataSet.Edit;
              aOrder.Positions.FieldByName('QUANTITY').AsFloat := aOrder.Positions.FieldByName('QUANTITY').AsFloat+StrToFloat(ARequest.QueryFields.Values['quantity']);
            end
          else
            begin
              aOrder.Positions.DataSet.Insert;
              aOrder.Positions.FieldByName('QUANTITY').AsFloat := StrToFloat(ARequest.QueryFields.Values['quantity']);
              aOrder.Positions.Assign(aMasterdata);
            end;
          if aOrder.Positions.CanEdit then aOrder.Positions.DataSet.Post;
          if aOrder.CanEdit then aOrder.DataSet.Post;
          aOrder.CalcDispatchType;
        end;
      aMasterdata.Free;
      Data.SetFilter(Masterdata,Data.QuoteField('TREEENTRY')+'='+Data.QuoteValue(IntToStr(aParent))+' and '+Data.QuoteField('SALEITEM')+'='+Data.QuoteValue('Y'),10);
      TFPWebAction(Sender).Template.OnReplaceTag := @ReplaceShopTags;
      AResponse.Content := TFPWebAction(Sender).Template.GetContent;
      Handled := true;
    end;
end;
procedure TfmShop.basketactionRequest(Sender: TObject; ARequest: TRequest;
  AResponse: TResponse; var Handled: Boolean);
var
  res: Boolean;
begin
  if ARequest.QueryFields.Values['Id'] <> '' then
    begin
      fmWikiPage.SetTemplateParams(TFPWebAction(Sender).Template);
      aOrder.Positions.Open;
      if copy(ARequest.QueryFields.Values['Id'],pos('_',ARequest.QueryFields.Values['Id'])+1,length(ARequest.QueryFields.Values['Id'])) = '' then
        res := aOrder.Positions.DataSet.Locate('IDENT',copy(ARequest.QueryFields.Values['Id'],0,pos('_',ARequest.QueryFields.Values['Id'])-1),[])
      else
        res := aOrder.Positions.dataSet.Locate('IDENT;VERSION',VarArrayOf([copy(ARequest.QueryFields.Values['Id'],0,pos('_',ARequest.QueryFields.Values['Id'])-1),copy(ARequest.QueryFields.Values['Id'],pos('_',ARequest.QueryFields.Values['Id'])+1,length(ARequest.QueryFields.Values['Id']))]),[]);
      if res then
        begin
          if ARequest.QueryFields.Values['Action'] = 'incqty' then
            begin
              aOrder.Positions.DataSet.Edit;
              aOrder.Positions.FieldByName('QUANTITY').AsFloat := aOrder.Positions.FieldByName('QUANTITY').AsFloat+1;
              aOrder.Positions.DataSet.Post;
              aOrder.CalcDispatchType;
            end
          else if ARequest.QueryFields.Values['Action'] = 'decqty' then
            begin
              aOrder.Positions.DataSet.Edit;
              aOrder.Positions.FieldByName('QUANTITY').AsFloat := aOrder.Positions.FieldByName('QUANTITY').AsFloat-1;
              if aOrder.Positions.FieldByName('QUANTITY').AsFloat < 0 then
                aOrder.Positions.FieldByName('QUANTITY').AsFloat := 0;
              aOrder.Positions.DataSet.Post;
              aOrder.CalcDispatchType;
            end
          else if ARequest.QueryFields.Values['Action'] = 'delete' then
            begin
              aOrder.Positions.DataSet.Delete;
              aOrder.CalcDispatchType;
            end
          ;
          if aOrder.CanEdit then
            aOrder.DataSet.Post;
        end;
    end;
  TFPWebAction(Sender).Template.OnReplaceTag := @ReplaceBasketDetailTags;
  AResponse.Content := TFPWebAction(Sender).Template.GetContent;
  Handled := true;
end;
procedure TfmShop.DataModuleCreate(Sender: TObject);
var
  PageName: String;

  procedure RecourseTree(bParent : string;aDeep : string;aPath : string);
  var
    aTree : TTree;
  begin
    aTree := TTree.Create(Self,Data);
    Data.SetFilter(aTree,Data.QuoteField('TYPE')+'='+Data.QuoteValue('M')+' AND '+Data.QuoteField('PARENT')+'='+Data.QuoteValue(bParent));
    with aTree.DataSet do
      begin
        First;
        while not EOF do
          begin
            Menue.Add(aDeep+HTTPEncode(FieldByName('NAME').AsString)+'='+HTTPEncode(aPath)+'/'+HTTPEncode(StringReplace(FieldByName('NAME').AsString,'/','_',[rfReplaceAll])));
            RecourseTree(aTree.Id.AsString,aDeep+' ',aPath+'/'+FieldByName('NAME').AsString);
            Next;
          end;
      end;
//    Menue.SaveToFile('menue.txt');
    aTree.Free;
  end;

begin
  AddSearchAbleDataSet(TMasterdataList);
  Masterdata := TMasterdataList.Create(Self,Data);
  aOrder := TOrder.Create(Self,Data);
  Menue := TStringlist.Create;
  aParent := 0;
  with BaseApplication as IBaseApplication do
    PageName := Config.ReadString('SHOPTREEOFFSET','');
  Data.SetFilter(Data.Tree,Data.QuoteField('TYPE')+'='+Data.QuoteValue('M'),0,'','ASC',False,True,True);
  while pos('/',PageName) > 0 do
    begin
      if Data.Tree.DataSet.Locate('NAME;PARENT',VarArrayOf([copy(PageName,0,pos('/',PageName)-1),aParent]),[])
      or Data.Tree.DataSet.Locate('NAME;PARENT',VarArrayOf([copy(PageName,0,pos('/',PageName)-1),aParent]),[loCaseInSensitive]) then
        begin
          PageName := copy(PageName,pos('/',PageName)+1,length(PageName));
          aParent := Data.Tree.Id.AsVariant;
        end
      else
        begin
          Data.SetFilter(Data.Tree,'',0,'','ASC',False,True,True);
          if Data.Tree.DataSet.Locate('NAME;PARENT',VarArrayOf([copy(PageName,0,pos('/',PageName)-1),aParent]),[])
          or Data.Tree.DataSet.Locate('NAME;PARENT',VarArrayOf([copy(PageName,0,pos('/',PageName)-1),aParent]),[loCaseInSensitive]) then
            begin
              PageName := copy(PageName,pos('/',PageName)+1,length(PageName));
              aParent := Data.Tree.Id.AsVariant;
            end
          else break;
        end;
    end;
  Data.SetFilter(Data.Tree,Data.QuoteField('TYPE')+'='+Data.QuoteValue('M')+' AND '+Data.QuoteField('PARENT')+'='+Data.QuoteValue(IntToStr(aParent)),0,'','ASC',False,True,True);
  with Data.Tree.DataSet do
    begin
      First;
      while not EOF do
        begin
          Menue.Add(HTTPEncode(FieldByName('NAME').AsString)+'='+HTTPEncode(StringReplace(FieldByName('NAME').AsString,'/','_',[rfReplaceAll])));
          RecourseTree(Data.Tree.Id.AsString,' ',StringReplace(FieldByName('NAME').AsString,'/','_',[rfReplaceAll]));
          Next;
        end;
    end;
end;
procedure TfmShop.DataModuleDestroy(Sender: TObject);
begin
  Menue.Free;
  Masterdata.Destroy;
  aOrder.Destroy;
end;
procedure TfmShop.DataModuleGetAction(Sender: TObject; ARequest: TRequest;
  var ActionName: String);
var
  Path: String;
  Result: String;
  Found: Boolean;
  PageName: String;
  PathFound: Boolean;
  aOldParent: Integer;
begin
  Path := '';
  If (ActionVar<>'') then
    Result:=ARequest.QueryFields.Values[ActionVar];
  If (Result='') then
    begin
      Result := copy(ARequest.PathInfo,2,length(ARequest.PathInfo));
      Result := copy(Result,0,pos('/',Result)-1);
    end;
  if Result = '' then
    Result:=ARequest.GetNextPathInfo;
  if (ARequest.PathInfo = '') or (ARequest.PathInfo = '/') or (Result = 'show') or (Result = 'shop') then
    begin
      Result := 'show';
      Path := copy(ARequest.PathInfo,2,length(ARequest.PathInfo));
      Path := copy(Path,pos('/',Path)+1,length(Path));
      if Path = '' then
        Path := 'highrunner';
      Path := trim(Path);
    end;
  PageName := Path;
  with BaseApplication as IBaseApplication do
    PageName := Config.ReadString('SHOPTREEOFFSET','')+PageName+'/';
  PathFound := True;
  aOldParent := aParent;
  aParent := 0;
  while pos('/',PageName) > 0 do
    begin
      if Data.Tree.DataSet.Locate('NAME;PARENT',VarArrayOf([HTTPDecode(StringReplace(copy(PageName,0,pos('/',PageName)-1),'_','/',[rfReplaceAll])),aParent]),[])
      or Data.Tree.DataSet.Locate('NAME;PARENT',VarArrayOf([HTTPDecode(StringReplace(copy(PageName,0,pos('/',PageName)-1),'_','/',[rfReplaceAll])),aParent]),[loCaseInSensitive]) then
        begin
          PageName := copy(PageName,pos('/',PageName)+1,length(PageName));
          aParent := Data.Tree.Id.AsVariant;
        end
      else
        begin
          Data.SetFilter(Data.Tree,'',0,'','ASC',False,True,True);
          if Data.Tree.DataSet.Locate('NAME;PARENT',VarArrayOf([HTTPDecode(StringReplace(copy(PageName,0,pos('/',PageName)-1),'_','/',[rfReplaceAll])),aParent]),[])
          or Data.Tree.DataSet.Locate('NAME;PARENT',VarArrayOf([HTTPDecode(StringReplace(copy(PageName,0,pos('/',PageName)-1),'_','/',[rfReplaceAll])),aParent]),[loCaseInSensitive]) then
            begin
              PageName := copy(PageName,pos('/',PageName)+1,length(PageName));
              aParent := Data.Tree.Id.AsVariant;
            end
          else
            begin
              aParent := aOldParent;
              PathFound := False;
              break;
            end;
        end;
    end;
  Found := False;
  SelectedParent := aParent;
  aOrder.Select(StrToIntDef(Session.Variables['BASKET'],0));
  aOrder.Open;
  if Path='rescentadded' then
    begin
      Data.SetFilter(Masterdata,Data.QuoteField('SALEITEM')+'='+Data.QuoteValue('Y'),10);
      Found := (Masterdata.Count > 0) or (Data.Tree.Count > 0);
    end
  else
    begin
      Data.SetFilter(Masterdata,Data.QuoteField('TREEENTRY')+'='+Data.QuoteValue(IntToStr(aParent))+' and '+Data.QuoteField('SALEITEM')+'='+Data.QuoteValue('Y'),10);
      Found := (Masterdata.Count > 0) or (Data.Tree.Count > 0);
    end;
  if Actions.FindAction(path) <> nil then
    Result := path;
  if Result = 'show' then
    begin
      if PathFound then
        SelectedPath := Path
      else SelectedPath := '';
      if not Found then
        Result := 'notfound';
    end;
  ActionName := Result;
end;
procedure TfmShop.FSearchItemFound(aIdent: string; aName: string;
  aStatus: string;aActive : Boolean; aLink: string; aItem: TBaseDBList=nil);
var
  LinkValue: String;
  aOffset: String;
  i: Integer;
begin
  LinkValue := copy(aLink,pos('@',aLink)+1,length(aLink));
  if Pos('{',LinkValue) > 0 then
    LinkValue := copy(LinkValue,0,pos('{',LinkValue)-1);
  FSearchResult.Add(aLink);
end;
procedure TfmShop.ReplaceBasketDetailTags(Sender: TObject;
  const TagString: String; TagParams: TStringList; out ReplaceText: String);
var
  aRow: String;
  aTmpRow: String;
begin
  if AnsiCompareText(TagString, 'MENUE_RIGHT') = 0 then
    ReplaceMenueTags(Sender,TagString,TagParams,ReplaceText)
  else if AnsiCompareText(TagString, 'SHOP_BASKET') = 0 then
    begin
      ReplaceText := TagParams.Values['HEADER'];
      aOrder.Positions.Open;
      with aOrder.Positions.DataSet do
        begin
          First;
          while not EOF do
            begin
              if aOrder.Positions.PosTypDec <> 6 then
                aRow := TagParams.Values['ONEROW']
              else
                aRow := TagParams.Values['ONESHIPROW'];
              aTmpRow := aRow;
              aTmpRow := StringReplace(aTmpRow,'~ProductId',FieldByName('IDENT').AsString+'_'+FieldByName('VERSION').AsString,[rfReplaceAll]);
              aTmpRow := StringReplace(aTmpRow,'~ProductName',FieldByName('SHORTTEXT').AsString,[rfReplaceAll]);
              aTmpRow := StringReplace(aTmpRow,'~RowPrice',aOrder.FormatCurrency(FieldByName('GROSSPRICE').AsFloat),[rfReplaceAll]);
              aTmpRow := StringReplace(aTmpRow,'~PosPrice',aOrder.FormatCurrency(FieldByName('POSPRICE').AsFloat),[rfReplaceAll]);
              aTmpRow := StringReplace(aTmpRow,'~ProductLink','/shop/showdetail?Id='+FieldByName('IDENT').AsString+'_'+FieldByName('VERSION').AsString,[rfReplaceAll]);
              aTmpRow := StringReplace(aTmpRow,'~PosQuantity',FieldByName('QUANTITY').AsString,[rfReplaceAll]);
              ReplaceText := ReplaceText+aTmpRow;
              Next;
            end;
        end;
      aTmpRow := TagParams.Values['FOOTER'];
      aTmpRow := StringReplace(aTmpRow,'~SumPrice',aOrder.FormatCurrency(aOrder.FieldByName('GROSSPRICE').AsFloat),[rfReplaceAll]);
      aTmpRow := StringReplace(aTmpRow,'~SumWeight',FormatFloat('0.00',aOrder.FieldByName('WEIGHT').AsFloat),[rfReplaceAll]);
      ReplaceText := ReplaceText+aTmpRow;
    end
  else
    begin
      if not Assigned(fmWikiPage) then
        Application.CreateForm(TfmWikiPage,fmWikiPage);
      TagParams.Values['BASELOCATION'] := 'shop';
      fmWikiPage.ReplaceStdTags(Sender,TagString,TagParams,ReplaceText);
    end;
end;
procedure TfmShop.ReplaceDetailTags(Sender: TObject; const TagString: String;
  TagParams: TStringList; out ReplaceText: String);
begin
  if AnsiCompareText(TagString, 'MENUE_RIGHT') = 0 then
    ReplaceMenueTags(Sender,TagString,TagParams,ReplaceText)
  else if (AnsiCompareText(TagString, 'SHOP_DETAIL') = 0) then
    ReplaceShopDetailTags(Sender,TagString,TagParams,ReplaceText)
  else
    begin
      if not Assigned(fmWikiPage) then
        Application.CreateForm(TfmWikiPage,fmWikiPage);
      TagParams.Values['BASELOCATION'] := 'shop';
      fmWikiPage.ReplaceStdTags(Sender,TagString,TagParams,ReplaceText);
    end;
end;
procedure TfmShop.ReplaceShopDetailTags(Sender: TObject;
  const TagString: String; TagParams: TStringList; out ReplaceText: String);
var
  aTmpRow: String;
  ImageFile: String;
  ImageBasePath: String;
  s: TStream;
  GraphExt: String;
  aFile: TFileStream;
  aPicture: TFPMemoryImage;
  Aspect: Double;
  aPicture2: TFPMemoryImage;
  aCanvas: TFPImageCanvas;
  ImgExt: String;
  aImageTmp: String;
  aSmallImageTmp: String;
  aPropertyTmp: String;
begin
  if AnsiCompareText(TagString, 'Title') = 0 then
    begin
      ReplaceText := '';
    end
  else if AnsiCompareText(TagString, 'MENUE_RIGHT') = 0 then
    ReplaceMenueTags(Sender,TagString,TagParams,ReplaceText)
  else if AnsiCompareText(TagString, 'BASKET') = 0 then
    ReplaceBasketTags(Sender,TagString,TagParams,ReplaceText)
  else if AnsiCompareText(TagString, 'SHOP_DETAIL') = 0 then
    begin
      ReplaceText := TagParams.Values['HEADER'];
      ReplaceText := ReplaceText+TagParams.Values['DETAIL'];
      aTmpRow := ReplaceText;
      if aMasterdata.Count > 0 then
        begin
          aMasterdata.Texts.Open;
          with aMasterdata.DataSet do
            begin
              aTmpRow := StringReplace(aTmpRow,'~ProductText',StringReplace(aMasterdata.Texts.FieldByName('TEXT').AsString,#13,'<br>',[rfReplaceAll]),[rfReplaceAll]);
              aMasterdata.Properties.Open;
              aPropertyTmp := '';
              if aMasterdata.Properties.Count > 0 then
                begin
                  with aMasterdata.Properties.DataSet do
                    begin
                      aPropertyTmp := TagParams.Values['PROPERTY_HEADER'];
                      while not EOF do
                        begin
                          aPropertyTmp := aPropertyTmp+TagParams.Values['PROPERTY_ROW'];
                          aPropertyTmp := StringReplace(aPropertyTmp,'~Property',FieldByName('PROPERTY').AsString,[rfReplaceAll]);
                          aPropertyTmp := StringReplace(aPropertyTmp,'~Value',FieldByName('VALUE').AsString+' '+FieldByName('UNIT').AsString,[rfReplaceAll]);
                          Next;
                        end;
                      aPropertyTmp := aPropertyTmp+TagParams.Values['PROPERTY_FOOTER'];
                    end;
                end;
              aTmpRow := StringReplace(aTmpRow,'~Properties',aPropertyTmp,[rfReplaceAll]);
              aTmpRow := StringReplace(aTmpRow,'~ProductId',FieldByName('ID').AsString,[rfReplaceAll]);
              aTmpRow := StringReplace(aTmpRow,'~ProductName',FieldByName('SHORTTEXT').AsString,[rfReplaceAll]);
              ImgExt := '';
              with BaseApplication as IBaseApplication do
                ImageBasePath := AppendPathDelim(AppendPathDelim(Config.ReadString('DOCROOTPATH','')));
              aSmallImageTmp := '';
              aMasterdata.Images.Open;
              aMasterdata.Images.DataSet.First;
              ImageFile := 'images/'+ValidateFileName(FieldByName('ID').AsString);
              if aMasterdata.Images.Count = 0 then ImageFile := '';
              while not aMasterdata.Images.DataSet.EOF do
                begin
                  if (not FileExists(ImageBasePath+ImageFile+ImgExt+'_50px.jpg')) then
                    begin
                      s := aMasterdata.Images.DataSet.CreateBlobStream(aMasterdata.Images.FieldByName('IMAGE'),bmRead);
                      if (S=Nil) or (s.Size = 0) then
                        begin
                          with BaseApplication as IBaseApplication do
                            ImageFile := '';
                        end
                      else
                        begin
                          s.Position := 0;
                          GraphExt :=  s.ReadAnsiString;
                          aFile := TFileStream.Create(ImageBasePath+ImageFile+ImgExt+'.'+GraphExt,fmCreate);
                          aFile.CopyFrom(s,s.Size-s.Position);
                          aFile.Free;
                          aPicture := TFPMemoryImage.Create(0,0);
                          aPicture.LoadFromFile(ImageBasePath+ImageFile+ImgExt+'.'+GraphExt);
                          Aspect := aPicture.Width/aPicture.Height;
                          aPicture2 := TFPMemoryImage.Create(50,round(50/Aspect));
                          aCanvas := TFPImageCanvas.create(aPicture2);
                          aCanvas.Height := aPicture2.Height;
                          aCanvas.Width := aPicture2.Width;
                          aCanvas.StretchDraw(0,0,50,round(50/Aspect),aPicture);
                          aPicture2.SaveToFile(ImageBasePath+ImageFile+ImgExt+'_50px.jpg');
                          aPicture.Free;
                          aPicture2.Free;
                          aCanvas.Free;
                        end;
                    end;
                  aImageTmp := TagParams.Values['SMALLIMAGE'];
                  aImageTmp := StringReplace(aImageTmp,'~ProductImageWidth','50',[rfReplaceAll]);
                  aImageTmp := StringReplace(aImageTmp,'~ProductImageAlt',strClickToEnlarge,[rfReplaceAll]);
                  aImageTmp := StringReplace(aImageTmp,'~ProductImageHref','/'+ImageFile+ImgExt+'.jpg',[rfReplaceAll]);
                  aImageTmp := StringReplace(aImageTmp,'~ProductImage','/'+ImageFile+ImgExt+'_50px.jpg',[rfReplaceAll]);
                  aSmallImageTmp := aSmallImageTmp+aImageTmp;
                  aMasterdata.Images.DataSet.Next;
                  ImgExt := IntToStr(StrToIntDef(ImgExt,1)+1);
                end;
              aImageTmp := '';
              if ImageFile <> '' then
                begin
                  aImageTmp := TagParams.Values['IMAGE'];
                  aImageTmp := StringReplace(aImageTmp,'~ProductImageWidth','170',[rfReplaceAll]);
                  aImageTmp := StringReplace(aImageTmp,'~ProductImageAlt',FieldByName('SHORTTEXT').AsString,[rfReplaceAll]);
                  aImageTmp := StringReplace(aImageTmp,'~ProductImage','/'+ImageFile+'.jpg',[rfReplaceAll]);
                  if aMasterdata.Images.Count > 1 then
                    aImageTmp := StringReplace(aImageTmp,'~SmallImage',aSmallImageTmp,[rfReplaceAll])
                  else
                    aImageTmp := StringReplace(aImageTmp,'~SmallImage','',[rfReplaceAll]);
                end;
              aTmpRow := StringReplace(aTmpRow,'~Image',aImageTmp,[]);
            end;
        end;
      ReplaceText := aTmpRow+TagParams.Values['FOOTER'];
    end
  else if AnsiCompareText(TagString, 'DETAIL_PRICE') = 0 then
    begin
      ReplaceText := TagParams.Values['HEADER'];
      ReplaceText := ReplaceText+TagParams.Values['PRICE']+TagParams.Values['FOOTER'];
      if aMasterdata.Count > 0 then
        begin
          aMasterdata.Texts.Open;
          with aMasterdata.DataSet do
            begin
              ReplaceText := StringReplace(ReplaceText,'~ProductId',FieldByName('ID').AsString+'_'+FieldByName('VERSION').AsString,[rfReplaceAll]);
              ReplaceText := StringReplace(ReplaceText,'~ProductName',FieldByName('SHORTTEXT').AsString,[rfReplaceAll]);
            end;
        end;
      aTmpRow := ReplaceText;
      aMasterdata.Prices.Open;
      Data.PriceTypes.Open;
      Data.Locate(Data.Pricetypes,'TYPE','4',[loCaseInsensitive,loPartialKey]); //Verkaufspreis
      if aMasterdata.Prices.DataSet.Locate('PTYPE;CUSTOMER',VarArrayOf([Data.Pricetypes.FieldByName('SYMBOL').AsString,Null]),[loPartialKey]) then
        aTmpRow := StringReplace(aTmpRow,'~Price',aMasterdata.Prices.FormatCurrency(aMasterdata.Prices.FieldByName('PRICE').AsFloat),[rfReplaceAll])
      else
        aTmpRow := StringReplace(aTmpRow,'~Price','n.A.',[rfReplaceAll]);
      ReplaceText := aTmpRow;
    end
  else
    begin
      if not Assigned(fmWikiPage) then
        Application.CreateForm(TfmWikiPage,fmWikiPage);
      TagParams.Values['BASELOCATION'] := 'shop';
      fmWikiPage.ReplaceStdTags(Sender,TagString,TagParams,ReplaceText);
    end;
end;
procedure TfmShop.ReplaceShopTags(Sender: TObject; const TagString: String;
  TagParams: TStringList; out ReplaceText: String);
begin
  if AnsiCompareText(TagString, 'Title') = 0 then
    begin
      ReplaceText := '';
    end
  else if AnsiCompareText(TagString, 'MENUE_RIGHT') = 0 then
    ReplaceMenueTags(Sender,TagString,TagParams,ReplaceText)
  else if AnsiCompareText(TagString, 'BASKET') = 0 then
    ReplaceBasketTags(Sender,TagString,TagParams,ReplaceText)
  else if ((AnsiCompareText(TagString, 'SHOP_OVERVIEW') = 0) or (AnsiCompareText(TagString, 'SHOP_CATEGORIES') = 0)) then
    ReplaceOverviewTags(Sender,TagString,TagParams,ReplaceText)
  else
    begin
      if not Assigned(fmWikiPage) then
        Application.CreateForm(TfmWikiPage,fmWikiPage);
      TagParams.Values['BASELOCATION'] := 'shop';
      fmWikiPage.ReplaceStdTags(Sender,TagString,TagParams,ReplaceText);
    end;
end;
procedure TfmShop.ReplaceMenueTags(Sender: TObject; const TagString: String;
  TagParams: TStringList; out ReplaceText: String);
var
  aRow: String;
  i: Integer;
  procedure RecourseMenue(SelPath : string);
  var
    tmp: String;
    tmp1: String;
    tmp2: String;
  begin
    tmp := HTTPDecode(copy(Menue[i],pos('=',Menue[i])+1,length(Menue[i])));
    if copy(tmp,0,length(SelPath)) = SelPath then
      tmp2 := copy(tmp,length(SelPath)+2,length(tmp))
    else tmp2 := tmp;
    if tmp = SelPath then
      begin
        ReplaceText := ReplaceText+StringReplace(
                                   StringReplace(
                                   StringReplace(TagParams.Values['HEADER'],'~HeaderValue','/shop/'+copy(Menue[i],pos('=',Menue[i])+1,length(Menue[i])),[rfReplaceAll])
                                                     ,'~HeaderName',HTMLEncode(HTTPDecode(copy(Menue[i],0,pos('=',Menue[i])-1))),[rfReplaceAll])
                                                     ,'~HeaderDesc','',[rfReplaceAll]);
        inc(i);
        if i >= Menue.Count then exit;
        tmp1 := copy(HTTPDecode(copy(Menue[i],pos('=',Menue[i])+1,length(Menue[i]))),0,length(SelPath));
        while (i < Menue.Count) and (copy(HTTPDecode(copy(Menue[i],pos('=',Menue[i])+1,length(Menue[i]))),0,length(SelPath)) = SelPath) do
          begin
            tmp1 := copy(SelectedPath,length(SelPath)+2,length(SelectedPath));
            if pos('/',tmp1) > 0 then
              RecourseMenue(SelPath+'/'+copy(tmp1,0,pos('/',tmp1)-1))
            else
              RecourseMenue(SelPath+'/'+tmp1);
          end;
        ReplaceText := ReplaceText+TagParams.Values['FOOTER'];
      end
    else if (copy(SelPath,rpos('/',SelPath)+1,length(SelPath)) <> '')
        and ((copy(tmp,0,length(SelPath)) = SelPath) or ((copy(tmp,0,rpos('/',tmp)-1) = copy(SelPath,0,rpos('/',SelPath)-1)))) then
      begin
        ReplaceText := ReplaceText+StringReplace(
                                   StringReplace(
                                   StringReplace(aRow,'~LinkValue','/shop/'+copy(Menue[i],pos('=',Menue[i])+1,length(Menue[i])),[rfReplaceAll])
                                                     ,'~LinkName',HTMLEncode(HTTPDecode(copy(Menue[i],0,pos('=',Menue[i])-1))),[rfReplaceAll])
                                                     ,'~LinkDesc','',[rfReplaceAll]);
        inc(i);
      end
    else if pos('/',tmp2) = 0 then
      begin
        ReplaceText := ReplaceText+StringReplace(
                                   StringReplace(
                                   StringReplace(aRow,'~LinkValue','/shop/'+copy(Menue[i],pos('=',Menue[i])+1,length(Menue[i])),[rfReplaceAll])
                                                     ,'~LinkName',HTMLEncode(HTTPDecode(copy(Menue[i],0,pos('=',Menue[i])-1))),[rfReplaceAll])
                                                     ,'~LinkDesc','',[rfReplaceAll]);
        inc(i);
      end
    else inc(i);
  end;
begin
  if AnsiCompareText(TagString, 'MENUE_RIGHT') = 0 then
    begin
      ReplaceText := StringReplace(StringReplace(TagParams.Values['HEADER'],'~HeaderName',strCategory,[]),'~HeaderLink','/shop/overview',[]);
      aRow := TagParams.Values['ONEROW'];
      i := 0;
      while i < Menue.Count do
        begin
          if pos('/',SelectedPath) > 0 then
            RecourseMenue(copy(SelectedPath,0,pos('/',SelectedPath)-1))
          else
            RecourseMenue(SelectedPath);
        end;
      ReplaceText := ReplaceText+TagParams.Values['FOOTER'];
    end;
end;
procedure TfmShop.ReplaceBasketTags(Sender: TObject; const TagString: String;
  TagParams: TStringList; out ReplaceText: String);
var
  aRow: String;
begin
  if AnsiCompareText(TagString, 'BASKET') = 0 then
    begin
      if aOrder.Count > 0 then
        begin
          ReplaceText := TagParams.Values['HEADER'];
          aOrder.Positions.Open;
          with aOrder.Positions.DataSet do
            begin
              First;
              while not EOF do
                begin
                  aRow := TagParams.Values['ONEROW'];
                  aRow := StringReplace(aRow,'~Quantity',FieldByName('QUANTITY').AsString,[]);
                  aRow := StringReplace(aRow,'~ProductName',Utils.TextCut(30,FieldByName('SHORTTEXT').AsString),[]);
                  aRow := StringReplace(aRow,'~ProductId',FieldByName('IDENT').AsString,[]);
                  ReplaceText := ReplaceText+aRow;
                  next;
                end;
            end;
          ReplaceText := ReplaceText+TagParams.Values['FOOTER'];
          ReplaceText := StringReplace(ReplaceText,'~Price',aOrder.FieldByName('GROSSPRICE').AsString+' '+aOrder.FieldByName('CURRENCY').AsString,[]);
        end;
    end;
end;
procedure TfmShop.ReplaceOverviewTags(Sender: TObject; const TagString: String;
  TagParams: TStringList; out ReplaceText: String);
var
  aRow: String;
  aTmpRow: String;
  ImageFile: String;
  ImageBasePath: String;
  s: TStream;
  GraphExt: String;
  Aspect: real;
  aPicture: TFPCustomImage;
  aFile: TFileStream;
  aCanvas : TFPCustomCanvas;
  aPicture2: TFPMemoryImage;
begin
  if AnsiCompareText(TagString, 'SHOP_CATEGORIES') = 0 then
    begin
      ReplaceText := TagParams.Values['HEADER'];
      aRow := TagParams.Values['ONEROW'];
      with Data.Tree.DataSet do
        begin
          First;
          while not EOF do
            begin
              if FieldByName('PARENT').AsInteger = SelectedParent then
                begin
                  aTmpRow := aRow;
                  aTmpRow := StringReplace(aTmpRow,'~CategoryName',FieldByName('NAME').AsString,[rfReplaceAll]);
                  aTmpRow := StringReplace(aTmpRow,'~CategoryLink','/shop/'+SelectedPath+'/'+StringReplace(FieldByName('NAME').AsString,'/','_',[rfReplaceAll]),[rfReplaceAll]);
                  ReplaceText := ReplaceText+aTmpRow;
                end;
              Next;
            end;
        end;
    end
  else if AnsiCompareText(TagString, 'SHOP_OVERVIEW') = 0 then
    begin
      ReplaceText := TagParams.Values['HEADER'];
      aRow := TagParams.Values['ONEROW'];
      with Masterdata.DataSet do
        begin
          First;
          while not EOF do
            begin
              aTmpRow := aRow;
              aTmpRow := StringReplace(aTmpRow,'~ProductId',FieldByName('ID').AsString+'_'+FieldByName('VERSION').AsString,[rfReplaceAll]);
              aTmpRow := StringReplace(aTmpRow,'~ProductName',FieldByName('SHORTTEXT').AsString,[rfReplaceAll]);
              aMasterdata := TMasterdata.Create(Self,Data);
              aMasterdata.Select(FieldByName('SQL_ID').AsInteger);
              aMasterdata.Open;
              with BaseApplication as IBaseApplication do
                ImageBasePath := AppendPathDelim(AppendPathDelim(Config.ReadString('DOCROOTPATH','')));
              ImageFile := 'images/'+ValidateFileName(FieldByName('ID').AsString);
              if (not FileExists(ImageBasePath+ImageFile+'.jpg'))
              or (not FileExists(ImageBasePath+ImageFile+'_100px.jpg'))
              then
                begin
                  aMasterdata.Images.Open;
                  s := aMasterdata.Images.DataSet.CreateBlobStream(aMasterdata.Images.FieldByName('IMAGE'),bmRead);
                  if (S=Nil) or (s.Size = 0) then
                    begin
                      with BaseApplication as IBaseApplication do
                        ImageFile := 'images/noimage';
                    end
                  else
                    begin
                      s.Position := 0;
                      GraphExt :=  s.ReadAnsiString;
                      aFile := TFileStream.Create(ImageBasePath+ImageFile+'.'+GraphExt,fmCreate);
                      aFile.CopyFrom(s,s.Size-s.Position);
                      aFile.Free;
                      aPicture := TFPMemoryImage.Create(0,0);
                      aPicture.LoadFromFile(ImageBasePath+ImageFile+'.'+GraphExt);
                      Aspect := aPicture.Width/aPicture.Height;
                      aPicture2 := TFPMemoryImage.Create(100,round(100/Aspect));
                      aCanvas := TFPImageCanvas.create(aPicture2);
                      aCanvas.Height := aPicture2.Height;
                      aCanvas.Width := aPicture2.Width;
                      aCanvas.StretchDraw(0,0,100,round(100/Aspect),aPicture);
                      aPicture2.SaveToFile(ImageBasePath+ImageFile+'_100px.jpg');
                      aPicture.Free;
                      aPicture2.Free;
                      aCanvas.Free;
                    end;
                end;
              aTmpRow := StringReplace(aTmpRow,'~ProductImageWidth','100',[rfReplaceAll]);
              aTmpRow := StringReplace(aTmpRow,'~ProductImageHeight','100',[rfReplaceAll]);
              aTmpRow := StringReplace(aTmpRow,'~ProductImageAlt',FieldByName('SHORTTEXT').AsString,[rfReplaceAll]);
              aTmpRow := StringReplace(aTmpRow,'~ProductLink','/shop/showdetail?Id='+FieldByName('ID').AsString+'_'+FieldByName('VERSION').AsString,[rfReplaceAll]);
              aTmpRow := StringReplace(aTmpRow,'~ProductImage','/'+ImageFile+'_100px.jpg',[rfReplaceAll]);
              aMasterdata.Prices.Open;
              Data.PriceTypes.Open;
              Data.Locate(Data.Pricetypes,'TYPE','4',[loCaseInsensitive,loPartialKey]); //Verkaufspreis
              if aMasterdata.Prices.DataSet.Locate('PTYPE;CUSTOMER',VarArrayOf([Data.Pricetypes.FieldByName('SYMBOL').AsString,Null]),[loPartialKey]) then
                aTmpRow := StringReplace(aTmpRow,'~Price',FormatFloat('0.00',aMasterdata.Prices.FieldByName('PRICE').AsFloat)+' '+aMasterdata.Prices.FieldByName('CURRENCY').AsString,[rfReplaceAll])
              else
                aTmpRow := StringReplace(aTmpRow,'~Price','n.A.',[rfReplaceAll]);
              aMasterdata.Free;
              ReplaceText := ReplaceText+aTmpRow;
              Next;
            end;
        end;
      ReplaceText := ReplaceText+TagParams.Values['FOOTER'];
    end
end;
procedure TfmShop.searchRequest(Sender: TObject; ARequest: TRequest;
  AResponse: TResponse; var Handled: Boolean);
var
  Locations : TSearchLocations;
begin
  fmWikiPage.SettemplateParams(TFPWebAction(Sender).Template);
  fmWikiPage.Title:='Suche';
  TFPWebAction(Sender).Template.OnReplaceTag:=@SearchTagreplace;
  Setlength(Locations,1);
  Locations[0] := strMasterdata;
  FSearch := TSearch.Create([fsIdents,fsShortNames,fsDescription],Locations,True);
  FSearch.OnItemFound:=@FSearchItemFound;
  FSearchResult := TStringList.Create;
  FSearch.Start(ARequest.QueryFields.Values['search']);
  FreeAndNil(FSearch);
  AResponse.Content := TFPWebAction(Sender).Template.GetContent;
  FreeAndNil(FSearchResult);
  Handled := true;
end;
procedure TfmShop.SearchTagreplace(Sender: TObject; const TagString: String;
  TagParams: TStringList; out ReplaceText: String);
var
  aRow: string;
  i: Integer;
  LinkValue: String;
  LinkDesc: String;
  LinkLocation: String;
  aMd: TMasterdata;
  aCount: Integer;
  ImageFile: String;
  ImageBasePath: String;
  s: TStream;
  GraphExt: String;
  aFile: TFileStream;
  aPicture: TFPMemoryImage;
  Aspect: Extended;
  aPicture2: TFPMemoryImage;
  aCanvas: TFPImageCanvas;
  aImageText: String;
begin
  aMd := TMasterdata.Create(Self,Data);
  if AnsiCompareText(TagString, 'CONTENT') = 0 then
    begin
      ReplaceText := TagParams.Values['CHEADER'];
      aRow := TagParams.Values['CONEROW'];
      aCount := 0;
      for i := 0 to FSearchResult.Count-1 do
        begin
          aMd.SelectFromLink(FSearchResult[i]);
          aMd.Open;
          if (aMd.Count > 0) and (aMd.FieldByName('SALEITEM').AsString = 'Y') then
            with aMd.DataSet do
              begin
                inc(aCount);
                LinkValue := copy(FSearchResult[i],pos('@',FSearchResult[i])+1,length(FSearchResult[i]));
                if rpos('{',LinkValue) > 0 then
                  LinkValue := copy(LinkValue,0,rpos('{',LinkValue)-1)
                else if rpos('(',LinkValue) > 0 then
                  LinkValue := copy(LinkValue,0,rpos('(',LinkValue)-1);
                LinkDesc := HTMLEncode(Data.GetLinkDesc(FSearchResult[i]));
                LinkLocation := LinkDesc;
                with BaseApplication as IBaseApplication do
                  ImageBasePath := AppendPathDelim(AppendPathDelim(Config.ReadString('DOCROOTPATH','')));
                if rpos('(',Linkdesc) > 0 then
                  begin
                    LinkLocation := copy(LinkDesc,rpos('(',LinkDesc)+1,length(LinkDesc));
                    LinkLocation := copy(LinkLocation,0,length(LinkLocation)-1);
                    LinkDesc := copy(LinkDesc,0,rpos('(',LinkDesc)-1);
                  end
                else if rpos('{',Linkdesc) > 0 then
                  begin
                    LinkLocation := copy(LinkDesc,rpos('{',LinkDesc)+1,length(LinkDesc));
                    LinkLocation := copy(LinkLocation,0,length(LinkLocation)-1);
                    LinkDesc := copy(LinkDesc,0,rpos('{',LinkDesc)-1);
                  end;
                ImageFile := 'images/'+ValidateFileName(FieldByName('ID').AsString);
                if (not FileExists(ImageBasePath+ImageFile+'.jpg'))
                or (not FileExists(ImageBasePath+ImageFile+'_100px.jpg'))
                then
                  begin
                    aMd.Images.Open;
                    s := aMd.Images.DataSet.CreateBlobStream(aMd.Images.FieldByName('IMAGE'),bmRead);
                    if (S=Nil) or (s.Size = 0) then
                      begin
                        with BaseApplication as IBaseApplication do
                          ImageFile := 'images/noimage';
                      end
                    else
                      begin
                        s.Position := 0;
                        GraphExt :=  s.ReadAnsiString;
                        aFile := TFileStream.Create(ImageBasePath+ImageFile+'.'+GraphExt,fmCreate);
                        aFile.CopyFrom(s,s.Size-s.Position);
                        aFile.Free;
                        aPicture := TFPMemoryImage.Create(0,0);
                        aPicture.LoadFromFile(ImageBasePath+ImageFile+'.'+GraphExt);
                        Aspect := aPicture.Width/aPicture.Height;
                        aPicture2 := TFPMemoryImage.Create(100,round(100/Aspect));
                        aCanvas := TFPImageCanvas.create(aPicture2);
                        aCanvas.Height := aPicture2.Height;
                        aCanvas.Width := aPicture2.Width;
                        aCanvas.StretchDraw(0,0,100,round(100/Aspect),aPicture);
                        aPicture2.SaveToFile(ImageBasePath+ImageFile+'_100px.jpg');
                        aPicture.Free;
                        aPicture2.Free;
                        aCanvas.Free;
                      end;
                  end;
                aImageText := TagParams.Values['CIMAGE'];
                aImageText := StringReplace(
                                           StringReplace(
                                           StringReplace(aImageText,'~ProductImageWidth','70',[rfReplaceAll])
                                                             ,'~ProductImageHeight','70',[rfReplaceAll])
                                                             ,'~ProductImage','/'+ImageFile+'_100px.jpg',[rfReplaceAll]);
                if ImageFile = 'images/noimage' then
                  aImageText := '';
                ReplaceText := ReplaceText+StringReplace(
                                           StringReplace(
                                           StringReplace(
                                           StringReplace(
                                           StringReplace(aRow,'~LinkValue','/shop/showdetail?Id='+FieldByName('ID').AsString+'_'+FieldByName('VERSION').AsString,[rfReplaceAll])
                                                             ,'~LinkName',LinkDesc,[rfReplaceAll])
                                                             ,'~LinkLocation',LinkLocation,[rfReplaceAll])
                                                             ,'~ProductImage',aImageText,[rfReplaceAll])
                                                             ,'~LinkDesc',Data.GetLinkLongDesc(FSearchResult[i]),[rfReplaceAll]);
              end;
        end;
      if aCount = 0 then
        ReplaceText := ReplaceText+TagParams.Values['CNONEFOUND'];
      ReplaceText := ReplaceText+TagParams.Values['CFOOTER'];
    end
  else
    begin
      if not Assigned(fmWikiPage) then
        Application.CreateForm(TfmWikiPage,fmWikiPage);
      TagParams.Values['BASELOCATION'] := 'shop';
      fmWikiPage.ReplaceStdTags(Sender,TagString,TagParams,ReplaceText);
    end;
  aMd.Free;
  ReplaceText := UTF8ToSys(ReplaceText);
end;
procedure TfmShop.showbasketRequest(Sender: TObject; ARequest: TRequest;
  AResponse: TResponse; var Handled: Boolean);
begin
  fmWikiPage.SetTemplateParams(TFPWebAction(Sender).Template);
  TFPWebAction(Sender).Template.OnReplaceTag :=@ReplaceBasketDetailTags;
  AResponse.Content := TFPWebAction(Sender).Template.GetContent;
  Handled := true;
end;
procedure TfmShop.showdetailRequest(Sender: TObject; ARequest: TRequest;
  AResponse: TResponse; var Handled: Boolean);
begin
  SelectedArticle := '';
  if ARequest.QueryFields.Values['Id'] <> '' then
    begin
      fmWikiPage.SetTemplateParams(TFPWebAction(Sender).Template);
      TFPWebAction(Sender).Template.OnReplaceTag := @ReplaceShopDetailTags;
      SelectedArticle := ARequest.QueryFields.Values['Id'];
      aMasterdata := TMasterdata.Create(Self,Data);
      if copy(SelectedArticle,pos('_',SelectedArticle)+1,length(SelectedArticle)) = '' then
        aMasterdata.Select(copy(SelectedArticle,0,pos('_',SelectedArticle)-1),Null,'de')
      else
        aMasterdata.Select(copy(SelectedArticle,0,pos('_',SelectedArticle)-1),copy(SelectedArticle,pos('_',SelectedArticle)+1,length(SelectedArticle)),'de');
      aMasterdata.Open;
      if aMasterdata.Count > 0 then
        AResponse.Content := TFPWebAction(Sender).Template.GetContent;
      aMasterdata.Free;
      Handled := true;
    end;
end;
procedure TfmShop.showRequest(Sender: TObject; ARequest: TRequest;
  AResponse: TResponse; var Handled: Boolean);
begin
  fmWikiPage.SetTemplateParams(TFPWebAction(Sender).Template);
  TFPWebAction(Sender).Template.OnReplaceTag :=@ReplaceShopTags;
  AResponse.Content := TFPWebAction(Sender).Template.GetContent;
  Handled := true;
end;
initialization
  RegisterHTTPModule('shop', TfmShop);
end.

