import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'midtrans_service.dart';

class PaymentPage extends StatefulWidget {
  final String packageName;
  final int packagePrice;
  final String customerName;
  final String customerEmail;
  final String customerPhone;

  const PaymentPage({
    super.key,
    required this.packageName,
    required this.packagePrice,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  String? _snapUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize the WebViewController
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (navigation) {
                if (navigation.url.contains('status_code=200')) {
                  Navigator.of(context).pop(true);
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          );

    _initializePayment();
  }

  Future<void> _initializePayment() async {
    try {
      final orderId = MidtransService.generateOrderId();

      final response = await MidtransService.createTransaction(
        orderId: orderId,
        grossAmount: widget.packagePrice,
        customerName: widget.customerName,
        customerEmail: widget.customerEmail,
        customerPhone: widget.customerPhone,
      );

      setState(() {
        _snapUrl = response['redirect_url'];
        _isLoading = false;
      });

      if (_snapUrl != null) {
        await _webViewController.loadRequest(Uri.parse(_snapUrl!));
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 50),
            const SizedBox(height: 20),
            Text(
              'Gagal memuat pembayaran',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializePayment,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return WebViewWidget(controller: _webViewController);
  }
}
