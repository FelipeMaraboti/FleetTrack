import '../exceptions/telemetria_exceptions.dart';
import '../mixins/log_auditoria_mixin.dart';
import '../models/leitura_telemetria.dart';
import '../models/veiculo.dart';

/// Serviço responsável pelo processamento de fluxos de telemetria, detecção de anomalias,
/// alertas de segurança e registro de auditoria via mixin.
class ServicoTelemetria with LogAuditoriaMixin {
  /// Processa diretamente uma leitura recebida de sensor.
  /// Aplica regras de negócio críticas de telemetria.
  void processarLeitura(LeituraTelemetria leitura, Veiculo veiculo) {
    if (leitura.veiculoId != veiculo.id) {
      throw DadosTelemetriaInvalidosException(
        'Inconsistência de telemetria: Leitura do veículo "${leitura.veiculoId}" enviada para instância "${veiculo.id}".',
      );
    }

    veiculo.atualizarEstado(
      velocidade: leitura.velocidade,
      bateria: leitura.bateria,
      statusConexao: leitura.conectado,
    );

    if (!leitura.conectado) {
      registrarLog(
        'Veículo ${veiculo.id} (${veiculo.modelo}) perdeu conexão com a central de monitoramento.',
      );
    }

    if (leitura.bateria <= 5.0) {
      throw RecursoCriticoException(
        'Bateria insuficiente no veículo ${veiculo.id} (${leitura.bateria.toStringAsFixed(1)}%). Parada de emergência obrigatória!',
        leitura.bateria,
      );
    }

    if (leitura.bateria < 20.0) {
      print(
          '   [ALERTA] ${veiculo.id} está com bateria baixa (${leitura.bateria.toStringAsFixed(1)}%).');
    }
  }

  /// Processa a leitura de telemetria demonstrando os blocos estruturados
  /// try, on, catch, finally e o comando rethrow para propagação de exceção.
  void processarComAuditoria(LeituraTelemetria leitura, Veiculo veiculo) {
    try {
      processarLeitura(leitura, veiculo);
    } on RecursoCriticoException catch (e) {
      registrarLog(
        'CRÍTICO: Exceção de recurso capturada no veículo ${veiculo.id}. Propagando via rethrow. Detalhes: ${e.mensagem}',
      );
      rethrow;
    } on DadosTelemetriaInvalidosException catch (e) {
      registrarLog(
        'ERRO DE DADOS: Dados inválidos no veículo ${veiculo.id}: ${e.mensagem}',
      );
      rethrow;
    } catch (e) {
      registrarLog('ERRO INESPERADO no veículo ${veiculo.id}: $e');
      rethrow;
    } finally {
      registrarLog(
        'Ciclo de telemetria finalizado para o veículo ${veiculo.id}.',
      );
    }
  }
}
