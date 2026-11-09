import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/leitura_telemetria.dart';
import '../widgets/comuns.dart';

/// Tela 9 - Detalhes de uma leitura (recebida como argumento tipado).
class LeituraDetalheScreen extends StatelessWidget {
  final LeituraTelemetria leitura;
  const LeituraDetalheScreen({super.key, required this.leitura});

  @override
  Widget build(BuildContext context) {
    final json = const JsonEncoder.withIndent('  ').convert(leitura.toApiMap());
    return Scaffold(
      appBar: AppBar(title: const Text('Leitura')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: Text(leitura.id),
            subtitle: Text(leitura.sincronizado ? 'Sincronizada com a API' : 'Pendente de envio'),
            trailing: SyncStatusIcon(sincronizado: leitura.sincronizado),
          ),
          ListTile(leading: const Icon(Icons.directions_car), title: const Text('Veículo'), subtitle: Text(leitura.veiculoId)),
          ListTile(leading: const Icon(Icons.alt_route), title: const Text('Rota'), subtitle: Text(leitura.rotaId ?? 'Sem rota')),
          ListTile(
            leading: const Icon(Icons.gps_fixed),
            title: const Text('GPS'),
            subtitle: Text('${leitura.latitude.toStringAsFixed(5)}, ${leitura.longitude.toStringAsFixed(5)}'),
          ),
          ListTile(leading: const Icon(Icons.speed), title: const Text('Velocidade'), subtitle: Text('${leitura.velocidade.toStringAsFixed(1)} km/h')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BateriaIndicator(nivel: leitura.bateria),
          ),
          const SizedBox(height: 16),
          Text('Payload JSON enviado à API', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SelectableText(json, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
