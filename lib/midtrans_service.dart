import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MidtransService {
  static const String _sandboxUrl = 'https://app.sandbox.midtrans.com/snap/v1';
  static const String _serverKey =
      'SB-Mid-server-BNBW0SVbCzix9EgtRlUmaTQB'; // Ganti dengan sandbox key Anda

  static Future<Map<String, dynamic>> createTransaction({
    required String orderId,
    required int grossAmount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_sandboxUrl/transactions'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_serverKey:'))}',
        },
        body: jsonEncode({
          "transaction_details": {
            "order_id": orderId,
            "gross_amount": grossAmount,
          },
          "credit_card": {"secure": true},
          "customer_details": {
            "first_name": customerName.split(' ')[0],
            "last_name":
                customerName.split(' ').length > 1
                    ? customerName.split(' ').sublist(1).join(' ')
                    : '',
            "email": customerEmail,
            "phone": customerPhone,
          },
          "callbacks": {
            "finish": "https://yourwebsite.com/finish", // Callback URL
          },
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to create transaction: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error connecting to Midtrans: $e');
    }
  }

  static String generateOrderId() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMddHHmmss');
    return 'AMBATRASH-${formatter.format(now)}-${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }
}
