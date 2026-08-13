#Requires AutoHotkey v2.0
#SingleInstance Force
ListLines 0

; ==============================================================================
;                  【零、 🛡️ 系统权限与环境初始化】
; ==============================================================================
; 强制脚本以管理员权限运行，确保能够关闭任务管理器等高权限进程
if not A_IsAdmin {
    try {
        Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"')
    }
    ExitApp()
}

; ==============================================================================
;                  【一、 ⚙️ 全局用户配置控制台 (USER CONFIG)】
; ==============================================================================

; 屏蔽长按按键时触发的 "71 hotkeys have been received" 警告弹窗
A_MaxHotkeysPerInterval := 99000

global CFG_PromptOffsetX    := -180
global CFG_PromptOffsetY    := -57
global CFG_GeminiOffsetX    := -10
global CFG_GeminiOffsetY    := -120
global CFG_YouGlishOffsetX  := -40
global CFG_YouGlishOffsetY  := 20
global CFG_CopiedOffsetX    := 100
global CFG_CopiedOffsetY    := 50

global MIN_DRAG_X           := 35
global MIN_DRAG_Y           := 45
global MIN_DRAG_TIME_MS     := 50
global MAX_DRAG_TIME_MS     := 15000
global ESC_LONG_PRESS_MS    := 400

global PATH_AppDir          := A_ScriptDir "\resources\"

; ------------------------------------------------------------------------------
; [移植性优化] 动态获取浏览器路径 (优先 Chrome，无 Chrome 则自动降级使用系统自带的 Edge)
global PATH_Chrome := ""
Try {
    PATH_Chrome := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe")
} Catch {
    PATH_Chrome := "C:\Program Files\Google\Chrome\Application\chrome.exe"
}

if !FileExist(PATH_Chrome) {
    Try {
        PATH_Chrome := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe")
    } Catch {
        PATH_Chrome := "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    }
}
; ------------------------------------------------------------------------------

global PATH_EditorExe       := A_ScriptDir "\GeminiPromptEditor.exe"
global PATH_ActivePrompt    := A_ScriptDir "\active_prompt.txt"

global ICON_Prompt          := PATH_AppDir "photo\gemini_prompt.png"
global ICON_Gemini          := PATH_AppDir "photo\gemini.png"
global ICON_YouGlish        := PATH_AppDir "photo\youglish_auto_load.png"
global ICON_Copied          := PATH_AppDir "photo\copied.png"

global URL_Gemini           := "https://gemini.google.com/app"
global URL_YouGlish         := "https://youglish.com/"
global URL_DouYin           := "https://www.douyin.com/"
global URL_YouTube          := "https://www.youtube.com/"
global URL_Bilibili         := "https://www.bilibili.com/"
global URL_Github           := "https://github.com/"
global URL_Zhihu            := "https://www.zhihu.com/"
global URL_Reddit           := "https://www.reddit.com/"

; ------------------------------------------------------------------------------
; [移植性优化] 动态获取 Telegram 路径 (兼容便携版、注册表与默认安装版)
global APP_Telegram := PATH_AppDir "programfiles\Telegram Desktop\Telegram.exe"
if !FileExist(APP_Telegram) {
    Try {
        APP_Telegram := RegRead("HKEY_CURRENT_USER\Software\Classes\tg\shell\open\command")
        APP_Telegram := StrReplace(APP_Telegram, '" "%1"', '')
        APP_Telegram := StrReplace(APP_Telegram, '"', '')
    } Catch {
        APP_Telegram := EnvGet("APPDATA") "\Telegram Desktop\Telegram.exe"
    }
}

; [移植性优化] 动态获取 Everything 路径 (兼容便携版与系统安装版)
global APP_Everything       := PATH_AppDir "programfiles\Everything\Everything.exe"
if !FileExist(APP_Everything) {
    Try APP_Everything := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\Everything.exe")
    Catch
        APP_Everything := A_ProgramFiles "\Everything\Everything.exe"
}

; [移植性优化] 动态获取 Anytxt 路径 (优先注册表，其次系统程序目录)
global APP_Anytxt := ""
Try {
    APP_Anytxt := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Applications\ATGUI.exe\shell\open\command")
    APP_Anytxt := StrReplace(APP_Anytxt, '" "%1"', '') 
    APP_Anytxt := StrReplace(APP_Anytxt, '"', '')
} Catch {
    APP_Anytxt := A_ProgramFiles "\Anytxt Searcher\ATGUI.exe"
}
; ------------------------------------------------------------------------------

global APP_Notepad          := A_WinDir "\notepad.exe" 

global APP_Ethernet         := A_ScriptDir "\Toggle_Ethernet_切换有线网口状态.bat"
global APP_Shutdown         := A_ScriptDir "\shutdown_30second_等待30秒关机.bat"
global APP_Restart          := A_ScriptDir "\restart_30second_等待30秒重启.bat"
global APP_SecurityCenter   := A_ScriptDir "\windows security center_关闭安全中心设置.bat"

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

global PromptGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "PromptUploader")
PromptGui.BackColor := "EEAA99"
WinSetTransColor("EEAA99", PromptGui)
if FileExist(ICON_Prompt) {
    promptBtn := PromptGui.Add("Picture", "h30 w-1 BackgroundTrans", ICON_Prompt)
    promptBtn.OnEvent("Click", TriggerPromptUpload)
    PromptGui.OnEvent("ContextMenu", OpenPromptUI)
}

global FloatingGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "GeminiUploader")
FloatingGui.BackColor := "EEAA99"
WinSetTransColor("EEAA99", FloatingGui)
if FileExist(ICON_Gemini) {
    geminiBtn := FloatingGui.Add("Picture", "w48 h48 BackgroundTrans", ICON_Gemini)
    geminiBtn.OnEvent("Click", TriggerUpload)
}

global YouGlishGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "YouGlishUploader")
YouGlishGui.BackColor := "EEAA99"
WinSetTransColor("EEAA99", YouGlishGui)
global g_YgWidth := 0, g_YgHeight := 0
if FileExist(ICON_YouGlish) {
    ygBtn := YouGlishGui.Add("Picture", "h32 w-1 BackgroundTrans", ICON_YouGlish)
    ygBtn.OnEvent("Click", TriggerYouGlish)
    ygBtn.GetPos(,, &g_YgWidth, &g_YgHeight)
}

global CopiedGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "CopiedIcon")
CopiedGui.BackColor := "EEAA99"
WinSetTransColor("EEAA99", CopiedGui)
if FileExist(ICON_Copied) {
    CopiedGui.Add("Picture", "h37 w-1 BackgroundTrans", ICON_Copied)
}


; ==============================================================================
;           【三、 ⌨️ 快捷键、快速启动与多击引擎 (HOTKEYS & MULTI-TAP)】
; ==============================================================================

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
    RunChromePWA(URL_Zhihu)
}
TripleRAction() { 
    Send("{Backspace 3}")
    RunChromePWA(URL_Reddit)
}
TripleYAction() { 
    Send("{Backspace 3}")
    RunChromePWA(URL_YouTube)
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
    if (g_IsImageReady || g_IsTextReady) {
        TriggerUpload()
    } else {
        ShowTip("剪贴板中无有效图片或文本")
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

` & 1::SmartRun(PATH_Chrome)
` & 2::RunChromePWA(URL_Gemini)
` & 3::RunChromePWA(URL_Github)
` & 4::RunChromePWA(URL_Bilibili)
` & 5::RunChromePWA(URL_YouTube)
` & 6::RunChromePWA(URL_YouGlish)
` & 7::RunChromePWA(URL_DouYin)
` & 8::SmartRun(APP_Telegram)
` & 9::SmartRun(APP_Restart)
` & 0::SmartRun(APP_Shutdown)
` & n::SmartRun(APP_Ethernet)
` & s::SmartRun(APP_SecurityCenter)  

SmartRun(Path) {
    if FileExist(Path) {
        Run(Path)
    } else {
        ShowTip("找不到文件或路径：`n" . Path)
    }
}

RunChromePWA(URL) {
    if FileExist(PATH_Chrome) {
        Run('"' PATH_Chrome '" --app="' URL '"')
    } else {
        ShowTip("无法启动：未在系统中找到 浏览器`n" PATH_Chrome)
    }
}

`::SendText("``")
+`::SendText("~")

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

OnClipboardChange(ClipboardChangedHandler)

ClipboardChangedHandler(DataType) {
    global g_ClipLastChangeTime := A_TickCount
    if (DataType != 0) {
        SetTimer(CheckClipboardForImage, -150)
    }
}

CheckClipboardForImage() {
    global g_LastImageCopyTime, g_SavedImageClip, g_LastCopiedText, g_IsImageReady, g_IsTextReady
    
    if (DllCall("IsClipboardFormatAvailable", "UInt", 2) 
     || DllCall("IsClipboardFormatAvailable", "UInt", 8) 
     || DllCall("IsClipboardFormatAvailable", "UInt", 17)) {
        g_LastImageCopyTime := A_TickCount
        g_SavedImageClip    := ClipboardAll()
        g_LastCopiedText    := ""
        g_IsImageReady      := true
        g_IsTextReady       := false
        
        ShowPromptIcon()    
        ShowFloatingIcon()  
    } else {
        g_IsImageReady      := false
        g_LastImageCopyTime := 0
        if (!g_IsTextReady) {
            HideFloatingIcon()
        }
    }
}

~LButton:: {
    global g_DragStartX, g_DragStartY, g_DragStartTime, g_IsPromptGuiVisible, g_PromptShowX, g_PromptShowY
    MouseGetPos(&g_DragStartX, &g_DragStartY)
    g_DragStartTime := A_TickCount
    
    if (g_IsPromptGuiVisible && Sqrt((g_DragStartX - g_PromptShowX)**2 + (g_DragStartY - g_PromptShowY)**2) > 500) {
        HidePromptIcon()
    }
}

~LButton Up:: {
    global g_DragStartX, g_DragStartY, g_DragStartTime, g_LastCopiedText, g_ClipLastChangeTime, g_LastImageCopyTime, g_IsTextReady
    releaseTime := A_TickCount

    if WinActive("ahk_class Windows.UI.Core.CoreWindow") 
    || WinActive("ahk_exe SnippingTool.exe") || WinActive("ahk_exe SnippingToolApp.exe")
    || WinActive("ahk_exe Snipaste.exe") || WinActive("ahk_exe PixPin.exe") {
        return
    }

    ; [移植性优化] 动态计算当前屏幕的 DPI 缩放比例 (100%缩放为1, 125%缩放为1.25)
    global DPIScale := A_ScreenDPI / 96 

    if (A_Cursor = "Cross") || GetKeyState("Shift", "P") || GetKeyState("Ctrl", "P") || GetKeyState("Alt", "P") {
        return
    }
    
    if WinActive("ahk_exe chrome.exe") || WinActive("ahk_exe msedge.exe") { 
        if (g_DragStartY < 120 * DPIScale) {
            return
        }
    }
    if WinActive("ahk_exe Code.exe") && (g_DragStartX < 80 * DPIScale || g_DragStartY < 70 * DPIScale) {
        return
    }

    dragTime := A_TickCount - g_DragStartTime
    if (dragTime < MIN_DRAG_TIME_MS || dragTime > MAX_DRAG_TIME_MS) {
        return
    }

    MouseGetPos(&endX, &endY)
    deltaX := Abs(endX - g_DragStartX)
    deltaY := Abs(endY - g_DragStartY)

    if (deltaX > MIN_DRAG_X || deltaY > MIN_DRAG_Y) {
        
        if (g_LastImageCopyTime > 0 && (A_TickCount - g_LastImageCopyTime) < 8000) {
            return
        }

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

            if (deltaY < 25 && (InStr(A_Clipboard, "`n") || InStr(A_Clipboard, "`r"))) {
                A_Clipboard := oldClip
                return
            }

            if (trimmedText != priorText) {
                g_LastCopiedText := trimmedText
                g_IsTextReady    := true
                
                ShowPromptIcon()    
                ShowCopiedIcon()    
                ShowYouGlishIcon()  
                ShowFloatingIcon()  
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
    
    existingWins := Map()
    try {
        for hwnd in WinGetList("Gemini")
            existingWins[hwnd] := true
    }
    
    Run('"' PATH_Chrome '" --new-window --app="https://gemini.google.com/app"')
    
    newHwnd := 0
    startTime := A_TickCount
    while (A_TickCount - startTime < 10000) {
        try {
            for hwnd in WinGetList("Gemini") {
                if !existingWins.Has(hwnd) {
                    newHwnd := hwnd
                    break 2  
                }
            }
        }
        Sleep(150)
    }
    
    if (newHwnd) {
        WinActivate("ahk_id " newHwnd)
        WinWaitActive("ahk_id " newHwnd, , 3)
        
        Sleep(2500) 
        
        Loop 3 {
            WinActivate("ahk_id " newHwnd) 
            Send("{Esc}")
            Sleep(100)
            Send("gi")
            Sleep(400)
        }
        
        oldClip := ClipboardAll()
        hasImg  := (g_LastImageCopyTime > 0 && (A_TickCount - g_LastImageCopyTime) < 8000)
        
        if (hasImg && g_SavedImageClip != "") {
            A_Clipboard := g_SavedImageClip
            if ClipWait(1, 1) {
                Sleep(100)
                Send("^v")
                Sleep(2000) 
            }
        }
        
        if (finalText != "") {
            A_Clipboard := finalText
            if ClipWait(1) {
                Sleep(100)
                Send("^v")
                Sleep(800) 
            }
        }
        
        SendEvent("{Ctrl down}{Enter}{Ctrl up}")
        Sleep(400)
        A_Clipboard := oldClip
    } else {
        ShowTip("打开 Gemini 新窗口超时，请重试。")
    }
}

#+g:: {
    if (g_IsImageReady || g_IsTextReady) {
        TriggerUpload()
    }
}
TriggerUpload(*) {
    global g_IsImageReady, g_IsTextReady, URL_Gemini, PATH_Chrome
    SetTimer(HideFloatingIcon, 0)
    FloatingGui.Hide()
    g_IsImageReady := false
    g_IsTextReady  := false
    
    try {
        oldMode := A_TitleMatchMode
        SetTitleMatchMode(2)
        targetTitle := "Gemini"
        
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
            Run('"' PATH_Chrome '" --app="' URL_Gemini '"')
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
        MsgBox("无法启动 Gemini，请检查路径。`n" URL_Gemini, "启动错误")
    }
}

^+y::TriggerYouGlish()
TriggerYouGlish(*) {
    global g_IsTextReady, URL_YouGlish, PATH_Chrome
    SetTimer(HideYouGlishIcon, 0)
    YouGlishGui.Hide()
    g_IsTextReady := false
    
    try {
        oldMode := A_TitleMatchMode
        SetTitleMatchMode(2)
        targetTitle := "youglish"
        
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
            Run('"' PATH_Chrome '" --app="' URL_YouGlish '"')
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
        MsgBox("无法启动 YouGlish，请检查路径。`n" URL_YouGlish, "启动错误")
    }
}


; ==============================================================================
;           【六、 🛡️ 系统功能与窗口工具 (SYSTEM & WINDOW UTILITIES)】
; ==============================================================================

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

~WheelUp::
~WheelDown:: {
    HidePromptIcon()
    HideFloatingIcon()
    HideYouGlishIcon()
    HideCopiedIcon()
}

~Esc:: {
    global g_EscPressTime
    ; 拦截按键长按时的系统重复连发信号，解决 "71 hotkeys" 报错
    if (g_EscPressTime > 0) {
        return
    }
    g_EscPressTime := A_TickCount
    HidePromptIcon()
    HideFloatingIcon()
    HideYouGlishIcon()
    HideCopiedIcon()
}
~Esc up:: {
    global g_EscPressTime := 0
}

; ------------------------------------------------------------------------------
; [权限增强] Esc + 鼠标左键：强制关闭单个窗口 (废弃 Esc+右键 与 ProcessClose)
#HotIf GetKeyState("Esc", "P")

$LButton:: {
    global g_EscPressTime, ESC_LONG_PRESS_MS
    if (g_EscPressTime > 0 && (A_TickCount - g_EscPressTime >= ESC_LONG_PRESS_MS)) {
        MouseGetPos(,, &hoverWin)
        if hoverWin {
            try {
                ; 仅关闭当前悬停的单个窗口，彻底摒弃 ProcessClose 杀进程，防止波及其他浏览器页面
                WinClose("ahk_id " hoverWin)
            } catch {
                ShowTip("❌ 关闭窗口失败")
            }
        }
    } else {
        ; 恢复原有的按键基础输入
        Send("{Blind}{LButton down}")
        KeyWait("LButton")
        Send("{Blind}{LButton up}")
    }
}
#HotIf
; ------------------------------------------------------------------------------

; ------------------------------------------------------------------------------
; [稳定性增强] Win+J 强制恢复被最小化的核心应用窗口
#j:: {
    restoredCount := 0
    
    for hwnd in WinGetList() {
        if (WinGetMinMax(hwnd) == -1) {  ; 仅处理当前处于"最小化"状态的窗口
            title   := WinGetTitle(hwnd)
            class   := WinGetClass(hwnd)
            exStyle := WinGetExStyle(hwnd)
            
            ; 过滤规则1：过滤没有标题的幽灵窗口以及系统桌面基层 (防止恢复出奇怪的底板)
            if (title == "" || class == "Progman" || class == "WorkerW")
                continue
                
            ; 过滤规则2：过滤特殊的工具条或隐藏式的后台悬浮窗 (防止破坏 UI 布局)
            if (exStyle & 0x00000080) ; WS_EX_TOOLWINDOW
                continue

            try {
                WinRestore(hwnd)
                restoredCount++
            }
        }
    }
    
    ; 增加恢复数量的反馈提示
    if (restoredCount > 0) {
        ShowTip("🔄 成功唤醒了 " restoredCount " 个最小化窗口")
    } else {
        ShowTip("ℹ️ 当前没有需要恢复的最小化窗口")
    }
}
; ------------------------------------------------------------------------------

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
