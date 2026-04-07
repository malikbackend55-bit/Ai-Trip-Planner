# Stage 1: Build the Flutter Web App
FROM instrumentisto/flutter:3.27 AS build

WORKDIR /app

# Copy the dependencies file
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the source code
COPY . .

# Build for Web - injecting the API_URL build argument
ARG API_URL
RUN flutter build web --release --dart-define=API_URL=${API_URL}

# Stage 2: Serve the app using Nginx
FROM nginx:alpine

# Copy the build artifacts from the build stage
COPY --from=build /app/build/web /usr/share/nginx/html

COPY docker/nginx/default.conf.template /etc/nginx/templates/default.conf.template

ENV API_UPSTREAM=http://backend:8080

EXPOSE 80

CMD ["/bin/sh", "-c", "envsubst '$API_UPSTREAM' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
