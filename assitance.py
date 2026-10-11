import os
import platform
import subprocess
import webbrowser
from datetime import datetime

try:
    # pyrefly: ignore [missing-import]
    import speech_recognition as sr
except ImportError:
    sr = None

# Comprehensive dictionary of supported macOS applications
APPS = {
    "chrome": "Google Chrome",
    "safari": "Safari",
    "calculator": "Calculator",
    "notes": "Notes",
    "terminal": "Terminal",
    "pycharm": "PyCharm",
    "vscode": "Visual Studio Code",
    "spotify": "Spotify",
    "finder": "Finder",
    "slack": "Slack",
    "whatsapp": "WhatsApp",
    "settings": "System Settings",
}

WEBSITES = {
    "whatsapp": "https://web.whatsapp.com",
    "chatgpt": "https://chatgpt.com",
    "youtube": "https://www.youtube.com",
    "google": "https://www.google.com",
    "github": "https://github.com",
    "reddit": "https://www.reddit.com",
    "twitter": "https://x.com",
}


LAST_OPENED = {"type": "", "target": ""}

SYNONYMS = {
    "google chrome": "chrome",
    "chrome": "chrome",
    "brave": "brave",
    "brave browser": "brave",
    "safari": "safari",
    "calculator": "calculator",
    "calc": "calculator",
    "notes": "notes",
    "note": "notes",
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
}


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


def is_mac_process_running(proc_name: str) -> bool:
    try:
        res = subprocess.run(["pgrep", "-if", proc_name], capture_output=True, text=True, timeout=1)
        return res.returncode == 0 and bool(res.stdout.strip())
    except Exception:
        return False


def open_app(app_name):
    """Open an application on macOS."""
    if platform.system() != "Darwin":
        print("This assistant currently supports macOS only.")
        return False

    global LAST_OPENED
    LAST_OPENED = {"type": "app", "target": app_name}

    try:
        subprocess.run(
            ["open", "-a", app_name],
            check=True,
            capture_output=True,
            text=True,
        )
        print(f"Opening {app_name}...")
        return True
    except subprocess.CalledProcessError as error:
        if "whatsapp" in app_name.lower():
            print("WhatsApp desktop app not found, opening WhatsApp Web...")
            webbrowser.open("https://web.whatsapp.com")
            LAST_OPENED = {"type": "website", "target": "whatsapp"}
            return True
        print(f"Could not open {app_name}.")
        if error.stderr:
            print(error.stderr.strip())
        return False
    except OSError as error:
        if "whatsapp" in app_name.lower():
            webbrowser.open("https://web.whatsapp.com")
            LAST_OPENED = {"type": "website", "target": "whatsapp"}
            return True
        print(f"Application error: {error}")
        return False


def close_app(app_name):
    """Close/Quit an application or web tab on macOS."""
    if platform.system() != "Darwin":
        print("This assistant currently supports macOS only.")
        return False

    target_lower = app_name.lower().strip()
    closed_something = False

    # Check web tabs
    for site_key in ["whatsapp", "chatgpt", "youtube", "google", "github", "reddit", "twitter"]:
        if site_key in target_lower:
            if close_browser_tab(site_key):
                closed_something = True

    # Process names for macOS quit
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

    if close_browser_tab(target_lower):
        closed_something = True

    print(f"Closed {app_name}.")
    return True


def get_battery():
    """Retrieve macOS battery percentage."""
    if platform.system() != "Darwin":
        return "Battery info available on macOS only."
    try:
        res = subprocess.run(["pmset", "-g", "batt"], capture_output=True, text=True, check=False)
        output = res.stdout
        for line in output.splitlines():
            if "%" in line:
                for part in line.split(";"):
                    if "%" in part:
                        return f"Battery is at {part.strip()}"
        return "Battery status checked."
    except Exception as e:
        return f"Battery error: {e}"


def clean_command(text: str) -> str:
    import re
    t = text.strip()
    t = re.sub(r"[.!?]+$", "", t).strip()
    prefixes = [
        r"^hey\s+aura[\s,]+",
        r"^hi\s+aura[\s,]+",
        r"^ok\s+aura[\s,]+",
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


def process_command(command):
    """Process a recognized voice or text command."""
    import re
    if not command:
        return True

    global LAST_OPENED
    raw_command = command.strip()
    command = clean_command(raw_command).lower()

    if command in {"exit", "quit", "stop assistant", "bye"}:
        print("Goodbye!")
        return False

    # AURA Self-Shutdown / Close
    if command in {"shut down", "shutdown", "shut down yourself", "shutdown yourself", "shut down aura", "shutdown aura", "close yourself", "close aura", "quit yourself", "quit aura"}:
        print("Closing AURA into background standby. Say 'open' to wake me up.")
        try:
            subprocess.run(["osascript", "-e", 'tell application "System Events" to set visible of process "AURA" to false'], timeout=2, check=False)
        except Exception:
            pass
        return True

    # AURA Self-Open / Wake
    if command in {"open", "open aura", "open yourself", "wake up", "wake up aura", "aura", "show aura"}:
        print("Opening AURA...")
        try:
            subprocess.run(["osascript", "-e", 'tell application "AURA" to activate'], timeout=2, check=False)
        except Exception:
            pass
        return True

    # Close Application Commands
    close_pattern = re.compile(
        r"^(?:closing|close|quitting|quit|shutting down|shut down|terminating|terminate|killing|kill|stopping|stop|exit)\s*(?:the\s+)?(?:app\s+|application\s+)?(.*?)(?:\s+app|\s+application)?$",
        re.IGNORECASE,
    )
    m_close = close_pattern.match(command)

    if m_close or command in {"close", "quit", "exit"}:
        raw_target = m_close.group(1).strip() if m_close else ""
        if not raw_target or raw_target in {"this", "it", "current", "active", "window", "tab", "app", "application", "the app", "this app"}:
            if LAST_OPENED.get("target"):
                target = LAST_OPENED["target"]
                app_to_close = APPS.get(target.lower(), target)
                close_app(app_to_close)
                return True
            else:
                try:
                    subprocess.run(["osascript", "-e", 'tell application "System Events" to keystroke "w" using command down'], timeout=2)
                    print("Closed active window.")
                    return True
                except Exception:
                    pass

        target_norm = SYNONYMS.get(raw_target, raw_target)
        matched_app = None
        for keyword, app_name in APPS.items():
            if target_norm == keyword or target_norm == app_name.lower() or keyword in target_norm:
                matched_app = app_name
                break

        app_to_close = matched_app if matched_app else raw_target
        close_app(app_to_close)
        return True

    # Open Application Commands
    open_pattern = re.compile(
        r"^(?:opening|open|launching|launch|starting|start|running|run)\s*(?:the\s+)?(?:app\s+|application\s+)?(.*?)(?:\s+app|\s+application)?$",
        re.IGNORECASE,
    )
    m_open = open_pattern.match(command)

    if m_open:
        raw_target = m_open.group(1).strip()
        target_norm = SYNONYMS.get(raw_target, raw_target)

        # 1. Apps
        for keyword, app_name in APPS.items():
            if target_norm == keyword or target_norm == app_name.lower() or keyword in target_norm:
                open_app(app_name)
                return True

        # 2. Websites
        for keyword, url in WEBSITES.items():
            if target_norm == keyword or keyword in target_norm:
                try:
                    webbrowser.open(url)
                    LAST_OPENED = {"type": "website", "target": keyword}
                    print(f"Opening {keyword.title()}...")
                except Exception as error:
                    print(f"Browser error: {error}")
                return True

        if raw_target and not raw_target.startswith("http"):
            open_app(raw_target)
            return True

    # 2. Websites
    for keyword, url in WEBSITES.items():
        if f"open {keyword}" in command:
            try:
                webbrowser.open(url)
                print(f"Opening {keyword.title()}...")
            except Exception as error:
                print(f"Browser error: {error}")
            return True

    # 3. Google Search
    if command.startswith("search for ") or command.startswith("google ") or command.startswith("search "):
        query = command.replace("search for ", "").replace("google ", "").replace("search ", "").strip()
        search_url = f"https://www.google.com/search?q={query.replace(' ', '+')}"
        webbrowser.open(search_url)
        print(f"Searching Google for '{query}'...")
        return True

    # 4. YouTube
    if command.startswith("play ") or "on youtube" in command:
        query = command.replace("play ", "").replace("on youtube", "").strip()
        yt_url = f"https://www.youtube.com/results?search_query={query.replace(' ', '+')}"
        webbrowser.open(yt_url)
        print(f"Playing '{query}' on YouTube...")
        return True

    # 5. Battery
    if "battery" in command:
        info = get_battery()
        print(info)
        return True

    # 6. Time & Date
    if "time" in command:
        now_time = datetime.now().strftime("%I:%M %p")
        print(f"Current time: {now_time}")
        return True

    if "date" in command or "day" in command:
        now_date = datetime.now().strftime("%A, %B %d, %Y")
        print(f"Today is {now_date}")
        return True

    # 7. Screenshot
    if "screenshot" in command:
        desktop_dir = os.path.expanduser("~/Desktop")
        filename = f"Screenshot_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
        filepath = os.path.join(desktop_dir, filename)
        try:
            subprocess.run(["screencapture", "-x", filepath], check=True)
            print(f"Screenshot saved to Desktop: {filename}")
        except Exception as e:
            print(f"Screenshot error: {e}")
        return True

    print(f"Command not recognized: {raw_command}")
    return True


def listen():
    """Listen to the microphone and convert speech to text."""
    if sr is None:
        print("SpeechRecognition is not installed.")
        print("Run: python -m pip install SpeechRecognition")
        return ""

    recognizer = sr.Recognizer()
    # Don't cut off speech when the user pauses briefly
    recognizer.pause_threshold = 2.2
    recognizer.non_speaking_duration = 0.8

    try:
        with sr.Microphone() as source:
            print("\nListening... Speak now (brief pauses allowed).")
            recognizer.adjust_for_ambient_noise(source, duration=0.5)
            audio = recognizer.listen(source, timeout=8, phrase_time_limit=15)

        command = recognizer.recognize_google(audio, language="en-IN")
        print("You said:", command)
        return command

    except sr.WaitTimeoutError:
        print("No speech detected. Try again.")
    except sr.UnknownValueError:
        print("Sorry, I could not understand.")
    except sr.RequestError as error:
        print("Speech recognition service error:", error)
    except (OSError, AttributeError) as error:
        print("Microphone error:", error)
        print("Check microphone permissions and PyAudio.")

    return ""


def main():
    print("=" * 50)
    print("AURA — AI PERSONAL VOICE ASSISTANT")
    print("=" * 50)
    print("Say or type: open Chrome")
    print("Say or type: open Calculator")
    print("Say or type: open ChatGPT")
    print("Say or type: play Jazz on YouTube")
    print("Say or type: battery status")
    print("Say or type: stop assistant")

    if platform.system() != "Darwin":
        print("Warning: Application launching requires macOS.")

    while True:
        try:
            if sr is not None:
                command = listen()
            else:
                command = input("\nEnter command (or 'exit'): ")

            if command and not process_command(command):
                break
        except KeyboardInterrupt:
            print("\nStopping assistant.")
            break


if __name__ == "__main__":
    main()
