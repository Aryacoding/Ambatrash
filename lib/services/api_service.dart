import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      'http://10.0.2.2:3000/api'; // Replace with your IP or 10.0.2.2 for emulator// Replace with your IP or 10.0.2.2 for emulator

  // Register user
  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      print('Attempting register to $baseUrl/register'); // Debug
      final response = await http
          .post(
            Uri.parse('$baseUrl/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );
      print(
        'Register response: ${response.statusCode} - ${response.body}',
      ); // Debug
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('Register error: $e'); // Debug
      rethrow;
    }
  }

  // Login user
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      print('Attempting login to $baseUrl/login with email: $email'); // Debug
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );
      print(
        'Login response: ${response.statusCode} - ${response.body}',
      ); // Debug
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        return data;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(
          data['message'] ?? 'Login failed with status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Login error: $e'); // Debug
      rethrow;
    }
  }

  // Get JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Get all products
  static Future<List<dynamic>> getProducts() async {
    try {
      print('Fetching products from $baseUrl/products'); // Debug
      final response = await http
          .get(Uri.parse('$baseUrl/products'))
          .timeout(const Duration(seconds: 10));
      print(
        'Products response: ${response.statusCode} - ${response.body}',
      ); // Debug
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Failed to fetch products: ${response.statusCode}');
    } catch (e) {
      print('Products error: $e'); // Debug
      rethrow;
    }
  }

  // Create order
  static Future<Map<String, dynamic>> createOrder({
    required int productId,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String location,
    required String orderId,
    required int amount,
  }) async {
    final token = await getToken();
    try {
      print('Creating order at $baseUrl/orders'); // Debug
      final response = await http
          .post(
            Uri.parse('$baseUrl/orders'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'product_id': productId,
              'customer_name': customerName,
              'customer_email': customerEmail,
              'customer_phone': customerPhone,
              'location': location,
              'order_id': orderId,
              'amount': amount,
            }),
          )
          .timeout(const Duration(seconds: 10));
      print(
        'Order response: ${response.statusCode} - ${response.body}',
      ); // Debug
      return jsonDecode(response.body);
    } catch (e) {
      print('Order error: $e'); // Debug
      rethrow;
    }
  }

  // Update order status
  static Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    String status,
  ) async {
    try {
      print('Updating order status at $baseUrl/orders/$orderId'); // Debug
      final response = await http
          .put(
            Uri.parse('$baseUrl/orders/$orderId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 10));
      print(
        'Update order response: ${response.statusCode} - ${response.body}',
      ); // Debug
      return jsonDecode(response.body);
    } catch (e) {
      print('Update order error: $e'); // Debug
      rethrow;
    }
  }
}
