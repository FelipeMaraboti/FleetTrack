import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/leitura_telemetria.dart';
import '../theme/app_theme.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          DestaqueCard(
            sobretitulo: leitura.sincronizado ? 'Sincronizada com a API' : 'Pendente de envio',
            titulo: leitura.id,
            trailing: SyncStatusIcon(sincronizado: leitura.sincronizado),
            children: [
              Row(
                children: [
                  DestaqueValor(valor: leitura.velocidade.toStringAsFixed(0), rotulo: 'km/h'),
                  DestaqueValor(valor: '${leitura.bateria.toStringAsFixed(0)}%', rotulo: 'Bateria'),
                  DestaqueValor(valor: leitura.conectado ? 'Sim' : 'Não', rotulo: 'Sensor conectado'),
                ],
              ),
            ],
          ),
          const SecaoTitulo('Detalhes'),
          Bloco(children: [
            InfoLinha(icone: Icons.directions_car, rotulo: 'Veículo', valor: leitura.veiculoId),
            InfoLinha(icone: Icons.alt_route, rotulo: 'Rota', valor: leitura.rotaId ?? 'Sem rota'),
            InfoLinha(
              icone: Icons.gps_fixed,
              rotulo: 'GPS',
              valor: '${leitura.latitude.toStringAsFixed(5)}, ${leitura.longitude.toStringAsFixed(5)}',
            ),
            InfoLinha(icone: Icons.speed, rotulo: 'Velocidade', valor: '${leitura.velocidade.toStringAsFixed(1)} km/h'),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 12),
              child: BateriaIndicator(nivel: leitura.bateria),
            ),
          ]),
          const SecaoTitulo('Payload JSON enviado à API'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cinza800, borderRadius: BorderRadius.circular(16)),
            child: SelectableText(json, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFFB8F5CF))),
          ),
        ],
      ),
    );
  }
}
