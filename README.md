# RTW Region Picker

GUI app to pick regions from _Rome: Total War_ modifications either visually (`map_regions.tga`) or by marking checkboxes on a list. The app outputs selected regions to `regions.txt` as a space-delimited list of either province names (merc pool option) or settlement names (win conditions option). This output file is updated in real time as you pick and unpick any regions. **The app will overwrite any previous `regions.txt` file, so please make backups if necessary.**

To use, browse for a campaign folder (e.g., `world\maps\campaign\imperial_campaign`). If a file is not found in the campaign folder, the app will look for it in `world\maps\base`. If either `map_regions.tga` or `descr_regions.txt` is not found, the app will notify the user.

Make sure the correct game mode is selected (e.g., if the mod uses the religion mechanic from BI).

## Download

Visit the [**Releases**](https://gitlab.com/eb-online/tools/rtw-region-picker/-/releases) page to download the latest package.

## Screenshot

![RTW Region Picker (screenshot)](screenshot.png)

Brought to you by the EB Online Team
