//Obs: para acessar o painel de administrador basta fazer login usando um email que está cadastrado como admin
//Um dos emails de administrador é "admin@email.com" e a senha é "123456", com ele o painel de adm fica disponivel na profile screen
//No painel de administrador é possível tornar qualquer outro usuario cadastrado administrador, gerenciar usuarios, ver logs, gerenciar os espaços e gerenciar reservas

import 'package:flutter/material.dart';
import 'package:flutter_application_2/screens/manage_spaces_screen.dart';
import 'package:flutter_application_2/screens/manage_users_screen.dart';
import 'package:flutter_application_2/screens/manage_reservations_screen.dart';
import 'package:flutter_application_2/screens/system_logs_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Administrativo'),
        elevation: 0,
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildAdminCard(
            context,
            'Gerenciar Espaços',
            Icons.meeting_room,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageSpacesScreen(),
              ),
            ),
          ),
          _buildAdminCard(
            context,
            'Gerenciar Usuários',
            Icons.people,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ManageUsersScreen()),
            ),
          ),
          _buildAdminCard(
            context,
            'Gerenciar Reservas',
            Icons.analytics,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageReservationsScreen(),
              ),
            ),
          ),
          _buildAdminCard(
            context,
            'Logs do Sistema',
            Icons.history,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SystemLogsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildAdminCard(
  BuildContext context,
  String title,
  IconData icon,
  VoidCallback onTap,
) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
