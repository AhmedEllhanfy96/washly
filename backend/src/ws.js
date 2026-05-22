const clients = new Set();

export function registerWsRoutes(app) {
  app.get('/ws', { websocket: true }, (socket, req) => {
    const token = req.query?.token;
    if (token) {
      try {
        app.jwt.verify(token);
      } catch {
        socket.close(1008, 'Unauthorized');
        return;
      }
    }
    clients.add(socket);
    socket.on('close', () => clients.delete(socket));
    socket.on('error', () => clients.delete(socket));
  });
}

export function broadcast(data) {
  const msg = JSON.stringify(data);
  for (const client of clients) {
    if (client.readyState === 1) client.send(msg);
  }
}
