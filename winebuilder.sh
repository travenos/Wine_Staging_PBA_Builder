#!/bin/bash

#Constants
WINE_SOURCE=git://source.winehq.org/git/wine.git
STAGING_SOURCE=git://github.com/wine-staging/wine-staging
PBA_SOURCE=git://github.com/acomminos/wine-pba

WORK_DIR_ARG=-d
OUTPUT_DIR_ARG=-o
THREADS_ARG=-j
CLEAR_ARG=-c
HELP_ARG=-h

HELP_STRING="Tool for downloading, patching and building newest Wine with Staging and PBA patches.\n
Arguments:\n
$WORK_DIR_ARG - specify working directory\n
$OUTPUT_DIR_ARG - scecify output directory\n
$THREADS_ARG - scecify number of threads used for building Wine\n
$CLEAR_ARG - clear temporary files after successfull installation\n
$HELP_ARG - print this help text"

OUTPUT_DIR_NAME=wineoutput
WINE_DIR_NAME=$(basename "$WINE_SOURCE")
WINE_DIR_NAME=${WINE_DIR_NAME%.*}
STAGING_DIR_NAME=$(basename "$STAGING_SOURCE")
STAGING_DIR_NAME=${STAGING_DIR_NAME%.*}
PBA_DIR_NAME=$(basename "$PBA_SOURCE")
PBA_DIR_NAME=${PBA_DIR_NAME%.*}

CLEAR=0
THREADS_NUMBER=8

# Printing errors
echoerror() { >&2 echo $@; }

SCRIPT=$(readlink -f "$BASH_SOURCE")
WORKSPACE=$(dirname "$SCRIPT")

# Checking arguments
for (( i=1; i<=$#; i++ ))
do
    if [[ ${!i} = $WORK_DIR_ARG ]]
    then
        i=$(($i+1))
        WORKSPACE=$(readlink -f "${!i}")
    elif [[ ${!i} = $OUTPUT_DIR_ARG ]]
    then
        i=$(($i+1))
        WINEOUT=$(readlink -f "${!i}")
    elif [[ ${!i} = $THREADS_ARG ]]
    then
        i=$(($i+1))
        THREADS_NUMBER="${!i}"   
        if [[ -z "${THREADS_NUMBER##*[!0-9]*}" || $THREADS_NUMBER = 0 ]]
        then
            echoerror "Invalid number of threads ${!i}"
            exit 1
        fi
    elif [[ ${!i} = $CLEAR_ARG ]]
    then
        CLEAR=1
    elif [[ ${!i} = $HELP_ARG ]]
    then
        echo -e $HELP_STRING 
        exit 0
    else
        echoerror "Invalid argument ${!i}"
        exit 1
    fi
done

if [[ -z "$WINEOUT" ]]
then
    WINEOUT="$WORKSPACE/$OUTPUT_DIR_NAME"
fi

mkdir -p "$WORKSPACE" || exit
cd "$WORKSPACE"

# Update sources from git repository
download_source()
{
    SOURCE=$1
    DIR=$(basename "$SOURCE")
    DIR=${DIR%.*}
    cd "$DIR" 2> /dev/null 
    if [[ $? = 0 ]]
    then
        git clean -fd  2> /dev/null 
        if [[  $? != 0  ]]
        then
            cd ..
            rm -rf "$DIR" || exit
            git clone "$SOURCE" || exit
        else
            git checkout .
            git pull
            cd ..
        fi
    else
        git clone "$SOURCE" || exit
    fi
}

#Getting newest Wine
download_source "$WINE_SOURCE"
download_source "$STAGING_SOURCE"
download_source "$PBA_SOURCE"

#Applying Staging patches
bash $STAGING_DIR_NAME/patches/patchinstall.sh DESTDIR=$WINE_DIR_NAME --all || exit
cd $WINE_DIR_NAME

#Applying PBA patches
for f in ../$PBA_DIR_NAME/patches/*
do
    patch -p1 < "$f"
done

#Making directories for builds
mkdir build32 build64

#Building for x64
cd build64
../configure --enable-win64 --with-opengl --with-vulkan  --prefix="$WINEOUT" || exit
make -j$THREADS_NUMBER && make install -j$THREADS_NUMBER  || exit

cd ../build32
../configure --with-wine64=../build64 --with-opengl --with-vulkan --prefix="$WINEOUT" || exit
make -j$THREADS_NUMBER && make install -j$THREADS_NUMBER  || exit

#Removing source codes
if [[ $CLEAR = 1 ]]
then
    echo "Removing source codes"
    cd ..
    rm -rf $WINE_DIR_NAME $STAGING_DIR_NAME $PBA_DIR_NAME
fi

echo "Patched Wine has been successfully installed to $WINEOUT"
