# Verifica - Serie B Bolivia

**App para verificar billetes inhabilitados de la "Serie B" inhabilitados (Bs 10, 20 y 50)**

![Portada o Cover](assets/img/bg.png)  

## ¿Qué hace esta app?

Verifica al instante si un billete de **Bs 10, 20 o 50** (Serie B) está inhabilitado según las listas oficiales publicadas por el Ministerio de Economía y Finanzas Públicas de Bolivia.

- Escanea el número de serie con la cámara del celular  
- Detecta automáticamente si está en los rangos inhabilitados  
- Permite corregir manualmente si la lectura automática falla  
- 100% offline – no necesita internet  

¡Ideal para mercados, tiendas, transporte y uso diario en Bolivia!

## Capturas de pantalla

| Pantalla principal                  | Escaneo Bs 10                       | Resultado inhabilitado              |
|-------------------------------------|-------------------------------------|-------------------------------------|
| ![Home](assets/img/screen_1.png)       | ![Scanner](assets/img/screen_2.png) | ![Invalid](assets/img/screen_4.png) |

## Requisitos

- Android 6.0 o superior  
- Cámara funcional  
- Permiso de cámara (la app lo pide al iniciar)

## Cómo instalar (para usuarios)

1. **Descarga el APK** que mejor se adapte a tu celular Android:

   - **Recomendado para la mayoría** (celulares modernos desde 2018 en adelante – Samsung, Xiaomi, Motorola, etc.):  
     [⬇️ app-arm64-v8a-release.apk (125 MB)](https://github.com/alvinoDev/verificador_billetes_bo/releases/download/v1.0.0/app-arm64-v8a-release.apk)

   - **Solo si tienes un celular muy antiguo** (modelos de 2015-2018 o low-end que no instala el de arriba):  
     [⬇️ app-armeabi-v7a-release.apk (97 MB)](https://github.com/alvinoDev/verificador_billetes_bo/releases/download/v1.0.0/app-armeabi-v7a-release.apk)

   *(No necesitas descargar el de x86_64, es para emuladores y casos muy raros)*

2. En tu celular Android:
   - Ve a **Ajustes > Seguridad** (o Busca "Fuentes desconocidas")
   - Activa "Instalar apps de fuentes desconocidas" para el navegador o administrador de archivos
   - Abre el archivo APK descargado y toca **Instalar**

3. ¡Listo! Abre la app y empieza a verificar billetes.

**Nota importante**: Esta app usa datos oficiales publicados por el gobierno boliviano (rangos de Serie B inhabilitados). Siempre confirma manualmente en casos dudosos.

## Cómo generar los APKs tú mismo (para desarrolladores)

```bash
# Clona el repo
git clone https://github.com/alvinoDev/verificador-billetes-bo.git
cd verificador-billetes-bo

# Instala dependencias
flutter pub get

# Genera los APKs release (split por ABI)
flutter build apk --release --split-per-abi