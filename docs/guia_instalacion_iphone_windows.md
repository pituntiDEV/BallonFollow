# Guía: Cómo Instalar y Probar la App Nativa en tu iPhone desde Windows

Esta guía te permite compilar la aplicación nativa para iPhone (con acceso a Bluetooth BLE y Cámara completa) **sin tener una Mac** y **sin pagar los $99/año de Apple Developer**.

---

## 📋 Requisitos Previos

1. Tu iPhone con cable USB (Lightning o USB-C).
2. Tu cuenta personal gratuita de Apple ID (la misma que usas en tu iPhone).
3. Una cuenta gratuita de [GitHub](https://github.com).
4. El programa gratuito **Sideloadly** instalado en tu PC Windows.

---

## Paso 1: Compilar el `.ipa` en la Nube con GitHub Actions

El repositorio ya contiene el archivo de compilación automatizada [`.github/workflows/build_ios.yml`](file:///C:/Users/pi121/OneDrive/Escritorio/BallonFollow/.github/workflows/build_ios.yml).

1. Abre tu terminal en la carpeta del proyecto y sube el código a tu GitHub:
   ```bash
   git init
   git add .
   git commit -m "Inicializar BallonFollow con soporte iOS"
   git branch -M main
   git remote add origin https://github.com/TU_USUARIO/BallonFollow.git
   git push -u origin main
   ```
2. Entra a tu repositorio en GitHub desde el navegador y haz clic en la pestaña **Actions**.
3. Verás la tarea **"Compilar App Nativa iOS"** ejecutándose automáticamente en una máquina virtual macOS de GitHub.
4. En unos 5 a 8 minutos terminará con un check verde ✅.
5. Haz clic en la ejecución completada y al final, en la sección **Artifacts**, descarga el archivo:
   👉 **`BallonFollow-iPhone-IPA.zip`**
6. Descomprime el archivo en tu PC; obtendrás **`BallonFollow.ipa`**.

---

## Paso 2: Instalar Sideloadly en Windows

1. Descarga e instala **Sideloadly** (oficial y seguro) para Windows:
   - Sitio oficial: [https://sideloadly.io](https://sideloadly.io)
2. Abre Sideloadly en tu computadora.
3. Conecta tu iPhone a la PC con el cable USB.
4. En la pantalla del iPhone aparecerá el mensaje: *"¿Confiar en esta computadora?"*; presiona **Confiar** e introduce tu código de desbloqueo.

---

## Paso 3: Cargar la App al iPhone

1. En Sideloadly:
   - En el campo **"iDevice"**, selecciona tu iPhone detectado por USB.
   - En el campo **"Apple ID"**, introduce tu correo de Apple ID personal.
   - Arrastra el archivo **`BallonFollow.ipa`** al recuadro grande de Sideloadly.
2. Haz clic en el botón **Start**.
3. Sideloadly te pedirá la contraseña de tu Apple ID para solicitar un certificado de desarrollo gratuito de 7 días directamente a los servidores de Apple.
4. El proceso tardará unos 60 segundos hasta decir **"Done"**.
5. ¡Verás el icono de **BallonFollow** en la pantalla de inicio de tu iPhone!

---

## Paso 4: Autorizar la App en el iPhone (Primer Inicio)

Por seguridad de Apple, antes de abrir una app instalada manualmente:

1. Ve a **Ajustes** > **General** > **VPN y gestión de dispositivos** (o *Gestión de perfiles*).
2. Toca sobre tu Apple ID en la lista.
3. Presiona **"Confiar en [Tu Correo]"** y confirma.
4. *(Solo si tienes iOS 16 o superior)*:
   - Ve a **Ajustes** > **Privacidad y seguridad** > Desliza hasta el fondo y activa **Modo desarrollador**.
   - El iPhone se reiniciará; al encender confirma "Activar".

---

## Paso 5: ¡Listo para la Cancha!

Abre **BallonFollow** en tu iPhone:
- Te solicitará permisos de **Cámara** y **Bluetooth**.
- Enciende tu ESP32; la app lo detectará por BLE sin necesidad de configuración Wi-Fi.
- Puedes salir a la cancha y probar el seguimiento en vivo.
