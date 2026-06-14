import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  // ─── Backend (NestJS) ───────────────────────────────
  static String get baseUrl => dotenv.env['API_BASE_URL']!;

  // ─── Supabase ───────────────────────────────────────
  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;

  // ─── Auth ───────────────────────────────────────────
  static const String authRole = '/auth/role';

  // ─── Drug Search ────────────────────────────────────
  static const String drugSearch = '/drugs/search';
  static String drugNearby(String drugId) => '/drugs/$drugId/nearby';

  // ─── Reservations ───────────────────────────────────
  static const String reservations = '/reservations';
  static const String myReservations = '/reservations/me';
  static String cancelReservation(String id) => '/reservations/$id';

  // ─── AI Chat ────────────────────────────────────────
  static const String aiChat = '/ai/chat';

  // ─── Notifications ──────────────────────────────────
  static const String myNotifications = '/notifications/me';
  static String markNotificationRead(String id) => '/notifications/$id/read';

  // ─── User ───────────────────────────────────────────
  static const String updateFcmToken = '/users/me/fcm-token';
}