import 'package:echo/pages/code_reader_page.dart';
import 'package:echo/pages/home_page.dart';
import 'package:echo/pages/product_detail.dart';
import 'package:echo/pages/shopping_cart_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echo App',
      home: HomePage(),
      routes: {
        "/HomePage": (context) => HomePage(),
        "/CodeReader": (context) => CodeReaderPage(),
        "/DetalheProduto": (context) => ProductDetailsPage(),
        "/CarrinhoDeCompras": (context) => ShoppingCartPage()
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}