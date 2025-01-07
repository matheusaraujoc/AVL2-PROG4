// ignore_for_file: avoid_print

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

      final currentLogs = await getLogs();

      if (currentLogs.length >= maxLogs) {
        currentLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        if (currentLogs.isNotEmpty) {
          await http.delete(
            Uri.parse('$baseUrl/logs/${currentLogs[0].id}.json'),
          );
        }
      }

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

  Future<void> cleanOldLogs() async {
    try {
      final logs = await getLogs();

      if (logs.length > maxLogs) {
        logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        final logsToRemove = logs.length - maxLogs;

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
