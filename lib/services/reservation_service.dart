// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter_application_2/utils/log_helper.dart';
import 'package:http/http.dart' as http;
import '../models/reservation.dart';
import 'auth_service.dart';
import 'space_service.dart';

class ReservationService {
  final String baseUrl = 'https://reservas-f39b7-default-rtdb.firebaseio.com';
  final String apiKey = 'AIzaSyAqYnKmOM_YrcVHGWxFunzLRn-xTAbkXZA';

  Future<void> createReservation(String spaceId, String timeSlot) async {
    if (AuthService.currentUserId == null ||
        AuthService.currentUserName == null) {
      throw Exception('Usuário não está logado');
    }

    try {
      await LogHelper.logReservationCreated(spaceId, timeSlot);
    } catch (e) {
      print('Logging failed but continuing with reservation: $e');
    }

// Continue with reservation creation...

    final reservation = Reservation(
      id: '', // Será gerado pelo Firebase
      spaceId: spaceId,
      userId: AuthService.currentUserId!,
      userName: AuthService.currentUserName!,
      timeSlot: timeSlot,
      createdAt: DateTime.now(),
    );

    final response = await http.post(
      Uri.parse('$baseUrl/reservations.json'),
      body: json.encode(reservation.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao criar reserva');
    }
  }

  Future<List<Reservation>> getReservationsForSpace(String spaceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservations.json'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = json.decode(response.body);

        if (data == null) return [];

        List<Reservation> reservations = [];

        data.forEach((key, value) {
          if (value['spaceId'] == spaceId) {
            reservations.add(Reservation.fromJson(key, value));
          }
        });

        // Ordenar reservas por data de criação (mais recentes primeiro)
        reservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return reservations;
      } else {
        throw Exception('Falha ao carregar reservas');
      }
    } catch (e) {
      print('Erro ao buscar reservas: $e');
      throw Exception('Falha ao carregar reservas');
    }
  }

  Future<List<Reservation>> getAllReservations() async {
    try {
      print('Iniciando busca de reservas...'); // Debug
      final response = await http.get(
        Uri.parse('$baseUrl/reservations.json'),
      );

      print('Status code: ${response.statusCode}'); // Debug
      print('Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = json.decode(response.body);

        if (data == null) {
          print('Nenhuma reserva encontrada'); // Debug
          return [];
        }

        List<Reservation> reservations = [];

        data.forEach((key, value) {
          try {
            reservations.add(Reservation.fromJson(key, value));
            print('Reserva adicionada: $key'); // Debug
          } catch (e) {
            print('Erro ao converter reserva $key: $e');
          }
        });

        print('Total de reservas carregadas: ${reservations.length}'); // Debug

        reservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reservations;
      } else {
        throw Exception('Falha ao carregar reservas');
      }
    } catch (e) {
      print('Erro ao buscar todas as reservas: $e');
      throw Exception('Falha ao carregar reservas');
    }
  }

  Future<List<Reservation>> getUserReservations(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservations.json'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = json.decode(response.body);

        if (data == null) return [];

        List<Reservation> reservations = [];

        data.forEach((key, value) {
          if (value['userId'] == userId) {
            reservations.add(Reservation.fromJson(key, value));
          }
        });

        // Ordenar reservas por data de criação (mais recentes primeiro)
        reservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return reservations;
      } else {
        throw Exception('Falha ao carregar reservas do usuário');
      }
    } catch (e) {
      print('Erro ao buscar reservas do usuário: $e');
      throw Exception('Falha ao carregar reservas do usuário');
    }
  }

  Future<void> cancelReservation(String reservationId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reservations/$reservationId.json'),
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao buscar dados da reserva');
      }

      final reservationData = json.decode(response.body);
      if (reservationData == null) {
        throw Exception('Reserva não encontrada');
      }

      final reservation = Reservation.fromJson(reservationId, reservationData);

      // Primeiro retornar o slot
      final spaceService = SpaceService();
      await spaceService.returnSlot(reservation.spaceId, reservation.timeSlot);

      // Depois deletar a reserva
      final deleteResponse = await http.delete(
        Uri.parse('$baseUrl/reservations/$reservationId.json'),
      );

      if (deleteResponse.statusCode != 200) {
        throw Exception('Falha ao cancelar reserva');
      }
    } catch (e) {
      print('Erro ao cancelar reserva: $e');
      throw Exception('Falha ao cancelar reserva');
    }
  }

  Future<void> updateSpaceAvailability(
      String spaceId, String timeSlot, bool available) async {
    try {
      // Primeiro, buscar os slots disponíveis atuais
      final response = await http.get(
        Uri.parse('$baseUrl/spaces/$spaceId/availableSlots.json?auth=$apiKey'),
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao buscar slots disponíveis');
      }

      final Map<String, dynamic>? currentSlots = json.decode(response.body);

      // Determinar o próximo índice
      int nextIndex = 0;
      if (currentSlots != null) {
        nextIndex = currentSlots.length;
      }

      // Atualizar com o novo slot usando índice numérico
      final updateResponse = await http.patch(
        Uri.parse('$baseUrl/spaces/$spaceId/availableSlots.json?auth=$apiKey'),
        body: json.encode({'$nextIndex': timeSlot}),
      );

      if (updateResponse.statusCode != 200) {
        throw Exception('Falha ao atualizar disponibilidade do espaço');
      }
    } catch (e) {
      print('Erro ao atualizar disponibilidade: $e');
      throw Exception('Falha ao atualizar disponibilidade do espaço');
    }
  }
}
