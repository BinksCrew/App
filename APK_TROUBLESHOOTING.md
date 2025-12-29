# Solución de Problemas - Instalación de APK

## Problema: "Ya existe una aplicación con el mismo nombre de paquete"

### Síntomas
- Al intentar instalar un nuevo APK, Android muestra: "Ya existe una aplicación con el mismo nombre de paquete"
- No se puede actualizar la app sin desinstalar primero

### Causas
1. **versionCode no incrementado**: El `versionCode` en `android/app/build.gradle` es el mismo que la versión anterior
2. **Versión no actualizada**: La versión en `pubspec.yaml` no cambió

### Soluciones

#### Opción 1: Usar el script automático (Recomendado)
```bash
./bump_version.sh patch
flutter build apk --release
```

#### Opción 2: Actualización manual
1. Abre `pubspec.yaml` y incrementa la versión:
   ```yaml
   version: 0.1.6  # Era 0.1.5
   ```

2. Abre `android/app/build.gradle` y actualiza:
   ```gradle
   versionCode 6  // Era 5
   versionName "0.1.6"
   ```

3. Reconstruye el APK:
   ```bash
   flutter build apk --release
   ```

## Problema: "La aplicación no se puede instalar"

### Causas posibles
1. **APK corrupto**: El archivo APK se dañó durante la construcción
2. **Firma incorrecta**: Problemas con la configuración de firma
3. **Arquitectura incompatible**: APK para arquitectura incorrecta
4. **Espacio insuficiente**: No hay espacio en el dispositivo

### Soluciones
1. **Reconstruir el APK**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

2. **Verificar firma**: Asegúrate de que `signingConfig` esté configurado correctamente en `build.gradle`

3. **Probar con diferentes arquitecturas**:
   ```bash
   flutter build apk --release --split-per-abi
   ```

## Problema: "Instalación bloqueada por Play Protect"

### Solución
1. El APK no está firmado para producción
2. Temporalmente desactiva Play Protect en el dispositivo para testing
3. Para distribución real, firma el APK correctamente

## Verificación de versión actual

Para verificar qué versión está instalada actualmente:

```bash
# En el dispositivo Android
adb shell dumpsys package com.binkscrew.app | grep version
```

## Comandos útiles para debugging

```bash
# Ver información detallada del APK
flutter build apk --analyze-size

# Ver logs de instalación
adb logcat | grep "PackageManager"

# Instalar APK forzosamente (borra datos)
adb install -r -d build/app/outputs/flutter-apk/app-release.apk

# Desinstalar app
adb uninstall com.binkscrew.app
```

## Prevención

1. **Siempre incrementa versionCode** antes de construir un nuevo APK
2. **Usa el script bump_version.sh** para automatizar el proceso
3. **Prueba la instalación** en un dispositivo real antes de distribuir
4. **Mantén backups** de versiones anteriores si es necesario

## Configuración de firma para producción

Para evitar problemas de Play Protect, configura la firma correcta:

```gradle
android {
    signingConfigs {
        release {
            storeFile file('path/to/keystore.jks')
            storePassword System.getenv('STORE_PASSWORD')
            keyAlias System.getenv('KEY_ALIAS')
            keyPassword System.getenv('KEY_PASSWORD')
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```