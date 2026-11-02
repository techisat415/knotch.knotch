//
//  BatteryMonitor.swift
//  KnotchKnotch
//

import IOKit
import IOKit.ps

final class BatteryMonitor {
    private var runLoopSource: CFRunLoopSource?
    private var callback: ((BatteryInfo?) -> Void)?

    func start(callback: @escaping (BatteryInfo?) -> Void) {
        stop()
        self.callback = callback
        guard let source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            let monitor = Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue()
            monitor.callback?(monitor.sample())
        }, Unmanaged.passUnretained(self).toOpaque())?.takeRetainedValue() else {
            return
        }
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        callback(sample())
    }

    func stop() {
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        }
        runLoopSource = nil
        callback = nil
    }

    func sample() -> BatteryInfo? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return nil
        }
        guard let source = sources.first(where: { source in
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                return false
            }
            return description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType
        }),
        let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
        let current = description[kIOPSCurrentCapacityKey] as? Int,
        let maximum = description[kIOPSMaxCapacityKey] as? Int else {
            return nil
        }

        let remaining = description[kIOPSTimeToEmptyKey] as? Int
            ?? description[kIOPSTimeToFullChargeKey] as? Int
        return BatteryInfo(
            currentCapacity: current,
            maxCapacity: maximum,
            isCharging: description[kIOPSIsChargingKey] as? Bool ?? false,
            isPluggedIn: description[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue,
            timeRemaining: remaining == -1 ? nil : remaining,
            isTimeRemainingCalculating: remaining == -1
        )
    }
}
