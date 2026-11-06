class Validators {
  static String? required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label khong duoc de trong';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email khong duoc de trong';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Email khong hop le';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Mat khau khong duoc de trong';
    if (v.length < 6) return 'Mat khau toi thieu 6 ky tu';
    return null;
  }
}