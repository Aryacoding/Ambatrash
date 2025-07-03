import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';
import 'dashboard.dart';
import 'all_products.dart';
import 'payment.dart';
import 'payment_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMBATRASH',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/all_products': (context) => const AllProductsScreen(),
        // Hapus route '/payment' dari sini karena membutuhkan parameter
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/payment') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder:
                (context) => PaymentScreen(
                  packageName: args['packageName'],
                  packagePrice: args['packagePrice'],
                  customerName: args['customerName'],
                  customerEmail: args['customerEmail'],
                  customerPhone: args['customerPhone'],
                  packageDescription: args['packageDescription'],
                ),
          );
        }
        return null;
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Midtrans Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [PaymentButton()],
        ),
      ),
    );
  }
}
