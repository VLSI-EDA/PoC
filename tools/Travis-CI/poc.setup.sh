#! /usr/bin/env bash

# define color escape codes
RED='\e[0;31m'			# Red
GREEN='\e[1;32m'		# Green
MAGENTA='\e[1;35m'	# Magenta
CYAN='\e[1;36m'			# Cyan
NOCOLOR='\e[0m'			# No Color


# -> LastExitCode
# -> Error message
ExitIfError() {
	if [ $1 -ne 0 ]; then
		echo 1>&2 -e $2
		exit 1
	fi
}

echo -e "${MAGENTA}========================================${NOCOLOR}"
echo -e "${MAGENTA}             Configuring PoC            ${NOCOLOR}"
echo -e "${MAGENTA}========================================${NOCOLOR}"

echo -e "${CYAN}Copy config.private.ini into ./py directory${NOCOLOR}"
cp ./tools/Travis-CI/config.private.ini ./py
ExitIfError $? "${RED}Copying of ./tools/Travis-CI/config.private.ini [FAILED]${NOCOLOR}"

echo -e "${CYAN}Copy my_project.vhdl into ./tb/common directory${NOCOLOR}"
cp ./tools/Travis-CI/my_project.vhdl ./tb/common
ExitIfError $? "${RED}Copying of ./tools/Travis-CI/my_project.vhdl [FAILED]${NOCOLOR}"

echo -e "${CYAN}Copy modelsim.ini into ./temp/precompiled/vsim directory${NOCOLOR}"
mkdir -p ./temp/precompiled/vsim
ExitIfError $? "${RED}Creating directory ./temp/precompiled/vsim [FAILED]${NOCOLOR}"
cp ./tools/Travis-CI/modelsim.ini ./temp/precompiled/vsim
ExitIfError $? "${RED}Copying of ./tools/Travis-CI/modelsim.ini [FAILED]${NOCOLOR}"

echo -e "${CYAN}Test PoC front-end script.${NOCOLOR}"
./poc.sh
ExitIfError $? "${RED}Testing PoC front-end script [FAILED]${NOCOLOR}"

echo -e "${CYAN}Pre-compiling OSVVM for GHDL into ./temp/precompiled/ghdl/osvvm directory${NOCOLOR}"
./tools/precompile/compile-osvvm.sh --ghdl
ExitIfError $? "${RED}Pre-compiling OSVVM for GHDL [FAILED]${NOCOLOR}"

echo -e "${CYAN}Pre-compiling UVVM for GHDL into ./temp/precompiled/ghdl/uvvm directory${NOCOLOR}"
echo -e "UVVM pre-compile scripts are not yet shipped with GHDL. ${RED}[SKIPPING]${NOCOLOR}"
#./tools/precompile/compile-uvvm.sh --ghdl
#ExitIfError $? "${RED}Pre-compiling UVVM for GHDL [FAILED]${NOCOLOR}"


echo -e "Configuring PoC ${GREEN}[FINISHED]${NOCOLOR}"
exit 0
