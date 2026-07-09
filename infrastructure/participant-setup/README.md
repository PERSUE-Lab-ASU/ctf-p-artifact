# CTF-P Study Participant Setup Scripts

This directory contains scripts to automate the setup and cleanup of CTF-P study participants, including:
- Generating random Coder user credentials  
- Creating and activating Coder users
- Outputting all participant information in CSV format
- Cleaning up participants after the study

**Note:** This simplified version only creates users. Workspaces can be created separately as needed.

## 🚀 Quick Start

```bash
# 1. Copy and configure environment file
cp env.example .env
# Edit .env with your actual credentials

# 2. Load environment variables
source .env

# 3. Login to Coder
coder login --url $CODER_URL

# 4. Create participants
chmod +x setup_study_participants.sh
./setup_study_participants.sh 10  # Creates 10 participants

# 5. Clean up when done (optional)
chmod +x cleanup_participants.sh
./cleanup_participants.sh  # Deletes all participants from CSV
```

## 📋 Prerequisites

### Required Tools
- `coder` - Coder CLI tool
- `openssl` - For random password generation
- `jq` - For JSON parsing (cleanup script only)

Install missing tools:
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y openssl jq

# macOS
brew install openssl jq

# Install Coder CLI
curl -fsSL https://coder.com/install.sh | sh
```

### Required Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `CODER_URL` | Your Coder instance URL | ✅ Yes |

### Optional Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `STUDY_DOMAIN` | Email domain for participants | `study.ctf.example.com` |

## 🔧 Setup Instructions

### 1. Coder Setup

1. Ensure your Coder instance is running
2. Create the `ctf-p` template (see main documentation)
3. Login to Coder CLI:
   ```bash
   coder login --url https://your-coder-instance.com
   ```

### 2. Environment Configuration

Use the provided template file:
```bash
# Copy the example file
cp env.example .env

# Edit with your actual values
nano .env  # or use your preferred editor

# Load environment variables
source .env
```

The `env.example` file contains all required and optional variables with documentation. Key variables:

**Required:**
- `CODER_URL` - Your Coder instance URL

**Optional:**
- `STUDY_DOMAIN` - Email domain for participants (default: study.ctf.example.com)

## 📖 Usage

### Creating Participants

```bash
# Create 5 participants (default)
./setup_study_participants.sh

# Create specific number of participants
./setup_study_participants.sh 15

# Show help
./setup_study_participants.sh --help
```

### Cleaning Up Participants

```bash
# Delete all participants from CSV file (recommended)
./cleanup_participants.sh

# Delete all users matching 'participant*' pattern
./cleanup_participants.sh pattern

# Delete specific participants
./cleanup_participants.sh list "participant1,participant3,participant5"

# Force deletion without confirmation
./cleanup_participants.sh --force

# Show cleanup help
./cleanup_participants.sh --help
```

**Note:** The cleanup script automatically detects and deletes any workspaces owned by participants before deleting the user accounts. This ensures clean removal even if participants have created workspaces.

## 📊 Output Files

The setup script creates a `participant_credentials/` directory with:

### `participants_info.csv`
Contains all participant information:
```csv
participant_name,email,password,coder_url,status
participant1,participant1_a1b2c3@study.ctf.example.com,xK9mP2nQ8vR1,https://coder.example.com,ACTIVE
participant2,participant2_d4e5f6@study.ctf.example.com,yL0nQ3oR9wS2,https://coder.example.com,ACTIVE
```

### `study_summary.txt`
Contains setup summary and statistics:
```
CTF-P Study Setup Summary
========================
Generated on: Mon Jan 15 10:30:45 PST 2024
Total Participants: 10
Successful Users: 10
Failed Users: 0

Configuration:
- Coder URL: https://coder.example.com
- Study Domain: study.ctf.example.com
```

## 🔐 Security Features

### Random Credential Generation
- **Passwords**: 12-character random strings using `openssl rand`
- **Emails**: Unique with random suffixes (e.g., `participant1_a1b2c3@study.ctf.example.com`)
- **No credential reuse** across participants

### Coder Security
- **Isolated user accounts** per participant
- **Active user status** for immediate access
- **Secure credential storage** in CSV format

## 🏗️ Workspace Creation

Since this script only creates users, workspaces need to be created separately:

### Option 1: Participants Create Their Own
Provide participants with instructions:
```bash
# After logging in to Coder
coder create <username>/<workspace-name> --template ctf-p

# Example:
coder create participant1/participant1-ctf --template ctf-p
```

### Option 2: Batch Create Workspaces
You can create a simple script to create workspaces for all participants:
```bash
#!/bin/bash
# Read participants from CSV and create workspaces
tail -n +2 participant_credentials/participants_info.csv | while IFS=',' read -r username email password coder_url status; do
    if [[ "$status" == "ACTIVE" ]]; then
        echo "Creating workspace for $username..."
        coder create "$username/$username-ctf" --template ctf-p
    fi
done
```

## 🛠️ Troubleshooting

### Common Issues

#### "Cannot connect to Coder"
```bash
# Re-authenticate
coder login --url $CODER_URL

# Check connection
coder version
coder templates list
```

#### "Template 'ctf-p' not found"
```bash
# List available templates
coder templates list

# Create the template (see main documentation)
cd ~/ctf-p-template/ctf-p
coder templates create
```

#### User Creation Prompts
If the script prompts for confirmation during user creation/activation, ensure you're using the latest version with `--yes` flags.

### Partial Failures
Both scripts handle partial failures gracefully:
- **User creation fails**: Marked as "FAILED" in CSV
- **User deletion fails**: Shows warning but continues with other users

Review the CSV file for any "FAILED" entries and manually retry if needed.

## 📝 Manual Operations

### List Current Users
```bash
# List all users
coder users list

# List only participants
coder users list | grep participant
```

### Manual User Operations
```bash
# Create user manually
coder users create --username participant1 --email participant1@study.ctf.example.com --password "password123"

# Activate user
coder users activate participant1 --yes

# Delete user
coder users delete participant1 --yes

# Show user details
coder users show participant1
```

## 🔄 Workflow Integration

### Pre-Study Checklist
1. ✅ Run the setup script
2. ✅ Review CSV for any failures
3. ✅ Test login with 1-2 sample participants
4. ✅ Set up recording sessions separately
5. ✅ Confirm CTF environment is accessible
6. ✅ Share credentials securely with participants

### During Study
- Monitor Coder users: `coder users list`
- Create workspaces as needed
- Manage recording sessions through your chosen platform
- Watch for any technical issues

### Post-Study
- Export workspace logs if needed
- Run cleanup script to remove participants
- Download recordings from your platform
- Analyze participant data

## 📁 File Structure

```
participant-setup/
├── setup_study_participants.sh    # Main setup script
├── cleanup_participants.sh        # Cleanup script
├── env.example                    # Environment template
├── README.md                      # This file
└── participant_credentials/       # Generated by setup script
    ├── participants_info.csv      # Participant credentials
    └── study_summary.txt          # Setup summary
```

## 🤝 Contributing

To improve these scripts:
1. Test with your specific Coder setup
2. Add error handling for edge cases
3. Enhance output formatting
4. Add additional validation checks

## 📞 Support

For platform-specific issues, see the [Coder Documentation](https://coder.com/docs).
