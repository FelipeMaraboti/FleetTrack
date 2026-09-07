import 'veiculo.dart';

/// Representa um veículo com motor a combustão interna monitorado pela frota.
class CarroCombustao extends Veiculo {
  final double capacidadeTanqueLitros;
  double nivelCombustivelLitros;
  final double consumoMedioKmL;

  CarroCombustao({
    required super.id,
    required super.modelo,
    super.nivelBateria,
    super.conectado,
    super.velocidadeAtual,
    super.rotaAtualId,
    super.ultimaAtualizacao,
    this.capacidadeTanqueLitros = 50.0,
    double? nivelCombustivelLitros,
    this.consumoMedioKmL = 11.5,
  }) : nivelCombustivelLitros =
           (nivelCombustivelLitros ?? capacidadeTanqueLitros).clamp(
             0.0,
             capacidadeTanqueLitros,
           );

  /// Processamento polimórfico de carga de trabalho para veículos a combustão.
  /// Consome combustível conforme a intensidade do percurso e gera dreno na bateria auxiliar (12V).
  @override
  void processarCargaTrabalho(double intensidade) {
    if (intensidade <= 0) return;

    final litrosConsumidos = intensidade * 1.8;
    nivelCombustivelLitros = (nivelCombustivelLitros - litrosConsumidos).clamp(
      0.0,
      capacidadeTanqueLitros,
    );

    final drenoBateria = intensidade * 2.5;
    nivelBateria = (nivelBateria - drenoBateria).clamp(0.0, 100.0);
  }

  @override
  String toString() {
    return '[COMBUSTÃO] ${super.toString()} | Tanque: ${nivelCombustivelLitros.toStringAsFixed(1)}/${capacidadeTanqueLitros.toStringAsFixed(0)} L | Consumo: ${consumoMedioKmL.toStringAsFixed(1)} km/L';
  }
}
