import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/log_sincronizacao.dart';
import '../widgets/comuns.dart';

/// Tela 10 - Diagnóstico de sincronização: pendências, última sync e histórico.
class SincronizacaoScreen extends StatefulWidget {
  const SincronizacaoScreen({super.key});

  @override
  State<SincronizacaoScreen> createState() => _SincronizacaoScreenState();
}

class _SincronizacaoScreenState extends State<SincronizacaoScreen> {
  int _pendentes = 0;
  List<LogSincronizacao> _logs = [];
  bool _sincronizando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregar();
  }

  Future<void> _carregar() async {
    final repo = AppScope.of(context).sincronizacao;
    final pendentes = await repo.contarPendentes();
    final logs = await repo.historico();
    if (!mounted) return;
    setState(() {
      _pendentes = pendentes;
      _logs = logs;
    });
  }

  Future<void> _sincronizar() async {
    setState(() => _sincronizando = true);
    final resumo = await AppScope.of(context).sincronizacao.sincronizarTudo();
    if (!mounted) return;
    setState(() => _sincronizando = false);
    mostrarMensagem(context, resumo.mensagem, erro: !resumo.online);
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final ultima = AppScope.of(context).sincronizacao.ultimaSincronizacao;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronização'),
        actions: [
          IconButton(
            tooltip: 'Limpar histórico',
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              await AppScope.of(context).sincronizacao.limparHistorico();
              _carregar();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Registros pendentes: $_pendentes', style: Theme.of(context).textTheme.titleMedium),
                  Text('Última sincronização: ${ultima?.toLocal().toString().substring(0, 19) ?? 'nunca'}'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _sincronizando ? null : _sincronizar,
                    icon: _sincronizando
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync),
                    label: const Text('Sincronizar agora'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const EmptyState(mensagem: 'Sem histórico de sincronização.', icone: Icons.history)
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, i) {
                      final log = _logs[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          log.sucesso ? Icons.check_circle : Icons.error,
                          color: log.sucesso ? Colors.green : Colors.red,
                        ),
                        title: Text('${log.entidade} • ${log.operacao}'),
                        subtitle: Text('${log.mensagem}\n${log.dataHora.toLocal().toString().substring(0, 19)}'),
                        isThreeLine: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
