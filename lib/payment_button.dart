import 'package:flutter/material.dart';
import 'payment_page.dart';

class PaymentButton extends StatelessWidget {
  const PaymentButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => PaymentPage(
                  packageName: 'Paket Premium',
                  packagePrice: 150000,
                  customerName: 'John Doe',
                  customerEmail: 'john.doe@example.com',
                  customerPhone: '081234567890',
                ),
          ),
        );

        if (result == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Pembayaran berhasil!')));
        }
      },
      child: const Text('Test Midtrans Payment'),
    );
  }
}
