#!/usr/bin/env bash
set -e

# CTF-P Study Participant Cleanup Script
# This script deletes participant users created by the setup script

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARTICIPANTS_FILE="${SCRIPT_DIR}/participant_credentials/participants_info.csv"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to delete participant users
delete_participants() {
    local method=$1
    
    if [[ "$method" == "csv" ]]; then
        delete_from_csv
    elif [[ "$method" == "pattern" ]]; then
        delete_by_pattern
    elif [[ "$method" == "list" ]]; then
        delete_from_list "$2"
    else
        print_error "Invalid deletion method"
        exit 1
    fi
}

# Delete users from CSV file
delete_from_csv() {
    print_header "Deleting Participants from CSV File"
    
    if [[ ! -f "$PARTICIPANTS_FILE" ]]; then
        print_error "CSV file not found: $PARTICIPANTS_FILE"
        print_status "Run the setup script first or use pattern-based deletion"
        exit 1
    fi
    
    print_status "Reading participants from: $PARTICIPANTS_FILE"
    
    # Skip header line and extract usernames
    local participants=($(tail -n +2 "$PARTICIPANTS_FILE" | cut -d',' -f1))
    
    if [[ ${#participants[@]} -eq 0 ]]; then
        print_warning "No participants found in CSV file"
        exit 0
    fi
    
    print_status "Found ${#participants[@]} participants to delete"
    
    for participant in "${participants[@]}"; do
        delete_user "$participant"
    done
}

# Delete users by pattern (participant*)
delete_by_pattern() {
    print_header "Deleting Participants by Pattern"
    
    print_status "Finding users matching pattern 'participant*'..."
    
    # Get list of users matching pattern - use simpler approach
    local participants=($(coder users list | grep -E '^participant[0-9]+' | awk '{print $1}' || true))
    
    if [[ ${#participants[@]} -eq 0 ]]; then
        print_warning "No participants found matching pattern 'participant*'"
        exit 0
    fi
    
    print_status "Found ${#participants[@]} participants to delete"
    
    for participant in "${participants[@]}"; do
        delete_user "$participant"
    done
}

# Delete users from provided list
delete_from_list() {
    local user_list="$1"
    print_header "Deleting Specific Participants"
    
    IFS=',' read -ra participants <<< "$user_list"
    
    print_status "Deleting ${#participants[@]} specified participants"
    
    for participant in "${participants[@]}"; do
        # Trim whitespace
        participant=$(echo "$participant" | xargs)
        delete_user "$participant"
    done
}

# Delete a single user
delete_user() {
    local username="$1"
    
    print_status "Deleting user: $username..."
    
    # First, check if user has any workspaces and delete them
    print_status "Checking for workspaces owned by $username..."
    local workspaces=($(coder list --owner "$username" 2>/dev/null | tail -n +2 | awk '{print $1}' || true))
    
    if [[ ${#workspaces[@]} -gt 0 ]]; then
        print_warning "Found ${#workspaces[@]} workspace(s) for $username. Deleting workspaces first..."
        for workspace in "${workspaces[@]}"; do
            print_status "Deleting workspace: $workspace..."
            if coder delete "$workspace" --yes 2>/dev/null || echo "yes" | coder delete "$workspace" 2>/dev/null; then
                print_status "✅ Deleted workspace: $workspace"
            else
                print_warning "⚠️ Failed to delete workspace: $workspace"
            fi
        done
    fi
    
    # Now delete the user
    if coder users delete "$username" 2>/dev/null; then
        print_status "✅ Successfully deleted: $username"
    else
        # Check if user actually exists
        if coder users show "$username" >/dev/null 2>&1; then
            print_error "❌ Failed to delete existing user: $username"
        else
            print_warning "❌ Failed to delete: $username (user does not exist)"
        fi
    fi
}

# Show confirmation prompt
confirm_deletion() {
    local method="$1"
    local count_msg="$2"
    
    print_header "DELETION CONFIRMATION"
    print_warning "This will permanently delete participant users!"
    echo ""
    
    case "$method" in
        "csv")
            print_status "Method: Delete users from CSV file"
            print_status "File: $PARTICIPANTS_FILE"
            ;;
        "pattern")
            print_status "Method: Delete all users matching 'participant*'"
            ;;
        "list")
            print_status "Method: Delete specific users from provided list"
            ;;
    esac
    
    echo ""
    read -p "Are you sure you want to proceed? (yes/no): " confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
        print_status "Deletion cancelled"
        exit 0
    fi
}

# Show help
show_help() {
    cat <<EOF
CTF-P Study Participant Cleanup Script

Usage: $0 [METHOD] [OPTIONS]

Methods:
  csv                    Delete users listed in the CSV file (default)
  pattern                Delete all users matching 'participant*'
  list "user1,user2"     Delete specific users from comma-separated list

Options:
  --force                Skip confirmation prompt
  --help, -h             Show this help

Examples:
  $0                                    # Delete from CSV (with confirmation)
  $0 csv                               # Delete from CSV (with confirmation)
  $0 pattern                           # Delete all participant* users
  $0 list "participant1,participant5"  # Delete specific users
  $0 csv --force                       # Delete from CSV without confirmation
  $0 pattern --force                   # Delete all participant* users without confirmation

Files:
  CSV file location: $PARTICIPANTS_FILE

Safety:
  - Always shows what will be deleted before proceeding
  - Requires confirmation unless --force is used
  - Handles non-existent users gracefully
EOF
}

# Main function
main() {
    local method="csv"
    local force=false
    local user_list=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            csv|pattern)
                method="$1"
                shift
                ;;
            list)
                method="list"
                shift
                if [[ $# -gt 0 ]]; then
                    user_list="$1"
                    shift
                else
                    print_error "List method requires a comma-separated list of usernames"
                    exit 1
                fi
                ;;
            --force)
                force=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_header "CTF-P Study Participant Cleanup"
    
    # Validate Coder connection
    if ! coder version >/dev/null 2>&1; then
        print_error "Cannot connect to Coder. Please run 'coder login' first"
        exit 1
    fi
    
    # Show confirmation unless forced
    if [[ "$force" != true ]]; then
        confirm_deletion "$method"
    fi
    
    # Perform deletion
    if [[ "$method" == "list" ]]; then
        delete_participants "$method" "$user_list"
    else
        delete_participants "$method"
    fi
    
    print_header "Cleanup Complete!"
    print_status "You can verify deletion with: coder users list"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 