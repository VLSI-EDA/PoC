#! /usr/bin/env bash

# configure variables in the section below
GHDL_BACKEND="llvm"
GHDL_VERSION="0.34dev"
RELEASE_DATE="2016-09-14"

GITHUB_SERVER="https://github.com"
GITHUB_SLUG="tgingold/ghdl"

TRAVIS_DIR="temp/Travis-CI"


# assemble the GitHub URL
# --------------------------------------
# example: 2016-05-03
GITHUB_TAGNAME="$RELEASE_DATE"

# example: ghdl-llvm-0.34dev-2016-05-03.tgz
GITHUB_RELEASE_FILE="ghdl-$GHDL_VERSION-$GHDL_BACKEND-$RELEASE_DATE.tgz"

# example: https://github.com/tgingold/ghdl/releases/download/2016.05.03/ghdl-0.34dev-llvm-2016-05-03.tar.gz
GITHUB_URL="$GITHUB_SERVER/$GITHUB_SLUG/releases/download/$GITHUB_TAGNAME/$GITHUB_RELEASE_FILE"


# other variables
# --------------------------------------
GITROOT=$(pwd)
GHDL_TARBALL="ghdl.tgz"

# define color escape codes
RED='\e[0;31m'			# Red
GREEN='\e[1;32m'		# Green
YELLOW='\e[1;33m'		# Yellow
MAGENTA='\e[1;35m'	# Magenta
CYAN='\e[1;36m'			# Cyan
NOCOLOR='\e[0m'			# No Color


echo -e "${MAGENTA}========================================${NOCOLOR}"
echo -e "${MAGENTA}     Downloading and installing GHDL    ${NOCOLOR}"
echo -e "${MAGENTA}========================================${NOCOLOR}"
echo -e "${CYAN}mkdir -p $TRAVIS_DIR${NOCOLOR}"
mkdir -p $TRAVIS_DIR
cd $TRAVIS_DIR

# downloading GHDL
echo -e "${CYAN}Downloading $GHDL_TARBALL from $GITHUB_URL...${NOCOLOR}"
wget -q $GITHUB_URL -O $GHDL_TARBALL
if [ $? -eq 0 ]; then
	echo -e "${GREEN}Download [SUCCESSFUL]${NOCOLOR}"
else
	echo 1>&2 -e "${RED}Download of $GITHUB_RELEASE_FILE [FAILED]${NOCOLOR}"
	exit 1
fi

# unpack GHDL
if [ -e $GHDL_TARBALL ]; then
	echo -e "${CYAN}Unpacking $GHDL_TARBALL... ${NOCOLOR}"
	tar -xzf $GHDL_TARBALL
	if [ $? -eq 0 ]; then
		echo -e "${GREEN}Unpack [SUCCESSFUL]${NOCOLOR}"
	else
		echo 1>&2 -e "${RED}Unpack [FAILED]${NOCOLOR}"
		exit 1
	fi
fi

# remove downloaded files
rm $GHDL_TARBALL

# gcc debugging
echo -e "${CYAN}Testing GCC version and configuration...${NOCOLOR}"
gcc -v

# test ghdl version
echo -e "${CYAN}Testing GHDL version...${NOCOLOR}"
./bin/ghdl -v
if [ $? -eq 0 ]; then
	echo -e "${GREEN}GHDL test [SUCCESSFUL]${NOCOLOR}"
else
	echo 1>&2 -e "${RED}GHDL test [FAILED]${NOCOLOR}"
	exit 1
fi
