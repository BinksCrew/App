# Dockerfile para desplegar Flutter app en Render
FROM cirrusci/flutter:latest AS build

# Establecer directorio de trabajo
WORKDIR /app

# Copiar el código fuente de la app Flutter
COPY . .

# Diagnosticar Flutter
RUN flutter doctor

# Instalar dependencias de Flutter
RUN flutter pub get || (flutter pub cache repair && flutter pub get)

# Build para web
RUN flutter build web

# Etapa de producción con Nginx
FROM nginx:alpine

# Copiar los archivos de build a Nginx
COPY --from=build /app/build/web /usr/share/nginx/html

# Copiar configuración de Nginx (opcional, para SPA)
COPY nginx.conf /etc/nginx/nginx.conf

# Exponer el puerto 80
EXPOSE 80

# Comando por defecto
CMD ["nginx", "-g", "daemon off;"]