import FinderSync

class FinderSync: FIFinderSync {
    
    private let appGroupID = "group.finder-file-creator"
    
    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }
    
    private var fileTemplates: [(name: String, ext: String, content: String)] {
        let defaults = UserDefaults(suiteName: appGroupID)
        if let data = defaults?.data(forKey: "fileTemplates"),
           let decoded = try? JSONDecoder().decode([FileTemplate].self, from: data) {
            return decoded.map { ($0.name, $0.ext, $0.content) }
        }
        return Self.defaultTemplates
    }
    
    static let defaultTemplates: [(name: String, ext: String, content: String)] = [
        ("New Markdown File",           ".md",   "# New Document\n\n"),
        ("New Python Script",           ".py",   "#!/usr/bin/env python3\n\n"),
        ("New HTML File",               ".html", "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n    <meta charset=\"UTF-8\">\n    <title>New Page</title>\n</head>\n<body>\n\n</body>\n</html>"),
        ("New OpenDocument Text",       ".odt",  ""),
        ("New OpenDocument Spreadsheet",".ods",  ""),
        ("New OpenDocument Presentation",".odp",  ""),
        ("New YML",".yml",  ""),
        ("New JSON",".json",  ""),
    ]
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForContainer else { return nil }
        let menu = NSMenu(title: "New")
        for template in fileTemplates {
            menu.addItem(withTitle: template.name, action: #selector(createNewFile(_:)), keyEquivalent: "")
        }
        return menu
    }
    
    @objc private func createNewFile(_ sender: NSMenuItem) {
        let controller = FIFinderSyncController.default()
        var targetFolder = controller.targetedURL()
        if targetFolder == nil, let selected = controller.selectedItemURLs(), !selected.isEmpty {
            targetFolder = selected[0].deletingLastPathComponent()
        }
        guard let folder = targetFolder else { return }
        
        let title = sender.title
        guard let template = fileTemplates.first(where: { $0.name == title }) else { return }
        
        var fileURL = folder.appendingPathComponent("Untitled" + template.ext)
        var counter = 1
        while FileManager.default.fileExists(atPath: fileURL.path) {
            fileURL = folder.appendingPathComponent("Untitled \(counter)" + template.ext)
            counter += 1
        }
        
        do {
            try (template.content.data(using: .utf8) ?? Data()).write(to: fileURL, options: .atomic)
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } catch {
            print("Failed to create file: \(error.localizedDescription)")
        }
    }
}
