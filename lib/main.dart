import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/config/firebase_options.dart';
import 'package:echo/features/common/providers/market_provider.dart';
import 'package:echo/features/home/presentation/screens/home_page.dart';
import 'package:echo/features/code_reader/presentation/screens/code_reader_page.dart';
import 'package:echo/features/products/presentation/screens/product_detail_page.dart';
import 'package:echo/features/shopping_cart/presentation/screens/shopping_cart_page.dart';
import 'package:echo/features/auth/presentation/screens/login_page.dart';
import 'package:echo/features/home/presentation/screens/tutorial_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Erro ao inicializar o Firebase: $e");
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MarketProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echo App',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return const TutorialPage();
          } else {
            return const LoginPage();
          }
        },
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/DetalheProduto') {
          final String codBarras = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) {
              return ProductDetailsPage(codBarras: codBarras);
            },
          );
        }
        return null;
      },
      routes: {
        "/HomePage": (context) => const HomePage(),
        "/CodeReader": (context) => CodeReaderPage(),
        "/CarrinhoDeCompras": (context) => ShoppingCartPage(),
        "/LoginPage": (context) => const LoginPage(),
        "/TutorialPage": (context) => const TutorialPage(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
