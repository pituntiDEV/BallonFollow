"""
Exportador de Modelo YOLO a formato TensorFlow Lite (.tflite)
Optimizado para ejecución en tiempo real en iOS (CoreML) y Android (NNAPI/GPU).
"""

import argparse
import sys
import os

def export_model(weights_path: str = "yolov8n.pt", imgsz: int = 640, int8: bool = False):
    try:
        from ultralytics import YOLO
    except ImportError:
        print("[ERROR] ultralytics no está instalado. Ejecuta: pip install ultralytics")
        sys.exit(1)
        
    print(f"[INFO] Cargando modelo: {weights_path}")
    model = YOLO(weights_path)
    
    print(f"[INFO] Exportando modelo a TFLite (imgsz={imgsz}, int8={int8})...")
    # Exportación con cuantización
    # int8=True requiere dataset de calibración, float16 (half) es ideal para GPU móvil
    output_path = model.export(
        format="tflite",
        imgsz=imgsz,
        half=not int8,  # FP16 para CoreML/GPU móvil
        int8=int8
    )
    
    print(f"[EXITO] Modelo exportado con éxito en: {output_path}")
    print("[NOTA] Copia el archivo .tflite resultante a: mobile_app/assets/models/ball_detector.tflite")
    return output_path

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Exporta YOLOv8/v11 a TFLite")
    parser.add_argument("--weights", type=str, default="yolov8n.pt", help="Ruta a los pesos .pt")
    parser.add_argument("--imgsz", type=int, default=640, help="Tamaño de entrada de la imagen")
    parser.add_argument("--int8", action="store_true", help="Habilitar cuantización INT8 completa")
    args = parser.parse_args()
    
    export_model(args.weights, args.imgsz, args.int8)
