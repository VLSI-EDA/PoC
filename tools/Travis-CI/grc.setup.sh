#! /usr/bin/env bash

# configure variables in the section below
GRC_FILE="grc_1.9-1_all.deb"
TEMP_DIR="temp"


# assemble the download URL
# --------------------------------------
GRC_URL="http://kassiopeia.juls.savba.sk/~garabik/software/grc/$GRC_FILE"

# other variables
# --------------------------------------
GITROOT=$(pwd)
POCROOT=$(pwd)
GRC_DEB="grc.deb"

# define color escape codes
RED='\e[0;31m'			# Red
GREEN='\e[1;32m'		# Green
YELLOW='\e[1;33m'		# Yellow
MAGENTA='\e[1;35m'	# Magenta
CYAN='\e[1;36m'			# Cyan
NOCOLOR='\e[0m'			# No Color


echo -e "${MAGENTA}========================================${NOCOLOR}"
echo -e "${MAGENTA}     Downloading and installing grcat   ${NOCOLOR}"
echo -e "${MAGENTA}========================================${NOCOLOR}"
echo -e "${CYAN}mkdir -p $TEMP_DIR${NOCOLOR}"
mkdir -p $TEMP_DIR && cd $TEMP_DIR

# downloading GHDL
echo -e "${CYAN}Downloading $GRC_DEB from $GRC_URL...${NOCOLOR}"
wget -q $GRC_URL -O $GRC_DEB
if [ $? -eq 0 ]; then
	echo -e "${GREEN}Download [SUCCESSFUL]${NOCOLOR}"
else
	echo 1>&2 -e "${RED}Download of $GRC_FILE [FAILED]${NOCOLOR}"
	exit 1
fi

# install grcat
if [ -e $GRC_DEB ]; then
	echo -e "${CYAN}Installing $GRC_DEB... ${NOCOLOR}"
	sudo dpkg -i $GRC_DEB
	if [ $? -eq 0 ]; then
		echo -e "${GREEN}Installation [SUCCESSFUL]${NOCOLOR}"
	else
		echo 1>&2 -e "${RED}Installation [FAILED]${NOCOLOR}"
		exit 1
	fi
fi

# remove downloaded files
rm $GRC_DEB

# test grc version
echo -e "${CYAN}Testing grc version...${NOCOLOR}"
grc --version
if [ $? -eq 0 ]; then
	echo -e "${GREEN}grc/grcat test [SUCCESSFUL]${NOCOLOR}"
	exit 0
else
	echo 1>&2 -e "${RED}grc/grcat test [FAILED]${NOCOLOR}"
	exit 1
fi
