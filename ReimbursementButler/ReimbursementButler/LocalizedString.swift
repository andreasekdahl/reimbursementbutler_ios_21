//
//  LocalizedString.swift
//
//  Acts as a wrapper for NSLocalizedString

import Foundation

extension String {
    func localized() -> String {
        return NSLocalizedString(self, tableName: "Main", bundle: Bundle.main, value: "", comment: "")
    }
}
