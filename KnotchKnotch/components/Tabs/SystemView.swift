//
//  SystemView.swift
//  KnotchKnotch
//

import SwiftUI

struct SystemView: View {
    @EnvironmentObject private var vm: BoringViewModel
    @StateObject private var monitor = SystemMonitorService()

    var body: some View {
        SystemOverview(snapshot: monitor.snapshot, cpuHistory: monitor.cpuHistory)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                print("[SystemView] start")
                if vm.notchState == .open {
                    monitor.start()
                }
            }
            .onDisappear {
                print("[SystemView] stop")
                monitor.stop()
            }
            .onChange(of: vm.notchState) { _, state in
                if state == .open {
                    print("[SystemView] start")
                    monitor.start()
                } else {
                    print("[SystemView] stop")
                    monitor.stop()
                }
            }
    }
}
