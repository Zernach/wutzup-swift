import Foundation

enum WutzupResearchText {
    static func attributed(_ text: String) -> AttributedString {
        var result = (try? AttributedString(markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
        for run in result.runs {
            if let url = run.link, url.scheme != "https" {
                result[run.range].link = nil
            }
        }
        return result
    }
}
