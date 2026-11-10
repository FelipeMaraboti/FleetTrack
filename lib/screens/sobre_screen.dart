import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/comuns.dart';

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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const DestaqueCard(
            sobretitulo: 'Tema 01 · Mobilidade Urbana & Telemetria',
            titulo: 'FleetTrack',
            trailing: Icon(Icons.local_shipping, size: 32),
            children: [
              Text('Computação Móvel · Multivix · AP2B 2026/2', style: TextStyle(color: AppColors.cinza300)),
            ],
          ),
          const SecaoTitulo('Equipe'),
          Bloco(children: [
            for (final nome in integrantes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.preto,
                      child: Text(nome[0], style: const TextStyle(color: AppColors.branco, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Text(nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                  ],
                ),
              ),
          ]),
          const SecaoTitulo('Arquitetura'),
          Bloco(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Arquitetura Offline-First: a interface lê e grava apenas no SQLite '
                '(fonte única da verdade). O repositório sincroniza as pendências com '
                'a API REST quando há conexão.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
