#! /bin/bash

POC_GHDL_DIR="temp/ghdl"

# define color escape codes
RED='\e[0;31m'			# Red
GREEN='\e[1;32m'		# Green
YELLOW='\e[1;33m'		# Yellow
MAGENTA='\e[1;35m'		# Magenta
CYAN='\e[1;36m'			# Cyan
NOCOLOR='\e[0m'			# No Color

GITROOT=$(pwd)
POCROOT=$(pwd)

echo -e "${MAGENTA}========================================${NOCOLOR}"
echo -e "${MAGENTA}    Running PoC testbenches with GHDL   ${NOCOLOR}"
echo -e "${MAGENTA}========================================${NOCOLOR}"

echo -e "${CYAN}mkdir -p $POC_GHDL_DIR && cd $POC_GHDL_DIR${NOCOLOR}"
mkdir -p $POC_GHDL_DIR && cd $POC_GHDL_DIR

echo -e "Starting first test: PoC.arith.prng"
$POCROOT/poc.sh -q ghdl PoC.arith.prng

