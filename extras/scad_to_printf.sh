#! /bin/sh

content="`cat "$1"`"
content="${content//\$fn/\\\$fn}"
content="${content//\$preview/\\\$preview}"
# add other openscad special variables here
content="${content//$'\n'/\\\\n}"
echo "printf \"$content\" > \"\$temp_dir/roller.scad\""
