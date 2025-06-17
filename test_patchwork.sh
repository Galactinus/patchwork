#!/bin/bash

# Exit on error
set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print test status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
        exit 1
    fi
}

# Function to run a test command
run_test() {
    echo -e "${YELLOW}Running: $1${NC}"
    eval "$1"
    print_status $? "$1"
}

# Function to show file contents
show_file() {
    if [ -f "$1" ]; then
        echo -e "${BLUE}Contents of $1:${NC}"
        cat "$1"
        echo
    else
        echo -e "${RED}File $1 does not exist${NC}"
    fi
}

# Function to show directory structure
show_dir() {
    if [ -d "$1" ]; then
        echo -e "${BLUE}Directory structure of $1:${NC}"
        find "$1" -type f -o -type d | sort
        echo
    else
        echo -e "${RED}Directory $1 does not exist${NC}"
    fi
}

# Function to show git status
show_git_status() {
    if [ -d "$1/.git" ]; then
        echo -e "${BLUE}Git status in $1:${NC}"
        (cd "$1" && git status)
        echo
    else
        echo -e "${RED}Git repository not found in $1${NC}"
    fi
}

# Cleanup old test folders (only directories matching test_[0-9]*)
echo "Cleaning up old test folders..."
rm -rf test_[0-9]*

# Create test directory with timestamp
TEST_DIR="test_$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "Setting up test environment..."

# Clone the repository
run_test "git clone git@github.com:Galactinus/calendar_alarm_clock.git"

# Show initial directory structure
show_dir "calendar_alarm_clock"

# Initialize patchwork
run_test "../patchwork.py init calendar_alarm_clock"

# Show git status after init
show_git_status "calendar_alarm_clock"

# Make initial test changes
echo "Making initial test changes..."
# Modify existing files
echo "# Test patch note" >> calendar_alarm_clock/README.md
echo "# Test patch" >> calendar_alarm_clock/ulticlock.py
echo "# Test plugin" >> calendar_alarm_clock/plugins/__init__.py
# Create new file
echo "# New test file" > calendar_alarm_clock/plugins/test_plugin.py
# Delete a file
rm -f calendar_alarm_clock/example.config

# Show changes
echo -e "${BLUE}Changes made:${NC}"
show_file "calendar_alarm_clock/README.md"
show_file "calendar_alarm_clock/ulticlock.py"
show_file "calendar_alarm_clock/plugins/__init__.py"
show_file "calendar_alarm_clock/plugins/test_plugin.py"
show_dir "calendar_alarm_clock"

# Show git status after changes
show_git_status "calendar_alarm_clock"

# Build, add, and cache the patch
run_test "../patchwork.py build_patch"

# Show patch contents
echo -e "${BLUE}Patch contents:${NC}"
show_file "patches/changes.patch"

# Save first patch
FIRST_PATCH="patches/first_changes.patch"
cp patches/changes.patch "$FIRST_PATCH"
echo -e "${BLUE}Saved first patch to: $FIRST_PATCH${NC}"

run_test "../patchwork.py add_patch patches/changes.patch"
run_test "../patchwork.py cache_patch"

# Clear changes before testing/applying
run_test "../patchwork.py clear"

# Show git status after clear
show_git_status "calendar_alarm_clock"

# Test and apply the patch
run_test "../patchwork.py test"
run_test "../patchwork.py apply"

# Show files after patch application
echo -e "${BLUE}Files after patch application:${NC}"
show_file "calendar_alarm_clock/README.md"
show_file "calendar_alarm_clock/ulticlock.py"
show_file "calendar_alarm_clock/plugins/__init__.py"
show_file "calendar_alarm_clock/plugins/test_plugin.py"
show_dir "calendar_alarm_clock"

# Verify patch application (initial changes)
run_test "grep -q 'Test patch note' calendar_alarm_clock/README.md"
run_test "grep -q 'Test patch' calendar_alarm_clock/ulticlock.py"
run_test "grep -q 'Test plugin' calendar_alarm_clock/plugins/__init__.py"
run_test "test -f calendar_alarm_clock/plugins/test_plugin.py"
run_test "! test -f calendar_alarm_clock/example.config"

# Make additional changes (including subdirectories, new files, deletions)
echo "Making additional changes..."
# Modify existing files
echo "# Additional test note" >> calendar_alarm_clock/README.md
echo "# Additional test" >> calendar_alarm_clock/ulticlock.py
echo "# Additional plugin" >> calendar_alarm_clock/plugins/__init__.py
# Create new file in subdirectory
mkdir -p calendar_alarm_clock/notification_server
echo "# Additional test file" > calendar_alarm_clock/notification_server/test_notification.py
# Delete another file
rm -f calendar_alarm_clock/setup.bat

# Show additional changes
echo -e "${BLUE}Additional changes made:${NC}"
show_file "calendar_alarm_clock/README.md"
show_file "calendar_alarm_clock/ulticlock.py"
show_file "calendar_alarm_clock/plugins/__init__.py"
show_file "calendar_alarm_clock/notification_server/test_notification.py"
show_dir "calendar_alarm_clock"

# Show git status after additional changes
show_git_status "calendar_alarm_clock"

# Build, add, and cache the new patch
run_test "../patchwork.py build_patch"

# Show new patch contents
echo -e "${BLUE}New patch contents:${NC}"
show_file "patches/changes.patch"

# Save second patch
SECOND_PATCH="patches/second_changes.patch"
cp patches/changes.patch "$SECOND_PATCH"
echo -e "${BLUE}Saved second patch to: $SECOND_PATCH${NC}"

run_test "../patchwork.py add_patch patches/changes.patch"
run_test "../patchwork.py cache_patch"

# Clear changes before testing/applying
run_test "../patchwork.py clear"

# Show git status after clear
show_git_status "calendar_alarm_clock"

# Test and apply the new patch
run_test "../patchwork.py test"
run_test "../patchwork.py apply"

# Show files after second patch application
echo -e "${BLUE}Files after second patch application:${NC}"
show_file "calendar_alarm_clock/README.md"
show_file "calendar_alarm_clock/ulticlock.py"
show_file "calendar_alarm_clock/plugins/__init__.py"
show_file "calendar_alarm_clock/plugins/test_plugin.py"
show_file "calendar_alarm_clock/notification_server/test_notification.py"
show_dir "calendar_alarm_clock"

# Verify patch application (all changes, including new ones)
run_test "grep -q 'Test patch note' calendar_alarm_clock/README.md"
run_test "grep -q 'Additional test note' calendar_alarm_clock/README.md"
run_test "grep -q 'Test patch' calendar_alarm_clock/ulticlock.py"
run_test "grep -q 'Additional test' calendar_alarm_clock/ulticlock.py"
run_test "grep -q 'Test plugin' calendar_alarm_clock/plugins/__init__.py"
run_test "grep -q 'Additional plugin' calendar_alarm_clock/plugins/__init__.py"
run_test "test -f calendar_alarm_clock/plugins/test_plugin.py"
run_test "test -f calendar_alarm_clock/notification_server/test_notification.py"
run_test "! test -f calendar_alarm_clock/example.config"
run_test "! test -f calendar_alarm_clock/setup.bat"

# Test force apply (should succeed even if not at base)
run_test "../patchwork.py apply --force"

# Show final git status
show_git_status "calendar_alarm_clock"

echo -e "${GREEN}All tests completed successfully!${NC}"
echo -e "${BLUE}Test directory preserved at: $TEST_DIR${NC}"
echo -e "${BLUE}First patch preserved at: $FIRST_PATCH${NC}"
echo -e "${BLUE}Second patch preserved at: $SECOND_PATCH${NC}" 