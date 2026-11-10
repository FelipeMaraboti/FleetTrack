import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../exceptions/telemetria_exceptions.dart';
import '../models/leitura_telemetria.dart';
import '../models/rota.dart';
import '../widgets/comuns.dart';

/// Tela 8 - Formulário de nova leitura de telemetria.
/// Reaproveita as regras de domínio da AP1B (validação de GPS/bateria e
/// alerta de recurso crítico via ServicoTelemetria).
class LeituraFormScreen extends StatefulWidget {
  final String? rotaIdInicial;
  const LeituraFormScreen({super.key, this.rotaIdInicial});

  @override
  State<LeituraFormScreen> createState() => _LeituraFormScreenState();
}

class _LeituraFormScreenState extends State<LeituraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _latitude = TextEditingController(text: '-20.8489');
  final _longitude = TextEditingController(text: '-41.1129');
  final _velocidade = TextEditingController();
  final _bateria = TextEditingController();

  String? _veiculoId;
  String? _rotaId;
  bool _conectado = true;
  bool _salvando = false;
  List<Rota> _rotas = [];

  @override
  void initState() {
    super.initState();
    _rotaId = widget.rotaIdInicial;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppScope.of(context).rotas.listar().then((rotas) {
      if (mounted) setState(() => _rotas = rotas);
    });
  }

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    _velocidade.dispose();
    _bateria.dispose();
    super.dispose();
  }

  static String? Function(String?) validarFaixa(double min, double max) {
    return (valor) {
      final numero = double.tryParse((valor ?? '').replaceAll(',', '.'));
      if (numero == null) return 'Informe um número válido';
      if (numero < min || numero > max) return 'Valor deve estar entre $min e $max';
      return null;
    };
  }

  double _num(TextEditingController c) => double.parse(c.text.replaceAll(',', '.'));

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final deps = AppScope.of(context);
    setState(() => _salvando = true);

    try {
      final leitura = LeituraTelemetria(
        veiculoId: _veiculoId!,
        rotaId: _rotaId,
        latitude: _num(_latitude),
        longitude: _num(_longitude),
        velocidade: _num(_velocidade),
        bateria: _num(_bateria),
        conectado: _conectado,
      );

      // Regras de negócio da AP1B: atualiza o estado do veículo em memória.
      String? alertaCritico;
      final veiculo = deps.frota.buscarPorIdOuNull(leitura.veiculoId);
      if (veiculo != null) {
        try {
          deps.servicoTelemetria.processarComAuditoria(leitura, veiculo);
        } on RecursoCriticoException catch (e) {
          alertaCritico = e.mensagem;
        }
      }

      // Persistência Offline-First (a leitura é salva mesmo se for crítica).
      final salva = await deps.telemetria.registrar(leitura);
      if (!mounted) return;

      if (alertaCritico != null) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.warning_amber, color: Colors.red),
            title: const Text('Recurso crítico'),
            content: Text(alertaCritico!),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
        if (!mounted) return;
      } else if (leitura.bateria < 20) {
        mostrarMensagem(context, 'Alerta: bateria baixa (${leitura.bateria.toStringAsFixed(0)}%).', erro: true);
      }

      mostrarMensagem(context, salva.sincronizado ? 'Leitura enviada para a central.' : 'Leitura salva offline (pendente).');
      Navigator.pop(context, true);
    } on DadosTelemetriaInvalidosException catch (e) {
      mostrarMensagem(context, e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final veiculos = AppScope.of(context).frota.obterTodos();
    final rotaValida = _rotas.any((r) => r.id == _rotaId) ? _rotaId : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Nova leitura')),
      body: Form(
        key: _formKey,
        // Coluna (não-preguiçosa): todos os campos existem e são validados.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Registrar telemetria', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('A leitura é salva no aparelho e enviada quando houver conexão.', style: Theme.of(context).textTheme.bodySmall),
              const SecaoTitulo('Veículo e rota'),
              DropdownButtonFormField<String>(
                key: const Key('campo-veiculo'),
                initialValue: _veiculoId,
                decoration: const InputDecoration(labelText: 'Veículo', prefixIcon: Icon(Icons.directions_car)),
                items: [
                  for (final v in veiculos)
                    DropdownMenuItem(value: v.id, child: Text('${v.id} - ${v.modelo}', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _veiculoId = v),
                validator: (v) => v == null ? 'Selecione um veículo' : null,
                isExpanded: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: ValueKey('campo-rota-$rotaValida-${_rotas.length}'),
                initialValue: rotaValida,
                decoration: const InputDecoration(labelText: 'Rota (opcional)', prefixIcon: Icon(Icons.alt_route)),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Sem rota')),
                  for (final r in _rotas)
                    DropdownMenuItem<String?>(value: r.id, child: Text('${r.id} - ${r.origem}', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _rotaId = v),
                isExpanded: true,
              ),
              const SecaoTitulo('Posição GPS'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitude,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: validarFaixa(-90, 90),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitude,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      validator: validarFaixa(-180, 180),
                    ),
                  ),
                ],
              ),
              const SecaoTitulo('Sensores'),
              TextFormField(
                key: const Key('campo-velocidade'),
                controller: _velocidade,
                decoration: const InputDecoration(labelText: 'Velocidade (km/h)', prefixIcon: Icon(Icons.speed)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: validarFaixa(0, 300),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('campo-bateria'),
                controller: _bateria,
                decoration: const InputDecoration(labelText: 'Bateria (%)', prefixIcon: Icon(Icons.battery_std)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: validarFaixa(0, 100),
              ),
              const SizedBox(height: 16),
              SwitchLinha(
                icone: Icons.sensors,
                titulo: 'Sensor conectado',
                valor: _conectado,
                onChanged: (v) => setState(() => _conectado = v),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BarraAcao(
        child: FilledButton.icon(
          key: const Key('botao-salvar-leitura'),
          onPressed: _salvando ? null : _salvar,
          icon: const Icon(Icons.check),
          label: const Text('Registrar leitura'),
        ),
      ),
    );
  }
}
