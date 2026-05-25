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
  static const Duration bookingPollInterval = Duration(seconds: 30);
  static const Duration teamPollInterval = Duration(seconds: 60);

  // ── Service prices ────────────────────────────────────────────────────────
  static const int priceExteriorOnly = 195;
  static const int priceInteriorOnly = 220;
  static const int priceFullService = 250;
  static const String currency = 'EGP';

  // ── Schedule defaults ─────────────────────────────────────────────────────
  static const int slotDurationHours = 2;
  static const int maxBookingsPerSlot = 3;
  static const String dayStart = '08:00';
  static const String dayEnd = '18:00';

  // ── Booking constraints ───────────────────────────────────────────────────
  static const int minBookingDaysAhead = 1;
  static const int maxBookingDaysAhead = 90;
  static const int dashboardPendingLimit = 10;
  static const int scheduleViewPastDays = 7;
  static const int scheduleViewFutureDays = 30;

  // ── Alert thresholds ─────────────────────────────────────────────────────
  static const int pendingAlertHours = 2; // pending booking turns red after this

  // ── Location ─────────────────────────────────────────────────────────────
  static const double defaultLat = 30.0444; // Cairo center
  static const double defaultLng = 31.2357;
  static const String searchCountryCode = 'eg';
  static const int nominatimResultLimit = 5;
  static const int locationSearchMinChars = 3;
  static const Duration gpsFetchTimeout = Duration(seconds: 15);
  static const Duration nominatimTimeout = Duration(seconds: 6);
  static const Duration searchDebounce = Duration(milliseconds: 600);

  // ── External URLs ─────────────────────────────────────────────────────────
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String nominatimSearchUrl =
      'https://nominatim.openstreetmap.org/search';
  static const String whatsAppUrl = 'https://wa.me/';
  static const String userAgent = 'WashlyApp/1.0';

  // ── UI constants ──────────────────────────────────────────────────────────
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 200);
}
