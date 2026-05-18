# TTS CLI Reference

## Source Project

The original project is a Bash installer that writes a Python CLI to:

- `~/.local/share/tts-cli/main.py`
- `~/.local/share/tts-cli/tts`
- `/usr/local/bin/tts` as a symlink

It creates an isolated Python virtual environment and installs:

- `edge-tts`
- `markitdown[all]`

The installer may ask for sudo only when linking `/usr/local/bin/tts`.

## Supported Operations

Text to MP3:

```bash
tts "text to speak" -o output.mp3
```

Document to MP3:

```bash
tts -f input.docx -o output.mp3
```

Batch directory conversion:

```bash
tts -f input_dir -o output_dir
```

Subtitles:

```bash
tts "text" -o output.mp3 -s
```

Subtitles are generated as `.srt`, not WebVTT.

Prosody controls:

- `--rate` / `-r`: examples `+20%`, `-10%`
- `--volume` / `-v`: examples `+10%`, `-20%`
- `--pitch` / `-p`: examples `+10Hz`, `-5Hz`

## Built-In Voices

The CLI includes these Microsoft neural voices:

- `zh-CN-YunxiNeural`: 云希, male, young and lively
- `zh-CN-YunjianNeural`: 云健, male, mature and formal
- `zh-CN-YunyangNeural`: 云扬, male, broadcast style
- `zh-CN-XiaoxiaoNeural`: 晓晓, female, warm general-purpose voice
- `zh-CN-XiaoyiNeural`: 晓伊, female, gentle and expressive
- `zh-CN-Liaoning-XiaobeiNeural`: 晓北, female, Liaoning accent
- `zh-HK-HiuGaaiNeural`: 晓佳, female, Cantonese
- `zh-TW-HsiaoChenNeural`: 晓臻, female, Taiwan Mandarin

The CLI does not expose a `--voice` flag. Change voice with `tts --select`, or edit `~/.config/tts-cli/config.json` to:

```json
{"voice": "zh-CN-XiaoxiaoNeural"}
```

## Verification

After generation, verify the output exists and is non-empty:

```bash
test -s /absolute/path/output.mp3
```

For subtitle tasks, also verify:

```bash
test -s /absolute/path/output.srt
```

## Troubleshooting

- `tts: command not found`: run the installer, then retry. If the symlink failed, try `~/.local/share/tts-cli/tts`.
- `文件不存在`: use an absolute path and verify the input file exists.
- Empty document extraction: confirm the PDF/DOCX contains selectable text. Scanned PDFs may need OCR dependencies outside the Python package.
- Edge TTS errors: check network access and retry later; the backend service is external.
- Permission errors under `/usr/local/bin`: run the installer with approval for sudo, or invoke `~/.local/share/tts-cli/tts` directly.
