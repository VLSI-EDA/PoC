#! /usr/bin/env bash

# configure variables in the section below
GRC_VERSION="$(curl -s https://api.github.com/repos/garabik/grc/releases/latest | grep "tag_name" | cut -d : -f 2 | tr -d \, | tr -d \" | cut -c3-)"
GRC_FILE="grc_${GRC_VERSION}-1_all.deb"
#GRC_FILE="grc_1.11.3-1_all.deb"
#GRC_FILE="grc_1.9-1_all.deb"
TEMP_DIR="temp"


# assemble the download URL
# --------------------------------------
GRC_URL="https://korpus.sk/~garabik/software/grc/$GRC_FILE"
#GRC_URL="http://kassiopeia.juls.savba.sk/~garabik/software/grc/$GRC_FILE"
# other variables
# --------------------------------------
GITROOT=$(pwd)
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

# downloading GRC
echo -e "${CYAN}Downloading $GRC_FILE from $GRC_URL...${NOCOLOR}"
curl -L $GRC_URL -o $GRC_DEB
if [ $? -eq 0 ]; then
	echo -e "${GREEN}Download [SUCCESSFUL]${NOCOLOR}"
else
	echo 1>&2 -e "${RED}Download of $GRC_FILE [FAILED]${NOCOLOR}"
	exit 1
fi

# install grcat
if [ -e $GRC_DEB ]; then
	echo -e "${CYAN}Installing $GRC_DEB... ${NOCOLOR}"
	FORCE="$([ "$(command -v python3)" != "/usr/bin/python3" ] && echo "--ignore-depends=python3:any")"
	dpkg $FORCE -i $GRC_DEB
	if [ $? -eq 0 ]; then
		echo -e "${GREEN}Installation [SUCCESSFUL]${NOCOLOR}"
	else
		echo 1>&2 -e "${RED}Installation [FAILED]${NOCOLOR}"
		exit 0
		#exit 1
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
