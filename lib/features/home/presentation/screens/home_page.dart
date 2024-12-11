import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../common/providers/market_provider.dart';
import '/components/custom_navbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _wordsSpoken = "";
  LatLng _usuarioLocalizacao = LatLng(-23.5505, -46.6333);
  User? _usuarioAtual;
  List<QueryDocumentSnapshot> mercadosDisponiveis = [];

  @override
  void initState() {
    super.initState();
    initSpeech();
    _obterUsuarioAtual();
    _obterTodosOsMercados();
    _obterLocalizacaoAtual().then((_) {
      _obterMercadoMaisProximo();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter localização: $error')),
      );
    });
  }

  void _atualizarMercadoManual(
      String nomeMercado, String idMercado, double latitude, double longitude) {
    setState(() {
      _usuarioLocalizacao = LatLng(latitude, longitude);
    });

    Provider.of<MarketProvider>(context, listen: false)
        .updateMarket(nomeMercado, idMercado);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mercado alterado para: $nomeMercado')),
    );
  }

  Future<void> _obterLocalizacaoAtual() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Por favor, habilite o serviço de localização.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Permissão de localização negada permanentemente. Não é possível acessar a localização.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _usuarioLocalizacao = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> _obterTodosOsMercados() async {
    QuerySnapshot mercadosQuery =
        await FirebaseFirestore.instance.collection('empresas').get();

    setState(() {
      mercadosDisponiveis = mercadosQuery.docs;
    });
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: "pt_BR",
    );
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(result) {
    String spokenWords = result.recognizedWords.toLowerCase();
    setState(() {});

    if (spokenWords.contains("scanner")) {
      Navigator.pushNamed(context, '/CodeReader');
    } else if (spokenWords.contains("carrinho")) {
      Navigator.pushNamed(context, '/CarrinhoDeCompras');
    } else if (spokenWords.contains("atualizar mercado")) {
      _obterMercadoMaisProximo();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mercado atualizado!')),
      );
    }
  }

  Future<void> _obterMercadoMaisProximo() async {
    QuerySnapshot mercadosQuery =
        await FirebaseFirestore.instance.collection('empresas').get();

    if (mercadosQuery.docs.isNotEmpty) {
      double menorDistancia = double.infinity;
      String nomeMercadoMaisProximo = "";
      String idMercadoMaisProximo = "";

      for (var doc in mercadosQuery.docs) {
        double lat = doc['latitude'];
        double lng = doc['longitude'];
        double distancia = _calcularDistancia(_usuarioLocalizacao.latitude,
            _usuarioLocalizacao.longitude, lat, lng);

        if (distancia < menorDistancia) {
          menorDistancia = distancia;
          nomeMercadoMaisProximo = doc['nomeFantasia'];
          idMercadoMaisProximo = doc['id'];
        }
      }

      if (mounted) {
        Provider.of<MarketProvider>(context, listen: false)
            .updateMarket(nomeMercadoMaisProximo, idMercadoMaisProximo);
      }
    }
  }

  double _calcularDistancia(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371;
    var dLat = _grausParaRadianos(lat2 - lat1);
    var dLng = _grausParaRadianos(lng2 - lng1);
    var a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_grausParaRadianos(lat1)) *
            cos(_grausParaRadianos(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _grausParaRadianos(double graus) {
    return graus * pi / 180;
  }

  void _obterUsuarioAtual() {
    User? usuario = FirebaseAuth.instance.currentUser;
    setState(() {
      _usuarioAtual = usuario;
    });
  }

  @override
  Widget build(BuildContext context) {
    final marketProvider = Provider.of<MarketProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Echo App"),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFBDBCBC),
        child: Column(
          children: <Widget>[
            CustomNavbar(
              user: _usuarioAtual,
              onLogout: () async {
                await GoogleSignIn().signOut();
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/LoginPage');
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Mercado Atual: ${marketProvider.marketName}',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                'Mercados Disponíveis:',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: mercadosDisponiveis.length,
                itemBuilder: (context, index) {
                  var mercado =
                      mercadosDisponiveis[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(
                      mercado['nomeFantasia'] ?? 'Nome do Mercado',
                      style: const TextStyle(fontSize: 18),
                    ),
                    subtitle: Text(
                      'Localização: ${mercado['endereco'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        _atualizarMercadoManual(
                          mercado['nomeFantasia'],
                          mercado['id'],
                          mercado['latitude'],
                          mercado['longitude'],
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Selecionar',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await _obterLocalizacaoAtual();
                        await _obterMercadoMaisProximo();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Mercado atualizado para o mais próximo!')),
                        );
                      } catch (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Erro ao atualizar mercado: $error')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: const Text(
                      'Atualizar Mercado',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_speechToText.isListening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: Text(
                      _speechToText.isListening ? "Escutando..." : "Microfone",
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/CodeReader');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: const Text(
                      'Abrir Scanner',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/CarrinhoDeCompras');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: const Text(
                      'Abrir Carrinho',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
