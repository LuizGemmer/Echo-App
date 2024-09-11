import 'package:flutter/material.dart';

class ShoppingCartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carrinho de Compras'),
      ),
      body: ListView.builder(
        itemCount: 3,
        itemBuilder: (_, index) => 
          Text("data"),
      )
    );
  }
}