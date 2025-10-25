//
//  LanguageDetectionService.swift
//  Wutzup
//
//  Created on October 21, 2025
//

import Foundation
import NaturalLanguage
import os.log

protocol LanguageDetectionService {
    func detectLanguage(for text: String) async -> String?
}

class NaturalLanguageDetectionService: LanguageDetectionService {
    private let logger = Logger(subsystem: "org.archlife.wutzup", category: "LanguageDetection")
    
    func detectLanguage(for text: String) async -> String? {
        // Validate input
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.warning("Empty or whitespace-only text provided for language detection")
            return nil
        }
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let recognizer = NLLanguageRecognizer()
                    recognizer.processString(text)
                    
                    guard let language = recognizer.dominantLanguage else {
                        self.logger.warning("Could not determine dominant language for text: \(text.prefix(50))...")
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    // Convert NLLanguage to ISO 639-1 code
                    let languageCode = self.convertToISOCode(language)
                    self.logger.info("Detected language: \(languageCode) for text: \(text.prefix(50))...")
                    continuation.resume(returning: languageCode)
                } catch {
                    self.logger.error("Error during language detection: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func convertToISOCode(_ language: NLLanguage) -> String {
        switch language {
        // Core supported languages
        case .english: return "en"
        case .spanish: return "es"
        case .french: return "fr"
        case .german: return "de"
        case .italian: return "it"
        case .portuguese: return "pt"
        case .dutch: return "nl"
        case .russian: return "ru"
        case .japanese: return "ja"
        case .korean: return "ko"
        case .simplifiedChinese: return "zh-CN"
        case .traditionalChinese: return "zh-TW"
        case .arabic: return "ar"
        case .hindi: return "hi"
        case .thai: return "th"
        case .vietnamese: return "vi"
        case .turkish: return "tr"
        case .polish: return "pl"
        case .swedish: return "sv"
        case .danish: return "da"
        case .norwegian: return "no"
        case .finnish: return "fi"
        case .czech: return "cs"
        case .hungarian: return "hu"
        case .romanian: return "ro"
        case .bulgarian: return "bg"
        case .croatian: return "hr"
        case .slovak: return "sk"
        case .ukrainian: return "uk"
        case .greek: return "el"
        case .hebrew: return "he"
        case .persian: return "fa"
        case .urdu: return "ur"
        case .bengali: return "bn"
        case .tamil: return "ta"
        case .telugu: return "te"
        case .marathi: return "mr"
        case .gujarati: return "gu"
        case .kannada: return "kn"
        case .malayalam: return "ml"
        case .punjabi: return "pa"
        case .indonesian: return "id"
        case .malay: return "ms"
        case .amharic: return "am"
        case .catalan: return "ca"
        case .georgian: return "ka"
        case .icelandic: return "is"
        case .armenian: return "hy"
        case .burmese: return "my"
        case .cherokee: return "chr"
        case .khmer: return "km"
        case .lao: return "lo"
        case .mongolian: return "mn"
        case .oriya: return "or"
        case .sinhalese: return "si"
        case .tibetan: return "bo"
        case .undetermined: return "unknown"
        default: 
            // For unsupported languages, try to extract from the raw value
            let rawValue = language.rawValue
            logger.warning("Unsupported language detected: \(rawValue)")
            if rawValue.count == 2 {
                return rawValue
            }
            return "unknown"
        }
    }
}
