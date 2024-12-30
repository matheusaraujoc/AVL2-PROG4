import 'package:flutter/material.dart';
import '../models/system_log.dart';
import '../services/log_service.dart';
import 'package:intl/intl.dart';

class SystemLogsScreen extends StatefulWidget {
  const SystemLogsScreen({Key? key}) : super(key: key);

  @override
  State<SystemLogsScreen> createState() => _SystemLogsScreenState();
}

class _SystemLogsScreenState extends State<SystemLogsScreen> {
  final LogService _logService = LogService();
  List<SystemLog> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregarLogs();
  }

  Future<void> _carregarLogs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final logs = await _logService.getLogs();
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar logs: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs do Sistema'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarLogs,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarLogs,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_logs.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum log encontrado',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarLogs,
      child: ListView.builder(
        itemCount: _logs.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final log = _logs[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text(
                log.action,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Usuário: ${log.userName}'),
                  Text(log.details),
                  Text(
                    'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(log.timestamp)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
