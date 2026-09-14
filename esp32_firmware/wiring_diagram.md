# Guía de Conexión Eléctrica y Hardware (ESP32 + TMC2208 + NEMA 17)

Este documento detalla la conexión de los componentes para el soporte giratorio de seguimiento de balón.

---

## 1. Lista de Materiales Recomendados

| Componente | Función | Recomendación |
|---|---|---|
| **Microcontrolador** | ESP32 NodeMCU (30 o 38 pines) | ESP-WROOM-32 |
| **Driver de Motor** | Controlador silencioso de micropasos | **TMC2208 o TMC2209** (Modo StealthChop) |
| **Motor Pan (Horizontal)** | Giro continuo 360° | **NEMA 17** (o motor paso a paso con reductora 28BYJ-48 a 12V) |
| **Condensador Electrolítico** | Protección contra picos de voltaje | **100 µF (16V o 25V)** |
| **Fuente de Alimentación** | Alimentación del sistema | Batería LiPo 3S (11.1V - 12.6V) o Power Bank con cable Step-Up a 12V |
| **Soporte Mecánico** | Chasis y acople de teléfono | Rodamiento axial 608 + montura de trípode 1/4" |

---

## 2. Diagrama de Conexiones (Pinout)

### Conexión ESP32 a Driver TMC2208 / A4988

| Pin Driver (TMC2208) | Conexión en ESP32 / Fuente | Descripción |
|---|---|---|
| **EN (Enable)** | **GPIO 21** | Habilita el motor (Activo en nivel BAJO) |
| **DIR (Direction)** | **GPIO 19** | Controla el sentido de giro (horario / antihorario) |
| **STEP (Paso)** | **GPIO 18** | Envía los pulsos de movimiento |
| **VIO / VDD** | **3V3 (ESP32)** | Voltaje lógico digital (3.3V) |
| **GND (Lógico)** | **GND (ESP32)** | Masa común del circuito lógico |
| **VMOT** | **+12V (Batería / Fuente)** | Voltaje de potencia para el motor |
| **GND (Potencia)** | **GND (Batería / Fuente)** | Masa de potencia (unida a GND de ESP32) |
| **1A, 1B, 2A, 2B** | **Bobinas Motor Paso a Paso** | Conectar las 4 líneas del NEMA 17 |

> [!CAUTION]
> **Condensador obligatorio**: Conecta el condensador electrolítico de **100 µF** directamente entre los pines **VMOT** y **GND de potencia** del TMC2208 lo más cerca posible del módulo. Sin este condensador, el driver puede quemarse por picos de inductancia al encender.

---

## 3. Microstepping (Configuración de Micropasos)

Para lograr un giro de cámara suave como la seda y sin saltos visibles en la grabación de video:
- Con el **TMC2208** en modo Standalone, conecta **MS1 a VIO (3.3V)** y **MS2 a VIO (3.3V)** para activar **1/16 micropasos con interpolación a 1/256**.
- Ajusta el potenciómetro de corriente (**Vref**) del driver a aproximadamente **0.6V - 0.7V** (para motores NEMA 17 típicos de 1A), asegurando buen par sin calentamiento excesivo.

---

## 4. Alimentación Portátil en Cancha

Para operar de forma 100% inalámbrica durante un partido de fútbol (90+ minutos):
1. **Power Bank USB (20,000 mAh)**:
   - Salida 1 (5V / 2A): Alimenta el ESP32 mediante su puerto Micro-USB o pin VIN.
   - Salida 2 con convertidor elevador (Step-Up DC-DC de 5V a 12V): Alimenta el pin VMOT del driver.
2. Alternativa: Batería LiPo 3S (11.1V) conectada a un módulo reductor (Buck) LM2596 que entrega 5V al ESP32 y 11.1V directos al motor.
