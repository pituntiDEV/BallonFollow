#pragma once

#include <Arduino.h>
#include <NimBLEDevice.h>
#include "config.h"
#include "motor_controller.h"

class BleHandler {
public:
    BleHandler(MotorController& motorCtrl);
    void begin();
    bool isClientConnected() const;

private:
    MotorController& motor;
    NimBLEServer* pServer;
    NimBLECharacteristic* pRxCharacteristic;
    NimBLECharacteristic* pTxCharacteristic;
    bool deviceConnected;

    friend class ServerCallbacks;
    friend class RxCallbacks;
};
