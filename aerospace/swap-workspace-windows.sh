#!/usr/bin/env bash

# Script to swap all windows between the current AeroSpace workspace and a target workspace.
#
# Usage: ./swap_workspace_windows.sh <target_workspace_name>
# Example: ./swap_workspace_windows.sh 3
#
# Dependencies:
#   - aerospace cli: Must be installed and in PATH.
#   - jq: Command-line JSON processor. Install using 'brew install jq' or package manager.

# --- Configuration ---
# If 'aerospace cli' is not directly in your PATH, uncomment and set the full path below.
# Example: AEROSPACE_CMD="/opt/homebrew/bin/aerospace cli"
AEROSPACE_CMD="aerospace"

# --- Dependency Check ---
if ! command -v jq &> /dev/null; then
    >&2 echo "Error: 'jq' command is not found. Please install jq (e.g., 'brew install jq')."
    exit 1
fi

# Check if the base aerospace command exists
AEROSPACE_BASE_CMD=$(echo "$AEROSPACE_CMD" | awk '{print $1}')
if ! command -v "$AEROSPACE_BASE_CMD" &> /dev/null; then
     >&2 echo "Error: '$AEROSPACE_CMD' command is not found. Is AeroSpace installed and CLI available in PATH?"
     exit 1
fi

# --- Input Validation ---
if [ -z "$1" ]; then
    >&2 echo "Error: No target workspace name provided."
    >&2 echo "Usage: $0 <target_workspace_name>"
    exit 1
fi
TARGET_WORKSPACE="$1"

# --- Get Current Workspace ---
CURRENT_WORKSPACE=$($AEROSPACE_CMD list-workspaces --focused)
if [ $? -ne 0 ] || [ -z "$CURRENT_WORKSPACE" ]; then
    >&2 echo "Error: Failed to get the current AeroSpace workspace."
    exit 1
fi

# --- Prevent Swapping with Self ---
if [ "$CURRENT_WORKSPACE" == "$TARGET_WORKSPACE" ]; then
    echo "Current workspace ('$CURRENT_WORKSPACE') and target ('$TARGET_WORKSPACE') are the same. No action taken."
    exit 0
fi

# --- Fetch Window IDs ---
echo "Fetching window IDs for '$CURRENT_WORKSPACE' and '$TARGET_WORKSPACE'..."

# Fetch and parse JSON, store IDs in arrays (requires Bash 4+)
mapfile -t CURRENT_WS_WINDOW_IDS < <($AEROSPACE_CMD list-windows --workspace "$CURRENT_WORKSPACE" --json | jq -r '.[] | .["window-id"]')
if [ $? -ne 0 ]; then
    >&2 echo "Error: Failed to list windows for current workspace '$CURRENT_WORKSPACE'."
    # Check if target workspace exists before proceeding with that message.
    # Simple check: try listing one window. If error, it likely doesn't exist or CLI failed.
    if ! $AEROSPACE_CMD list-windows --workspace "$TARGET_WORKSPACE" --limit 1 &> /dev/null; then
         >&2 echo "Error: Target workspace '$TARGET_WORKSPACE' may not exist or CLI failed."
         exit 1
    fi
fi

mapfile -t TARGET_WS_WINDOW_IDS < <($AEROSPACE_CMD list-windows --workspace "$TARGET_WORKSPACE" --json | jq -r '.[] | .["window-id"]')
if [ $? -ne 0 ]; then
     >&2 echo "Error: Failed to list windows for target workspace '$TARGET_WORKSPACE'. Does it exist?"
     exit 1
fi

# --- Perform the Swap ---
echo "Swapping windows..."

# 1. Move windows from CURRENT workspace to TARGET workspace
if [ ${#CURRENT_WS_WINDOW_IDS[@]} -gt 0 ]; then
    echo " -> Moving ${#CURRENT_WS_WINDOW_IDS[@]} window(s) from '$CURRENT_WORKSPACE' to '$TARGET_WORKSPACE'"
    for window_id in "${CURRENT_WS_WINDOW_IDS[@]}"; do
        $AEROSPACE_CMD move-node-to-workspace "$TARGET_WORKSPACE" --window-id "$window_id"
        if [ $? -ne 0 ]; then
             >&2 echo "Warning: Failed to move window ID $window_id to '$TARGET_WORKSPACE'."
        fi
    done
else
    echo " -> No windows to move from '$CURRENT_WORKSPACE'."
fi

# 2. Move windows from TARGET workspace to CURRENT workspace
if [ ${#TARGET_WS_WINDOW_IDS[@]} -gt 0 ]; then
    echo " -> Moving ${#TARGET_WS_WINDOW_IDS[@]} window(s) from '$TARGET_WORKSPACE' to '$CURRENT_WORKSPACE'"
    for window_id in "${TARGET_WS_WINDOW_IDS[@]}"; do
        $AEROSPACE_CMD move-node-to-workspace "$CURRENT_WORKSPACE" --window-id "$window_id"
         if [ $? -ne 0 ]; then
             >&2 echo "Warning: Failed to move window ID $window_id to '$CURRENT_WORKSPACE'."
        fi
    done
else
     echo " -> No windows to move from '$TARGET_WORKSPACE'."
fi

echo "Window swap between '$CURRENT_WORKSPACE' and '$TARGET_WORKSPACE' complete."
exit 0
