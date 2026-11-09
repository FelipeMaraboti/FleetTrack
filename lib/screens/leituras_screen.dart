import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/leitura_telemetria.dart';
import '../routes/app_routes.dart';
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
                        itemCount: _leituras.length,
                        itemBuilder: (context, i) {
                          final l = _leituras[i];
                          return Dismissible(
                            key: ValueKey(l.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Theme.of(context).colorScheme.error,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => _excluir(l),
                            child: ListTile(
                              leading: Icon(l.conectado ? Icons.sensors : Icons.sensors_off),
                              title: Text('${l.veiculoId} • ${l.velocidade.toStringAsFixed(0)} km/h • ${l.bateria.toStringAsFixed(0)}%'),
                              subtitle: Text('${l.rotaId ?? 'Sem rota'} • ${_formatarData(l.timestamp)}'),
                              trailing: SyncStatusIcon(sincronizado: l.sincronizado),
                              onTap: () => Navigator.pushNamed(context, AppRoutes.leituraDetalhe, arguments: l),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nova leitura',
        onPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.leituraForm);
          _carregar();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

String _dois(int n) => n.toString().padLeft(2, '0');

String _formatarData(DateTime d) =>
    '${_dois(d.day)}/${_dois(d.month)} ${_dois(d.hour)}:${_dois(d.minute)}:${_dois(d.second)}';
