//
//  String+Extensions.swift
//  FileRenamer
//

import Foundation

extension String {
    func applySequenceNumber(_ number: Int, digits: Int, separator: String, prefix: String) -> String {
        let formattedNumber = String(format: "%0\(digits)d", number)
        return prefix + separator + formattedNumber
    }
    
    func removeExtension() -> String {
        (self as NSString).deletingPathExtension
    }
    
    func getExtension() -> String {
        (self as NSString).pathExtension
    }
    
    func replaceExtension(with newExtension: String) -> String {
        removeExtension() + (newExtension.isEmpty ? "" : ".\(newExtension)")
    }
    
    var isValidFilename: Bool {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return rangeOfCharacter(from: invalidCharacters) == nil && !isEmpty
    }
    
    func sanitizedFilename() -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}
