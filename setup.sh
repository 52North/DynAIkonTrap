#! /bin/bash

echo "Installation starting. This may take a while, so please be patient."

## Start by checking the necessary Python version exists
possible_pythons=$(find /usr/bin/python* -maxdepth 1 -type f -printf "%f\n")

python_command=0
for possible_python in $possible_pythons; do
    major=$(echo $possible_python | awk -F. '/python[0-9]*\.[0-9]*$/ {print $1}')
    minor=$(echo $possible_python | awk -F. '/python[0-9]*\.[0-9]*$/ {print $2}')

    if [ "$major" == "python3" ]
    then
        if [ $minor -ge 7 ]
        then
            python_command="$major.$minor"
            break
        fi
    fi
done

if [ $python_command == 0 ]
then
    echo "Need python >= 3.7; install with:"
    echo "  apt install python3.7"
    exit -1
fi

## Install dependencies
-p "[sudo] password to install dependencies> " apt install -y libaom0 libatlas3-base libavcodec58 libavformat58 libavutil56 libbluray2 libcairo2 libchromaprint1 libcodec2-0.8.1 libcroco3 libdatrie1 libdrm2 libfontconfig1 libgdk-pixbuf2.0-0 libgfortran5 libgme0 libgraphite2-3 libgsm1 libharfbuzz0b libilmbase23 libjbig0 libmp3lame0 libmpg123-0 libogg0 libopenexr23 libopenjp2-7 libopenmpt0 libopus0 libpango-1.0-0 libpangocairo-1.0-0 libpangoft2-1.0-0 libpixman-1-0 librsvg2-2 libshine3 libsnappy1v5 libsoxr0 libspeex1 libssh-gcrypt-4 libswresample3 libswscale5 libthai0 libtheora0 libtiff5 libtwolame0 libva-drm2 libva-x11-2 libva2 libvdpau1 libvorbis0a libvorbisenc2 libvorbisfile3 libvpx5 libwavpack1 libwebp6 libwebpmux3 libx264-155 libx265-165 libxcb-render0 libxcb-shm0 libxfixes3 libxrender1 libxvidcore4 libzvbi0

## Ensure virtual environment package is installed
dpkg -s python3-venv > /dev/null 2>&1
if [ $? -ne 0 ]
then
    sudo -p "[sudo] password to install virtual environment> " apt install -y python3-venv
fi

## Create the virtual environment and activate
$python_command -m venv venv
source ./venv/bin/activate

## Ensure pip is up-to-date
python -m pip install --upgrade pip

## Install the requiremnts
pip install -r requirements.txt

if [ $? -eq 0 ]
then
    echo "Setup complete!"
else
    echo "There was a problem, check above for information"
    exit -1
fi
