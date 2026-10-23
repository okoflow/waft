import CoreGraphics
import Foundation

nonisolated struct ForeignWindow {
    let level: Int
    let bounds: CGRect

    init(level: Int, bounds: CGRect) {
        self.level = level
        self.bounds = bounds
    }

    private init?(info: [String: Any], excluding ownProcess: pid_t) {
        guard let process = info[kCGWindowOwnerPID as String] as? pid_t,
              process != ownProcess,
              let level = info[kCGWindowLayer as String] as? Int,
              let alpha = info[kCGWindowAlpha as String] as? Double,
              alpha > 0,
              let boundsInfo = info[kCGWindowBounds as String] as? NSDictionary,
              let bounds = CGRect(dictionaryRepresentation: boundsInfo as CFDictionary) else { return nil }

        self.init(level: level, bounds: bounds)
    }

    static func onScreen() -> [Self] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]

        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return [] }

        let ownProcess = getpid()

        return windows.compactMap { Self(info: $0, excluding: ownProcess) }
    }

    static func coveringLevel(of area: CGRect, on screen: CGRect, among windows: [Self]) -> Int? {
        let menuBarLevel = Int(CGWindowLevelForKey(.mainMenuWindow))

        let covering = windows.filter { window in
            guard window.level >= menuBarLevel, window.bounds.width < screen.width else { return false }

            return window.bounds.intersects(area)
        }

        return covering.map(\.level).max()
    }
}
