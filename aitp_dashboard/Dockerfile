# Stage 1: Build the Flutter Web App
# Match the local dashboard toolchain so `flutter pub get` satisfies `sdk: ^3.11.0`.
FROM instrumentisto/flutter:3.41.2 AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Build for Web - injecting the API_URL build argument
ARG API_URL
RUN flutter build web --release --dart-define=API_URL=${API_URL}

# Stage 2: Serve the app using Nginx
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

RUN printf "server {\n\
    listen 80;\n\
    location / {\n\
        root /usr/share/nginx/html;\n\
        try_files \$uri \$uri/ /index.html;\n\
    }\n\
}\n" > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
