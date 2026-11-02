//
//  MemoryMonitor.swift
//  KnotchKnotch
//

import Darwin
import Foundation

final class MemoryMonitor {
    func sample() -> MemoryUsage? {
        var statistics = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &statistics) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }

        var pageSize: vm_size_t = 0
        guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS else { return nil }

        let usedPages = (statistics.internal_page_count &- statistics.purgeable_count)
            &+ statistics.wire_count
            &+ statistics.compressor_page_count
        let totalBytes = UInt64(ProcessInfo.processInfo.physicalMemory)
        let swap = swapUsage()
        return MemoryUsage(
            usedBytes: UInt64(usedPages) * UInt64(pageSize),
            totalBytes: totalBytes,
            swapUsedBytes: swap.used,
            swapTotalBytes: swap.total,
            pressureLevel: pressureLevel()
        )
    }

    private func swapUsage() -> (used: UInt64, total: UInt64) {
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        guard sysctlbyname("vm.swapusage", &usage, &size, nil, 0) == 0 else {
            return (0, 0)
        }
        return (UInt64(usage.xsu_used), UInt64(usage.xsu_total))
    }

    private func pressureLevel() -> Int {
        var level: Int32 = 1
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0) == 0 else {
            return 1
        }
        return Int(level)
    }
}
