import 'package:flutter/material.dart';

import '../models/leitura_telemetria.dart';
import '../models/rota.dart';
import '../screens/configuracoes_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/leitura_detalhe_screen.dart';
import '../screens/leitura_form_screen.dart';
import '../screens/leituras_screen.dart';
import '../screens/rota_detalhe_screen.dart';
import '../screens/rota_form_screen.dart';
import '../screens/rotas_screen.dart';
import '../screens/sincronizacao_screen.dart';
import '../screens/sobre_screen.dart';
import '../screens/veiculo_detalhe_screen.dart';
import '../screens/veiculos_screen.dart';

/// Rotas nomeadas do aplicativo (12 telas).
class AppRoutes {
  static const dashboard = '/';
  static const veiculos = '/veiculos';
  static const veiculoDetalhe = '/veiculos/detalhe';
  static const rotas = '/rotas';
  static const rotaForm = '/rotas/form';
  static const rotaDetalhe = '/rotas/detalhe';
  static const leituras = '/leituras';
  static const leituraForm = '/leituras/form';
  static const leituraDetalhe = '/leituras/detalhe';
  static const sincronizacao = '/sincronizacao';
  static const configuracoes = '/configuracoes';
  static const sobre = '/sobre';

  /// Gera a rota validando o TIPO do argumento recebido (passagem segura).
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final Widget tela = switch (settings.name) {
      dashboard => const DashboardScreen(),
      veiculos => const VeiculosScreen(),
      veiculoDetalhe when args is String => VeiculoDetalheScreen(veiculoId: args),
      rotas => const RotasScreen(),
      rotaForm => RotaFormScreen(rotaExistente: args is Rota ? args : null),
      rotaDetalhe when args is String => RotaDetalheScreen(rotaId: args),
      leituras => const LeiturasScreen(),
      leituraForm => LeituraFormScreen(rotaIdInicial: args is String ? args : null),
      leituraDetalhe when args is LeituraTelemetria => LeituraDetalheScreen(leitura: args),
      sincronizacao => const SincronizacaoScreen(),
      configuracoes => const ConfiguracoesScreen(),
      sobre => const SobreScreen(),
      _ => _RotaInvalida(nome: settings.name),
    };
    return MaterialPageRoute(builder: (_) => tela, settings: settings);
  }
}

class _RotaInvalida extends StatelessWidget {
  final String? nome;
  const _RotaInvalida({this.nome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: Center(child: Text('Rota "$nome" inexistente ou argumento inválido.')),
    );
  }
}
