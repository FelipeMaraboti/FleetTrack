import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../exceptions/telemetria_exceptions.dart';
import '../models/rota.dart';
import '../widgets/comuns.dart';

/// Tela 5 - Formulário de cadastro/edição de rota com validação.
class RotaFormScreen extends StatefulWidget {
  final Rota? rotaExistente;
  const RotaFormScreen({super.key, this.rotaExistente});

  @override
  State<RotaFormScreen> createState() => _RotaFormScreenState();
}

class _RotaFormScreenState extends State<RotaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _origem;
  late final TextEditingController _destino;
  late final TextEditingController _distancia;
  late final TextEditingController _tempo;
  late bool _ativa;
  bool _salvando = false;

  bool get _edicao => widget.rotaExistente != null;

  @override
  void initState() {
    super.initState();
    final r = widget.rotaExistente;
    _origem = TextEditingController(text: r?.origem ?? '');
    _destino = TextEditingController(text: r?.destino ?? '');
    _distancia = TextEditingController(text: r?.distanciaKm.toString() ?? '');
    _tempo = TextEditingController(text: r?.tempoEstimadoMinutos.toString() ?? '');
    _ativa = r?.ativa ?? true;
  }

  @override
  void dispose() {
    _origem.dispose();
    _destino.dispose();
    _distancia.dispose();
    _tempo.dispose();
    super.dispose();
  }

  static String? validarTexto(String? valor) => (valor == null || valor.trim().isEmpty) ? 'Campo obrigatório' : null;

  static String? validarNumeroPositivo(String? valor) {
    final numero = double.tryParse((valor ?? '').replaceAll(',', '.'));
    if (numero == null) return 'Informe um número válido';
    if (numero <= 0) return 'Deve ser maior que zero';
    return null;
  }

  double _num(TextEditingController c) => double.parse(c.text.replaceAll(',', '.'));

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _salvando = true);
    try {
      final base = widget.rotaExistente;
      final rota = base == null
          ? Rota(
              id: 'ROTA-${DateTime.now().millisecondsSinceEpoch}',
              origem: _origem.text.trim(),
              destino: _destino.text.trim(),
              distanciaKm: _num(_distancia),
              tempoEstimadoMinutos: _num(_tempo),
              ativa: _ativa,
            )
          : base.copyWith(
              origem: _origem.text.trim(),
              destino: _destino.text.trim(),
              distanciaKm: _num(_distancia),
              tempoEstimadoMinutos: _num(_tempo),
              ativa: _ativa,
            );
      final salva = await AppScope.of(context).rotas.salvar(rota);
      if (!mounted) return;
      mostrarMensagem(context, salva.sincronizado ? 'Rota salva e sincronizada.' : 'Rota salva offline (pendente de envio).');
      Navigator.pop(context, true);
    } on RotaInvalidaException catch (e) {
      mostrarMensagem(context, e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_edicao ? 'Editar rota' : 'Nova rota')),
      body: Form(
        key: _formKey,
        // Coluna (não-preguiçosa): todos os campos existem e são validados.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_edicao ? 'Ajuste o trajeto' : 'Para onde vamos?', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('Informe a origem, o destino e a estimativa da viagem.', style: Theme.of(context).textTheme.bodySmall),
              const SecaoTitulo('Trajeto'),
              TextFormField(
                key: const Key('campo-origem'),
                controller: _origem,
                decoration: const InputDecoration(labelText: 'Origem', prefixIcon: Icon(Icons.radio_button_checked)),
                validator: validarTexto,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('campo-destino'),
                controller: _destino,
                decoration: const InputDecoration(labelText: 'Destino', prefixIcon: Icon(Icons.stop)),
                validator: validarTexto,
                textInputAction: TextInputAction.next,
              ),
              const SecaoTitulo('Estimativa'),
              TextFormField(
                key: const Key('campo-distancia'),
                controller: _distancia,
                decoration: const InputDecoration(labelText: 'Distância (km)', prefixIcon: Icon(Icons.straighten)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: validarNumeroPositivo,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('campo-tempo'),
                controller: _tempo,
                decoration: const InputDecoration(labelText: 'Tempo estimado (min)', prefixIcon: Icon(Icons.timer)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: validarNumeroPositivo,
              ),
              const SizedBox(height: 16),
              SwitchLinha(
                icone: Icons.toggle_on_outlined,
                titulo: 'Rota ativa',
                subtitulo: 'Rotas inativas não recebem novos veículos.',
                valor: _ativa,
                onChanged: (v) => setState(() => _ativa = v),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BarraAcao(
        child: FilledButton.icon(
          key: const Key('botao-salvar-rota'),
          onPressed: _salvando ? null : _salvar,
          icon: const Icon(Icons.check),
          label: Text(_edicao ? 'Salvar alterações' : 'Salvar'),
        ),
      ),
    );
  }
}
