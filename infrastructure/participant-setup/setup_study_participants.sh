#!/usr/bin/env bash
set -e

# CTF-P Study Participant Setup Script
# This script creates Coder users for study participants

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/participant_credentials"
PARTICIPANTS_FILE="${OUTPUT_DIR}/participants_info.csv"
SUMMARY_FILE="${OUTPUT_DIR}/study_summary.txt"

# Coder Configuration  
CODER_URL="${CODER_URL}"

# Study Configuration
STUDY_DOMAIN="${STUDY_DOMAIN:-study.ctf.example.com}"
DEFAULT_PARTICIPANT_COUNT=5
DEFAULT_START_INDEX=1

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

# Function to generate random password
generate_password() {
    # Generate 12-character password with letters, numbers, and symbols
    openssl rand -base64 12 | tr -d "=+/" | cut -c1-12
}

# Function to generate random email
generate_email() {
    local username=$1
    local participant_number="${username#participant}"
    echo "p${participant_number}@${STUDY_DOMAIN}"
}

# Function to activate existing dormant participants
activate_existing_participants() {
    print_header "Activating Existing Dormant Participants"
    
    # Get list of dormant participant users
    local dormant_participants=($(coder users list | grep -E '^participant[0-9]+.*dormant' | awk '{print $1}'))
    
    if [[ ${#dormant_participants[@]} -eq 0 ]]; then
        print_status "No dormant participant users found."
        return 0
    fi
    
    print_status "Found ${#dormant_participants[@]} dormant participants:"
    for participant in "${dormant_participants[@]}"; do
        echo "  - $participant"
    done
    echo ""
    
    # Activate each dormant participant
    local activated=0
    local failed=0
    
    for participant in "${dormant_participants[@]}"; do
        print_status "Activating $participant..."
        # Use echo to automatically answer 'yes' to the confirmation prompt
        if echo "yes" | coder users activate "$participant" 2>/dev/null; then
            print_status "✅ Successfully activated: $participant"
            ((activated++))
        else
            print_error "❌ Failed to activate: $participant"
            ((failed++))
        fi
    done
    
    echo ""
    print_status "Activation Summary: $activated activated, $failed failed"
    
    if [[ $activated -gt 0 ]]; then
        print_status "Run 'coder users list' to verify the changes."
    fi
}

# Function to create Coder user
create_coder_user() {
    local username=$1
    local email=$2
    local password=$3
    
    print_status "Creating Coder user: $username..."
    
    coder users create \
        --username "$username" \
        --email "$email" \
        --password "$password"
    
    if [[ $? -ne 0 ]]; then
        print_error "Failed to create Coder user: $username"
        return 1
    fi
    
    # Activate the user (in case they're created as inactive)
    print_status "Activating user: $username..."
    # Use echo to automatically answer 'yes' to the confirmation prompt
    if echo "yes" | coder users activate "$username" 2>/dev/null; then
        print_status "✅ User $username created and activated successfully"
    else
        print_warning "⚠️ User $username created but activation may have failed"
    fi
}

# Function to validate prerequisites
validate_prerequisites() {
    print_header "Validating Prerequisites"
    
    # Check required environment variables
    if [[ -z "$CODER_URL" ]]; then
        print_error "Coder URL not set. Please export CODER_URL"
        exit 1
    fi
    
    # Check required tools
    local missing_tools=()
    
    command -v coder >/dev/null 2>&1 || missing_tools+=("coder")
    command -v openssl >/dev/null 2>&1 || missing_tools+=("openssl")
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    # Test Coder connection
    if ! coder version >/dev/null 2>&1; then
        print_error "Cannot connect to Coder. Please run 'coder login' first"
        exit 1
    fi
    
    print_status "All prerequisites validated ✓"
}

# Function to setup output directory
setup_output_directory() {
    print_header "Setting Up Output Directory"
    
    mkdir -p "$OUTPUT_DIR"
    
    # Create CSV header
    echo "participant_name,email,password,coder_url,status" > "$PARTICIPANTS_FILE"
    
    print_status "Output directory created: $OUTPUT_DIR"
}

# Function to process participants
process_participants() {
    local participant_count=${1:-$DEFAULT_PARTICIPANT_COUNT}
    local start_index=${2:-$DEFAULT_START_INDEX}
    local end_index=$((start_index + participant_count - 1))
    
    print_header "Processing $participant_count Participants (participant${start_index} to participant${end_index})"
    
    # Process each participant
    for i in $(seq "$start_index" "$end_index"); do
        local participant_name="participant${i}"
        
        print_header "Processing $participant_name ($i/$participant_count)"
        
        # Generate credentials
        local email=$(generate_email "$participant_name")
        local password=$(generate_password)
        
        print_status "Generated credentials for $participant_name"
        print_status "  Email: $email"
        print_status "  Password: $password"
        
        # Create Coder user
        if create_coder_user "$participant_name" "$email" "$password"; then
            # Save to CSV
            echo "$participant_name,$email,$password,$CODER_URL,ACTIVE" >> "$PARTICIPANTS_FILE"
            print_status "✅ $participant_name setup complete"
        else
            echo "$participant_name,$email,$password,$CODER_URL,FAILED" >> "$PARTICIPANTS_FILE"
            print_warning "❌ $participant_name setup failed"
        fi
        
        echo ""
    done
}

# Function to generate summary
generate_summary() {
    print_header "Generating Study Summary"
    
    local total_participants=$(tail -n +2 "$PARTICIPANTS_FILE" | wc -l)
    local successful_users=$(tail -n +2 "$PARTICIPANTS_FILE" | grep "ACTIVE" | wc -l)
    local failed_users=$(tail -n +2 "$PARTICIPANTS_FILE" | grep "FAILED" | wc -l)
    
    cat > "$SUMMARY_FILE" <<EOF
CTF-P Study Setup Summary
========================
Generated on: $(date)
Total Participants: $total_participants
Successful Users: $successful_users
Failed Users: $failed_users

Configuration:
- Coder URL: $CODER_URL
- Study Domain: $STUDY_DOMAIN

Files Generated:
- Participant Info: $PARTICIPANTS_FILE
- Summary: $SUMMARY_FILE

Next Steps:
1. Review the participant information in the CSV file
2. Test login with a sample participant
3. Share credentials securely with participants
4. Participants can create their own workspaces using the ctf-p template
5. Set up recording sessions separately (Zoom, Discord, etc.)

Security Notes:
- Passwords are randomly generated and unique per participant
- Email addresses use the study domain: $STUDY_DOMAIN
- Users are created as active and ready to use
- Participants will need to create workspaces manually or you can create them later
EOF

    print_status "Summary generated: $SUMMARY_FILE"
}

# Function to display final instructions
display_final_instructions() {
    print_header "Setup Complete!"
    
    echo ""
    echo "📁 Files created:"
    echo "   • Participant credentials: $PARTICIPANTS_FILE"
    echo "   • Study summary: $SUMMARY_FILE"
    echo ""
    echo "📋 Next steps:"
    echo "   1. Review the CSV file for any failed setups"
    echo "   2. Test login with a sample participant"
    echo "   3. Share credentials securely with participants"
    echo "   4. Participants can create workspaces using: coder create <username>/<workspace-name> --template ctf-p"
    echo "   5. Set up recording sessions separately (Zoom, Discord, etc.)"
    echo ""
    echo "🔗 Quick commands:"
    echo "   • View CSV: cat '$PARTICIPANTS_FILE'"
    echo "   • View summary: cat '$SUMMARY_FILE'"
    echo "   • List Coder users: coder users list"
    echo ""
    echo "📝 Note: Users are created and active. Workspaces can be created as needed."
    echo ""
}

# Main function
main() {
    local participant_count=${1:-$DEFAULT_PARTICIPANT_COUNT}
    local start_index=${START_INDEX:-$DEFAULT_START_INDEX}
    local activate_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --activate)
                activate_only=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            [0-9]*)
                participant_count=$1
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    if [[ "$activate_only" == true ]]; then
        print_header "CTF-P Study Participant Activation"
        validate_prerequisites
        activate_existing_participants
        return 0
    fi
    
    print_header "CTF-P Study Participant Setup (Users Only)"
    print_status "Setting up $participant_count participants starting at participant${start_index}..."
    echo ""
    
    validate_prerequisites
    
    # Check if we should activate existing dormant users first
    local dormant_count=$(coder users list | grep -E '^participant[0-9]+.*dormant' | wc -l)
    if [[ $dormant_count -gt 0 ]]; then
        echo ""
        print_warning "Found $dormant_count dormant participant users."
        read -p "Would you like to activate them first? (y/n): " activate_dormant
        if [[ "$activate_dormant" =~ ^[Yy] ]]; then
            activate_existing_participants
            echo ""
        fi
    fi
    
    setup_output_directory
    process_participants "$participant_count" "$start_index"
    generate_summary
    display_final_instructions
}

# Help function
show_help() {
    cat <<EOF
CTF-P Study Participant Setup Script (Simplified)

Usage: $0 [OPTIONS] [NUMBER_OF_PARTICIPANTS]

This script creates:
- Coder user accounts with random credentials
- Active user status
- CSV file with all participant information

Options:
  --activate              Only activate existing dormant participants (no new users)
  --help, -h             Show this help

Environment Variables Required:
- CODER_URL: Your Coder instance URL

Optional Environment Variables:
- STUDY_DOMAIN: Email domain for participants (default: study.ctf.example.com)
- START_INDEX: Starting participant number (default: 1)

Examples:
  $0                     # Create 5 participants (default)
  $0 10                  # Create 10 participants
  START_INDEX=31 $0 20   # Create participant31 through participant50
  $0 --activate          # Only activate existing dormant participants
  $0 --help              # Show this help

Prerequisites:
- coder CLI, openssl
- Authenticated Coder session (run 'coder login' first)

Output:
- participant_credentials/participants_info.csv
- participant_credentials/study_summary.txt

Note: This script only creates users. Workspaces can be created separately as needed.
The script will automatically offer to activate any existing dormant participants before creating new ones.
EOF
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 
