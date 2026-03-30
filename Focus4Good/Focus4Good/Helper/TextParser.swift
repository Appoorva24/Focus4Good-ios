import Foundation

/// Parsed task structure from scanned text
struct ParsedTask: Identifiable {
    let id = UUID()
    var taskName: String
    var time: Date?
    var isValid: Bool {
        !taskName.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

/// Text Parser - Extracts tasks and times from scanned text
final class TextParser {
    
    // MARK: - Main Parsing Function
    
    /// Parse scanned text to extract tasks and times
    static func parseTasksFromText(_ text: String) -> [ParsedTask] {
        var parsedTasks: [ParsedTask] = []
        
        // Split text into lines
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines
            guard !trimmedLine.isEmpty else { continue }
            
            // Try to extract task and time from this line
            if let parsedTask = parseTaskFromLine(trimmedLine) {
                parsedTasks.append(parsedTask)
            }
        }
        
        print("📝 Parsed \(parsedTasks.count) tasks from text")
        return parsedTasks
    }
    
    // MARK: - Line Parsing
    
    /// Parse a single line to extract task name and time
    private static func parseTaskFromLine(_ line: String) -> ParsedTask? {
        var cleanLine = line
        
        // Remove common task prefixes
        cleanLine = removeTaskPrefixes(from: cleanLine)
        
        // Extract time if present
        let (taskName, time) = extractTimeFromText(cleanLine)
        
        // Skip if task name is too short (likely noise)
        guard taskName.count >= 3 else {
            return nil
        }
        
        // Skip lines that look like headers or dates
        if isLikelyHeader(taskName) {
            return nil
        }
        
        return ParsedTask(taskName: taskName, time: time)
    }
    
    // MARK: - Task Prefix Removal
    
    /// Remove common task list prefixes (bullets, numbers, checkboxes)
    private static func removeTaskPrefixes(from text: String) -> String {
        var cleaned = text
        
        // Remove bullet points
        let bulletPatterns = ["•", "○", "◦", "-", "*", "✓", "☐", "☑", "□", "■"]
        for bullet in bulletPatterns {
            if cleaned.hasPrefix(bullet) {
                cleaned = String(cleaned.dropFirst()).trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Remove numbered lists (1. 2. 3. etc)
        if let regex = try? NSRegularExpression(pattern: "^\\d+\\.\\s*", options: []) {
            let range = NSRange(cleaned.startIndex..., in: cleaned)
            cleaned = regex.stringByReplacingMatches(
                in: cleaned,
                options: [],
                range: range,
                withTemplate: ""
            ).trimmingCharacters(in: .whitespaces)
        }
        
        // Remove checkbox patterns [x] [ ] etc
        if let regex = try? NSRegularExpression(pattern: "^\\[[ xX]?\\]\\s*", options: []) {
            let range = NSRange(cleaned.startIndex..., in: cleaned)
            cleaned = regex.stringByReplacingMatches(
                in: cleaned,
                options: [],
                range: range,
                withTemplate: ""
            ).trimmingCharacters(in: .whitespaces)
        }
        
        return cleaned
    }
    
    // MARK: - Time Extraction
    
    /// Extract time from text and return task name + time
    private static func extractTimeFromText(_ text: String) -> (taskName: String, time: Date?) {
        var taskName = text
        var extractedTime: Date?
        
        // Time patterns to match
        let timePatterns = [
            // 12-hour format: 3pm, 3:30pm, 3:30 PM
            "\\b(1[0-2]|0?[1-9])(?::(\\d{2}))?\\s*([aApP][mM])\\b",
            // 24-hour format: 15:00, 15:30
            "\\b([01]?\\d|2[0-3]):(\\d{2})\\b",
            // @time format: @3pm, @15:00
            "@\\s*(1[0-2]|0?[1-9])(?::(\\d{2}))?\\s*([aApP][mM])?\\b",
            // Word format: "at 3pm", "by 5:30pm"
            "(?:at|by)\\s+(1[0-2]|0?[1-9])(?::(\\d{2}))?\\s*([aApP][mM])\\b"
        ]
        
        for pattern in timePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    // Extract the matched time string
                    if let matchRange = Range(match.range, in: text) {
                        let timeString = String(text[matchRange])
                        extractedTime = parseTimeString(timeString)
                        
                        // Remove time from task name
                        taskName = text.replacingOccurrences(of: timeString, with: "")
                            .trimmingCharacters(in: .whitespaces)
                        
                        // Clean up extra words
                        taskName = taskName.replacingOccurrences(of: " at ", with: " ")
                        taskName = taskName.replacingOccurrences(of: " by ", with: " ")
                        taskName = taskName.trimmingCharacters(in: .whitespaces)
                        
                        break
                    }
                }
            }
        }
        
        return (taskName, extractedTime)
    }
    
    /// Parse time string into Date object
    private static func parseTimeString(_ timeString: String) -> Date? {
        let cleaned = timeString.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "@", with: "")
            .replacingOccurrences(of: "at ", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "by ", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespaces)
        
        let formatters = [
            "h:mma",  // 3:30pm
            "h:mm a", // 3:30 pm
            "hmma",   // 3pm
            "h a",    // 3 pm
            "HH:mm",  // 15:30 (24-hour)
            "H:mm"    // 9:30 (24-hour)
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            
            if let date = formatter.date(from: cleaned) {
                return date
            }
        }
        
        return nil
    }
    
    // MARK: - Header Detection
    
    /// Check if line is likely a header/title rather than a task
    private static func isLikelyHeader(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        
        // Common header words
        let headerKeywords = [
            "schedule", "planner", "todo", "to-do", "tasks",
            "today", "tomorrow", "monday", "tuesday", "wednesday",
            "thursday", "friday", "saturday", "sunday",
            "january", "february", "march", "april", "may", "june",
            "july", "august", "september", "october", "november", "december"
        ]
        
        // If text is just a header keyword, skip it
        if headerKeywords.contains(lowercased) {
            return true
        }
        
        // If text is all caps and short, likely a header
        if text == text.uppercased() && text.count < 20 {
            return true
        }
        
        return false
    }
    
    // MARK: - Date Detection (Future Enhancement)
    
    /// Detect dates in text (for future use)
    static func extractDatesFromText(_ text: String) -> [Date] {
        var dates: [Date] = []
        
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        
        detector?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let date = match?.date {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    // MARK: - Helper Functions
    
    /// Clean up parsed text (remove extra spaces, special chars)
    static func cleanText(_ text: String) -> String {
        var cleaned = text
        
        // Remove multiple spaces
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Remove leading/trailing whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
}

// MARK: - Example Usage
/*
 let scannedText = """
 My Schedule for Today
 
 • Buy groceries at 5pm
 - Team meeting 3:30pm
 1. Call mom
 ☐ Workout @6:30am
 Study for exam by 8pm
 """
 
 let tasks = TextParser.parseTasksFromText(scannedText)
 // Returns:
 // [
 //   ParsedTask(taskName: "Buy groceries", time: 17:00),
 //   ParsedTask(taskName: "Team meeting", time: 15:30),
 //   ParsedTask(taskName: "Call mom", time: nil),
 //   ParsedTask(taskName: "Workout", time: 06:30),
 //   ParsedTask(taskName: "Study for exam", time: 20:00)
 // ]
 */
