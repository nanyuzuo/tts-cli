# TTS-CLI Project Context

## Project Overview
**TTS-CLI** is a command-line interface tool designed to convert text and various document formats (PDF, Word, Markdown, Text) into natural-sounding speech (MP3). It leverages Microsoft Edge-TTS for synthesis and MarkItDown for document parsing and cleaning.

## Key Files
*   **`install_tts.sh`**: The primary artifact. This script acts as:
    *   **Installer**: Sets up the environment, directories, and dependencies.
    *   **Source Container**: Contains the Python source code (`main.py`) embedded as a heredoc.
    *   **Deployer**: Writes the Python code to the target directory and sets up the `tts` command alias.
*   **`README.md`**: User documentation.

## Architecture & Installation
This project uses a "self-contained installer" pattern.

1.  **Deployment Target**: The tool installs itself to `~/.local/share/tts-cli`.
2.  **Python Environment**: Creates a dedicated `venv` inside the target directory to avoid system package conflicts.
3.  **Executable**: Symlinks a wrapper script to `/usr/local/bin/tts` for global access.

### How to Install/Update
Run the installer script directly:
```bash
bash install_tts.sh
```
*Note: This requires `sudo` access during the final step to create the symlink in `/usr/local/bin`.*

## Development & Modification
**Important**: The Python source code (`main.py`) is **generated** by `install_tts.sh`.

*   **To make permanent changes**: Edit the `cat > "$INSTALL_DIR/main.py" << 'EOF'` section within `install_tts.sh`.
*   **To test changes locally**: You can directly modify `~/.local/share/tts-cli/main.py` on your machine, but these changes will be overwritten the next time `install_tts.sh` is run.

## Usage Examples
*   **Select Voice**: `tts --select`
*   **Text to Speech**: `tts "Hello World" --out hello.mp3`
*   **File to Speech**: `tts --file doc.pdf --out doc.mp3`
