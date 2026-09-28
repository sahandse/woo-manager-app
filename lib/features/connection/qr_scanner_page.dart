import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatefulWidget { const QrScannerPage({super.key}); @override State<QrScannerPage> createState()=>_QrScannerPageState(); }
class _QrScannerPageState extends State<QrScannerPage>{bool handled=false;@override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('اسکن QR فروشگاه')),body:MobileScanner(onDetect:(capture){if(handled)return;final value=capture.barcodes.firstOrNull?.rawValue;if(value==null)return;final uri=Uri.tryParse(value);if(uri==null||!['http','https'].contains(uri.scheme))return;handled=true;Navigator.pop(context,value);}),);}
