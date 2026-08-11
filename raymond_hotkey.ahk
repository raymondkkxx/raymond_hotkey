#Requires AutoHotkey v2.0
#SingleInstance Force
ListLines 0

; ==============================================================================
;                  【一、 ⚙️ 全局用户配置控制台 (USER CONFIG)】
;     说明：所有需要微调的坐标、时间阈值、程序与图标路径均在此修改，改后 Ctrl+S 生效
; ==============================================================================

; --- [1.1] 悬浮窗相对鼠标的偏移坐标 (X轴：正向右/负向左 | Y轴：正向下/负向上) ---
global CFG_PromptOffsetX    := -180   ; [Gemini 提示词窗] 默认处于鼠标右方 15px
global CFG_PromptOffsetY    := -57    ; [Gemini 提示词窗] 默认处于鼠标上方 57px

global CFG_GeminiOffsetX    := -60    ; [Gemini 直接上传] 默认处于鼠标左方 60px
global CFG_GeminiOffsetY    := -60    ; [Gemini 直接上传] 默认处于鼠标上方 60px

global CFG_YouGlishOffsetX  := -40    ; [YouGlish 发音搜索] 默认处于鼠标左方 40px (注：代码内已额外扣除图标自身宽度以保证向左延展)
global CFG_YouGlishOffsetY  := 20     ; [YouGlish 发音搜索] 默认处于鼠标下方 15px (注：代码内已额外扣除图标一半高度以保证居中)

global CFG_CopiedOffsetX    := 100    ; [Copied 成功提示] 默认处于鼠标右方 70px
global CFG_CopiedOffsetY    := 50     ; [Copied 成功提示] 默认处于鼠标上方 2px

; --- [1.2] 防误触与划词参数 ---
global MIN_DRAG_X           := 35     ; 触发复制的最小水平移动距离 (像素)
global MIN_DRAG_Y           := 45     ; 触发复制的最小垂直移动距离 (像素)
global MIN_DRAG_TIME_MS     := 50     ; 触发复制的最小拖拽时间 (毫秒)
global MAX_DRAG_TIME_MS     := 15000  ; 触发复制的最大拖拽时间 (毫秒)
global ESC_LONG_PRESS_MS    := 400    ; 长按 Esc 接管左键关闭窗口的时限 (毫秒)

; --- [1.3] 路径管理：基础目录与关键程序 ---
global PATH_AppDir          := "C:\Users\raymond\WPSDrive\1158436994\WPS云盘\Raymond_Workstation\chrome_app\"
global PATH_Chrome          := "C:\Program Files\Google\Chrome\Application\chrome.exe"
global PATH_EditorExe       := A_ScriptDir "\GeminiPromptEditor.exe"
global PATH_ActivePrompt    := A_ScriptDir "\active_prompt.txt"

; --- [1.4] 路径管理：图示与按钮素材 ---
global ICON_Prompt          := PATH_AppDir "programfiles\photo\gemini_prompt.png"
global ICON_Gemini          := PATH_AppDir "programfiles\photo\gemini.png"
global ICON_YouGlish        := PATH_AppDir "programfiles\photo\youglish_auto_load.png"
global ICON_Copied          := PATH_AppDir "programfiles\photo\copied.png"

; --- [1.5] 路径管理：快捷启动软件与脚本链接 ---
global APP_GeminiLnk        := PATH_AppDir "Gemini.lnk"
global APP_YouGlishLnk      := PATH_AppDir "youglish.lnk"
global APP_DouYin           := PATH_AppDir "抖音.lnk"
global APP_YouTube          := PATH_AppDir "YouTube.lnk"
global APP_Bilibili         := PATH_AppDir "bilibili.lnk"
global APP_Wps              := PATH_AppDir "WPS听记.lnk"
global APP_WxSrf            := PATH_AppDir "微信输入法.lnk"
global APP_Zhihu            := PATH_AppDir "知乎.lnk"
global APP_Reddit           := PATH_AppDir "Reddit.lnk"
global APP_Telegram         := PATH_AppDir "programfiles\Telegram Desktop\Telegram.exe"
global APP_Everything       := PATH_AppDir "programfiles\Everything\Everything.exe"
global APP_ScreenToGif      := "C:\Program Files\WindowsApps\33823Nicke.ScreenToGif_2.43.2.0_x64__99xjgbc30gqtw\ScreenToGif.exe"
global APP_Anytxt           := "C:\Program Files\Anytxt Searcher\ATGUI.exe"
global APP_Notepad          := "C:\WINDOWS\notepad.exe"

; 👇【已升级为 A_ScriptDir 相对路径】同目录下的 4 个 Windows 批处理脚本
global APP_Ethernet         := A_ScriptDir "\Toggle_Ethernet_切换有线网口状态.bat"
global APP_Shutdown         := A_ScriptDir "\shutdown_30second_等待30秒关机.bat"
global APP_Restart          := A_ScriptDir "\restart_30second_等待30秒重启.bat"
global APP_SecurityCenter   := A_ScriptDir "\windows security center_关闭安全中心设置.bat"

; --- [1.6] 全局内部运行时状态 (非必要不改动) ---
global g_IsPromptGuiVisible := false
global g_IsImageReady       := false
global g_IsTextReady        := false
global g_PromptShowX        := 0, g_PromptShowY := 0
global g_DragStartX         := 0, g_DragStartY  := 0, g_DragStartTime := 0
global g_ClipLastChangeTime := 0
global g_LastImageCopyTime  := 0
global g_SavedImageClip     := ""
global g_LastCopiedText     := ""
global g_EscPressTime       := 0


; ==============================================================================
;               【二、 🎨 悬浮窗 GUI 初始化与布局 (GUI MANAGER)】
; ==============================================================================

; [1] Gemini Prompt 右上角提示词悬浮窗
global PromptGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "PromptUploader")
PromptGui.BackColor := "EEAA99"
WinSetTransColor("EEAA99", PromptGui)
if FileExist(ICON_Prompt) {
    promptBtn := PromptGui.Add("Picture", "h30 w-1 BackgroundTrans", ICON_Prompt)
    promptBtn.OnEvent("Click", TriggerPromptUpload)
    PromptGui.OnEvent("ContextMenu", OpenPromptUI)
}

; [2] Gemini 左上角快速黏贴悬浮窗
global FloatingGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "GeminiUploader")
FloatingGui.BackColor := "EEAA99"
WinSetTransColor("EEAA99", FloatingGui)
if FileExist(ICON_Gemini) {
    geminiBtn := FloatingGui.Add("Picture", "w48 h48 BackgroundTrans", ICON_Gemini)
    geminiBtn.OnEvent("Click", TriggerUpload)
}

; [3] YouGlish 左侧划词发音搜索悬浮窗
global YouGlishGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "YouGlishUploader")
YouGlishGui.BackColor := "EEAA99"
WinSetTransColor("EEAA99", YouGlishGui)
global g_YgWidth := 0, g_YgHeight := 0
if FileExist(ICON_YouGlish) {
    ygBtn := YouGlishGui.Add("Picture", "h32 w-1 BackgroundTrans", ICON_YouGlish)
    ygBtn.OnEvent("Click", TriggerYouGlish)
    ygBtn.GetPos(,, &g_YgWidth, &g_YgHeight)
}

; [4] Copied 划词成功文本提示悬浮窗
global CopiedGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "CopiedIcon")
CopiedGui.BackColor := "EEAA99"
WinSetTransColor("EEAA99", CopiedGui)
if FileExist(ICON_Copied) {
    CopiedGui.Add("Picture", "h37 w-1 BackgroundTrans", ICON_Copied)
}


; ==============================================================================
;           【三、 ⌨️ 快捷键、快速启动与多击引擎 (HOTKEYS & MULTI-TAP)】
; ==============================================================================

; --- [3.1] F1-F12 常用按键映射 ---
F1::Send("^z")
F3::Send("^v")
F4::Send("^a")
F5::Send("^c")
F6::Send("!q")
F8::SendLevel(1), Send("^+8")
F9::Send("^+9")
F10::Send("^+p")
F11::Send("^w")
F12::Send("^+{Esc}")
End::Send("#+{Right}")
PgUp::Send("^{Enter}")
PgDn::Send("^v")

; --- [3.2] 后台多键连按注册 (按键名, 连按次数, 响应回调) ---
RegisterMultiTap("Space",   4, QuadSpaceAction)
RegisterMultiTap("n",       5, PentaNAction)
RegisterMultiTap("z",       3, TripleZAction)
RegisterMultiTap("r",       3, TripleRAction)
RegisterMultiTap("y",       3, TripleYAction)
RegisterMultiTap("e",       3, TripleEAction)
RegisterMultiTap("a",       3, TripleAAction)
RegisterMultiTap("g",       4, QuadGAction)
RegisterMultiTap("d",       4, QuadDAction)
RegisterMultiTap("RButton", 4, QuadRButtonAction)

QuadSpaceAction() {
    Send("{Ctrl Up}{Shift Up}{Alt Up}{Backspace 4}")
    Sleep(150)
    SendLevel 1
    SendEvent("{Ctrl Down}{Shift Down}{7}{Shift Up}{Ctrl Up}")
    SendLevel 0
    ShowTip("⚡ activated QuadSpaceAction")
}
PentaNAction() { 
    Send("{Backspace 5}")
    SmartRun(APP_Notepad)
}
TripleZAction() { 
    Send("{Backspace 3}")
    SmartRun(APP_Zhihu)
}
TripleRAction() { 
    Send("{Backspace 3}")
    SmartRun(APP_Reddit)
}
TripleYAction() { 
    Send("{Backspace 3}")
    SmartRun(APP_YouTube)
}
TripleEAction() { 
    Send("{Backspace 3}")
    SmartRun(APP_Everything)
}
TripleAAction() { 
    Send("{Backspace 3}")
    SmartRun(APP_Anytxt)
}
QuadGAction() {
    Send("{Backspace 4}")
    Sleep(30)
    if (g_IsImageReady) {
        TriggerUpload()
    } else {
        ShowTip("剪贴板中无有效图片")
    }
}
QuadDAction() {
    Send("{Backspace 4}")
    A_Clipboard := ""
    ShowTip("🗑️ 剪贴板已强制清空")
}
QuadRButtonAction() {
    Send("{Esc}")
    Sleep(50)
    Send("{Enter}")
    ShowTip("↩️ 触发 Enter")
}

; --- [3.3] 波浪号组合键启动器 (` & 数字/字母) ---
` & 1::SmartRun(PATH_Chrome)
` & 2::SmartRun(APP_GeminiLnk)
` & 3::SmartRun(APP_Wps)
` & 4::SmartRun(APP_Bilibili)
` & 5::SmartRun(APP_YouTube)
` & 6::SmartRun(APP_YouGlishLnk)
` & 7::SmartRun(APP_DouYin)
` & 8::SmartRun(APP_Telegram)
` & 9::SmartRun(APP_Restart)
` & 0::SmartRun(APP_Shutdown)
` & n::SmartRun(APP_Ethernet)
` & g::SmartRun(APP_ScreenToGif)
` & s::SmartRun(APP_SecurityCenter)  ; 👇【新增】组合键触发关闭 Windows 安全中心设置

SmartRun(Path) {
    if FileExist(Path) {
        Run(Path)
    } else {
        ShowTip("找不到文件或路径：`n" . Path)
    }
}

; 恢复原按键基础输入
`::SendText("``")
+`::SendText("~")

; --- [3.4] 记事本静默自动保存 ---
#HotIf WinActive("ahk_class Notepad") || WinActive("ahk_exe Notepad.exe")
SetTimer AutoSaveNotepad, 3000
AutoSaveNotepad() {
    if (!WinActive("ahk_exe Notepad.exe") || (A_TimeIdleKeyboard < 2000)) {
        return
    }
    if (GetKeyState("Ctrl") || GetKeyState("Shift") || GetKeyState("Alt")) {
        return
    }
    title := WinGetTitle("A")
    if (InStr(title, "•") || InStr(title, "*")) {
        try {
            PostMessage(0x0111, 3, 0, , "ahk_exe Notepad.exe")
        } catch {
            SendKeyDelay := A_KeyDelay
            SetKeyDelay(10, 10)
            ControlSend("{Ctrl down}s{Ctrl up}", , "ahk_exe Notepad.exe")
            SetKeyDelay(SendKeyDelay)
        }
        ShowTip("已自动保存")
    }
}
#HotIf


; ==============================================================================
;           【四、 🖱️ 核心监听引擎：划词与剪贴板 (CORE LISTENERS)】
; ==============================================================================

; --- [4.1] 剪贴板统一监听函数 ---
OnClipboardChange(ClipboardChangedHandler)

ClipboardChangedHandler(DataType) {
    global g_ClipLastChangeTime := A_TickCount
    if (DataType != 0) {
        SetTimer(CheckClipboardForImage, -150)
    }
}

CheckClipboardForImage() {
    global g_LastImageCopyTime, g_SavedImageClip, g_LastCopiedText, g_IsImageReady
    
    ; 检查剪贴板是否存在图像 CF_BITMAP=2, CF_DIB=8, CF_DIBV5=17
    if (DllCall("IsClipboardFormatAvailable", "UInt", 2) 
     || DllCall("IsClipboardFormatAvailable", "UInt", 8) 
     || DllCall("IsClipboardFormatAvailable", "UInt", 17)) {
        g_LastImageCopyTime := A_TickCount
        g_SavedImageClip    := ClipboardAll()
        g_LastCopiedText    := ""
        g_IsImageReady      := true
        
        ShowPromptIcon()    ; [上放] 显示 Gemini 提示词窗
        ShowFloatingIcon()  ; [左放] 显示 Gemini 直接黏贴窗
    } else {
        g_IsImageReady      := false
        g_LastImageCopyTime := 0
        HideFloatingIcon()
    }
}

; --- [4.2] 划词操作全方位安全保护与复制执行 ---
~LButton:: {
    global g_DragStartX, g_DragStartY, g_DragStartTime, g_IsPromptGuiVisible, g_PromptShowX, g_PromptShowY
    MouseGetPos(&g_DragStartX, &g_DragStartY)
    g_DragStartTime := A_TickCount
    
    ; 鼠标远离提示词窗 500px 自动关闭
    if (g_IsPromptGuiVisible && Sqrt((g_DragStartX - g_PromptShowX)**2 + (g_DragStartY - g_PromptShowY)**2) > 500) {
        HidePromptIcon()
    }
}

~LButton Up:: {
    global g_DragStartX, g_DragStartY, g_DragStartTime, g_LastCopiedText, g_ClipLastChangeTime, g_LastImageCopyTime, g_IsTextReady
    releaseTime := A_TickCount

    ; [规则 1] 黑名单窗口屏蔽 (如截屏软件、系统核心栏)
    if WinActive("ahk_class Windows.UI.Core.CoreWindow") 
    || WinActive("ahk_exe SnippingTool.exe") || WinActive("ahk_exe SnippingToolApp.exe")
    || WinActive("ahk_exe Snipaste.exe") || WinActive("ahk_exe PixPin.exe") {
        return
    }

    ; [规则 2] 十字形截图光标、特定浏览器区域(顶部标签栏)、修饰键按压状态过滤
    if (A_Cursor = "Cross") || GetKeyState("Shift", "P") || GetKeyState("Ctrl", "P") || GetKeyState("Alt", "P") {
        return
    }
    if WinActive("ahk_exe chrome.exe") && (g_DragStartY < 120) {
        return
    }
    if WinActive("ahk_exe Code.exe") && (g_DragStartX < 80 || g_DragStartY < 70) {
        return
    }

    ; [规则 3] 拖拽持续时长拦截
    dragTime := A_TickCount - g_DragStartTime
    if (dragTime < MIN_DRAG_TIME_MS || dragTime > MAX_DRAG_TIME_MS) {
        return
    }

    MouseGetPos(&endX, &endY)
    deltaX := Abs(endX - g_DragStartX)
    deltaY := Abs(endY - g_DragStartY)

    ; [规则 4] 物理位移达到要求才开启复制工作流程
    if (deltaX > MIN_DRAG_X || deltaY > MIN_DRAG_Y) {
        
        ; 保护剪贴板内图片不过期：若 8 秒内复制过图片，阻拦常规文字划词触发
        if (g_LastImageCopyTime > 0 && (A_TickCount - g_LastImageCopyTime) < 8000) {
            return
        }

        ; 防止剪贴板写入竞争
        isBusy := false
        Loop 2 {
            Sleep(40)
            if (g_ClipLastChangeTime > releaseTime) {
                isBusy := true
                break
            }
        }
        if (isBusy || GetKeyState("Backspace", "P") || GetKeyState("Delete", "P") || GetKeyState("v", "P")) {
            return
        }

        priorText := ""
        try {
            priorText := A_Clipboard
        }
        
        oldClip := ClipboardAll()
        A_Clipboard := ""
        Send("^c")

        if ClipWait(0.15, 1) {
            ; 过滤文件及文件夹拖动 (CF_HDROP = 15) 及图像
            if DllCall("IsClipboardFormatAvailable", "UInt", 15)
            || DllCall("IsClipboardFormatAvailable", "UInt", 2) 
            || DllCall("IsClipboardFormatAvailable", "UInt", 8) 
            || DllCall("IsClipboardFormatAvailable", "UInt", 17) {
                A_Clipboard := oldClip
                return
            }

            trimmedText := Trim(A_Clipboard, " `t`r`n")
            if (trimmedText == "") {
                A_Clipboard := oldClip
                return
            }

            ; 单行划词却含换行符，视为误选返回
            if (deltaY < 25 && (InStr(A_Clipboard, "`n") || InStr(A_Clipboard, "`r"))) {
                A_Clipboard := oldClip
                return
            }

            ; 成功提取变化纯文本：触发全阵列悬浮图标提示
            if (trimmedText != priorText) {
                g_LastCopiedText := trimmedText
                g_IsTextReady    := true
                
                ShowPromptIcon()    ; [右上] Gemini提示词
                ShowCopiedIcon()    ; [正右] 复制反馈字样
                ShowYouGlishIcon()  ; [正左] YouGlish发音
            } else {
                A_Clipboard := oldClip
            }
        } else {
            A_Clipboard := oldClip
        }
    }
}


; ==============================================================================
;           【五、 🚀 业务逻辑与程序调度执行器 (UPLOAD & EXECUTION)】
; ==============================================================================

; --- [5.1] GUI 悬浮窗口定位渲染管理 ---
ShowPromptIcon() {
    global g_IsPromptGuiVisible, g_PromptShowX, g_PromptShowY, CFG_PromptOffsetX, CFG_PromptOffsetY
    oldCoord := A_CoordModeMouse
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)
    CoordMode("Mouse", oldCoord)
    g_PromptShowX := mX
    g_PromptShowY := mY
    PromptGui.Show("x" (mX + CFG_PromptOffsetX) " y" (mY + CFG_PromptOffsetY) " NoActivate")
    WinSetAlwaysOnTop(1, PromptGui.Hwnd)
    g_IsPromptGuiVisible := true
    SetTimer(HidePromptIcon, -2500)
}
HidePromptIcon(*) {
    global g_IsPromptGuiVisible
    PromptGui.Hide()
    g_IsPromptGuiVisible := false
}

ShowFloatingIcon() {
    global CFG_GeminiOffsetX, CFG_GeminiOffsetY
    oldCoord := A_CoordModeMouse
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)
    CoordMode("Mouse", oldCoord)
    FloatingGui.Show("x" (mX + CFG_GeminiOffsetX) " y" (mY + CFG_GeminiOffsetY) " NoActivate")
    WinSetAlwaysOnTop(1, FloatingGui.Hwnd)
    SetTimer(HideFloatingIcon, -3000)
}
HideFloatingIcon(*) {
    FloatingGui.Hide()
}

ShowYouGlishIcon() {
    global g_YgWidth, g_YgHeight, CFG_YouGlishOffsetX, CFG_YouGlishOffsetY
    oldCoord := A_CoordModeMouse
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)
    CoordMode("Mouse", oldCoord)
    YouGlishGui.Show("x" (mX + CFG_YouGlishOffsetX - g_YgWidth) " y" (mY + CFG_YouGlishOffsetY - (g_YgHeight / 2)) " NoActivate")
    WinSetAlwaysOnTop(1, YouGlishGui.Hwnd)
    SetTimer(HideYouGlishIcon, -3000)
}
HideYouGlishIcon(*) {
    YouGlishGui.Hide()
}

ShowCopiedIcon() {
    global CFG_CopiedOffsetX, CFG_CopiedOffsetY
    oldCoord := A_CoordModeMouse
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)
    CoordMode("Mouse", oldCoord)
    CopiedGui.Show("x" (mX + CFG_CopiedOffsetX) " y" (mY + CFG_CopiedOffsetY) " NoActivate")
    WinSetAlwaysOnTop(1, CopiedGui.Hwnd)
    SetTimer(HideCopiedIcon, -1500)
}
HideCopiedIcon(*) {
    CopiedGui.Hide()
}

; --- [5.2] 触发逻辑：Gemini 提示词模板合辑发送版 ---
OpenPromptUI(*) {
    SetTimer(HidePromptIcon, 0)
    HidePromptIcon()
    if (FileExist(PATH_EditorExe)) {
        Run(PATH_EditorExe)
    } else {
        MsgBox("找不到 UI 程序：`n" PATH_EditorExe, "缺少文件")
    }
}

TriggerPromptUpload(*) {
    global g_LastCopiedText, g_SavedImageClip, g_LastImageCopyTime, PATH_ActivePrompt, PATH_Chrome
    SetTimer(HidePromptIcon, 0)
    HidePromptIcon()
    
    template := (FileExist(PATH_ActivePrompt)) ? FileRead(PATH_ActivePrompt, "UTF-8") : "{text}"
    finalText := Trim(StrReplace(template, "{text}", g_LastCopiedText), " `t`r`n")
    
    Run('"' PATH_Chrome '" --new-window --app="https://gemini.google.com/app"')
    targetTitle := "Gemini ahk_exe chrome.exe"
    
    if WinWait(targetTitle, , 8) {
        WinActivate(targetTitle)
        WinWaitActive(targetTitle, , 2)
        Sleep(800)
        Loop 3 {
            Send("{Esc}")
            Sleep(50)
            Send("gi")
            Sleep(300)
        }
        
        oldClip := ClipboardAll()
        hasImg  := (g_LastImageCopyTime > 0 && (A_TickCount - g_LastImageCopyTime) < 8000)
        
        if (hasImg && g_SavedImageClip != "") {
            A_Clipboard := g_SavedImageClip
            if ClipWait(1, 1) {
                Sleep(50)
                Send("^v")
                Sleep(1500)
            }
        }
        if (finalText != "") {
            A_Clipboard := finalText
            if ClipWait(1) {
                Sleep(50)
                Send("^v")
                Sleep(600)
            }
        }
        SendEvent("{Ctrl down}{Enter}{Ctrl up}")
        Sleep(300)
        A_Clipboard := oldClip
    } else {
        ShowTip("打开 Gemini 窗口超时，请重试。")
    }
}

; --- [5.3] 触发逻辑：Gemini 剪贴板一键极速回车黏贴版 ---
#+g:: {
    if (g_IsImageReady) {
        TriggerUpload()
    }
}
TriggerUpload(*) {
    global g_IsImageReady, APP_GeminiLnk
    SetTimer(HideFloatingIcon, 0)
    FloatingGui.Hide()
    g_IsImageReady := false
    
    try {
        oldMode := A_TitleMatchMode
        SetTitleMatchMode(2)
        targetTitle := "Gemini ahk_exe chrome.exe"
        
        if WinActive(targetTitle) {
            Send("{Esc}")
            Sleep(50)
            Send("gi")
            Sleep(200)
        } else if WinExist(targetTitle) {
            WinActivate(targetTitle)
            WinWaitActive(targetTitle, , 2)
            Send("{Esc}")
            Sleep(50)
            Send("gi")
            Sleep(200)
        } else {
            Run(APP_GeminiLnk)
            if WinWait(targetTitle, , 5) {
                WinActivate(targetTitle)
                WinWaitActive(targetTitle, , 2)
                Sleep(2000)
            } else {
                Sleep(1000)
            }
        }
        SetTitleMatchMode(oldMode)
        Send("^v")
        Sleep(400)
        Send("{Enter}")
    } catch {
        MsgBox("无法启动 Gemini，请检查路径：`n" APP_GeminiLnk, "路径错误")
    }
}

; --- [5.4] 触发逻辑：YouGlish 划词自动发音查询 ---
^+y::TriggerYouGlish()
TriggerYouGlish(*) {
    global g_IsTextReady, APP_YouGlishLnk
    SetTimer(HideYouGlishIcon, 0)
    YouGlishGui.Hide()
    g_IsTextReady := false
    
    try {
        oldMode := A_TitleMatchMode
        SetTitleMatchMode(2)
        targetTitle := "youglish ahk_exe chrome.exe"
        
        if WinActive(targetTitle) {
            Send("{Esc}")
            Sleep(50)
            Send("gi")
            Sleep(200)
        } else if WinExist(targetTitle) {
            WinActivate(targetTitle)
            WinWaitActive(targetTitle, , 2)
            Send("{Esc}")
            Sleep(50)
            Send("gi")
            Sleep(200)
        } else {
            Run(APP_YouGlishLnk)
            if WinWait(targetTitle, , 5) {
                WinActivate(targetTitle)
                WinWaitActive(targetTitle, , 2)
                Sleep(1500)
                Send("{Esc}")
                Sleep(50)
                Send("gi")
                Sleep(200)
            } else {
                Sleep(1000)
            }
        }
        SetTitleMatchMode(oldMode)
        Send("^a")
        Sleep(50)
        Send("^v")
        Sleep(400)
        Send("{Enter}")
    } catch {
        MsgBox("无法启动 YouGlish，请检查路径：`n" APP_YouGlishLnk, "路径错误")
    }
}


; ==============================================================================
;           【六、 🛡️ 系统功能与窗口工具 (SYSTEM & WINDOW UTILITIES)】
; ==============================================================================

; --- [6.1] 开发热重载：脚本编辑器中 Ctrl+S 立即应用变更 ---
if (A_Args.Length > 0 && A_Args[1] == "/reloaded") {
    ShowTip("🚀 脚本已成功加载新参数！")
}
#HotIf WinActive(A_ScriptName)
~^s:: {
    Sleep(200)
    Run('"' . A_AhkPath . '" "' . A_ScriptFullPath . '" /reloaded')
    ExitApp()
}
#HotIf

; --- [6.2] 全局鼠标滚轮联动：滚动即可隐藏一切悬浮图标 ---
~WheelUp::
~WheelDown:: {
    HidePromptIcon()
    HideFloatingIcon()
    HideYouGlishIcon()
    HideCopiedIcon()
}

; --- [6.3] 全局 Esc 智能行为：点击清除悬浮窗，长按配合左键强制杀后台进程 ---
~Esc:: {
    global g_EscPressTime
    if (g_EscPressTime == 0) {
        g_EscPressTime := A_TickCount
    }
    HidePromptIcon()
    HideFloatingIcon()
    HideYouGlishIcon()
    HideCopiedIcon()
}
~Esc up:: {
    global g_EscPressTime := 0
}

#HotIf GetKeyState("Esc", "P")
$LButton:: {
    global g_EscPressTime, ESC_LONG_PRESS_MS
    if (g_EscPressTime > 0 && (A_TickCount - g_EscPressTime >= ESC_LONG_PRESS_MS)) {
        MouseGetPos ,, &hoverWin
        if hoverWin {
            try {
                WinClose hoverWin
            }
        }
    } else {
        Send "{Blind}{LButton down}"
        KeyWait("LButton")
        Send("{Blind}{LButton up}")
    }
}
#HotIf

; --- [6.4] Win+J 强制恢复全部被最小化的窗口 ---
#j:: {
    for this_id in WinGetList(,, "Program Manager") {
        if (WinGetMinMax(this_id) == -1) {
            if (WinGetTitle(this_id) != "") {
                WinRestore(this_id)
            }
        }
    }
}

; --- [6.5] 多按键与多模块公用反馈信息提示方法 ---
RegisterMultiTap(key, targetCount, callback, maxSpeedInterval := 200) {
    static stateMap := Map()
    stateMap[key] := { count: 0, lastTime: 0, triggered: false }
    Hotkey("~" . key, (*) => ProcessTap(key, targetCount, callback, maxSpeedInterval))

    ProcessTap(k, target, cb, maxSpeed) {
        st := stateMap[k]
        now := A_TickCount
        diff := now - st.lastTime
        if (st.lastTime == 0 || diff > maxSpeed || st.triggered) {
            st.count := 1
            st.triggered := false
        } else {
            st.count++
        }
        st.lastTime := now
        if (st.count == target) {
            st.triggered := true
            st.count := 0
            st.lastTime := 0
            cb()
        }
    }
}

ShowTip(text) {
    ToolTip(text)
    SetTimer(() => ToolTip(), -1500)
}