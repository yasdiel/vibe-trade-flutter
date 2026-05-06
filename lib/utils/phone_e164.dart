/// Normaliza [dialCode] (ej. `+53` o `53`) y dígitos nacionales en E.164
/// (siempre con `+` y sin espacios).
String buildE164Phone(String dialCode, String nationalDigits) {
  final national = nationalDigits.replaceAll(RegExp(r'\D'), '');
  var dial = dialCode.trim();
  if (dial.startsWith('+')) {
    dial = dial.substring(1);
  }
  dial = dial.replaceAll(RegExp(r'\D'), '');
  return '+$dial$national';
}
