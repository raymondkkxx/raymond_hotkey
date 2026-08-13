import customtkinter as ctk
import json
import os
import sys
import subprocess
import winreg
import logging
from datetime import datetime
from tkinter import filedialog, messagebox

# ==========================================
# 稳定性提升：全局日志配置
# ==========================================
LOG_FILE = "launcher_error.log"
logging.basicConfig(
    filename=LOG_FILE, 
    level=logging.ERROR,
    format="%(asctime)s - %(levelname)s - %(message)s",
    encoding="utf-8"
)

# ==========================================
# 全局配置 & UI 主题色规范 (Mac/Fluent 质感)
# ==========================================
CONFIG_FILE = "launcher_config.json"
REG_PATH = r"Software\Microsoft\Windows\CurrentVersion\Run"
APP_NAME = "RaymondScriptLauncher"

# 强制浅色模式
ctk.set_appearance_mode("Light") 

# 自定义高级色板
BG_COLOR = "#F3F4F6"         # 全局浅灰色背景，突出上方卡片
CARD_COLOR = "#FFFFFF"       # 卡片纯白背景
TEXT_MAIN = "#111827"        # 深黑主文本
TEXT_SUB = "#6B7280"         # 灰色次文本
BTN_BLUE = "#007AFF"         # Mac系统蓝 (主按钮)
BTN_BLUE_HOVER = "#0056b3"
BTN_WHITE = "#FFFFFF"        # 白色次按钮
BTN_WHITE_HOVER = "#F9FAFB"
BTN_RED = "#FEE2E2"          # 浅红警示按钮 (用于移除)
TEXT_RED = "#DC2626"
BTN_RED_HOVER = "#FECACA"
BORDER_COLOR = "#E5E7EB"     # 细微的边框颜色

# 全局字体族
FONT_FAMILY = "Microsoft YaHei UI"

class ScriptLauncherApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("Script Center")
        self.geometry("680x550")
        self.resizable(False, False)
        self.configure(fg_color=BG_COLOR) # 设置主背景为浅灰色
        
        # 居中窗口
        self.update_idletasks()
        x = (self.winfo_screenwidth() // 2) - (680 // 2)
        y = (self.winfo_screenheight() // 2) - (550 // 2)
        self.geometry(f"+{x}+{y}")

        self.scripts = []
        self.auto_start_var = ctk.BooleanVar(value=self.check_registry_autostart())

        self.load_config()
        self.build_ui()

    def build_ui(self):
        # --- 顶部 Header ---
        self.header_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.header_frame.pack(fill="x", padx=25, pady=(25, 10))
        
        self.title_label = ctk.CTkLabel(
            self.header_frame, 
            text="工作流自启中心", 
            font=ctk.CTkFont(family=FONT_FAMILY, size=26, weight="bold"),
            text_color=TEXT_MAIN
        )
        self.title_label.pack(side="left")

        self.autostart_switch = ctk.CTkSwitch(
            self.header_frame, 
            text="开机静默拉起", 
            variable=self.auto_start_var, 
            command=self.toggle_autostart,
            font=ctk.CTkFont(family=FONT_FAMILY, size=13, weight="bold"),
            text_color=TEXT_MAIN,
            progress_color=BTN_BLUE
        )
        self.autostart_switch.pack(side="right", pady=5)

        # --- 中间列表区 (Scrollable Frame) ---
        # 背景设为透明，让里面的白卡片悬浮在浅灰底色上
        self.scroll_frame = ctk.CTkScrollableFrame(
            self, 
            fg_color="transparent", 
            corner_radius=0
        )
        self.scroll_frame.pack(fill="both", expand=True, padx=20, pady=5)

        self.refresh_list()

        # --- 底部 Footer 控制区 ---
        self.bottom_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.bottom_frame.pack(fill="x", padx=25, pady=25)

        # 添加按钮 (清爽白底灰边)
        self.add_btn = ctk.CTkButton(
            self.bottom_frame, 
            text="＋ 引入新脚本", 
            font=ctk.CTkFont(family=FONT_FAMILY, size=14, weight="bold"),
            fg_color=BTN_WHITE, 
            text_color=TEXT_MAIN,
            hover_color=BTN_WHITE_HOVER,
            border_width=1,
            border_color=BORDER_COLOR,
            height=40,
            command=self.add_script
        )
        self.add_btn.pack(side="left")

        # 运行按钮 (Mac蓝色)
        self.run_btn = ctk.CTkButton(
            self.bottom_frame, 
            text="▶ 立即拉起所有脚本", 
            font=ctk.CTkFont(family=FONT_FAMILY, size=14, weight="bold"),
            fg_color=BTN_BLUE, 
            text_color="white",
            hover_color=BTN_BLUE_HOVER, 
            height=40,
            command=self.test_run_all
        )
        self.run_btn.pack(side="right")

    def refresh_list(self):
        for widget in self.scroll_frame.winfo_children():
            widget.destroy()
            
        if not self.scripts:
            empty_label = ctk.CTkLabel(
                self.scroll_frame, 
                text="当前没有自启任务，请点击下方按钮添加", 
                text_color=TEXT_SUB,
                font=ctk.CTkFont(family=FONT_FAMILY, size=14)
            )
            empty_label.pack(pady=40)
            return

        for index, path in enumerate(self.scripts):
            # 卡片容器 (Card UI)
            item_frame = ctk.CTkFrame(
                self.scroll_frame, 
                fg_color=CARD_COLOR,
                corner_radius=12,
                border_width=1,
                border_color=BORDER_COLOR
            )
            item_frame.pack(fill="x", pady=6, padx=5)
            
            filename = os.path.basename(path)
            
            # 检测丢失状态
            if not os.path.exists(path):
                filename = f"⚠️ [路径失效] {filename}"
                text_col = TEXT_RED
            else:
                text_col = TEXT_MAIN

            # 左侧信息区
            info_frame = ctk.CTkFrame(item_frame, fg_color="transparent")
            info_frame.pack(side="left", padx=15, pady=12, fill="x", expand=True)

            name_label = ctk.CTkLabel(
                info_frame, 
                text=filename, 
                font=ctk.CTkFont(family=FONT_FAMILY, size=15, weight="bold"), 
                text_color=text_col,
                anchor="w"
            )
            name_label.pack(fill="x")
            
            # 优雅的缩略路径显示
            short_path = path if len(path) < 60 else path[:20] + " ... " + path[-35:]
            path_label = ctk.CTkLabel(
                info_frame, 
                text=short_path, 
                text_color=TEXT_SUB, 
                font=ctk.CTkFont(family=FONT_FAMILY, size=11),
                anchor="w"
            )
            path_label.pack(fill="x", pady=(2, 0))

            # 右侧移除按钮 (柔和的微红配色)
            del_btn = ctk.CTkButton(
                item_frame, 
                text="移除", 
                width=60, 
                height=28,
                font=ctk.CTkFont(family=FONT_FAMILY, size=12, weight="bold"),
                fg_color=BTN_RED, 
                text_color=TEXT_RED,
                hover_color=BTN_RED_HOVER,
                command=lambda i=index: self.remove_script(i)
            )
            del_btn.pack(side="right", padx=15)

    def add_script(self):
        file_path = filedialog.askopenfilename(
            title="选择要自启的工作流脚本",
            filetypes=[
                ("支持的脚本", "*.ahk *.py *.pyw *.bat *.cmd *.vbs"), 
                ("AutoHotkey", "*.ahk"), 
                ("Python", "*.py *.pyw"),
                ("批处理", "*.bat *.cmd"),
                ("VBScript", "*.vbs")
            ]
        )
        if file_path:
            file_path = os.path.normpath(file_path)
            if file_path not in self.scripts:
                self.scripts.append(file_path)
                self.save_config()
                self.refresh_list()
            else:
                messagebox.showinfo("提示", "该脚本已在执行队列中！")

    def remove_script(self, index):
        self.scripts.pop(index)
        self.save_config()
        self.refresh_list()

    def load_config(self):
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
                    self.scripts = json.load(f)
            except Exception as e:
                logging.error(f"Failed to load config: {e}")
                self.scripts = []

    def save_config(self):
        try:
            with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
                json.dump(self.scripts, f, indent=4, ensure_ascii=False)
        except Exception as e:
            logging.error(f"Failed to save config: {e}")

    def check_registry_autostart(self):
        try:
            key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, REG_PATH, 0, winreg.KEY_READ)
            winreg.QueryValueEx(key, APP_NAME)
            winreg.CloseKey(key)
            return True
        except WindowsError:
            return False

    def toggle_autostart(self):
        try:
            key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, REG_PATH, 0, winreg.KEY_SET_VALUE)
            if self.auto_start_var.get():
                exe_path = sys.executable.replace("python.exe", "pythonw.exe")
                script_path = os.path.abspath(sys.argv[0])
                cmd = f'"{exe_path}" "{script_path}" --silent'
                winreg.SetValueEx(key, APP_NAME, 0, winreg.REG_SZ, cmd)
            else:
                winreg.DeleteValue(key, APP_NAME)
            winreg.CloseKey(key)
        except Exception as e:
            logging.error(f"Registry modification failed: {e}")
            messagebox.showerror("权限异常", f"无法写入注册表，修改开机自启项失败:\n{e}")
            self.auto_start_var.set(not self.auto_start_var.get()) 

    def test_run_all(self):
        run_all_scripts(is_test=True)
        messagebox.showinfo("拉起指令已下发", "所有有效脚本已尝试在后台独立拉起。\n\n如遇脚本未运行，请检查脚本内语法是否正确，或查阅本目录的 launcher_error.log 日志文件。")


# ==========================================
# 核心执行引擎：多脚本并发独立拉起
# ==========================================
def run_all_scripts(is_test=False):
    if not os.path.exists(CONFIG_FILE):
        return
        
    try:
        with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
            scripts = json.load(f)
    except Exception as e:
        logging.error(f"Runtime failed to read config: {e}")
        return
        
    for path in scripts:
        if not os.path.exists(path):
            logging.error(f"Skipped missing script: {path}")
            continue
            
        ext = os.path.splitext(path)[1].lower()
        script_dir = os.path.dirname(path)
        
        try:
            if ext in ['.py', '.pyw']:
                cmd = f'cmd.exe /c set PYTHONIOENCODING=utf-8 && python "{path}"'
                subprocess.Popen(cmd, shell=True, cwd=script_dir, creationflags=subprocess.CREATE_NO_WINDOW)
                
            elif ext == '.ahk':
                cmd = f'cmd.exe /c start "" "{path}"'
                subprocess.Popen(cmd, shell=True, cwd=script_dir, creationflags=subprocess.CREATE_NO_WINDOW)
                
            elif ext in ['.bat', '.cmd']:
                cmd = f'cmd.exe /c "{path}"'
                subprocess.Popen(cmd, shell=True, cwd=script_dir, creationflags=subprocess.CREATE_NO_WINDOW)
                
            elif ext == '.vbs':
                cmd = f'wscript.exe "{path}"'
                subprocess.Popen(cmd, shell=True, cwd=script_dir, creationflags=subprocess.CREATE_NO_WINDOW)

        except Exception as e:
            logging.error(f"Failed to execute {path}. Reason: {str(e)}")


# ==========================================
# 程序主入口
# ==========================================
if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--silent":
        # 开机静默模式
        run_all_scripts()
        sys.exit()
    
    # 手动启动：展示现代化操作面板
    app = ScriptLauncherApp()
    app.mainloop()