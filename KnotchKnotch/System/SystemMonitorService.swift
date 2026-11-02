//
//  SystemMonitorService.swift
//  KnotchKnotch
//

import Foundation
import Combine

@MainActor
final class SystemMonitorService: ObservableObject {
    @Published private(set) var snapshot: SystemSnapshot?
    private(set) var cpuHistory = RingBuffer<CPUUsage>(capacity: 60)

    private let cpuMonitor = CPUMonitor()
    private let memoryMonitor = MemoryMonitor()
    private let networkMonitor = NetworkMonitor()
    private let batteryMonitor = BatteryMonitor()
    private let queue = DispatchQueue(label: "com.knotch.system-monitor", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var running = false

    func start() {
        guard !running else { return }
        running = true
        batteryMonitor.start { [weak self] battery in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.update(battery: battery)
            }
        }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .seconds(1), leeway: .milliseconds(200))
        timer.setEventHandler { [weak self] in
            Task { @MainActor [weak self] in
                self?.sample()
            }
        }
        self.timer = timer
        timer.resume()
    }

    func stop() {
        guard running else { return }
        running = false
        timer?.setEventHandler {}
        timer?.cancel()
        timer = nil
        batteryMonitor.stop()
    }

    private func sample() {
        let cpu = cpuMonitor.sample()
        if let cpu { cpuHistory.append(cpu) }
        let next = SystemSnapshot(
            cpu: cpu ?? snapshot?.cpu,
            memory: memoryMonitor.sample() ?? snapshot?.memory,
            network: networkMonitor.sample() ?? snapshot?.network,
            battery: snapshot?.battery
        )
        publishIfChanged(next)
    }

    private func update(battery: BatteryInfo?) {
        let next = SystemSnapshot(
            cpu: snapshot?.cpu,
            memory: snapshot?.memory,
            network: snapshot?.network,
            battery: battery
        )
        publishIfChanged(next)
    }

    private func publishIfChanged(_ next: SystemSnapshot) {
        guard snapshot != next else { return }
        snapshot = next
    }

    deinit {
        timer?.setEventHandler {}
        timer?.cancel()
        batteryMonitor.stop()
    }
}
