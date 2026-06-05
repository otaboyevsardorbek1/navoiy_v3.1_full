// lib/core/utils/error_handler.dart

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

// ─── Error messages in Uzbek ──────────────────────────────────────────────────

class UzbekErrors {
  static const networkUnavailable = 'Internet aloqasi mavjud emas';
  static const timeout = 'So\'rov muddati tugadi, qayta urinib ko\'ring';
  static const serverError = 'Server xatosi yuz berdi';
  static const unauthorized = 'Tizimga kirish talab etiladi';
  static const forbidden = 'Ruxsat yo\'q';
  static const notFound = 'Ma\'lumot topilmadi';
  static const validationError = 'Kiritilgan ma\'lumotlar noto\'g\'ri';
  static const unknownError = 'Kutilmagan xatolik yuz berdi';
  static const databaseError = 'Ma\'lumotlar bazasida xatolik';
  static const sessionExpired = 'Sessiya muddati tugadi, qayta kiring';
}
