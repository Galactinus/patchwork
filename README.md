# Patchwork

A Python-based tool for managing and applying patches in a unified diff format.

## Requirements

### System Requirements
- Python 3.6 or higher
- Git (for version control operations)
- Unix-like operating system (Linux/macOS)

### Python Dependencies
- `gitpython` - For Git operations
- `colorama` - For colored terminal output
- `typer` - For CLI interface
- `rich` - For rich text formatting and progress bars

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd patchwork
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

## Usage

### Basic Commands

1. **Create a Patch**
```bash
python patchwork.py create <patch-name>
```
- Creates a new patch with the specified name
- Generates a unified diff format patch file
- Stores patch in the patches directory

2. **Apply a Patch**
```bash
python patchwork.py apply <patch-name>
```
- Applies the specified patch to the current working directory
- Validates patch format before applying
- Provides feedback on application status

3. **List Patches**
```bash
python patchwork.py list
```
- Shows all available patches in the patches directory
- Displays patch names and creation dates

4. **Remove a Patch**
```bash
python patchwork.py remove <patch-name>
```
- Removes the specified patch from the patches directory
- Confirms deletion before proceeding

### Patch Format

Patches are stored in unified diff format with the following structure:
```
--- a/<original-file>
+++ b/<modified-file>
@@ -<line-numbers> +<line-numbers> @@
<context lines>
<added/removed lines>
```

### Directory Structure

```
patchwork/
├── patches/           # Directory for storing patch files
├── patchwork.py       # Main script
├── requirements.txt   # Python dependencies
└── README.md         # This file
```

## Error Handling

The tool includes comprehensive error handling for:
- Invalid patch formats
- Missing files
- Git operation failures
- Permission issues
- Invalid command arguments

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

[Specify your license here] 