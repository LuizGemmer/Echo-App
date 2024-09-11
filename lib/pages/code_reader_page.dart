import 'package:flutter/material.dart';

class CodeReaderPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Produto'),
      ),
      body: Column(
        children: [
          Placeholder(),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/DetalheProduto');
            }, 
            child: Text("next"),
          )
        ],
      )
    );
  }
}