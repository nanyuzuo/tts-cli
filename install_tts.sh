#!/bin/bash
#
#*****************************************************
#Author:        nanyuzuo
#Github:        https://github.com/nanyuzuo
#Date:          2025-11-22
#FileName:      install_tts.sh
#Description:                         
#BLOG:          http://nanyuzuo.xin/hexo
#Copyright (c):2025 All rights reserved
#****************************************************
#!/bin/bash

# =================配置区域=================
INSTALL_DIR="$HOME/.local/share/tts-cli"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="$HOME/.config/tts-cli"
# =========================================

echo -e "\033[1;34m>>> 欢迎使用TTS 智能语音转换工具 (v1.0)\033[0m"
echo -e "\033[1;34m>>> 开始安装...\033[0m"

# 1. 检查 Python3，MarkItDown 当前正式版要求 Python >= 3.10
PYTHON_BIN=""
for candidate in python3 /opt/homebrew/bin/python3 /opt/homebrew/Caskroom/miniforge/base/bin/python; do
    if command -v "$candidate" &> /dev/null; then
        if "$candidate" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null; then
            PYTHON_BIN="$candidate"
            break
        fi
    fi
done

if [ -z "$PYTHON_BIN" ]; then
    echo -e "\033[1;31m错误: 未检测到 Python 3.10+，请先安装新版 Python。\033[0m"
    exit 1
fi

# 2. 创建目录
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"

# 3. 创建虚拟环境 (如果不存在)
if [ ! -d "$INSTALL_DIR/venv" ]; then
    echo -e "\033[1;33m-> 创建独立运行环境...\033[0m"
    "$PYTHON_BIN" -m venv "$INSTALL_DIR/venv"
fi

# 使用 markitdown[all] 确保支持 PDF, Word, Excel, OCR 等所有格式
echo -e "\033[1;33m-> 正在安装/更新依赖 (含 PDF/Word 解析库)...\033[0m"
echo -e "\033[0;37m   (此过程可能需要几分钟，日志: /tmp/tts_install.log)\033[0m"

# 定义 spinner 动画
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# 后台执行安装
(
    "$INSTALL_DIR/venv/bin/pip" install --upgrade pip
    "$INSTALL_DIR/venv/bin/pip" install edge-tts "markitdown[all]"
) > /tmp/tts_install.log 2>&1 &

PID=$!
echo -n "   正在下载并配置环境"
spinner $PID

wait $PID
if [ $? -eq 0 ]; then
    echo -e "\033[1;32m✅ 依赖安装成功\033[0m"
else
    echo -e "\n\033[1;31m❌ 安装失败，请查看日志: cat /tmp/tts_install.log\033[0m"
    exit 1
fi

# 5. 生成 Python 核心代码
cat > "$INSTALL_DIR/main.py" << 'EOF'
import argparse
import asyncio
import json
import os
import sys
import re
import shutil
import subprocess
from markitdown import MarkItDown
import edge_tts

# 路径定义
INSTALL_DIR = os.path.expanduser("~/.local/share/tts-cli")
CONFIG_DIR = os.path.expanduser("~/.config/tts-cli")
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")
LINK_PATH = "/usr/local/bin/tts"

# 声音列表
VOICES = [
    {"id": "zh-CN-YunxiNeural", "name": "云希", "gender": "男", "desc": "年轻活力，适合有声书、现代文 (推荐)"},
    {"id": "zh-CN-YunjianNeural", "name": "云健", "gender": "男", "desc": "成熟稳重，适合新闻、正式报告"},
    {"id": "zh-CN-YunyangNeural", "name": "云扬", "gender": "男", "desc": "专业播音腔，正气凛然"},
    {"id": "zh-CN-XiaoxiaoNeural", "name": "晓晓", "gender": "女", "desc": "温暖亲切，最受欢迎的通用女声 (推荐)"},
    {"id": "zh-CN-XiaoyiNeural", "name": "晓伊", "gender": "女", "desc": "温柔甜美，情感丰富"},
    {"id": "zh-CN-Liaoning-XiaobeiNeural", "name": "晓北", "gender": "女", "desc": "东北话口音，幽默风趣，适合段子"},
    {"id": "zh-HK-HiuGaaiNeural", "name": "晓佳", "gender": "女", "desc": "标准粤语 (广东话)"},
    {"id": "zh-TW-HsiaoChenNeural", "name": "晓臻", "gender": "女", "desc": "台湾国语，软糯温柔"}
]

# 自定义帮助信息模板
HELP_EPILOG = """
\033[1;36m==============================================
使用方法:
1. 选择声音: \033[1;33mtts --select\033[0m
2. 文本转语音: \033[1;33mtts "你好，世界" -o hi.mp3\033[0m
3. 文档转语音: \033[1;33mtts -f 报告.pdf -o report.mp3\033[0m (支持 PDF/Word/TXT/MD)
4. 批量转换:   \033[1;33mtts -f ./book_dir -o ./output_dir\033[0m
5. 生成字幕:   \033[1;33mtts "你好" -o hi.mp3 --subtitle\033[0m
6. 调整参数:   \033[1;33mtts "内容" --rate=+20% --pitch=+10Hz --volume=+10%\033[0m
7. 卸载应用:   \033[1;31mtts -u\033[0m
8. 查看帮助:   \033[1;33mtts -h\033[0m
\033[1;36m==============================================\033[0m
"""

def load_config():
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'r') as f:
                return json.load(f)
        except:
            pass
    return {"voice": "zh-CN-YunxiNeural"}

def save_config(voice_id):
    if not os.path.exists(CONFIG_DIR):
        os.makedirs(CONFIG_DIR)
    with open(CONFIG_FILE, 'w') as f:
        json.dump({"voice": voice_id}, f)

def clean_markdown(text):
    if not text: return ""
    # 1. 去除 Markdown 标记
    text = re.sub(r'#+\s', '', text) # 标题
    text = re.sub(r'[\*_]{1,2}(.*?)[\*_]{1,2}', r'\1', text) # 加粗
    text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text) # 链接
    text = re.sub(r'!\[.*?\]\(.*?\)', '', text) # 图片

    # 2. 将所有换行符、Tab、连续空格都替换成单个空格
    text = re.sub(r'\s+', ' ', text)

    # 3. 去除汉字之间的空格
    # 正则解释：(?<=中文) 空格 (?=中文) -> 替换为空
    # \u4e00-\u9fa5 覆盖了常用汉字范围
    text = re.sub(r'(?<=[\u4e00-\u9fa5])\s+(?=[\u4e00-\u9fa5])', '', text)

    return text.strip()
def uninstall_app():
    print("\n\033[1;31m⚠️  正在执行卸载程序...\033[0m")
    confirm = input("确定要删除 tts 及其所有组件吗？(y/n): ")
    if confirm.lower() != 'y':
        print("已取消。")
        return

    # 1. 删除配置文件
    if os.path.exists(CONFIG_DIR):
        try:
            shutil.rmtree(CONFIG_DIR)
            print("✅ 已删除配置文件。")
        except Exception as e:
            print(f"❌ 删除配置失败: {e}")

    # 2. 删除软链接 (需要处理权限)
    if os.path.exists(LINK_PATH):
        try:
            os.remove(LINK_PATH)
            print("✅ 已删除命令链接。")
        except PermissionError:
            print(f"❌ 权限不足，无法删除 {LINK_PATH}。")
            print("   请稍后手动运行: sudo rm " + LINK_PATH)
        except Exception as e:
            print(f"❌ 删除链接失败: {e}")

    # 3. 删除安装目录
    # 注意：脚本自身在安装目录中运行，Linux下通常允许删除自身所在的目录索引
    if os.path.exists(INSTALL_DIR):
        try:
            shutil.rmtree(INSTALL_DIR)
            print(f"✅ 已删除安装目录: {INSTALL_DIR}")
        except Exception as e:
            print(f"❌ 删除安装目录失败: {e}")
            print(f"   请手动删除: rm -rf {INSTALL_DIR}")

    print("\n👋 卸载完成！感谢使用。")
    sys.exit(0)

def select_voice_ui():
    print("\n\033[1;36m=== 请选择你喜欢的语音助手 ===\033[0m")
    print(f"{'序号':<4} {'名字':<6} {'性别':<4} {'特点介绍'}")
    print("-" * 60)
    for i, v in enumerate(VOICES):
        print(f"[{i+1}]  {v['name']:<6} {v['gender']:<4} {v['desc']}")
    print("-" * 60)
    
    while True:
        try:
            choice = input("\n\033[1;32m请输入序号 (1-8): \033[0m")
            idx = int(choice) - 1
            if 0 <= idx < len(VOICES):
                selected = VOICES[idx]
                save_config(selected['id'])
                print(f"\n✅ 已切换为: \033[1;33m{selected['name']}\033[0m")
                break
            else:
                print("❌ 输入无效。")
        except ValueError:
            print("❌ 请输入数字。")

def split_text_smart(text, limit=4000):
    """智能切分长文本，避免超过 Edge-TTS 限制"""
    if len(text) <= limit:
        return [text]
    
    # 正则：按句号、感叹号、问号或换行符切分，并保留分隔符
    # (?<=...) 是后向肯定预查，确保分隔符包含在切分结果的前面部分（即句尾）
    sentences = re.split(r'(?<=[。！？!.?\n])', text)
    chunks = []
    current_chunk = ""
    
    for sentence in sentences:
        if len(current_chunk) + len(sentence) > limit:
            if current_chunk:
                chunks.append(current_chunk)
            current_chunk = sentence
        else:
            current_chunk += sentence
    
    if current_chunk:
        chunks.append(current_chunk)
    return chunks

def format_srt_time(ticks):
    """将 Edge-TTS 的 100ns 单位时间转换为 SRT 格式 (HH:MM:SS,mmm)"""
    seconds = ticks / 10000000
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    millis = int((seconds * 1000) % 1000)
    return f"{hours:02}:{minutes:02}:{secs:02},{millis:03}"

def is_latin(char):
    return 'a' <= char <= 'z' or 'A' <= char <= 'Z' or char.isdigit()

async def run_tts(text, output_file, rate, pitch, volume, gen_srt):
    config = load_config()
    voice_id = config.get("voice", "zh-CN-YunxiNeural")
    voice_name = next((v['name'] for v in VOICES if v['id'] == voice_id), "未知")
    
    chunks = split_text_smart(text)
    total_chunks = len(chunks)
    
    print(f"🎙️  声音: \033[1;35m{voice_name}\033[0m | 语速: {rate} | 音调: {pitch} | 音量: {volume}")
    print(f"    输出: \033[1;32m{output_file}\033[0m")
    
    srt_f = None
    if gen_srt:
        srt_file = os.path.splitext(output_file)[0] + ".srt"
        print(f"    字幕: \033[1;32m{srt_file}\033[0m")
        srt_f = open(srt_file, "w", encoding="utf-8")
        srt_index = 1
        global_offset = 0

    if total_chunks > 1:
        print(f"📦 长文本模式: 已自动切分为 {total_chunks} 个片段处理...")

    try:
        with open(output_file, "wb") as f:
            for i, chunk in enumerate(chunks):
                if not chunk.strip(): continue
                
                if total_chunks > 1:
                    sys.stdout.write(f"\r⏳ 正在合成片段 [{i+1}/{total_chunks}] ...")
                    sys.stdout.flush()

                # 字幕临时缓冲区
                sub_buffer = []
                chunk_last_timestamp = 0
                
                communicate = edge_tts.Communicate(chunk, voice_id, rate=rate, pitch=pitch, volume=volume, boundary="WordBoundary")
                
                async for message in communicate.stream():
                    if message["type"] == "audio":
                        f.write(message["data"])
                    elif message["type"] == "WordBoundary" and gen_srt:
                        # 计算全局时间
                        start_ticks = message["offset"] + global_offset
                        duration_ticks = message["duration"]
                        end_ticks = start_ticks + duration_ticks
                        word = message["text"]
                        
                        # 更新当前片段的最大时间戳，用于计算下一个片段的偏移量
                        chunk_last_timestamp = max(chunk_last_timestamp, message["offset"] + message["duration"])

                        # 简单的字幕分行逻辑：按标点或长度
                        sub_buffer.append({"start": start_ticks, "end": end_ticks, "text": word})
                        
                        # 如果遇到标点符号或者缓冲区太长，就写入一行字幕
                        # 常用标点: ，。？！；：, . ? ! ; :
                        is_punctuation = word.strip() in "，。？！；：,.?!;:"
                        # 或者当前行字数超过一定限制 (例如 20 个字符)
                        current_line_len = sum(len(w["text"]) for w in sub_buffer)
                        
                        if is_punctuation or current_line_len > 25:
                            # 写入 SRT
                            line_start = sub_buffer[0]["start"]
                            line_end = sub_buffer[-1]["end"]
                            
                            # 智能拼接，为英文单词间添加空格
                            line_text = ""
                            for j, w in enumerate(sub_buffer):
                                txt = w["text"]
                                if j > 0:
                                    prev_txt = sub_buffer[j-1]["text"]
                                    if prev_txt and txt and is_latin(prev_txt[-1]) and is_latin(txt[0]):
                                        line_text += " "
                                line_text += txt
                            
                            srt_f.write(f"{srt_index}\n")
                            srt_f.write(f"{format_srt_time(line_start)} --> {format_srt_time(line_end)}\n")
                            srt_f.write(f"{line_text}\n\n")
                            srt_f.flush()
                            
                            srt_index += 1
                            sub_buffer = []

                # 片段结束后，如果还有残留的字幕 buffer，全部写出
                if gen_srt and sub_buffer:
                    line_start = sub_buffer[0]["start"]
                    line_end = sub_buffer[-1]["end"]
                    
                    line_text = ""
                    for j, w in enumerate(sub_buffer):
                        txt = w["text"]
                        if j > 0:
                            prev_txt = sub_buffer[j-1]["text"]
                            if prev_txt and txt and is_latin(prev_txt[-1]) and is_latin(txt[0]):
                                line_text += " "
                        line_text += txt

                    srt_f.write(f"{srt_index}\n")
                    srt_f.write(f"{format_srt_time(line_start)} --> {format_srt_time(line_end)}\n")
                    srt_f.write(f"{line_text}\n\n")
                    srt_f.flush()
                    srt_index += 1

                # 更新下一段的起始偏移量
                # 这里加一个小缓冲 (e.g. 50ms = 500,000 ticks) 避免两段语音太紧凑
                if gen_srt:
                    global_offset += chunk_last_timestamp + 500000

        if gen_srt:
            srt_f.close()
            if srt_index == 1:
                print("⚠️  警告: 未生成任何字幕内容 (可能是文本过短或语音服务未返回时间戳)")

        if total_chunks > 1:
            print("")
        print(f"✅ 完成！")
    except Exception as e:
        print(f"\n❌ 合成失败: {str(e)}")
        if gen_srt and srt_f:
            srt_f.close()

async def process_single_file(file_path, output_file, args):
    print(f"📖 读取中: {file_path} ...")
    try:
        md = MarkItDown()
        result = md.convert(file_path)
        text_content = clean_markdown(result.text_content)
        if not text_content:
            print("⚠️  跳过: 未提取到有效文本。")
            return
        print(f"📝 提取到 {len(text_content)} 字")
        await run_tts(text_content, output_file, args.rate, args.pitch, args.volume, args.subtitle)
    except Exception as e:
        print(f"❌ 解析失败: {e}")
        print("💡 提示: 某些扫描版 PDF 可能需要系统安装 'poppler-utils' 或 'tesseract-ocr'。")

def main():
    # 使用 RawTextHelpFormatter 保持 Help 的格式不被自动换行打乱
    parser = argparse.ArgumentParser(
        description="TTS - 终端智能语音合成工具",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog=HELP_EPILOG
    )
    
    parser.add_argument("text", nargs="?", help="要转换的文本")
    parser.add_argument("--select", action="store_true", help="选择声音")
    parser.add_argument("-f", "--file", help="输入文件 (支持 .pdf, .docx, .md, .txt)")
    parser.add_argument("-o", "--out", default="output.mp3", help="输出文件名")
    parser.add_argument("-r", "--rate", default="+0%", help="语速 (如: +50%%, -20%%)")
    parser.add_argument("-p", "--pitch", default="+0Hz", help="音调 (如: +10Hz, -5Hz)")
    parser.add_argument("-v", "--volume", default="+0%", help="音量 (如: +10%%, -20%%)")
    parser.add_argument("-s", "--subtitle", action="store_true", help="生成 SRT 字幕文件")
    parser.add_argument("-u", "--uninstall", action="store_true", help="卸载本工具")
    parser.add_argument("-V", "--version", action="store_true", help="显示版本信息")
    
    args = parser.parse_args()

    if args.version:
        print("TTS 智能语音转换工具 v1.0")
        print("Author: 北落师门")
        print("Github: https://github.com/nanyuzuo")
        return

    if args.uninstall:
        uninstall_app()
        return

    if args.select:
        select_voice_ui()
        return

    if args.file:
        # 判断是文件还是目录
        if os.path.isdir(args.file):
            # 批量处理
            input_dir = args.file
            # 如果没指定 out 或 out 是默认值，则输出到原目录；否则输出到指定目录
            output_dir = args.out if args.out != "output.mp3" else input_dir
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)
            
            files = [f for f in os.listdir(input_dir) if f.lower().endswith(('.txt', '.md', '.pdf', '.docx'))]
            files.sort()
            total = len(files)
            
            if total == 0:
                print("⚠️  该目录下没有支持的文件 (.txt, .md, .pdf, .docx)")
                return
            
            print(f"📂 批量模式: 发现 {total} 个文件")
            print(f"📂 输出目录: {output_dir}")
            
            for i, fname in enumerate(files):
                f_path = os.path.join(input_dir, fname)
                out_name = os.path.splitext(fname)[0] + ".mp3"
                out_path = os.path.join(output_dir, out_name)
                
                print(f"\n--- [{i+1}/{total}] 处理: {fname} ---")
                asyncio.run(process_single_file(f_path, out_path, args))
                
        else:
            # 单文件处理
            if not os.path.exists(args.file):
                print(f"❌ 文件不存在: {args.file}")
                return
            asyncio.run(process_single_file(args.file, args.out, args))
            
    elif args.text:
        asyncio.run(run_tts(args.text, args.out, args.rate, args.pitch, args.volume, args.subtitle))
    else:
        parser.print_help()
        return

if __name__ == "__main__":
    main()
EOF

# 6. 重新创建 Wrapper
WRAPPER_PATH="$INSTALL_DIR/tts"
cat > "$WRAPPER_PATH" << EOF
#!/bin/bash
"$INSTALL_DIR/venv/bin/python" "$INSTALL_DIR/main.py" "\$@"
EOF
chmod +x "$WRAPPER_PATH"

# 7. 链接处理
if [ ! -f "$BIN_DIR/tts" ]; then
    echo -e "\033[1;33m正在将 'tts' 添加到系统命令 (可能需要密码)...\033[0m"
    sudo ln -sf "$WRAPPER_PATH" "$BIN_DIR/tts"
fi

echo -e "\n\033[1;32m✅ 久等啦，安装已完成！\033[0m"
echo -e "输入: \033[1;33mtts --help\033[0m 查看使用帮助。"
