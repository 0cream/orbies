import Foundation

public enum SolanaSwiftLoggerLogLevel: String {
    case info
    case error
    case warning
    case debug
}

public protocol SolanaSwiftLogger {
    func log(
        event: String,
        data: String?,
        logLevel: SolanaSwiftLoggerLogLevel,
        function: String,
        file: String,
        line: Int
    )
}

public enum Logger {
    // MARK: -

    private static var loggers: [SolanaSwiftLogger] = []

    public static func setLoggers(_ loggers: [SolanaSwiftLogger]) {
        self.loggers = loggers
    }

    public static func log(
        event: String,
        message: String?,
        logLevel: SolanaSwiftLoggerLogLevel = .info,
        function: String = #function,
        file: String = #file,
        line: Int = #line
    ) {
        loggers.forEach {
            $0.log(
                event: event,
                data: message,
                logLevel: logLevel,
                function: function,
                file: file,
                line: line
            )
        }
    }
}
