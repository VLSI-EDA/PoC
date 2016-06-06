#! /bin/bash

# define color escape codes
RED='\e[0;31m'			# Red
GREEN='\e[1;32m'		# Green
MAGENTA='\e[1;35m'	# Magenta
CYAN='\e[1;36m'			# Cyan
NOCOLOR='\e[0m'			# No Color

echo -e "${MAGENTA}========================================${NOCOLOR}"
echo -e "${MAGENTA}             Configuring PoC            ${NOCOLOR}"
echo -e "${MAGENTA}========================================${NOCOLOR}"

echo -e "${CYAN}Copy config.private.ini into ./py directory${NOCOLOR}"
cp ./tools/Travis-CI/config.private.ini ./py
if [ $? -ne 0 ]; then
	echo 1>&2 -e "${RED}Copy of ./tools/Travis-CI/config.private.ini [FAILED]${NOCOLOR}"
	exit 1
fi

echo -e "${CYAN}Copy my_project.vhdl into ./tb/common directory${NOCOLOR}"
cp ./tools/Travis-CI/my_project.vhdl ./tb/common
if [ $? -ne 0 ]; then
	echo 1>&2 -e "${RED}Copy of ./tools/Travis-CI/my_project.vhdl [FAILED]${NOCOLOR}"
	exit 1
fi

echo -e "${CYAN}Pre-compiling OSVVM with GHDL into ./temp/precompiled/ghdl/osvvm directory${NOCOLOR}"
pwd
cd ./temp/precompiled
../../../tools/precompile/compile-osvvm.sh --ghdl

ls -Ahl ./temp/precompiled
ls -Ahl ./temp/precompiled/osvvm
ls -Ahl ./temp/precompiled/osvvm/v08
