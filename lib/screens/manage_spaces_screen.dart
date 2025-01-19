import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/event_bus.dart';

class TimeSlot {
  String startTime;
  String endTime;

  TimeSlot({required this.startTime, required this.endTime});

  @override
  String toString() => '$startTime - $endTime';
}

class ManageSpacesScreen extends StatefulWidget {
  const ManageSpacesScreen({super.key});

  @override
  State<ManageSpacesScreen> createState() => _ManageSpacesScreenState();
}

class _ManageSpacesScreenState extends State<ManageSpacesScreen> {
  final String dbUrl = 'https://reservas-f39b7-default-rtdb.firebaseio.com/';
  final _eventBus = SpaceEventBus();
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> spaces = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSpaces();
  }

  Future<void> loadSpaces() async {
    try {
      final response = await http.get(Uri.parse('$dbUrl/spaces.json'));
      if (response.statusCode == 200) {
        setState(() {
          spaces = json.decode(response.body) ?? {};
          isLoading = false;
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar espaços: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  Future<void> updateSpace(String spaceId, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('$dbUrl/spaces/$spaceId.json'),
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        await loadSpaces();
        _eventBus.notify();
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Espaço atualizado com sucesso!')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar espaço: $e')),
      );
    }
  }

  Future<void> deleteSpace(String spaceId) async {
    try {
      final response =
          await http.delete(Uri.parse('$dbUrl/spaces/$spaceId.json'));
      if (response.statusCode == 200) {
        await loadSpaces();
        _eventBus.notify();
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Espaço excluído com sucesso!')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao deletar espaço: $e')),
      );
    }
  }

  Future<void> createSpace(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$dbUrl/spaces.json'),
        body: json.encode(data),
      );
      if (response.statusCode == 200) {
        await loadSpaces();
        _eventBus.notify();
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Espaço criado com sucesso!')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar espaço: $e')),
      );
    }
  }

  String? _validateTimeFormat(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório';
    }

    final parts = value.split(':');
    if (parts.length != 2) return 'Formato inválido (HH:mm)';

    try {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);

      if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
        return 'Horário inválido';
      }
    } catch (e) {
      return 'Apenas números permitidos';
    }

    return null;
  }

  void _showTimeSlotDialog(BuildContext context, Function(TimeSlot) onAdd) {
    final startController = TextEditingController();
    final endController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Horário'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: startController,
                decoration: const InputDecoration(
                  labelText: 'Horário Inicial (HH:mm)',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                  LengthLimitingTextInputFormatter(5),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final text = newValue.text;
                    if (text.length == 2 &&
                        !text.contains(':') &&
                        oldValue.text.length == 1) {
                      return TextEditingValue(
                        text: '$text:',
                        selection: const TextSelection.collapsed(offset: 3),
                      );
                    }
                    return newValue;
                  }),
                ],
                validator: _validateTimeFormat,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: endController,
                decoration: const InputDecoration(
                  labelText: 'Horário Final (HH:mm)',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                  LengthLimitingTextInputFormatter(5),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    final text = newValue.text;
                    if (text.length == 2 &&
                        !text.contains(':') &&
                        oldValue.text.length == 1) {
                      return TextEditingValue(
                        text: '$text:',
                        selection: const TextSelection.collapsed(offset: 3),
                      );
                    }
                    return newValue;
                  }),
                ],
                validator: _validateTimeFormat,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                onAdd(TimeSlot(
                  startTime: startController.text,
                  endTime: endController.text,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showSpaceDialog([String? spaceId]) {
    final isEditing = spaceId != null;
    final space = isEditing ? spaces[spaceId] : null;

    final nameController = TextEditingController(text: space?['name'] ?? '');
    final capacityController =
        TextEditingController(text: space?['capacity']?.toString() ?? '');
    bool isActive = space?['isActive'] ?? true;

    List<TimeSlot> timeSlots = [];
    if (isEditing && space?['availableSlots'] != null) {
      for (String slot in space!['availableSlots']) {
        final parts = slot.split(' - ');
        if (parts.length == 2) {
          timeSlots.add(TimeSlot(startTime: parts[0], endTime: parts[1]));
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Editar Espaço' : 'Novo Espaço'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira um nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: capacityController,
                    decoration: const InputDecoration(
                      labelText: 'Capacidade',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, insira a capacidade';
                      }
                      final capacity = int.tryParse(value);
                      if (capacity == null || capacity <= 0) {
                        return 'Insira um número válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Horários Disponíveis:',
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  ...timeSlots.asMap().entries.map((entry) {
                    final index = entry.key;
                    final slot = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${slot.startTime} - ${slot.endTime}'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                timeSlots.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  ElevatedButton(
                    onPressed: () {
                      _showTimeSlotDialog(context, (TimeSlot slot) {
                        setState(() {
                          timeSlots.add(slot);
                        });
                      });
                    },
                    child: const Text('Adicionar Horário'),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Ativo'),
                    value: isActive,
                    onChanged: (value) => setState(() => isActive = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate() && timeSlots.isNotEmpty) {
                  final data = {
                    'name': nameController.text.trim(),
                    'capacity': int.parse(capacityController.text.trim()),
                    'availableSlots':
                        timeSlots.map((slot) => slot.toString()).toList(),
                    'isActive': isActive,
                  };

                  if (isEditing) {
                    updateSpace(spaceId, data);
                  } else {
                    createSpace(data);
                  }

                  Navigator.pop(context);
                } else if (timeSlots.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Adicione pelo menos um horário'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Salvar' : 'Criar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Espaços'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSpaceDialog(),
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : spaces.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum espaço cadastrado',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: spaces.length,
                  itemBuilder: (context, index) {
                    final spaceId = spaces.keys.elementAt(index);
                    final space = spaces[spaceId];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          space['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('Capacidade: ${space['capacity']}'),
                            Text('Horários: ${space['availableSlots'].length}'),
                            Row(
                              children: [
                                const Text('Status: '),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: space['isActive']
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    space['isActive'] ? 'Ativo' : 'Inativo',
                                    style: TextStyle(
                                      color: space['isActive']
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showSpaceDialog(spaceId),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirmar Exclusão'),
                                  content: const Text(
                                      'Deseja realmente excluir este espaço?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        deleteSpace(spaceId);
                                        Navigator.pop(context);
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Excluir'),
                                    ),
                                  ],
                                ),
                              ),
                              tooltip: 'Excluir',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
