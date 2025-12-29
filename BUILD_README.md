# Guía de Construcción y Distribución de APK

## Actualización de Versiones

### Método Automático (Recomendado)

Usa el script `bump_version.sh` para actualizar automáticamente la versión:

```bash
# Para actualizaciones menores (bug fixes)
./bump_version.sh patch

# Para nuevas funcionalidades
./bump_version.sh minor

# Para cambios importantes
./bump_version.sh major
```

### Método Manual

Si prefieres actualizar manualmente:

1. **Actualizar pubspec.yaml:**
   ```yaml
   version: 0.1.6  # Incrementa según corresponda
   ```

2. **Actualizar android/app/build.gradle:**
   ```gradle
   versionCode 6    # Incrementa en 1 cada vez
   versionName "0.1.6"  # Debe coincidir con pubspec.yaml
   ```

## Construcción del APK

### APK de Desarrollo
```bash
flutter build apk --debug
```

### APK de Producción
```bash
flutter build apk --release
```

El APK se generará en `build/app/outputs/flutter-apk/app-release.apk`

## Solución de Problemas de Instalación

### Error: "Ya existe una aplicación con el mismo nombre de paquete"

Este error ocurre cuando el `versionCode` no se incrementa entre builds. Asegúrate de:

1. **Incrementar versionCode** en `android/app/build.gradle` antes de cada build
2. **Usar el script** `bump_version.sh` para automatizar esto
3. **Verificar** que el `applicationId` sea único: `com.binkscrew.app`

### Error: "La aplicación no se puede instalar"

Posibles causas:
- El APK está corrupto → Reconstruye el APK
- Firma incorrecta → Verifica la configuración de firma en `build.gradle`
- Versión anterior → Asegúrate de incrementar `versionCode`

## Configuración de Firma para Producción

Para distribución real, configura la firma en `android/app/build.gradle`:

```gradle
android {
    signingConfigs {
        release {
            storeFile file('path/to/keystore.jks')
            storePassword 'store_password'
            keyAlias 'key_alias'
            keyPassword 'key_password'
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            // ... otras configuraciones
        }
    }
}
```

## Distribución

### Play Store
1. Firma el APK con la configuración de producción
2. Sube el APK a Google Play Console
3. El `versionCode` debe ser mayor que la versión anterior

### Distribución Directa
1. Comparte el APK generado
2. Los usuarios pueden instalarlo directamente
3. Asegúrate de que permitan "Fuentes desconocidas" en Android

## Versionado Recomendado

- **Major (X.0.0)**: Cambios incompatibles, nuevas funcionalidades importantes
- **Minor (0.X.0)**: Nuevas funcionalidades compatibles
- **Patch (0.0.X)**: Corrección de bugs, mejoras menores

## Comandos Útiles

```bash
# Ver información del APK
flutter build apk --analyze-size

# Limpiar build cache
flutter clean && flutter pub get

# Ver dispositivos conectados
flutter devices

# Instalar en dispositivo
flutter install
```