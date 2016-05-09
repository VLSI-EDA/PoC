#! /bin/bash

POC_GHDL_DIR="temp/ghdl"

# define color escape codes
RED='\e[0;31m'			# Red
GREEN='\e[1;32m'		# Green
YELLOW='\e[1;33m'		# Yellow
MAGENTA='\e[1;35m'		# Magenta
CYAN='\e[1;36m'			# Cyan
NOCOLOR='\e[0m'			# No Color

POCROOT=$(pwd)

TRAVIS_DIR=$POCROOT/tools/Travis-CI

echo -e "${MAGENTA}========================================${NOCOLOR}"
echo -e "${MAGENTA}    Running PoC testbenches with GHDL   ${NOCOLOR}"
echo -e "${MAGENTA}========================================${NOCOLOR}"

echo -e "${CYAN}mkdir -p $POC_GHDL_DIR && cd $POC_GHDL_DIR${NOCOLOR}"
mkdir -p $POC_GHDL_DIR && cd $POC_GHDL_DIR

# Check if output filter grcat is available and install it
if grcat $TRAVIS_DIR/poc.run.grcrules</dev/null 2>/dev/null; then
	echo -e "Pipe STDOUT through grcat ..."
	{ coproc grcat $TRAVIS_DIR/poc.run.grcrules 1>&3; } 3>&1
  exec 1>&${COPROC[1]}-
fi

echo -e "Running all testbenches..."
$POCROOT/poc.sh -q ghdl $1
ret=$?

# Cleanup and exit
exec 1>&-
wait # for output filter
exit $ret
