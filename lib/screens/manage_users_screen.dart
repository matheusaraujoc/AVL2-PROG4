import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<Map<String, dynamic>> users = [];
  Map<String, bool> admins = {};
  bool isLoading = true;
  String? currentUserId = AuthService.currentUserId;

  static const Color adminColor = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final usersResponse = await http.get(
        Uri.parse(
            'https://reservas-f39b7-default-rtdb.firebaseio.com/users.json'),
      );

      final adminsResponse = await http.get(
        Uri.parse(
            'https://reservas-f39b7-default-rtdb.firebaseio.com/admins.json'),
      );

      if (usersResponse.statusCode == 200 && adminsResponse.statusCode == 200) {
        final Map<String, dynamic> usersData = json.decode(usersResponse.body);
        final Map<String, dynamic> adminsData =
            json.decode(adminsResponse.body) ?? {};

        setState(() {
          users = usersData.entries
              .where((entry) => entry.key != currentUserId)
              .map((entry) => {
                    'id': entry.key,
                    ...Map<String, dynamic>.from(entry.value),
                  })
              .toList();
          admins = Map<String, bool>.from(adminsData);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> toggleAdminStatus(String userId, bool isAdmin) async {
    if (admins.length == 1 && isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não é possível remover o último administrador'),
        ),
      );
      return;
    }

    try {
      if (!isAdmin) {
        await http.put(
          Uri.parse(
              'https://reservas-f39b7-default-rtdb.firebaseio.com/admins/$userId.json'),
          body: json.encode(true),
        );
      } else {
        await http.delete(
          Uri.parse(
              'https://reservas-f39b7-default-rtdb.firebaseio.com/admins/$userId.json'),
        );
      }
      await fetchData();
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao atualizar status de administrador'),
        ),
      );
    }
  }

  bool isToggleEnabled() {
    return admins.length > 1 ||
        users.any((user) => !admins.containsKey(user['id']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final bool isAdmin = admins.containsKey(user['id']);
                final bool canToggle = isToggleEnabled();

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      child: Text(user['username'][0].toUpperCase()),
                    ),
                    title: Text(user['username']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['email']),
                        Text(
                          isAdmin ? 'Administrador' : 'Usuário comum',
                          style: TextStyle(
                            color: isAdmin ? adminColor : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: SizedBox(
                      width: 65,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Admin',
                            style: TextStyle(
                              color: isAdmin ? adminColor : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(
                            height: 30,
                            child: Switch(
                              value: isAdmin,
                              activeColor: adminColor,
                              onChanged: canToggle
                                  ? (bool value) =>
                                      toggleAdminStatus(user['id'], isAdmin)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
