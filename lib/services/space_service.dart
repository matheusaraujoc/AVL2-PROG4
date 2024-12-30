// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter_application_2/models/space.dart';
import 'package:http/http.dart' as http;
import 'event_bus.dart';

class SpaceService {
  final String baseUrl =
      'https://reservas-f39b7-default-rtdb.firebaseio.com/spaces';
  final String apiKey = 'AIzaSyAqYnKmOM_YrcVHGWxFunzLRn-xTAbkXZA';
  final _eventBus = SpaceEventBus();

  Future<List<Space>> getSpaces() async {
    final response = await http.get(Uri.parse('$baseUrl.json?auth=$apiKey'));

    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List<Space> spaces = [];

      data.forEach((key, value) {
        if (value['availableSlots'] == null) {
          value['availableSlots'] = [];
        }
        spaces.add(Space.fromJson(key, value));
      });

      return spaces;
    } else {
      throw Exception('Failed to load spaces');
    }
  }

  Future<void> reserveSlot(String spaceId, String slot) async {
    final space = await getSpace(spaceId);
    List<String> updatedSlots = List.from(space.availableSlots);
    updatedSlots.remove(slot);

    final response = await http.patch(
      Uri.parse('$baseUrl/$spaceId.json?auth=$apiKey'),
      body: json.encode({
        'availableSlots': updatedSlots,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reserve slot');
    }
    _eventBus.notify();
  }

  Future<Space> getSpace(String spaceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$spaceId.json?auth=$apiKey'),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['availableSlots'] == null) {
        data['availableSlots'] = [];
      }
      return Space.fromJson(spaceId, data);
    } else {
      throw Exception('Failed to load space');
    }
  }

  Future<void> returnSlot(String spaceId, String timeSlot) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$spaceId.json?auth=$apiKey'),
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao buscar detalhes do espaço');
      }

      final spaceData = json.decode(response.body);
      List<dynamic> availableSlots =
          List.from(spaceData['availableSlots'] ?? []);
      availableSlots.add(timeSlot);

      final updateResponse = await http.patch(
        Uri.parse('$baseUrl/$spaceId.json?auth=$apiKey'),
        body: json.encode({'availableSlots': availableSlots}),
      );

      if (updateResponse.statusCode != 200) {
        throw Exception('Falha ao atualizar slots disponíveis');
      }

      _eventBus.notify();
    } catch (e) {
      print('Erro ao retornar slot: $e');
      throw Exception('Falha ao retornar slot');
    }
  }

  Future<List<Space>> getAllSpaces() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl.json?auth=$apiKey'));

      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = json.decode(response.body);

        if (data == null) return [];

        List<Space> spaces = [];
        data.forEach((key, value) {
          if (value != null) {
            try {
              // Ensure availableSlots exists
              if (value['availableSlots'] == null) {
                value['availableSlots'] = [];
              }
              spaces.add(Space.fromJson(key, value));
            } catch (e) {
              print('Error parsing space $key: $e');
            }
          }
        });

        return spaces;
      } else {
        throw Exception('Failed to load spaces: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching spaces: $e');
      throw Exception('Failed to load spaces');
    }
  }
}
