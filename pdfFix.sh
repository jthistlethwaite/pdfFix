#/bin/bash

function toImage {
 input=$1
 output=$2
 orderid=$3
 carrier=$4

  # file already exists; don't need to do it
	if [ -f $output ]; then
		return 0;
	fi


# Great for dhl labels
if [ "$carrier" == "DHL" ]; then
	convert -density 300 -flatten -sharpen 0x1.0 \
		"$input" -quality 100 -trim  +repage -rotate "90" -resize 1200x1800 \
		-extent 1200x1800 \
		-font helvetica -pointsize 12 -draw "text 250,1700 'Order: $orderid'" \
		"$output"

elif [ "$carrier" == "USPS" ]; then
	convert -density 300 -flatten -sharpen 0x1.0 \
		"$input" -quality 100 -trim  +repage  -resize 1200x1800 \
		-extent 1200x1800 \
		"$output"

elif [ "$carrier" == "FEDEX" ]; then
	# if it's 8.5x11 at 300dpi then 2250 x 3300
	convert -density 300 "$input" -rotate "-90" -crop 1600x2250+0+0 \
		-resize 1200x1800 -extent 1200x1800 +repage \
		-font helvetica -pointsize 12 -draw "text 250,1700 'Order: $orderid'" \
		"$output"
fi

# Doesn't work because it needs re-encoded for code128
#-font code128.ttf -pointsize 30 -draw "text 100,1760 '$orderid'" \

#	convert -verbose -density 300 -flatten -sharpen 0x1.0 \
#		"$input" -quality 100 -trim  +repage -auto-orient -resize 1200x1800 -extent 1200x1800 "$output"



	#rePdf "$output" "$output.pdf"
}

CONVERT=`which convert`

if [[ -x "$CONVERT" ]]; then
	imagick=1
else
	echo "imagemagick not installed"
	exit `false`
fi

PDFUNITE=`which pdfunite`

if [[ -x "$PDFUNITE" ]]; then
 pdfunite=1
else
	echo "poppler-utils not installed"
	exit `false`
fi

for i in $@; do
	input="$i"
	fileName=`basename $i`

	orderid=`echo $fileName | sed -e 's/__.*$//'`
	tracker=`echo $fileName | sed -e 's/^.*__//' -e 's/\.pdf$//'`

	trackerPrefix=`echo $tracker | cut -c 1-4`

	output="./4x6/$fileName.4x6.pdf"

	echo "t: $tracker"
	echo "$trackerPrefix"
  echo "$input => $output $orderid"


 case $trackerPrefix in
	"9374")
			##dhl
			carrier="DHL"
		;;

	"9400")
		##USPS
		carrier="USPS"
	;;

	"7844")
		##fedex ground
		carrier="FEDEX"
	;;
  "7845")
		## fedex home
		carrier="FEDEX"
	;;

	*)
		carrier="UNKNOWN"
	;;
 esac

	toImage "$input" "$output" "$orderid" "$carrier"

done

cd 4x6/
rm ../merged.pdf
pdfunite ./*pdf ../merged.pdf
