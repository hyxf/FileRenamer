//
//  RenameRule.swift
//  FileRenamer
//

import Foundation

enum RenameRuleType: String, CaseIterable, Identifiable {
    case replace = "查找替换"
    case prefix = "添加前缀"
    case suffix = "添加后缀"
    case sequence = "序列编号"
    case caseChange = "大小写转换"
    case removeText = "删除文本"
    case insertText = "插入文本"

    var id: String {
        rawValue
    }
}

enum CaseType: String, CaseIterable, Identifiable {
    case uppercase = "全部大写"
    case lowercase = "全部小写"
    case capitalized = "首字母大写"

    var id: String {
        rawValue
    }
}

struct RenameRule: Equatable {
    var type: RenameRuleType = .replace
    var findText: String = ""
    var replaceText: String = ""
    var prefixText: String = ""
    var suffixText: String = ""
    var startNumber: Int = 1
    var digits: Int = 3
    var separator: String = "_"
    var caseType: CaseType = .lowercase
    var removeText: String = ""
    var insertText: String = ""
    var insertPosition: Int = 0
    var applyToExtension: Bool = false
    var isRegex: Bool = false // 新增：是否启用正则

    func apply(to filename: String) -> String {
        let nameWithoutExt = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension

        var newName = nameWithoutExt

        switch type {
        case .replace:
            if !findText.isEmpty {
                newName = newName.replacingOccurrences(of: findText, with: replaceText)
            }

        case .prefix:
            if !prefixText.isEmpty {
                newName = prefixText + newName
            }

        case .suffix:
            if !suffixText.isEmpty {
                newName = newName + suffixText
            }

        case .sequence:
            // 序列模式在 apply(to:index:) 中处理，这里返回空或原名仅作占位
            newName = ""

        case .caseChange:
            switch caseType {
            case .uppercase:
                newName = newName.uppercased()
            case .lowercase:
                newName = newName.lowercased()
            case .capitalized:
                newName = newName.capitalized
            }

        case .removeText:
            if !removeText.isEmpty {
                if isRegex {
                    // 正则表达式模式
                    // 预先检查正则是否有效，避免运行时 Crash
                    if (try? NSRegularExpression(pattern: removeText)) != nil {
                        newName = newName.replacingOccurrences(
                            of: removeText,
                            with: "",
                            options: .regularExpression,
                            range: nil)
                    }
                } else {
                    // 普通文本模式
                    newName = newName.replacingOccurrences(of: removeText, with: "")
                }
            }

        case .insertText:
            if !insertText.isEmpty, insertPosition >= 0 {
                let index = min(insertPosition, newName.count)
                let insertIndex = newName.index(newName.startIndex, offsetBy: index)
                newName.insert(contentsOf: insertText, at: insertIndex)
            }
        }

        if ext.isEmpty {
            return newName
        } else {
            if applyToExtension {
                return newName + "." + apply(to: ext)
            } else {
                return newName + "." + ext
            }
        }
    }

    func apply(to filename: String, index: Int) -> String {
        if type == .sequence {
            let ext = (filename as NSString).pathExtension

            let number = startNumber + index
            let formattedNumber = String(format: "%0\(digits)d", number)

            let newName = prefixText + separator + formattedNumber

            if ext.isEmpty {
                return newName
            } else {
                return newName + "." + ext
            }
        } else {
            return apply(to: filename)
        }
    }
}
