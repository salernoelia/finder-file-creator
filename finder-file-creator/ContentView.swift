import SwiftUI

struct ContentView: View {
    private let appGroupID = "group.finder-file-creator"

    @State private var templates: [FileTemplate] = []
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var newExt = ""
    @State private var newContent = ""
    @State private var editingTemplate: FileTemplate? = nil

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            templateList
            Divider()
            footer
        }
        .frame(width: 420, height: 520)
        .background(.windowBackground)
        .onAppear(perform: load)
        .sheet(isPresented: $showingAdd) { addSheet }
        .sheet(item: $editingTemplate) { t in editSheet(t) }
    }

    private var toolbar: some View {
        HStack {
            Text("File Templates")
                .font(.headline)
            Spacer()
            Button(action: { showingAdd = true }) {
                Image(systemName: "plus")
                    .frame(width: 28, height: 28)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var templateList: some View {
        List {
            ForEach(templates) { template in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.quaternary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(template.ext.replacingOccurrences(of: ".", with: "").prefix(3).uppercased())
                                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.secondary)
                        )
                    VStack(alignment: .leading, spacing: 1) {
                        Text(template.name)
                            .font(.system(size: 13))
                        Text(template.ext)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Button {
                        editingTemplate = template
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .opacity(0.6)

                    Button {
                        withAnimation {
                            templates.removeAll { $0.id == template.id }
                            save()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .opacity(0.6)
                }
                .padding(.vertical, 2)
            }
            .onMove { from, to in
                templates.move(fromOffsets: from, toOffset: to)
                save()
            }
        }
        .listStyle(.inset)
    }

    private var footer: some View {
        HStack {
            Button("Reset to Defaults") {
                withAnimation {
                    templates = FinderSync.defaultTemplates.map {
                        FileTemplate(name: $0.name, ext: $0.ext, content: $0.content)
                    }
                    save()
                }
            }
            .foregroundStyle(.secondary)
            .font(.system(size: 12))
            Spacer()
            Text("\(templates.count) templates")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var addSheet: some View {
        TemplateFormView(
            title: "New Template",
            name: $newName,
            ext: $newExt,
            content: $newContent,
            confirmLabel: "Add"
        ) {
            templates.append(FileTemplate(name: newName, ext: newExt, content: newContent))
            save()
            newName = ""; newExt = ""; newContent = ""
            showingAdd = false
        } onCancel: {
            newName = ""; newExt = ""; newContent = ""
            showingAdd = false
        }
    }

    private func editSheet(_ template: FileTemplate) -> some View {
        let idx = templates.firstIndex(where: { $0.id == template.id })
        let bindName = Binding(
            get: { idx.map { templates[$0].name } ?? "" },
            set: { if let i = idx { templates[i].name = $0 } }
        )
        let bindExt = Binding(
            get: { idx.map { templates[$0].ext } ?? "" },
            set: { if let i = idx { templates[i].ext = $0 } }
        )
        let bindContent = Binding(
            get: { idx.map { templates[$0].content } ?? "" },
            set: { if let i = idx { templates[i].content = $0 } }
        )
        return TemplateFormView(
            title: "Edit Template",
            name: bindName,
            ext: bindExt,
            content: bindContent,
            confirmLabel: "Save"
        ) {
            save()
            editingTemplate = nil
        } onCancel: {
            load()
            editingTemplate = nil
        }
    }

    private func load() {
        let defaults = UserDefaults(suiteName: appGroupID)
        if let data = defaults?.data(forKey: "fileTemplates"),
           let decoded = try? JSONDecoder().decode([FileTemplate].self, from: data) {
            templates = decoded
        } else {
            templates = FinderSync.defaultTemplates.map {
                FileTemplate(name: $0.name, ext: $0.ext, content: $0.content)
            }
        }
    }

    private func save() {
        let defaults = UserDefaults(suiteName: appGroupID)
        if let data = try? JSONEncoder().encode(templates) {
            defaults?.set(data, forKey: "fileTemplates")
        }
    }
}

struct TemplateFormView: View {
    let title: String
    @Binding var name: String
    @Binding var ext: String
    @Binding var content: String
    let confirmLabel: String
    var onConfirm: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                Label("Menu label", systemImage: "tag")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                TextField("e.g. New Swift File", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Extension", systemImage: "doc")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    TextField(".swift", text: $ext)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                        .font(.system(.body, design: .monospaced))
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("Default content", systemImage: "text.alignleft")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                TextEditor(text: $content)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.quaternary, lineWidth: 1)
                    )
            }

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.escape)
                Spacer()
                Button(confirmLabel, action: onConfirm)
                    .disabled(name.isEmpty || ext.isEmpty)
                    .keyboardShortcut(.return)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}
