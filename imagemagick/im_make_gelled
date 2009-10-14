#!/bin/bash
convert "$1" \
            \( +clone -fx A +matte  -blur 0x12  -shade 60x0 -normalize \
               -sigmoidal-contrast 16,60% -evaluate Multiply .5 \
               -roll +5+10 +clone -compose Screen -composite \) \
           	 -matte  -compose In  -composite \
            \( +clone -fx A  +matte -blur 0x2  -shade 0x90 -normalize \
               -blur 0x2  -negate -evaluate multiply 0.4 -negate -roll -.5-1 \
               +clone  -compose Multiply -composite \) \
            -matte  -compose In  -composite gelled_${1}
