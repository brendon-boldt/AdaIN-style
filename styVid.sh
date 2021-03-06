set -e

# Get a carriage return into `cr`
cr=`echo $'\n.'`
cr=${cr%.}

# Check if FFMPEG is installed
FFMPEG=ffmpeg
command -v $FFMPEG >/dev/null 2>&1 || {
  echo >&2 "This script requires ffmpeg. Aborting."; exit 1;
}

if [ "$#" -le 1 ]; then
   echo "Usage: ./styVid.sh <path_to_video> <path_to_style_directory>"
   exit 1
fi

# Parse arguments
filename=$(basename "$1")
extension="${filename##*.}"
filename="${filename%.*}"
filename=${filename//[%]/x}
#styledirpath=$2
styleimage=$2
absoluteOutputPath=$3
contentSize=$4
styleSize=$5

inputPrefix="upload-"
outputPrefix="output-"

# Create processing and output folder
mkdir -p videoprocessing/${inputPrefix}${filename}
mkdir -p videos/${filename}

#echo ""
#read -p "Maximum recommended resolution with a Titan X 12GB: 500,000 pixels \
  #(i.e around 960:540). Please enter a resolution at which the content video should be processed, \
  #in the format w:h (example 640:480), or press enter to use the original resolution $cr > " resolution
height=$contentSize
width=$(echo "$contentSize * 16/9" | bc)
resolution="$width:$height"

# Obtain FPS of input video
fps=$(ffmpeg -i $1 2>&1 | sed -n "s/.*, \(.*\) fp.*/\1/p")

# Save frames of the video as individual image files
if [ -z $resolution ]; then
  $FFMPEG -i $1 -r ${fps} videoprocessing/${inputPrefix}${filename}/frame_%04d.ppm
  resolution=default
else
  $FFMPEG -i $1 -vf scale=$resolution -r ${fps} videoprocessing/${inputPrefix}${filename}/frame_%04d.ppm
fi

echo ""

# For each style image generate a corresponding video
#for styleimage in "${styledirpath}"/*
#do
  stylename=$(basename "${styleimage}")
  stylename="${stylename%.*}"
  stylename=${stylename//[%]/x}
  th testVid.lua -contentDir videoprocessing/${inputPrefix}${filename} -style ${styleimage} -outputDir videoprocessing/${outputPrefix}${filename} -gpu -1 -contentSize ${contentSize} -styleSize ${styleSize} 

  # Generate video from output images.
  #$FFMPEG -i videoprocessing/${filename}-${stylename}/frame_%04d_stylized_${stylename}.jpg -pix_fmt yuv420p -r ${fps} videos/${filename}/${filename}-stylized-${stylename}.$extension
  $FFMPEG -y -i videoprocessing/${outputPrefix}${filename}/frame_%04d_stylized_${stylename}.jpg -pix_fmt yuv420p -r ${fps} ${absoluteOutputPath}
#done

# Also synthesize back the original video. 
# Sometimes there can be a difference of about 1 second
#$FFMPEG -y -i videoprocessing/${filename}/frame_%04d.ppm -pix_fmt yuv420p -r ${fps} videos/${filename}/${filename}-fix.$extension

  rm -rf videoprocessing/${outputPrefix}${filename} videoprocessing/${inputPrefix}${filename}
