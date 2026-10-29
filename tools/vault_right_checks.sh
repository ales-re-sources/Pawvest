#!/usr/bin/env bash
# Checks of the vault's right half, the ledge tower (docs/STAGES.md -> "Vault tower"), all in parallel; one line per check.
# route: a baseline player (Triple Jump + Long Dash) gets from the doorway to the key and lands on the slot floor left of
#        the bottom spike.
# plugK: with the gap of ledge K filled, a maxed player reaches no key: every lane is on every way to the key.
# exit:  with the hatch open (the key held), from the slot floor to the lock zone by the exit.
# A line ending in "state cap hit" is not a result: raise MAX_STATES.
cd "$(dirname "$0")/.." || exit 1
out=$(mktemp -d)
export MAX_STATES=${MAX_STATES:-15000000}
run() { # name env profile u h target...
	local name=$1 envs=$2 prof=$3 u=$4 h=$5
	shift 5
	( env RIGHT=1 $envs python tools/vault_reach.py "$prof" "$u" "$h" > "$out/$name.txt" 2>&1
	  res=""
	  for t in "$@"; do res="$res $(grep "  $t:" "$out/$name.txt" | sed 's/^ *//' | cut -c1-90);"; done
	  cap=$(grep -c "state cap hit" "$out/$name.txt")
	  states=$(grep -o "states=[0-9]*" "$out/$name.txt")
	  echo "$name ($envs $prof from $u,$h, $states):$res$([ "$cap" != 0 ] && echo " state cap hit")" ) &
}
run route "" base 159 0 Key_Green SlotFloor
for k in 1 2 3 4; do run "plug$k" "PLUG=$k" max 159 0 Key_Green; done
run exit "HATCH=open" base 163.0 41 LockZone_Green
wait
