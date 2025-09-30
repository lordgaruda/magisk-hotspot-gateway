#!/bin/bash

# Script to create a flashable Magisk module ZIP

MODULE_NAME="hotspot-gateway"
VERSION=$(grep "version=" module.prop | cut -d'=' -f2)
ZIP_NAME="${MODULE_NAME}-v${VERSION}.zip"

echo "Creating flashable ZIP: $ZIP_NAME"

# Create temporary directory structure
TEMP_DIR=$(mktemp -d)
MODULE_DIR="$TEMP_DIR/META-INF/com/google/android"

# Create META-INF structure for flashable ZIP
mkdir -p "$MODULE_DIR"

# Create update-binary (Magisk module installer)
cat > "$MODULE_DIR/update-binary" << 'EOF'
#!/sbin/sh

#################
# Initialization
#################

umask 022

# echo before loading util_functions
ui_print() { echo "$1"; }

require_new_magisk() {
  ui_print "*******************************"
  ui_print " Please install Magisk v20.4+! "
  ui_print "*******************************"
  exit 1
}

#########################
# Load util_functions.sh
#########################

OUTFD=$2
ZIPFILE=$3

mount /data 2>/dev/null

[ -f /data/adb/magisk/util_functions.sh ] || require_new_magisk
. /data/adb/magisk/util_functions.sh
[ $MAGISK_VER_CODE -lt 20400 ] && require_new_magisk

install_module
exit 0
EOF

# Create updater-script (required but can be empty for Magisk)
cat > "$MODULE_DIR/updater-script" << 'EOF'
#MAGISK
EOF

# Make update-binary executable
chmod 755 "$MODULE_DIR/update-binary"

# Copy module files to temp directory
cp module.prop "$TEMP_DIR/"
cp install.sh "$TEMP_DIR/"
cp hotspot-watcher.sh "$TEMP_DIR/"
cp README.md "$TEMP_DIR/"

# Create the ZIP
cd "$TEMP_DIR"
zip -r "../$ZIP_NAME" .
cd - > /dev/null

# Move ZIP to current directory
mv "$TEMP_DIR/../$ZIP_NAME" .

# Cleanup
rm -rf "$TEMP_DIR"

echo "✅ Flashable ZIP created: $ZIP_NAME"
echo ""
echo "To install:"
echo "1. Copy $ZIP_NAME to your phone"
echo "2. Open Magisk Manager"
echo "3. Tap 'Modules' tab"
echo "4. Tap '+' (Install from storage)"
echo "5. Select the ZIP file"
echo "6. Reboot after installation"