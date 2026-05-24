FROM ghcr.io/cirruslabs/flutter:stable AS builder
USER flutter
WORKDIR /home/flutter/app
COPY --chown=flutter:flutter pubspec.* ./
RUN flutter pub get
COPY --chown=flutter:flutter . .
ARG API_URL=http://localhost:3000
ARG WS_URL=ws://localhost:3000/ws
RUN flutter build web --release \
    --dart-define=API_URL=${API_URL} \
    --dart-define=WS_URL=${WS_URL}

FROM nginx:alpine
COPY --from=builder /home/flutter/app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
