unit Main;

{$mode ObjFPC}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ActnList, Grids, ImagingTypes, Imaging, ImagingComponents, FileUtil,
  LazFileUtils, LCLIntf, LCLType, Menus, ComCtrls, ATImageBox, Clipbrd, ECSlider,
  Utils;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnUncheckAll: TButton;
    btnCheckAll: TButton;
    btnCopy: TButton;
    btnInvert: TButton;
    tbZoom: TECSlider;
    imgMap: TATImageBox;
    mnuMainOutputMode: TMenuItem;
    mnuMainOutputModeMerc: TMenuItem;
    mnuMainOutputModeWin: TMenuItem;
    mnuMainGameMode: TMenuItem;
    mnuMainGameModeRTW: TMenuItem;
    mnuMainGameModeBI: TMenuItem;
    mnuMainBrowse: TMenuItem;
    mnuMainColumns: TMenuItem;
    mnuMainColumnsRegion: TMenuItem;
    mnuMainColumnsSettlement: TMenuItem;
    mnuAbout: TMenuItem;
    mnuMain: TMainMenu;
    dlgCampaignDir: TSelectDirectoryDialog;
    pnlGrid: TPanel;
    sgRegions: TStringGrid;
    splSplitMapGrid: TSplitter;
    sbMainStatusBar: TStatusBar;
    procedure btnCheckAllClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnInvertClick(Sender: TObject);
    procedure btnUncheckAllClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure imgMapMouseUp(Sender: TObject);
    procedure imgMapScroll(Sender: TObject);
    procedure mnuMainOutputModeMercClick(Sender: TObject);
    procedure mnuMainOutputModeWinClick(Sender: TObject);
    procedure mnuAboutClick(Sender: TObject);
    procedure mnuMainBrowseClick(Sender: TObject);
    procedure mnuMainColumnsRegionClick(Sender: TObject);
    procedure mnuMainColumnsSettlementClick(Sender: TObject);
    procedure mnuMainGameModeBIClick(Sender: TObject);
    procedure mnuMainGameModeRTWClick(Sender: TObject);
    procedure sgRegionsCheckboxToggled(Sender: TObject);
    procedure SavePickedRegionsToFile(const Filename: string);
    procedure SortRegions;
    function CountPickedRegions: integer;
    function ScreenColor(x, y: integer): TColor;
    procedure tbZoomChange(Sender: TObject);
  private
    GameMode: TGameMode;
    OutputMode: TOutputMode;
    RegionDict: TRegionDictionary;
  public
  end;

const
  TITLE: string = 'RTW Region Picker';
  VERSION: string = 'v1.1.0';
  AUTHOR: string = 'Vartan Haghverdi';
  COPYRIGHT: string = 'Copyright 2023';
  NOTE: string = 'Brought to you by the EB Online Team';

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.btnUncheckAllClick(Sender: TObject);
var
  i: integer;
begin
  if sgRegions.RowCount < 2 then
    Exit;
  for i := 1 to sgRegions.RowCount - 1 do
    sgRegions.Rows[i][0] := '0';
  SortRegions;
  SavePickedRegionsToFile('regions.txt');
  sbMainStatusBar.Panels[1].Text :=
    Format('Picked: %d of %d', [CountPickedRegions, sgRegions.RowCount - 1]);
end;

procedure TfrmMain.btnCopyClick(Sender: TObject);
begin
  Clipboard.AsText := PickedRegionsToStr(sgRegions, OutputMode);
end;

procedure TfrmMain.btnInvertClick(Sender: TObject);
var
  i: integer;
begin
  if sgRegions.RowCount < 2 then
    Exit;
  for i := 1 to sgRegions.RowCount - 1 do
    if sgRegions.Rows[i][0] = '0' then
      sgRegions.Rows[i][0] := '1'
    else
      sgRegions.Rows[i][0] := '0';
  SortRegions;
  SavePickedRegionsToFile('regions.txt');
  sbMainStatusBar.Panels[1].Text :=
    Format('Picked: %d of %d', [CountPickedRegions, sgRegions.RowCount - 1]);
end;

procedure TfrmMain.btnCheckAllClick(Sender: TObject);
var
  i: integer;
begin
  if sgRegions.RowCount < 2 then
    Exit;
  for i := 1 to sgRegions.RowCount - 1 do
    sgRegions.Rows[i][0] := '1';
  SortRegions;
  SavePickedRegionsToFile('regions.txt');
  sbMainStatusBar.Panels[1].Text :=
    Format('Picked: %d of %d', [CountPickedRegions, sgRegions.RowCount - 1]);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  frmMain.Caption := TITLE + ' ' + VERSION;
end;

procedure TfrmMain.imgMapMouseUp(Sender: TObject);
var
  ShiftState: TShiftState;
  PickedColor: TColor;
  Region: TRegion;
  PickedStatus: string;
  RowIndex: integer = -1;
begin
  ShiftState := GetKeyShiftState;
  if not (ssCtrl in ShiftState) then
    Exit;
  PickedColor := ScreenColor(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  if Assigned(RegionDict) then
    if RegionDict.TryGetValue(PickedColor, Region) then
      RowIndex := sgRegions.Cols[1].IndexOf(Region.Province);
  if RowIndex > 0 then
  begin
    // toggle region picked or not
    PickedStatus := sgRegions.Rows[RowIndex][0];
    if PickedStatus = '0' then
      PickedStatus := '1'
    else
      PickedStatus := '0';
    sgRegions.Rows[RowIndex][0] := PickedStatus;
    SortRegions;
    SavePickedRegionsToFile('regions.txt');
    sbMainStatusBar.Panels[1].Text :=
      Format('Picked: %d of %d', [CountPickedRegions, sgRegions.RowCount - 1]);
  end;
end;

procedure TfrmMain.imgMapScroll(Sender: TObject);
begin
  sbMainStatusBar.Panels[0].Text := 'Zoom: ' + IntToStr(imgMap.ImageZoom) + '%';
  tbZoom.Position := imgMap.ImageZoom;
end;

procedure TfrmMain.mnuMainOutputModeMercClick(Sender: TObject);
begin
  OutputMode := omMercPool;
  sbMainStatusBar.Panels[3].Text := 'Merc Pool';
  SortRegions;
  SavePickedRegionsToFile('regions.txt');
end;

procedure TfrmMain.mnuMainOutputModeWinClick(Sender: TObject);
begin
  OutputMode := omWinCondition;
  sbMainStatusBar.Panels[3].Text := 'Win Condition';
  SortRegions;
  SavePickedRegionsToFile('regions.txt');
end;

function TfrmMain.ScreenColor(x, y: integer): TColor;
var
  ScreenDC: HDC;
  Bitmap: TBitmap;
begin
  Bitmap := TBitmap.Create;
  try
    Bitmap.SetSize(Screen.Width, Screen.Height);
    ScreenDC := GetDC(0);
    try
      Bitmap.LoadFromDevice(ScreenDC);
    finally
      ReleaseDC(0, ScreenDC);
    end;
    Exit(Bitmap.Canvas.Pixels[x, y]);
  finally
    FreeAndNil(Bitmap);
  end;
end;

procedure TfrmMain.tbZoomChange(Sender: TObject);
begin
  imgMap.ImageZoom := Round(tbZoom.Position);
  sbMainStatusBar.Panels[0].Text := 'Zoom: ' + IntToStr(imgMap.ImageZoom) + '%';
end;

procedure TfrmMain.mnuAboutClick(Sender: TObject);
begin
  ShowMessage(TITLE + ' ' + VERSION + LineEnding + NOTE + LineEnding +
    COPYRIGHT + ' ' + AUTHOR);
end;

procedure TfrmMain.mnuMainBrowseClick(Sender: TObject);
var
  CampaignDir, BaseDir: string;
  RegionColor: TColor;
  ImgData: TImageData;
  ImgBitmap: TImagingBitmap;
  i: integer;
begin
  ImgBitmap := TImagingBitmap.Create;
  try
    // read region colors and names from descr_regions.txt
    if dlgCampaignDir.Execute then
    begin
      CampaignDir := dlgCampaignDir.FileName;
      frmMain.Caption := TITLE + ' ' + VERSION + ' - ' +
        CampaignDir.Substring(Length(ExpandFileName(CampaignDir +
        '\..\..\..\..\..\..')) + 1);
      BaseDir := ExpandFileName(CampaignDir + '\..\..\base');
      try
        // first check campaign directory
        if FileExists(CampaignDir + '\descr_regions.txt') then
        begin
          FreeAndNil(RegionDict);
          RegionDict := LoadRegions(CampaignDir + '\descr_regions.txt', GameMode);
        end
        // then check base directory if necessary
        else if FileExists(BaseDir + '\descr_regions.txt') then
        begin
          FreeAndNil(RegionDict);
          RegionDict := LoadRegions(BaseDir + '\descr_regions.txt', GameMode);
        end
        // regions file not found
        else
        begin
          ShowMessage('descr_regions.txt not found. Please check ' +
            'the campaign and base folders.');
          Exit;
        end;
      except
        // wrong game mode or invalid regions file
        FreeAndNil(RegionDict);
        ShowMessage(
          'Something went wrong. Either you''ve selected the wrong ' +
          'game mode or there is invalid code in descr_regions.txt.');
        Exit;
      end;

      // list regions
      sgRegions.RowCount := 1;
      i := 1;
      for RegionColor in RegionDict.Keys do
      begin
        sgRegions.InsertRowWithValues(
          i, ['0', RegionDict[RegionColor].Province,
          RegionDict[RegionColor].Settlement]);
        i := i + 1;
      end;
      SortRegions;

      // load map_regions.tga
      InitImage(ImgData);
      if FileExists(CampaignDir + '\map_regions.tga') then
        LoadImageFromFile(CampaignDir + '\map_regions.tga', ImgData)
      else if FileExists(BaseDir + '\map_regions.tga') then
        LoadImageFromFile(BaseDir + '\map_regions.tga', ImgData);
      ImgBitmap.AssignFromImageData(ImgData);
      imgMap.Picture.Graphic := ImgBitmap;
      imgMap.OptFitToWindow := True;

      // report number of regions
      sbMainStatusBar.Panels[1].Text :=
        'Picked: 0 of ' + IntToStr(sgRegions.RowCount - 1);
    end;
  finally
    FreeImage(ImgData);
    FreeAndNil(ImgBitmap);
  end;
end;

procedure TfrmMain.mnuMainColumnsRegionClick(Sender: TObject);
begin
  sgRegions.Columns[1].Visible := mnuMainColumnsRegion.Checked;
end;

procedure TfrmMain.mnuMainColumnsSettlementClick(Sender: TObject);
begin
  sgRegions.Columns[2].Visible := mnuMainColumnsSettlement.Checked;
end;

procedure TfrmMain.mnuMainGameModeBIClick(Sender: TObject);
begin
  GameMode := gmBI;
  sbMainStatusBar.Panels[2].Text := 'BI';
end;

procedure TfrmMain.mnuMainGameModeRTWClick(Sender: TObject);
begin
  GameMode := gmRTW;
  sbMainStatusBar.Panels[2].Text := 'RTW';
end;

procedure TfrmMain.sgRegionsCheckboxToggled(Sender: TObject);
begin
  SortRegions;
  SavePickedRegionsToFile('regions.txt');
  sbMainStatusBar.Panels[1].Text :=
    Format('Picked: %d of %d', [CountPickedRegions, sgRegions.RowCount - 1]);
end;

procedure TfrmMain.SavePickedRegionsToFile(const Filename: string);
var
  s: string;
begin
  if CountPickedRegions = 0 then
    s := ''
  else
    s := PickedRegionsToStr(sgRegions, OutputMode);
  SaveStringToFile(s, Filename);
end;

procedure TfrmMain.SortRegions;
var
  PickedCount: integer;
begin
  PickedCount := CountPickedRegions;
  sgRegions.SortOrder := soDescending;
  sgRegions.SortColRow(True, 0);
  sgRegions.SortOrder := soAscending;
  if OutputMode = omMercPool then
    if PickedCount > 0 then
      sgRegions.SortColRow(True, 1, 1, PickedCount)
    else
      sgRegions.SortColRow(True, 1)
  else if OutputMode = omWinCondition then
    if PickedCount > 0 then
      sgRegions.SortColRow(True, 2, 1, PickedCount)
    else
      sgRegions.SortColRow(True, 2);
  sgRegions.TopRow := 1;
end;

function TfrmMain.CountPickedRegions: integer;
var
  RowIndex: integer;
begin
  Result := 0;
  if sgRegions.RowCount > 1 then
    for RowIndex := 1 to sgRegions.RowCount - 1 do
      if sgRegions.Rows[RowIndex][0] = '1' then
        Result := Result + 1;
end;

end.
