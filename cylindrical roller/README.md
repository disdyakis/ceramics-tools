# Cylindrical Texture Roller
[![OpenSCAD](https://img.shields.io/badge/openscad-%23F9D72C.svg?logo=openscad&logoColor=black&logoSize=auto)](#)&nbsp;&nbsp;[![version](https://img.shields.io/badge/version-0.0.1-blue)](#)&nbsp;&nbsp;[![project type: toy](https://img.shields.io/badge/project%20type-toy-blue)](https://img.shields.io/badge/project%20type-toy-blue)&nbsp;&nbsp;[![BuyMeACoffee](https://raw.githubusercontent.com/pachadotdev/buymeacoffee-badges/main/bmc-white.svg)](https://www.buymeacoffee.com/disdyakis)&nbsp;&nbsp;[![CC BY-NC-SA 4.0][cc-by-nc-sa-shield]][cc-by-nc-sa]&nbsp;&nbsp;[![No AI](https://custom-icon-badges.demolab.com/badge/No%20AI-2f2f2f?logo=non-ai&logoColor=white)](#)&nbsp;&nbsp;[![fuck ice](https://custom-icon-badges.demolab.com/badge/Fuck%20ICE-grey?logo=fuck-ice)](#)

generates a hollow, cylindrical, texture roller using OpenSCAD from an input image

## Pre-requisites
- macOS or Linux
  - (for the shell script, Windows users will still be able to use the .scad file)
- [OpenSCAD](https://openscad.org/downloads.html)
- [BOSL2 library](https://github.com/BelfrySCAD/BOSL2) installed (>=v2.0)

## Usage

```
usage: .\img_to_cylinder.sh [analyze] { --help | -v --version | ...options } image

script that uses openscad to generate a cylindrical texture roller from an image input.
outputs an stl file for 3d printing

	--help		display this message
	-v, --version		 display version
	-h, --height		resize image to specified height before generating stl (images larger than 1024x1024 can take quite a while)
	-w, --width		resize image to specified width before generating stl (images larger than 1024x1024 can take quite a while)
	-ppi, --ppi		the ppi the final print will have [ppi] (default 72, recommended values 72-300)
	-d, --depth		the depth of the grooves on the roller [mm] (default 5, recommended values: 3-8)
	-t, --thickness		the thickness of the cylinder wall [mm] (default 5)
	-o, --output		output file (default ./roller.stl)

analyze:
usage: .\img_to_cylinder.sh analyze { -h --height | -w --width | -ar --aspect-ratio | -ppi --ppi | -r --radius | -l --length | -t --thickness }

specify known variables to find what the unkown variables should be

	-ar, --aspect-ratio		aspect ratio of the input image (x:y format)
	-r, --radius		inner radius of final roller cylinder [in]
	-l, --length		length of final roller roller cyinder [in]
```

### Analyze

helper command to figure out missing dimensions from known values

#### Example

```
$ ./img_to_cylinder.sh analyze -ar 20:1 -r 4 -ppi 150

image
	dimensions: 3953x197
	aspect ratio: 20.06:1
roller
	ppi: 150
	length: 1.31in.
	radius: 4.025in.
	rim thickness: 5mm
```

here, I have the hypothetical that I have an image I want to use that has an aspect ratio of 20:1, and I want the final roller to have an inner radius of 4" (say, to fit on a dowel or texture rolling handle for instance). the output tells me that if I want the detail level to be 150ppi, then the input image needs to have the dimensions of 3953x197.

NOTE: the aspect ratio and the radius in the summary aren't exactly 20:1 and 4 respectively due to rounding errors during calculation, as certain values (i.e. image height and width) cannot have fractional values.

## Helper Scripts

this project's root directory also has two related helper scripts in the 'extras' folder: `cylindrical_roller.scad`, and `scad_to_printf.sh`

`cylindrical_roller.scad` is the openSCAD file that's actually doing all the heavy lifting. you can just open this in the openSCAD gui and use it without using the bash script.

to make it work properly in openSCAD, you'll just have make the following changes:

- line 2: replace `$temp_dir/texture.scad` with the location of a BOSL2 texture file
  - to generate these from an image, use one of the `img2scad` scripts in the scripts folder located in the BOSL2 library directory
- replace instances of `$ppi`, `$h`, `$w`, `$depth`, `$thickness` with values (`$h` and `$w` should the the dimensions of the BOSL2 texture)

if you make changes to the script and then revert the changes above, you can use the `/extras/scad_to_print_f.sh` script to output a replacement for the `printf` command on line 288 of `img_to_cylinder.sh`

## License
[ceramics-tools](https://github.com/disdyakis/ceramics-tools) © 2026 by [michael turenne](https://michaelturenne.com) is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)&nbsp;<img src="https://mirrors.creativecommons.org/presskit/icons/cc.svg" alt=""  width=16>&nbsp;<img src="https://mirrors.creativecommons.org/presskit/icons/by.svg" alt=""  width=16>&nbsp;<img src="https://mirrors.creativecommons.org/presskit/icons/nc.svg" alt="" width=16>&nbsp;<img src="https://mirrors.creativecommons.org/presskit/icons/sa.svg" alt="" width=16>

this license just applies to the code, you can do whatever you want with the 3d files generated from it. but, if you make bank from selling the rollers, or ceramics you make using the rollers, [here's a link to support me](https://www.buymeacoffee.com/disdyakis)


[cc-by-nc-sa]: http://creativecommons.org/licenses/by-nc-sa/4.0/
[cc-by-nc-sa-shield]: https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg
