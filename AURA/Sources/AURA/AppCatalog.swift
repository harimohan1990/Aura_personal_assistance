import Foundation
import AppKit

public final class AppCatalog: @unchecked Sendable {
    public static let shared = AppCatalog()

    private init() {}

    // MARK: - Scan Real Installed macOS Applications
    public func scanInstalledApps() -> [AppItem] {
        var results: [AppItem] = []
        var seenNames = Set<String>()

        let searchDirs = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/System/Applications/Utilities"),
            URL(fileURLWithPath: "/Applications/Utilities"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        let fileManager = FileManager.default

        for dir in searchDirs {
            guard let items = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
                continue
            }

            for item in items where item.pathExtension == "app" {
                let appName = item.deletingPathExtension().lastPathComponent
                let lowerName = appName.lowercased()

                if seenNames.contains(lowerName) { continue }
                seenNames.insert(lowerName)

                let category = categorizeApp(name: lowerName)
                let icon = iconForApp(name: lowerName, category: category)

                results.append(AppItem(
                    key: lowerName,
                    name: appName,
                    category: category,
                    icon: icon,
                    isInstalled: true,
                    bundlePath: item.path
                ))
            }
        }

        return results.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    private func categorizeApp(name: String) -> String {
        if name.contains("code") || name.contains("terminal") || name.contains("xcode") || name.contains("pycharm") || name.contains("git") || name.contains("docker") || name.contains("postman") || name.contains("sublime") || name.contains("warp") || name.contains("intellij") || name.contains("studio") {
            return "Developer"
        } else if name.contains("chrome") || name.contains("safari") || name.contains("brave") || name.contains("firefox") || name.contains("edge") || name.contains("arc") || name.contains("opera") || name.contains("browser") {
            return "Browsers"
        } else if name.contains("note") || name.contains("notion") || name.contains("obsidian") || name.contains("pages") || name.contains("numbers") || name.contains("keynote") || name.contains("remind") || name.contains("cal") || name.contains("todo") || name.contains("word") || name.contains("excel") || name.contains("powerpoint") || name.contains("docs") || name.contains("sheets") {
            return "Productivity"
        } else if name.contains("slack") || name.contains("whatsapp") || name.contains("telegram") || name.contains("discord") || name.contains("zoom") || name.contains("teams") || name.contains("message") || name.contains("mail") || name.contains("facetime") || name.contains("chat") {
            return "Communication"
        } else if name.contains("music") || name.contains("spotify") || name.contains("tv") || name.contains("podcast") || name.contains("vlc") || name.contains("quicktime") || name.contains("youtube") || name.contains("netflix") || name.contains("player") {
            return "Media"
        } else if name.contains("figma") || name.contains("photo") || name.contains("illustrat") || name.contains("premiere") || name.contains("canva") || name.contains("sketch") || name.contains("blender") || name.contains("design") || name.contains("davinci") {
            return "Design"
        } else if name.contains("calc") || name.contains("sett") || name.contains("util") || name.contains("system") || name.contains("activ") || name.contains("disk") || name.contains("finder") || name.contains("preview") || name.contains("clean") {
            return "Utilities"
        } else if name.contains("gpt") || name.contains("claude") || name.contains("ai") || name.contains("ollama") || name.contains("perplexity") || name.contains("gemini") || name.contains("deepseek") {
            return "AI Tools"
        }
        return "General"
    }

    private func iconForApp(name: String, category: String) -> String {
        if name.contains("calc") { return "divide.circle.fill" }
        if name.contains("chrome") || name.contains("safari") || name.contains("brave") || name.contains("firefox") || name.contains("browser") { return "globe" }
        if name.contains("terminal") || name.contains("iterm") || name.contains("warp") { return "terminal.fill" }
        if name.contains("code") || name.contains("xcode") || name.contains("pycharm") || name.contains("cursor") { return "chevron.left.forwardslash.chevron.right" }
        if name.contains("note") { return "note.text" }
        if name.contains("mail") || name.contains("outlook") || name.contains("spark") { return "envelope.fill" }
        if name.contains("cal") { return "calendar" }
        if name.contains("music") || name.contains("spotify") { return "music.note" }
        if name.contains("message") || name.contains("chat") || name.contains("slack") || name.contains("whatsapp") || name.contains("telegram") || name.contains("discord") { return "bubble.left.and.bubble.right.fill" }
        if name.contains("photo") || name.contains("figma") || name.contains("canva") { return "paintpalette.fill" }
        if name.contains("sett") { return "gearshape.fill" }
        if name.contains("finder") { return "folder.fill" }
        if name.contains("video") || name.contains("tv") || name.contains("zoom") || name.contains("meet") { return "video.fill" }
        if name.contains("gpt") || name.contains("ai") || name.contains("claude") { return "brain.head.profile" }

        switch category {
        case "Developer": return "hammer.fill"
        case "Browsers": return "safari"
        case "Productivity": return "doc.text.fill"
        case "Communication": return "phone.fill"
        case "Media": return "play.circle.fill"
        case "Design": return "pencil.tip.crop.circle"
        case "Utilities": return "wrench.and.screwdriver.fill"
        case "AI Tools": return "sparkles"
        default: return "app.fill"
        }
    }

    // MARK: - Curated Real 500+ Most Used Applications Database
    public lazy var catalog500: [AppItem] = {
        let rawItems: [(String, String, String, String)] = [
            // 1. macOS System Apps & Built-in Utilities (40)
            ("calculator", "Calculator", "Utilities", "divide.circle.fill"),
            ("system settings", "System Settings", "Utilities", "gearshape.fill"),
            ("activity monitor", "Activity Monitor", "Utilities", "waveform.path.ecg"),
            ("terminal", "Terminal", "Developer", "terminal.fill"),
            ("finder", "Finder", "Utilities", "folder.fill"),
            ("preview", "Preview", "Utilities", "doc.viewfinder"),
            ("textedit", "TextEdit", "Utilities", "pencil.line"),
            ("disk utility", "Disk Utility", "Utilities", "opticaldiscdrive.fill"),
            ("keychain access", "Keychain Access", "Utilities", "key.fill"),
            ("app store", "App Store", "Utilities", "bag.fill"),
            ("font book", "Font Book", "Utilities", "textformat"),
            ("screenshot", "Screenshot", "Utilities", "camera.fill"),
            ("shortcuts", "Shortcuts", "Utilities", "square.2.layers.3d.top.filled"),
            ("automator", "Automator", "Utilities", "robot"),
            ("quicktime player", "QuickTime Player", "Media", "play.rectangle.fill"),
            ("archive utility", "Archive Utility", "Utilities", "archivebox.fill"),
            ("voice memos", "Voice Memos", "Utilities", "mic.fill"),
            ("stocks", "Stocks", "Utilities", "chart.line.uptrend.xyaxis"),
            ("weather", "Weather", "Utilities", "cloud.sun.fill"),
            ("clock", "Clock", "Utilities", "clock.fill"),
            ("maps", "Apple Maps", "Utilities", "map.fill"),
            ("photos", "Apple Photos", "Media", "photo.on.rectangle.angled"),
            ("books", "Apple Books", "Productivity", "book.fill"),
            ("home", "Apple Home", "Utilities", "house.fill"),
            ("find my", "Find My", "Utilities", "location.circle.fill"),
            ("contacts", "Contacts", "Communication", "person.crop.circle.fill"),
            ("time machine", "Time Machine", "Utilities", "clock.arrow.circlepath"),
            ("colorsync utility", "ColorSync Utility", "Utilities", "eyedropper.halffull"),
            ("grapher", "Grapher", "Utilities", "function"),
            ("migration assistant", "Migration Assistant", "Utilities", "arrow.right.arrow.left"),
            ("system information", "System Information", "Utilities", "info.circle.fill"),
            ("audio midi setup", "Audio MIDI Setup", "Media", "pianokeys"),
            ("bluetooth file exchange", "Bluetooth Exchange", "Utilities", "dot.radiowaves.left.and.right"),
            ("boot camp assistant", "Boot Camp Assistant", "Utilities", "externaldrive.badge.person.crop"),
            ("digital colormeter", "Digital Color Meter", "Utilities", "eyedropper"),
            ("directory utility", "Directory Utility", "Utilities", "folder.badge.gearshape"),
            ("freeform", "Freeform", "Productivity", "scribble.variable"),
            ("tips", "Tips", "Utilities", "lightbulb.fill"),
            ("chess", "Chess", "Media", "checkerboard.rectangle"),
            ("stickies", "Stickies", "Productivity", "note"),

            // 2. Web Browsers (20)
            ("google chrome", "Google Chrome", "Browsers", "globe"),
            ("safari", "Safari", "Browsers", "safari"),
            ("brave", "Brave Browser", "Browsers", "shield.checkerboard"),
            ("firefox", "Firefox", "Browsers", "flame.fill"),
            ("arc", "Arc Browser", "Browsers", "circle.hexagongrid.fill"),
            ("microsoft edge", "Microsoft Edge", "Browsers", "globe.badge.chevron.backward"),
            ("opera", "Opera", "Browsers", "circle.dashed"),
            ("opera gx", "Opera GX", "Browsers", "gamecontroller.fill"),
            ("vivaldi", "Vivaldi", "Browsers", "v.circle.fill"),
            ("tor browser", "Tor Browser", "Browsers", "lock.shield.fill"),
            ("duckduckgo", "DuckDuckGo Browser", "Browsers", "magnifyingglass.circle.fill"),
            ("orion browser", "Orion Browser", "Browsers", "safari.fill"),
            ("sidekick", "Sidekick Browser", "Browsers", "bolt.shield"),
            ("chromium", "Chromium", "Browsers", "globe.badge.clock"),
            ("waterfox", "Waterfox", "Browsers", "drop.fill"),
            ("brave beta", "Brave Beta", "Browsers", "shield"),
            ("chrome canary", "Chrome Canary", "Browsers", "bird.fill"),
            ("firefox developer edition", "Firefox Dev Edition", "Browsers", "wrench.fill"),
            ("safari technology preview", "Safari Tech Preview", "Browsers", "gear"),
            ("sigmaos", "SigmaOS", "Browsers", "command"),

            // 3. Developer Tools & Code Editors (60)
            ("visual studio code", "Visual Studio Code", "Developer", "chevron.left.forwardslash.chevron.right"),
            ("xcode", "Xcode", "Developer", "hammer.fill"),
            ("pycharm", "PyCharm", "Developer", "curlybraces"),
            ("pycharm community", "PyCharm Community", "Developer", "curlybraces"),
            ("intellij idea", "IntelliJ IDEA", "Developer", "chevron.left.forwardslash.chevron.right"),
            ("webstorm", "WebStorm", "Developer", "chevron.left.forwardslash.chevron.right"),
            ("sublime text", "Sublime Text", "Developer", "doc.plaintext"),
            ("docker desktop", "Docker Desktop", "Developer", "shippingbox.fill"),
            ("postman", "Postman", "Developer", "paperplane.fill"),
            ("insomnia", "Insomnia", "Developer", "moon.fill"),
            ("iterm2", "iTerm2", "Developer", "terminal"),
            ("warp", "Warp Terminal", "Developer", "terminal.fill"),
            ("gitkraken", "GitKraken", "Developer", "arrow.triangle.branch"),
            ("sourcetree", "SourceTree", "Developer", "arrow.triangle.branch"),
            ("fork", "Fork Git Client", "Developer", "tuningfork"),
            ("tower", "Tower Git", "Developer", "building.2.fill"),
            ("tableplus", "TablePlus", "Developer", "cylinder.split.1x2.fill"),
            ("dbeaver", "DBeaver", "Developer", "cylinder.fill"),
            ("android studio", "Android Studio", "Developer", "phone.fill"),
            ("cursor", "Cursor AI IDE", "Developer", "sparkles.square.filled.on.square"),
            ("zed", "Zed Editor", "Developer", "bolt.fill"),
            ("clion", "CLion", "Developer", "chevron.left.forwardslash.chevron.right"),
            ("goland", "GoLand", "Developer", "chevron.left.forwardslash.chevron.right"),
            ("rider", "JetBrains Rider", "Developer", "chevron.left.forwardslash.chevron.right"),
            ("datagrip", "DataGrip", "Developer", "cylinder.split.1x2"),
            ("phpstorm", "PhpStorm", "Developer", "chevron.left.forwardslash.chevron.right"),
            ("rubymine", "RubyMine", "Developer", "gem"),
            ("appcode", "AppCode", "Developer", "hammer"),
            ("wireshark", "Wireshark", "Developer", "antenna.radiowaves.left.and.right"),
            ("cyberduck", "Cyberduck", "Developer", "arrow.up.doc.fill"),
            ("filezilla", "FileZilla", "Developer", "folder.badge.gearshape"),
            ("transmit", "Transmit 5", "Developer", "arrow.triangle.2.circlepath"),
            ("paw", "RapidAPI (Paw)", "Developer", "network"),
            ("mongodb compass", "MongoDB Compass", "Developer", "leaf.fill"),
            ("redis insight", "Redis Insight", "Developer", "bolt.ring.closed"),
            ("pgadmin", "pgAdmin 4", "Developer", "cylinder"),
            ("mysql workbench", "MySQL Workbench", "Developer", "server.rack"),
            ("sublime merge", "Sublime Merge", "Developer", "rectangle.split.2x1"),
            ("alacritty", "Alacritty", "Developer", "terminal"),
            ("kitty", "Kitty Terminal", "Developer", "cat.fill"),
            ("virtualbox", "VirtualBox", "Developer", "cube.transparent"),
            ("utm", "UTM Virtual Machines", "Developer", "desktopcomputer"),
            ("parallels desktop", "Parallels Desktop", "Developer", "window.vertical.closed"),
            ("vmware fusion", "VMware Fusion", "Developer", "square.stack.3d.down.right"),
            ("lens", "Lens Kubernetes", "Developer", "viewfinder"),
            ("k9s", "K9s Kubernetes", "Developer", "server.rack"),
            ("homebrew", "Homebrew CLI", "Developer", "mug.fill"),
            ("git", "Git Version Control", "Developer", "arrow.triangle.branch"),
            ("node.js", "Node.js Runtime", "Developer", "hexagon.fill"),
            ("python", "Python Engine", "Developer", "curlybraces"),
            ("ruby", "Ruby", "Developer", "suit.diamond.fill"),
            ("rust", "Rust Compiler (cargo)", "Developer", "gear"),
            ("golang", "Go Compiler", "Developer", "arrow.forward.circle.fill"),
            ("java", "Java JDK", "Developer", "cup.and.saucer.fill"),
            ("cmake", "CMake", "Developer", "hammer.circle"),
            ("gradle", "Gradle", "Developer", "square.stack.3d.up"),
            ("maven", "Maven", "Developer", "feather"),
            ("insomnia designer", "Insomnia Designer", "Developer", "doc.text.below.ecg"),
            ("hoppscotch", "Hoppscotch", "Developer", "paperplane"),
            ("proxyman", "Proxyman HTTP Proxy", "Developer", "shield.lefthalf.filled"),

            // 4. Communication & Messaging (40)
            ("whatsapp", "WhatsApp", "Communication", "message.fill"),
            ("whatsapp web", "WhatsApp Web", "Communication", "message.circle.fill"),
            ("slack", "Slack", "Communication", "bubble.left.and.bubble.right.fill"),
            ("discord", "Discord", "Communication", "gamecontroller.fill"),
            ("telegram", "Telegram", "Communication", "paperplane.fill"),
            ("zoom", "Zoom", "Communication", "video.fill"),
            ("microsoft teams", "Microsoft Teams", "Communication", "person.3.fill"),
            ("skype", "Skype", "Communication", "phone.circle.fill"),
            ("signal", "Signal", "Communication", "lock.shield.fill"),
            ("messages", "Messages (iMessage)", "Communication", "message.badge.filled.fill"),
            ("facetime", "FaceTime", "Communication", "video.badge.checkmark"),
            ("mail", "Apple Mail", "Communication", "envelope.fill"),
            ("microsoft outlook", "Microsoft Outlook", "Communication", "envelope.badge.shield.half.filled"),
            ("google meet", "Google Meet", "Communication", "video.circle.fill"),
            ("google chat", "Google Chat", "Communication", "message"),
            ("thunderbird", "Thunderbird", "Communication", "envelope.open.fill"),
            ("spark mail", "Spark Mail", "Communication", "sparkles.rectangle.stack"),
            ("airmail", "Airmail", "Communication", "airplane"),
            ("canary mail", "Canary Mail", "Communication", "lock.fill"),
            ("mailspring", "Mailspring", "Communication", "paperplane"),
            ("wechat", "WeChat", "Communication", "bubble.left.and.exclamationmark.bubble.right.fill"),
            ("viber", "Viber", "Communication", "phone.down.fill"),
            ("line", "Line", "Communication", "bubble.left.fill"),
            ("element", "Element Matrix", "Communication", "lock.square"),
            ("keybase", "Keybase", "Communication", "key.icloud"),
            ("mumble", "Mumble Voice", "Communication", "speaker.wave.2"),
            ("mattermost", "Mattermost", "Communication", "bubble.middle.bottom"),
            ("rocketchat", "Rocket.Chat", "Communication", "flame"),
            ("zulip", "Zulip", "Communication", "bubble.right"),
            ("flock", "Flock", "Communication", "person.2"),
            ("twist", "Twist", "Communication", "arrow.turn.down.right"),
            ("tandem", "Tandem Virtual Office", "Communication", "person.2.circle"),
            ("gather", "Gather Town", "Communication", "house.and.flag"),
            ("around", "Around Video", "Communication", "video.bubble.left"),
            ("loom", "Loom Video Recorder", "Communication", "record.circle"),
            ("webex", "Cisco Webex", "Communication", "phone.bubble.left"),
            ("ringcentral", "RingCentral", "Communication", "phone.connection"),
            ("gotomeeting", "GoToMeeting", "Communication", "person.crop.rectangle"),
            ("bluejeans", "BlueJeans", "Communication", "video.slash"),
            ("dialpad", "Dialpad", "Communication", "phone.badge.plus"),

            // 5. Productivity & Office Suites (60)
            ("notes", "Apple Notes", "Productivity", "note.text"),
            ("notion", "Notion", "Productivity", "doc.text.image.fill"),
            ("obsidian", "Obsidian", "Productivity", "diamond.fill"),
            ("reminders", "Reminders", "Productivity", "checklist"),
            ("calendar", "Calendar", "Productivity", "calendar"),
            ("microsoft word", "Microsoft Word", "Productivity", "doc.fill"),
            ("microsoft excel", "Microsoft Excel", "Productivity", "tablecells.fill"),
            ("microsoft powerpoint", "Microsoft PowerPoint", "Productivity", "rectangle.inset.filled.and.person.filled"),
            ("microsoft onenote", "Microsoft OneNote", "Productivity", "note.text.badge.plus"),
            ("pages", "Pages", "Productivity", "doc.richtext.fill"),
            ("numbers", "Numbers", "Productivity", "tablecells"),
            ("keynote", "Keynote", "Productivity", "presentation"),
            ("google docs", "Google Docs", "Productivity", "doc.plaintext.fill"),
            ("google sheets", "Google Sheets", "Productivity", "tablecells.badge.ellipsis"),
            ("google slides", "Google Slides", "Productivity", "rectangle.portrait.and.arrow.forward"),
            ("google keep", "Google Keep", "Productivity", "lightbulb.fill"),
            ("todoist", "Todoist", "Productivity", "checkmark.circle.fill"),
            ("things 3", "Things 3", "Productivity", "checkmark.seal.fill"),
            ("ticktick", "TickTick", "Productivity", "clock.badge.checkmark"),
            ("evernote", "Evernote", "Productivity", "square.and.pencil"),
            ("bear", "Bear Notes", "Productivity", "pawprint.fill"),
            ("craft", "Craft Docs", "Productivity", "doc.text"),
            ("goodnotes", "GoodNotes", "Productivity", "pencil.tip"),
            ("notability", "Notability", "Productivity", "pencil.and.scribble"),
            ("logseq", "Logseq", "Productivity", "circle.dashed.rectangle"),
            ("roam research", "Roam Research", "Productivity", "point.3.filled.connected.trianglepath.dotted"),
            ("linear", "Linear Issue Tracker", "Productivity", "arrow.triangle.pull"),
            ("jira", "Jira Software", "Productivity", "square.split.diagonal.2x2"),
            ("confluence", "Confluence", "Productivity", "book.closed.fill"),
            ("asana", "Asana", "Productivity", "circle.grid.3x3.fill"),
            ("trello", "Trello", "Productivity", "rectangle.3.group.fill"),
            ("monday.com", "Monday.com", "Productivity", "calendar.day.timeline.left"),
            ("clickup", "ClickUp", "Productivity", "hand.thumbsup.fill"),
            ("basecamp", "Basecamp", "Productivity", "tent.fill"),
            ("fantastical", "Fantastical", "Productivity", "calendar.badge.clock"),
            ("cron", "Notion Calendar (Cron)", "Productivity", "calendar.circle.fill"),
            ("omnifocus", "OmniFocus", "Productivity", "target"),
            ("coda", "Coda", "Productivity", "doc.on.doc.fill"),
            ("airtable", "Airtable", "Productivity", "tablecells.badge.ellipsis"),
            ("google drive", "Google Drive", "Productivity", "externaldrive.fill"),
            ("dropbox", "Dropbox", "Productivity", "cube.box.fill"),
            ("onedrive", "OneDrive", "Productivity", "cloud.fill"),
            ("box", "Box Cloud", "Productivity", "shippingbox"),
            ("icloud drive", "iCloud Drive", "Productivity", "icloud.fill"),
            ("nextcloud", "Nextcloud", "Productivity", "cloud.rainbow.half"),
            ("mega", "MEGA Cloud", "Productivity", "m.circle.fill"),
            ("pcloud", "pCloud", "Productivity", "cloud.sun"),
            ("smartsheet", "Smartsheet", "Productivity", "list.bullet.rectangle"),
            ("wrike", "Wrike", "Productivity", "w.circle.fill"),
            ("scrivener", "Scrivener", "Productivity", "book"),
            ("ulysses", "Ulysses", "Productivity", "pencil"),
            ("ia writer", "iA Writer", "Productivity", "doc.plaintext"),
            ("byword", "Byword", "Productivity", "b.circle"),
            ("mindnode", "MindNode", "Productivity", "network"),
            ("xmind", "XMind", "Productivity", "brain.head.profile"),
            ("lucidchart", "Lucidchart", "Productivity", "rectangle.connected.to.line.below"),
            ("miro", "Miro Collaborative Board", "Productivity", "hand.draw.fill"),
            ("mural", "Mural", "Productivity", "rectangle.3.group"),
            ("workflowy", "WorkFlowy", "Productivity", "list.dash"),
            ("dynalist", "Dynalist", "Productivity", "list.bullet"),

            // 6. Design, Creative & Video Editing (60)
            ("figma", "Figma", "Design", "paintpalette.fill"),
            ("figma desktop", "Figma Desktop", "Design", "paintpalette.fill"),
            ("canva", "Canva", "Design", "swatchpalette.fill"),
            ("adobe photoshop", "Adobe Photoshop", "Design", "photo.fill"),
            ("adobe illustrator", "Adobe Illustrator", "Design", "paintbrush.fill"),
            ("adobe premiere pro", "Adobe Premiere Pro", "Design", "film.fill"),
            ("adobe after effects", "Adobe After Effects", "Design", "sparkles.tv.fill"),
            ("adobe lightroom", "Adobe Lightroom", "Design", "camera.filters"),
            ("adobe xd", "Adobe XD", "Design", "rectangle.dashed"),
            ("adobe indesign", "Adobe InDesign", "Design", "book.fill"),
            ("adobe audition", "Adobe Audition", "Media", "waveform"),
            ("adobe animate", "Adobe Animate", "Design", "figure.walk"),
            ("adobe substance 3d", "Adobe Substance 3D", "Design", "cube.transparent"),
            ("final cut pro", "Final Cut Pro", "Design", "scissors"),
            ("logic pro", "Logic Pro", "Media", "waveform.path"),
            ("motion", "Apple Motion", "Design", "circle.dashed.inset.filled"),
            ("compressor", "Apple Compressor", "Media", "arrow.down.right.and.arrow.up.left"),
            ("sketch", "Sketch", "Design", "diamond"),
            ("blender", "Blender 3D", "Design", "cube.transparent.fill"),
            ("davinci resolve", "DaVinci Resolve", "Design", "slider.horizontal.3"),
            ("affinity designer", "Affinity Designer", "Design", "pencil.and.outline"),
            ("affinity photo", "Affinity Photo", "Design", "photo.artframe"),
            ("affinity publisher", "Affinity Publisher", "Design", "newspaper.fill"),
            ("procreate", "Procreate", "Design", "pencil.tip.crop.circle.badge.plus"),
            ("pixelmator pro", "Pixelmator Pro", "Design", "wand.and.stars"),
            ("photomator", "Photomator", "Design", "camera.aperture"),
            ("gimp", "GIMP", "Design", "paintbrush.pointed.fill"),
            ("inkscape", "Inkscape", "Design", "bezierpath"),
            ("cinema 4d", "Cinema 4D", "Design", "cube.fill"),
            ("maya", "Autodesk Maya", "Design", "cube"),
            ("3ds max", "Autodesk 3ds Max", "Design", "square.3.layers.3d"),
            ("autocad", "AutoCAD", "Design", "ruler.fill"),
            ("rhino 3d", "Rhinoceros 3D", "Design", "seal.fill"),
            ("zbrush", "ZBrush", "Design", "figure.archery"),
            ("substance painter", "Substance 3D Painter", "Design", "paintbrush"),
            ("unity", "Unity Hub", "Developer", "cube.box"),
            ("unreal engine", "Unreal Engine", "Developer", "gamecontroller"),
            ("godot engine", "Godot Engine", "Developer", "gamecontroller.fill"),
            ("penpot", "Penpot", "Design", "square.and.pencil"),
            ("invision", "InVision", "Design", "sparkle"),
            ("framer", "Framer", "Design", "rectangle.inset.filled"),
            ("origami studio", "Origami Studio", "Design", "paperplane.circle"),
            ("principle", "Principle Animation", "Design", "arrow.triangle.swap"),
            ("rive", "Rive Animation", "Design", "figure.run"),
            ("lottie", "LottieFiles", "Design", "sparkles.square.filled.on.square"),
            ("rawtherapee", "RawTherapee", "Design", "camera.filters"),
            ("darktable", "Darktable", "Design", "slider.vertical.3"),
            ("krita", "Krita Painting", "Design", "paintbrush.pointed"),
            ("clip studio paint", "Clip Studio Paint", "Design", "pencil.and.scribble"),
            ("coreldraw", "CorelDRAW", "Design", "pencil.tip"),
            ("capture one", "Capture One Pro", "Design", "camera"),
            ("lineform", "Lineform", "Design", "scribble"),
            ("vectornator", "Curve (Vectornator)", "Design", "pencil.line"),
            ("sparkle visual web", "Sparkle Web Design", "Design", "wand.and.stars"),
            ("hype 4", "Tumult Hype 4", "Design", "play.circle"),
            ("keyshot", "KeyShot 3D", "Design", "cube.fill"),
            ("marmoset toolbag", "Marmoset Toolbag", "Design", "wrench.fill"),
            ("plasticscm", "Unity Version Control", "Developer", "arrow.triangle.branch"),
            ("fontlab", "FontLab 8", "Design", "character"),
            ("glyphs", "Glyphs 3", "Design", "textformat.size"),

            // 7. Media Players, Audio & Streaming (40)
            ("spotify", "Spotify", "Media", "music.note"),
            ("apple music", "Apple Music", "Media", "music.quarternote.3"),
            ("podcasts", "Apple Podcasts", "Media", "mic.fill"),
            ("apple tv", "Apple TV", "Media", "tv.fill"),
            ("vlc", "VLC Media Player", "Media", "cone.fill"),
            ("youtube", "YouTube", "Media", "play.rectangle.fill"),
            ("netflix", "Netflix", "Media", "film.stack.fill"),
            ("amazon prime video", "Prime Video", "Media", "play.tv.fill"),
            ("disney plus", "Disney+", "Media", "sparkles.tv"),
            ("hulu", "Hulu", "Media", "tv.circle"),
            ("hbo max", "Max (HBO)", "Media", "film.fill"),
            ("paramount plus", "Paramount+", "Media", "star.circle.fill"),
            ("peacock", "Peacock", "Media", "sparkles"),
            ("audacity", "Audacity", "Media", "waveform"),
            ("garageband", "GarageBand", "Media", "guitars.fill"),
            ("ableton live", "Ableton Live", "Media", "waveform.path.ecg"),
            ("fl studio", "FL Studio", "Media", "slider.horizontal.below.rectangle"),
            ("pro tools", "Avid Pro Tools", "Media", "waveform.circle"),
            ("reaper", "REAPER DAW", "Media", "gearshape.2"),
            ("studio one", "PreSonus Studio One", "Media", "music.note.house"),
            ("bitwig studio", "Bitwig Studio", "Media", "music.mic"),
            ("handbrake", "HandBrake", "Media", "gearshape.arrow.triangle.2.circlepath"),
            ("obs studio", "OBS Studio", "Media", "video.badge.waveform.fill"),
            ("streamlabs", "Streamlabs", "Media", "antenna.radiowaves.left.and.right.circle"),
            ("soundflow", "SoundFlow", "Media", "waveform.badge.magnifyingglass"),
            ("shazam", "Shazam", "Media", "headphones"),
            ("plex", "Plex Media Server", "Media", "server.rack"),
            ("infuse", "Infuse Pro", "Media", "play.circle"),
            ("iina", "IINA Media Player", "Media", "play.fill"),
            ("elmedia player", "Elmedia Player", "Media", "play.rectangle"),
            ("movist pro", "Movist Pro", "Media", "film"),
            ("tidal", "TIDAL HiFi", "Media", "music.quarternote.3"),
            ("soundcloud", "SoundCloud", "Media", "cloud.fill"),
            ("deezer", "Deezer Music", "Media", "waveform"),
            ("amazon music", "Amazon Music", "Media", "cart.fill"),
            ("pandora", "Pandora Radio", "Media", "radio.fill"),
            ("tunein radio", "TuneIn Radio", "Media", "antenna.radiowaves.left.and.right"),
            ("mixxx", "Mixxx DJ Software", "Media", "opticaldisc.fill"),
            ("serato dj", "Serato DJ Pro", "Media", "record.circle"),
            ("traktor pro", "Traktor Pro", "Media", "music.note.list"),

            // 8. AI Tools & Modern LLMs (30)
            ("chatgpt", "ChatGPT", "AI Tools", "brain.head.profile"),
            ("claude", "Claude AI", "AI Tools", "brain"),
            ("perplexity", "Perplexity AI", "AI Tools", "sparkles.rectangle.stack.fill"),
            ("gemini", "Google Gemini", "AI Tools", "sparkles"),
            ("midjourney", "Midjourney", "AI Tools", "photo.badge.plus"),
            ("copilot", "Microsoft Copilot", "AI Tools", "bolt.shield.fill"),
            ("poe", "Poe AI", "AI Tools", "person.crop.circle.badge.checkmark"),
            ("ollama", "Ollama Local AI", "AI Tools", "cpu.fill"),
            ("lm studio", "LM Studio", "AI Tools", "desktopcomputer"),
            ("jan ai", "Jan AI", "AI Tools", "brain.fill"),
            ("mistral", "Mistral Le Chat", "AI Tools", "wind"),
            ("groq", "Groq AI", "AI Tools", "bolt.horizontal.fill"),
            ("deepseek", "DeepSeek AI", "AI Tools", "magnifyingglass.circle"),
            ("hugging face", "Hugging Face", "AI Tools", "face.smiling.fill"),
            ("github copilot", "GitHub Copilot", "AI Tools", "laptopcomputer"),
            ("elevenlabs", "ElevenLabs Voice AI", "AI Tools", "waveform.and.mic"),
            ("suno", "Suno AI Music", "AI Tools", "music.note"),
            ("udio", "Udio AI Music", "AI Tools", "guitars"),
            ("runway ml", "Runway Gen-3", "AI Tools", "video.badge.plus"),
            ("pika labs", "Pika Video AI", "AI Tools", "sparkles.tv"),
            ("krea ai", "Krea AI", "AI Tools", "paintpalette"),
            ("leonardo ai", "Leonardo AI", "AI Tools", "wand.and.stars"),
            ("civitai", "Civitai Models", "AI Tools", "cube.box.fill"),
            ("replicate", "Replicate", "AI Tools", "square.2.layers.3d"),
            ("pinokio", "Pinokio AI Browser", "AI Tools", "circle.hexagongrid"),
            ("macwhisper", "MacWhisper AI", "AI Tools", "ear.badge.waveform"),
            ("superwhisper", "Superwhisper", "AI Tools", "mic.circle"),
            ("raycast ai", "Raycast AI", "AI Tools", "command"),
            ("phind", "Phind Dev Search", "AI Tools", "magnifyingglass"),
            ("you.com", "You.com Search", "AI Tools", "globe"),

            // 9. Mac System Utilities, Window Managers & Enhancements (50)
            ("cleanmymac", "CleanMyMac X", "Utilities", "wand.and.rays"),
            ("alfred", "Alfred 5", "Utilities", "magnifyingglass"),
            ("raycast", "Raycast", "Utilities", "command"),
            ("1password", "1Password", "Utilities", "key.radiowaves.forward.fill"),
            ("bitwarden", "Bitwarden", "Utilities", "shield.lefthalf.filled"),
            ("dashlane", "Dashlane", "Utilities", "key.fill"),
            ("keepassxc", "KeePassXC", "Utilities", "lock.fill"),
            ("enpass", "Enpass Password Manager", "Utilities", "lock.shield"),
            ("rectangle", "Rectangle Window Manager", "Utilities", "rectangle.split.2x1.fill"),
            ("rectangle pro", "Rectangle Pro", "Utilities", "rectangle.split.3x3"),
            ("magnet", "Magnet", "Utilities", "rectangle.inset.filled"),
            ("bettertouchtool", "BetterTouchTool", "Utilities", "hand.tap.fill"),
            ("bartender", "Bartender Menu Bar", "Utilities", "menubar.arrow.up.rectangle"),
            ("hidden bar", "Hidden Bar", "Utilities", "line.3.horizontal.decrease.circle"),
            ("ice menu bar", "Ice Menu Bar", "Utilities", "snowflake"),
            ("vanilla", "Vanilla Menu Bar", "Utilities", "chevron.compact.left"),
            ("coconutbattery", "coconutBattery", "Utilities", "battery.100.bolt"),
            ("stats", "Stats Menu Bar", "Utilities", "chart.xyaxis.line"),
            ("istat menus", "iStat Menus", "Utilities", "chart.bar.xaxis"),
            ("menubar stats", "MenuBar Stats", "Utilities", "speedometer"),
            ("sensei", "Sensei Mac Performance", "Utilities", "gauge.with.needle"),
            ("amphetamine", "Amphetamine", "Utilities", "cup.and.saucer.fill"),
            ("caffeine", "Caffeine", "Utilities", "mug.fill"),
            ("lungo", "Lungo", "Utilities", "cup.and.heat.waves"),
            ("the unarchiver", "The Unarchiver", "Utilities", "doc.zipper"),
            ("keka", "Keka Compression", "Utilities", "archivebox"),
            ("transmission", "Transmission BitTorrent", "Utilities", "arrow.down.circle.fill"),
            ("qbittorrent", "qBittorrent", "Utilities", "arrow.down.to.line.compact"),
            ("daisydisk", "DaisyDisk", "Utilities", "chart.pie.fill"),
            ("grandperspective", "GrandPerspective", "Utilities", "square.grid.3x3.square"),
            ("omnidisksweeper", "OmniDiskSweeper", "Utilities", "internaldrive.fill"),
            ("appcleaner", "AppCleaner", "Utilities", "trash.fill"),
            ("malwarebytes", "Malwarebytes", "Utilities", "shield.fill"),
            ("little snitch", "Little Snitch Firewall", "Utilities", "shield.lefthalf.filled"),
            ("lulu firewall", "LuLu Firewall", "Utilities", "shield.fill"),
            ("hazel", "Hazel File Organizer", "Utilities", "folder.badge.gearshape"),
            ("keyboard maestro", "Keyboard Maestro", "Utilities", "keyboard"),
            ("dropzone", "Dropzone 4", "Utilities", "arrow.down.doc.fill"),
            ("dropover", "Dropover", "Utilities", "tray.and.arrow.down.fill"),
            ("yoink", "Yoink Shelf", "Utilities", "tray.full.fill"),
            ("paste", "Paste Clipboard", "Utilities", "doc.on.clipboard.fill"),
            ("maccy", "Maccy Clipboard", "Utilities", "clipboard"),
            ("clipy", "Clipy", "Utilities", "paperclip"),
            ("cleanshot x", "CleanShot X", "Utilities", "camera.metering.center.weighted"),
            ("shottr", "Shottr Screenshot", "Utilities", "scissors"),
            ("monosnap", "Monosnap", "Utilities", "camera.viewfinder"),
            ("kap", "Kap Screen Recorder", "Utilities", "record.circle.fill"),
            ("soundsource", "SoundSource Audio", "Utilities", "speaker.wave.3"),
            ("loopback", "Loopback Audio Router", "Utilities", "arrow.triangle.2.circlepath.circle"),
            ("blackhole", "BlackHole Audio Driver", "Utilities", "circle.dashed"),

            // 10. Social Media, News, Content & Creator Platforms (40)
            ("twitter", "X / Twitter", "Social", "bubble.left.fill"),
            ("reddit", "Reddit", "Social", "person.2.fill"),
            ("linkedin", "LinkedIn", "Social", "person.text.rectangle.fill"),
            ("instagram", "Instagram", "Social", "camera.macro"),
            ("facebook", "Facebook", "Social", "person.circle.fill"),
            ("tiktok", "TikTok", "Social", "music.note.tv.fill"),
            ("pinterest", "Pinterest", "Social", "pin.fill"),
            ("threads", "Threads", "Social", "circle.dotted"),
            ("bluesky", "Bluesky", "Social", "cloud.fill"),
            ("mastodon", "Mastodon", "Social", "antenna.radiowaves.left.and.right"),
            ("tumblr", "Tumblr", "Social", "t.circle.fill"),
            ("medium", "Medium", "Social", "newspaper"),
            ("substack", "Substack", "Social", "envelope.open"),
            ("quora", "Quora", "Social", "q.circle.fill"),
            ("twitch", "Twitch", "Media", "gamecontroller"),
            ("youtube studio", "YouTube Studio", "Media", "play.rectangle.on.rectangle"),
            ("behance", "Behance", "Design", "b.circle"),
            ("dribbble", "Dribbble", "Design", "basketball.fill"),
            ("artstation", "ArtStation", "Design", "paintpalette"),
            ("patreon", "Patreon", "Social", "dollarsign.circle"),
            ("kickstarter", "Kickstarter", "Social", "k.circle"),
            ("product hunt", "Product Hunt", "Social", "p.circle.fill"),
            ("hacker news", "Hacker News", "Social", "y.circle.fill"),
            ("feedly", "Feedly RSS", "Social", "dot.radiowaves.up.forward"),
            ("reeder", "Reeder 5", "Social", "book.circle"),
            ("netnewswire", "NetNewsWire", "Social", "newspaper.fill"),
            ("goodreads", "Goodreads", "Social", "books.vertical.fill"),
            ("letterboxd", "Letterboxd", "Media", "film.circle.fill"),
            ("strava", "Strava Fitness", "Utilities", "figure.run"),
            ("nike run club", "Nike Run Club", "Utilities", "shoeprints.fill"),
            ("fitbit", "Fitbit Dashboard", "Utilities", "heart.fill"),
            ("myfitnesspal", "MyFitnessPal", "Utilities", "scalemass.fill"),
            ("alltrails", "AllTrails", "Utilities", "figure.hiking"),
            ("untappd", "Untappd", "Social", "wineglass.fill"),
            ("vivino", "Vivino", "Social", "cup.and.saucer"),
            ("yelp", "Yelp", "Social", "star.bubble.fill"),
            ("tripadvisor", "Tripadvisor", "Social", "airplane.circle"),
            ("airbnb", "Airbnb", "Social", "house.circle.fill"),
            ("booking.com", "Booking.com", "Social", "bed.double.fill"),
            ("uber", "Uber", "Social", "car.fill"),

            // 11. Finance, Business, Crypto & Commerce (30)
            ("tradingview", "TradingView", "Utilities", "chart.xyaxis.line"),
            ("robinhood", "Robinhood", "Utilities", "feather"),
            ("coinbase", "Coinbase", "Utilities", "bitcoinsign.circle.fill"),
            ("binance", "Binance", "Utilities", "dollarsign.circle.fill"),
            ("metamask", "MetaMask", "Utilities", "cube.transparent"),
            ("ledger live", "Ledger Live", "Utilities", "lock.shield.fill"),
            ("paypal", "PayPal", "Utilities", "p.square.fill"),
            ("stripe dashboard", "Stripe Dashboard", "Utilities", "creditcard.fill"),
            ("wise", "Wise (TransferWise)", "Utilities", "arrow.left.arrow.right"),
            ("revolut", "Revolut", "Utilities", "r.circle.fill"),
            ("quickbooks", "QuickBooks", "Utilities", "book.closed"),
            ("xero", "Xero Accounting", "Utilities", "chart.pie"),
            ("turbotax", "TurboTax", "Utilities", "doc.text.badge.plus"),
            ("bloomberg", "Bloomberg Terminal", "Utilities", "chart.bar.doc.horizontal"),
            ("wealthfront", "Wealthfront", "Utilities", "arrow.up.right.circle.fill"),
            ("fidelity", "Fidelity Investments", "Utilities", "building.columns.fill"),
            ("charles schwab", "Charles Schwab", "Utilities", "chart.line.uptrend.xyaxis.circle"),
            ("etrade", "E*TRADE", "Utilities", "star.fill"),
            ("webull", "Webull", "Utilities", "chart.bar.fill"),
            ("kraken", "Kraken Crypto", "Utilities", "water.waves"),
            ("shopify", "Shopify Store", "Utilities", "bag.fill"),
            ("amazon", "Amazon Shopping", "Utilities", "cart.fill"),
            ("ebay", "eBay", "Utilities", "tag.fill"),
            ("apple wallet", "Apple Wallet & Pay", "Utilities", "wallet.pass.fill"),
            ("cash app", "Cash App", "Utilities", "dollarsign.square.fill"),
            ("venmo", "Venmo", "Utilities", "v.square.fill"),
            ("zelle", "Zelle", "Utilities", "z.circle.fill"),
            ("ynab", "You Need A Budget (YNAB)", "Utilities", "calendar.day.timeline.right"),
            ("mint", "Mint / Credit Karma", "Utilities", "leaf.arrow.triangle.circlepath"),
            ("expensify", "Expensify", "Utilities", "receipt.fill"),

            // 12. Gaming & Game Launchers (30)
            ("steam", "Steam", "Media", "gamecontroller.fill"),
            ("epic games", "Epic Games Launcher", "Media", "e.circle.fill"),
            ("battle.net", "Blizzard Battle.net", "Media", "shield.pattern.checkered"),
            ("gog galaxy", "GOG Galaxy", "Media", "globe.americas.fill"),
            ("minecraft", "Minecraft Launcher", "Media", "cube.fill"),
            ("roblox", "Roblox", "Media", "square.fill"),
            ("riot client", "Riot Client", "Media", "flame.circle.fill"),
            ("league of legends", "League of Legends", "Media", "shield.lefthalf.filled"),
            ("valorant tracker", "Valorant Tracker", "Media", "target"),
            ("geforce now", "GeForce NOW", "Media", "tv.and.mediabox"),
            ("xbox cloud gaming", "Xbox Cloud Gaming", "Media", "x.circle.fill"),
            ("playstation remote", "PS Remote Play", "Media", "gamecontroller"),
            ("crossover", "CrossOver Mac", "Utilities", "arrow.right.arrow.left.square"),
            ("whisky", "Whisky Wine Wrapper", "Utilities", "wineglass"),
            ("porting kit", "Porting Kit", "Utilities", "shippingbox"),
            ("retroarch", "RetroArch Emulator", "Media", "arcade.stick"),
            ("dolphin", "Dolphin Emulator", "Media", "water.waves.and.arrow.down"),
            ("pcsx2", "PCSX2 PlayStation 2", "Media", "opticaldisc"),
            ("rpcs3", "RPCS3 PlayStation 3", "Media", "cpu"),
            ("ppsspp", "PPSSPP PSP", "Media", "gamecontroller.circle"),
            ("desmume", "DeSmuME Nintendo DS", "Media", "rectangle.split.1x2"),
            ("mame", "MAME Arcade", "Media", "gamecontroller"),
            ("twitch studio", "Twitch Studio", "Media", "video.badge.plus"),
            ("curseforge", "CurseForge Mods", "Media", "flame"),
            ("modrinth", "Modrinth App", "Media", "wrench.and.screwdriver"),
            ("prism launcher", "Prism Launcher", "Media", "cube.transparent"),
            ("openemu", "OpenEmu Retro Gaming", "Media", "gamecontroller.fill"),
            ("ea app", "EA App", "Media", "e.square"),
            ("ubisoft connect", "Ubisoft Connect", "Media", "circle.hexagongrid"),
            ("itch.io", "itch.io Launcher", "Media", "gamecontroller")
        ]

        var list: [AppItem] = []
        var seen = Set<String>()

        for item in rawItems {
            let key = item.0.lowercased()
            if !seen.contains(key) {
                seen.insert(key)
                list.append(AppItem(
                    key: key,
                    name: item.1,
                    category: item.2,
                    icon: item.3,
                    isInstalled: false,
                    bundlePath: nil
                ))
            }
        }

        return list
    }()

    // MARK: - Unified App Catalog (Installed first, then catalog, sorted)
    public func getUnifiedApps() -> [AppItem] {
        let installed = scanInstalledApps()
        var installedKeys = Set(installed.map { $0.key })

        var combined: [AppItem] = installed

        for item in catalog500 {
            if !installedKeys.contains(item.key) && !installedKeys.contains(item.name.lowercased()) {
                installedKeys.insert(item.key)
                combined.append(item)
            }
        }

        return combined
    }
}
