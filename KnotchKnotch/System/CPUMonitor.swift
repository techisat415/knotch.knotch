//
//  CPUMonitor.swift
//  KnotchKnotch
//

import Darwin

final class CPUMonitor {
    private var previousTicks: (user: UInt32, system: UInt32, idle: UInt32, nice: UInt32)?

    func sample() -> CPUUsage? {
        var load = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &load) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        let ticks = (
            user: load.cpu_ticks.0,
            system: load.cpu_ticks.1,
            idle: load.cpu_ticks.2,
            nice: load.cpu_ticks.3
        )
        defer { previousTicks = ticks }
        guard let previousTicks else { return nil }

        let user = ticks.user &- previousTicks.user
        let system = ticks.system &- previousTicks.system
        let idle = ticks.idle &- previousTicks.idle
        let nice = ticks.nice &- previousTicks.nice
        let total = user &+ system &+ idle &+ nice
        guard total > 0 else { return nil }

        let denominator = Double(total)
        let usage = CPUUsage(
            total: Double(user &+ system &+ nice) / denominator * 100,
            user: Double(user &+ nice) / denominator * 100,
            system: Double(system) / denominator * 100
        )
        return usage
    }
}
