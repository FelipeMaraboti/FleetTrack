import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/comuns.dart';

/// Tela 1 - Painel principal com métricas da frota e status de sincronização.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalRotas = 0;
  int _totalLeituras = 0;
  int _pendentes = 0;
  bool _carregando = true;
  bool _sincronizando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregar();
  }

  /// Leitura imediata local: os números vêm do SQLite, nunca da rede.
  Future<void> _carregar() async {
    final deps = AppScope.of(context);
    final rotas = await deps.rotas.listar();
    final leituras = await deps.telemetria.listar();
    final pendentes = await deps.sincronizacao.contarPendentes();
    if (!mounted) return;
    setState(() {
      _totalRotas = rotas.length;
      _totalLeituras = leituras.length;
      _pendentes = pendentes;
      _carregando = false;
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

  Future<void> _abrir(String rota) async {
    await Navigator.pushNamed(context, rota);
    _carregar();
  }

  /// Grade com as 6 métricas da frota.
  Widget _grid({required bool shrink}) {
    final frota = AppScope.of(context).frota;
    return GridView.count(
      shrinkWrap: shrink,
      physics: shrink ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      childAspectRatio: 1.25,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        MetricCard(
            titulo: 'Veículos na frota',
            valor: '${frota.totalVeiculos}',
            icone: Icons.directions_car,
            onTap: () => _abrir(AppRoutes.veiculos)),
        MetricCard(titulo: 'Rotas cadastradas', valor: '$_totalRotas', icone: Icons.alt_route, onTap: () => _abrir(AppRoutes.rotas)),
        MetricCard(
            titulo: 'Leituras de telemetria', valor: '$_totalLeituras', icone: Icons.sensors, onTap: () => _abrir(AppRoutes.leituras)),
        MetricCard(
            titulo: 'Pendentes de envio',
            valor: '$_pendentes',
            icone: Icons.cloud_upload_outlined,
            destaque: _pendentes > 0 ? AppColors.laranja : null,
            onTap: () => _abrir(AppRoutes.sincronizacao)),
        MetricCard(
            titulo: 'Bateria média',
            valor: '${frota.calcularMediaBateria().toStringAsFixed(0)}%',
            icone: Icons.battery_charging_full,
            destaque: AppColors.verde),
        MetricCard(
            titulo: 'Bateria baixa (<20%)',
            valor: '${frota.obterVeiculosComBateriaBaixa().length}',
            icone: Icons.battery_alert,
            destaque: AppColors.vermelho),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final topo = MediaQuery.paddingOf(context).top;

    return Scaffold(
      drawer: const AppDrawer(),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(builder: (context, constraints) {
              final largo = constraints.maxWidth > 700;
              final lista = RefreshIndicator(
                onRefresh: _carregar,
                child: CustomScrollView(
                  slivers: [
                    // Cabeçalho com "mapa" ilustrativo e botões flutuantes.
                    // Mapa e folha ficam no mesmo Stack para a folha ser desenhada por cima.
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 260 + topo,
                            child: CustomPaint(painter: _MapaPainter(escuro: Theme.of(context).brightness == Brightness.dark)),
                          ),
                          Positioned(
                            top: topo + 12,
                            left: 16,
                            child: Builder(
                              builder: (ctx) => _BotaoRedondo(
                                icone: Icons.menu,
                                tooltip: 'Menu',
                                onPressed: () => Scaffold.of(ctx).openDrawer(),
                              ),
                            ),
                          ),
                          Positioned(
                            top: topo + 12,
                            right: 16,
                            child: _BotaoRedondo(
                              key: const Key('botao-sincronizar'),
                              tooltip: 'Sincronizar agora',
                              onPressed: _sincronizando ? null : _sincronizar,
                              child: _sincronizando
                                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Badge(
                                      isLabelVisible: _pendentes > 0,
                                      label: Text('$_pendentes'),
                                      child: const Icon(Icons.sync),
                                    ),
                            ),
                          ),
                          // Folha branca sobreposta ao mapa.
                          Padding(
                            padding: EdgeInsets.only(top: 232 + topo),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cores.surface,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))
                                ],
                              ),
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      width: 40,
                                      height: 4,
                                      decoration: BoxDecoration(color: cores.outline, borderRadius: BorderRadius.circular(99)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text('FleetTrack', style: tt.headlineMedium),
                                  Text('Sua frota em tempo real', style: tt.bodyMedium?.copyWith(color: cores.onSurfaceVariant)),
                                  const SizedBox(height: 16),
                                  const OfflineBanner(margem: EdgeInsets.only(bottom: 12)),
                                  _BarraBusca(onTap: () => _abrir(AppRoutes.rotaForm)),
                                  const SizedBox(height: 16),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    clipBehavior: Clip.none,
                                    child: Row(
                                      children: [
                                        _Atalho(
                                            icone: Icons.add_circle_outline,
                                            texto: 'Nova leitura',
                                            onTap: () => _abrir(AppRoutes.leituraForm)),
                                        _Atalho(
                                            icone: Icons.directions_car_outlined,
                                            texto: 'Veículos',
                                            onTap: () => _abrir(AppRoutes.veiculos)),
                                        _Atalho(icone: Icons.alt_route, texto: 'Rotas', onTap: () => _abrir(AppRoutes.rotas)),
                                        _Atalho(icone: Icons.sensors, texto: 'Telemetria', onTap: () => _abrir(AppRoutes.leituras)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  if (!largo) ...[
                                    Text('Visão geral', style: tt.titleLarge),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!largo)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverToBoxAdapter(child: _grid(shrink: true)),
                      ),
                  ],
                ),
              );
              if (!largo) return lista;
              // Tela larga (tablet/desktop): mapa + busca à esquerda, métricas à direita.
              return Row(
                children: [
                  Expanded(child: lista),
                  SizedBox(
                    width: constraints.maxWidth * 0.5,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(8, topo + 20, 20, 20),
                      child: _grid(shrink: false),
                    ),
                  ),
                ],
              );
            }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(AppRoutes.leituraForm),
        icon: const Icon(Icons.add),
        label: const Text('Nova leitura'),
      ),
    );
  }
}

class _BotaoRedondo extends StatelessWidget {
  final IconData? icone;
  final Widget? child;
  final String tooltip;
  final VoidCallback? onPressed;

  const _BotaoRedondo({super.key, this.icone, this.child, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Material(
      color: cores.surface,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black38,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: cores.onSurface,
        icon: child ?? Icon(icone),
      ),
    );
  }
}

class _BarraBusca extends StatelessWidget {
  final VoidCallback onTap;
  const _BarraBusca({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Material(
      color: cores.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
          child: Row(
            children: [
              const Icon(Icons.search, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Para onde?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: cores.surface, borderRadius: BorderRadius.circular(99)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_road, size: 18),
                    SizedBox(width: 6),
                    Text('Nova rota', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Atalho extends StatelessWidget {
  final IconData icone;
  final String texto;
  final VoidCallback onTap;
  const _Atalho({required this.icone, required this.texto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: cores.surfaceContainerLow, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Icon(icone, size: 28),
              const SizedBox(height: 8),
              Text(texto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mapa ilustrativo: quarteirões, avenidas, uma rota em preto e marcadores.
class _MapaPainter extends CustomPainter {
  final bool escuro;
  _MapaPainter({required this.escuro});

  @override
  void paint(Canvas canvas, Size size) {
    final fundo = escuro ? const Color(0xFF1B1D22) : const Color(0xFFEDEFF2);
    final quadra = escuro ? const Color(0xFF23262C) : const Color(0xFFF8F8F9);
    final rua = escuro ? const Color(0xFF30343B) : AppColors.branco;
    final parque = escuro ? const Color(0xFF1F3326) : const Color(0xFFD7EFD9);
    final agua = escuro ? const Color(0xFF1A2A3D) : const Color(0xFFCFE3F7);

    canvas.drawRect(Offset.zero & size, Paint()..color = fundo);

    final rnd = math.Random(7);
    const passo = 64.0;
    for (double y = -20; y < size.height; y += passo) {
      for (double x = -30; x < size.width; x += passo) {
        final r = RRect.fromRectAndRadius(Rect.fromLTWH(x + 6, y + 6, passo - 12, passo - 12), const Radius.circular(6));
        final v = rnd.nextDouble();
        canvas.drawRRect(r, Paint()..color = v < 0.1 ? parque : quadra);
      }
    }

    // Rio cortando o mapa.
    final rio = Path()
      ..moveTo(size.width * 0.72, 0)
      ..cubicTo(size.width * 0.65, size.height * 0.3, size.width * 0.9, size.height * 0.55, size.width * 0.8, size.height);
    canvas.drawPath(
        rio,
        Paint()
          ..color = agua
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26);

    // Avenidas principais.
    final av = Paint()
      ..color = rua
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height * 0.62), Offset(size.width, size.height * 0.48), av);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.4, size.height), av);

    // Rota destacada.
    final a = Offset(size.width * 0.18, size.height * 0.78);
    final b = Offset(size.width * 0.82, size.height * 0.30);
    final rota = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(size.width * 0.37, a.dy - 20)
      ..lineTo(size.width * 0.37, size.height * 0.5)
      ..lineTo(size.width * 0.6, size.height * 0.45)
      ..lineTo(b.dx, b.dy);
    canvas.drawPath(
      rota,
      Paint()
        ..color = escuro ? AppColors.branco : AppColors.preto
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Origem (círculo) e destino (quadrado), como em apps de mobilidade.
    final contraste = escuro ? AppColors.branco : AppColors.preto;
    final interno = escuro ? AppColors.preto : AppColors.branco;
    canvas.drawCircle(a, 10, Paint()..color = contraste);
    canvas.drawCircle(a, 4, Paint()..color = interno);
    canvas.drawRect(Rect.fromCenter(center: b, width: 18, height: 18), Paint()..color = contraste);
    canvas.drawRect(Rect.fromCenter(center: b, width: 7, height: 7), Paint()..color = interno);

    // Veículos espalhados.
    for (final p in [
      Offset(size.width * 0.55, size.height * 0.70),
      Offset(size.width * 0.12, size.height * 0.35),
      Offset(size.width * 0.9, size.height * 0.68),
    ]) {
      canvas.drawCircle(p, 13, Paint()..color = Colors.black.withValues(alpha: 0.15));
      canvas.drawCircle(p, 11, Paint()..color = AppColors.branco);
      canvas.drawCircle(p, 7, Paint()..color = AppColors.verde);
    }
  }

  @override
  bool shouldRepaint(covariant _MapaPainter old) => old.escuro != escuro;
}
