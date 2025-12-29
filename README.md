# App - Binkscrew

## Requisitos Previos

- Flutter SDK instalado (versión 3.10.0 o superior)
- Dart SDK incluido con Flutter
- Un dispositivo o emulador Android/iOS configurado
- Editor de código como VS Code o Android Studio

## Instalación

1. Clona el repositorio:
   ```bash
   git clone https://github.com/BinksCrew/App.git
   cd app
   ```

2. Instala las dependencias:
   ```bash
   flutter pub get
   ```

3. Verifica la configuración:
   ```bash
   flutter doctor
   ```

**Nota**: Para releases rápidos, usa el script `release.ps1` incluido en el proyecto (solo Windows).

## Comandos de Desarrollo

### Análisis de Código
- Analizar el código en busca de errores y advertencias:
  ```bash
  flutter analyze
  ```

### Ejecutar la Aplicación
- Ejecutar en modo debug en un dispositivo conectado:
  ```bash
  flutter run
  ```

### Generar Íconos de la Aplicación
- Generar íconos para Android e iOS usando flutter_launcher_icons:
  ```bash
  flutter pub run flutter_launcher_icons
  ```

### Verificar Dependencias Desactualizadas
- Verificar si hay paquetes desactualizados:
  ```bash
  flutter pub outdated
  ```

## Construcción y Despliegue

### Construir APK para Android
- Construir APK de release universal:
  ```bash
  flutter build apk --release
  ```

- Construir APKs separados por arquitectura (recomendado para reducir tamaño):
  ```bash
  flutter build apk --release --split-per-abi
  ```

- **Comando único para release y copiar APK al root** (Windows PowerShell):
  ```powershell
  .\release.ps1
  ```
  Este script construye el APK de release y lo copia como `binkscrew.apk` en la raíz del proyecto.

### Versionado de la Aplicación

Para evitar conflictos de instalación al actualizar la app, es **crucial** incrementar el número de versión antes de cada build:

#### Método Automático (Recomendado)
```bash
# Para corrección de bugs
./bump_version.sh patch

# Para nuevas funcionalidades
./bump_version.sh minor

# Para cambios importantes
./bump_version.sh major
```

#### Método Manual
1. Actualiza `pubspec.yaml`:
   ```yaml
   version: 0.1.6  # Incrementa la versión
   ```

2. Actualiza `android/app/build.gradle`:
   ```gradle
   versionCode 6    // Incrementa en 1
   versionName "0.1.6"  // Debe coincidir con pubspec.yaml
   ```

**Importante**: Si no incrementas el `versionCode`, Android no permitirá instalar la nueva versión sobre la anterior.

### Construir para iOS (en macOS)
- Construir para iOS:
  ```bash
  flutter build ios --release
  ```

### Limpiar el Proyecto
- Limpiar archivos generados:
  ```bash
  flutter clean
  ```

## Estructura del Proyecto

- `lib/`: Código fuente de la aplicación
  - `main.dart`: Punto de entrada
  - `screens/`: Pantallas de la aplicación (welcome, login, register, home)
- `assets/`: Recursos como imágenes y videos
- `android/`: Configuración específica de Android
- `ios/`: Configuración específica de iOS

## Características

- Pantalla de bienvenida con video
- Sistema de login y registro
- Navegación fluida entre pantallas
- Optimizaciones de rendimiento (encogimiento de código, recursos)

## Contribución

1. Crea una rama para tu feature
2. Realiza tus cambios
3. Ejecuta `flutter analyze` para verificar el código
4. Envía un pull request

## Licencia

[Especifica la licencia si aplica]
