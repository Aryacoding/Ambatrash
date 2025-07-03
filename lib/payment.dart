import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'midtrans_service.dart';
import 'services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final String packageName;
  final String packagePrice;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String? packageDescription;

  const PaymentScreen({
    super.key,
    required this.packageName,
    required this.packagePrice,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.packageDescription,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  String? _snapUrl;
  String? _errorMessage;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
    _initializePayment();
  }

  Future<void> _initializeWebViewController() async {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final webViewController = WebViewController.fromPlatformCreationParams(
      params,
    );

    if (webViewController.platform is AndroidWebViewController) {
      await (webViewController.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _webViewController =
        webViewController
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (request) {
                if (request.url.contains('status_code=200')) {
                  _updateOrderStatus();
                  _showPaymentSuccessDialog();
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
            ),
          );

    setState(() {});
  }

  Future<void> _initializePayment() async {
    try {
      _orderId = MidtransService.generateOrderId();
      final amount = int.parse(widget.packagePrice.replaceAll('.', ''));

      final response = await MidtransService.createTransaction(
        orderId: _orderId!,
        grossAmount: amount,
        customerName: widget.customerName,
        customerEmail: widget.customerEmail,
        customerPhone: widget.customerPhone,
      );

      if (response.containsKey('redirect_url')) {
        setState(() {
          _snapUrl = response['redirect_url'];
        });
        await _webViewController.loadRequest(Uri.parse(_snapUrl!));
      } else {
        throw Exception('No redirect URL received from Midtrans');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus() async {
    try {
      await ApiService.updateOrderStatus(_orderId!, 'completed');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menyiapkan pembayaran...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            const Text(
              'Gagal memproses pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 24),
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

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Pembayaran Berhasil'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
                const SizedBox(height: 16),
                Text('Paket: ${widget.packageName}'),
                const SizedBox(height: 8),
                Text('Total: Rp ${widget.packagePrice}'),
                const SizedBox(height: 16),
                const Text('Terima kasih telah menggunakan layanan kami!'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Selesai'),
              ),
            ],
          ),
    );
  }
}
