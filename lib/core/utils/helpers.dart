import 'dart:math';
import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  static String formatPrice(int price) {
    try {
      return NumberFormat.currency(
          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(price);
    } catch (_) {
      final s = price.toString();
      final buf = StringBuffer('Rp ');
      for (int i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
        buf.write(s[i]);
      }
      return buf.toString();
    }
  }

  static String formatDate(DateTime dt) {
    try { return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt); }
    catch (_) { return _manual(dt, time: true); }
  }

  static String formatDateShort(DateTime dt) {
    try { return DateFormat('d MMM yyyy', 'id_ID').format(dt); }
    catch (_) { return _manual(dt, time: false); }
  }

  static const _m = [
    'Jan','Feb','Mar','Apr','Mei','Jun',
    'Jul','Agu','Sep','Okt','Nov','Des'
  ];

  static String _manual(DateTime dt, {required bool time}) {
    final base = '${dt.day} ${_m[dt.month - 1]} ${dt.year}';
    if (!time) return base;
    return '$base, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }

  // Unique 6-char order code using secure random + timestamp entropy
  static String generateUniqueCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final buf = StringBuffer();
    // 2 chars from timestamp, 4 from secure random
    buf.write(chars[ts % chars.length]);
    buf.write(chars[(ts ~/ 100) % chars.length]);
    for (int i = 0; i < 4; i++) {
      buf.write(chars[rng.nextInt(chars.length)]);
    }
    return buf.toString().toUpperCase();
  }

  static String generateOrderId() {
    final n = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
    return 'ORD-$n';
  }

  static String generateId([String prefix = '']) =>
      '$prefix${DateTime.now().microsecondsSinceEpoch}';

  static String get greeting {
    final h = DateTime.now().hour;
    if (h < 11) return 'Good Morning';
    if (h < 15) return 'Good Afternoon';
    if (h < 18) return 'Good Evening';
    return 'Good Night';
  }

  static String timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inSeconds < 60) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${(d.inDays / 7).floor()}w ago';
  }
}
