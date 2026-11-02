//
//  NetworkMonitor.swift
//  KnotchKnotch
//

import Darwin

final class NetworkMonitor {
    private var previousBytes: (received: UInt64, transmitted: UInt64)?

    func sample() -> NetworkRate? {
        var addresses: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addresses) == 0, let first = addresses else { return nil }
        defer { freeifaddrs(addresses) }

        var received: UInt64 = 0
        var transmitted: UInt64 = 0
        var current: UnsafeMutablePointer<ifaddrs>? = first
        while let address = current {
            defer { current = address.pointee.ifa_next }
            let interface = address.pointee
            guard (interface.ifa_flags & UInt32(IFF_LOOPBACK)) == 0,
                  (interface.ifa_flags & UInt32(IFF_UP)) != 0,
                  let socketAddress = interface.ifa_addr,
                  socketAddress.pointee.sa_family == UInt8(AF_LINK),
                  let data = interface.ifa_data else { continue }
            let statistics = data.assumingMemoryBound(to: if_data.self).pointee
            received &+= UInt64(statistics.ifi_ibytes)
            transmitted &+= UInt64(statistics.ifi_obytes)
        }

        defer { previousBytes = (received, transmitted) }
        guard let previousBytes else { return NetworkRate(receivedBytesPerSecond: 0, transmittedBytesPerSecond: 0) }
        guard received >= previousBytes.received, transmitted >= previousBytes.transmitted else {
            return NetworkRate(receivedBytesPerSecond: 0, transmittedBytesPerSecond: 0)
        }
        return NetworkRate(
            receivedBytesPerSecond: received &- previousBytes.received,
            transmittedBytesPerSecond: transmitted &- previousBytes.transmitted
        )
    }
}
