#!/bin/bash

#Compiling GZDoom from source code on Fedora 38
#This is only for GZDoom 3.X and newer
#The script is taken from https://zdoom.org/wiki/Compile_GZDoom_on_Linux
#Only the necessary code for my use is written in this script.
#If somethig is malfunctioning for you. Please see the wiki page.

#Fetching dependencies
echo "Fetching dependencies"
sudo dnf install gcc-c++ make cmake SDL2-devel git zlib-devel bzip2-devel \
libjpeg-turbo-devel fluidsynth-devel game-music-emu-devel openal-soft-devel \
libmpg123-devel libsndfile-devel gtk3-devel timidity++ nasm \
mesa-libGL-devel tar SDL-devel glew-devel libwebp-devel libvpx-devel

sleep 1
echo "Making ZMusic directory, downloading the ZMusic source and creating build directory" 

#Making ZMusic directory, downloading the ZMusic source and create build directory
mkdir -pv ~/zmusic_build
cd ~/zmusic_build &&
git clone https://github.com/ZDoom/ZMusic.git zmusic &&
mkdir -pv zmusic/build

sleep 1
echo "Compiling ZMusic"

#Compiling ZMusic
cd ~/zmusic_build/zmusic/build &&
cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr &&
make

#To update ZMusic use the following commands. Remember to remove the pound signs (#)
#cd ~/zmusic_build/zmusic &&
#git pull

sleep 1
echo "Installing Zmusic"

#Installing ZMusic
cd ~/zmusic_build/zmusic/build &&
sudo make install

#Uninstalling ZMusic
#cd ~/zmusic_build/zmusic/build &&
#while IFS= read -r file || [ -n "$file" ]; do
#sudo rm -v -- "$file"
#done < install_manifest.txt

sleep 1
echo "Creating gzdoom_build directory in home directory"

#Create GZDoom_build directory
mkdir -pv ~/gzdoom_build

sleep 1
echo "Downloading and preparing the source code"

#Download and prepare the source code and create an out of tree build directory
cd ~/gzdoom_build &&
git clone https://github.com/ZDoom/gzdoom.git &&
mkdir -pv gzdoom/build
cd gzdoom
git config --local --add remote.origin.fetch +refs/tags/*:refs/tags/*
git pull

#Download FMOD (only for GZDoom 2.X or older versions)
#cd ~/gzdoom_build &&
#wget -nc http://zdoom.org/files/fmod/fmodapi44464linux.tar.gz &&
#tar -xvzf fmodapi44464linux.tar.gz -C gzdoom
#cd ~/gzdoom_build/gzdoom/build &&
#cmake .. -DNO_FMOD=ON
#cd ~/gzdoom_build/gzdoom/build &&
#cmake .. -DNO_FMOD=OFF#

#Compiling GZDoom (Development version)
sleep 1
echo "Compiling GZDoom (development version)"
a='' && [ "$(uname -m)" = x86_64 ] && a=64
c="$(lscpu -p | grep -v '#' | sort -u -t , -k 2,4 | wc -l)" ; [ "$c" -eq 0 ] && c=1
cd ~/gzdoom_build/gzdoom/build &&
rm -f output_sdl/liboutput_sdl.so &&
if [ -d ../fmodapi44464linux ]; then
f="-DFMOD_LIBRARY=../fmodapi44464linux/api/lib/libfmodex${a}-4.44.64.so \
-DFMOD_INCLUDE_DIR=../fmodapi44464linux/api/inc"; else
f='-UFMOD_LIBRARY -UFMOD_INCLUDE_DIR'; fi &&
cmake .. -DCMAKE_BUILD_TYPE=Release $f &&
make -j$c

#Compiling GZDoom (Stable version)
#sleep 1
#echo "Compiling GZDoom latest stable version"
#cd ~/gzdoom_build/gzdoom &&
#Tag="$(git tag -l | grep -v 9999 | grep -E '^g[0-9]+([.][0-9]+)*$' |
#sed 's/^g//' | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4 |
#tail -n 1 | sed 's/^/g/')" &&
#git checkout --detach refs/tags/$Tag

#Starting the game
sleep 1
echo "Starting GZDoom. Prepare for the slaughter"
./gzdoom
