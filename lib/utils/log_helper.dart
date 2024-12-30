import '../services/log_service.dart';
import '../services/auth_service.dart';

class LogHelper {
  static final LogService _logService = LogService();

  static Future<void> logUserAction(String action, String details) async {
    if (AuthService.currentUserId != null &&
        AuthService.currentUserName != null) {
      await _logService.createLog(
        action,
        AuthService.currentUserId!,
        AuthService.currentUserName!,
        details,
      );
    }
  }

  static Future<void> logLogin() async {
    await logUserAction('Login', 'Usuário realizou login no sistema');
  }

  static Future<void> logLogout() async {
    await logUserAction('Logout', 'Usuário realizou logout do sistema');
  }

  static Future<void> logReservationCreated(
      String spaceId, String timeSlot) async {
    await logUserAction(
      'Reserva Criada',
      'Espaço: $spaceId, Horário: $timeSlot',
    );
  }

  static Future<void> logReservationCanceled(
      String spaceId, String timeSlot) async {
    await logUserAction(
      'Reserva Cancelada',
      'Espaço: $spaceId, Horário: $timeSlot',
    );
  }
}
