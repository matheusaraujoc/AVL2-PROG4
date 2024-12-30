import 'package:flutter/material.dart';
import 'dart:async';
import '../models/space.dart';
import '../screens/space_details_screen.dart';
import '../screens/profile_screen.dart';
import '../services/space_service.dart';
import '../services/event_bus.dart';

class SpacesScreen extends StatefulWidget {
  const SpacesScreen({super.key});

  @override
  _SpacesScreenState createState() => _SpacesScreenState();
}

class _SpacesScreenState extends State<SpacesScreen> {
  final SpaceService _spaceService = SpaceService();
  final _eventBus = SpaceEventBus();
  late StreamSubscription _subscription;
  late Future<List<Space>> _spaces;

  @override
  void initState() {
    super.initState();
    _loadSpaces();
    _subscription = _eventBus.stream.listen((_) => _loadSpaces());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _loadSpaces() async {
    setState(() {
      _spaces = _spaceService.getSpaces();
    });
  }

  bool isSpaceActive(Space space) {
    return space.isActive && space.availableSlots.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Espaços Disponíveis',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.secondaryContainer,
            ),
            child: IconButton(
              icon: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );

                if (result == true) {
                  _loadSpaces();
                }
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSpaces,
        child: FutureBuilder<List<Space>>(
          future: _spaces,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 70,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erro ao carregar espaços',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: _loadSpaces,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.space_dashboard_outlined,
                      size: 70,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum espaço disponível',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final space = snapshot.data![index];
                final isActive = isSpaceActive(space);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    elevation: 2,
                    color: Theme.of(context).colorScheme.surface,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SpaceDetailsScreen(space: space),
                          ),
                        );

                        if (result == true) {
                          _loadSpaces();
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    space.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isActive
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        size: 16,
                                        color: isActive
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isActive ? 'Ativo' : 'Inativo',
                                        style: TextStyle(
                                          color: isActive
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildInfoItem(
                                    context,
                                    Icons.people,
                                    'Capacidade',
                                    '${space.capacity}',
                                  ),
                                  _buildInfoItem(
                                    context,
                                    Icons.access_time,
                                    'Horários',
                                    '${space.availableSlots.length}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.secondary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
