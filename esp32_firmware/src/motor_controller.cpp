#include "motor_controller.h"

MotorController::MotorController()
    : stepperPan(AccelStepper::DRIVER, PIN_PAN_STEP, PIN_PAN_DIR),
      targetSpeed(0.0f),
      lastCommandTime(0),
      enabled(false) {}

void MotorController::begin() {
    pinMode(PIN_PAN_EN, OUTPUT);
    digitalWrite(PIN_PAN_EN, LOW); // Activar driver (TMC2208 activo en LOW)
    enabled = true;

    stepperPan.setMaxSpeed(MAX_PAN_SPEED);
    stepperPan.setAcceleration(PAN_ACCELERATION);
    stepperPan.setSpeed(0.0f);
    lastCommandTime = millis();
}

void MotorController::setPanVelocity(float normalizedSpeed) {
    // normalizedSpeed viene en rango [-1.0, 1.0]
    normalizedSpeed = constrain(normalizedSpeed, -1.0f, 1.0f);
    
    // Si la velocidad es insignificante (zona muerta), frenar
    if (abs(normalizedSpeed) < 0.02f) {
        targetSpeed = 0.0f;
    } else {
        targetSpeed = normalizedSpeed * MAX_PAN_SPEED;
    }

    stepperPan.setSpeed(targetSpeed);
    lastCommandTime = millis();
}

void MotorController::stop() {
    targetSpeed = 0.0f;
    stepperPan.setSpeed(0.0f);
}

void MotorController::update() {
    // Failsafe Watchdog: Si no recibimos comandos de la app en más de COMMAND_TIMEOUT_MS, frenar
    if (millis() - lastCommandTime > COMMAND_TIMEOUT_MS) {
        if (targetSpeed != 0.0f) {
            targetSpeed = 0.0f;
            stepperPan.setSpeed(0.0f);
        }
    }

    // Ejecutar el paso de tiempo para velocidad continua
    stepperPan.runSpeed();
}

bool MotorController::isMoving() const {
    return abs(targetSpeed) > 0.01f;
}
