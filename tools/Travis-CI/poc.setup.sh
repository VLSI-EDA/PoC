#! /usr/bin/env bash

# define color escape codes
RED='\e[0;31m'			# Red
GREEN='\e[1;32m'		# Green
MAGENTA='\e[1;35m'	# Magenta
CYAN='\e[1;36m'			# Cyan
NOCOLOR='\e[0m'			# No Color

ERROR_COUNT=0

# -> ERROR_COUNT
# -> LastExitCode
# -> Error message
ExitIfError() {
	if [ $2 -ne 0 ]; then
		echo 1>&2 -e $3
		return $ERROR_COUNT+1
	fi
	return $ERROR_COUNT
}

echo -e "${MAGENTA}========================================${NOCOLOR}"
echo -e "${MAGENTA}             Configuring PoC            ${NOCOLOR}"
echo -e "${MAGENTA}========================================${NOCOLOR}"

echo -e "${CYAN}Copy config.private.ini into ./py directory${NOCOLOR}"
cp ./tools/Travis-CI/config.private.ini ./py
ERROR_COUNT=ExitIfError $ERROR_COUNT $? "${RED}Copying of ./tools/Travis-CI/config.private.ini [FAILED]${NOCOLOR}"

echo -e "${CYAN}Copy my_project.vhdl into ./tb/common directory${NOCOLOR}"
cp ./tools/Travis-CI/my_project.vhdl ./tb/common
ERROR_COUNT=ExitIfError $ERROR_COUNT $? "${RED}Copying of ./tools/Travis-CI/my_project.vhdl [FAILED]${NOCOLOR}"

echo -e "${CYAN}Copy modelsim.ini into ./temp/precompiled/vsim directory${NOCOLOR}"
mkdir -p ./temp/precompiled/vsim
ERROR_COUNT=ExitIfError $ERROR_COUNT $? "${RED}Creating directory ./temp/precompiled/vsim [FAILED]${NOCOLOR}"
cp ./tools/Travis-CI/modelsim.ini ./temp/precompiled/vsim
ERROR_COUNT=ExitIfError $ERROR_COUNT $? "${RED}Copying of ./tools/Travis-CI/modelsim.ini [FAILED]${NOCOLOR}"

echo -e "${CYAN}Test PoC front-end script.${NOCOLOR}"
./poc.sh
ERROR_COUNT=ExitIfError $ERROR_COUNT $? "${RED}Testing PoC front-end script [FAILED]${NOCOLOR}"

echo -e "${CYAN}Pre-compiling OSVVM for GHDL into ./temp/precompiled/ghdl/osvvm directory${NOCOLOR}"
./tools/precompile/compile-osvvm.sh --ghdl
ERROR_COUNT=ExitIfError $ERROR_COUNT $? "${RED}Pre-compiling OSVVM for GHDL [FAILED]${NOCOLOR}"

echo -e "${CYAN}Pre-compiling UVVM for GHDL into ./temp/precompiled/ghdl/uvvm directory${NOCOLOR}"
echo -e "${RED}UVVM pre-compile scripts are not yet shipped with GHDL${NOCOLOR}"
#./tools/precompile/compile-uvvm.sh --ghdl
#ExitIfError $? "${RED}Pre-compiling UVVM for GHDL [FAILED]${NOCOLOR}"

if [ $ERROR_COUNT -gt 0 ]; then
	echo -e "Configuring PoC ${RED}[FAILED]${NOCOLOR}"
	exit 1
else
	echo -e "Configuring PoC ${GREEN}[SUCESSFUL]${NOCOLOR}"
	exit 0
fi
