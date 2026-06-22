import SwiftUI

/// A simple block-level Markdown renderer covering headings, lists,
/// code blocks, blockquotes and paragraphs. Inline styling (bold,
/// italic, links, inline code) within each block is handled by
/// AttributedString's built-in Markdown parser.
enum MarkdownBlock: Identifiable {
    case heading(level: Int, text: String)
    case bullet(text: String)
    case numbered(index: String, text: String)
    case codeBlock(lines: [String])
    case quote(text: String)
    case paragraph(text: String)
    case table(headers: [String], rows: [[String]])
    case spacer

    var id: UUID { UUID() }
}

struct MarkdownParser {
    static func parse(_ source: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = source.components(separatedBy: .newlines)
        var i = 0
        var paragraphBuffer: [String] = []

        func flushParagraph() {
            if !paragraphBuffer.isEmpty {
                blocks.append(.paragraph(text: paragraphBuffer.joined(separator: " ")))
                paragraphBuffer.removeAll()
            }
        }

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                flushParagraph()
                var codeLines: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[i])
                    i += 1
                }
                blocks.append(.codeBlock(lines: codeLines))
                i += 1
                continue
            }

            if trimmed.isEmpty {
                flushParagraph()
                blocks.append(.spacer)
                i += 1
                continue
            }

            if let headingMatch = headingLevel(trimmed) {
                flushParagraph()
                blocks.append(.heading(level: headingMatch.level, text: headingMatch.text))
                i += 1
                continue
            }

            if trimmed.contains("|"),
               i + 1 < lines.count,
               isTableSeparator(lines[i + 1].trimmingCharacters(in: .whitespaces)) {
                flushParagraph()
                let headers = tableCells(trimmed)
                var rows: [[String]] = []
                i += 2
                while i < lines.count {
                    let rowTrimmed = lines[i].trimmingCharacters(in: .whitespaces)
                    guard rowTrimmed.contains("|"), !rowTrimmed.isEmpty else { break }
                    rows.append(tableCells(rowTrimmed))
                    i += 1
                }
                blocks.append(.table(headers: headers, rows: rows))
                continue
            }

            if trimmed.hasPrefix("> ") || trimmed == ">" {
                flushParagraph()
                let text = String(trimmed.dropFirst(trimmed.hasPrefix("> ") ? 2 : 1))
                blocks.append(.quote(text: text))
                i += 1
                continue
            }

            if let bulletText = bulletText(trimmed) {
                flushParagraph()
                blocks.append(.bullet(text: bulletText))
                i += 1
                continue
            }

            if let numbered = numberedListItem(trimmed) {
                flushParagraph()
                blocks.append(.numbered(index: numbered.index, text: numbered.text))
                i += 1
                continue
            }

            paragraphBuffer.append(trimmed)
            i += 1
        }
        flushParagraph()
        return blocks
    }

    private static func headingLevel(_ line: String) -> (level: Int, text: String)? {
        guard line.hasPrefix("#") else { return nil }
        var level = 0
        var idx = line.startIndex
        while idx < line.endIndex, line[idx] == "#" {
            level += 1
            idx = line.index(after: idx)
        }
        guard level >= 1 && level <= 6, idx < line.endIndex, line[idx] == " " else { return nil }
        let text = String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
        return (level, text)
    }

    private static func bulletText(_ line: String) -> String? {
        for prefix in ["- ", "* ", "+ "] {
            if line.hasPrefix(prefix) {
                return String(line.dropFirst(prefix.count))
            }
        }
        return nil
    }

    private static func numberedListItem(_ line: String) -> (index: String, text: String)? {
        guard let dotRange = line.range(of: ". ") else { return nil }
        let prefix = line[line.startIndex..<dotRange.lowerBound]
        guard !prefix.isEmpty, prefix.allSatisfy(\.isNumber) else { return nil }
        let text = String(line[dotRange.upperBound...])
        return (String(prefix), text)
    }

    /// Matches GFM table separator rows, e.g. "|---|:---:|---:|" or "---|---".
    private static func isTableSeparator(_ line: String) -> Bool {
        guard line.contains("-") else { return false }
        let cells = line.split(separator: "|", omittingEmptySubsequences: true)
        guard !cells.isEmpty else { return false }
        return cells.allSatisfy { cell in
            let trimmedCell = cell.trimmingCharacters(in: .whitespaces)
            guard !trimmedCell.isEmpty else { return false }
            return trimmedCell.allSatisfy { $0 == "-" || $0 == ":" }
        }
    }

    private static func tableCells(_ line: String) -> [String] {
        var stripped = line
        if stripped.hasPrefix("|") { stripped.removeFirst() }
        if stripped.hasSuffix("|") { stripped.removeLast() }
        return stripped.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

struct InlineMarkdownText: View {
    let text: String

    var body: some View {
        Text(attributed)
    }

    private var attributed: AttributedString {
        var options = AttributedString.MarkdownParsingOptions()
        options.interpretedSyntax = .inlineOnlyPreservingWhitespace
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

struct MarkdownView: View {
    let source: String

    private var blocks: [MarkdownBlock] {
        MarkdownParser.parse(source)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    blockView(block)
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            InlineMarkdownText(text: text)
                .font(headingFont(level))
                .fontWeight(.bold)
                .padding(.top, level <= 2 ? 8 : 4)
                .padding(.bottom, 2)

        case .bullet(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                InlineMarkdownText(text: text)
            }
            .padding(.leading, 12)

        case .numbered(let index, let text):
            HStack(alignment: .top, spacing: 8) {
                Text("\(index).")
                InlineMarkdownText(text: text)
            }
            .padding(.leading, 12)

        case .codeBlock(let lines):
            Text(lines.joined(separator: "\n"))
                .font(.system(.body, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(6)

        case .quote(let text):
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 3)
                InlineMarkdownText(text: text)
                    .foregroundColor(.secondary)
            }

        case .paragraph(let text):
            InlineMarkdownText(text: text)

        case .table(let headers, let rows):
            tableView(headers: headers, rows: rows)

        case .spacer:
            Spacer().frame(height: 4)
        }
    }

    /// Columns whose content is short across header + all rows are kept at their
    /// natural compact width; the remaining (typically long-text) columns absorb
    /// the leftover space and wrap, which keeps total table height to a minimum.
    private static let shortColumnCharThreshold = 14

    private func isShortColumn(_ index: Int, headers: [String], rows: [[String]]) -> Bool {
        var maxLength = headers[index].count
        for row in rows where index < row.count {
            maxLength = max(maxLength, row[index].count)
        }
        return maxLength <= Self.shortColumnCharThreshold
    }

    @ViewBuilder
    private func tableView(headers: [String], rows: [[String]]) -> some View {
        Grid(alignment: .topLeading, horizontalSpacing: 16, verticalSpacing: 0) {
            GridRow {
                ForEach(Array(headers.enumerated()), id: \.offset) { col, header in
                    tableCell(header, bold: true, isShort: isShortColumn(col, headers: headers, rows: rows))
                }
            }
            Divider().gridCellColumns(max(headers.count, 1))
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(headers.indices), id: \.self) { col in
                        tableCell(col < row.count ? row[col] : "", bold: false, isShort: isShortColumn(col, headers: headers, rows: rows))
                    }
                }
                Divider().gridCellColumns(max(headers.count, 1))
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func tableCell(_ text: String, bold: Bool, isShort: Bool) -> some View {
        let label = InlineMarkdownText(text: text)
            .fontWeight(bold ? .bold : .regular)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

        if isShort {
            label.fixedSize(horizontal: true, vertical: false)
        } else {
            label.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func headingFont(_ level: Int) -> Font {
        switch level {
        case 1: return .system(size: 26)
        case 2: return .system(size: 22)
        case 3: return .system(size: 19)
        case 4: return .system(size: 17)
        case 5: return .system(size: 15)
        default: return .system(size: 14)
        }
    }
}
