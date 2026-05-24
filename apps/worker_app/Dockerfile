FROM ghcr.io/cirruslabs/flutter:stable AS builder
USER user
WORKDIR /home/user/app
COPY --chown=user:user pubspec.* ./
RUN flutter pub get
COPY --chown=user:user . .
ARG API_URL=http://localhost:3000
ARG WS_URL=ws://localhost:3000/ws
RUN flutter build web --release \
    --dart-define=API_URL=${API_URL} \
    --dart-define=WS_URL=${WS_URL}

FROM nginx:alpine
COPY --from=builder /home/user/app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
