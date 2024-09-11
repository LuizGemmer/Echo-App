import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Echo App'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              children: [
                Text('Clique para escanear o produto'),
                SizedBox(height: 16),
                IconButton(
                  icon: Icon(Icons.qr_code_scanner, size: 100),
                  onPressed: () {
                    Navigator.pushNamed(context, '/CodeReader');
                  },
                ),
              ],
            ),
            Column(
              children: [
                Text('Clique para Acessar o Carrinho'),
                SizedBox(height: 16),
                IconButton(
                  icon: Icon(Icons.shopping_basket, size: 100),
                  onPressed: () {
                    Navigator.pushNamed(context, '/CarrinhoDeCompras');
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}