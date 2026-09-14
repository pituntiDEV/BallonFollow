#pragma once

#include <Arduino.h>
#include <AccelStepper.h>
#include "config.h"

class MotorController {
public:
    MotorController();
    void begin();
    void update();
    void setPanVelocity(float normalizedSpeed); // -1.0 a +1.0
    void stop();
    bool isMoving() const;

private:
    AccelStepper stepperPan;
    float targetSpeed;
    unsigned long lastCommandTime;
    bool enabled;
};
