# Dockerfile para desplegar Flutter app en Vercel
FROM cirrusci/flutter:latest

# Establecer directorio de trabajo
WORKDIR /app

# Copiar el código fuente de la app Flutter (ahora el contexto es app/)
COPY . .

# Instalar dependencias de Flutter
RUN flutter pub get

# Build para web
RUN flutter build web

# Mover los archivos de build a la raíz para que Vercel los sirva
RUN mv build/web /app/build

# Exponer el puerto (Vercel lo maneja)
EXPOSE 3000

# Comando por defecto (Vercel usará los archivos estáticos)
CMD ["echo", "Build completado"]