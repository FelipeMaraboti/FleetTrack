import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/log_sincronizacao.dart';
import '../theme/app_theme.dart';
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DestaqueCard(
              sobretitulo: 'Registros pendentes',
              titulo: _pendentes == 0 ? 'Tudo sincronizado' : '$_pendentes aguardando envio',
              trailing: Icon(
                _pendentes == 0 ? Icons.cloud_done : Icons.cloud_upload_outlined,
                color: _pendentes == 0 ? AppColors.verde : AppColors.laranja,
                size: 32,
              ),
              children: [
                Text(
                  'Pendentes: $_pendentes · Última sincronização: ${ultima?.toLocal().toString().substring(0, 19) ?? 'nunca'}',
                  style: const TextStyle(color: AppColors.cinza300, fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.branco, foregroundColor: AppColors.preto),
                    onPressed: _sincronizando ? null : _sincronizar,
                    icon: _sincronizando
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync),
                    label: const Text('Sincronizar agora'),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SecaoTitulo('Histórico'),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const EmptyState(mensagem: 'Sem histórico de sincronização.', icone: Icons.history)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _logs.length,
                    separatorBuilder: (_, __) => const Divider(indent: 56),
                    itemBuilder: (context, i) {
                      final log = _logs[i];
                      final cor = log.sucesso ? AppColors.verde : AppColors.vermelho;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), shape: BoxShape.circle),
                              child: Icon(log.sucesso ? Icons.check : Icons.close, color: cor, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${log.entidade} · ${log.operacao}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(log.mensagem, style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 2),
                                  Text(log.dataHora.toLocal().toString().substring(0, 19), style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
