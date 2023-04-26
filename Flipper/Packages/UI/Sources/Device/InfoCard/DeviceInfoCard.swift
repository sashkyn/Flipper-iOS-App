import Core
import SwiftUI

import struct Peripheral.ProtobufVersion
import struct Peripheral.StorageSpace

struct DeviceInfoCard: View {
    @EnvironmentObject var device: Device

    var flipper: Flipper? {
        device.flipper
    }

    var isConnecting: Bool {
        flipper?.state == .connecting
    }
    var isConnected: Bool {
        flipper?.state == .connected
    }
    var isDisconnected: Bool {
        flipper?.state == .disconnected ||
        flipper?.state == .pairingFailed ||
        flipper?.state == .invalidPairing
    }
    var isNoDevice: Bool {
        flipper == nil
    }
    var isUpdating: Bool {
        device.status == .updating
    }

    var _protobufVersion: ProtobufVersion? {
        flipper?.information?.protobufRevision
    }

    var protobufVersion: String? {
        guard isConnected else { return nil }
        guard let version = _protobufVersion else { return nil }
        return version == .unknown ? "—" : version.rawValue
    }

    var firmwareVersion: String? {
        guard isConnected else { return nil }
        guard let info = flipper?.information else { return nil }
        return info.firmwareVersion?.description ?? "invalid"
    }

    var firmwareVersionColor: Color {
        guard let firmwareVersion else { return .clear }
        switch firmwareVersion {
        case _ where firmwareVersion.starts(with: "Dev"): return .development
        case _ where firmwareVersion.starts(with: "RC"): return .candidate
        case _ where firmwareVersion.starts(with: "Release"): return .release
        default: return .clear
        }
    }

    var firmwareBuild: String? {
        guard isConnected else { return nil }
        guard let info = flipper?.information else { return nil }

        let build = info
            .softwareRevision
            .split(separator: " ")
            .suffix(1)
            .joined(separator: " ")

        return .init(build)
    }

    var internalSpace: AttributedString? {
        guard isConnected, let int = flipper?.storage?.internal else {
            return nil
        }
        var result = AttributedString(int.description)
        if int.free < 20_000 {
            result.foregroundColor = .sRed
        }
        return result
    }

    var externalSpace: AttributedString? {
        guard isConnected, flipper?.storage?.internal != nil else {
            return nil
        }
        guard let ext = flipper?.storage?.external else {
            return "—"
        }
        var result = AttributedString(ext.description)
        if ext.free < 100_000 {
            result.foregroundColor = .sRed
        }
        return result
    }

    var body: some View {
        Card {
            VStack(spacing: 0) {
                HStack {
                    Text("Device Info")
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.horizontal, 12)

                if isUpdating {
                    VStack(spacing: 4) {
                        Spinner()
                        Text(
                            "Waiting for Flipper to finish update.\n" +
                            "Reconnecting..."
                        )
                        .multilineTextAlignment(.center)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black30)
                    }
                    .padding(.top, 66)
                    .padding(.bottom, 62)
                } else if isDisconnected || isNoDevice {
                    VStack(spacing: 2) {
                        Image("InfoNoDevice")
                        Text("Connect to Flipper to see device info")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black30)
                    }
                    .padding(.vertical, 62)
                } else {
                    VStack(spacing: 12) {
                        CardRow(
                            name: "Firmware Version",
                            value: firmwareVersion
                        )
                        .foregroundColor(firmwareVersionColor)
                        .padding(.horizontal, 12)
                        Divider()
                        CardRow(
                            name: "Build Date",
                            value: firmwareBuild
                        )
                        .padding(.horizontal, 12)

                        Divider()
                        CardRow(
                            name: "Int. Flash (Used/Total)",
                            value: internalSpace
                        )
                        .padding(.horizontal, 12)

                        Divider()
                        CardRow(
                            name: "SD Card (Used/Total)",
                            value: externalSpace
                        )
                        .padding(.horizontal, 12)

                        HStack {
                            Text("Full info")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black16)
                        .padding(.top, 5)
                    }
                    .padding(.top, 18)
                    .padding(.bottom, 12)
                }
            }
        }
    }
}

extension StorageSpace: CustomStringConvertible {
    public var description: String {
        "\(used.hr) / \(total.hr)"
    }
}

fileprivate extension Int {
    var bytes: Int {
        1024
    }

    var units: [String] {
        ["KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"]
    }

    var hr: String {
        guard self >= bytes else { return "\(self) B" }
        let exp = Int(log2(Double(self)) / log2(Double(bytes)))
        let unit = units[exp - 1]
        let number = Double(self) / pow(Double(bytes), Double(exp))
        return (exp <= 1 || number >= 100)
            ? String(format: "%.0f %@", number, unit)
            : String(format: "%.1f %@", number, unit)
                .replacingOccurrences(of: ".0", with: "")
    }
}
