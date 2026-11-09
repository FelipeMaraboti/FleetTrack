import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../routes/app_routes.dart';

/// Ícone que indica se o registro já foi enviado à API ou está pendente.
class SyncStatusIcon extends StatelessWidget {
  final bool sincronizado;
  const SyncStatusIcon({super.key, required this.sincronizado});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: sincronizado ? 'Sincronizado' : 'Pendente de envio',
      child: Icon(
        sincronizado ? Icons.cloud_done : Icons.cloud_upload_outlined,
        key: ValueKey(sincronizado ? 'icone-sincronizado' : 'icone-pendente'),
        color: sincronizado ? Colors.green : Colors.orange,
      ),
    );
  }
}

/// Faixa exibida no topo quando o app está em modo offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: deps.modoOffline,
      builder: (context, offline, _) {
        if (!offline) return const SizedBox.shrink();
        return MaterialBanner(
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          leading: const Icon(Icons.wifi_off),
          content: const Text('Modo offline: alterações ficam salvas no aparelho.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.configuracoes),
              child: const Text('AJUSTAR'),
            ),
          ],
        );
      },
    );
  }
}

/// Cartão de métrica do dashboard.
class MetricCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, color: cores.primary, size: 22),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(valor, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: Text(titulo, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de bateria colorida conforme as regras da AP1B (<20% alerta, <=5% crítico).
class BateriaIndicator extends StatelessWidget {
  final double nivel;
  const BateriaIndicator({super.key, required this.nivel});

  @override
  Widget build(BuildContext context) {
    final cor = nivel <= 5
        ? Colors.red
        : nivel < 20
            ? Colors.orange
            : Colors.green;
    return Row(
      children: [
        Icon(Icons.battery_std, color: cor, size: 18),
        const SizedBox(width: 4),
        Expanded(
          child: LinearProgressIndicator(value: (nivel / 100).clamp(0.0, 1.0), color: cor),
        ),
        const SizedBox(width: 8),
        Text('${nivel.toStringAsFixed(0)}%'),
      ],
    );
  }
}

/// Estado vazio padrão para listas.
class EmptyState extends StatelessWidget {
  final String mensagem;
  final IconData icone;
  const EmptyState({super.key, required this.mensagem, this.icone = Icons.inbox});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 8),
            Text(mensagem, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Menu lateral de navegação entre os módulos.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    void ir(String rota) {
      Navigator.pop(context);
      Navigator.pushNamed(context, rota);
    }

    return NavigationDrawer(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 24, 16, 16),
          child: Text('FleetTrack', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        ListTile(leading: const Icon(Icons.directions_car), title: const Text('Veículos'), onTap: () => ir(AppRoutes.veiculos)),
        ListTile(leading: const Icon(Icons.alt_route), title: const Text('Rotas'), onTap: () => ir(AppRoutes.rotas)),
        ListTile(leading: const Icon(Icons.sensors), title: const Text('Telemetria'), onTap: () => ir(AppRoutes.leituras)),
        ListTile(leading: const Icon(Icons.sync), title: const Text('Sincronização'), onTap: () => ir(AppRoutes.sincronizacao)),
        ListTile(leading: const Icon(Icons.settings), title: const Text('Configurações'), onTap: () => ir(AppRoutes.configuracoes)),
        ListTile(leading: const Icon(Icons.info_outline), title: const Text('Sobre'), onTap: () => ir(AppRoutes.sobre)),
      ],
    );
  }
}

/// Exibe uma SnackBar padronizada.
void mostrarMensagem(BuildContext context, String texto, {bool erro = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: erro ? Theme.of(context).colorScheme.error : null,
    ));
}
