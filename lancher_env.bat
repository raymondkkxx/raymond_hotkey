@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title 🚀 Master One-Click Script Deployment & Environment Setup
color 0b

echo ==============================================================================
echo                🚀 自动化环境安装与启动器部署中心
echo ==============================================================================
echo.

:: 1. 检查 Python 环境
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [CRITICAL ERROR] 未检测到 Python，请先安装 Python 并勾选 "Add to PATH"！
    pause
    exit /b
)

echo [1/3] 升级 Python 基础核心构建工具...
python -m pip install --upgrade pip setuptools wheel
echo.

:: 2. 批量循环安装 86 个依赖包
echo [2/3] 正在并行安装 86 个环境依赖包（使用清华镜像源加速）...
set "PACKAGES=altgraph==0.17.5 annotated-doc==0.0.4 annotated-types==0.8.0 anyio==4.14.2 bcrypt==5.0.0 beautifulsoup4==4.15.0 blinker==1.9.0 certifi==2026.7.22 cffi==2.1.0 charset-normalizer==3.4.9 click==8.4.2 colorama==0.4.6 cryptography==49.0.0 distro==1.9.0 fastapi==0.140.2 Flask==3.1.3 h11==0.16.0 httpcore==1.0.9 httpx==0.28.1 idna==3.18 invoke==3.0.3 itsdangerous==2.2.0 Jinja2==3.1.6 jiter==0.16.0 keyboard==0.13.5 Markdown==3.10.2 markdown-it-py==4.2.0 mdurl==0.1.2 MarkupSafe==3.0.3 MouseInfo==0.1.3 netmiko==4.7.0 paramiko==4.0.0 ntc_templates==9.2.0 openai==2.48.0 pydantic==2.13.4 typing_extensions==4.16.0 packaging==26.2 pefile==2024.8.26 pillow==12.3.0 psutil==7.2.2 PyAutoGUI==0.9.54 pycparser==3.0 pydantic_core==2.46.4 PyGetWindow==0.0.9 Pygments==2.20.0 pyinstaller==6.21.0 pyinstaller-hooks-contrib==2026.6 PyMsgBox==2.0.1 PyNaCl==1.6.2 pynput==1.8.2 pyperclip==1.11.0 PyQt5==5.15.11 PyQt5-Qt5==5.15.2 PyQt5_sip==12.18.0 PyQt6==6.11.0 PyQt6-Qt6==6.11.1 PyQt6_sip==13.11.1 PyQt6-WebEngine==6.11.0 PyQt6-WebEngine-Qt6==6.11.1 PyRect==0.2.0 PyScreeze==1.0.1 pyserial==3.5 pystray==0.19.5 python-dotenv==1.2.2 pytweening==1.2.0 pywin32==312 pywin32-ctypes==0.2.3 PyYAML==6.0.3 requests==2.34.2 urllib3==2.7.0 rich==15.0.0 ruamel.yaml==0.19.1 scp==0.16.0 setuptools==83.0.0 six==1.17.0 sniffio==1.3.1 soupsieve==2.9.1 starlette==1.3.1 textfsm==2.1.0 tqdm==4.70.0 typing-inspection==0.4.2 uvicorn==0.51.0 websockets==16.1.1 Werkzeug==3.1.8 WMI==1.5.1 customtkinter"

set TOTAL=86
set COUNT=1

for %%p in (%PACKAGES%) do (
    echo [!COUNT!/%TOTAL%] 安装: %%p
    pip install %%p -i https://pypi.tuna.tsinghua.edu.cn/simple >nul 2>&1
    set /a COUNT+=1
)
echo ✅ 86 个依赖包完全安装完成！
echo.

:: 3. 动态释放/生成最新的 MacStyleLauncher.pyw 启动器文件
echo [3/3] 正在生成并准备启动器界面...

(
echo import customtkinter as ctk
echo import json, os, sys, subprocess, winreg, logging
echo LOG_FILE = "launcher_error.log"
echo logging.basicConfig^(filename=LOG_FILE, level=logging.ERROR, format="%%^(asctime^)s - %%^(levelname^)s - %%^(message^)s", encoding="utf-8"^)
echo CONFIG_FILE = "launcher_config.json"
echo REG_PATH = r"Software\Microsoft\Windows\CurrentVersion\Run"
echo APP_NAME = "RaymondScriptLauncher"
echo ctk.set_appearance_mode^("Light"^)
echo BG_COLOR, CARD_COLOR, TEXT_MAIN, TEXT_SUB = "#F3F4F6", "#FFFFFF", "#111827", "#6B7280"
echo BTN_BLUE, BTN_BLUE_HOVER, BTN_WHITE, BTN_WHITE_HOVER = "#007AFF", "#0056b3", "#FFFFFF", "#F9FAFB"
echo BTN_RED, TEXT_RED, BTN_RED_HOVER, BORDER_COLOR = "#FEE2E2", "#DC2626", "#FECACA", "#E5E7EB"
echo FONT_FAMILY = "Microsoft YaHei UI"
echo class ScriptLauncherApp^(ctk.CTk^):
echo     def __init__^(self^):
echo         super^(^).__init__^(^)
echo         self.title^("Script Center"^)
echo         self.geometry^("680x550"^)
echo         self.resizable^(False, False^)
echo         self.configure^(fg_color=BG_COLOR^)
echo         self.update_idletasks^(^)
echo         x = ^(self.winfo_screenwidth^(^) // 2^) - ^(680 // 2^)
echo         y = ^(self.winfo_screenheight^(^) // 2^) - ^(550 // 2^)
echo         self.geometry^(f"+{x}+{y}"^)
echo         self.scripts = []
echo         self.auto_start_var = ctk.BooleanVar^(value=self.check_registry_autostart^(^)^)
echo         self.load_config^(^)
echo         self.build_ui^(^)
echo     def build_ui^(self^):
echo         self.header_frame = ctk.CTkFrame^(self, fg_color="transparent"^)
echo         self.header_frame.pack^(fill="x", padx=25, pady=^(25, 10^)^)
echo         self.title_label = ctk.CTkLabel^(self.header_frame, text="工作流自启中心", font=ctk.CTkFont^(family=FONT_FAMILY, size=26, weight="bold"^), text_color=TEXT_MAIN^)
echo         self.title_label.pack^(side="left"^)
echo         self.autostart_switch = ctk.CTkSwitch^(self.header_frame, text="开机静默拉起", variable=self.auto_start_var, command=self.toggle_autostart, font=ctk.CTkFont^(family=FONT_FAMILY, size=13, weight="bold"^), text_color=TEXT_MAIN, progress_color=BTN_BLUE^)
echo         self.autostart_switch.pack^(side="right", pady=5^)
echo         self.scroll_frame = ctk.CTkScrollableFrame^(self, fg_color="transparent", corner_radius=0^)
echo         self.scroll_frame.pack^(fill="both", expand=True, padx=20, pady=5^)
echo         self.refresh_list^(^)
echo         self.bottom_frame = ctk.CTkFrame^(self, fg_color="transparent"^)
echo         self.bottom_frame.pack^(fill="x", padx=25, pady=25^)
echo         self.add_btn = ctk.CTkButton^(self.bottom_frame, text="＋ 引入新脚本", font=ctk.CTkFont^(family=FONT_FAMILY, size=14, weight="bold"^), fg_color=BTN_WHITE, text_color=TEXT_MAIN, hover_color=BTN_WHITE_HOVER, border_width=1, border_color=BORDER_COLOR, height=40, command=self.add_script^)
echo         self.add_btn.pack^(side="left"^)
echo         self.run_btn = ctk.CTkButton^(self.bottom_frame, text="▶ 立即拉起所有脚本", font=ctk.CTkFont^(family=FONT_FAMILY, size=14, weight="bold"^), fg_color=BTN_BLUE, text_color="white", hover_color=BTN_BLUE_HOVER, height=40, command=self.test_run_all^)
echo         self.run_btn.pack^(side="right"^)
echo     def refresh_list^(self^):
echo         for widget in self.scroll_frame.winfo_children^(^): widget.destroy^(^)
echo         if not self.scripts:
echo             ctk.CTkLabel^(self.scroll_frame, text="当前没有自启任务，请点击下方按钮添加", text_color=TEXT_SUB, font=ctk.CTkFont^(family=FONT_FAMILY, size=14^)^).pack^(pady=40^)
echo             return
echo         for index, path in enumerate^(self.scripts^):
echo             item_frame = ctk.CTkFrame^(self.scroll_frame, fg_color=CARD_COLOR, corner_radius=12, border_width=1, border_color=BORDER_COLOR^)
echo             item_frame.pack^(fill="x", pady=6, padx=5^)
echo             filename = os.path.basename^(path^)
echo             text_col = TEXT_RED if not os.path.exists^(path^) else TEXT_MAIN
echo             if not os.path.exists^(path^): filename = f"⚠️ [路径失效] {filename}"
echo             info_frame = ctk.CTkFrame^(item_frame, fg_color="transparent"^)
echo             info_frame.pack^(side="left", padx=15, pady=12, fill="x", expand=True^)
echo             ctk.CTkLabel^(info_frame, text=filename, font=ctk.CTkFont^(family=FONT_FAMILY, size=15, weight="bold"^), text_color=text_col, anchor="w"^).pack^(fill="x"^)
echo             short_path = path if len^(path^) ^< 60 else path[:20] + " ... " + path[-35:]
echo             ctk.CTkLabel^(info_frame, text=short_path, text_color=TEXT_SUB, font=ctk.CTkFont^(family=FONT_FAMILY, size=11^), anchor="w"^).pack^(fill="x", pady=^(2, 0^)^)
echo             ctk.CTkButton^(item_frame, text="移除", width=60, height=28, font=ctk.CTkFont^(family=FONT_FAMILY, size=12, weight="bold"^), fg_color=BTN_RED, text_color=TEXT_RED, hover_color=BTN_RED_HOVER, command=lambda i=index: self.remove_script^(i^)^).pack^(side="right", padx=15^)
echo     def add_script^(self^):
echo         from tkinter import filedialog
echo         fp = filedialog.askopenfilename^(title="选择要自启的工作流脚本", filetypes=[^("支持的脚本", "*.ahk *.py *.pyw *.bat *.cmd *.vbs"^)]^)
echo         if fp:
echo             fp = os.path.normpath^(fp^)
echo             if fp not in self.scripts: self.scripts.append^(fp^); self.save_config^(^); self.refresh_list^(^)
echo     def remove_script^(self, index^): self.scripts.pop^(index^); self.save_config^(^); self.refresh_list^(^)
echo     def load_config^(self^):
echo         if os.path.exists^(CONFIG_FILE^):
echo             try:
echo                 with open^(CONFIG_FILE, 'r', encoding='utf-8'^) as f: self.scripts = json.load^(f^)
echo             except: self.scripts = []
echo     def save_config^(self^):
echo         with open^(CONFIG_FILE, 'w', encoding='utf-8'^) as f: json.dump^(self.scripts, f, indent=4, ensure_ascii=False^)
echo     def check_registry_autostart^(self^):
echo         try:
echo             key = winreg.OpenKey^(winreg.HKEY_CURRENT_USER, REG_PATH, 0, winreg.KEY_READ^)
echo             winreg.QueryValueEx^(key, APP_NAME^)
echo             winreg.CloseKey^(key^)
echo             return True
echo         except: return False
echo     def toggle_autostart^(self^):
echo         try:
echo             key = winreg.OpenKey^(winreg.HKEY_CURRENT_USER, REG_PATH, 0, winreg.KEY_SET_VALUE^)
echo             if self.auto_start_var.get^(^):
echo                 exe_path = sys.executable.replace^("python.exe", "pythonw.exe"^)
echo                 cmd = f'"{exe_path}" "{os.path.abspath(sys.argv[0])}" --silent'
echo                 winreg.SetValueEx^(key, APP_NAME, 0, winreg.REG_SZ, cmd^)
echo             else: winreg.DeleteValue^(key, APP_NAME^)
echo             winreg.CloseKey^(key^)
echo         except Exception as e:
echo             from tkinter import messagebox
echo             messagebox.showerror^("权限异常", f"无法写入注册表:\n{e}"^)
echo             self.auto_start_var.set^(not self.auto_start_var.get^(^)^)
echo     def test_run_all^(self^):
echo         run_all_scripts^(is_test=True^)
echo         from tkinter import messagebox
echo         messagebox.showinfo^("拉起指令已下发", "所有有效脚本已尝试在后台独立拉起。"^)
echo def run_all_scripts^(is_test=False^):
echo     if not os.path.exists^(CONFIG_FILE^): return
echo     try:
echo         with open^(CONFIG_FILE, 'r', encoding='utf-8'^) as f: scripts = json.load^(f^)
echo     except: return
echo     for path in scripts:
echo         if not os.path.exists^(path^): continue
echo         ext = os.path.splitext^(path^)[1].lower^(^)
echo         script_dir = os.path.dirname^(path^)
echo         try:
echo             if ext in ['.py', '.pyw']:
echo                 subprocess.Popen^(f'cmd.exe /c set PYTHONIOENCODING=utf-8 ^&^& python "{path}"', shell=True, cwd=script_dir, creationflags=subprocess.CREATE_NO_WINDOW^)
echo             elif ext == '.ahk':
echo                 subprocess.Popen^(f'cmd.exe /c start "" "{path}"', shell=True, cwd=script_dir, creationflags=subprocess.CREATE_NO_WINDOW^)
echo             elif ext in ['.bat', '.cmd']:
echo                 subprocess.Popen^(f'cmd.exe /c "{path}"', shell=True, cwd=script_dir, creationflags=subprocess.CREATE_NO_WINDOW^)
echo             elif ext == '.vbs':
echo                 subprocess.Popen^(f'wscript.exe "{path}"', shell=True, cwd=script_dir, creationflags=subprocess.CREATE_NO_WINDOW^)
echo         except Exception as e: logging.error^(f"Failed {path}: {e}"^)
echo if __name__ == "__main__":
echo     if len^(sys.argv^) ^> 1 and sys.argv[1] == "--silent":
echo         run_all_scripts^(^)
echo         sys.exit^(^)
echo     app = ScriptLauncherApp^(^)
echo     app.mainloop^(^)
) > MacStyleLauncher.pyw

echo ✅ 启动器生成完成！正在启动图形面板...
start pythonw MacStyleLauncher.pyw
exit