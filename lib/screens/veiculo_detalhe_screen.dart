import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../exceptions/telemetria_exceptions.dart';
import '../models/carro_combustao.dart';
import '../models/carro_eletrico.dart';
import '../models/condicao_clima.dart';
import '../models/leitura_telemetria.dart';
import '../theme/app_theme.dart';
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          DestaqueCard(
            sobretitulo: '${veiculo.id} · ${veiculo is CarroEletrico ? 'Elétrico' : 'Combustão'}',
            titulo: veiculo.modelo,
            trailing: StatusPill(
              texto: veiculo.conectado ? 'ONLINE' : 'OFFLINE',
              cor: veiculo.conectado ? AppColors.verde : AppColors.cinza300,
            ),
            children: [
              Row(
                children: [
                  DestaqueValor(valor: '${veiculo.nivelBateria.toStringAsFixed(0)}%', rotulo: 'Bateria'),
                  DestaqueValor(valor: veiculo.velocidadeAtual.toStringAsFixed(0), rotulo: 'km/h agora'),
                  if (veiculo is CarroEletrico)
                    DestaqueValor(valor: veiculo.autonomiaRestanteKm.toStringAsFixed(0), rotulo: 'km de autonomia'),
                  if (veiculo is CarroCombustao)
                    DestaqueValor(valor: veiculo.nivelCombustivelLitros.toStringAsFixed(0), rotulo: 'litros no tanque'),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: (veiculo.nivelBateria / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  color: veiculo.nivelBateria < 20 ? AppColors.laranja : AppColors.verde,
                  backgroundColor: AppColors.cinza800,
                ),
              ),
            ],
          ),
          const SecaoTitulo('Informações'),
          Bloco(children: [
            InfoLinha(icone: Icons.alt_route, rotulo: 'Rota atual', valor: veiculo.rotaAtualId ?? 'Sem rota atribuída'),
            if (veiculo is CarroEletrico)
              InfoLinha(
                  icone: Icons.bolt, rotulo: 'Capacidade da bateria', valor: '${veiculo.capacidadeBateriaKwh.toStringAsFixed(0)} kWh'),
            if (veiculo is CarroCombustao)
              InfoLinha(
                icone: Icons.local_gas_station,
                rotulo: 'Tanque',
                valor: '${veiculo.nivelCombustivelLitros.toStringAsFixed(1)} / ${veiculo.capacidadeTanqueLitros.toStringAsFixed(0)} L',
              ),
            InfoLinha(
              icone: Icons.gps_fixed,
              rotulo: 'Última leitura registrada',
              valor: ultima == null
                  ? 'Nenhuma leitura salva para este veículo.'
                  : '${ultima.latitude.toStringAsFixed(4)}, ${ultima.longitude.toStringAsFixed(4)} · ${ultima.velocidade.toStringAsFixed(0)} km/h',
              trailing: ultima == null ? null : SyncStatusIcon(sincronizado: ultima.sincronizado),
            ),
          ]),
          const SecaoTitulo('Clima no local'),
          Bloco(
            padding: const EdgeInsets.all(16),
            children: [
              if (clima != null) ...[
                Row(
                  children: [
                    Text('${clima.temperatura.toStringAsFixed(0)}°',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(clima.descricao, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          Text('Vento ${clima.ventoKmh.toStringAsFixed(0)} km/h', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (clima.doCache) const StatusPill(texto: 'CACHE', cor: AppColors.laranja),
                  ],
                ),
                const SizedBox(height: 16),
              ] else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Consulte a previsão do Open-Meteo para a última posição do veículo.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
              if (_carregandoClima) ...[
                ClipRRect(borderRadius: BorderRadius.circular(99), child: const LinearProgressIndicator(minHeight: 4)),
                const SizedBox(height: 12),
              ],
              if (_erroClima != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_erroClima!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _carregandoClima ? null : _consultarClima,
                  icon: const Icon(Icons.cloud_outlined),
                  label: Text(clima == null ? 'Consultar clima' : 'Atualizar clima'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
