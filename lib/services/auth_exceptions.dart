/// Excepcion lanzada cuando el backend responde 401 a una request autenticada.
/// Se usa como senal para que la UI redirija al login y muestre un mensaje al
/// usuario.
class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException([
    this.message = 'Tu sesion expiro. Inicia sesion nuevamente.',
  ]);

  @override
  String toString() => message;
}

/// El comprador intenta abrir chat en su propia oferta (validacion del backend).
class ChatCannotMessageSelfException implements Exception {
  const ChatCannotMessageSelfException();

  @override
  String toString() => 'No puedes chatear contigo mismo en tu propia oferta.';
}
