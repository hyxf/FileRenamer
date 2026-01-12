//
//  FileRenamerViewModel.swift
//  FileRenamer
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
class FileRenamerViewModel: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var rule = RenameRule()
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var successMessage: String?
    @Published var showSuccess = false
    @Published var searchText = ""
    
    private var accessedURLs: Set<URL> = []
    
    var filteredFiles: [FileItem] {
        if searchText.isEmpty {
            return files
        }
        return files.filter { file in
            file.originalName.localizedCaseInsensitiveContains(searchText) ||
            file.newName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var selectedFiles: [FileItem] {
        files.filter { $0.isSelected }
    }
    
    var hasChanges: Bool {
        files.contains { $0.hasChanges && $0.isSelected }
    }
    
    var isAllSelected: Bool {
        !files.isEmpty && files.allSatisfy { $0.isSelected }
    }
    
    // MARK: - Actions
    
    func addFiles(urls: [URL]) {
        let newFiles = urls.map { FileItem(url: $0) }
        files.append(contentsOf: newFiles)
        applyRule()
    }
    
    func removeFile(at indexSet: IndexSet) {
        files.remove(atOffsets: indexSet)
    }
    
    func removeSelectedFiles() {
        files.removeAll { $0.isSelected }
    }
    
    func clearAll() {
        stopAllAccess()
        files.removeAll()
    }
    
    func toggleSelection(for file: FileItem) {
        if let index = files.firstIndex(where: { $0.id == file.id }) {
            files[index].isSelected.toggle()
            objectWillChange.send() // 强制刷新
            
            if rule.type == .sequence {
                applyRule()
            }
        }
    }
    
    func toggleSelectAll() {
        if isAllSelected {
            deselectAll()
        } else {
            selectAll()
        }
    }
    
    func selectAll() {
        for index in files.indices {
            files[index].isSelected = true
        }
        objectWillChange.send()
        applyRule()
    }
    
    func deselectAll() {
        for index in files.indices {
            files[index].isSelected = false
        }
        objectWillChange.send()
        applyRule()
    }
    
    func applyRule() {
        objectWillChange.send()
        
        for index in files.indices {
            if rule.type == .sequence {
                let selectedIndex = files[0..<index].filter { $0.isSelected }.count
                if files[index].isSelected {
                    files[index].newName = rule.apply(to: files[index].originalName, index: selectedIndex)
                } else {
                    files[index].newName = files[index].originalName
                }
            } else {
                files[index].newName = rule.apply(to: files[index].originalName)
            }
        }
    }
    
    // MARK: - File System Access
    
    private func startAccess(for url: URL) -> Bool {
        guard url.startAccessingSecurityScopedResource() else { return false }
        accessedURLs.insert(url)
        return true
    }
    
    private func stopAccess(for url: URL) {
        if accessedURLs.contains(url) {
            url.stopAccessingSecurityScopedResource()
            accessedURLs.remove(url)
        }
    }
    
    private func stopAllAccess() {
        for url in accessedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        accessedURLs.removeAll()
    }
    
    func executeRename() async {
        isProcessing = true
        errorMessage = nil
        
        var successCount = 0
        var failedFiles: [(name: String, error: String)] = []
        var updates: [(index: Int, newURL: URL, newName: String)] = []
        
        for index in files.indices {
            let file = files[index]
            guard file.isSelected && file.hasChanges else { continue }
            
            let fileURL = file.url
            let parentURL = fileURL.deletingLastPathComponent()
            let newURL = parentURL.appendingPathComponent(file.newName)
            
            let fileAccess = startAccess(for: fileURL)
            let parentAccess = startAccess(for: parentURL)
            
            defer {
                if fileAccess { stopAccess(for: fileURL) }
                if parentAccess { stopAccess(for: parentURL) }
            }
            
            if FileManager.default.fileExists(atPath: newURL.path) {
                failedFiles.append((name: file.originalName, error: "目标文件名已存在"))
                continue
            }
            
            do {
                try FileManager.default.moveItem(at: fileURL, to: newURL)
                successCount += 1
                updates.append((index: index, newURL: newURL, newName: file.newName))
                _ = startAccess(for: newURL)
            } catch let error {
                failedFiles.append((name: file.originalName, error: error.localizedDescription))
            }
        }
        
        if !updates.isEmpty {
            for update in updates {
                var updatedFile = files[update.index]
                updatedFile = FileItem(url: update.newURL)
                updatedFile.isSelected = true
                files[update.index] = updatedFile
            }
            
            // 【修改点】重置规则表单
            rule = RenameRule()
            
            // 重新应用（空）规则，更新预览状态
            applyRule()
        }
        
        isProcessing = false
        
        if !failedFiles.isEmpty {
            let errorDetails = failedFiles.map { "• \($0.name)\n  \($0.error)" }.joined(separator: "\n\n")
            errorMessage = "以下文件重命名失败:\n\n\(errorDetails)"
            showError = true
        }
        
        if successCount > 0 {
            successMessage = "✓ 成功重命名 \(successCount) 个文件"
            showSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                self?.showSuccess = false
            }
        }
    }
    
    nonisolated deinit {
        let urls = accessedURLs
        for url in urls {
            url.stopAccessingSecurityScopedResource()
        }
    }
}
