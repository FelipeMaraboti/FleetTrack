import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

/// Ícone que indica se o registro já foi enviado à API ou está pendente.
class SyncStatusIcon extends StatelessWidget {
  final bool sincronizado;
  const SyncStatusIcon({super.key, required this.sincronizado});

  @override
  Widget build(BuildContext context) {
    final cor = sincronizado ? AppColors.verde : AppColors.laranja;
    return Tooltip(
      message: sincronizado ? 'Sincronizado' : 'Pendente de envio',
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(
          sincronizado ? Icons.cloud_done : Icons.cloud_upload_outlined,
          key: ValueKey(sincronizado ? 'icone-sincronizado' : 'icone-pendente'),
          color: cor,
          size: 18,
        ),
      ),
    );
  }
}

/// Faixa compacta exibida no topo quando o app está em modo offline.
class OfflineBanner extends StatelessWidget {
  final EdgeInsets margem;
  const OfflineBanner({super.key, this.margem = const EdgeInsets.fromLTRB(16, 4, 16, 8)});

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: deps.modoOffline,
      builder: (context, offline, _) {
        if (!offline) return const SizedBox.shrink();
        return Padding(
          padding: margem,
          child: Material(
            color: AppColors.preto,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pushNamed(context, AppRoutes.configuracoes),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.laranja, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Modo offline: alterações ficam salvas no aparelho.',
                        style: TextStyle(color: AppColors.branco, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Text('AJUSTAR', style: TextStyle(color: AppColors.branco, fontWeight: FontWeight.w800, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
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
  final Color? destaque;

  const MetricCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icone,
    this.onTap,
    this.destaque,
  });

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: destaque ?? cores.primary, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icone, color: AppColors.branco, size: 18),
                  ),
                  const Spacer(),
                  if (onTap != null) Icon(Icons.arrow_forward, size: 18, color: cores.onSurfaceVariant),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(valor, style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
                  ),
                  const SizedBox(height: 2),
                  Text(titulo, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
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
        ? AppColors.vermelho
        : nivel < 20
            ? AppColors.laranja
            : AppColors.verde;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: (nivel / 100).clamp(0.0, 1.0), color: cor, minHeight: 6),
          ),
        ),
        const SizedBox(width: 10),
        Text('${nivel.toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.w700, color: cor, fontSize: 13)),
      ],
    );
  }
}

/// Pequena etiqueta em formato de pílula.
class StatusPill extends StatelessWidget {
  final String texto;
  final Color cor;
  const StatusPill({super.key, required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
      child: Text(texto, style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
    );
  }
}

/// Avatar quadrado arredondado com ícone (estilo lista de viagens).
class IconTile extends StatelessWidget {
  final IconData icone;
  final Color? cor;
  const IconTile({super.key, required this.icone, this.cor});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: cores.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
      child: Icon(icone, color: cor ?? cores.onSurface),
    );
  }
}

/// Título de seção em negrito.
class SecaoTitulo extends StatelessWidget {
  final String texto;
  final Widget? acao;
  const SecaoTitulo(this.texto, {super.key, this.acao});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
      child: Row(
        children: [
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.titleLarge)),
          if (acao != null) acao!,
        ],
      ),
    );
  }
}

/// Linha "rótulo / valor" com ícone, estilo recibo de viagem.
class InfoLinha extends StatelessWidget {
  final IconData icone;
  final String rotulo;
  final String valor;
  final Widget? trailing;
  const InfoLinha({super.key, required this.icone, required this.rotulo, required this.valor, this.trailing});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: cores.surface, borderRadius: BorderRadius.circular(10)),
            child: Icon(icone, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rotulo, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(valor, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Cartão de seção com fundo cinza e conteúdo em coluna.
class Bloco extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  const Bloco({super.key, required this.children, this.padding = const EdgeInsets.fromLTRB(16, 6, 16, 6)});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}

/// Cartão preto de destaque (topo das telas de detalhe).
class DestaqueCard extends StatelessWidget {
  final String sobretitulo;
  final String titulo;
  final Widget? trailing;
  final List<Widget> children;
  const DestaqueCard({super.key, required this.sobretitulo, required this.titulo, this.trailing, this.children = const []});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.preto, borderRadius: BorderRadius.circular(20)),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: AppColors.branco),
        child: IconTheme.merge(
          data: const IconThemeData(color: AppColors.branco),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sobretitulo.toUpperCase(),
                            style:
                                const TextStyle(color: AppColors.cinza300, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                        const SizedBox(height: 6),
                        Text(titulo, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.15)),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              if (children.isNotEmpty) const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador numérico usado dentro do [DestaqueCard].
class DestaqueValor extends StatelessWidget {
  final String valor;
  final String rotulo;
  const DestaqueValor({super.key, required this.valor, required this.rotulo});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valor, style: const TextStyle(color: AppColors.branco, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(rotulo, style: const TextStyle(color: AppColors.cinza300, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Trajeto origem (círculo) → destino (quadrado).
class TrajetoOD extends StatelessWidget {
  final String origem;
  final String destino;
  final Color? cor;
  const TrajetoOD({super.key, required this.origem, required this.destino, this.cor});

  @override
  Widget build(BuildContext context) {
    final c = cor ?? Theme.of(context).colorScheme.onSurface;
    final linha = c.withValues(alpha: 0.35);
    TextStyle estilo(bool principal) => TextStyle(color: c, fontSize: principal ? 17 : 17, fontWeight: FontWeight.w700);
    return Row(
      children: [
        Column(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c, width: 3))),
            Container(width: 2, height: 30, color: linha),
            Container(width: 12, height: 12, color: c),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(origem, style: estilo(true), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 22),
              Text(destino, style: estilo(false), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

/// Barra fixa no rodapé com o botão de ação principal.
class BarraAcao extends StatelessWidget {
  final Widget child;
  const BarraAcao({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cores.surface,
        border: Border(top: BorderSide(color: cores.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(top: false, child: SizedBox(width: double.infinity, child: child)),
    );
  }
}

/// Linha com switch dentro de um bloco.
class SwitchLinha extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final IconData icone;
  final bool valor;
  final ValueChanged<bool> onChanged;
  const SwitchLinha({super.key, required this.titulo, this.subtitulo, required this.icone, required this.valor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        secondary: Icon(icone),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitulo == null ? null : Text(subtitulo!),
        value: valor,
        onChanged: onChanged,
      ),
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
    final cores = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: cores.surfaceContainerHigh, shape: BoxShape.circle),
              child: Icon(icone, size: 40, color: cores.onSurface),
            ),
            const SizedBox(height: 16),
            Text(mensagem, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
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

    Widget item(IconData icone, String titulo, String rota) => ListTile(
          leading: Icon(icone),
          title: Text(titulo),
          onTap: () => ir(rota),
        );

    return NavigationDrawer(
      children: [
        Container(
          color: AppColors.preto,
          padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 28, 24, 24),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.cinza800,
                child: Icon(Icons.local_shipping, color: AppColors.branco),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FleetTrack', style: TextStyle(color: AppColors.branco, fontSize: 22, fontWeight: FontWeight.w800)),
                    SizedBox(height: 2),
                    Text('Gestão de frota', style: TextStyle(color: AppColors.cinza300, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        item(Icons.directions_car, 'Veículos', AppRoutes.veiculos),
        item(Icons.alt_route, 'Rotas', AppRoutes.rotas),
        item(Icons.sensors, 'Telemetria', AppRoutes.leituras),
        item(Icons.sync, 'Sincronização', AppRoutes.sincronizacao),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Divider()),
        item(Icons.settings_outlined, 'Configurações', AppRoutes.configuracoes),
        item(Icons.info_outline, 'Sobre', AppRoutes.sobre),
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
      backgroundColor: erro ? AppColors.vermelho : null,
    ));
}
