#! /bin/bash
# ps1 codes
bold="$(tput bold )"
red="$(tput setaf 1 )"
reset="$(tput sgr0 )"
yellow="$(tput setaf 3 )"
# help message
display_help() {
    echo "usage: .\\$(basename "$0") [analyze] { --help | -v --version | ...options } image" >&2
    echo
    echo "script that uses openscad to generate a stamp from an image input."
    echo "outputs an stl file for 3d printing"
    echo
    # XXX fix this message
    echo -e "\t--help\t\tdisplay this message"
    echo -e "\t-v, --version\t\t display version"
    echo -e "\t-h, --height\t\tresize image to specified height before generating stl (images larger than 1024x1024 can take quite a while)"
    echo -e "\t-w, --width\t\tresize image to specified width before generating stl (images larger than 1024x1024 can take quite a while)"
    echo -e "\t-ppi, --ppi\t\tthe ppi the final print will have [ppi] (default 72, recommended values 72-300)"
    echo -e "\t-d, --depth\t\tthe depth of the grooves on the roller [mm] (default 5, recommended values: 3-8)"
    echo -e "\t-o, --output\t\toutput file (default ./stamp.stl)"
    echo
    echo "analyze:"
    echo "usage: .\\$(basename "$0") analyze { -h --height | -w --width | -ppi --ppi | -r --radius }"
    echo
    echo "specify known variables to find what the unkown variables should be"
    echo
    echo -e "\t-r, --radius\t\tinner radius of final roller cylinder [in]"
    echo
    exit 1
}
display_version() {
    echo "$(basename "$0") 0.1"
    echo "copyright (c) 2026 michael turenne and contributors"
    echo "report bugs at: https://github.com/disdyakis/ceramics-tools/issues"
}
# summary function (args order): width, height, ar, ppi, x, y, depth
summary() {
    echo -ne "\n"
    echo "image"
    echo -e "\tdimensions: ${1}x${2}"
    echo -e "\taspect ratio: $3"
    echo "stamp"
    echo -e "\tppi: $4"
    echo -e "\tx: $5in."
    echo -e "\ty: $6in."
    # XXX only show if populated
    echo -e "\ttexture depth: ${7}mm"
    echo
}
# helper functions
gcd() (
    ! (( $1 % $2 )) && echo "$2" || gcd "$2" $(( $1 % $2 ))
)
aspect-ratio() (
    local d=$(gcd "$1" "$2")
    if [[ $d -eq 1 ]]; then
        if [[ $1 -gt $2 ]]; then
            echo $(bc <<<"scale=2;$1/$2" | sed '/\./ s/\.\{0,1\}0\{1,\}$//'):$(bc <<<"scale=2;$2/$2" | sed '/\./ s/\.\{0,1\}0\{1,\}$//')
        else
            echo $(bc <<<"scale=2;$1/$1" | sed '/\./ s/\.\{0,1\}0\{1,\}$//'):$(bc <<<"scale=2;$2/$1" | sed '/\./ s/\.\{0,1\}0\{1,\}$//')
        fi
    else
        echo $(($1/$d)):$(($2/$d))
    fi
)
solved() (
    local count=0
    for i in "${which_solved[@]}"
    do
      if [[ $i == true ]]
      then
        count=$((count+1))
      fi
    done
    echo $count
)
# defaults
ppi=72
depth=3
threshold=1
hole=8.2
clearence=.2
dir=$(dirname "$0")
output=stamp.stl
# parse args
# first make sure the first arg is either help, version, a valid option, otherwise there's a bad option and also display help
case $1 in
    --help)
        display_help "$0"
        ;;
    -v | --version)
        display_version "$0"
        ;;
    -o | --output | -ppi | --ppi | -ar | --aspect-ratio | -d | --depth | -h | --height | -w | --width | -x | -y | -t | --threshold | -hd | --hole-diameter | -c | -clearence | analyze) ;;
    *)
        reg="^[\-]+"
        if [[ $1 =~ $reg ]]; then
            display_help "$0"
        fi
        ;;
esac
# if it's an analyze command we'll use shift so the following options all look like [-flag arg]
if [[ $1 = "analyze" ]]; then
    analyze=1
    shift
fi
# if analyze is true we don't expect the final argument being the image, we expect it to be the last flag's argument
while [ $# -gt $((1-analyze)) ] ; do
  case $1 in
    -o | --output) output="$2" ;;
    -ppi | --ppi)
        ppi=$2
        ppi_set=1
        ;;
    -d | --depth) depth=$2 ;;
    -h | --height) h=$2 ;;
    -w | --width) w=$2 ;;
    -ar | --aspect-ratio) ar=$2 ;;
    -x) x=$2 ;;
    -y) y=$2 ;;
    -t | --threshold) threshold=$2 ;;
    -hd | --hole-diameter) hole=$2 ;;
    -c | --clearence) clearence=$2 ;;
    analyze)
        if ! [[ analyze -eq 1 ]] ; then
            display_help "$0"
        fi
        ;;
    *)
        display_help "$0"
        ;;
  esac
  shift
  shift
done
# if not doing analyze, then the last remaining arg is the image argument
img=$1
# 'analyze' sub-command
if [[ $analyze -eq 1 ]]; then
    if ! [ "$ppi_set" = 1 ]; then
        unset ppi
    fi
    # array slots = (height width aspect-ratio x y ppi)
    declare -a which_solved=(false false false false false false)
    if ! [ -z "$h" ]; then which_solved[0]=true; fi
    if ! [ -z "$w" ]; then which_solved[1]=true; fi
    if ! [ -z "$ar" ]; then
        regex="([0-9.]+):([0-9.]+)"
        [[ $ar =~ $regex ]]
        which_solved[2]=true;
        ar=$(bc <<<"scale=2;${BASH_REMATCH[1]}/${BASH_REMATCH[2]}")
    fi
    if ! [ -z "$x" ]; then which_solved[3]=true; fi
    if ! [ -z "$y" ]; then which_solved[4]=true; fi
    if ! [ -z "$ppi" ]; then which_solved[5]=true; fi
    if [ -n "$h" -a -n "$w" -a -n "$ar" ] || [ -n "$x" -a -n "$y" -a -n "$ar" ]; then
        echo "$bold${yellow}WARNING:$reset ignoring ar input and re-calculating"
        unset ar
        which_solved[2]=false
    fi
    if [ -n "$h" -a -n "$y" -a -n "$ppi" ] || [ -n "$w" -a -n "$x" -a -n "$ppi" ]; then
        echo "$bold${yellow}WARNING:$reset ignoring ppi input and re-calculating"
        unset ppi
        which_solved[5]=false
    fi
    if [ -n "$h" ] && [ -n "$w" ] && [ -n "$x" ] && [ -n "$y" ]; then
        echo "$bold${yellow}WARNING:$reset too many constraints, ignoring "
        if ! [ -z "$ar" ]; then echo -n "height"; unset h; fi
        if ! [ -z "$ppi" ]; then echo -n "x"; unset x; fi
        echo -n " and y inputs"
        unset y
    fi
    # while slots are unsolved, keep looping and try to calculate any variables we have the prerequisites to figure out
    # if it loops without having solved any more variables, it's stuck due to insufficient input
    while [ $(solved $which_solved) -ne 6 ]; do
        prev_solved=$(solved $which_solved)
        if [ -z "$ar" ]; then
            if [ -n "$h" ] && [ -n "$w" ]; then
                ar=$(bc <<<"scale=3;$w/$h")
                which_solved[2]=true
            elif [ -n "$x" ] && [ -n "$y" ]; then
                ar=$(bc <<<"scale=3;$x/$y")
                which_solved[2]=true
            fi
        fi
        if [ -z "$ppi" ]; then
            if [ -n "$w" ] && [ -n "$x" ]; then
                ppi=$(bc <<<"scale=10;var=$w/$x;scale=0;var/1")
                which_solved[5]=true
            elif [ -n "$h" ] && [ -n "$y" ]; then
                ppi=$(bc <<<"scale=10;var=$h/$y;scale=0;var/1")
                which_solved[5]=true
            fi
        fi
        if [ -z "$h" ]; then
            if [ -n "$w" ] && [ -n "$ar" ]; then
                h=$(bc <<<"var=$w/$ar; scale=0; var/1")
                which_solved[0]=true
            elif [ -n "$y" ] && [ -n "$ppi" ]; then
                h=$(bc <<<"var=$y*$ppi; scale=0; var/1")
                which_solved[0]=true
            fi
        fi
        if [ -z "$w" ]; then
            if [ -n "$h" ] && [ -n "$ar" ]; then
                h=$(bc <<<"var=$h*$ar; scale=0; var/1")
                which_solved[1]=true
            elif [ -n "$x" ] && [ -n "$ppi" ]; then
                h=$(bc <<<"var=$x*$ppi; scale=0; var/1")
                which_solved[1]=true
            fi
        fi
        if [ -z "$x" ]; then
            if [ -n "$w" ] && [ -n "$ppi" ]; then
                x=$(bc <<<"scale=2;var=$ppi/$w;scale=0;var/1")
                which_solved[3]=true
            elif [ -n "$y" ] && [ -n "$ar" ]; then
                x=$(bc <<<"scale=2;var=$y*$ar;scale=0;var/1")
                which_solved[3]=true
            fi
        fi
        if [ -z "$y" ]; then
            if [ -n "$h" ] && [ -n "$ppi" ]; then
                y=$(bc <<<"scale=10;var=$ppi/$h;scale=0;var/1")
                which_solved[4]=true
            elif [ -n "$x" ] && [ -n "$ar" ]; then
                circumference=$(bc -l <<<"scale=10;$r*8*a(1)")
                y=$(bc <<<"scale=10;var=$x/$ar;scale=0;var/1")
                which_solved[4]=true
            fi
        fi
        if [ $(solved $which_solved) -eq $prev_solved ]; then
            if [ -z "$ppi" ]; then
                echo "$bold${yellow}WARNING:$reset insufficient inputs: setting ppi to default (72)"
                ppi=72
                which_solved[5]=true
            else
                # could change this to a warning and show a partial summary of any info we were able to calculate
                echo "$bold${red}ERROR:$reset insufficient inputs"
                exit 123
            fi
        fi
    done
    summary "$w" "$h" "$ppi" "$thickness"
    exit 0
fi
# error if image isn't specified
if ! [ -f $img ]; then
    echo "$bold${red}ERROR:$reset could not find input image '$img'"
    exit 125
fi
# command changes depending on location of openscad binary, i.e. mac vs. linux
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     cmd="openscad";;
    Darwin*)    cmd="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD";;
    *)          cmd="UNKNOWN"
esac
if [ "$cmd" = "UNKNOWN" ]; then
    echo "$bold${red}ERROR:$reset could not determine OS type for finding openscad bin"
    exit 125
fi
if ! [[ $h -gt 0 && $w -gt 0 ]] ; then
    # get height and width from input image
    info=$(file "$img")
    regex=", ?([0-9]+) ?x ?([0-9]+) ?,"
    if ! [[ $info =~ $regex ]]
    then
        echo "$bold${red}ERROR:$reset could not find dimensions of image"
        exit 125
    fi
    if ! [[ $w -gt 0 ]] ; then
        w=${BASH_REMATCH[1]}
    fi
    if ! [[ $h -gt 0 ]] ; then
        h=${BASH_REMATCH[2]}
    fi
fi
# generate openscad file, and use openscad to generate stl file for 3d printing
temp_dir=$(mktemp -d)
printf "include <BOSL2/std.scad>\n\$fn= \$preview ? 20 : 200;\n\nh = $h;\nw = $w;\nppi = $ppi;\nutomm = ppi/25.4;\n// how much the texture extrudes in mm (3-8)\ndepth = $depth * utomm;\nthreshold = $threshold;\nhole_diameter = $hole;\nclearence = $clearence;\n\n\nrotate([0, 180, 0]) {\n    difference() {\n        up((depth/threshold) - depth) scale([1, 1, 1/100 * (depth/threshold)])\n        surface(file = "$img", center = true, invert = true);\n        up(depth/threshold/2) cube([w * 1.5, h * 1.5, depth/threshold], center=true, \$fn=100);\n    }\n    thickness = depth;\n    down(depth*3/2 - 1) rotate([0, 0, 90])\n        cube([h - 1, w - 1, thickness], center=true, \$fn=100);\n}\n\ncirc = circle(\$fn=80, r=12);\n\ndown(1) difference() {\n    height = 10;\n    rotate([0, 0, 90]) up(depth * 2) skin([rect([h - 1, w - 1]), circle(r=utomm * 6)], z=[0, height*utomm], slices=20);\n    up(depth * 2) scale(utomm) cylinder(r=(hole_diameter - clearence)/2, h=height+1);\n}" > "$temp_dir/roller.scad"
$cmd -q --export-format stl -o "$dir"/"$output" --backend Manifold "$temp_dir"/roller.scad & pid=$!
# spinner logic, remove this and the & pid=$! on the line above to remove spinner
trap 'kill $pid; rm -rf "$temp_dir"; exit' INT
sp=("⣼" "⣹" "⢻" "⠿" "⡟" "⣏" "⣧")
frame_index=0
frame_count=7
while ps -p $pid > /dev/null
do
    current_frame="${sp[$frame_index]}"
    printf '\b%.0s' {0..18}
    printf "%s generating stl..." "$current_frame"
    frame_index=$(( (frame_index + 1) % frame_count ))
    sleep 0.1
done
printf "done!\n"
# summary
summary "$w" "$h" "$ar" "$ppi" "$x" "$y" "$depth"
# cleanup tmp files
rm -rf "$temp_dir"
