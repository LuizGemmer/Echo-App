import 'package:echo/pages/code_reader_page.dart';
import 'package:echo/pages/home_page.dart';
import 'package:echo/pages/product_detail.dart';
import 'package:echo/pages/shopping_cart_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echo App',
      home: HomePage(),
      onGenerateRoute: (settings) {
        if (settings.name == '/DetalheProduto') {
          // Pegando o codBarras passado como argumento
          final String codBarras = settings.arguments as String;

          // Navegando para a página de detalhes com o parâmetro codBarras
          return MaterialPageRoute(
            builder: (context) {
              return ProductDetailsPage(codBarras: codBarras);
            },
          );
        }
        return null;
      },
      routes: {
        "/HomePage": (context) => HomePage(),
        "/CodeReader": (context) => CodeReaderPage(),
        "/CarrinhoDeCompras": (context) => ShoppingCartPage(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
