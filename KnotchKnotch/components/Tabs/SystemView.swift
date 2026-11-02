//
//  SystemView.swift
//  KnotchKnotch
//

import SwiftUI

struct SystemView: View {
    @StateObject private var monitor = SystemMonitorService()

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.xyaxis.line")
                .symbolRenderingMode(.hierarchical)
                .imageScale(.large)

            Text("System")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.medium)

            Text(String(describing: monitor.snapshot))
                .font(.caption2)
                .monospaced()
                .textSelection(.enabled)
        }
        .foregroundStyle(.gray)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { monitor.start() }
        .onDisappear { monitor.stop() }
    }
}
