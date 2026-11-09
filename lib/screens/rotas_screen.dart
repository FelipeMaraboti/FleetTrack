import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/rota.dart';
import '../routes/app_routes.dart';
import '../widgets/comuns.dart';

/// Tela 4 - Listagem de rotas (CRUD com Dismissible e indicador de sync).
class RotasScreen extends StatefulWidget {
  const RotasScreen({super.key});

  @override
  State<RotasScreen> createState() => _RotasScreenState();
}

class _RotasScreenState extends State<RotasScreen> {
  List<Rota> _rotas = [];
  bool _carregando = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregar();
  }

  Future<void> _carregar() async {
    final rotas = await AppScope.of(context).rotas.listar();
    if (!mounted) return;
    setState(() {
      _rotas = rotas;
      _carregando = false;
    });
  }

  Future<void> _excluir(Rota rota) async {
    // Atualiza a UI imediatamente; o repositório cuida do envio.
    setState(() => _rotas.remove(rota));
    final confirmado = await AppScope.of(context).rotas.excluir(rota.id);
    if (!mounted) return;
    mostrarMensagem(
      context,
      confirmado ? 'Rota ${rota.id} excluída.' : 'Rota ${rota.id} excluída localmente (envio pendente).',
    );
  }

  Future<void> _abrirFormulario([Rota? rota]) async {
    final salvou = await Navigator.pushNamed(context, AppRoutes.rotaForm, arguments: rota);
    if (salvou == true) _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rotas urbanas')),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _rotas.isEmpty
                    ? const EmptyState(mensagem: 'Nenhuma rota cadastrada.', icone: Icons.alt_route)
                    : RefreshIndicator(
                        onRefresh: _carregar,
                        child: ListView.builder(
                          itemCount: _rotas.length,
                          itemBuilder: (context, i) {
                            final rota = _rotas[i];
                            return Dismissible(
                              key: ValueKey(rota.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Theme.of(context).colorScheme.error,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (_) => _excluir(rota),
                              child: ListTile(
                                leading: CircleAvatar(child: Icon(rota.ativa ? Icons.alt_route : Icons.block)),
                                title: Text('${rota.origem} → ${rota.destino}', maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text('${rota.id} • ${rota.distanciaKm.toStringAsFixed(1)} km • ${rota.tempoEstimadoMinutos.toStringAsFixed(0)} min'),
                                trailing: SyncStatusIcon(sincronizado: rota.sincronizado),
                                onTap: () async {
                                  await Navigator.pushNamed(context, AppRoutes.rotaDetalhe, arguments: rota.id);
                                  _carregar();
                                },
                                onLongPress: () => _abrirFormulario(rota),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nova rota',
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
