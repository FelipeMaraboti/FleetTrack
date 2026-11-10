import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/rota.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
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
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          separatorBuilder: (_, __) => const SizedBox.shrink(),
                          itemCount: _rotas.length,
                          itemBuilder: (context, i) {
                            final rota = _rotas[i];
                            return Dismissible(
                              key: ValueKey(rota.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.error,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                child: const Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              onDismissed: (_) => _excluir(rota),
                              child: _RotaCard(
                                rota: rota,
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
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Nova rota',
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nova rota'),
      ),
    );
  }
}

/// Cartão de rota no estilo "viagem": origem (círculo) ligada ao destino (quadrado).
class _RotaCard extends StatelessWidget {
  final Rota rota;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _RotaCard({required this.rota, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(rota.id, style: tt.labelMedium?.copyWith(color: cores.onSurfaceVariant, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  if (!rota.ativa) const StatusPill(texto: 'INATIVA', cor: AppColors.cinza500),
                  const Spacer(),
                  SyncStatusIcon(sincronizado: rota.sincronizado),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: cores.onSurface)),
                      Container(width: 2, height: 22, color: cores.outline),
                      Container(width: 10, height: 10, color: cores.onSurface),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${rota.origem} → ${rota.destino}',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Text('Origem: ${rota.origem}  ·  Destino: ${rota.destino}',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _Info(icone: Icons.straighten, texto: '${rota.distanciaKm.toStringAsFixed(1)} km'),
                  const SizedBox(width: 8),
                  _Info(icone: Icons.schedule, texto: '${rota.tempoEstimadoMinutos.toStringAsFixed(0)} min'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icone;
  final String texto;
  const _Info({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16),
          const SizedBox(width: 6),
          Text(texto, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
