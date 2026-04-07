# Stage 1: Build the Flutter Web App
# Match the local dashboard toolchain so `flutter pub get` satisfies `sdk: ^3.11.0`.
FROM instrumentisto/flutter:3.41.2 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Build for Web - injecting the API_URL build argument.
# Disable the Flutter service worker to avoid stale-cache white screens after redeploys.
ARG API_URL
RUN flutter build web --release --pwa-strategy=none --dart-define=API_URL=${API_URL}

# Stage 2: Serve the app using Nginx
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

COPY docker/nginx/default.conf.template /etc/nginx/templates/default.conf.template

ENV API_UPSTREAM=http://backend:8080

EXPOSE 80

CMD ["/bin/sh", "-c", "envsubst '$API_UPSTREAM' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
