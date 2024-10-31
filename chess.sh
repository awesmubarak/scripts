#!/bin/bash

# Generates randomised chess visualisation training questions to improve pattern recognition
# and movement planning. The script selects a random piece and board square, then generates
# one of three puzzle types with weighted probabilities: *Directional Reach* (for bishops and
# knights, with partial occlusion), *Square Color Recognition* (identify square color), or
# *Single-Move Reach* (specify all moves from the current position).
#
# Author: Awes Mubarak <contact@awesmubarak.com>
# license: Unlicense [1] or MIT [2], 2024
#
# [1]: https://unlicense.org
# [2]: https://mit-license.org

# Enable strict error handling
set -euo pipefail
IFS=$'\n\t'

# Array of board squares
squares=(
  "a1" "a2" "a3" "a4" "a5" "a6" "a7" "a8"
  "b1" "b2" "b3" "b4" "b5" "b6" "b7" "b8"
  "c1" "c2" "c3" "c4" "c5" "c6" "c7" "c8"
  "d1" "d2" "d3" "d4" "d5" "d6" "d7" "d8"
  "e1" "e2" "e3" "e4" "e5" "e6" "e7" "e8"
  "f1" "f2" "f3" "f4" "f5" "f6" "f7" "f8"
  "g1" "g2" "g3" "g4" "g5" "g6" "g7" "g8"
  "h1" "h2" "h3" "h4" "h5" "h6" "h7" "h8"
)

# Updated Array of piece types (added "rook")
pieces=("king" "bishop" "knight" "rook")

# Function to determine square color
get_square_color() {
  local square="$1"
  local file="${square:0:1}"
  local rank="${square:1:1}"

  if [[ "$file" =~ [aceg] ]]; then
    if ((rank % 2 == 1)); then
      echo "black"
    else
      echo "white"
    fi
  else
    if ((rank % 2 == 1)); then
      echo "white"
    else
      echo "black"
    fi
  fi
}

# Function to get the initial of a piece (uppercase for standard notation)
get_piece_initial() {
  local piece="$1"
  case "$piece" in
  king) echo "K" ;;
  bishop) echo "B" ;;
  knight) echo "N" ;;
  rook) echo "R" ;;
  *) echo "?" ;; # Fallback for unexpected input
  esac
}

# Function to generate a directional reach question with partial occlusion
directional_reach_question() {
  local piece="$1"
  local square="$2"
  local piece_initial
  piece_initial=$(get_piece_initial "$piece")

  # Initialize variables
  local target_file=""
  local target_rank=""
  local max_retries=10
  local attempt=0
  local valid_move=false

  if [[ "$piece_initial" == "B" ]]; then
    # Bishop moves diagonally: change both file and rank
    # Possible directions: up-right, up-left, down-right, down-left
    local directions=("up-right" "up-left" "down-right" "down-left")

    local file="${square:0:1}"
    local rank="${square:1:1}"
    local file_index
    local rank_index

    file_index=$(echo "abcdefgh" | grep -bo "$file" | cut -d: -f1)
    rank_index=$((rank))

    # Collect all possible target squares along each diagonal direction
    local possible_targets=()

    for direction in "${directions[@]}"; do
      local current_file_index=$file_index
      local current_rank_index=$rank_index

      case "$direction" in
      "up-right")
        while ((current_file_index < 7 && current_rank_index < 8)); do
          current_file_index=$((current_file_index + 1))
          current_rank_index=$((current_rank_index + 1))
          possible_targets+=("$(echo "abcdefgh" | cut -c$((current_file_index + 1)))${current_rank_index}")
        done
        ;;
      "up-left")
        while ((current_file_index > 0 && current_rank_index < 8)); do
          current_file_index=$((current_file_index - 1))
          current_rank_index=$((current_rank_index + 1))
          possible_targets+=("$(echo "abcdefgh" | cut -c$((current_file_index + 1)))${current_rank_index}")
        done
        ;;
      "down-right")
        while ((current_file_index < 7 && current_rank_index > 1)); do
          current_file_index=$((current_file_index + 1))
          current_rank_index=$((current_rank_index - 1))
          possible_targets+=("$(echo "abcdefgh" | cut -c$((current_file_index + 1)))${current_rank_index}")
        done
        ;;
      "down-left")
        while ((current_file_index > 0 && current_rank_index > 1)); do
          current_file_index=$((current_file_index - 1))
          current_rank_index=$((current_rank_index - 1))
          possible_targets+=("$(echo "abcdefgh" | cut -c$((current_file_index + 1)))${current_rank_index}")
        done
        ;;
      esac
    done

    # Remove the starting square if present (shouldn't be, but just in case)
    possible_targets=($(echo "${possible_targets[@]}" | tr ' ' '\n' | grep -v "^${square}$"))

    # Check if there are available target squares
    if [ ${#possible_targets[@]} -eq 0 ]; then
      echo "Error: No available target squares for bishop at $square."
      exit 1
    fi

    # Select a random target square from possible_targets
    target_square="${possible_targets[$((RANDOM % ${#possible_targets[@]}))]}"
    valid_move=true

  elif [[ "$piece_initial" == "N" ]]; then
    # Knight moves in L-shape: two squares in one direction and one square perpendicular
    # Possible moves: (±2, ±1) and (±1, ±2)
    local file="${square:0:1}"
    local rank="${square:1:1}"
    local file_index
    local rank_index

    file_index=$(echo "abcdefgh" | grep -bo "$file" | cut -d: -f1)
    rank_index=$((rank))

    # Define all possible knight moves
    local move_offsets=(
      "2 1" "1 2" "-1 2" "-2 1"
      "-2 -1" "-1 -2" "1 -2" "2 -1"
    )

    # Collect all valid knight moves
    local possible_targets=()

    for move in "${move_offsets[@]}"; do
      local df="${move%% *}"
      local dr="${move##* }"
      local new_file_index=$((file_index + df))
      local new_rank=$((rank_index + dr))

      # Check if the new position is within bounds
      if ((new_file_index >= 0 && new_file_index < 8 && new_rank >= 1 && new_rank <= 8)); then
        local new_file=$(echo "abcdefgh" | cut -c$((new_file_index + 1)))
        local new_square="${new_file}${new_rank}"
        possible_targets+=("$new_square")
      fi
    done

    # Check if there are available target squares
    if [ ${#possible_targets[@]} -eq 0 ]; then
      echo "Error: No available target squares for knight at $square."
      exit 1
    fi

    # Select a random target square from possible_targets
    target_square="${possible_targets[$((RANDOM % ${#possible_targets[@]}))]}"
    valid_move=true

  else
    # Unsupported piece
    echo "Error: Directional reach not applicable for ${piece_initial}."
    exit 1
  fi

  if $valid_move; then
    # Randomly decide to obscure file or rank
    local mask_type=$((RANDOM % 2)) # 0: mask file, 1: mask rank

    if ((mask_type == 0)); then
      # Mask file
      target_square="_${target_square:1:1}"
    else
      # Mask rank
      target_square="${target_square:0:1}_"
    fi

    echo "${piece_initial}${square} -> ${target_square}"
  else
    echo "Error: Unable to generate a valid directional reach question after $max_retries attempts."
    exit 1
  fi
}

# Function to generate single-move reach question in chess notation
single_move_reach_question() {
  local piece="$1"
  local square="$2"
  local piece_initial
  piece_initial=$(get_piece_initial "$piece")
  echo "${piece_initial}${square} -> __"
}

# Function to generate square color question in chess notation
square_color_question() {
  local square="$1"
  echo "${square} colour"
}

# Function to get applicable puzzle types based on piece
get_applicable_puzzle_types() {
  local piece="$1"
  case "$piece" in
  king)
    echo "2 3" # Square Color, Single-Move Reach
    ;;
  bishop | knight)
    echo "1 2 3" # Directional Reach, Square Color, Single-Move Reach
    ;;
  rook)
    echo "2 3" # Square Color, Single-Move Reach
    ;;
  *)
    echo "2 3" # Default to Square Color and Single-Move Reach
    ;;
  esac
}

# Function to select puzzle type based on weighted probabilities
select_puzzle_type() {
  local applicable=("$@")
  local has_type1=false
  local has_type2=false
  local has_type3=false

  for p in "${applicable[@]}"; do
    if [[ "$p" == "1" ]]; then
      has_type1=true
    elif [[ "$p" == "2" ]]; then
      has_type2=true
    elif [[ "$p" == "3" ]]; then
      has_type3=true
    fi
  done

  if $has_type1; then
    # Weighted selection: Type 1 (2/3), Type 2 (1/6), Type 3 (1/6)
    local r=$((RANDOM % 6 + 1)) # 1 to 6
    if ((r <= 4)); then
      echo "1"
    elif ((r == 5)); then
      echo "2"
    else
      echo "3"
    fi
  else
    # Equal selection between Type 2 and Type 3
    # Check which types are available
    local available=()
    [[ $has_type2 == true ]] && available+=("2")
    [[ $has_type3 == true ]] && available+=("3")

    if [ ${#available[@]} -eq 0 ]; then
      echo "Error: No valid puzzle types available."
      exit 1
    elif [ ${#available[@]} -eq 1 ]; then
      echo "${available[0]}"
    else
      # Randomly select between Type 2 and Type 3
      echo "${available[$((RANDOM % 2))]}"
    fi
  fi
}

# Generate a random square and piece
random_square="${squares[$((RANDOM % ${#squares[@]}))]}"
random_piece="${pieces[$((RANDOM % ${#pieces[@]}))]}"

# Get applicable puzzle types for the selected piece
# Override IFS to space only for this read command
IFS=' ' read -ra applicable_puzzles -r <<<"$(get_applicable_puzzle_types "$random_piece")"

# Select a puzzle type based on weighted probabilities
puzzle_type="$(select_puzzle_type "${applicable_puzzles[@]}")"

# Debugging Statements (Optional)
# echo "Selected Piece: $random_piece"
# echo "Selected Square: $random_square"
# echo "Applicable Puzzles: ${applicable_puzzles[@]}"
# echo "Selected Puzzle Type: $puzzle_type"

# Display the puzzle based on the selected type
case "$puzzle_type" in
1) # Directional Reach (only for bishop and knight)
  directional_reach_question "$random_piece" "$random_square"
  ;;
2) # Square Color Recognition
  square_color_question "$random_square"
  ;;
3) # Single-Move Reach (reach ... from ...)
  single_move_reach_question "$random_piece" "$random_square"
  ;;
*)
  echo "Error: Invalid puzzle type selected."
  exit 1
  ;;
esac
