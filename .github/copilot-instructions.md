# Binks Crew - Plataforma de Trivia de Anime

## 📖 Sobre el Proyecto

**Binks Crew** es una plataforma interactiva diseñada para que los fanáticos del anime pongan a prueba sus conocimientos y obtengan recompensas físicas. Es una aplicación móvil gratuita (Android e iOS) que gamifica el conocimiento sobre anime.

### 🚀 Funcionamiento del Sistema
El núcleo de la experiencia se basa en cuatro pilares:
1.  **Trivia y Conocimiento**: Los usuarios responden preguntas sobre diversos animes.
2.  **Sistema de Puntos**: Cada respuesta correcta acumula puntos en el perfil del usuario.
3.  **Recompensas Reales**: Los puntos funcionan como "tickets" que se canjean por premios físicos tangibles (figuras coleccionables, peluches, llaveros premium), no solo bienes digitales.
4.  **Comunidad**: Fomenta una comunidad ("tripulación") activa en redes sociales.

### 🛠️ Contexto Técnico
El proyecto está desarrollado en **Flutter** y **Dart**, priorizando una interfaz minimalista, fluida y atractiva ("Anime Tech"). El backend gestiona usuarios, preguntas y puntuaciones mediante una API REST.

---

# Guía de Estilo y Diseño UI/UX - Anime Quiz App

Este documento define los estándares de diseño y estilo para la aplicación, basados en la pantalla de Login actual. Todas las nuevas pantallas y componentes deben seguir estas directrices para mantener una consistencia visual "Anime Tech/Cyberpunk" pero limpia y empresarial.

## 1. Estructura Visual General (Glassmorphism & Background)

Todas las pantallas principales (Login, Registro, Bienvenida, etc.) deben seguir esta estructura de capas:

1.  **Fondo**: Imagen de alta calidad (`assets/hero.webp` o similar) cubriendo toda la pantalla (`BoxFit.cover`).
2.  **Filtro de Desenfoque**: `BackdropFilter` con `ImageFilter.blur(sigmaX: 10, sigmaY: 10)`.
3.  **Overlay Oscuro**: Capa de color `Colors.black.withOpacity(0.6)` para garantizar legibilidad.

```dart
Stack(
  children: [
    // 1. Fondo
    Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/hero.webp'),
          fit: BoxFit.cover,
        ),
      ),
    ),
    // 2. Blur y 3. Overlay
    BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withOpacity(0.6),
      ),
    ),
    // Contenido...
  ],
)
```

## 2. Contenedores y Tarjetas (Cards)

Los formularios y bloques de contenido principal deben usar contenedores blancos semitransparentes con bordes redondeados suaves y sombras difusas.

*   **Color de Fondo**: `Colors.white.withOpacity(0.9)` (Casi opaco, pero permite ver sutilmente el fondo).
*   **Bordes**: `BorderRadius.circular(20)`.
*   **Sombra**: `BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: Offset(0, 10))`.
*   **Padding Interno**: `32.0` para dar aire al contenido.

```dart
Container(
  padding: const EdgeInsets.all(32),
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.9),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  ),
  child: ...
)
```

## 3. Tipografía

*   **Títulos (Headlines)**:
    *   Estilo: `Theme.of(context).textTheme.headlineMedium`
    *   Peso: `FontWeight.bold`
    *   Color: `Color(0xFF1A1A1A)` (Negro suave, no puro).
*   **Subtítulos / Cuerpo**:
    *   Color: `Colors.grey[600]`.
*   **Texto sobre fondo oscuro**:
    *   Color: `Colors.white` con `FontWeight.bold` para enlaces o acciones.

## 4. Elementos de UI

### Logos e Iconos Destacados
Deben estar encapsulados en contenedores circulares con borde sutil.
*   **Fondo**: `Colors.white.withOpacity(0.1)`
*   **Borde**: `Border.all(color: Colors.white24)`
*   **Forma**: `BoxShape.circle`

### Botones (ElevatedButton)
*   Deben ocupar el ancho disponible cuando son acciones principales (`SizedBox(width: double.infinity, ...)`).
*   Texto en mayúsculas (`INGRESAR`) para mayor impacto.
*   Indicadores de carga (`CircularProgressIndicator`) deben ser blancos y pequeños dentro del botón.

### Campos de Texto (TextField)
*   Usar `InputDecoration` con `prefixIcon`.
*   Iconos de línea (`Icons.email_outlined`, `Icons.lock_outline`).

## 5. Paleta de Colores (Referencia)
*   **Primario**: `Color(0xFF6200EE)` (Deep Purple)
*   **Fondo Oscuro**: `Colors.black` con opacidad.
*   **Texto Principal**: `Color(0xFF1A1A1A)`
*   **Texto Secundario**: `Colors.grey[600]`
