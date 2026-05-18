# 🎙️ TTS-CLI: 终端智能语音合成工具

基于微软 Edge-TTS 和 MarkItDown 构建的命令行语音合成工具。支持将文本、Word、PDF 等文档一键转换为自然流畅的语音 (MP3)。

本项目现在同时也是一个标准的 Agent Skill：仓库内置 `tts-skill/`，其他支持 Skills 的 agent 可以加载它，并在需要文本转语音、文档转语音、批量转语音或生成字幕时自动调用本项目的 `tts` 命令。

## ✨ 主要功能
- **一键转换**：支持 Text, .txt, .md, .pdf, .docx 格式。
- **智能清洗**：自动去除文档中的 Markdown 符号、修复中文排版顿挫问题。
- **多角色支持**：内置 8 种精选语音（含男声、女声、粤语、东北话、台湾话）。
- **自定义音效**：灵活调整语速、音量和音调，满足个性化需求。
- **长文本优化**：高效处理超长文本，确保流畅转换不中断。
- **字幕文件生成**：同步生成 SRT 字幕文件，便于视频或学习使用。
- **短格式支持**：命令行参数支持短格式选项，提升输入效率。
- **交互式界面**：简单的命令行交互选择声音。
- **Agent Skill 支持**：内置标准 `tts-skill`，可供 Codex、Claude Code 等 agent 调用。

## 🚀 快速安装
在终端（macOS / Linux / WSL）中运行以下命令：

```bash
curl -s https://raw.githubusercontent.com/nanyuzuo/tts-cli/main/install_tts.sh | bash
```

安装脚本会创建独立 Python 虚拟环境，不污染系统环境。由于 MarkItDown 当前正式版需要 Python 3.10+，脚本会自动寻找可用的新版 Python。

## 📖 使用方法

### 1. 交互式选择声音
```bash
tts --select
```

### 2. 简单文本转语音
```bash
tts "你好，这是一个测试" --out hello.mp3
```

### 3. 文档转语音 (支持 PDF/Word)
```bash
tts --file "年度报告.pdf" --out report.mp3
```

### 4. 卸载
```bash
tts --uninstall
```

### 5. 调整语速、音量和音调
```bash
tts "调整语速、音量和音调" --rate +20% --volume +10% --pitch -5Hz --out customized.mp3
```

### 6. 生成字幕文件
```bash
tts "这是一段需要生成字幕的文本" --out with_subtitle.mp3 --subtitle
```

### 7. 使用短格式选项
```bash
tts -f "文档.txt" -o doc_short.mp3 -s
```

## 🤖 作为 Agent Skill 使用

`tts-skill/` 是一个标准 skill 目录，包含：

- `SKILL.md`：定义何时触发该 skill，以及 agent 应如何调用 `tts`。
- `references/tts-cli.md`：提供声音列表、命令参数、安装细节和故障排查。
- `agents/openai.yaml`：用于支持该 metadata 的 agent UI。

### 安装到 Codex

```bash
mkdir -p ~/.codex/skills
cp -R tts-skill ~/.codex/skills/tts-skill
```

### 安装到 Claude Code

```bash
mkdir -p ~/.claude/skills
cp -R tts-skill ~/.claude/skills/tts-skill
```

### Agent 调用示例

```text
Use $tts-skill to convert this text into an MP3 file: 你好，这是一个测试。
```

```text
使用 $tts-skill，把 /absolute/path/article.md 转成 MP3，输出到 /absolute/path/article.mp3，并生成字幕。
```

```text
请把 /absolute/path/docs 目录下的文档批量转成语音，输出到 /absolute/path/audio。
```

这个 skill 本身不直接合成音频，而是指导 agent 检测、安装并调用本项目提供的 `tts` CLI。因此目标机器仍需先安装本工具，或者允许 agent 运行 `install_tts.sh`。

## 🛠️ 依赖
本工具会自动创建独立的 Python 虚拟环境，不会污染系统环境。
- Python 3.10+
- edge-tts
- markitdown
