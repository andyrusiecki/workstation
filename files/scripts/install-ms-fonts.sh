#!/bin/bash

set -euo pipefail

function silent() {
  "$@" > /dev/null
}

fonts=(
  andale32
  arial32
  arialb32
  comic32
  courie32
  georgi32
  impact32
  times32
  trebuc32
  verdan32
  webdin32
)

tmp_dir=$(mktemp -d)
base_dir="/usr/share/fonts"

mkdir -p $base_dir

for font in ${fonts[@]}
do
  fontdir="$base_dir/ms-$font"

  silent curl -L http://downloads.sourceforge.net/corefonts/$font.exe --output $tmp_dir/$font.exe &> /dev/null

  if [ -d "$fontdir" ]; then
    rm -r $fontdir
  fi

  silent mkdir -p $fontdir
  silent cabextract -d $fontdir/ $tmp_dir/$font.exe &>/dev/null

  echo "Added Micosoft Font: $font"
done

rm -rf $tmp_dir
