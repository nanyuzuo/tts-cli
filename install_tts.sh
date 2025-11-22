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

# 1. 检查 Python3
if ! command -v python3 &> /dev/null; then
    echo -e "\033[1;31m错误: 未检测到 Python3，请先安装。\033[0m"
    exit 1
fi

# 2. 创建目录
mkdir -p "$INSTALL_DIR"
mkdir -p "$CONFIG_DIR"

# 3. 创建虚拟环境 (如果不存在)
if [ ! -d "$INSTALL_DIR/venv" ]; then
    echo -e "\033[1;33m-> 创建独立运行环境...\033[0m"
    python3 -m venv "$INSTALL_DIR/venv"
fi

# 使用 markitdown[all] 确保支持 PDF, Word, Excel, OCR 等所有格式
echo -e "\033[1;33m-> 正在安装/更新依赖 (含 PDF/Word 解析库，可能需要几分钟)...\033[0m"
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip --quiet
# 注意：这里加上了 [all] 并使用了引号
"$INSTALL_DIR/venv/bin/pip" install edge-tts "markitdown[all]" --quiet

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
2. 文本转语音: \033[1;33mtts "你好，世界" --out hi.mp3\033[0m
3. 文档转语音: \033[1;33mtts --file 报告.pdf --out report.mp3\033[0m
4. 卸载应用: \033[1;31mtts --uninstall\033[0m
5. 查看帮助: \033[1;33mtts --help\033[0m
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

async def run_tts(text, output_file):
    config = load_config()
    voice_id = config.get("voice", "zh-CN-YunxiNeural")
    voice_name = next((v['name'] for v in VOICES if v['id'] == voice_id), "未知")
    
    print(f"🎙️  声音: \033[1;35m{voice_name}\033[0m | 输出: \033[1;32m{output_file}\033[0m")
    try:
        communicate = edge_tts.Communicate(text, voice_id)
        await communicate.save(output_file)
        print(f"✅ 完成！")
    except Exception as e:
        print(f"\n❌ 合成失败: {str(e)}")

def main():
    # 使用 RawTextHelpFormatter 保持 Help 的格式不被自动换行打乱
    parser = argparse.ArgumentParser(
        description="TTS - 终端智能语音合成工具",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog=HELP_EPILOG
    )
    
    parser.add_argument("text", nargs="?", help="要转换的文本")
    parser.add_argument("--select", action="store_true", help="选择声音")
    parser.add_argument("--file", help="输入文件 (支持 .pdf, .docx, .md, .txt)")
    parser.add_argument("--out", default="output.mp3", help="输出文件名")
    parser.add_argument("--uninstall", action="store_true", help="卸载本工具")
    
    args = parser.parse_args()

    if args.uninstall:
        uninstall_app()
        return

    if args.select:
        select_voice_ui()
        return

    text_content = ""
    if args.file:
        if not os.path.exists(args.file):
            print(f"❌ 文件不存在: {args.file}")
            return
        
        print(f"📖 读取中: {args.file} ...")
        try:
            md = MarkItDown()
            result = md.convert(args.file)
            text_content = clean_markdown(result.text_content)
            if not text_content:
                print("⚠️  警告: 未提取到有效文本。")
                return
            print(f"📝 提取到 {len(text_content)} 字")
        except Exception as e:
            print(f"❌ 解析失败: {e}")
            print("💡 提示: 某些扫描版 PDF 可能需要系统安装 'poppler-utils' 或 'tesseract-ocr'。")
            return
            
    elif args.text:
        text_content = args.text
    else:
        parser.print_help()
        return

    if text_content:
        asyncio.run(run_tts(text_content, args.out))

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
