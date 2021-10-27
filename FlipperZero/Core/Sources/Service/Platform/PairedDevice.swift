import Combine
import Injector
import struct Foundation.UUID

class PairedDevice: PairedDeviceProtocol, ObservableObject {
    @Inject var connector: BluetoothConnector
    @Inject var storage: DeviceStorage
    var disposeBag: DisposeBag = .init()

    private var isReconnecting = false
    private var peripheralSubject: SafeValueSubject<Peripheral?> = .init(nil)

    private var flipper: BluetoothPeripheral? {
        didSet {
            if let flipper = flipper {
                subscribeToUpdates()
                storage.pairedDevice = .init(flipper)
                peripheralSubject.value = .init(flipper)
            }
        }
    }

    var peripheral: SafePublisher<Peripheral?> {
        peripheralSubject.eraseToAnyPublisher()
    }

    init() {
        if let pairedDevice = storage.pairedDevice {
            isReconnecting = true
            peripheralSubject.value = pairedDevice
            reconnectOnBluetoothReady(to: pairedDevice.id)
        }

        saveLastConnectedDeviceOnConnect()
    }

    func reconnectOnBluetoothReady(to uuid: UUID) {
        connector.status
            .sink { [weak self] status in
                if status == .ready {
                    self?.connector.connect(to: uuid)
                }
            }
            .store(in: &disposeBag)
    }

    func saveLastConnectedDeviceOnConnect() {
        connector
            .connectedPeripherals
            .sink { [weak self] peripherals in
                guard let self = self else { return }
                guard let peripheral = peripherals.first else {
                    if self.isReconnecting { self.isReconnecting = false }
                    return
                }
                self.flipper = peripheral
            }
            .store(in: &disposeBag)
    }

    func subscribeToUpdates() {
        flipper?.info
            .sink { [weak self] in
                if let flipper = self?.flipper {
                    self?.flipper = flipper
                }
            }
            .store(in: &disposeBag)
    }

    func disconnect() {
        if let flipper = flipper {
            connector.disconnect(from: flipper.id)
        }
    }

    func send(_ request: Request, continuation: @escaping Continuation) {
        flipper?.send(request, continuation: continuation)
    }
}
