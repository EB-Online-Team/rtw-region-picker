unit Utils;

{$mode ObjFPC}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Generics.Collections, Graphics, StrUtils,
  Grids, Dialogs, Win32Proc, Registry;

type
  { Determines whether to expect the religion mechanic (BI). }
  TGameMode = (gmRTW, gmBI);

  { Determines whether to output provinces (merc pool)
    or settlements (win conditions). }
  TOutputMode = (omMercPool, omWinCondition);

  { Holds region data. }
  TRegion = record
    Picked: boolean;
    Province, Settlement: string;
  end;

  { Maps region color to region data. }
  TRegionDictionary = specialize TDictionary<TColor, TRegion>;

{ Read region data from descr_regions.txt.
  @param(Filename is the path to descr_regions.txt)
  @param(GameMode tells whether to expect RTW or BI format)
  @returns(A dictionary mapping region color to data) }
function LoadRegions(const Filename: string;
  const GameMode: TGameMode = gmRTW): TRegionDictionary;

{ Convert region grid into a string of picked regions.
  @param(RegionGrid is the grid component holding region data)
  @param(OutputMode chooses between provinces and settlements)
  @returns(A string of space-delimited regions) }
function PickedRegionsToStr(const RegionGrid: TStringGrid;
  const OutputMode: TOutputMode = omMercPool): string;

{ Save a string to disk.
  @param(s is the string to save)
  @param(Filename is the save destination)
  @returns(@true on success, @false otherwise) }
function SaveStringToFile(s, Filename: string): boolean;

{ Detect if the system theme is set to dark. }
function IsDarkTheme: boolean;

implementation

function LoadRegions(const Filename: string;
  const GameMode: TGameMode = gmRTW): TRegionDictionary;
var
  RegionDict: TRegionDictionary;
  Region: TRegion;
  RegionSl: TStringList;
  Line: string;
  ColorString: array of string;
  RegionColor: TColor;
  i, r, g, b: integer;
begin
  RegionDict := TRegionDictionary.Create;
  RegionSl := TStringList.Create;
  try
    RegionSl.LoadFromFile(Filename);
    i := 1;
    for Line in RegionSl do
    begin
      // skip empty lines and comments
      if (Length(Trim(Line)) = 0) or (Trim(Line)[1] = ';') then
        Continue;
      case i of
        1: Region.Province := Trim(Line);
        2: Region.Settlement := Trim(Line);
        5: begin
          ColorString := SplitString(Line, ' ');
          r := StrToInt(ColorString[0]);
          g := StrToInt(ColorString[1]);
          b := StrToInt(ColorString[2]);
          RegionColor := RGBToColor(r, g, b);
          RegionDict.AddOrSetValue(RegionColor, Region);
        end;
      end;
      i := i + 1;
      case GameMode of
        gmRTW: if i = 9 then i := 1;
        gmBI: if i = 10 then i := 1;
      end;
    end;
    Exit(RegionDict);
  finally
    FreeAndNil(RegionSl);
  end;
end;

function SaveStringToFile(s, Filename: string): boolean;
var
  fsOut: TFileStream;
begin
  try
    fsOut := TFileStream.Create(Filename, fmCreate);
    if Length(s) > 0 then
      fsOut.Write(s[1], Length(s))
    else
      fsOut.Write('', 0);
    FreeAndNil(fsOut);
    Exit(True);
  except
    Exit(False);
  end;
end;

function PickedRegionsToStr(const RegionGrid: TStringGrid;
  const OutputMode: TOutputMode): string;
var
  i: integer;
  PickedRegions: TStringList;
begin
  PickedRegions := TStringList.Create;
  try
    if RegionGrid.RowCount < 2 then
      Exit('');
    PickedRegions.Delimiter := #32; // space delimiter
    for i := 1 to RegionGrid.RowCount - 1 do
      if RegionGrid.Rows[i][0] = '1' then
        case OutputMode of
          omMercPool: PickedRegions.Add(RegionGrid.Rows[i][1]);
          omWinCondition: PickedRegions.Add(RegionGrid.Rows[i][2]);
        end;
    PickedRegions.Sort;
    Exit(PickedRegions.DelimitedText);
  finally
    FreeAndNil(PickedRegions);
  end;
end;

// IsDarkTheme: Detects if the Dark Theme (true) has been enabled or not (false)
function IsDarkTheme: boolean;
const
  KEYPATH = '\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize';
  KEYNAME = 'AppsUseLightTheme';
var
  LightKey: boolean;
  Registry: TRegistry;
begin
  Result := False;
  Registry := TRegistry.Create;
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKeyReadOnly(KEYPATH) then
    begin
      if Registry.ValueExists(KEYNAME) then
        LightKey := Registry.ReadBool(KEYNAME)
      else
        LightKey := True;
    end
    else
      LightKey := True;
    Result := not LightKey
  finally
    Registry.Free;
  end;
end;

end.
