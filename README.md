# BallonFollow: Seguimiento Automático de Balón de Fútbol con IA y ESP32 ⚽📱🤖

Sistema completo de grabación y seguimiento autónomo de partidos de fútbol para **iPhone (iOS)** y **Android**. Utiliza Visión Artificial en el smartphone para detectar el balón en tiempo real, filtrar el área de juego (ROI de la cancha) y enviar comandos de velocidad mediante **Bluetooth Low Energy (BLE)** a un soporte motorizado con microcontrolador **ESP32** para mantener la cámara siempre centrada.

---

## 📁 Estructura del Proyecto

```
BallonFollow/
├── mobile_app/                  # Aplicación Flutter para iOS y Android
│   ├── lib/
│   │   ├── main.dart            # Punto de entrada y permisos
│   │   ├── models/              # Modelos de datos (BallDetection, FieldROI)
│   │   ├── services/            # Servicios de BLE y Visión TFLite
│   │   ├── vision/              # Filtro de Kalman, PID y Point-in-Polygon
│   │   ├── screens/             # Pantallas (Dashboard, Scanner BLE, Calibración, Tracker)
│   │   └── widgets/             # Overlays de dibujo y mira sobre el video
│   ├── test/                    # Pruebas unitarias en Dart
│   ├── android/                 # Configuración nativa y permisos de Android
│   ├── ios/                     # Configuración nativa y permisos de iOS
│   └── pubspec.yaml             # Dependencias del proyecto Flutter
│
├── esp32_firmware/              # Código fuente para el soporte motorizado ESP32
│   ├── src/
│   │   ├── main.cpp             # Bucle principal de ejecución
│   │   ├── config.h             # Pines GPIO, UUIDs BLE y constantes de velocidad
│   │   ├── ble_handler.h/.cpp   # Servidor GATT BLE con pila NimBLE
│   │   └── motor_controller.h/.cpp # Control de aceleración y micropasos (AccelStepper)
│   ├── platformio.ini           # Configuración de compilación PlatformIO
│   └── wiring_diagram.md        # Esquema de conexión electrónica y componentes
│
└── ai_model/                    # Herramientas de IA y Simulación
    ├── export_yolo_to_tflite.py # Conversión y optimización de YOLOv8 a .tflite FP16/INT8
    ├── simulation_tracker.py    # Simulación y verificación del bucle de control en Python
    └── requirements.txt         # Dependencias Python
```

---

## 🚀 Guía de Inicio Rápido

### 1. Simulación y Verificación de Algoritmos (Python)
Puedes comprobar el funcionamiento matemático del seguimiento (Filtro de Kalman + PID + Delimitación de Cancha + Protocolo BLE) ejecutando:
```bash
python ai_model/simulation_tracker.py
```

### 2. Preparar el Modelo de IA
1. Instala los requerimientos:
   ```bash
   pip install -r ai_model/requirements.txt
   ```
2. Exporta el modelo YOLOv8n optimizado a TensorFlow Lite:
   ```bash
   python ai_model/export_yolo_to_tflite.py --weights yolov8n.pt --imgsz 640
   ```
3. Copia el archivo `.tflite` generado a la carpeta de la app:
   `mobile_app/assets/models/ball_detector.tflite`

### 3. Grabar el Firmware en el ESP32
1. Abre la carpeta `esp32_firmware` en **VS Code con la extensión PlatformIO** (o Arduino IDE con soporte ESP32).
2. Conecta tu ESP32 por USB y pulsa **Upload** (o ejecuta `pio run -t upload`).
3. Consulta [`esp32_firmware/wiring_diagram.md`](file:///C:/Users/pi121/OneDrive/Escritorio/BallonFollow/esp32_firmware/wiring_diagram.md) para conectar el driver TMC2208/A4988 y el motor paso a paso NEMA 17.

### 4. Ejecutar la Aplicación Móvil (iOS / Android)
1. Entra a la carpeta `mobile_app`:
   ```bash
   cd mobile_app
   flutter pub get
   ```
2. Ejecuta en tu teléfono conectado por cable o Wi-Fi:
   ```bash
   flutter run
   ```

---

## 🎯 Modo de Uso en la Cancha

1. **Ubicación del Trípode**: Coloca el trípode motorizado a la altura del medio campo, preferiblemente a 1.8 - 2.5 metros de altura para tener una perspectiva clara.
2. **Encendido y Enlace BLE**: Enciende el ESP32. Abre la app y pulsa **"Conectar"**. La app se vinculará instantáneamente vía Bluetooth Low Energy (sin desconectar tus datos móviles ni requerir contraseñas de Wi-Fi).
3. **Calibrar Cancha de Fútbol (ROI)**: Toca los 4 vértices para ajustar el polígono verde sobre las líneas visibles de la cancha. De esta forma, si hay personas calentando o balones en la banda, el sistema los ignorará.
4. **Iniciar Grabación & Seguimiento**: Pulsa el botón grande para entrar a la cámara con IA. Pulsa el botón circular rojo para iniciar la grabación de video. El soporte moverá el teléfono automáticamente para mantener el balón en el centro exacto de la pantalla.

---

## ⚙️ Protocolo de Comunicación BLE

Para garantizar mínima latencia (< 25 ms), la app y el ESP32 intercambian paquetes binarios compactos de 6 bytes en la característica `beb5483e-36e1-4688-b7f5-ea07361b26a8`:

| Byte | Nombre | Valor / Rango | Descripción |
|---|---|---|---|
| 0 | `Header` | `0xAA` (170) | Byte de sincronización de inicio |
| 1 | `Pan Dir` | `0` (Izq) o `1` (Der) | Sentido de giro horizontal |
| 2 | `Pan Speed` | `0` a `255` | Magnitud de velocidad calculada por el PID |
| 3 | `Tilt Dir` | `0` (Arr) o `1` (Aba) | Sentido vertical (opcional) |
| 4 | `Tilt Speed` | `0` a `255` | Magnitud vertical (opcional) |
| 5 | `Checksum` | XOR de Bytes 0-4 | Validación de integridad para evitar comandos corruptos |

---

## 🛡️ Características de Seguridad y Estabilidad
- **Failsafe Watchdog**: Si el ESP32 deja de recibir paquetes BLE durante más de 600 ms (ej. llamada entrante en el teléfono o corte de señal), desacelera y frena el motor automáticamente para evitar giros continuos fuera de control.
- **Zona Muerta (Deadband)**: Si el balón se encuentra dentro del $\pm 4\%$ del centro de la pantalla, el motor permanece en reposo, evitando micro-vibraciones y asegurando tomas de video estables.
- **Predicción con Filtro de Kalman**: Si un defensa o árbitro tapa el balón por unos instantes (oclusión temporal de hasta 0.5s), el algoritmo predice la trayectoria continua en lugar de perder el encuadre.
