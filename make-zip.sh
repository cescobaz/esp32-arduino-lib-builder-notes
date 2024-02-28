#!/bin/bash
source ./tools/config.sh

set -ex

DIR=$(pwd)

# define some stuff
BUILD_VERSION=2.0.12
ARCHIVE_FILE_NAME="esp32-$BUILD_VERSION.zip"
ARCHIVE_FILE_PATH="$DIR/dist/$ARCHIVE_FILE_NAME" 

ARCHIVE_CONTENT_DIR_NAME=esp32
ARCHIVE_CONTENT_DIR_PATH="$DIR/dist/$ARCHIVE_CONTENT_DIR_NAME"
rm -rf "$ARCHIVE_CONTENT_DIR_PATH"
mkdir -p "$ARCHIVE_CONTENT_DIR_PATH"
rm -rf "$ARCHIVE_FILE_PATH"

# copy arduino stuff
ESP32_ARDUINO="$AR_COMPS/arduino"
cp -r "$ESP32_ARDUINO"/* "$ARCHIVE_CONTENT_DIR_PATH/"
rm -rf "$ARCHIVE_CONTENT_DIR_PATH/.git"

# copy compiled stuff to dest folder
ESP32_ARDUINO="$ARCHIVE_CONTENT_DIR_PATH"
echo "Copy files to Arduino folder ${ESP32_ARDUINO}"
ESP32_ARDUINO=$ESP32_ARDUINO ./tools/copy-to-arduino.sh

# Replace tools locations in platform.txt
PKG_DIR="$ARCHIVE_CONTENT_DIR_PATH"
echo "Generating platform.txt..."
cat "$DIR/out/platform.txt" | \
sed 's/tools.xtensa-esp32-elf-gcc.path={runtime.platform.path}\/tools\/xtensa-esp32-elf/tools.xtensa-esp32-elf-gcc.path=\{runtime.tools.xtensa-esp32-elf-gcc.path\}/g' | \
sed 's/tools.xtensa-esp32s2-elf-gcc.path={runtime.platform.path}\/tools\/xtensa-esp32s2-elf/tools.xtensa-esp32s2-elf-gcc.path=\{runtime.tools.xtensa-esp32s2-elf-gcc.path\}/g' | \
sed 's/tools.xtensa-esp32s3-elf-gcc.path={runtime.platform.path}\/tools\/xtensa-esp32s3-elf/tools.xtensa-esp32s3-elf-gcc.path=\{runtime.tools.xtensa-esp32s3-elf-gcc.path\}/g' | \
sed 's/tools.xtensa-esp-elf-gdb.path={runtime.platform.path}\/tools\/xtensa-esp-elf-gdb/tools.xtensa-esp-elf-gdb.path=\{runtime.tools.xtensa-esp-elf-gdb.path\}/g' | \
sed 's/tools.riscv32-esp-elf-gcc.path={runtime.platform.path}\/tools\/riscv32-esp-elf/tools.riscv32-esp-elf-gcc.path=\{runtime.tools.riscv32-esp-elf-gcc.path\}/g' | \
sed 's/tools.riscv32-esp-elf-gdb.path={runtime.platform.path}\/tools\/riscv32-esp-elf-gdb/tools.riscv32-esp-elf-gdb.path=\{runtime.tools.riscv32-esp-elf-gdb.path\}/g' | \
sed 's/tools.esptool_py.path={runtime.platform.path}\/tools\/esptool/tools.esptool_py.path=\{runtime.tools.esptool_py.path\}/g' | \
sed 's/debug.server.openocd.path={runtime.platform.path}\/tools\/openocd-esp32\/bin\/openocd/debug.server.openocd.path=\{runtime.tools.openocd-esp32.path\}\/bin\/openocd/g' | \
sed 's/debug.server.openocd.scripts_dir={runtime.platform.path}\/tools\/openocd-esp32\/share\/openocd\/scripts\//debug.server.openocd.scripts_dir=\{runtime.tools.openocd-esp32.path\}\/share\/openocd\/scripts\//g' | \
sed 's/debug.server.openocd.scripts_dir.windows={runtime.platform.path}\\tools\\openocd-esp32\\share\\openocd\\scripts\\/debug.server.openocd.scripts_dir.windows=\{runtime.tools.openocd-esp32.path\}\\share\\openocd\\scripts\\/g' \
 > "$PKG_DIR/platform.txt"

# copy dependencies file
# cp "$DIR/out/package_esp32_index.template.json" "$ESP32_ARDUINO/package/"

# get/generate the needed stuff
# cd "$ESP32_ARDUINO/tools"
# python3 ./get.py

# create the zip
cd "$ARCHIVE_CONTENT_DIR_PATH/.."
zip -r "$ARCHIVE_FILE_PATH" \
  "$ARCHIVE_CONTENT_DIR_NAME/platform.txt" \
  "$ARCHIVE_CONTENT_DIR_NAME/boards.txt" \
  "$ARCHIVE_CONTENT_DIR_NAME/programmers.txt" \
  "$ARCHIVE_CONTENT_DIR_NAME/cores" \
  "$ARCHIVE_CONTENT_DIR_NAME/libraries" \
  "$ARCHIVE_CONTENT_DIR_NAME/tools" \
  "$ARCHIVE_CONTENT_DIR_NAME/tools/espota.exe \
  "$ARCHIVE_CONTENT_DIR_NAME/tools/espota.py \
  "$ARCHIVE_CONTENT_DIR_NAME/tools/gen_esp32part.py \
  "$ARCHIVE_CONTENT_DIR_NAME/tools/gen_esp32part.exe \
  "$ARCHIVE_CONTENT_DIR_NAME/tools/gen_insights_package.py \
  "$ARCHIVE_CONTENT_DIR_NAME/tools/gen_insights_package.exe \
  "$ARCHIVE_CONTENT_DIR_NAME/tools/partitions \
  "$ARCHIVE_CONTENT_DIR_NAME/tools/ide-debug \
  "$ARCHIVE_CONTENT_DIR_NAME/tools/sdk \
  "$ARCHIVE_CONTENT_DIR_NAME/tools/platformio-build*.py \
  "$ARCHIVE_CONTENT_DIR_NAME/variants"

cd "$DIR"

# create platform_index file
INDEX_FILE_PATH="./dist/package_esp32_index.json"
cp "./out/package_esp32_index.template.json" "$INDEX_FILE_PATH"

BASE_URL=https://buro.fra1.digitaloceanspaces.com/arduino
ZIP_URL="$BASE_URL/$ARCHIVE_FILE_NAME"
ZIP_CHECKSUM=$(sha256sum "$ARCHIVE_FILE_PATH" | awk '{print $1}')
ARCHIVE_FILE_SIZE=$(stat -c%s "$ARCHIVE_FILE_PATH")

sed -i "s|\(.*\"url\"\) *: *\"\".*|\1: \"$ZIP_URL\",|" "$INDEX_FILE_PATH"
sed -i "s/\(.*\"archiveFileName\"\) *: *\"\".*/\1: \"$ARCHIVE_FILE_NAME\",/" "$INDEX_FILE_PATH"
sed -i "s/\(.*\"checksum\"\) *: *\"\".*/\1: \"SHA-256:$ZIP_CHECKSUM\",/" "$INDEX_FILE_PATH"
sed -i "s/\(.*\"size\"\) *: *\"\".*/\1: \"$ARCHIVE_FILE_SIZE\",/" "$INDEX_FILE_PATH"
sed -i "s/\(.*\"version\"\) *: *\"\".*/\1: \"$BUILD_VERSION\",/" "$INDEX_FILE_PATH"
