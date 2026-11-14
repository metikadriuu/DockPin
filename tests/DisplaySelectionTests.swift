import AppKit

private typealias Display = (id: CGDirectDisplayID?, uuid: String?)

private let builtin: Display = (1, "BUILTIN")
private let monitorA: Display = (2, "MONITOR-A")
private let monitorB: Display = (3, "MONITOR-B")

@main
enum DisplaySelectionTests {
    static func main() {
        var failures = 0

        func check(_ name: String, followMain: Bool, main: Display, locked: Display,
                   _ displays: [Display], picks expected: Int?) {
            let got = DisplayUtils.targetIndex(followMain: followMain,
                                               mainID: main.id ?? 0,
                                               lockedUUID: locked.uuid ?? "",
                                               displays: displays)
            if got == expected {
                print("ok    \(name)")
            } else {
                failures += 1
                print("FAIL  \(name): expected \(String(describing: expected)), got \(String(describing: got))")
            }
        }

        // Manual mode: the saved display, whatever the Main Display is.
        check("manual: locked external while built-in is main",
              followMain: false, main: builtin, locked: monitorA, [builtin, monitorA], picks: 1)
        check("manual: locked built-in while external is main",
              followMain: false, main: monitorA, locked: builtin, [monitorA, builtin], picks: 1)
        check("manual: unaffected when the Main Display moves to another monitor",
              followMain: false, main: monitorB, locked: monitorA, [builtin, monitorA, monitorB], picks: 1)
        check("manual: follows the display, not its list position",
              followMain: false, main: builtin, locked: monitorA, [monitorA, monitorB, builtin], picks: 0)
        check("manual: locked display disconnected is not replaced",
              followMain: false, main: monitorA, locked: monitorB, [builtin, monitorA], picks: nil)
        check("manual: no saved display matches nothing",
              followMain: false, main: builtin, locked: (nil, nil), [builtin, (4, nil)], picks: nil)

        // Automatic mode: the Main Display, built-in or external alike.
        check("auto: built-in only",
              followMain: true, main: builtin, locked: monitorA, [builtin], picks: 0)
        check("auto: one external set as main",
              followMain: true, main: monitorA, locked: builtin, [monitorA, builtin], picks: 0)
        check("auto: built-in is main next to one external",
              followMain: true, main: builtin, locked: monitorA, [builtin, monitorA], picks: 0)
        check("auto: built-in is main next to two externals",
              followMain: true, main: builtin, locked: monitorA, [monitorA, builtin, monitorB], picks: 1)
        check("auto: an external is main among several",
              followMain: true, main: monitorB, locked: builtin, [builtin, monitorA, monitorB], picks: 2)
        check("auto: Main Display switched from monitor A to monitor B",
              followMain: true, main: monitorB, locked: monitorA, [monitorA, monitorB, builtin], picks: 1)
        check("auto: Main Display disconnected, macOS promotes the built-in",
              followMain: true, main: builtin, locked: monitorA, [builtin, monitorB], picks: 0)
        check("auto: ignores a saved display that is still connected",
              followMain: true, main: monitorB, locked: monitorA, [builtin, monitorA, monitorB], picks: 2)
        check("auto: Main Display not in the list matches nothing",
              followMain: true, main: (9, nil), locked: builtin, [builtin, monitorA], picks: nil)
        check("auto: a screen without a display ID is never the Main Display",
              followMain: true, main: (0, nil), locked: builtin, [(nil, "UNKNOWN"), builtin], picks: nil)

        // Switching modes changes the target, not the saved display.
        let desk = [builtin, monitorA, monitorB]
        check("switch: automatic targets the Main Display",
              followMain: true, main: builtin, locked: monitorB, desk, picks: 0)
        check("switch: back to manual targets the saved display again",
              followMain: false, main: builtin, locked: monitorB, desk, picks: 2)

        print(failures == 0 ? "\nAll tests passed." : "\n\(failures) test(s) failed.")
        exit(failures == 0 ? 0 : 1)
    }
}
