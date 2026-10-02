import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ProductBarcodeScannerPage extends StatefulWidget {
  const ProductBarcodeScannerPage({super.key});
  @override
  State<ProductBarcodeScannerPage> createState() => _ProductBarcodeScannerPageState();
}

class _ProductBarcodeScannerPageState extends State<ProductBarcodeScannerPage> {
  bool handled = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('اسکن بارکد محصول')),
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              onDetect: (capture) {
                if (handled || capture.barcodes.isEmpty) return;
                final value = capture.barcodes.first.rawValue?.trim();
                if (value == null || value.isEmpty) return;
                handled = true;
                Navigator.pop(context, value);
              },
            ),
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 260,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 24,
              right: 24,
              bottom: 36,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('بارکد را داخل کادر قرار بده؛ بعد از تشخیص به فرم محصول برمی‌گردی.', textAlign: TextAlign.center),
                ),
              ),
            ),
          ],
        ),
      );
}
