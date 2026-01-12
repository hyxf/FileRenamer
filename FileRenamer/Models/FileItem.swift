//
//  FileItem.swift
//  FileRenamer
//

import Foundation
import UniformTypeIdentifiers

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    var originalName: String
    var newName: String
    var isSelected: Bool = true
    
    var fileExtension: String {
        url.pathExtension
    }
    
    var fileType: UTType? {
        UTType(filenameExtension: fileExtension)
    }
    
    var icon: String {
        if let type = fileType {
            if type.conforms(to: .image) {
                return "photo"
            } else if type.conforms(to: .movie) || type.conforms(to: .video) {
                return "film"
            } else if type.conforms(to: .audio) {
                return "music.note"
            } else if type.conforms(to: .pdf) {
                return "doc.text"
            } else if type.conforms(to: .folder) {
                return "folder"
            } else if type.conforms(to: .archive) {
                return "doc.zipper"
            } else if type.conforms(to: .text) || type.conforms(to: .sourceCode) {
                return "doc.text"
            }
        }
        return "doc"
    }
    
    var hasChanges: Bool {
        originalName != newName
    }
    
    init(url: URL) {
        self.url = url
        self.originalName = url.lastPathComponent
        self.newName = url.lastPathComponent
    }
    
    // 【关键修改】删除了手动的 hash 和 == 实现
    // 让 Swift 自动生成基于所有属性（包括 isSelected）的比较逻辑
    // 这样当选中状态改变时，界面才会检测到变化并刷新
}
