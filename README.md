# Patchwork

A Python-based patch management tool for developing and testing patches against a target directory using Git version control.

## Version

Current version: **1.1.0** - Autocomplete Support

## Overview

Patchwork simplifies the process of creating, testing, and managing patches for software projects. It uses Git to track changes and provides a workflow for:

- Creating patches from Git differences
- Testing patches in isolation
- Applying and reverting patches safely
- Managing patch versions and deployments

## Requirements

### System Requirements
- Python 3.6 or higher
- Git (for version control operations)
- Unix-like operating system (Linux/macOS)
- Standard Unix tools: `diff`, `patch`

### Python Dependencies
- No external Python dependencies required (uses standard library only)

## Installation

1. Clone or download the patchwork tool to your desired location

2. Run the installation script:
```bash
./install.sh /usr/local/bin/patchwork
```

This will:
- Create a Python virtual environment
- Generate a wrapper script (`patchwork.sh`)
- Install the tool to the specified location (e.g., `/usr/local/bin/patchwork`)
- Set up bash completion for all commands

3. Restart your shell or run `source ~/.bashrc` to enable bash completion

## Usage

### Workflow Overview

1. **Initialize** a patchwork project pointing to your target directory
2. **Make changes** to files in the target directory
3. **Build patch** from the Git differences
4. **Test** the patch to ensure it works correctly
5. **Cache** the patch for deployment
6. **Apply/Clear** patches as needed

### Commands

#### Initialize a Project
```bash
patchwork init [target_directory]
```
- Sets up a new patchwork project
- Creates or uses existing Git repository in target directory
- Creates a `patchwork_base` tag for tracking changes
- If no target directory is provided, uses existing configuration

#### Add a Patch File
```bash
patchwork add_patch <patch_file.patch>
```
- Configures patchwork to use the specified patch file
- Only one patch can be active at a time

#### Build a Patch from Changes
```bash
patchwork build_patch
```
- Creates a patch from Git differences since `patchwork_base` tag
- Generates unified diff format patch in `patches/changes.patch`
- Creates A/ and B/ directories showing before/after states

#### Cache a Patch
```bash
patchwork cache_patch
```
- Copies the configured patch to the local patches directory
- Required before testing or applying patches

#### Test a Patch
```bash
patchwork test
```
- Validates that the cached patch can be applied correctly
- Tests using the A/ and B/ directories created by `build_patch`

#### Apply a Patch
```bash
patchwork apply [--force]
```
- Applies the cached patch to the target directory
- Requires being at the `patchwork_base` commit (unless using `--force`)
- Use `--force` to apply patch regardless of current Git state

#### Clear Changes
```bash
patchwork clear
```
- Resets the target directory to the `patchwork_base` tag
- Removes all changes and applied patches

#### Deploy a Patch
```bash
patchwork deploy_patch
```
- Copies the cached patch back to the original patch file location
- Useful for updating the original patch after modifications

### Configuration

Patchwork stores its configuration in `patchwork.json`:

```json
{
    "target_dir": "/path/to/target/directory",
    "patches": [
        {
            "path": "/path/to/patch/file.patch",
            "cached": true
        }
    ]
}
```

### Directory Structure

After initialization and usage, your patchwork project will look like:

```
patchwork_project/
├── patchwork.json         # Configuration file
├── patches/               # Patch storage directory
│   ├── A/                # Original files (before changes)
│   ├── B/                # Modified files (after changes)
│   └── changes.patch     # Generated/cached patch file
└── target_directory/     # Your actual project directory (Git repo)
```

## Bash Completion

The installation includes comprehensive bash completion support:

- **Commands**: Auto-complete all available commands
- **Options**: Auto-complete command-line flags like `--force`
- **Files**: Auto-complete `.patch` files for `add_patch` command
- **Directories**: Auto-complete directory names for `init` command

Press `Tab` after typing `patchwork` to see available commands and options.

## Examples

### Creating and Testing a New Patch

```bash
# Initialize patchwork for a project
patchwork init /path/to/my/project

# Make some changes to files in /path/to/my/project
# ... edit files ...

# Build a patch from your changes
patchwork build_patch

# Test the patch
patchwork test

# Cache the patch for application
patchwork cache_patch

# Apply the patch (if needed)
patchwork apply

# Clear changes to start fresh
patchwork clear
```

### Working with Existing Patch Files

```bash
# Set up patchwork to use an existing patch
patchwork add_patch my_changes.patch

# Cache the patch locally
patchwork cache_patch

# Test the patch
patchwork test

# Apply the patch
patchwork apply

# After testing, deploy changes back to original patch
patchwork deploy_patch
```

## Error Handling

Patchwork includes comprehensive error handling for:
- Missing target directories
- Invalid Git repositories
- Uncommitted changes in target directory
- Missing or invalid patch files
- Git operation failures
- Permission issues

## Tips

- Always ensure your target directory changes are committed before using `patchwork clear`
- Use `build_patch` to create patches from your Git workflow
- Use `test` before `apply` to validate patches work correctly
- The `--force` flag bypasses Git state checks but use it carefully
- Bash completion makes the tool much easier to use - make sure it's installed

## License

[Specify your license here] 