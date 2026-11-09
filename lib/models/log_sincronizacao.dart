/// Registro histórico de cada tentativa de comunicação com a API.
/// Persistido na tabela `logs_sincronizacao` e exibido na tela de diagnóstico.
class LogSincronizacao {
  final int? id;
  final DateTime dataHora;
  final String entidade; // ROTA | LEITURA | CLIMA
  final String operacao; // POST | DELETE | GET
  final bool sucesso;
  final String mensagem;

  LogSincronizacao({
    this.id,
    DateTime? dataHora,
    required this.entidade,
    required this.operacao,
    required this.sucesso,
    required this.mensagem,
  }) : dataHora = dataHora ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'data_hora': dataHora.toIso8601String(),
        'entidade': entidade,
        'operacao': operacao,
        'sucesso': sucesso ? 1 : 0,
        'mensagem': mensagem,
      };

  factory LogSincronizacao.fromMap(Map<String, dynamic> map) {
    return LogSincronizacao(
      id: map['id'] as int?,
      dataHora: DateTime.tryParse(map['data_hora']?.toString() ?? ''),
      entidade: map['entidade'] as String? ?? 'DESCONHECIDA',
      operacao: map['operacao'] as String? ?? '-',
      sucesso: map['sucesso'] == 1 || map['sucesso'] == true,
      mensagem: map['mensagem'] as String? ?? '',
    );
  }
}
