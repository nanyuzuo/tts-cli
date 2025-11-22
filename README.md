# 🎙️ TTS-CLI: 终端智能语音合成工具

基于微软 Edge-TTS 和 MarkItDown 构建的命令行语音合成工具。支持将文本、Word、PDF 等文档一键转换为自然流畅的语音 (MP3)。

## ✨ 主要功能
- **一键转换**：支持 Text, .txt, .md, .pdf, .docx 格式。
- **智能清洗**：自动去除文档中的 Markdown 符号、修复中文排版顿挫问题。
- **多角色支持**：内置 8 种精选语音（含男声、女声、粤语、东北话、台湾话）。
- **交互式界面**：简单的命令行交互选择声音。

## 🚀 快速安装
在终端（macOS / Linux / WSL）中运行以下命令：

```bash
curl -s https://raw.githubusercontent.com/nanyuzuo/tts-cli/main/install.sh | bash
```
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

## 🛠️ 依赖
本工具会自动创建独立的 Python 虚拟环境，不会污染系统环境。
- python3
- edge-tts
- markitdown
```

