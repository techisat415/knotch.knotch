//
//  SystemView.swift
//  KnotchKnotch
//

import SwiftUI

struct SystemView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.xyaxis.line")
                .symbolRenderingMode(.hierarchical)
                .imageScale(.large)

            Text("System")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.medium)
        }
        .foregroundStyle(.gray)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
