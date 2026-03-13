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
    echo "script that uses openscad to generate a cylindrical texture roller from an image input."
    echo "outputs an stl file for 3d printing"
    echo
    echo -e "\t--help\t\tdisplay this message"
    echo -e "\t-v, --version\t\t display version"
    echo -e "\t-h, --height\t\tresize image to specified height before generating stl (images larger than 1024x1024 can take quite a while)"
    echo -e "\t-w, --width\t\tresize image to specified width before generating stl (images larger than 1024x1024 can take quite a while)"
    echo -e "\t-ppi, --ppi\t\tthe ppi the final print will have [ppi] (default 72, recommended values 72-300)"
    echo -e "\t-d, --depth\t\tthe depth of the grooves on the roller [mm] (default 5, recommended values: 3-8)"
    echo -e "\t-t, --thickness\t\tthe thickness of the cylinder wall [mm] (default 5)"
    echo -e "\t-o, --output\t\toutput file (default ./roller.stl)"
    echo
    echo "analyze:"
    echo "usage: .\\$(basename "$0") analyze { -h --height | -w --width | -ar --aspect-ratio | -ppi --ppi | -r --radius | -l --length | -t --thickness }"
    echo
    echo "specify known variables to find what the unkown variables should be"
    echo
    echo -e "\t-ar, --aspect-ratio\t\taspect ratio of the input image (x:y format)"
    echo -e "\t-r, --radius\t\tinner radius of final roller cylinder [in]"
    echo -e "\t-l, --length\t\tlength of final roller roller cyinder [in]"
    echo
    exit 1
}
display_version() {
    echo "$(basename "$0") 0.1"
    echo "copyright (c) 2026 michael turenne and contributors"
    echo "report bugs at: https://github.com/disdyakis/ceramics-tools/issues"
}
# summary function (args order): width, height, ppi, thickness, depth
summary() {
    echo -ne "\n"
    echo "image"
    echo -e "\tdimensions: ${1}x${2}"
    echo -e "\taspect ratio: $(aspect-ratio "$1" "$2")"
    echo "roller"
    echo -e "\tppi: $3"
    echo -e "\tlength: $(bc <<<"scale=2;$2/$3")in."
    echo -e "\tradius: $(bc -l <<<"scale=2;($1/((8*a(1))*$3))-(0.039*$4)")in."
    echo -e "\trim thickness: ${4}mm"
    if [ -n "$5" ]; then
        echo -e "\ttexture depth: ${5}mm"
    fi
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
depth=8
thickness=5
dir=$(dirname "$0")
output=roller.stl
# parse args
# first make sure the first arg is either help, version, a valid option, otherwise there's a bad option and also display help
case $1 in
    --help)
        display_help "$0"
        ;;
    -v | --version)
        display_version "$0"
        ;;
    -o | --output | -ppi | --ppi | -d | --depth | -t | --thickness | -h | --height | -w | --width | -l | --length | -ar | --aspect-ratio | -r | --radius | analyze) ;;
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
    -t | --thickness) thickness=$2 ;;
    -h | --height) h=$2 ;;
    -w | --width) w=$2 ;;
    -l | --length) l=$2 ;;
    -r | --radius) r=$2 ;;
    -ar | --aspect-ratio) ar=$2 ;;
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
    # array slots = (height width aspect-ratio length radius ppi)
    declare -a which_solved=(false false false false false false)
    if ! [ -z "$h" ]; then which_solved[0]=true; fi
    if ! [ -z "$w" ]; then which_solved[1]=true; fi
    if ! [ -z "$ar" ]; then
        regex="([0-9.]+):([0-9.]+)"
        [[ $ar =~ $regex ]]
        which_solved[2]=true;
        ar=$(bc <<<"scale=2;${BASH_REMATCH[1]}/${BASH_REMATCH[2]}")
    fi
    if ! [ -z "$l" ]; then which_solved[3]=true; fi
    if ! [ -z "$r" ]; then which_solved[4]=true; fi
    if ! [ -z "$ppi" ]; then which_solved[5]=true; fi
    if [ -n "$h" -a -n "$w" -a -n "$ar" ] || [ -n "$r" -a -n "$l" -a -n "$ar" ]; then
        echo "$bold${yellow}WARNING:$reset ignoring ar input and re-calculating"
        unset ar
        which_solved[2]=false
    fi
    if [ -n "$h" -a -n "$l" -a -n "$ppi" ] || [ -n "$w" -a -n "$r" -a -n "$ppi" ]; then
        echo "$bold${yellow}WARNING:$reset ignoring ppi input and re-calculating"
        unset ppi
        which_solved[5]=false
    fi
    if [ -n "$h" ] && [ -n "$w" ] && [ -n "$r" ] && [ -n "$l" ]; then
        echo "$bold${yellow}WARNING:$reset too many constraints, ignoring "
        if ! [ -z "$ppi" ]; then echo -n "radius"; unset r; fi
        if ! [ -z "$ar" ]; then echo -n "height"; unset h; fi
        echo -n " and length inputs"
        unset l
    fi
    # while slots are unsolved, keep looping and try to calculate any variables we have the prerequisites to figure out
    # if it loops without having solved any more variables, it's stuck due to insufficient input
    while [ $(solved $which_solved) -ne 6 ]; do
        prev_solved=$(solved $which_solved)
        if [ -z "$h" ]; then
            if [ -n "$w" ] && [ -n "$ar" ]; then
                h=$(bc <<<"var=$w/$ar; scale=0; var/1")
                which_solved[0]=true
            elif [ -n "$l" ] && [ -n "$ppi" ]; then
                h=$(bc <<<"var=$l*$ppi; scale=0; var/1")
                which_solved[0]=true
            fi
        fi
        if [ -z "$w" ]; then
            if [ -n "$h" ] && [ -n "$ar" ]; then
                w=$(bc <<<"var=$h*$ar;scale=0;var/1")
                which_solved[1]=true
            elif [ -n "$r" ] && [ -n "$ppi" ]; then
                w=$(bc -l <<<"var=($r + (0.039*$thickness)) * 8*a(1) * $ppi;scale=0;var/1")
                which_solved[1]=true
            fi
        fi
        if [ -z "$ppi" ]; then
            if [ -n "$r" ] && [ -n "$w" ]; then
                circumference=$(bc -l <<<"scale=2;$r*8*a(1)")
                ppi=$(bc <<<"scale=10;var=$w/$circumference;scale=0;var/1")
                which_solved[5]=true
            elif [ -n "$h" ] && [ -n "$l" ]; then
                ppi=$(bc <<<"scale=10;var=$h/$l;scale=0;var/1")
                which_solved[5]=true
            fi
        fi
        if [ -z "$ar" ]; then
            if [ -n "$h" ] && [ -n "$w" ]; then
                ar=$(bc <<<"scale=3;$w/$h")
                which_solved[2]=true
            elif [ -n "$r" ] && [ -n "$l" ]; then
                ar=$(bc <<<"scale=3;$r/$l")
                which_solved[2]=true
            fi
        fi
        if [ -z "$r" ]; then
            if [ -n "$w" ] && [ -n "$ppi" ]; then
                circumference=$(bc <<<"scale=2;$ppi/$w")
                r=$(bc -l <<<"var=$circumference/(8*a(1));scale=0;var/1")
                which_solved[4]=true
            elif [ -n "$l" ] && [ -n "$ar" ]; then
                circumference=$(bc <<<"scale=2;$l*$ar")
                r=$(bc -l <<<"var=$circumference/(8*a(1));scale=0;var/1")
                which_solved[4]=true
            fi
        fi
        if [ -z "$l" ]; then
            if [ -n "$h" ] && [ -n "$ppi" ]; then
                l=$(bc <<<"scale=10;var=$ppi/$h;scale=0;var/1")
                which_solved[3]=true
            elif [ -n "$r" ] && [ -n "$ar" ]; then
                circumference=$(bc -l <<<"scale=10;$r*8*a(1)")
                l=$(bc <<<"scale=10;var=$circumference/$ar;scale=0;var/1")
                which_solved[3]=true
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
# convert image to texture, generate openscad file, and use openscad to generate stl file for 3d printing
temp_dir=$(mktemp -d)
python3 ~/Documents/OpenSCAD/libraries/BOSL2/scripts/img2scad.py "$img" -o "$temp_dir"/texture.scad -v image_array -r "${w}"x"${h}" > /dev/null 2>&1 &
printf "include <BOSL2/std.scad>\ninclude <$temp_dir/texture.scad>\n\n\$fn= \$preview ? 20 : 200;\n\n//desired ppi has to be specified so the thickness and embossing depth can be consistent\nppi = $ppi;\nh = $h;\nw = $w;\n\nradius = w/(2*PI);\nheight = h;\npath = circle(r=radius);\nutomm = ppi/25.4;\n\n// how much the texture extrudes in mm (3-8)\ndepth = $depth * utomm;\n// how thick the cylinder is (5mm)\nthickness = $thickness * utomm;\n\ndifference() {\n    linear_sweep(\n        path, texture=image_array, tex_inset=false, tex_depth=-depth, tex_size=[h, w],\n        h=height, style=\"alt\");\n    down(10) cylinder(h=height + 20, r=radius - thickness);\n}" > "$temp_dir/roller.scad"
$cmd -q --export-format stl -o "$dir"/"$output" --backend Manifold "$temp_dir"/roller.scad & pid=$!
# spinner logic, remove this and the & pid=$! on the line above to remove spinner
trap 'kill $pid; exit' INT
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
summary "$w" "$h" "$ppi" "$thickness" "$depth"
# cleanup tmp files
rm -rf "$temp_dir"
