#!/usr/bin/env bash

set -u

# Characters to train (numbers + DVP symbol row)
CHARS=(
  "0" "1" "2" "3" "4" "5" "6" "7" "8" "9"
  "!" "@" "#" "$" "%" "^" "&" "*" "(" ")"
  "[" "]" "{" "}" "<" ">"
  "+" "-" "=" "_" "/" "\\" "|" ":" ";" "?"
)

# Weight table
declare -A WEIGHT
for c in "${CHARS[@]}"; do
  WEIGHT["$c"]=1
done

MISS_BOOST=3
HIT_BOOST=1

# Decay settings
DECAY_INTERVAL=4   # apply decay every 20 rounds
rounds=0

check_gum() {
  if ! command -v gum >/dev/null 2>&1; then
    echo "gum is required but not installed." >&2
    exit 1
  fi
}

pick_char() {
  local total=0
  for c in "${CHARS[@]}"; do
    total=$(( total + WEIGHT["$c"] ))
  done

  local r=$(( RANDOM % total ))
  local sum=0

  for c in "${CHARS[@]}"; do
    sum=$(( sum + WEIGHT["$c"] ))
    if (( r < sum )); then
      echo "$c"
      return
    fi
  done

  echo "${CHARS[0]}"
}

apply_decay() {
  for c in "${CHARS[@]}"; do
    local w=${WEIGHT["$c"]}
    if (( w > 1 )); then
      WEIGHT["$c"]=$(( w - 1 ))
    fi
  done
}

show_stats() {
  local msg="Weights: "
  for c in "${CHARS[@]}"; do
    msg+="$c=${WEIGHT["$c"]}  "
  done
  gum style --foreground="240" --italic "$msg"
}

check_gum

gum style --border="rounded" --padding="1 2" --bold --foreground="212" \
  "DVP Typing Trainer" \
  "Numbers + symbol row" \
  "Adaptive with simple decay (every $DECAY_INTERVAL rounds)."

sleep 1

correct=0
wrong=0

while true; do
  rounds=$((rounds + 1))
  char=$(pick_char)

  gum style --border="double" --padding="1 4" --bold --foreground="51" \
    "Type:  $char"

  read -r -n1 input
  echo

  if [[ "$input" == "$char" ]]; then
    correct=$((correct + 1))
    WEIGHT["$char"]=$(( WEIGHT["$char"] + HIT_BOOST ))
    gum style --foreground="82" --bold "✓ Correct"
  else
    wrong=$((wrong + 1))
    WEIGHT["$char"]=$(( WEIGHT["$char"] + MISS_BOOST ))
    gum style --foreground="196" --bold "✗ Wrong" \
      "You typed: '$input'  Expected: '$char'"
  fi

  # Apply decay every DECAY_INTERVAL rounds
  if (( rounds % DECAY_INTERVAL == 0 )); then
    apply_decay
    gum style --foreground="244" --italic "Decay applied."
  fi

  gum style --foreground="214" --bold \
    "Score:  correct=$correct  wrong=$wrong"

  show_stats

  sleep 0.4
done
