/// Construit un lien wa.me à partir d'un numéro stocké au format E.164
/// (`+261341234567`, format retourné par `IntlPhoneField` à
/// l'inscription — voir registration_screen.dart) : wa.me n'accepte que
/// des chiffres, sans le `+` ni espaces/tirets éventuels.
String? buildWhatsAppLink(String? phone) {
  if (phone == null) return null;
  final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isEmpty) return null;
  return 'https://wa.me/$digitsOnly';
}
