//
//  FileListView.swift
//  FileRenamer
//

import SwiftUI
import UniformTypeIdentifiers

struct FileListView: View {
    @ObservedObject var viewModel: FileRenamerViewModel
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.files.isEmpty {
                emptyState
            } else {
                searchBar
                
                VStack(spacing: 0) {
                    listHeader
                    
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.filteredFiles.enumerated()), id: \.element.id) { index, file in
                                FileRowView(file: file, index: index, viewModel: viewModel)
                                // 保留淡淡的分割线
                                if index < viewModel.filteredFiles.count - 1 {
                                    Divider().opacity(0.3).padding(.leading, 40)
                                }
                            }
                        }
                    }
                    .background(Color(nsColor: .controlBackgroundColor))
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
            handleDrop(providers: providers)
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
            TextField("搜索文件...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(nsColor: .separatorColor)),
            alignment: .bottom
        )
    }
    
    private var listHeader: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 68)
            
            Text("原文件名")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer().frame(width: 20)
            
            Text("新文件名 (预览)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 32)
        .background(Color.primary.opacity(0.08))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(nsColor: .separatorColor).opacity(0.5)),
            alignment: .bottom
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 6) {
                Text("暂无文件")
                    .font(.system(.headline))
                
                Text("拖拽文件到此处开始")
                    .font(.system(.subheadline))
                    .foregroundColor(.secondary)
            }
            
            Button("选择文件") {
                selectFiles()
            }
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDragging ? Color.accentColor : Color.clear,
                    style: StrokeStyle(lineWidth: 2, dash: [5])
                )
                .padding(20)
        )
    }
    
    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK {
            viewModel.addFiles(urls: panel.urls)
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []
        let group = DispatchGroup()
        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url { urls.append(url) }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            viewModel.addFiles(urls: urls)
        }
        return true
    }
}

struct FileRowView: View {
    let file: FileItem
    let index: Int
    @ObservedObject var viewModel: FileRenamerViewModel
    @State private var isHovered = false
    
    var body: some View {
        Button {
            viewModel.toggleSelection(for: file)
        } label: {
            HStack(spacing: 0) {
                Color.clear.frame(width: 12)
                
                Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundColor(file.isSelected ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 24, alignment: .center)
                    .padding(.trailing, 4)
                
                Image(systemName: file.icon)
                    .foregroundColor(file.isSelected ? .primary : .secondary)
                    .font(.system(size: 14))
                    .frame(width: 20)
                    .padding(.trailing, 8)
                
                // Diff Text (Original)
                DiffText(
                    oldString: file.originalName,
                    newString: file.newName,
                    mode: .original,
                    isSelected: file.isSelected
                )
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(
                        file.hasChanges
                        ? Color.accentColor.opacity(0.8)
                        : Color.clear
                    )
                    .frame(width: 20)
                
                // Diff Text (Preview)
                DiffText(
                    oldString: file.originalName,
                    newString: file.newName,
                    mode: .preview,
                    isSelected: file.isSelected
                )
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 12)
                .padding(.leading, 8)
            }
            .frame(height: 32)
            .background(
                isHovered ? Color.primary.opacity(0.04) : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Diff Component
struct DiffText: View {
    let oldString: String
    let newString: String
    let mode: DiffMode
    let isSelected: Bool
    
    enum DiffMode {
        case original
        case preview
    }
    
    var body: some View {
        if !isSelected || oldString == newString {
            Text(mode == .original ? oldString : newString)
                .foregroundColor(isSelected ? .primary : .secondary)
        } else {
            renderOptimizedDiff()
        }
    }
    
    private func renderOptimizedDiff() -> Text {
        let oldChars = Array(oldString)
        let newChars = Array(newString)
        
        // 1. 寻找公共前缀
        var prefixLen = 0
        while prefixLen < oldChars.count && prefixLen < newChars.count && oldChars[prefixLen] == newChars[prefixLen] {
            prefixLen += 1
        }
        
        // 2. 寻找公共后缀
        var suffixLen = 0
        while suffixLen < (oldChars.count - prefixLen) && suffixLen < (newChars.count - prefixLen) &&
              oldChars[oldChars.count - 1 - suffixLen] == newChars[newChars.count - 1 - suffixLen] {
            suffixLen += 1
        }
        
        // 3. 提取部分
        let prefixStr = String(oldChars.prefix(prefixLen))
        let suffixStr = String(oldChars.suffix(suffixLen))
        
        let middleOld = String(oldChars[prefixLen..<(oldChars.count - suffixLen)])
        let middleNew = String(newChars[prefixLen..<(newChars.count - suffixLen)])
        
        // 4. 构建 Text
        var result = Text(prefixStr).foregroundColor(.primary)
        
        if mode == .original {
            if !middleOld.isEmpty {
                if middleNew.isEmpty {
                    result = result + Text(middleOld)
                        .foregroundColor(.red)
                        .strikethrough()
                } else {
                    result = result + renderStandardDiff(old: middleOld, new: middleNew, mode: .original)
                }
            }
        } else {
            // Preview Mode
            if !middleNew.isEmpty {
                if middleOld.isEmpty {
                    // 纯新增：绿色 + 粗体 + 下划线
                    result = result + Text(middleNew)
                        .foregroundColor(.green)
                        .bold()
                        .underline(true, color: .green.opacity(0.5)) // 【修复】添加下划线
                } else {
                    result = result + renderStandardDiff(old: middleOld, new: middleNew, mode: .preview)
                }
            }
        }
        
        result = result + Text(suffixStr).foregroundColor(.primary)
        return result
    }
    
    private func renderStandardDiff(old: String, new: String, mode: DiffMode) -> Text {
        let diff = new.difference(from: old)
        var result = Text("")
        
        switch mode {
        case .original:
            let removals = Set(diff.removals.compactMap { change -> Int? in
                if case .remove(let offset, _, _) = change { return offset }
                return nil
            })
            
            var currentIndex = 0
            let chars = Array(old)
            while currentIndex < chars.count {
                let isRemoved = removals.contains(currentIndex)
                var segment = String(chars[currentIndex])
                currentIndex += 1
                while currentIndex < chars.count && removals.contains(currentIndex) == isRemoved {
                    segment.append(chars[currentIndex])
                    currentIndex += 1
                }
                
                if isRemoved {
                    result = result + Text(segment).foregroundColor(.red).strikethrough()
                } else {
                    result = result + Text(segment).foregroundColor(.primary)
                }
            }
            
        case .preview:
            let insertions = Set(diff.insertions.compactMap { change -> Int? in
                if case .insert(let offset, _, _) = change { return offset }
                return nil
            })
            
            var currentIndex = 0
            let chars = Array(new)
            while currentIndex < chars.count {
                let isInserted = insertions.contains(currentIndex)
                var segment = String(chars[currentIndex])
                currentIndex += 1
                while currentIndex < chars.count && insertions.contains(currentIndex) == isInserted {
                    segment.append(chars[currentIndex])
                    currentIndex += 1
                }
                
                if isInserted {
                    // 复杂替换中的新增：绿色 + 粗体 + 下划线
                    result = result + Text(segment)
                        .foregroundColor(.green)
                        .bold()
                        .underline(true, color: .green.opacity(0.5)) // 【修复】添加下划线
                } else {
                    result = result + Text(segment).foregroundColor(.primary)
                }
            }
        }
        return result
    }
}
