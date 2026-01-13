import AppKit
import Foundation

/// Color palette for syntax highlighting token types.
/// Adjust these colors as needed to match your preferred theme.
enum SyntaxColors {
    static let number = NSColor.systemOrange
    static let identifier = NSColor.systemCyan
    static let `operator` = NSColor.systemPink
    static let parenthesis = NSColor.systemYellow
    static let equals = NSColor.systemGray
    static let comment = NSColor.systemGray
    static let defaultText = NSColor.white
}

/// Applies syntax highlighting to an NSTextStorage using the expression Lexer.
final class SyntaxHighlighter {
    private let font: NSFont
    private let defaultColor: NSColor
    
    init(font: NSFont, defaultColor: NSColor = SyntaxColors.defaultText) {
        self.font = font
        self.defaultColor = defaultColor
    }
    
    /// Highlights the entire text storage by tokenizing each line.
    func highlight(_ textStorage: NSTextStorage) {
        let fullRange = NSRange(location: 0, length: textStorage.length)
        let source = textStorage.string
        
        // Begin editing batch
        textStorage.beginEditing()
        
        // Apply default attributes first
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: defaultColor
        ]
        textStorage.setAttributes(defaultAttributes, range: fullRange)
        
        // Tokenize and apply colors
        applyTokenColors(to: textStorage, source: source)
        
        textStorage.endEditing()
    }
    
    private func applyTokenColors(to textStorage: NSTextStorage, source: String) {
        let lines = source.components(separatedBy: .newlines)
        var lineStartOffset = 0
        
        for line in lines {
            let lineLength = (line as NSString).length
            
            if !line.isEmpty {
                let lexer = Lexer(source: line)
                let tokens = lexer.lexAll()
                
                for (index, token) in tokens.enumerated() {
                    guard case .eof = token.kind else {
                        let color = color(for: token.kind, tokens: tokens, currentIndex: index)
                        let absoluteRange = NSRange(
                            location: lineStartOffset + token.range.location,
                            length: token.range.length
                        )
                        
                        // Ensure range is valid
                        if absoluteRange.location + absoluteRange.length <= textStorage.length {
                            textStorage.addAttribute(.foregroundColor, value: color, range: absoluteRange)
                        }
                        continue
                    }
                    break
                }
            }
            
            // Move to next line (+1 for newline character, except for last line)
            lineStartOffset += lineLength + 1
        }
    }
    
    private func color(for tokenKind: TokenKind, tokens: [Token], currentIndex: Int) -> NSColor {
        switch tokenKind {
        case .number:
            return SyntaxColors.number
        case .currencySymbol:
            return SyntaxColors.number
        case .identifier:
            // Only highlight identifiers as variables if they are part of an assignment
            // (i.e., followed eventually by an equals sign, with only other identifiers in between)
            return isPartOfAssignment(tokens: tokens, identifierIndex: currentIndex) ? SyntaxColors.identifier : defaultColor
        case .plus, .minus, .star, .slash, .caret:
            return SyntaxColors.operator
        case .equal:
            return SyntaxColors.equals
        case .leftParen, .rightParen:
            return SyntaxColors.parenthesis
        case .comment:
            return SyntaxColors.comment
        case .sumAggregate, .totalAggregate, .avgAggregate, .averageAggregate, .prevAggregate:
            return SyntaxColors.identifier
        case .eof:
            return defaultColor
        }
    }
    
    /// Checks if the identifier at the given index is part of a variable assignment.
    /// An identifier is part of an assignment if it's followed by an equals sign,
    /// possibly with other identifiers in between (for multi-word variable names).
    private func isPartOfAssignment(tokens: [Token], identifierIndex: Int) -> Bool {
        // Look ahead from the current identifier to see if we hit an equals sign
        for i in (identifierIndex + 1)..<tokens.count {
            switch tokens[i].kind {
            case .identifier:
                // Continue looking - could be a multi-word variable name
                continue
            case .equal:
                // Found equals sign - this identifier is part of an assignment
                return true
            default:
                // Found something else - this is not an assignment
                return false
            }
        }
        return false
    }
}

