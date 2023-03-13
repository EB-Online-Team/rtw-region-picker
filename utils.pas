unit Utils;

{$mode ObjFPC}{$H+}{$J-}

interface

uses
  Classes, SysUtils, Generics.Collections, Graphics, StrUtils, Grids, Dialogs;

type
  { Determines whether to expect the religion mechanic (BI). }
  TGameMode = (gmRTW, gmBI);

  { Determines whether to output provinces (merc pool)
    or settlements (win conditions). }
  TOutputMode = (omMercPool, omWinCondition);

  { Holds region data. }
  TRegion = record
    Province, Settlement: string;
  end;

  { Maps region color to region data. }
  TRegionDictionary = specialize TDictionary<TColor, TRegion>;

{ Read descr_regions.txt and map region color to data.
  @param(Filename is the path to descr_regions.txt)
  @param(GameMode tells whether to expect RTW or BI format)
  @returns(A dictionary mapping region color to data) }
function LoadRegions(const Filename: string;
  const GameMode: TGameMode = gmRTW): TRegionDictionary;

{ Save picked regions to text file.
  @param(Filename is the path to save to)
  @param(RegionGrid is the spreadsheet to read from)
  @param(OutputMode determines whether to save provinces or settlements) }
procedure SavePickedRegionsToFile(const Filename: string;
  const RegionGrid: TStringGrid; const OutputMode: TOutputMode = omMercPool);

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
    fsOut.Write(s[1], Length(s));
    FreeAndNil(fsOut);
    Exit(True);
  except
    Exit(False);
  end;
end;

procedure SavePickedRegionsToFile(const Filename: string;
  const RegionGrid: TStringGrid; const OutputMode: TOutputMode = omMercPool);
var
  i: integer;
  PickedRegions: TStringList;
begin
  if RegionGrid.RowCount < 2 then
    Exit;
  PickedRegions := TStringList.Create;
  PickedRegions.Delimiter := #32; // space delimiter
  for i := 1 to RegionGrid.RowCount - 1 do
    if RegionGrid.Rows[i][0] = '1' then
      case OutputMode of
        omMercPool: PickedRegions.Add(RegionGrid.Rows[i][1]);
        omWinCondition: PickedRegions.Add(RegionGrid.Rows[i][2]);
      end;
  PickedRegions.Sort;
  SaveStringToFile(PickedRegions.DelimitedText, Filename);
  FreeAndNil(PickedRegions);
end;

end.
