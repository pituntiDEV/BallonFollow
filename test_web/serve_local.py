"""
Servidor Local de Pruebas para iPhone
Sirve la aplicación de prueba en la red Wi-Fi local para abrirla en Safari en tu iPhone.
"""

import http.server
import socketserver
import socket
import os
import sys

PORT = 8080
DIRECTORY = os.path.dirname(os.path.abspath(__file__))

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # No necesita ser alcanzable realmente
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def log_message(self, format, *args):
        # Silenciar logs innecesarios
        pass

def run():
    # Asegurar soporte de caracteres en consolas Windows
    if sys.platform == "win32":
        sys.stdout.reconfigure(encoding='utf-8')

    ip = get_local_ip()
    url = f"http://{ip}:{PORT}"
    
    print("\n" + "=" * 65)
    print("      [+] SERVIDOR LOCAL DE PRUEBA PARA IPHONE (SAFARI)")
    print("=" * 65)
    print(f"\n1. Asegurate de que tu iPhone este conectado a la MISMA RED WI-FI.")
    print(f"2. Abre Safari en tu iPhone y escribe la siguiente direccion:\n")
    print(f"   >>>   {url}   <<<\n")
    print("3. Funciones que podras probar inmediatamente en tu iPhone:")
    print("   - Calibracion interactiva arrastrando los 4 puntos de la cancha.")
    print("   - Simulacion en tiempo real del seguimiento del balon a 60 FPS.")
    print("   - Visualizacion del encuadre horizontal y controles de grabacion.")
    print("   - Activacion de camara trasera WebRTC.")
    print("\n[Presiona Ctrl+C para detener el servidor]")
    print("=" * 65 + "\n")

    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n[INFO] Servidor detenido por el usuario.")

if __name__ == "__main__":
    run()
