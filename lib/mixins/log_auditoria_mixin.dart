/// Mixin responsável por fornecer funcionalidade transversal de auditoria
/// para componentes do sistema FleetTrack.
mixin LogAuditoriaMixin {
  /// Registra uma mensagem de auditoria formatada no console com timestamp atual.
  void registrarLog(String mensagem) {
    final timestamp = DateTime.now().toIso8601String();
    print('[AUDITORIA TELEMETRIA - $timestamp] $mensagem');
  }
}
