---
name: tts-skill
description: Convert text, Markdown, TXT, PDF, DOCX, or a directory of supported documents into spoken audio with the local `tts` CLI based on Microsoft Edge TTS. Use when Codex needs to generate MP3 narration, create audio from pasted text, turn documents into speech, batch-convert files, adjust voice/rate/pitch/volume, or generate matching subtitle files.
---

# TTS Skill

## Workflow

Use the local `tts` command to synthesize speech. Prefer absolute input and output paths so generated audio is easy to find.

1. Check whether the CLI is available:
   ```bash
   command -v tts
   tts --version
   ```
2. If unavailable, install it from the current `tts-cli` project when that project is present:
   ```bash
   bash /path/to/tts-cli/install_tts.sh
   ```
   If no local project is available, install from the upstream script only with user approval because it downloads packages and may need sudo for `/usr/local/bin/tts`.
3. Create parent directories for requested outputs before conversion.
4. Run the smallest command that matches the request.
5. Verify output files exist and are non-empty before claiming success.

## Common Commands

Convert literal text:

```bash
tts "你好，这是一个测试" --out /absolute/path/output.mp3
```

Convert one document:

```bash
tts --file /absolute/path/input.pdf --out /absolute/path/output.mp3
```

Batch-convert a directory of `.txt`, `.md`, `.pdf`, and `.docx` files:

```bash
tts --file /absolute/path/input-dir --out /absolute/path/output-dir
```

Generate subtitles alongside the MP3:

```bash
tts "需要字幕的文本" --out /absolute/path/output.mp3 --subtitle
```

The subtitle file is written next to the MP3 with the same basename and an `.srt` extension.

Adjust prosody:

```bash
tts "调整语速、音量和音调" --rate +20% --volume +10% --pitch -5Hz --out /absolute/path/output.mp3
```

## Voice Selection

For interactive voice selection, run:

```bash
tts --select
```

For non-interactive agent work, use the configured default voice unless the user asks to change it. The CLI stores the selected voice in `~/.config/tts-cli/config.json`.

Read `references/tts-cli.md` when the task needs exact voice IDs, installation details, supported formats, or troubleshooting guidance.

## Operational Notes

- Supported direct input formats are text, `.txt`, `.md`, `.pdf`, and `.docx`; directory mode processes those file extensions.
- Long text is automatically chunked before sending to Edge TTS.
- Document extraction uses MarkItDown, so scanned PDFs may require OCR-related system packages.
- The CLI uses the network-backed Edge TTS service; if synthesis fails with connectivity or service errors, report that clearly.
- Do not run `tts --uninstall` unless the user explicitly asks to remove the tool.
