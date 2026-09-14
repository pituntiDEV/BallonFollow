#include "ble_handler.h"

// Callbacks del Servidor BLE (Conexión / Desconexión)
class ServerCallbacks : public NimBLEServerCallbacks {
public:
    ServerCallbacks(BleHandler& handler) : handler(handler) {}

    void onConnect(NimBLEServer* pServer) override {
        handler.deviceConnected = true;
        digitalWrite(PIN_STATUS_LED, HIGH);
        Serial.println("[BLE] Smartphone conectado con éxito!");
    }

    void onDisconnect(NimBLEServer* pServer) override {
        handler.deviceConnected = false;
        handler.motor.stop();
        digitalWrite(PIN_STATUS_LED, LOW);
        Serial.println("[BLE] Smartphone desconectado. Reiniciando publicidad BLE...");
        NimBLEDevice::startAdvertising();
    }

private:
    BleHandler& handler;
};

// Callbacks de Escritura de Comandos desde el Smartphone
class RxCallbacks : public NimBLECharacteristicCallbacks {
public:
    RxCallbacks(MotorController& motor) : motor(motor) {}

    void onWrite(NimBLECharacteristic* pCharacteristic) override {
        std::string rawData = pCharacteristic->getValue();
        size_t len = rawData.length();

        // Estructura esperada del paquete (6 bytes):
        // [0xAA, pan_dir (0 o 1), pan_speed (0..255), tilt_dir, tilt_speed, checksum]
        if (len >= 6 && (uint8_t)rawData[0] == 0xAA) {
            uint8_t header = (uint8_t)rawData[0];
            uint8_t panDir = (uint8_t)rawData[1];
            uint8_t panSpeed = (uint8_t)rawData[2];
            uint8_t tiltDir = (uint8_t)rawData[3];
            uint8_t tiltSpeed = (uint8_t)rawData[4];
            uint8_t receivedChecksum = (uint8_t)rawData[5];

            uint8_t calculatedChecksum = (header ^ panDir ^ panSpeed ^ tiltDir ^ tiltSpeed) & 0xFF;

            if (receivedChecksum == calculatedChecksum) {
                // Cálculo de velocidad normalizada [-1.0, 1.0]
                float normSpeed = (float)panSpeed / 255.0f;
                float finalVelocity = (panDir == 1) ? normSpeed : -normSpeed;

                motor.setPanVelocity(finalVelocity);
            } else {
                Serial.printf("[BLE ERR] Checksum inválido: Calc=0x%02X, Recv=0x%02X\n", 
                              calculatedChecksum, receivedChecksum);
            }
        }
    }

private:
    MotorController& motor;
};

BleHandler::BleHandler(MotorController& motorCtrl)
    : motor(motorCtrl),
      pServer(nullptr),
      pRxCharacteristic(nullptr),
      pTxCharacteristic(nullptr),
      deviceConnected(false) {}

void BleHandler::begin() {
    pinMode(PIN_STATUS_LED, OUTPUT);
    digitalWrite(PIN_STATUS_LED, LOW);

    Serial.println("[BLE] Inicializando NimBLE Stack...");
    NimBLEDevice::init(BLE_DEVICE_NAME);
    NimBLEDevice::setPower(ESP_PWR_LVL_P9); // Máxima potencia de transmisión (+9dBm)

    pServer = NimBLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks(*this));

    NimBLEService* pService = pServer->createService(SERVICE_UUID);

    // Característica para recibir comandos de la App
    pRxCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID_RX,
        NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR
    );
    pRxCharacteristic->setCallbacks(new RxCallbacks(motor));

    // Característica para telemetría hacia la App (opcional)
    pTxCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID_TX,
        NIMBLE_PROPERTY::NOTIFY
    );

    pService->start();

    NimBLEAdvertising* pAdvertising = NimBLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->start();

    Serial.printf("[BLE] Publicidad iniciada. Nombre: '%s'\n", BLE_DEVICE_NAME);
}

bool BleHandler::isClientConnected() const {
    return deviceConnected;
}
