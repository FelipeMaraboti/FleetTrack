import 'package:flutter/material.dart';

/// Tela 12 - Sobre o projeto e a equipe.
class SobreScreen extends StatelessWidget {
  const SobreScreen({super.key});

  static const integrantes = [
    'Enock de Oliveira Memelli Junio',
    'Felipe Sabino Maraboti',
    'Pedro José Muchelin Acha',
    'Samuel Mota Moysés',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('FleetTrack', style: Theme.of(context).textTheme.headlineMedium),
          const Text('Tema 01 - Mobilidade Urbana & Telemetria'),
          const Text('Computação Móvel • Multivix • AP2B 2026/2'),
          const SizedBox(height: 16),
          Text('Equipe', style: Theme.of(context).textTheme.titleMedium),
          for (final nome in integrantes)
            ListTile(leading: const Icon(Icons.person), title: Text(nome), dense: true),
          const SizedBox(height: 16),
          const Text(
            'Arquitetura Offline-First: a interface lê e grava apenas no SQLite '
            '(fonte única da verdade). O repositório sincroniza as pendências com '
            'a API REST quando há conexão.',
          ),
        ],
      ),
    );
  }
}
