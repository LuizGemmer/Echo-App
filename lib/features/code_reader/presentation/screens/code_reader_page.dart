import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class CodeReaderPage extends StatefulWidget {
  @override
  _CodeReaderPageState createState() => _CodeReaderPageState();
}

class _CodeReaderPageState extends State<CodeReaderPage> {
  @override
  void initState() {
    super.initState();
    _startBarcodeScan();
  }

  Future<void> _startBarcodeScan() async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Cancelar',
        true,
        ScanMode.BARCODE,
      );

      if (barcodeScanRes != '-1') {
        Navigator.pushNamed(
          context,
          '/DetalheProduto',
          arguments: barcodeScanRes,
        );
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao ler código de barras: $e')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leitor de Código de Barras'),
      ),
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
