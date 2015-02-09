unit threadedimageLoader;

//22.6.2010 Theo

{$MODE objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, types, syncobjs, Forms, Graphics, FPimage;

type

  EThreadedImageLoaderError = class(Exception);
  TLoadState = (lsEmpty, lsLoading, lsLoaded, lsError);

  { TThreadedImage }
  TLoaderThread = class;

  TThreadedImage = class
  private
    FDone: Boolean;
    FName: string;
    FOnThreadDone: TNotifyEvent;
    FOnThreadStart: TNotifyEvent;
    FArea: TRect;
    FBitmap: TBitmap;
    FBitmapSelected: TBitmap;
    FHeight: integer;
    FImage: TFPMemoryImage;
    FOnNeedRepaint: TNotifyEvent;
    FOnLoadURL: TNotifyEvent;
    FOnLoadPointer: TNotifyEvent;
    fOnSelect: TNotifyEvent;
    fOnDeselect: TNotifyEvent;
    FPointer: Pointer;
    FSelected: Boolean;
    FURL: UTF8String;
    FLoadState: TLoadState;
    FThread: TLoaderThread;
    FRect: TRect;
    FWidth: integer;
    FMultiThreaded: Boolean;
    function GetImage: TFPMemoryImage;
    function GetName: string;
    function GetRect: TRect;
    procedure SetSelected(AValue: Boolean);
    procedure ThreadTerm(Sender: TObject);
    procedure Select;
    procedure Deselect;
    property OnThreadDone: TNotifyEvent read FOnThreadDone write FOnThreadDone;
    property OnThreadStart: TNotifyEvent read FOnThreadStart write FOnThreadStart;
    property OnSelect: TNotifyEvent read fOnSelect write fOnSelect;
    property OnDeselect: TNotifyEvent read fOnDeselect write fOnDeselect;
  public
    constructor Create; overload;
    constructor Create(URL: UTF8String); overload;
    constructor Create(P: Pointer); overload;
    destructor Destroy; override;
    function Load(Reload: Boolean = False): Boolean;
    procedure FreeImage;
    procedure ChangeSelected;
    property Image: TFPMemoryImage read GetImage;
    property Bitmap: TBitmap read FBitmap write FBitmap;
    property BitmapSelected: TBitmap read FBitmapSelected write FBitmapSelected;
    property LoadState: TLoadState read FLoadState write FLoadState;
    property URL: UTF8String read FURL write FURL;
    property Name : string read GetName write FName;
    property Left: integer read FRect.Left write FRect.Left;
    property Top: integer read FRect.Top write FRect.Top;
    property Width: integer read FWidth write FWidth;
    property Height: integer read FHeight write FHeight;
    property Rect: TRect read GetRect;
    property Area: TRect read fArea write fArea;
    property Thread : TLoaderThread read FThread;
    property Pointer : Pointer read FPointer write FPointer;
    property Selected: Boolean read FSelected write SetSelected;
  published
    property OnNeedRepaint: TNotifyEvent read FOnNeedRepaint write FOnNeedRepaint;
    property OnLoadURL: TNotifyEvent read FOnLoadURL write FOnLoadURL;
    property OnLoadPointer: TNotifyEvent read FOnLoadPointer write FOnLoadPointer;
  end;

  { TLoaderThread }

  TLoaderThread = class(TThread)
  private
    fRef: TThreadedImage;
  protected
    procedure Execute; override;
  end;

  { TImageLoaderManager }

  TImageLoaderManager = class
  private
    FActiveIndex: integer;
    FBeforeQueue: TNotifyEvent;
    FFreeInvisibleImage: Boolean;
    fList: TObjectList;
    fSelectedList: TList;
    FMultiThreaded: boolean;
    FOnSetItemIndex: TNotifyEvent;
    FQueue: TList;
    FOnNeedRepaint: TNotifyEvent;
    FOnLoadURL: TNotifyEvent;
    FOnLoadPointer: TNotifyEvent;
    FReload: Boolean;
    FMaxThreads: integer;
    FThreadsFree: integer;
    procedure NextInQueue;
    procedure ThreadDone(Sender: TObject);
    procedure ThreadStart(Sender: TObject);
    procedure ImageSelected(Sender: TObject);
    procedure ImageDeselected(Sender: TObject);
    function GetActiveItem: TThreadedImage;
    procedure SetActiveIndex(const AValue: integer);
  public
    constructor Create;
    destructor Destroy; override;
    function AddImage(URL: UTF8String): TThreadedImage;
    function AddImagePointer(P: Pointer): TThreadedImage;
    function AddThreadedImage(Image: TThreadedImage): Integer;
    procedure SetActiveIndexAndChangeSelected(AValue: integer);
    procedure SetActiveIndexAndSelectBetween(AValue: integer);
    procedure DeselectAll;
    procedure LoadAll;
    procedure LoadRect(ARect: TRect);
    procedure StartQueue;
    function ItemIndexFromPoint(Point: TPoint): integer;
    function ItemFromPoint(Point: TPoint): TThreadedImage;
    procedure Clear;
    procedure FreeImages;
    function CountItems: integer;
    function ThreadsIdle:boolean;
    property List: TObjectList read fList write fList;
    property SelectedList: TList read fSelectedList write fSelectedList;
    property Queue: TList read FQueue;
    property Reload: Boolean read FReload write FReload;
    property FreeInvisibleImage: Boolean read FFreeInvisibleImage write FFreeInvisibleImage;
    procedure Sort(stpye: byte);
    function ItemFromIndex(AValue: integer): TThreadedImage;
    property ActiveIndex: integer read FActiveIndex write SetActiveIndex;
    property ActiveIndexSelect: integer read FActiveIndex write SetActiveIndexAndChangeSelected;
    property ActiveIndexSelectBetween: integer read FActiveIndex write SetActiveIndexAndSelectBetween;
    property ActiveItem: TThreadedImage read GetActiveItem;
  published
    property OnNeedRepaint: TNotifyEvent read FOnNeedRepaint write FOnNeedRepaint;
    property OnLoadURL: TNotifyEvent read FOnLoadURL write FOnLoadURL;
    property OnLoadPointer: TNotifyEvent read FOnLoadPointer write FOnLoadPointer;
    property BeforeStartQueue: TNotifyEvent read FBeforeQueue write FBeforeQueue;
    property MultiThreaded: boolean read FMultiThreaded write FMultiThreaded;
    property OnSetItemIndex : TNotifyEvent read FOnSetItemIndex write FOnSetItemIndex;
  end;

var CSImg: TCriticalSection;

implementation

uses Math;

var CS: TCriticalSection;


{ TThreadedImage }

procedure TThreadedImage.ThreadTerm(Sender: TObject);
var aW, aH: integer;
begin
  FLoadState := lsEmpty;
  try
    if Assigned(FImage) and (FImage is TFPMemoryImage) then
      begin
        aW := fImage.Width;
        aH := fImage.Height;
        if (aW > 0) and (aH > 0) then
        begin
          if fBitmap = nil then fBitmap := TBitmap.Create;
          try
            try
              CSImg.Acquire;
              fBitmap.Assign(fImage);
              fBitmap.Transparent:=false;
              FLoadState := lsError;
              FreeAndNil(fImage);
            except
              if fMultiThreaded then if Assigned(fOnThreadDone) then OnThreadDone(Self);
            end;
          finally
            CSImg.Release;
          end;
          FLoadState := lsLoaded;
          if fMultiThreaded then if Assigned(FOnNeedRepaint) then OnNeedRepaint(Self);
        end;
      end;
      if fMultiThreaded then if Assigned(fOnThreadDone) then OnThreadDone(Self);
  except
  end;
end;

procedure TThreadedImage.Select;
begin
  if not Selected then begin;
    // SelectedBitmap erstellen
    if FBitmapSelected = nil then FBitmapSelected := TBitmap.Create;
    //FBitmapSelected.Assign(FBitmap);
    FBitmapSelected.Width:=FBitmap.Width;
    FBitmapSelected.Height:=FBitmap.Height;
    FBitmapSelected.Transparent:=False;
    FBitmapSelected.Canvas.Draw(0,0,FBitmap);

    FBitmapSelected.Canvas.Pen.Color:=$000080FF;
    FBitmapSelected.Canvas.Brush.Style:=bsClear;
    FBitmapSelected.Canvas.Pen.Width:=8;
    FBitmapSelected.Canvas.Rectangle(0,0,FBitmapSelected.Width,FBitmapSelected.Height);

    // in SelectedList eintragen (auf Reihenfolge achten)


    FSelected:=True;
    if Assigned(OnSelect) then OnSelect(Self);
  end;
end;

procedure TThreadedImage.Deselect;
begin
  if FSelected then begin
    FSelected:=False;
    // SelectedBitmap Löschen
    FreeAndNil(FBitmapSelected);
    // aus SelectedList austragen
    if Assigned(OnDeselect) then OnDeselect(Self);
  end;
end;

function TThreadedImage.GetRect: TRect;
begin
  fRect.Right := fRect.Left + fWidth;
  fRect.Bottom := fRect.Top + fHeight;
  Result := fRect;
end;

procedure TThreadedImage.SetSelected(AValue: Boolean);
begin
  if FSelected=AValue then Exit;
  if AValue then Select else Deselect;
  if Assigned(FOnNeedRepaint) then OnNeedRepaint(Self);
end;


function TThreadedImage.GetImage: TFPMemoryImage;
begin
  try
    Result := FImage;
  except
    Result := nil;
  end;
end;

function TThreadedImage.GetName: string;
begin
  if FName <> '' then
    Result := Fname
  else Result := FURL;
end;

constructor TThreadedImage.Create;
begin
  FLoadState := lsEmpty;
  fMultiThreaded := False;
  FBitmap := nil;
  FBitmapSelected:=nil;
  Fimage := nil;
  FThread := nil;
  FPointer:=nil;
end;

constructor TThreadedImage.Create(URL: UTF8String);
begin
  FURL := URL;
  Create;
end;

constructor TThreadedImage.Create(P: Pointer);
begin
  Create;
  FPointer:=P;
end;

destructor TThreadedImage.Destroy;
begin
  FBitmap.Free;
  FBitmapSelected.Free;
  if Assigned(Pointer) then
    TObject(Pointer).Destroy;
  inherited Destroy;
end;

function TThreadedImage.Load(Reload: Boolean): Boolean;
begin
  Result := True;
  if (fLoadState = lsEmpty) or Reload then
  begin
    fLoadState := lsLoading;

    if Fimage = nil then
    begin
      FImage := TFPMemoryImage.Create(0, 0);
      FImage.UsePalette := false;
    end;

    if not fMultiThreaded then
    begin
      if Assigned(FOnLoadPointer) then OnLoadPointer(Self)
      else if Assigned(fOnLoadURL) then OnLoadURL(Self)
      else Image.LoadFromFile(URL);
      ThreadTerm(Self);
    end else
      begin
        fThread := TLoaderThread.Create(true);
        if Assigned(fOnThreadStart) then OnThreadStart(Self);
        fThread.fRef := Self;
        fThread.FreeOnTerminate := true;
        fThread.OnTerminate := @ThreadTerm;
        fThread.Resume;
      end;
  end else Result := false;
end;

procedure TThreadedImage.FreeImage;
begin
  fLoadState := lsEmpty;
  FreeAndNil(FBitmap);
  FreeAndNil(FBitmapSelected);
  FreeAndNil(FImage);
end;

procedure TThreadedImage.ChangeSelected;
begin
  if FSelected then Deselect else Select;
  if Assigned(FOnNeedRepaint) then OnNeedRepaint(Self);
end;


{ TLoaderThread }


procedure TLoaderThread.Execute;
begin
  if Assigned(fRef.OnLoadPointer) then fRef.OnLoadPointer(fRef) else
    if Assigned(fRef.OnLoadURL) then fRef.OnLoadURL(fRef) else
  begin
    fRef.Image.LoadFromFile(fRef.URL);
  end;
end;


{ TImageLoaderManager }


function TImageLoaderManager.GetActiveItem: TThreadedImage;
begin
  Result := ItemFromIndex(fActiveIndex);
end;

procedure TImageLoaderManager.SetActiveIndex(const AValue: integer);
begin
  if (AValue > -1) and (AValue < fList.Count) then
    begin
      FActiveIndex := AValue;
      if Assigned(OnSetItemIndex) then
        OnSetItemIndex(Self);
    end;
end;

constructor TImageLoaderManager.Create;
begin
  fMultiThreaded := False;
  FList := TObjectList.Create;
  fSelectedList:= TList.Create;
  FQueue := TList.Create;
  FReload := false;
  FFreeInvisibleImage := false;
  FMaxThreads := 8;
  FThreadsFree := FMaxThreads;
end;

destructor TImageLoaderManager.Destroy;
begin
  FQueue.free;
  FList.free;
  fSelectedList.Free;
  inherited Destroy;
end;

function TImageLoaderManager.AddImage(URL: UTF8String): TThreadedImage;
begin
  Result := TThreadedImage.Create(URL);
  Result.FMultiThreaded := FMultiThreaded;
  if Assigned(FOnLoadURL) then Result.OnLoadURL := FOnLoadURL;
  if Assigned(FOnNeedRepaint) then Result.OnNeedRepaint := FOnNeedRepaint;
  Result.OnThreadDone := @ThreadDone;
  Result.OnThreadStart := @ThreadStart;
  Result.OnSelect:=@ImageSelected;
  Result.OnDeselect:=@ImageDeselected;
  FList.Add(Result);
end;

function TImageLoaderManager.AddImagePointer(P: Pointer): TThreadedImage;
begin
  Result := TThreadedImage.Create(P);
  Result.FMultiThreaded := FMultiThreaded;
  if Assigned(FOnLoadPointer) then Result.OnLoadPointer := FOnLoadPointer;
  if Assigned(FOnNeedRepaint) then Result.OnNeedRepaint := FOnNeedRepaint;
  Result.OnThreadDone := @ThreadDone;
  Result.OnThreadStart := @ThreadStart;
  Result.OnSelect:=@ImageSelected;
  Result.OnDeselect:=@ImageDeselected;
  FList.Add(Result);
end;

function TImageLoaderManager.AddThreadedImage(Image: TThreadedImage): Integer;
begin
  Result:=FList.Add(Image);
end;

procedure TImageLoaderManager.LoadAll;
var i: integer;
begin
  FQueue.Clear;

  if not FMultiThreaded then
    for i := 0 to fList.Count - 1 do FQueue.Add(TThreadedImage(fList[i]))
  else
    begin
      for i := 0 to fList.Count - 1 do
        if fQueue.IndexOf(TThreadedImage(fList[i])) < 0 then fQueue.Add(TThreadedImage(fList[i]));
    end;
  StartQueue;
end;

procedure TImageLoaderManager.LoadRect(ARect: TRect);
var i: integer;
  Dum: TRect;
begin
  FQueue.Clear;

  if not FMultiThreaded then
  begin
    for i := 0 to fList.Count - 1 do
      if IntersectRect(Dum, ARect, TThreadedImage(fList[i]).Rect) then
        if fQueue.IndexOf(TThreadedImage(fList[i])) < 0 then fQueue.Add(TThreadedImage(fList[i]));
    if Assigned(FBeforeQueue) then
      BeforeStartQueue(Self);
    for i := 0 to fList.Count - 1 do
      if IntersectRect(Dum, ARect, TThreadedImage(fList[i]).Rect) then
        TThreadedImage(fList[i]).Load(FReload) else if FFreeInvisibleImage then
        TThreadedImage(fList[i]).FreeImage;
  end else
  begin
    for i := 0 to fList.Count - 1 do
    begin
      if IntersectRect(Dum, ARect, TThreadedImage(fList[i]).Rect) then
      begin
        if fQueue.IndexOf(TThreadedImage(fList[i])) < 0 then fQueue.Add(TThreadedImage(fList[i]))
      end else if FFreeInvisibleImage then TThreadedImage(fList[i]).FreeImage;
    end;
    StartQueue;
  end;
end;

procedure TImageLoaderManager.StartQueue;
begin
  if Assigned(FBeforeQueue) then
    BeforeStartQueue(Self);
  NextInQueue;
end;

procedure TImageLoaderManager.NextInQueue;
var i: integer;
begin
  if (fQueue.Count > 0) and (FThreadsFree > 0) then
  begin
    i := Min(fQueue.Count - 1, fThreadsFree-1);
    while i > -1 do
    begin
      if not TThreadedImage(fQueue[i]).Load(fReload) then
      begin
        fQueue.Delete(i);
        if fQueue.Count > i then inc(i);
      end;
      dec(i);
    end;
  end;
end;

procedure TImageLoaderManager.SetActiveIndexAndChangeSelected(AValue: integer);
begin
  FActiveIndex:=AValue;
  if (AValue > -1) and (AValue < fList.Count) then begin
    TThreadedImage(fList[AValue]).ChangeSelected;
  end;
end;

procedure TImageLoaderManager.SetActiveIndexAndSelectBetween(AValue: integer);
Var
  i: Integer;
begin
  if (AValue > -1) and (AValue < fList.Count) and (AValue<>FActiveIndex) then begin
    if AValue>FActiveIndex then begin;
      for i:=0 to FActiveIndex-1 do begin
        TThreadedImage(fList[i]).Deselect;
      end;
      for i:= FActiveIndex to AValue do begin
        TThreadedImage(fList[i]).Select;
      end;
      for i:=AValue+1 to fList.Count-1 do begin
        TThreadedImage(fList[i]).Deselect;
      end;
    end else begin
      for i:=0 to AValue-1 do begin
        TThreadedImage(fList[i]).Deselect;
      end;
      for i:= AValue to FActiveIndex do begin
        TThreadedImage(fList[i]).Select;
      end;
      for i:=FActiveIndex+1 to fList.Count-1 do begin
        TThreadedImage(fList[i]).Deselect;
      end;
    end;
    FActiveIndex:=AValue;
  end;
end;

procedure TImageLoaderManager.DeselectAll;
Var
  i: Integer;
begin
  for i:=0 to fSelectedList.Count-1 do begin
    TThreadedImage(fSelectedList[i]).Deselect;
  end;
end;


procedure TImageLoaderManager.ThreadDone(Sender: TObject);
var idx: integer;
begin
  Inc(FThreadsFree);
  idx := fQueue.IndexOf(Sender);
  if idx > -1 then fQueue.Delete(idx);
  NextInQueue;
end;

procedure TImageLoaderManager.ThreadStart(Sender: TObject);
begin
  Dec(FThreadsFree);
end;

procedure TImageLoaderManager.ImageSelected(Sender: TObject);
begin
  fSelectedList.Add(Sender);
end;

procedure TImageLoaderManager.ImageDeselected(Sender: TObject);
Var
  i: Integer;
begin
  // Delete Sender from fSelectedList;
  for i:=0 to fSelectedList.Count-1 do begin
    if fSelectedList[i]=@Sender then begin
      fSelectedList.Delete(i);
      Break;
    end;
  end;
end;


function TImageLoaderManager.ItemIndexFromPoint(Point: TPoint): integer;
var i: integer;
  aRect: TRect;
begin
  Result := -1;
  for i := 0 to fList.Count - 1 do
    if TThreadedImage(fList[i]).LoadState = lsLoaded then
    begin
      aRect := TThreadedImage(fList[i]).Rect;
      OffsetRect(aRect, TThreadedImage(fList[i]).Area.Left, TThreadedImage(fList[i]).Area.Top);
      if PtInRect(aRect, Point) then
      begin
        Result := i;
        break;
      end;
    end;
end;

function TImageLoaderManager.ItemFromPoint(Point: TPoint): TThreadedImage;
begin
  Result := ItemFromIndex(ItemIndexFromPoint(Point));
end;


procedure TImageLoaderManager.Clear;
begin
  FList.Clear;
end;

procedure TImageLoaderManager.FreeImages;
var i: integer;
begin
  try
    CSImg.Acquire;
    for i := 0 to fList.Count - 1 do TThreadedImage(fList[i]).FreeImage;
  finally
    CSImg.Release;
  end;
end;

function TImageLoaderManager.CountItems: integer;
begin
  CS.Acquire;
  try
    Result := fList.Count;
  finally
    CS.Release;
  end;
end;

function TImageLoaderManager.ThreadsIdle: boolean;
begin
  Result:=fThreadsFree=fMaxThreads;
end;

function sComp(Item1, Item2: Pointer): Integer;
begin
  Result := CompareStr(TThreadedImage(Item1).URL, TThreadedImage(Item2).URL);
end;

procedure TImageLoaderManager.Sort(stpye: byte);
begin
  fList.Sort(@sComp);
end;

function TImageLoaderManager.ItemFromIndex(AValue: integer): TThreadedImage;
begin
  if (AValue > -1) and (AValue < fList.Count) then Result := TThreadedImage(fList[AValue]) else
    Result := nil;
end;

initialization

  CS := TCriticalSection.Create;
  CSImg := TCriticalSection.Create;

finalization

  CSImg.free;
  CS.Free;


end.
