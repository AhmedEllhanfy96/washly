/// Central configuration — every magic number, URL, and business constant
/// lives here. Never hardcode these values elsewhere.
class AppConfig {
  AppConfig._();

  // ── API ───────────────────────────────────────────────────────────────────
  static const String defaultApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://150.230.53.189:3000',
  );
  static const Duration apiConnectTimeout = Duration(seconds: 10);
  static const Duration apiReceiveTimeout = Duration(seconds: 10);

  // ── WebSocket ─────────────────────────────────────────────────────────────
  static const Duration wsConnectTimeout = Duration(seconds: 5);
  static const Duration wsReconnectDelay = Duration(seconds: 3);

  // ── Polling intervals ─────────────────────────────────────────────────────
  static const Duration jobPollInterval = Duration(seconds: 30);

  // ── Service prices ────────────────────────────────────────────────────────
  static const int priceExteriorOnly = 195;
  static const int priceInteriorOnly = 220;
  static const int priceFullService = 250;
  static const String currency = 'EGP';

  // ── External URLs ─────────────────────────────────────────────────────────
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String googleMapsDirectionsUrl =
      'https://www.google.com/maps/dir/?api=1&destination=';
  static const String googleMapsSearchUrl =
      'https://www.google.com/maps/search/?api=1&query=';
  static const String whatsAppUrl = 'https://wa.me/';
  static const String userAgent = 'WashlyApp/1.0';

  // ── UI constants ──────────────────────────────────────────────────────────
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 200);
}
