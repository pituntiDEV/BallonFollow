"""
Simulación completa del algoritmo de seguimiento de balón:
1. Detección de Polígono de Cancha (Point-in-Polygon)
2. Filtro de Kalman (Predicción y Suavizado de Trayectoria)
3. Controlador PID (Cálculo de corrección de ángulo/velocidad)
4. Empaquetado Binario BLE (Verificación de protocolo hacia ESP32)
"""

import math
from typing import List, Tuple, Optional


class PointInPolygon:
    """Valida si una coordenada (x, y) normalizada [0.0 - 1.0] está dentro de la cancha."""
    
    @staticmethod
    def is_inside(point: Tuple[float, float], polygon: List[Tuple[float, float]]) -> bool:
        x, y = point
        n = len(polygon)
        inside = False
        p1x, p1y = polygon[0]
        for i in range(1, n + 1):
            p2x, p2y = polygon[i % n]
            if y > min(p1y, p2y):
                if y <= max(p1y, p2y):
                    if x <= max(p1x, p2x):
                        if p1y != p2y:
                            xinters = (y - p1y) * (p2x - p1x) / (p2y - p1y) + p1x
                        if p1x == p2x or x <= xinters:
                            inside = not inside
            p1x, p1y = p2x, p2y
        return inside


class KalmanFilter2D:
    """Filtro de Kalman para posición [x, y] y velocidad [vx, vy]."""
    
    def __init__(self, dt: float = 0.033, process_noise: float = 0.01, measurement_noise: float = 0.05):
        self.dt = dt
        # Estado: [x, y, vx, vy]
        self.x = 0.5
        self.y = 0.5
        self.vx = 0.0
        self.vy = 0.0
        
        # Covarianza del error
        self.p_pos = 1.0
        self.p_vel = 1.0
        
        self.q_pos = process_noise
        self.q_vel = process_noise * 2.0
        self.r = measurement_noise
        self.initialized = False

    def predict(self) -> Tuple[float, float]:
        """Paso de predicción cuando no hay medición o antes de recibirla."""
        self.x += self.vx * self.dt
        self.y += self.vy * self.dt
        self.p_pos += self.q_pos
        self.p_vel += self.q_vel
        return self.x, self.y

    def update(self, meas_x: float, meas_y: float) -> Tuple[float, float]:
        """Paso de corrección cuando se detecta el balón."""
        if not self.initialized:
            self.x = meas_x
            self.y = meas_y
            self.initialized = True
            return self.x, self.y

        # Ganancia de Kalman para posición
        k_pos = self.p_pos / (self.p_pos + self.r)
        error_x = meas_x - self.x
        error_y = meas_y - self.y
        
        # Actualización de velocidad estimada
        k_vel = self.p_vel / (self.p_vel + self.r * 2.0)
        self.vx += k_vel * (error_x / self.dt - self.vx)
        self.vy += k_vel * (error_y / self.dt - self.vy)
        
        # Actualización de posición
        self.x += k_pos * error_x
        self.y += k_pos * error_y
        
        # Actualización de covarianza
        self.p_pos = (1.0 - k_pos) * self.p_pos
        self.p_vel = (1.0 - k_vel) * self.p_vel
        
        return self.x, self.y


class PIDController:
    """Controlador PID con Zona Muerta (Deadband) para evitar microvibraciones."""
    
    def __init__(self, kp: float = 1.8, ki: float = 0.05, kd: float = 0.25, deadband: float = 0.04):
        self.kp = kp
        self.ki = ki
        self.kd = kd
        self.deadband = deadband
        self.integral = 0.0
        self.prev_error = 0.0

    def compute(self, target: float, current: float, dt: float) -> float:
        error = target - current  # Si el balón está a la derecha (ej. 0.8), error = 0.8 - 0.5 = +0.3
        
        # Zona muerta: si el balón ya está prácticamente centrado, no mover el motor
        if abs(error) < self.deadband:
            self.integral = 0.0
            self.prev_error = 0.0
            return 0.0
            
        self.integral += error * dt
        # Anti-windup
        self.integral = max(-0.5, min(0.5, self.integral))
        
        derivative = (error - self.prev_error) / dt if dt > 0 else 0.0
        self.prev_error = error
        
        output = (self.kp * error) + (self.ki * self.integral) + (self.kd * derivative)
        return max(-1.0, min(1.0, output))


class BLEPacketEncoder:
    """Protocolo binario hacia el ESP32: [0xAA, pan_dir, pan_speed, tilt_dir, tilt_speed, checksum]."""
    
    @staticmethod
    def encode(pan_cmd: float, tilt_cmd: float = 0.0) -> bytes:
        # Dirección: 1 = Derecha/Abajo, 0 = Izquierda/Arriba
        pan_dir = 1 if pan_cmd >= 0 else 0
        pan_speed = int(abs(pan_cmd) * 255.0)
        pan_speed = max(0, min(255, pan_speed))
        
        tilt_dir = 1 if tilt_cmd >= 0 else 0
        tilt_speed = int(abs(tilt_cmd) * 255.0)
        tilt_speed = max(0, min(255, tilt_speed))
        
        header = 0xAA
        checksum = (header ^ pan_dir ^ pan_speed ^ tilt_dir ^ tilt_speed) & 0xFF
        
        return bytes([header, pan_dir, pan_speed, tilt_dir, tilt_speed, checksum])

    @staticmethod
    def decode(packet: bytes) -> dict:
        """Emula la decodificación del firmware ESP32."""
        if len(packet) != 6:
            raise ValueError("Longitud de paquete inválida")
        header, pan_dir, pan_speed, tilt_dir, tilt_speed, checksum = packet
        if header != 0xAA:
            raise ValueError("Header no coincide (esperado 0xAA)")
        expected_cs = (header ^ pan_dir ^ pan_speed ^ tilt_dir ^ tilt_speed) & 0xFF
        if checksum != expected_cs:
            raise ValueError(f"Checksum erróneo: {checksum} != {expected_cs}")
            
        pan_val = (pan_speed / 255.0) * (1.0 if pan_dir == 1 else -1.0)
        tilt_val = (tilt_speed / 255.0) * (1.0 if tilt_dir == 1 else -1.0)
        return {"pan": pan_val, "tilt": tilt_val, "valid": True}


def run_full_simulation():
    print("=" * 60)
    print("EJECUTANDO SIMULACIÓN INTEGRADA DEL RASTREADOR DE BALÓN")
    print("=" * 60)
    
    # 1. Definir polígono de cancha (4 esquinas en perspectiva)
    court_polygon = [
        (0.10, 0.20),  # Esquina superior izquierda
        (0.90, 0.20),  # Esquina superior derecha
        (0.95, 0.95),  # Esquina inferior derecha
        (0.05, 0.95),  # Esquina inferior izquierda
    ]
    
    # Prueba Point-in-Polygon
    p_inside = (0.50, 0.50)
    p_outside = (0.02, 0.05)  # En gradas o fuera de banda
    assert PointInPolygon.is_inside(p_inside, court_polygon) is True, "Fallo: Punto dentro de cancha no reconocido"
    assert PointInPolygon.is_inside(p_outside, court_polygon) is False, "Fallo: Punto fuera de cancha no reconocido"
    print("[TEST 1/4] Point-in-Polygon (Filtro Cancha): CORRECTO")
    
    # 2. Prueba Protocolo BLE
    sample_packet = BLEPacketEncoder.encode(pan_cmd=0.75, tilt_cmd=-0.25)
    decoded = BLEPacketEncoder.decode(sample_packet)
    assert abs(decoded["pan"] - 0.75) < 0.01, "Error en decodificación Pan"
    assert abs(decoded["tilt"] - (-0.25)) < 0.01, "Error en decodificación Tilt"
    print(f"[TEST 2/4] BLE Packet Encode/Decode ({sample_packet.hex()}): CORRECTO")
    
    # 3. Simulación Dinámica de Seguimiento
    kalman = KalmanFilter2D(dt=0.033)
    pid = PIDController(kp=2.0, ki=0.02, kd=0.15, deadband=0.03)
    
    # Supongamos que la cámara está apuntando al centro (0.5), y un pase lleva el balón de 0.5 a 0.85
    print("\n[TEST 3/4] Simulando movimiento de balón y convergencia de cámara:")
    ball_real_x = 0.50
    camera_pan_angle = 0.0  # Ángulo del soporte motorizado
    
    for frame in range(1, 31):
        # El balón se mueve hacia la derecha en los primeros 10 frames, luego se detiene
        if frame <= 10:
            ball_real_x += 0.03
            
        # Posición aparente en la pantalla del móvil respecto al ángulo actual de la cámara
        # screen_x = 0.5 + (ball_real_x - 0.5) - camera_pan_angle
        apparent_x = max(0.0, min(1.0, ball_real_x - camera_pan_angle))
        
        # Simular oclusión en frames 12 y 13 (ej. jugador tapa el balón)
        ball_detected = not (12 <= frame <= 13)
        
        if ball_detected:
            # Medición con leve ruido
            meas_x = apparent_x + 0.005 * (1 if frame % 2 == 0 else -1)
            est_x, _ = kalman.update(meas_x, 0.5)
        else:
            # Predicción pura de Kalman durante oclusión
            est_x, _ = kalman.predict()
            
        # Error respecto al centro de pantalla (0.5)
        dt = 0.033
        motor_cmd = pid.compute(target=est_x, current=0.5, dt=dt)
        
        # El motor rota la cámara proporcionalmente al comando
        motor_speed = motor_cmd * 0.025  # Velocidad angular efectiva
        camera_pan_angle += motor_speed
        
        ble_packet = BLEPacketEncoder.encode(pan_cmd=motor_cmd)
        
        if frame in [1, 5, 10, 12, 14, 20, 30]:
            state_str = "DETECTADO" if ball_detected else "OCLUSIÓN (Kalman)"
            print(f"Frame {frame:02d} | Balón real: {ball_real_x:.2f} | En pantalla: {apparent_x:.2f} | "
                  f"Estimado: {est_x:.2f} | MotorCmd: {motor_cmd:+.2f} | Estado: {state_str}")
                  
    # Al final, la posición aparente en pantalla debe converger de regreso al centro (~0.5)
    final_apparent = ball_real_x - camera_pan_angle
    print(f"\nPosición final aparente en pantalla: {final_apparent:.3f} (Centro ideal: 0.500)")
    assert abs(final_apparent - 0.50) < 0.08, "Fallo: El seguidor no centró el balón correctamente"
    print("[TEST 4/4] Bucle de Control y Filtro de Kalman: CONVERGENCIA EXITOSA")
    
    print("\n" + "=" * 60)
    print("TODAS LAS PRUEBAS DE SIMULACIÓN PASARON SATISFACTORIAMENTE")
    print("=" * 60)

if __name__ == "__main__":
    run_full_simulation()
