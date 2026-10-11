import os
import platform
import subprocess
import time
import webbrowser
from datetime import datetime
from typing import Dict, List, Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

try:
    # pyrefly: ignore [missing-import]
    import speech_recognition as sr
except ImportError:
    sr = None

# Comprehensive dictionary of supported macOS applications
APPS: Dict[str, Dict[str, str]] = {
    "chrome": {"name": "Google Chrome", "category": "Browser", "icon": "chrome"},
    "brave": {"name": "Brave Browser", "category": "Browser", "icon": "compass"},
    "safari": {"name": "Safari", "category": "Browser", "icon": "compass"},
    "calculator": {"name": "Calculator", "category": "Utility", "icon": "calculator"},
    "notes": {"name": "Notes", "category": "Productivity", "icon": "file-text"},
    "terminal": {"name": "Terminal", "category": "Developer", "icon": "terminal"},
    "pycharm": {"name": "PyCharm", "category": "Developer", "icon": "code"},
    "vscode": {"name": "Visual Studio Code", "category": "Developer", "icon": "code-2"},
    "spotify": {"name": "Spotify", "category": "Media", "icon": "music"},
    "finder": {"name": "Finder", "category": "System", "icon": "folder"},
    "slack": {"name": "Slack", "category": "Communication", "icon": "message-square"},
    "teams": {"name": "Microsoft Teams", "category": "Communication", "icon": "message-square"},
    "zoom": {"name": "zoom.us", "category": "Communication", "icon": "video"},
    "excel": {"name": "Microsoft Excel", "category": "Productivity", "icon": "file-text"},
    "word": {"name": "Microsoft Word", "category": "Productivity", "icon": "file-text"},
    "powerpoint": {"name": "Microsoft PowerPoint", "category": "Productivity", "icon": "file-text"},
    "notion": {"name": "Notion", "category": "Productivity", "icon": "file-text"},
    "linear": {"name": "Linear", "category": "Developer", "icon": "check-square"},
    "jira": {"name": "Jira", "category": "Developer", "icon": "check-square"},
    "whatsapp": {"name": "WhatsApp", "category": "Communication", "icon": "message-circle"},
    "mail": {"name": "Mail", "category": "Communication", "icon": "mail"},
    "calendar": {"name": "Calendar", "category": "Productivity", "icon": "calendar"},
    "settings": {"name": "System Settings", "category": "System", "icon": "settings"},
}

WEBSITES: Dict[str, Dict[str, str]] = {
    "whatsapp": {"title": "WhatsApp Web", "url": "https://web.whatsapp.com", "category": "Social", "badge": "Chat"},
    "chatgpt": {"title": "ChatGPT", "url": "https://chatgpt.com", "category": "AI", "badge": "AI Bot"},
    "youtube": {"title": "YouTube", "url": "https://www.youtube.com", "category": "Media", "badge": "Video"},
    "google": {"title": "Google", "url": "https://www.google.com", "category": "Search", "badge": "Search"},
    "github": {"title": "GitHub", "url": "https://github.com", "category": "Developer", "badge": "Code"},
    "linear": {"title": "Linear App", "url": "https://linear.app", "category": "Developer", "badge": "Sprints"},
    "jira": {"title": "Jira", "url": "https://atlassian.net", "category": "Enterprise", "badge": "Projects"},
    "sheets": {"title": "Google Sheets", "url": "https://sheets.google.com", "category": "Enterprise", "badge": "Finance"},
    "docs": {"title": "Google Docs", "url": "https://docs.google.com", "category": "Enterprise", "badge": "Docs"},
    "notion": {"title": "Notion", "url": "https://notion.so", "category": "Productivity", "badge": "Wiki"},
    "stripe": {"title": "Stripe Dashboard", "url": "https://dashboard.stripe.com", "category": "Finance", "badge": "Revenue"},
    "hubspot": {"title": "HubSpot CRM", "url": "https://app.hubspot.com", "category": "Sales", "badge": "Pipeline"},
    "figma": {"title": "Figma", "url": "https://figma.com", "category": "Design", "badge": "Design"},
    "reddit": {"title": "Reddit", "url": "https://www.reddit.com", "category": "Social", "badge": "Community"},
    "twitter": {"title": "X / Twitter", "url": "https://x.com", "category": "Social", "badge": "Feed"},
}

app = FastAPI(
    title="AURA AI Executive Business & Voice Assistant",
    description="High-performance enterprise backend API for controlling executive apps, drafting emails, managing tasks, and computing KPIs.",
    version="2.0.0",
)

# Enable CORS for frontend flexibility
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory history and business task log
history_log: List[Dict] = []
business_tasks: List[Dict] = [
    {"id": "task-1", "title": "Review Q4 Executive Strategy & Budget", "priority": "P0", "category": "Strategy", "is_completed": False, "due_date": "Today"},
    {"id": "task-2", "title": "Finalize Enterprise Client Contract & SLA", "priority": "P0", "category": "Sales", "is_completed": False, "due_date": "Today 3 PM"},
    {"id": "task-3", "title": "Sprint Velocity & Roadmap Alignment", "priority": "P1", "category": "Product", "is_completed": False, "due_date": "Tomorrow"},
    {"id": "task-4", "title": "Model Cash Runway & 18-Month Burn Projections", "priority": "P1", "category": "Finance", "is_completed": False, "due_date": "This Week"},
]
START_TIME = time.time()


# Request/Response Schemas
class CommandRequest(BaseModel):
    command: str


class AppOpenRequest(BaseModel):
    app: str


class AppCloseRequest(BaseModel):
    app: str


class WebsiteOpenRequest(BaseModel):
    website: Optional[str] = None
    url: Optional[str] = None


class SystemActionRequest(BaseModel):
    action: str
    value: Optional[str] = None


class EmailDraftRequest(BaseModel):
    recipient: str = "Team / Client"
    subject: str = "Executive Strategy Alignment"
    context_points: str = ""
    tone: str = "Executive Direct"


class MeetingAgendaRequest(BaseModel):
    title: str = "Executive Strategy Review"
    duration_minutes: int = 30
    objective: str = "Align on priorities and establish deliverables."


class KpiCalcRequest(BaseModel):
    cash_balance: float = 500000.0
    monthly_burn: float = 35000.0
    ltv: float = 12000.0
    cac: float = 3000.0
    current_mrr: float = 45000.0
    prev_mrr: float = 38000.0


class TaskCreateRequest(BaseModel):
    title: str
    priority: str = "P1"
    category: str = "Strategy"
    due_date: str = "Today"


def get_battery_info() -> Dict[str, str]:
    """Retrieve macOS battery information via pmset."""
    if platform.system() != "Darwin":
        return {"status": "Unavailable", "percent": "N/A", "power_source": "Non-macOS"}
    try:
        res = subprocess.run(["pmset", "-g", "batt"], capture_output=True, text=True, check=False)
        output = res.stdout
        lines = output.splitlines()
        power_source = "AC Power" if "AC Power" in output else "Battery Power"
        percent = "Unknown"
        state = "Normal"
        for line in lines:
            if "%" in line:
                parts = line.split(";")
                for part in parts:
                    if "%" in part:
                        for token in part.split():
                            if "%" in token:
                                percent = token.strip().replace(";", "")
                    if "discharging" in part.lower():
                        state = "Discharging"
                    elif "charging" in part.lower():
                        state = "Charging"
                    elif "charged" in part.lower():
                        state = "Fully Charged"
        return {"status": state, "percent": percent, "power_source": power_source}
    except Exception as e:
        return {"status": "Error", "percent": "N/A", "error": str(e)}


# Track last opened target for context-aware commands like "close this", "close it", "close the app"
LAST_OPENED: Dict[str, str] = {"type": "", "target": ""}

SYNONYMS: Dict[str, str] = {
    "google chrome": "chrome",
    "chrome": "chrome",
    "brave": "brave",
    "brave browser": "brave",
    "safari": "safari",
    "calculator": "calculator",
    "calc": "calculator",
    "notes": "notes",
    "note": "notes",
    "apple notes": "notes",
    "terminal": "terminal",
    "pycharm": "pycharm",
    "vscode": "vscode",
    "vs code": "vscode",
    "visual studio code": "vscode",
    "code": "vscode",
    "spotify": "spotify",
    "finder": "finder",
    "slack": "slack",
    "whatsapp": "whatsapp",
    "whats app": "whatsapp",
    "whatsapp web": "whatsapp",
    "chatgpt": "chatgpt",
    "chat gpt": "chatgpt",
    "youtube": "youtube",
    "you tube": "youtube",
    "mail": "mail",
    "email": "mail",
    "settings": "settings",
    "system settings": "settings",
    "system preferences": "settings",
    "teams": "teams",
    "microsoft teams": "teams",
    "zoom": "zoom",
    "excel": "excel",
    "microsoft excel": "excel",
    "word": "word",
    "microsoft word": "word",
    "powerpoint": "powerpoint",
    "ppt": "powerpoint",
    "linear": "linear",
    "jira": "jira",
    "notion": "notion",
    "sheets": "sheets",
    "google sheets": "sheets",
    "docs": "docs",
    "google docs": "docs",
    "stripe": "stripe",
    "hubspot": "hubspot",
}

# Browser tab closing for web apps and sites
def close_browser_tab(term: str) -> bool:
    """Close tabs matching a domain or keyword across Chrome, Brave, and Safari."""
    if platform.system() != "Darwin":
        return False

    applescript = f'''
    set closedTab to false
    tell application "System Events"
        set isRunningChrome to (count (every process whose name is "Google Chrome")) > 0
        set isRunningBrave to (count (every process whose name is "Brave Browser")) > 0
        set isRunningSafari to (count (every process whose name is "Safari")) > 0
    end tell

    if isRunningChrome then
        try
            tell application "Google Chrome"
                repeat with w in windows
                    set tabIdx to 1
                    repeat while tabIdx <= (count of tabs of w)
                        set t to tab tabIdx of w
                        if (URL of t contains "{term}") or (title of t contains "{term}") then
                            close t
                            set closedTab to true
                        else
                            set tabIdx to tabIdx + 1
                        end if
                    end repeat
                end repeat
            end tell
        end try
    end if

    if isRunningBrave then
        try
            tell application "Brave Browser"
                repeat with w in windows
                    set tabIdx to 1
                    repeat while tabIdx <= (count of tabs of w)
                        set t to tab tabIdx of w
                        if (URL of t contains "{term}") or (title of t contains "{term}") then
                            close t
                            set closedTab to true
                        else
                            set tabIdx to tabIdx + 1
                        end if
                    end repeat
                end repeat
            end tell
        end try
    end if

    if isRunningSafari then
        try
            tell application "Safari"
                repeat with w in windows
                    set tabIdx to 1
                    repeat while tabIdx <= (count of tabs of w)
                        set t to tab tabIdx of w
                        if (URL of t contains "{term}") or (name of t contains "{term}") then
                            close t
                            set closedTab to true
                        else
                            set tabIdx to tabIdx + 1
                        end if
                    end repeat
                end repeat
            end tell
        end try
    end if

    return closedTab
    '''
    try:
        res = subprocess.run(["osascript", "-e", applescript], capture_output=True, text=True, timeout=3)
        return "true" in res.stdout.lower()
    except Exception:
        return False


def close_active_window() -> tuple[bool, str]:
    """Close the current frontmost window/tab using macOS shortcut Command+W."""
    if platform.system() != "Darwin":
        return False, "macOS required."
    try:
        script = 'tell application "System Events" to keystroke "w" using command down'
        subprocess.run(["osascript", "-e", script], check=True, timeout=2)
        return True, "Closed the active window/tab."
    except Exception as e:
        return False, f"Could not close active window: {e}"


def is_mac_process_running(proc_name: str) -> bool:
    """Check if a process with proc_name is currently running."""
    try:
        res = subprocess.run(["pgrep", "-if", proc_name], capture_output=True, text=True, timeout=1)
        return res.returncode == 0 and bool(res.stdout.strip())
    except Exception:
        return False


def open_mac_app(app_name: str) -> tuple[bool, str]:
    """Launch an application on macOS."""
    if platform.system() != "Darwin":
        return False, "Application launching requires macOS."

    global LAST_OPENED
    LAST_OPENED = {"type": "app", "target": app_name}

    try:
        subprocess.run(["open", "-a", app_name], check=True, capture_output=True, text=True)
        return True, f"Successfully opened {app_name}."
    except subprocess.CalledProcessError as err:
        err_msg = err.stderr.strip() if err.stderr else str(err)
        if "whatsapp" in app_name.lower():
            webbrowser.open("https://web.whatsapp.com")
            LAST_OPENED = {"type": "website", "target": "whatsapp"}
            return True, "WhatsApp desktop app not installed; launched WhatsApp Web in browser."
        return False, f"Could not open {app_name}: {err_msg}"
    except Exception as err:
        if "whatsapp" in app_name.lower():
            webbrowser.open("https://web.whatsapp.com")
            LAST_OPENED = {"type": "website", "target": "whatsapp"}
            return True, "Launched WhatsApp Web in browser."
        return False, f"Error launching {app_name}: {err}"


def close_mac_app(app_name: str) -> tuple[bool, str]:
    """Gracefully close an application or web tab on macOS."""
    if platform.system() != "Darwin":
        return False, "Application closing requires macOS."

    target_lower = app_name.lower().strip()
    closed_something = False

    # 1. Check if it is a website / web app (like WhatsApp, ChatGPT, YouTube)
    web_terms = {
        "whatsapp": "whatsapp",
        "chatgpt": "chatgpt",
        "youtube": "youtube",
        "google": "google",
        "github": "github",
        "reddit": "reddit",
        "twitter": "x.com",
    }
    for site_key, search_term in web_terms.items():
        if site_key in target_lower:
            if close_browser_tab(search_term):
                closed_something = True

    # 2. Map aliases to actual macOS process / application names
    process_names = [app_name]
    if "code" in target_lower or "vscode" in target_lower:
        process_names = ["Visual Studio Code", "Code"]
    elif "chrome" in target_lower:
        process_names = ["Google Chrome"]
    elif "brave" in target_lower:
        process_names = ["Brave Browser"]
    elif "pycharm" in target_lower:
        process_names = ["PyCharm", "pycharm"]
    elif "calculator" in target_lower:
        process_names = ["Calculator"]
    elif "notes" in target_lower:
        process_names = ["Notes"]
    elif "safari" in target_lower:
        process_names = ["Safari"]
    elif "terminal" in target_lower:
        process_names = ["Terminal"]
    elif "spotify" in target_lower:
        process_names = ["Spotify"]
    elif "whatsapp" in target_lower:
        process_names = ["WhatsApp"]

    # Try AppleScript quit for each process name if running
    for pname in process_names:
        if is_mac_process_running(pname):
            try:
                res = subprocess.run(
                    ["osascript", "-e", f'tell application "{pname}" to quit'],
                    capture_output=True,
                    text=True,
                    timeout=2,
                    check=False,
                )
                if res.returncode == 0:
                    closed_something = True
            except Exception:
                pass

            # Force terminate if still running
            time.sleep(0.3)
            if is_mac_process_running(pname):
                try:
                    subprocess.run(["killall", pname], capture_output=True, text=True, check=False)
                    closed_something = True
                except Exception:
                    try:
                        subprocess.run(["pkill", "-f", pname], capture_output=True, text=True, check=False)
                        closed_something = True
                    except Exception:
                        pass

    if closed_something:
        return True, f"Closed {app_name}."

    # If it was a web tab, try browser tab closure one more time with target string
    if close_browser_tab(target_lower):
        return True, f"Closed {app_name} in browser."

    return True, f"Closed {app_name}."


def clean_command_text(text: str) -> str:
    """Normalize input command text by removing prefixes, wake words, and trailing punctuation."""
    import re
    t = text.strip()
    t = re.sub(r"[.!?]+$", "", t).strip()

    prefixes = [
        r"^hey\s+aura[\s,]+",
        r"^hi\s+aura[\s,]+",
        r"^ok\s+aura[\s,]+",
        r"^hello\s+aura[\s,]+",
        r"^aura[\s,]+",
        r"^please[\s,]+",
        r"^kindly[\s,]+",
        r"^can\s+you[\s,]+",
        r"^could\s+you[\s,]+",
        r"^will\s+you[\s,]+",
        r"^would\s+you[\s,]+",
        r"^i\s+want\s+you\s+to[\s,]+",
        r"^i\s+want\s+to[\s,]+",
    ]
    changed = True
    while changed:
        changed = False
        for p in prefixes:
            sub = re.sub(p, "", t, flags=re.IGNORECASE).strip()
            if sub != t:
                t = sub
                changed = True
    return t


def execute_command(cmd_text: str) -> Dict:
    """Core logic to interpret and execute command strings."""
    import re
    global LAST_OPENED
    raw_cmd = cmd_text.strip()
    clean_cmd = clean_command_text(raw_cmd).lower()
    timestamp = datetime.now().strftime("%H:%M:%S")

    # 1. Exit / Quit Assistant
    if clean_cmd in {"exit", "quit", "stop assistant", "bye"}:
        res = {
            "success": True,
            "type": "control",
            "message": "Assistant standing by. You can reactivate anytime.",
            "speech": "Assistant standing by.",
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    # 1b. AURA Self-Shutdown / Standby
    if clean_cmd in {"shut down", "shutdown", "shut down yourself", "shutdown yourself", "shut down aura", "shutdown aura", "close yourself", "close aura", "quit yourself", "quit aura"}:
        try:
            subprocess.run(["osascript", "-e", 'tell application "System Events" to set visible of process "AURA" to false'], timeout=2, check=False)
        except Exception:
            pass
        res = {
            "success": True,
            "type": "aura_close",
            "message": "AURA closed into background standby. Say 'open' anytime to bring me back.",
            "speech": "Closing AURA. Say open anytime to wake me up.",
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    # 1c. AURA Self-Open / Wake
    if clean_cmd in {"open", "open aura", "open yourself", "wake up", "wake up aura", "aura", "show aura"}:
        try:
            subprocess.run(["osascript", "-e", 'tell application "AURA" to activate'], timeout=2, check=False)
        except Exception:
            pass
        res = {
            "success": True,
            "type": "aura_open",
            "message": "AURA opened and ready.",
            "speech": "Opening AURA. I am ready.",
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    # 2. Close / Quit Application / Tab / Context
    close_pattern = re.compile(
        r"^(?:closing|close|quitting|quit|shutting down|shut down|terminating|terminate|killing|kill|stopping|stop|exit)\s*(?:the\s+)?(?:app\s+|application\s+)?(.*?)(?:\s+app|\s+application)?$",
        re.IGNORECASE,
    )
    m_close = close_pattern.match(clean_cmd)

    if m_close or clean_cmd in {"close", "quit", "exit"}:
        raw_target = m_close.group(1).strip() if m_close else ""

        # Contextual close: "close this", "close it", "close the app", "close current", "close window"
        if not raw_target or raw_target in {"this", "it", "current", "active", "window", "tab", "app", "application", "the app", "this app", "current app"}:
            if LAST_OPENED.get("target"):
                target_to_close = LAST_OPENED["target"]
                # Resolve app name
                matched_app = None
                target_key = SYNONYMS.get(target_to_close.lower(), target_to_close.lower())
                if target_key in APPS:
                    matched_app = APPS[target_key]["name"]
                elif target_key in WEBSITES:
                    matched_app = WEBSITES[target_key]["title"]
                app_to_close = matched_app if matched_app else target_to_close
                success, msg = close_mac_app(app_to_close)
                res = {
                    "success": success,
                    "type": "app_close",
                    "app": app_to_close,
                    "message": msg,
                    "speech": f"Closed {app_to_close}",
                    "timestamp": timestamp,
                    "command": raw_cmd,
                }
                history_log.append(res)
                return res
            else:
                success, msg = close_active_window()
                res = {
                    "success": success,
                    "type": "app_close",
                    "app": "Active Window",
                    "message": msg,
                    "speech": "Closed active window.",
                    "timestamp": timestamp,
                    "command": raw_cmd,
                }
                history_log.append(res)
                return res

        # Named target close
        target_norm = SYNONYMS.get(raw_target, raw_target)
        matched_app = None
        for key, info in APPS.items():
            if target_norm == key or target_norm == info["name"].lower() or key in target_norm:
                matched_app = info["name"]
                break

        if not matched_app:
            for key, info in WEBSITES.items():
                if target_norm == key or target_norm == info["title"].lower() or key in target_norm:
                    matched_app = info["title"]
                    break

        app_to_close = matched_app if matched_app else raw_target
        success, msg = close_mac_app(app_to_close)
        res = {
            "success": success,
            "type": "app_close",
            "app": app_to_close,
            "message": msg,
            "speech": f"Closed {app_to_close}",
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    # 3. Open Application or Website
    open_pattern = re.compile(
        r"^(?:opening|open|launching|launch|starting|start|running|run)\s*(?:the\s+)?(?:app\s+|application\s+)?(.*?)(?:\s+app|\s+application)?$",
        re.IGNORECASE,
    )
    m_open = open_pattern.match(clean_cmd)

    if m_open:
        raw_target = m_open.group(1).strip()
        target_norm = SYNONYMS.get(raw_target, raw_target)

        # Check Apps
        matched_app = None
        for key, info in APPS.items():
            if target_norm == key or target_norm == info["name"].lower() or key in target_norm:
                matched_app = info["name"]
                break

        # Check Websites
        matched_site = None
        if not matched_app:
            for key, info in WEBSITES.items():
                if target_norm == key or target_norm == info["title"].lower() or key in target_norm:
                    matched_site = info
                    break

        if matched_app:
            success, msg = open_mac_app(matched_app)
            res = {
                "success": success,
                "type": "app_open",
                "app": matched_app,
                "message": msg,
                "speech": f"Opening {matched_app}" if success else f"Unable to open {matched_app}",
                "timestamp": timestamp,
                "command": raw_cmd,
            }
            history_log.append(res)
            return res

        if matched_site:
            webbrowser.open(matched_site["url"])
            LAST_OPENED = {"type": "website", "target": matched_site["title"]}
            res = {
                "success": True,
                "type": "website_open",
                "website": matched_site["title"],
                "url": matched_site["url"],
                "message": f"Opening {matched_site['title']} in default browser.",
                "speech": f"Opening {matched_site['title']}",
                "timestamp": timestamp,
                "command": raw_cmd,
            }
            history_log.append(res)
            return res

        # Arbitrary open app name
        if raw_target and not raw_target.startswith("http"):
            success, msg = open_mac_app(raw_target)
            if success:
                res = {
                    "success": True,
                    "type": "app_open",
                    "app": raw_target,
                    "message": msg,
                    "speech": f"Opening {raw_target}",
                    "timestamp": timestamp,
                    "command": raw_cmd,
                }
                history_log.append(res)
                return res

    # 3. Open Website
    for key, info in WEBSITES.items():
        if f"open {key}" in clean_cmd or clean_cmd == f"open {info['title'].lower()}":
            webbrowser.open(info["url"])
            res = {
                "success": True,
                "type": "website_open",
                "website": info["title"],
                "url": info["url"],
                "message": f"Opening {info['title']} in default browser.",
                "speech": f"Opening {info['title']}",
                "timestamp": timestamp,
                "command": raw_cmd,
            }
            history_log.append(res)
            return res

    # 4. Search commands (Google search)
    if clean_cmd.startswith("search for ") or clean_cmd.startswith("google ") or clean_cmd.startswith("search "):
        query = clean_cmd.replace("search for ", "").replace("google ", "").replace("search ", "").strip()
        search_url = f"https://www.google.com/search?q={query.replace(' ', '+')}"
        webbrowser.open(search_url)
        res = {
            "success": True,
            "type": "search",
            "query": query,
            "url": search_url,
            "message": f"Searching Google for: '{query}'",
            "speech": f"Searching for {query}",
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    # 5. YouTube play/search
    if clean_cmd.startswith("play ") or "on youtube" in clean_cmd or clean_cmd.startswith("youtube "):
        query = (
            clean_cmd.replace("play ", "")
            .replace("on youtube", "")
            .replace("youtube ", "")
            .strip()
        )
        yt_url = f"https://www.youtube.com/results?search_query={query.replace(' ', '+')}"
        webbrowser.open(yt_url)
        res = {
            "success": True,
            "type": "media",
            "query": query,
            "url": yt_url,
            "message": f"Playing '{query}' on YouTube.",
            "speech": f"Searching YouTube for {query}",
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    # 6. Battery Status query
    if "battery" in clean_cmd:
        batt = get_battery_info()
        msg = f"Battery is at {batt.get('percent', 'unknown')} ({batt.get('status', 'N/A')}, on {batt.get('power_source', 'N/A')})."
        res = {
            "success": True,
            "type": "system_info",
            "battery": batt,
            "message": msg,
            "speech": msg,
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    # 7. Time / Date queries
    if "time" in clean_cmd:
        current_time_str = datetime.now().strftime("%I:%M %p")
        msg = f"The current time is {current_time_str}."
        res = {
            "success": True,
            "type": "system_info",
            "message": msg,
            "speech": msg,
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    if "date" in clean_cmd or "day" in clean_cmd:
        current_date_str = datetime.now().strftime("%A, %B %d, %Y")
        msg = f"Today is {current_date_str}."
        res = {
            "success": True,
            "type": "system_info",
            "message": msg,
            "speech": msg,
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    # 8. Screenshot capture
    if "screenshot" in clean_cmd:
        desktop_dir = os.path.expanduser("~/Desktop")
        filename = f"Screenshot_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
        filepath = os.path.join(desktop_dir, filename)
        try:
            subprocess.run(["screencapture", "-x", filepath], check=True)
            msg = f"Screenshot saved to Desktop: {filename}"
            res = {
                "success": True,
                "type": "system_action",
                "message": msg,
                "speech": "Screenshot captured and saved to Desktop.",
                "timestamp": timestamp,
                "command": raw_cmd,
            }
        except Exception as e:
            res = {
                "success": False,
                "type": "system_action",
                "message": f"Could not capture screenshot: {e}",
                "speech": "Could not take screenshot.",
                "timestamp": timestamp,
                "command": raw_cmd,
            }
        history_log.append(res)
        return res

    # 9. Business & Executive Assistant Commands
    brief_phrases = ["executive brief", "morning brief", "morning briefing", "daily brief", "business brief", "status report", "executive status", "brief me", "today's brief"]
    if any(p in clean_cmd for p in brief_phrases):
        p0_count = sum(1 for t in business_tasks if t.get("priority") == "P0" and not t.get("is_completed"))
        total_active = sum(1 for t in business_tasks if not t.get("is_completed"))
        date_str = datetime.now().strftime("%A, %B %d, %Y")
        brief_msg = (
            f"📊 Executive Morning Briefing ({date_str}):\n"
            f"• Critical P0 Deliverables: {p0_count}\n"
            f"• Total Active Workstreams: {total_active}\n"
            f"• Macro Sentiment: Resilient • Velocity: High\n"
            f"• Strategic Principle: 'Focus is deciding what not to do.'"
        )
        speech_msg = f"Good day, Executive. You have {p0_count} critical P0 deliverables and {total_active} active workstreams today."
        res = {
            "success": True,
            "type": "executive_brief",
            "message": brief_msg,
            "speech": speech_msg,
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    # Draft Executive Email
    if clean_cmd.startswith("draft email to ") or clean_cmd.startswith("write email to ") or clean_cmd.startswith("draft an email to ") or clean_cmd.startswith("draft email "):
        query = (
            clean_cmd.replace("draft an email to ", "")
            .replace("draft email to ", "")
            .replace("write email to ", "")
            .replace("draft email ", "")
            .strip()
        )
        recipient = "Team"
        subject = "Strategic Milestone Alignment"
        points = query
        if " about " in query:
            parts = query.split(" about ", 1)
            recipient = parts[0].strip().title()
            subject = parts[1].strip().title()
            points = subject
        elif " regarding " in query:
            parts = query.split(" regarding ", 1)
            recipient = parts[0].strip().title()
            subject = parts[1].strip().title()
            points = subject
        elif query:
            recipient = query.title()

        email_body = (
            f"Dear {recipient},\n\n"
            f"I am writing to align on key strategic decisions regarding {subject}.\n\n"
            f"Core Deliverables:\n• {points}\n\n"
            f"Action Required:\n• Please confirm deliverable owners by EOD today.\n\n"
            f"Best regards,\nExecutive Office"
        )
        res = {
            "success": True,
            "type": "executive_email",
            "recipient": recipient,
            "subject": subject,
            "body": email_body,
            "message": f"Drafted Executive Email to {recipient}:\n\nSubject: {subject}\n\n{email_body}",
            "speech": f"Drafted executive email to {recipient} regarding {subject}.",
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    # Meeting Agenda
    if clean_cmd.startswith("meeting agenda for ") or clean_cmd.startswith("prepare agenda for ") or clean_cmd.startswith("agenda for "):
        topic = (
            clean_cmd.replace("meeting agenda for ", "")
            .replace("prepare agenda for ", "")
            .replace("agenda for ", "")
            .strip()
            .title()
        )
        agenda_msg = (
            f"📅 Structured 30-Min Agenda: {topic}\n"
            f"Goal: Establish executive alignment and assign DRI deliverables.\n"
            f"• 00-05m: Executive Summary & Metric Baseline\n"
            f"• 05-18m: Strategic Options Evaluation & Tradeoffs\n"
            f"• 18-25m: Risk Mitigation & Resource Allocation\n"
            f"• 25-30m: Decision Lock & Approval Gate"
        )
        res = {
            "success": True,
            "type": "meeting_agenda",
            "title": topic,
            "message": agenda_msg,
            "speech": f"Meeting agenda for {topic} has been created.",
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    # Add Task
    if clean_cmd.startswith("add priority task ") or clean_cmd.startswith("add task ") or clean_cmd.startswith("new task "):
        task_title = (
            clean_cmd.replace("add priority task ", "")
            .replace("add task ", "")
            .replace("new task ", "")
            .strip()
            .title()
        )
        is_p0 = "priority" in clean_cmd or "critical" in clean_cmd
        priority = "P0" if is_p0 else "P1"
        new_task = {
            "id": f"task-{len(business_tasks) + 1}",
            "title": task_title,
            "priority": priority,
            "category": "Operations",
            "is_completed": False,
            "due_date": "Today",
        }
        business_tasks.insert(0, new_task)
        res = {
            "success": True,
            "type": "executive_task",
            "task": new_task,
            "message": f"Added [{priority}] deliverable: '{task_title}' to Executive Deliverables Board.",
            "speech": f"Added {task_title} to your executive task board.",
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    # Calculate Runway / Burn / LTV
    if "runway" in clean_cmd or "burn rate" in clean_cmd:
        res = {
            "success": True,
            "type": "kpi_calc",
            "message": "Financial Runway: Standard healthy runway target is 18-24 months. Formula: Cash Balance / Monthly Net Burn.",
            "speech": "Healthy runway target is 18 to 24 months. You can model this in the Executive tab.",
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    # 10. Smart assistant conversational fallback
    # If the user asks a greeting or general query
    if any(greet in clean_cmd for greet in ["hello", "hi", "hey", "who are you", "what can you do"]):
        msg = (
            "Hello! I am AURA, your Executive AI Business & Desktop Assistant. "
            "I manage strategic priorities, draft executive communications, build meeting agendas, "
            "calculate financial KPIs, and control macOS applications and system workflows."
        )
        res = {
            "success": True,
            "type": "ai_response",
            "message": msg,
            "speech": "Hello! I am AURA, your executive business assistant. How can I assist you today?",
            "timestamp": timestamp,
            "command": raw_cmd,
        }
        history_log.append(res)
        return res

    # Default fallback
    msg = f"Command recognized: '{raw_cmd}'. You can ask for 'Executive Brief', 'Draft email to team', 'Meeting agenda for sprint', or open apps like Slack, Teams, or Excel."
    res = {
        "success": False,
        "type": "unknown",
        "message": msg,
        "speech": f"I heard {raw_cmd}, but no matching action was found.",
        "timestamp": timestamp,
        "command": raw_cmd,
    }
    history_log.append(res)
    return res


# ================== BUSINESS & EXECUTIVE API ENDPOINTS ==================


@app.get("/api/business/brief")
def get_executive_brief():
    """Generate and return daily executive briefing."""
    date_str = datetime.now().strftime("%A, %B %d, %Y")
    p0_count = sum(1 for t in business_tasks if t.get("priority") == "P0" and not t.get("is_completed"))
    total_count = sum(1 for t in business_tasks if not t.get("is_completed"))
    top_tasks = [t["title"] for t in business_tasks if not t.get("is_completed")][:3]
    hour = datetime.now().hour
    greeting = "Good morning" if hour < 12 else ("Good afternoon" if hour < 17 else "Good evening")

    return {
        "date": date_str,
        "greeting": f"{greeting}, Executive",
        "quote": "Focus is a decision on what NOT to do. Protect the team's critical path.",
        "p0_count": p0_count,
        "total_active_tasks": total_count,
        "top_deliverables": top_tasks,
        "macro_sentiment": "Macro Outlook: Resilient • Tech Velocity: High",
        "speech": f"{greeting}. Here is your executive brief. You have {p0_count} critical P0 deliverables and {total_count} active tasks today.",
    }


@app.post("/api/business/email")
def generate_email_draft(req: EmailDraftRequest):
    """Draft professional executive communication tailored by tone."""
    recipient = req.recipient.strip() or "Executive Leadership"
    subject = req.subject.strip() or "Strategic Alignment"
    points = req.context_points.strip() or "Review milestones and approve deliverables."

    formatted_points = "\n".join(f"• {p.strip()}" for p in points.split("\n") if p.strip()) if "\n" in points else f"• {points}"

    body = (
        f"Dear {recipient},\n\n"
        f"I am writing to share strategic decisions concerning {subject}.\n\n"
        f"Key Highlights:\n{formatted_points}\n\n"
        f"Next Steps:\n• Please confirm ownership of deliverables by end of day.\n\n"
        f"Best regards,\nExecutive Leadership"
    )

    return {
        "recipient": recipient,
        "subject": subject,
        "body": body,
        "tone": req.tone,
        "timestamp": datetime.now().strftime("%H:%M:%S"),
    }


@app.post("/api/business/meeting")
def generate_meeting_agenda(req: MeetingAgendaRequest):
    """Build a time-blocked structured agenda."""
    title = req.title.strip() or "Strategic Alignment"
    duration = req.duration_minutes

    topics = [
        "00-05m: Executive Summary & Metric Baseline",
        "05-18m: Strategic Options Evaluation & Tradeoffs",
        "18-25m: Risk Mitigation & Resource Allocation",
        "25-30m: Decision Lock & Approval Gate",
    ] if duration <= 30 else [
        "00-10m: Strategic Context & OKR Review",
        "10-30m: Deep Dive on Core Architectural Proposals",
        "30-45m: Cross-Functional Alignment (Ops, Sales, Eng)",
        "45-60m: Final Decisions & Signed Approvals",
    ]

    return {
        "title": title,
        "duration_minutes": duration,
        "objective": req.objective,
        "topics": topics,
        "outcomes": [
            "Clear Go/No-Go decision on core proposal",
            "Documented DRI deliverables with deadlines",
        ],
    }


@app.post("/api/business/kpi")
def compute_financial_kpis(req: KpiCalcRequest):
    """Compute startup and enterprise financial metrics."""
    runway_months = req.cash_balance / req.monthly_burn if req.monthly_burn > 0 else 99.0
    ltv_cac_ratio = req.ltv / req.cac if req.cac > 0 else 0.0
    mrr_growth = ((req.current_mrr - req.prev_mrr) / req.prev_mrr * 100.0) if req.prev_mrr > 0 else 0.0
    arr = req.current_mrr * 12.0

    runway_status = "Exceptional (>24m)" if runway_months >= 24 else ("Healthy (12-24m)" if runway_months >= 12 else "Fundraising Recommended (<12m)")
    ltv_status = "World-Class (>=4x)" if ltv_cac_ratio >= 4.0 else ("Healthy SaaS Benchmark (3x)" if ltv_cac_ratio >= 3.0 else "Sub-optimal (<3x)")

    return {
        "runway_months": round(runway_months, 1),
        "runway_status": runway_status,
        "ltv_cac_ratio": round(ltv_cac_ratio, 2),
        "ltv_status": ltv_status,
        "mrr_growth_percent": round(mrr_growth, 1),
        "annualized_run_rate_arr": round(arr, 2),
    }


@app.get("/api/business/tasks")
def list_business_tasks():
    """List all corporate deliverables."""
    return {"tasks": business_tasks, "count": len(business_tasks)}


@app.post("/api/business/tasks")
def create_business_task(req: TaskCreateRequest):
    """Add a new corporate deliverable."""
    task = {
        "id": f"task-{len(business_tasks) + 1}",
        "title": req.title.strip(),
        "priority": req.priority,
        "category": req.category,
        "is_completed": False,
        "due_date": req.due_date,
    }
    business_tasks.insert(0, task)
    return {"success": True, "task": task}


# ================== SYSTEM & GENERAL API ENDPOINTS ==================


@app.get("/api/status")
def get_system_status():
    """Return backend status, macOS platform info, and uptime."""
    uptime_sec = int(time.time() - START_TIME)
    batt = get_battery_info()
    return {
        "status": "online",
        "assistant_name": "AURA",
        "platform": platform.system(),
        "platform_release": platform.release(),
        "hostname": platform.node(),
        "uptime_seconds": uptime_sec,
        "battery": batt,
        "speech_recognition_available": sr is not None,
        "timestamp": datetime.now().isoformat(),
    }


@app.get("/api/apps")
def list_apps():
    """Return list of supported applications."""
    return {"apps": APPS}


@app.post("/api/apps/open")
def open_app_endpoint(req: AppOpenRequest):
    """Open a specific registered application."""
    key = req.app.lower().strip()
    if key in APPS:
        app_name = APPS[key]["name"]
    else:
        app_name = req.app

    success, msg = open_mac_app(app_name)
    timestamp = datetime.now().strftime("%H:%M:%S")
    item = {
        "success": success,
        "type": "app_open",
        "app": app_name,
        "message": msg,
        "speech": f"Opening {app_name}" if success else f"Unable to open {app_name}",
        "timestamp": timestamp,
        "command": f"open {req.app}",
    }
    history_log.append(item)
    return item


@app.post("/api/apps/close")
def close_app_endpoint(req: AppCloseRequest):
    """Close/terminate a specific registered application."""
    key = req.app.lower().strip()
    if key in APPS:
        app_name = APPS[key]["name"]
    else:
        app_name = req.app

    success, msg = close_mac_app(app_name)
    timestamp = datetime.now().strftime("%H:%M:%S")
    item = {
        "success": success,
        "type": "app_close",
        "app": app_name,
        "message": msg,
        "speech": f"Closed {app_name}" if success else f"Could not close {app_name}",
        "timestamp": timestamp,
        "command": f"close {req.app}",
    }
    history_log.append(item)
    return item


@app.get("/api/websites")
def list_websites():
    """Return list of bookmark websites."""
    return {"websites": WEBSITES}


@app.post("/api/websites/open")
def open_website_endpoint(req: WebsiteOpenRequest):
    """Open a registered bookmark or custom URL."""
    url = req.url
    title = req.website or "Website"

    if req.website and req.website.lower() in WEBSITES:
        info = WEBSITES[req.website.lower()]
        url = info["url"]
        title = info["title"]

    if not url:
        raise HTTPException(status_code=400, detail="Missing URL or valid website key.")

    if not (url.startswith("http://") or url.startswith("https://")):
        url = f"https://{url}"

    webbrowser.open(url)
    timestamp = datetime.now().strftime("%H:%M:%S")
    item = {
        "success": True,
        "type": "website_open",
        "website": title,
        "url": url,
        "message": f"Opened {title} in browser ({url}).",
        "speech": f"Opening {title}",
        "timestamp": timestamp,
        "command": f"open {title}",
    }
    history_log.append(item)
    return item


@app.post("/api/command")
def process_command_endpoint(req: CommandRequest):
    """Primary NLP/Action command dispatch endpoint."""
    if not req.command or not req.command.strip():
        raise HTTPException(status_code=400, detail="Command string cannot be empty.")
    return execute_command(req.command)


@app.get("/api/history")
def get_history():
    """Get history of commands executed in this session."""
    return {"history": history_log, "count": len(history_log)}


@app.delete("/api/history")
def clear_history():
    """Clear command history."""
    history_log.clear()
    return {"message": "History cleared.", "count": 0}


@app.post("/api/system/control")
def system_control(req: SystemActionRequest):
    """Perform quick system actions (screenshot, sleep, say)."""
    action = req.action.lower().strip()
    timestamp = datetime.now().strftime("%H:%M:%S")

    if action == "screenshot":
        desktop_dir = os.path.expanduser("~/Desktop")
        filename = f"Screenshot_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
        filepath = os.path.join(desktop_dir, filename)
        try:
            subprocess.run(["screencapture", "-x", filepath], check=True)
            res = {
                "success": True,
                "action": action,
                "message": f"Saved screenshot to {filename}",
                "speech": "Screenshot taken and saved to Desktop.",
                "timestamp": timestamp,
            }
        except Exception as e:
            res = {
                "success": False,
                "action": action,
                "message": f"Screenshot failed: {e}",
                "speech": "Screenshot failed.",
                "timestamp": timestamp,
            }
        history_log.append(res)
        return res

    elif action == "say" and req.value:
        try:
            subprocess.Popen(["say", req.value])
            return {"success": True, "action": action, "message": f"Spoke: {req.value}"}
        except Exception as e:
            return {"success": False, "action": action, "message": str(e)}

    raise HTTPException(status_code=400, detail=f"Unsupported action: {action}")


# Ensure frontend static directory / built React app is served
FRONTEND_DIST = os.path.join(os.path.dirname(__file__), "frontend", "dist")
FRONTEND_DIR = os.path.join(os.path.dirname(__file__), "frontend")

if os.path.exists(os.path.join(FRONTEND_DIST, "assets")):
    app.mount("/assets", StaticFiles(directory=os.path.join(FRONTEND_DIST, "assets")), name="assets")

@app.get("/")
def serve_index():
    if os.path.exists(os.path.join(FRONTEND_DIST, "index.html")):
        return FileResponse(os.path.join(FRONTEND_DIST, "index.html"))
    if os.path.exists(os.path.join(FRONTEND_DIR, "index.html")):
        return FileResponse(os.path.join(FRONTEND_DIR, "index.html"))
    return {"message": "AURA API Backend Online. Please build or start the frontend."}


if __name__ == "__main__":
    import uvicorn

    print("=" * 60)
    print("AURA AI PERSONAL VOICE & SYSTEM ASSISTANT")
    print("Starting API Server on http://localhost:8000")
    print("=" * 60)
    uvicorn.run("server:app", host="127.0.0.1", port=8000, reload=True)
