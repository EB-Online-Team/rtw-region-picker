unit Main;

{$mode ObjFPC}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ActnList, Grids, ImagingTypes, Imaging, ImagingComponents,
  FileUtil, LazFileUtils, LCLIntf, LCLType, Menus,
  Utils;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnCampaignDir: TButton;
    edtCampaignDir: TEdit;
    imgRegionMap: TImage;
    lblCampaignDir: TLabel;
    mnuAbout: TMenuItem;
    mnuMain: TMainMenu;
    pnlConfig: TPanel;
    rgOutputMode: TRadioGroup;
    rgGameMode: TRadioGroup;
    dlgCampaignDir: TSelectDirectoryDialog;
    sgRegions: TStringGrid;
    procedure btnCampaignDirClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure imgRegionMapClick(Sender: TObject);
    procedure mnuAboutClick(Sender: TObject);
    procedure rgOutputModeSelectionChanged(Sender: TObject);
    procedure sgRegionsCheckboxToggled(Sender: TObject);
  private
    OutputMode: TOutputMode;
    RegionDict: TRegionDictionary;
  public
  end;

const
  TITLE: string = 'RTW Region Picker';
  VERSION: string = 'v1.0.0';
  AUTHOR: string = 'Vartan Haghverdi';
  COPYRIGHT: string = 'Copyright 2023';
  NOTE: string = 'Brought to you by the EB Online Team';

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.btnCampaignDirClick(Sender: TObject);
var
  GameMode: TGameMode;
  CampaignDir, BaseDir: string;
  RegionColor: TColor;
  ImgData: TImageData;
  ImgBitmap: TImagingBitmap;
  i: integer;
begin
  ImgBitmap := TImagingBitmap.Create;
  case rgGameMode.ItemIndex of
    0: GameMode := gmRTW;
    1: GameMode := gmBI;
  end;

  try
    // read region colors and names from descr_regions.txt
    if dlgCampaignDir.Execute then
    begin
      CampaignDir := dlgCampaignDir.FileName;
      edtCampaignDir.Text := CampaignDir;
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
      sgRegions.AutoSizeColumns;
      sgRegions.Width := sgRegions.Columns[0].Width +
        sgRegions.Columns[1].Width + sgRegions.Columns[2].Width + 32;
      sgRegions.SortColRow(True, 1);

      // load map_regions.tga
      InitImage(ImgData);
      if FileExists(CampaignDir + '\map_regions.tga') then
        LoadImageFromFile(CampaignDir + '\map_regions.tga', ImgData)
      else if FileExists(BaseDir + '\map_regions.tga') then
        LoadImageFromFile(BaseDir + '\map_regions.tga', ImgData);
      ImgBitmap.AssignFromImageData(ImgData);
      imgRegionMap.Picture.Graphic := ImgBitmap;
    end;
  finally
    FreeImage(ImgData);
    FreeAndNil(ImgBitmap);
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  frmMain.Caption := TITLE + ' ' + VERSION;
end;

function ScreenColor(x, y: integer): TColor;
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

procedure TfrmMain.imgRegionMapClick(Sender: TObject);
var
  PickedColor: TColor;
  Region: TRegion;
  PickedStatus: string;
  RowIndex: integer = -1;
begin
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

    // sort by picked regions first then force scroll to top
    sgRegions.SortOrder := soDescending;
    sgRegions.SortColRow(True, 0);
    sgRegions.ScrollBy(0, 0);

    SavePickedRegionsToFile('regions.txt', sgRegions, OutputMode);
  end;
end;

procedure TfrmMain.mnuAboutClick(Sender: TObject);
begin
  ShowMessage(TITLE + ' ' + VERSION + LineEnding + NOTE + LineEnding +
    COPYRIGHT + ' ' + AUTHOR);
end;

procedure TfrmMain.rgOutputModeSelectionChanged(Sender: TObject);
begin
  case rgOutputMode.ItemIndex of
    0: OutputMode := omMercPool;
    1: OutputMode := omWinCondition;
  end;
  SavePickedRegionsToFile('regions.txt', sgRegions, OutputMode);
end;

procedure TfrmMain.sgRegionsCheckboxToggled(Sender: TObject);
begin
  SavePickedRegionsToFile('regions.txt', sgRegions, OutputMode);
end;


end.
