#!/bin/bash

NOW=$(date +"%Y%m%d-%H%M%S")

MISSING=false
#check for required programs
if hash jpegtran 2>/dev/null; then
  echo 'jpegtran exists. continuing...'
else
  echo 'jpegtran not installed. please install and try again.'
  MISSING=true
fi

if hash convert 2>/dev/null; then
  echo 'convert exists'
else
  echo 'convert not installed. please install and try again.'
  MISSING=true
fi

if [ $MISSING = true ]; then
  echo 'Exiting due to previous errors.';
exit;
fi

jpg_list=()
while IFS= read -d $'\0' -r jpg ; do
  jpg_list=("${jpg_list[@]}" "$jpg")
done < <(find * -maxdepth 3 -type f -name "*.jpg" -not -path "zoom/*" -not -path "product/*" -not -path "catalog/*" -not -path "thumb/*" -print0)

# see if any jpegs. maxdepth to look is 3 levels.
jpgcount=${#jpg_list[@]}
echo "Found $jpgcount jpegs"

if [ $jpgcount -eq 0 ]; then
  echo "No '.jpg' files found ('.JPG', '.jpeg', etc., ignored). exiting."
  exit 0
fi

#set to true to autocrop
autocrop=false

for i in "${jpg_list[@]}"
do
  echo "$i -> zoom, product, catalog, thumb"
  thisjpg=$(basename $i)
  dir=$(dirname $i)
  tempjpg=$dir"/asdfjkl."$thisjpg
  if [ $autocrop = true ]; then
    convert $i -trim $tempjpg
    height=$(identify -format "%h" $tempjpg)
    width=$(identify -format "%w" $tempjpg)
    maxdim=$(($height>$width?$height:$width))
    echo "Maxdim is $maxdim"
    #if [ $height -ne $width ]; then
    #
    #fi
  fi
  zoombefore=$(stat --printf='%s' $i)
  jpegtran -copy none -optimize -outfile $tempjpg $i
  zoomafter=$(stat --printf='%s' $tempjpg)
  echo "zoom before: $zoombefore - after: $zoomafter"
  if [ $zoomafter -lt $zoombefore ]; then
    echo "It shrank. Using it."
    #overwrite existing and remove temp
    \cp $tempjpg $i                
  fi
  rm -f $tempjpg
  
  zoom='zoom/'$i
  product='product/'$i
  catalog='catalog/'$i
  thumb='thumb/'$i
  mkdir -p "zoom/$dir"
  #       #NO RESIZE FOR ZOOM
  cp $i $zoom
  mkdir -p "product/$dir"
  convert $i -resize 380x380\> $product
  mkdir -p "catalog/$dir"
  convert $i -resize 230x230\> $catalog
  mkdir -p "thumb/$dir"
  convert $i -resize 50x50\> $thumb
  echo "Dir is '$dir'"
  #echo "Zoom image is '$zoom'"
done
