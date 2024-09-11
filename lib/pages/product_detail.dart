import 'package:flutter/material.dart';

class ProductDetailsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Produto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Placeholder(),
            SizedBox(height: 20),
            Text(
              'Stick onebyone FIT SPORT da SPIN',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Mais vida e Sabor ao seu pet com o novo Stick onebyone™ FIT SPORT™ da Spin™, um petisco que contém proteína de alta qualidade...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      )
    );
  }
}