#! /usr/bin/env bash

# define color escape codes
RED='\e[0;31m'			# Red
GREEN='\e[1;32m'		# Green
YELLOW='\e[1;33m'		# Yellow
MAGENTA='\e[1;35m'		# Magenta
CYAN='\e[1;36m'			# Cyan
NOCOLOR='\e[0m'			# No Color

POCROOT=$(pwd)

TRAVIS_DIR=$POCROOT/tools/Travis-CI

# -> LastExitCode
# -> Error message
ExitIfError() {
	if [ $1 -ne 0 ]; then
		echo 1>&2 -e $2
		# Cleanup and exit
		exec 1>&-
		wait # for output filter
		exit 1
	fi
}
# -> LastExitCode
# -> Error message
ExitIfNoError() {
	if [ $1 -eq 0 ]; then
		echo 1>&2 -e $2
		# Cleanup and exit
		exec 1>&-
		wait # for output filter
		exit 1
	fi
}



echo -e "${MAGENTA}========================================${NOCOLOR}"
echo -e "${MAGENTA}    Running PoC in dryrun mode          ${NOCOLOR}"
echo -e "${MAGENTA}========================================${NOCOLOR}"

# Check if output filter grcat is available and install it
if grcat $TRAVIS_DIR/poc.run.grcrules</dev/null 2>/dev/null; then
	echo -e "Pipe STDOUT through grcat ..."
	{ coproc grcat $TRAVIS_DIR/poc.run.grcrules 1>&3; } 3>&1
  exec 1>&${COPROC[1]}-
fi

echo -e "Testing Active-HDL (1/5)..."
$POCROOT/poc.sh --dryrun asim "PoC.arith.prng"
ExitIfNoError $? "${RED}Testing Active-HDL [FAILED]${NOCOLOR}"

echo -e "Testing Riviera-PRO (2/5)..."
$POCROOT/poc.sh --dryrun rpro "PoC.arith.prng"
ExitIfError $? "${RED}Testing Riviera-PRO [FAILED]${NOCOLOR}"

echo -e "Testing GHDL (3/6)..."
$POCROOT/poc.sh --dryrun ghdl "PoC.arith.prng"
ExitIfError $? "${RED}Testing ModelSim [FAILED]${NOCOLOR}"

echo -e "Testing ModelSim (4/6)..."
$POCROOT/poc.sh --dryrun vsim "PoC.arith.prng"
ExitIfError $? "${RED}Testing ModelSim [FAILED]${NOCOLOR}"

echo -e "Testing ISE Simulator (5/6)..."
$POCROOT/poc.sh --dryrun isim "PoC.arith.prng"
ExitIfError $? "${RED}Testing ISE Simulator [FAILED]${NOCOLOR}"

echo -e "Testing Vivado Simulator (6/6)..."
$POCROOT/poc.sh --dryrun xsim "PoC.arith.prng"
ExitIfError $? "${RED}Testing Vivado Simulator [FAILED]${NOCOLOR}"

$ret=0

# Cleanup and exit
exec 1>&-
wait # for output filter
exit $ret
