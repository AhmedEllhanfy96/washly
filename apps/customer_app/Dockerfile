FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app
COPY pubspec.* ./
RUN flutter pub get
COPY . .
ARG API_URL=http://localhost:3000
ARG WS_URL=ws://localhost:3000/ws
RUN flutter build web --release --pwa-strategy=none \
    --dart-define=API_URL=${API_URL} \
    --dart-define=WS_URL=${WS_URL}

FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
