import AppKit

enum DisplayUtils {
    static func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
        screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
    }

    static func uuid(for screen: NSScreen) -> String? {
        guard
            let id = displayID(for: screen),
            let cf = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue()
        else { return nil }
        return CFUUIDCreateString(nil, cf) as String?
    }

    static func label(for screen: NSScreen) -> String {
        let w = Int(screen.frame.width)
        let h = Int(screen.frame.height)
        return "\(screen.localizedName) (\(w)×\(h))"
    }

    /// The display to pin to: the Main Display when following it, otherwise the
    /// one saved as `lockedUUID`. Each mode ignores the other's input.
    static func targetIndex(followMain: Bool,
                            mainID: CGDirectDisplayID,
                            lockedUUID: String,
                            displays: [(id: CGDirectDisplayID?, uuid: String?)]) -> Int? {
        followMain
            ? displays.firstIndex { $0.id == mainID }
            : displays.firstIndex { $0.uuid == lockedUUID }
    }
}
