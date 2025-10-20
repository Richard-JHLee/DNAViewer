//
//  LanguageHelper.swift
//  DNAViewer
//
//  Created by AI Assistant on 2025-10-20.
//

import Foundation

// MARK: - Language Detection Utility

struct LanguageHelper {
    /// 현재 시스템 언어 코드
    static var currentLanguageCode: String {
        let preferredLanguages = Locale.preferredLanguages
        if let firstLanguage = preferredLanguages.first {
            let code = String(firstLanguage.prefix(2)).lowercased()
            return code
        }
        return Locale.current.languageCode ?? "en"
    }
    
    /// 한국어 여부
    static var isKorean: Bool {
        return currentLanguageCode == "ko"
    }
    
    /// 일본어 여부
    static var isJapanese: Bool {
        return currentLanguageCode == "ja"
    }
    
    /// 독일어 여부
    static var isGerman: Bool {
        return currentLanguageCode == "de"
    }
    
    /// 다국어 텍스트를 위한 헬퍼 함수 (4개 언어 지원)
    /// - Parameters:
    ///   - korean: 한국어 텍스트
    ///   - japanese: 일본어 텍스트
    ///   - german: 독일어 텍스트
    ///   - english: 영어 텍스트 (기본값)
    /// - Returns: 현재 언어에 맞는 텍스트
    static func localizedText(korean: String, japanese: String, german: String, english: String) -> String {
        switch currentLanguageCode {
        case "ko":
            return korean
        case "ja":
            return japanese
        case "de":
            return german
        default:
            return english
        }
    }
    
    /// 간단한 2개 언어 지원 (한국어/영어) - 레거시 호환성
    static func localizedText(korean: String, english: String) -> String {
        return isKorean ? korean : english
    }
    
    /// Localizable.strings에서 키로 텍스트 가져오기
    static func string(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
}

// MARK: - Localized String Extensions

extension String {
    /// NSLocalizedString wrapper
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// 특정 키로 번역된 문자열 가져오기
    func localized(comment: String = "") -> String {
        return NSLocalizedString(self, comment: comment)
    }
}

