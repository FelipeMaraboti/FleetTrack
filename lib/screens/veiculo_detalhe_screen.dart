import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../exceptions/telemetria_exceptions.dart';
import '../models/carro_combustao.dart';
import '../models/carro_eletrico.dart';
import '../models/condicao_clima.dart';
import '../models/leitura_telemetria.dart';
import '../widgets/comuns.dart';

/// Tela 3 - Detalhes do veículo + última leitura (SQLite) + clima (Open-Meteo).
class VeiculoDetalheScreen extends StatefulWidget {
  final String veiculoId;
  const VeiculoDetalheScreen({super.key, required this.veiculoId});

  @override
  State<VeiculoDetalheScreen> createState() => _VeiculoDetalheScreenState();
}

class _VeiculoDetalheScreenState extends State<VeiculoDetalheScreen> {
  LeituraTelemetria? _ultima;
  CondicaoClima? _clima;
  String? _erroClima;
  bool _carregandoClima = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _carregar();
  }

  Future<void> _carregar() async {
    final leituras = await AppScope.of(context).telemetria.listar();
    final doVeiculo = leituras.where((l) => l.veiculoId == widget.veiculoId);
    if (!mounted) return;
    setState(() => _ultima = doVeiculo.isEmpty ? null : doVeiculo.first);
  }

  Future<void> _consultarClima() async {
    final ultima = _ultima;
    // Sem leitura própria, usa a coordenada padrão (Cachoeiro de Itapemirim/ES).
    final lat = ultima?.latitude ?? -20.8489;
    final lng = ultima?.longitude ?? -41.1129;
    setState(() {
      _carregandoClima = true;
      _erroClima = null;
    });
    try {
      final clima = await AppScope.of(context).clima.obterClima(lat, lng);
      setState(() => _clima = clima);
    } on RedeIndisponivelException catch (e) {
      setState(() => _erroClima = 'Sem conexão e sem cache: ${e.mensagem}');
    } on SincronizacaoException catch (e) {
      setState(() => _erroClima = e.toString());
    } finally {
      if (mounted) setState(() => _carregandoClima = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final veiculo = AppScope.of(context).frota.buscarPorIdOuNull(widget.veiculoId);
    if (veiculo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Veículo')),
        body: const EmptyState(mensagem: 'Veículo não encontrado.'),
      );
    }

    final ultima = _ultima;
    final clima = _clima;
    return Scaffold(
      appBar: AppBar(title: Text(veiculo.modelo)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(veiculo.id, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  BateriaIndicator(nivel: veiculo.nivelBateria),
                  const SizedBox(height: 8),
                  Text('Status: ${veiculo.conectado ? 'ONLINE' : 'OFFLINE'}'),
                  Text('Velocidade: ${veiculo.velocidadeAtual.toStringAsFixed(0)} km/h'),
                  Text('Rota atual: ${veiculo.rotaAtualId ?? 'Sem rota atribuída'}'),
                  if (veiculo is CarroEletrico)
                    Text('Autonomia: ${veiculo.autonomiaRestanteKm.toStringAsFixed(0)} km (${veiculo.capacidadeBateriaKwh.toStringAsFixed(0)} kWh)'),
                  if (veiculo is CarroCombustao)
                    Text('Tanque: ${veiculo.nivelCombustivelLitros.toStringAsFixed(1)} / ${veiculo.capacidadeTanqueLitros.toStringAsFixed(0)} L'),
                ],
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.gps_fixed),
              title: const Text('Última leitura registrada'),
              subtitle: Text(ultima == null
                  ? 'Nenhuma leitura salva para este veículo.'
                  : '(${ultima.latitude.toStringAsFixed(4)}, ${ultima.longitude.toStringAsFixed(4)}) • ${ultima.velocidade.toStringAsFixed(0)} km/h'),
              trailing: ultima == null ? null : SyncStatusIcon(sincronizado: ultima.sincronizado),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Clima no local (Open-Meteo)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_carregandoClima) const LinearProgressIndicator(),
                  if (clima != null)
                    Text('${clima.descricao} • ${clima.temperatura.toStringAsFixed(1)} °C • vento ${clima.ventoKmh.toStringAsFixed(0)} km/h'
                        '${clima.doCache ? '\n(dados do cache local - offline)' : ''}'),
                  if (_erroClima != null) Text(_erroClima!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: _carregandoClima ? null : _consultarClima,
                    icon: const Icon(Icons.cloud),
                    label: const Text('Consultar clima'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
