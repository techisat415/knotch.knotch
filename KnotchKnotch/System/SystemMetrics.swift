//
//  SystemMetrics.swift
//  KnotchKnotch
//

import Foundation

struct CPUUsage: Equatable {
    let total: Double
    let user: Double
    let system: Double
}

struct MemoryUsage: Equatable {
    let usedBytes: UInt64
    let totalBytes: UInt64
    let swapUsedBytes: UInt64
    let swapTotalBytes: UInt64
    let pressureLevel: Int
}

struct NetworkRate: Equatable {
    let receivedBytesPerSecond: UInt64
    let transmittedBytesPerSecond: UInt64
}

struct BatteryInfo: Equatable {
    let currentCapacity: Int
    let maxCapacity: Int
    let isCharging: Bool
    let isPluggedIn: Bool
    let timeRemaining: Int?
    let isTimeRemainingCalculating: Bool
}

struct SystemSnapshot: Equatable {
    let cpu: CPUUsage?
    let memory: MemoryUsage?
    let network: NetworkRate?
    let battery: BatteryInfo?
}

struct RingBuffer<Element> {
    private(set) var elements: [Element] = []
    let capacity: Int

    init(capacity: Int) {
        precondition(capacity > 0)
        self.capacity = capacity
    }

    mutating func append(_ element: Element) {
        if elements.count == capacity {
            elements.removeFirst()
        }
        elements.append(element)
    }
}
