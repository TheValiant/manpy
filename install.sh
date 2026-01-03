#!/bin/bash

# Configuration
GITHUB_URL="https://raw.githubusercontent.com/TheValiant/manpy/main/pyhelp.py"
DEST_PATH="$HOME/pyhelp.py"
MARKER_START="# --- manpy configuration start ---"
MARKER_END="# --- manpy configuration end ---"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting manpy installation...${NC}"

# ------------------------------------------------------------------
# 1. Download the Python script
# ------------------------------------------------------------------
echo -e "Downloading pyhelp.py to ${DEST_PATH}..."

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$GITHUB_URL" -o "$DEST_PATH"
elif command -v wget >/dev/null 2>&1; then
    wget -qO "$DEST_PATH" "$GITHUB_URL"
else
    echo -e "${RED}Error: Neither curl nor wget found. Cannot download file.${NC}"
    exit 1
fi

if [ ! -f "$DEST_PATH" ]; then
    echo -e "${RED}Download failed. Please check the URL.${NC}"
    exit 1
fi

echo -e "${GREEN}Download complete.${NC}"

# ------------------------------------------------------------------
# 2. Check for Python dependencies (Rich)
# ------------------------------------------------------------------
echo "Checking for 'rich' library..."
if python3 -c "import rich" 2>/dev/null; then
    echo -e "${GREEN}'rich' is already installed.${NC}"
else
    echo -e "${YELLOW}'rich' not found. Installing via pip...${NC}"
    python3 -m pip install --user rich
    if [ $? -ne 0 ]; then
         echo -e "${RED}Failed to install 'rich'. Please run 'pip install rich' manually.${NC}"
    fi
fi

# ------------------------------------------------------------------
# 3. Define the function block to append
# ------------------------------------------------------------------
# We use single quotes 'EOF' to prevent $ variable expansion during script execution
read -r -d '' RC_CONTENT << 'EOF'

# --- manpy configuration start ---
manpy() {
    # Capture the output and the exit code
    local output
    local exit_code

    # 1. Run script forcing color. 2>&1 captures both stdout and stderr.
    # Note: Using absolute path to ensuring no $PATH issues
    output=$(FORCE_COLOR=1 ~/pyhelp.py "$1" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        # Success: Pipe to less
        echo "$output" | less -R
    else
        # Failure: Print directly to terminal (keeping colors)
        echo "$output"
    fi
}
# --- manpy configuration end ---
EOF

# ------------------------------------------------------------------
# 4. Helper function to update RC files safely
# ------------------------------------------------------------------
update_rc_file() {
    local rc_file="$1"

    # Only process if file exists
    if [ -f "$rc_file" ]; then
        echo -e "Updating $rc_file..."

        # 1. Check if Function already exists (using markers)
        if grep -Fq "$MARKER_START" "$rc_file"; then
            echo -e "${YELLOW}  -> configuration already found in $rc_file. Skipping append.${NC}"
        else
            echo "$RC_CONTENT" >> "$rc_file"
            echo -e "${GREEN}  -> Appended manpy function.${NC}"
        fi

        # 2. Check for conflicting aliases (e.g., alias manpy="...")
        # We look for lines starting with 'alias manpy=' and comment them out to prevent conflicts.
        if grep -E "^alias manpy=" "$rc_file" > /dev/null; then
            echo -e "${YELLOW}  -> Found old 'alias manpy' in $rc_file. Commenting it out...${NC}"
            # Backup created automatically by sed depending on OS, or verify standard sed usage
            # This works on standard GNU sed (Linux) and BSD sed (Mac/Zsh) may need syntax adjustment.
            # We assume standard sed or fallback to manual warning.
            
            # Using portable sed trick for in-place editing
            sed -i.bak 's/^alias manpy=/# DISABLED BY INSTALLER: alias manpy=/g' "$rc_file" \
            && rm "${rc_file}.bak"
        fi
    else
        echo "  -> $rc_file not found. Skipping."
    fi
}

# ------------------------------------------------------------------
# 5. Run updates
# ------------------------------------------------------------------
update_rc_file "$HOME/.bashrc"
update_rc_file "$HOME/.zshrc"

echo --------------------------------------------------
echo -e "${GREEN}Installation complete!${NC}"
echo "Restart your terminal or run the following to apply changes:"
echo -e "${YELLOW}source ~/.zshrc${NC}  (or ~/.bashrc)"
