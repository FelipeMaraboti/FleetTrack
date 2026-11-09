import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../models/carro_eletrico.dart';
import '../routes/app_routes.dart';
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
            child: ListView.builder(
              itemCount: veiculos.length,
              itemBuilder: (context, i) {
                final v = veiculos[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: Icon(v is CarroEletrico ? Icons.electric_car : Icons.local_gas_station),
                    title: Text(v.modelo),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${v.id} • ${v.conectado ? 'ONLINE' : 'OFFLINE'}'),
                        BateriaIndicator(nivel: v.nivelBateria),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.veiculoDetalhe, arguments: v.id),
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
