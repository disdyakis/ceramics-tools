# Spherical Texture Roller
[![OpenSCAD](https://img.shields.io/badge/openscad-%23F9D72C.svg?logo=openscad&logoColor=black&logoSize=auto)](#)&nbsp;&nbsp;[![version](https://img.shields.io/badge/version-0.0.1-blue)](#)&nbsp;&nbsp;[![project type: toy](https://img.shields.io/badge/project%20type-toy-blue)](https://img.shields.io/badge/project%20type-toy-blue)&nbsp;&nbsp;[![BuyMeACoffee](https://raw.githubusercontent.com/pachadotdev/buymeacoffee-badges/main/bmc-white.svg)](https://www.buymeacoffee.com/disdyakis)&nbsp;&nbsp;[![CC BY-NC-SA 4.0][cc-by-nc-sa-shield]][cc-by-nc-sa]&nbsp;&nbsp;[![No AI](https://custom-icon-badges.demolab.com/badge/No%20AI-2f2f2f?logo=non-ai&logoColor=white)](#)&nbsp;&nbsp;[![fuck ice](https://custom-icon-badges.demolab.com/badge/Fuck%20ICE-grey?logo=fuck-ice)](#)

generates a solid, spherical, texture roller using OpenSCAD from an input image

## Pre-requisites
- macOS or Linux
  - (for the shell script, Windows users will still be able to use the .scad file)
- [OpenSCAD](https://openscad.org/downloads.html)
- [BOSL2 library](https://github.com/BelfrySCAD/BOSL2) installed (>=v2.0)

## Usage

```
usage: .\img_to_stamp.sh [analyze] { --help | -v --version | ...options } image

script that uses openscad to generate a stamp from an image input.
outputs an stl file for 3d printing

	--help		display this message
	-v, --version		 display version
	-h, --height		resize image to specified height before generating stl
	-w, --width		resize image to specified width before generating stl
	-ppi, --ppi		the ppi the final print will have [ppi] (default 72, recommended values 72-300)
	-d, --depth		the depth of the grooves on the roller [mm] (default 5, recommended values: 3-8)
	-t, --threshold	takes the first x% of stamp instead of the full pixel range. useful for fine detail/small stamps where the geometry of the stamp gets too jagged for printing (0.0 - 1.0] (default 1)
	-hd, --hole-diameter	diameter of hole to put a dowel in to create a longer handle [mm] (default 8.2 [5/16" dowel])
	-c, --clearence	clearence needed to add to the dowel hole so it fits nicely after printing [mm] (default 0.2)
	-o, --output		output file (default ./roller.stl)

analyze:
usage: .\img_to_stamp.sh analyze { -h --height | -w --width | -ppi --ppi | -ar --aspect-ratio | -x | -y }

specify known variables to find what the unkown variables should be

	-ar, --aspect-ratio		aspect ratio of the input image (x:y format)
	-x		dimension of final stamp in the x-dimension, corresponds to width [in]
	-y		dimension of final stamp in the y-dimension, corresponds to height [in]
```

### Analyze

helper command to figure out missing dimensions from known values

#### Example

```
$ ./img_to_stamp.sh analyze -ar 2:1 -x 2 -ppi 300

image
	dimensions: 600x300
	aspect ratio: 2:1
stamp
	ppi: 300
	x: 2.00in.
	y: 1.00in.
```

here, I have the hypothetical that I want the final stamp to have a x-dimension of 2in. and a resolution of 300 ppi. the output tells me the input image will need to have the dimensions of 600x300.

## Helper Scripts

this project's root directory also has two related helper scripts in the 'extras' folder: `stamp.scad`, and `scad_to_printf.sh`

`stamp.scad` is the openSCAD file that's actually doing all the heavy lifting. you can just open this in the openSCAD gui and use it without using the bash script.

to make it work properly in openSCAD, you'll just have make the following changes:

- replace instances of `$ppi`, `$h`, `$w`, `$depth`, `$threshold`, `$hole`, `$clearence`, `$img` with values (`$h` and `$w` should the the dimensions of the image)

if you make changes to the script and then revert the changes above, you can use the `/extras/scad_to_print_f.sh` script to output a replacement for the `printf` command on line XXX of `img_to_stamp.sh`

## License
[ceramics-tools](https://github.com/disdyakis/ceramics-tools) © 2026 by [michael turenne](https://michaelturenne.com) is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)&nbsp;<img src="https://mirrors.creativecommons.org/presskit/icons/cc.svg" alt=""  width=16>&nbsp;<img src="https://mirrors.creativecommons.org/presskit/icons/by.svg" alt=""  width=16>&nbsp;<img src="https://mirrors.creativecommons.org/presskit/icons/nc.svg" alt="" width=16>&nbsp;<img src="https://mirrors.creativecommons.org/presskit/icons/sa.svg" alt="" width=16>

this license just applies to the code, you can do whatever you want with the 3d files generated from it. but, if you make bank from selling the rollers, or ceramics you make using the rollers, [here's a link to support me](https://www.buymeacoffee.com/disdyakis)


[cc-by-nc-sa]: http://creativecommons.org/licenses/by-nc-sa/4.0/
[cc-by-nc-sa-shield]: https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg
