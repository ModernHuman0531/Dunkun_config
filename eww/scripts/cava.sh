#!/bin/zsh
cava -p <(cat <<EOF # Use -p to dynamically load in temp config
[general]
bars = 24 # Tell cava: we need only 24 bars
[output]
method = raw # Tell cava don't draw the image in terminal, just output the raw data
raw_target = /dev/stdout # Directly output the raw data into stdout
data_format = ascii # Use Ascii format
ascii_max_range = 6 # Limit the range from 0 to 6
EOF
) | sed -u 's/;//g;s/0/▂/g;s/1/▃/g;s/2/▄/g;s/3/▅/g;s/4/▆/g;s/5/▇/g;s/6/█/g;'
