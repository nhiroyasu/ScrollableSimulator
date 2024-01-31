import Foundation

enum Logger {
    static func info(_ items: Any?, file: String = #file, line: Int = #line, function: String = #function) {
        #if DEBUG
        let filename = URL(fileURLWithPath: file).lastPathComponent
        if let items = items {
            print("✅ [\(filename) \(line):\(function)] : \(items)")
        } else {
            print("✅ [\(filename) \(line):\(function)]")
        }
        #endif
    }

    static func warn(_ items: Any?, file: String = #file, line: Int = #line, function: String = #function) {
        #if DEBUG
        let filename = URL(fileURLWithPath: file).lastPathComponent
        if let items = items {
            print("⚠️ [\(filename) \(line):\(function)] : \(items)")
        } else {
            print("⚠️ [\(filename) \(line):\(function)]")
        }
        #endif
    }

    static func error(_ items: Any?, file: String = #file, line: Int = #line, function: String = #function) {
        #if DEBUG
        let filename = URL(fileURLWithPath: file).lastPathComponent
        if let items = items {
            print("⛔️ [\(filename) \(line):\(function)] : \(items)")
        } else {
            print("⛔️ [\(filename) \(line):\(function)]")
        }
        #endif
    }
}
