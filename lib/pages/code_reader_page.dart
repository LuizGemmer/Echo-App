import 'package:flutter/material.dart';

class CodeReaderPage extends StatefulWidget {
  @override
  _CodeReaderPageState createState() => _CodeReaderPageState();
}

class _CodeReaderPageState extends State<CodeReaderPage> {
  final TextEditingController _barcodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inserir Código de Barras'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'Código de Barras',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final codBarras =
                    _barcodeController.text.trim(); // Remover espaços em branco
                if (codBarras.isNotEmpty) {
                  Navigator.pushNamed(
                    context,
                    '/DetalheProduto',
                    arguments: codBarras,
                  );
                }
              },
              child: Text('Ver Detalhes do Produto'),
            ),
          ],
        ),
      ),
    );
  }
}
