#!/bin/bash
# Script para actualizar la versión de la aplicación Flutter
# Uso: ./bump_version.sh [major|minor|patch]

set -e

# Función para mostrar uso
show_usage() {
    echo "Uso: $0 [major|minor|patch]"
    echo "Ejemplos:"
    echo "  $0 patch  # 1.0.0 -> 1.0.1"
    echo "  $0 minor  # 1.0.0 -> 1.1.0"
    echo "  $0 major  # 1.0.0 -> 2.0.0"
    exit 1
}

# Verificar argumentos
if [ $# -ne 1 ]; then
    show_usage
fi

TYPE=$1

# Validar tipo de versión
case $TYPE in
    major|minor|patch) ;;
    *) echo "Error: Tipo de versión inválido '$TYPE'"; show_usage ;;
esac

# Leer versión actual del pubspec.yaml
CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
echo "Versión actual: $CURRENT_VERSION"

# Parsear versión
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Incrementar versión según el tipo
case $TYPE in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "Nueva versión: $NEW_VERSION"

# Calcular versionCode (usando el formato: MAJOR * 10000 + MINOR * 100 + PATCH)
VERSION_CODE=$((MAJOR * 10000 + MINOR * 100 + PATCH))
echo "VersionCode: $VERSION_CODE"

# Actualizar pubspec.yaml
sed -i "s/^version: .*/version: $NEW_VERSION/" pubspec.yaml

# Actualizar build.gradle
sed -i "s/versionCode [0-9]*/versionCode $VERSION_CODE/" android/app/build.gradle
sed -i "s/versionName \"[^\"]*\"/versionName \"$NEW_VERSION\"/" android/app/build.gradle

echo "✅ Versión actualizada exitosamente:"
echo "   pubspec.yaml: $NEW_VERSION"
echo "   build.gradle: versionCode=$VERSION_CODE, versionName=$NEW_VERSION"
echo ""
echo "📝 Recuerda hacer commit de estos cambios:"
echo "   git add pubspec.yaml android/app/build.gradle"
echo "   git commit -m \"Bump version to $NEW_VERSION\""
echo ""
echo "🚀 Ahora puedes generar el APK:"
echo "   flutter build apk --release"