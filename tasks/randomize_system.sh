#!/usr/bin/env bash
set -e

echo "[*] Generating random decoy files…"

# System dirs and counts
declare -A DIR_COUNTS=(
  ["/var/log"]=5
  ["/etc"]=3
  ["/tmp"]=6
)

# List all corporate CTF users (except root) & assign 3–6 files each
USERS=(jdoe asmith mjohnson lgarcia dwilson swilliams rdavis kmiller bthompson canderson tbrown)
for u in "${USERS[@]}"; do
  DIR="/home/$u"
  # random count between 3 and 6
  DIR_COUNTS["$DIR"]=$((RANDOM % 4 + 3))
done

# Possible names and extensions
EXTS=(log conf txt ini json)
NAMES=(config backup cache history notes data report)

for DIR in "${!DIR_COUNTS[@]}"; do
  COUNT=${DIR_COUNTS[$DIR]}
  mkdir -p "$DIR"
  
  # Set directory permissions
  if [[ "$DIR" =~ ^/home/ ]]; then
    chmod 700 "$DIR"  # Owner: rwx, Group: none, Others: none (private access only)
  fi
  
  for i in $(seq 1 $COUNT); do
    # build random filename
    BASE="${NAMES[RANDOM % ${#NAMES[@]}]}_$(head /dev/urandom \
      | tr -dc 'a-z0-9' | head -c6)"
    EXT="${EXTS[RANDOM % ${#EXTS[@]}]}"
    FILE="$DIR/$BASE.$EXT"

    # random size 128–2048 bytes
    SIZE=$((RANDOM % 1921 + 128))
    head /dev/urandom | tr -dc 'A-Za-z0-9 .,_+=\-' | head -c "$SIZE" > "$FILE"

    # set owner:group based on directory
    OWNER="root:root"
    PERMS="644"  # Default for system files
    
    for u in "${USERS[@]}"; do
      if [[ "$DIR" == "/home/$u" ]]; then
        # Get the user's primary group instead of using user:user
        USER_GROUP=$(id -gn "$u" 2>/dev/null || echo "$u")
        OWNER="$u:$USER_GROUP"
        PERMS="600"  # Private files: owner read/write only
        break
      fi
    done
    
    chown $OWNER "$FILE"
    chmod $PERMS "$FILE"

    # backdate timestamp up to 30 days
    DAYS_AGO=$((RANDOM % 30 + 1))
    touch -d "$DAYS_AGO days ago" "$FILE"
  done
done

echo "[+] Decoy files created for all corporate users and system dirs."