import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/system_log.dart';

class LogService {
  final String baseUrl = 'https://reservas-f39b7-default-rtdb.firebaseio.com';
  final int maxLogs = 50;

  Future<void> createLog(
      String action, String userId, String userName, String details) async {
    try {
      final log = SystemLog(
        id: '',
        action: action,
        userId: userId,
        userName: userName,
        details: details,
        timestamp: DateTime.now(),
      );

      // Primeiro, obtemos a contagem atual de logs
      final currentLogs = await getLogs();

      // Se já tivermos 50 logs, removemos o mais antigo
      if (currentLogs.length >= maxLogs) {
        // Ordenamos por timestamp para encontrar o log mais antigo
        currentLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Removemos o log mais antigo
        if (currentLogs.isNotEmpty) {
          await http.delete(
            Uri.parse('$baseUrl/logs/${currentLogs[0].id}.json'),
          );
        }
      }

      // Criamos o novo log
      final response = await http.post(
        Uri.parse('$baseUrl/logs.json'),
        body: json.encode(log.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao criar log');
      }
    } catch (e) {
      print('Erro ao criar log: $e');
      throw Exception('Falha ao criar log');
    }
  }

  Future<List<SystemLog>> getLogs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/logs.json'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = json.decode(response.body);

        if (data == null) return [];

        List<SystemLog> logs = [];
        data.forEach((key, value) {
          logs.add(SystemLog.fromJson(key, value));
        });

        // Ordenamos os logs do mais recente para o mais antigo
        logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return logs;
      } else {
        throw Exception('Falha ao carregar logs');
      }
    } catch (e) {
      print('Erro ao buscar logs: $e');
      throw Exception('Falha ao carregar logs');
    }
  }

  // Método auxiliar para limpar logs antigos manualmente se necessário
  Future<void> cleanOldLogs() async {
    try {
      final logs = await getLogs();

      if (logs.length > maxLogs) {
        // Ordenamos do mais antigo para o mais recente
        logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // Calculamos quantos logs precisam ser removidos
        final logsToRemove = logs.length - maxLogs;

        // Removemos os logs mais antigos
        for (var i = 0; i < logsToRemove; i++) {
          await http.delete(
            Uri.parse('$baseUrl/logs/${logs[i].id}.json'),
          );
        }
      }
    } catch (e) {
      print('Erro ao limpar logs antigos: $e');
      throw Exception('Falha ao limpar logs antigos');
    }
  }
}
