import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/leitura_telemetria.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/comuns.dart';

/// Tela 7 - Listagem das leituras de telemetria salvas no SQLite.
class LeiturasScreen extends StatefulWidget {
  const LeiturasScreen({super.key});

  @override
  State<LeiturasScreen> createState() => _LeiturasScreenState();
}

class _LeiturasScreenState extends State<LeiturasScreen> {
  List<LeituraTelemetria> _leituras = [];
  bool _carregando = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregar();
  }

  Future<void> _carregar() async {
    final leituras = await AppScope.of(context).telemetria.listar();
    if (!mounted) return;
    setState(() {
      _leituras = leituras;
      _carregando = false;
    });
  }

  Future<void> _excluir(LeituraTelemetria leitura) async {
    setState(() => _leituras.remove(leitura));
    final confirmado = await AppScope.of(context).telemetria.excluir(leitura);
    if (!mounted) return;
    mostrarMensagem(context, confirmado ? 'Leitura excluída.' : 'Leitura excluída localmente (envio pendente).');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Telemetria')),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _leituras.isEmpty
                    ? const EmptyState(mensagem: 'Nenhuma leitura registrada.\nToque em + para adicionar.', icone: Icons.sensors_off)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: _leituras.length,
                        itemBuilder: (context, i) {
                          final l = _leituras[i];
                          return Dismissible(
                            key: ValueKey(l.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(Icons.delete_outline, color: Colors.white),
                            ),
                            onDismissed: (_) => _excluir(l),
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => Navigator.pushNamed(context, AppRoutes.leituraDetalhe, arguments: l),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      IconTile(
                                        icone: l.conectado ? Icons.sensors : Icons.sensors_off,
                                        cor: l.conectado ? AppColors.verde : AppColors.cinza500,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('${l.veiculoId} · ${l.velocidade.toStringAsFixed(0)} km/h',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 2),
                                            Text('${l.rotaId ?? 'Sem rota'} · ${_formatarData(l.timestamp)}',
                                                style: Theme.of(context).textTheme.bodySmall),
                                            const SizedBox(height: 10),
                                            BateriaIndicator(nivel: l.bateria),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SyncStatusIcon(sincronizado: l.sincronizado),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Nova leitura',
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.leituraForm);
          _carregar();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova leitura'),
      ),
    );
  }
}

String _dois(int n) => n.toString().padLeft(2, '0');

String _formatarData(DateTime d) => '${_dois(d.day)}/${_dois(d.month)} ${_dois(d.hour)}:${_dois(d.minute)}:${_dois(d.second)}';
