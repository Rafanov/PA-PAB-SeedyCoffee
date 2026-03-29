import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/env_config.dart';
import '../models/user_model.dart';

class WhatsappService {
  WhatsappService._();
  static final WhatsappService instance = WhatsappService._();

  // Send promo to ALL users who have a phone number in database
  Future<WhatsappResult> sendPromo(
      String message, List<UserModel> allUsers) async {
    // Filter: customer role + has phone
    final recipients = allUsers
        .where((u) => u.role == UserRole.customer &&
            u.phone != null && u.phone!.isNotEmpty)
        .toList();

    if (recipients.isEmpty) {
      return WhatsappResult(success: false, sent: 0,
          failed: 0, message: 'No recipients with phone numbers found');
    }

    final phones = recipients.map((u) => _normalizePhone(u.phone!)).toList();

    if (EnvConfig.useFonnte) {
      return await _sendViaFonnte(message, phones);
    }

    // Demo mode — simulate delay
    await Future.delayed(const Duration(seconds: 2));
    return WhatsappResult(
      success: true, sent: phones.length, failed: 0,
      message: 'Sent to ${phones.length} contacts',
      isDemo: true);
  }

  Future<WhatsappResult> _sendViaFonnte(
      String message, List<String> phones) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.fonnte.com/send'),
        headers: {
          'Authorization': EnvConfig.fonnte,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'target': phones.join(','),
          'message': _format(message),
          'delay': '2',
          'countryCode': '62',
        }),
      );
      if (response.statusCode == 200) {
        return WhatsappResult(
          success: true, sent: phones.length, failed: 0,
          message: 'Sent to ${phones.length} WhatsApp contacts');
      }
      return WhatsappResult(
        success: false, sent: 0, failed: phones.length,
        message: 'Send failed (${response.statusCode})');
    } catch (e) {
      return WhatsappResult(
        success: false, sent: 0, failed: phones.length,
        message: e.toString());
    }
  }

  String _format(String msg) =>
      '📢 *SeedyCoffee Promo!*\n\n$msg\n\n_SeedyCoffee — Premium Coffee ☕_';

  String _normalizePhone(String p) {
    p = p.replaceAll(RegExp(r'\D'), '');
    if (p.startsWith('0')) return '62${p.substring(1)}';
    if (p.startsWith('62')) return p;
    return '62$p';
  }

  String previewMessage(String msg) =>
      msg.isEmpty ? '' : _format(msg);

  bool get isLive => EnvConfig.useFonnte;
}

class WhatsappResult {
  final bool success, isDemo;
  final int sent, failed;
  final String message;
  const WhatsappResult({
    required this.success, required this.sent,
    required this.failed, required this.message,
    this.isDemo = false});
}
