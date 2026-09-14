#pragma once

#include <Arduino.h>

// ==========================================
// Configuración de Pines del ESP32
// ==========================================
// Driver TMC2208 / A4988 para Motor Pan (Horizontal)
#define PIN_PAN_STEP    18   // Pin de paso (STEP)
#define PIN_PAN_DIR     19   // Pin de dirección (DIR)
#define PIN_PAN_EN      21   // Pin de habilitación (ENABLE, Activo en LOW)

// Driver Opcional para Motor Tilt (Vertical) o Servo
#define PIN_TILT_STEP   22
#define PIN_TILT_DIR    23
#define PIN_TILT_EN     25

// LED indicador de estado BLE
#define PIN_STATUS_LED  2    // LED interno en la mayoría de placas ESP32

// ==========================================
// Parámetros de Movimiento
// ==========================================
#define MAX_PAN_SPEED       3200.0f  // Pasos por segundo (con 1/16 micropasos = 1 vuelta/seg)
#define PAN_ACCELERATION    4000.0f  // Aceleración pasos/s^2 para movimiento suave
#define COMMAND_TIMEOUT_MS  600      // Si no recibe datos en 600ms, frena por seguridad

// ==========================================
// UUIDs de Bluetooth Low Energy (BLE)
// ==========================================
#define BLE_DEVICE_NAME             "BallTracker-ESP32"
#define SERVICE_UUID                "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID_RX      "beb5483e-36e1-4688-b7f5-ea07361b26a8" // Escribir comandos desde App
#define CHARACTERISTIC_UUID_TX      "beb5483e-36e1-4688-b7f5-ea07361b26a9" // Notificaciones hacia App
