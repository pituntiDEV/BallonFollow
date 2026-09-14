#include <Arduino.h>
#include "config.h"
#include "motor_controller.h"
#include "ble_handler.h"

MotorController motor;
BleHandler ble(motor);

void setup() {
    Serial.begin(115200);
    delay(1000);
    Serial.println("\n=============================================");
    Serial.println("   ESP32 SOCCER BALL TRACKER MOUNT v1.0      ");
    Serial.println("=============================================");

    motor.begin();
    ble.begin();

    Serial.println("[SYSTEM] Sistema listo esperando conexión BLE.");
}

void loop() {
    // Actualización de alta frecuencia de pasos de motor y watchdog
    motor.update();

    // Pequeño yield para evitar saturar el watchdog del ESP32
    yield();
}
