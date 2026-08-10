import sys
import json
import os
from PyQt5.QtWidgets import (QApplication, QWidget, QVBoxLayout, QHBoxLayout, 
                             QListWidget, QLineEdit, QTextEdit, QTextBrowser, 
                             QPushButton, QSplitter, QMessageBox, QLabel, QRadioButton, QButtonGroup, QFrame)
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QIcon, QFont, QPixmap
import markdown

BASE_DIR = os.path.dirname(os.path.abspath(sys.argv[0]))
DB_FILE = os.path.join(BASE_DIR, "prompts.json")
ACTIVE_FILE = os.path.join(BASE_DIR, "active_prompt.txt")

DEFAULT_PROMPTS = [
    {"title": "翻译润色", "prompt": "请帮我把以下内容翻译成中文，要求语言流畅、地道，并解释其中的专业术语：", "mode": 0},
    {"title": "代码审查", "prompt": "请帮我审查上述代码，指出潜在的 Bug、性能隐患，并给出优化建议：", "mode": 1}
]

MODERN_STYLE = """
QWidget {
    font-family: 'Microsoft YaHei', 'Segoe UI', sans-serif;
    font-size: 14px;
    color: #1f2937;
    background-color: #f3f4f6;
}
QListWidget {
    background-color: #ffffff;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    padding: 5px;
    outline: none;
}
QListWidget::item {
    padding: 12px;
    border-radius: 6px;
    margin-bottom: 4px;
    color: #4b5563;
}
QListWidget::item:selected {
    background-color: #eff6ff;
    color: #2563eb;
    font-weight: bold;
    border-left: 4px solid #3b82f6;
}
QListWidget::item:hover:!selected {
    background-color: #f9fafb;
}
QPushButton {
    background-color: #ffffff;
    border: 1px solid #d1d5db;
    border-radius: 6px;
    padding: 8px 12px;
    color: #374151;
    font-weight: 500;
}
QPushButton:hover {
    background-color: #f3f4f6;
    border-color: #9ca3af;
}
QPushButton#primaryBtn {
    background-color: #3b82f6;
    color: white;
    border: none;
    font-size: 15px;
    font-weight: bold;
    border-radius: 8px;
}
QPushButton#primaryBtn:hover {
    background-color: #2563eb;
}
QLineEdit, QTextEdit {
    background-color: #ffffff;
    border: 1px solid #d1d5db;
    border-radius: 8px;
    padding: 10px;
    color: #111827;
}
QLineEdit:focus, QTextEdit:focus {
    border: 1px solid #3b82f6;
    background-color: #ffffff;
}
QTextBrowser {
    background-color: #f8fafc;
    border: 1px dashed #94a3b8;
    border-radius: 8px;
    padding: 15px;
}
QLabel {
    font-weight: bold;
    color: #4b5563;
}
QLabel#subText {
    font-weight: normal;
    color: #6b7280;
    font-size: 12px;
}
QRadioButton {
    spacing: 8px;
    font-weight: normal;
    color: #374151;
}
"""

class PromptEditor(QWidget):
    def __init__(self):
        super().__init__()
        self.prompts = self.load_data()
        self.current_index = -1
        self.init_ui()
        
    def init_ui(self):
        self.setWindowTitle("Gemini 提示词管理器")
        self.resize(1050, 650)
        self.setStyleSheet(MODERN_STYLE)
        
        transparent_pixmap = QPixmap(1, 1)
        transparent_pixmap.fill(Qt.transparent)
        self.setWindowIcon(QIcon(transparent_pixmap))
        
        main_layout = QHBoxLayout(self)
        main_layout.setContentsMargins(20, 20, 20, 20)
        main_layout.setSpacing(20)
        
        # ================= 左侧面板 =================
        left_panel = QFrame()
        left_layout = QVBoxLayout(left_panel)
        left_layout.setContentsMargins(0, 0, 0, 0)
        
        title_label = QLabel("📚 提示词库")
        title_label.setStyleSheet("font-size: 16px; margin-bottom: 5px;")
        left_layout.addWidget(title_label)
        
        self.list_widget = QListWidget()
        self.list_widget.currentRowChanged.connect(self.load_prompt)
        left_layout.addWidget(self.list_widget)
        
        btn_layout = QHBoxLayout()
        add_btn = QPushButton("➕ 新建")
        del_btn = QPushButton("🗑️ 删除")
        add_btn.clicked.connect(self.add_prompt)
        del_btn.clicked.connect(self.del_prompt)
        btn_layout.addWidget(add_btn)
        btn_layout.addWidget(del_btn)
        left_layout.addLayout(btn_layout)
        
        # ================= 右侧面板 =================
        right_panel = QFrame()
        right_layout = QVBoxLayout(right_panel)
        right_layout.setContentsMargins(0, 0, 0, 0)
        right_layout.setSpacing(15)
        
        # 【修复关键 1】：将上方的配置项打包进一个不允许拉伸的顶层容器
        top_container = QWidget()
        top_layout = QVBoxLayout(top_container)
        top_layout.setContentsMargins(0, 0, 0, 0)
        top_layout.setSpacing(15)
        
        title_layout = QHBoxLayout()
        title_layout.addWidget(QLabel("🔖 备注名:"))
        self.title_edit = QLineEdit()
        self.title_edit.setPlaceholderText("给这个提示词起个名字...")
        self.title_edit.textChanged.connect(self.update_title)
        title_layout.addWidget(self.title_edit)
        top_layout.addLayout(title_layout)
        
        mode_layout = QHBoxLayout()
        mode_layout.addWidget(QLabel("⚙️ 排版模式:"))
        self.radio_prompt_first = QRadioButton("[提示词] 在前，[划词内容] 在后")
        self.radio_content_first = QRadioButton("[划词内容] 在前，[提示词] 在后")
        
        self.mode_group = QButtonGroup()
        self.mode_group.addButton(self.radio_prompt_first, 0)
        self.mode_group.addButton(self.radio_content_first, 1)
        self.mode_group.buttonClicked.connect(self.update_mode)
        
        mode_layout.addWidget(self.radio_prompt_first)
        mode_layout.addWidget(self.radio_content_first)
        mode_layout.addStretch()
        top_layout.addLayout(mode_layout)
        
        tip_label = QLabel("✨ 直接输入提示词内容（无需任何占位符），右侧自动渲染预览：")
        tip_label.setObjectName("subText")
        top_layout.addWidget(tip_label)
        
        # 将紧凑的顶部容器加入右侧布局
        right_layout.addWidget(top_container)
        
        # 【修复关键 2】：创建占据剩余所有空间的 Splitter (编辑器)
        splitter = QSplitter(Qt.Horizontal)
        
        self.editor = QTextEdit()
        self.editor.setFont(QFont("Microsoft YaHei", 12))
        self.editor.setPlaceholderText("在这里输入你的提示词指令...")
        self.editor.textChanged.connect(self.update_preview)
        
        self.preview = QTextBrowser()
        
        splitter.addWidget(self.editor)
        splitter.addWidget(self.preview)
        splitter.setSizes([350, 450])
        
        # 注意此处的 ', 1'，强制要求代码框吸收所有放大窗口时的多余垂直空间
        right_layout.addWidget(splitter, 1)
        
        # 底部保存按钮
        save_btn = QPushButton("🚀 设为激活状态并关闭")
        save_btn.setObjectName("primaryBtn")
        save_btn.setMinimumHeight(45)
        save_btn.clicked.connect(self.save_and_activate)
        right_layout.addWidget(save_btn)
        
        # 组装全局
        main_splitter = QSplitter(Qt.Horizontal)
        main_splitter.addWidget(left_panel)
        main_splitter.addWidget(right_panel)
        main_splitter.setSizes([220, 780])
        main_splitter.setHandleWidth(20)
        main_layout.addWidget(main_splitter)
        
        self.refresh_list()
        if self.prompts:
            self.list_widget.setCurrentRow(0)

    def load_data(self):
        if os.path.exists(DB_FILE):
            try:
                with open(DB_FILE, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except:
                pass
        return DEFAULT_PROMPTS.copy()

    def save_data(self):
        with open(DB_FILE, 'w', encoding='utf-8') as f:
            json.dump(self.prompts, f, ensure_ascii=False, indent=4)

    def refresh_list(self):
        self.list_widget.clear()
        for p in self.prompts:
            self.list_widget.addItem(p["title"])

    def load_prompt(self, index):
        if index < 0 or index >= len(self.prompts): return
        self.current_index = index
        self.title_edit.setText(self.prompts[index]["title"])
        
        self.editor.blockSignals(True)
        self.editor.setText(self.prompts[index]["prompt"])
        self.editor.blockSignals(False)
        
        mode = self.prompts[index].get("mode", 0)
        if mode == 0:
            self.radio_prompt_first.setChecked(True)
        else:
            self.radio_content_first.setChecked(True)
            
        self.update_preview()

    def update_title(self, text):
        if self.current_index >= 0:
            self.prompts[self.current_index]["title"] = text
            self.list_widget.item(self.current_index).setText(text)

    def update_mode(self, btn):
        if self.current_index >= 0:
            self.prompts[self.current_index]["mode"] = self.mode_group.id(btn)
            self.update_preview()

    def update_preview(self):
        if self.current_index >= 0:
            prompt_text = self.editor.toPlainText()
            self.prompts[self.current_index]["prompt"] = prompt_text
            mode = self.prompts[self.current_index].get("mode", 0)
            
            rendered_prompt = markdown.markdown(prompt_text, extensions=['fenced_code'])
            
            dummy_text = """
            <div style='color: #64748b; border-left: 4px solid #94a3b8; padding: 12px; margin: 15px 0; background-color: #f1f5f9; border-radius: 0 6px 6px 0; font-family: Consolas, monospace;'>
                <em>...（此处将自动填入你鼠标划选的文本或代码）...</em>
            </div>
            """
            
            if mode == 0:
                html = f"<div style='margin-bottom:10px;'>{rendered_prompt}</div>{dummy_text}"
            else:
                html = f"{dummy_text}<div style='margin-top:10px;'>{rendered_prompt}</div>"
                
            self.preview.setHtml(html)

    def add_prompt(self):
        self.prompts.append({"title": "新建提示词", "prompt": "输入提示词...", "mode": 0})
        self.refresh_list()
        self.list_widget.setCurrentRow(len(self.prompts) - 1)

    def del_prompt(self):
        if self.current_index >= 0 and len(self.prompts) > 1:
            del self.prompts[self.current_index]
            self.refresh_list()
            self.list_widget.setCurrentRow(0)

    def save_and_activate(self):
        self.save_data()
        if self.current_index >= 0:
            prompt_text = self.prompts[self.current_index]["prompt"]
            mode = self.prompts[self.current_index]["mode"]
            
            if mode == 0:
                final_content = f"{prompt_text}\n\n{{text}}"
            else:
                final_content = f"{{text}}\n\n{prompt_text}"
                
            with open(ACTIVE_FILE, 'w', encoding='utf-8') as f:
                f.write(final_content)
        self.close()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    editor = PromptEditor()
    editor.show()
    sys.exit(app.exec_())