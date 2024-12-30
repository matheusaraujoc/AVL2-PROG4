import 'package:flutter/material.dart';
import '../models/reservation.dart';
import '../services/reservation_service.dart';
import '../services/space_service.dart';
import 'package:intl/intl.dart';

class ManageReservationsScreen extends StatefulWidget {
  const ManageReservationsScreen({super.key});

  @override
  State<ManageReservationsScreen> createState() =>
      _ManageReservationsScreenState();
}

class _ManageReservationsScreenState extends State<ManageReservationsScreen> {
  final ReservationService _reservationService = ReservationService();
  final SpaceService _spaceService = SpaceService();
  List<Reservation> _reservations = [];
  bool _isLoading = true;
  Map<String, String> _spaceNames = {};

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);

    try {
      // Carregar reservas primeiro
      final reservations = await _reservationService.getAllReservations();
      setState(() => _reservations = reservations);

      try {
        // Carregar espaços separadamente
        final spaces = await _spaceService.getAllSpaces();
        setState(() {
          _spaceNames = {
            for (var space in spaces) space.id: space.name,
          };
        });
      } catch (e) {
        print('Erro ao carregar espaços: $e');
        // Não mostrar erro ao usuário, apenas registrar
      }
    } catch (e) {
      print('Erro ao carregar reservas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar reservas')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete(Reservation reservation) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cancelamento'),
        content: Text(
          'Tem certeza que deseja cancelar a reserva de ${reservation.userName}?\n\n'
          'Espaço: ${_spaceNames[reservation.spaceId] ?? "Desconhecido"}\n'
          'Horário: ${reservation.timeSlot}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteReservation(reservation);
    }
  }

  Future<void> _deleteReservation(Reservation reservation) async {
    try {
      await _reservationService.cancelReservation(reservation.id);
      await _loadReservations(); // Recarrega a lista
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao cancelar reserva')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Reservas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
              ? const Center(child: Text('Nenhuma reserva encontrada'))
              : ListView.builder(
                  itemCount: _reservations.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final reservation = _reservations[index];
                    final spaceName = _spaceNames[reservation.spaceId] ??
                        'Espaço Desconhecido';
                    final formattedDate = DateFormat('dd/MM/yyyy HH:mm')
                        .format(reservation.createdAt);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: ListTile(
                        title: Text(
                          spaceName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Usuário: ${reservation.userName}'),
                            Text('Horário: ${reservation.timeSlot}'),
                            Text('Criado em: $formattedDate'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(reservation),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
