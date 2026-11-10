import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/carro_eletrico.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/comuns.dart';

/// Tela 2 - Lista de veículos da frota (domínio AP1B).
class VeiculosScreen extends StatelessWidget {
  const VeiculosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final veiculos = AppScope.of(context).frota.obterTodos();
    return Scaffold(
      appBar: AppBar(title: const Text('Veículos')),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: veiculos.length,
              separatorBuilder: (_, __) => const SizedBox.shrink(),
              itemBuilder: (context, i) {
                final v = veiculos[i];
                final eletrico = v is CarroEletrico;
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.veiculoDetalhe, arguments: v.id),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconTile(
                            icone: eletrico ? Icons.electric_car : Icons.local_gas_station,
                            cor: eletrico ? AppColors.verde : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(v.modelo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(v.id, style: Theme.of(context).textTheme.bodySmall),
                                    const SizedBox(width: 8),
                                    StatusPill(
                                      texto: v.conectado ? 'ONLINE' : 'OFFLINE',
                                      cor: v.conectado ? AppColors.verde : AppColors.cinza500,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                BateriaIndicator(nivel: v.nivelBateria),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
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
