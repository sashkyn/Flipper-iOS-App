import Core
import Inject
import Peripheral
import Foundation
import Combine

@MainActor
class DeviceViewModel: ObservableObject {
    @Inject var rpc: RPC
    private let appState: AppState = .shared
    private var disposeBag: DisposeBag = .init()

    @Published var showForgetAction = false
    @Published var showPairingIssueAlert = false
    @Published var showUnsupportedVersionAlert = false

    @Published var flipper: Flipper?
    @Published var status: DeviceStatus = .noDevice {
        didSet {
            switch status {
            case .invalidPairing: showPairingIssueAlert = true
            case .unsupportedDevice: showUnsupportedVersionAlert = true
            default: break
            }
        }
    }

    var canSync: Bool {
        status == .connected
    }

    var canPlayAlert: Bool {
        flipper?.state == .connected &&
        status != .unsupportedDevice
    }

    var canConnect: Bool {
        flipper?.state == .disconnected ||
        flipper?.state == .disconnecting
    }

    var canDisconnect: Bool {
        flipper?.state == .connected ||
        flipper?.state == .connecting
    }

    var canForget: Bool {
        status != .noDevice
    }

    init() {
        appState.$flipper
            .receive(on: DispatchQueue.main)
            .assign(to: \.flipper, on: self)
            .store(in: &disposeBag)

        appState.$status
            .receive(on: DispatchQueue.main)
            .assign(to: \.status, on: self)
            .store(in: &disposeBag)
    }

    func showWelcomeScreen() {
        appState.isFirstLaunch = true
    }

    func connect() {
        if status == .noDevice {
            showWelcomeScreen()
        } else {
            appState.connect()
        }
    }

    func disconnect() {
        appState.disconnect()
    }

    func showForgetActionSheet() {
        showForgetAction = true
    }

    func forgetFlipper() {
        appState.forgetDevice()
    }

    func sync() {
        Task { await appState.synchronize() }
    }

    func playAlert() {
        Task {
            try await rpc.playAlert()
        }
    }

    // MARK: Update

    enum Channel {
        case development
        case canditate
        case release
    }

    @Published var updateChannel: Channel = .development {
        didSet { didSetChannel() }
    }

    var targetVersion: String {
        switch updateChannel {
        case .development: return "Dev 000ebb8f"
        case .canditate: return "RC 0.55.1"
        case .release: return "Release 0.55.0"
        }
    }

    func didSetChannel() {
    }

    func update() {
        print("update")
    }
}
