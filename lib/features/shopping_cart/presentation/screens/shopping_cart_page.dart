import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../common/providers/market_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/components/custom_navbar.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ShoppingCartPage extends StatefulWidget {
  @override
  _ShoppingCartPageState createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _textToSpeech = FlutterTts();
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    initSpeech();
    _lerTotalAoAbrir();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _ouvirDetalhes(double totalCarrinho) async {
    String texto = '${totalCarrinho.toStringAsFixed(2)} reais';
    await _textToSpeech.speak(texto);
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult, localeId: "pt_BR");
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(result) async {
    String spokenWords = result.recognizedWords.toLowerCase();
    final marketId =
        Provider.of<MarketProvider>(context, listen: false).marketId;

    if (spokenWords.contains("scanner")) {
      Navigator.pushNamed(context, '/CodeReader');
    } else if (spokenWords.contains("remover todos")) {
      removerTodosProdutos(marketId);
    } else if (spokenWords.contains("ouvir detalhes")) {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('produtosCarrinho')
            .where('marketId', isEqualTo: marketId)
            .where('uid', isEqualTo: userId)
            .get();

        var produtos = querySnapshot.docs;
        double totalCarrinho = calcularTotal(produtos);

        _ouvirDetalhes(totalCarrinho);
      }
    }
  }

  void _lerTotalAoAbrir() async {
    final marketId =
        Provider.of<MarketProvider>(context, listen: false).marketId;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('produtosCarrinho')
          .where('marketId', isEqualTo: marketId)
          .where('uid', isEqualTo: userId)
          .get();

      var produtos = querySnapshot.docs;
      double totalCarrinho = calcularTotal(produtos);

      _ouvirDetalhes(totalCarrinho);
    }
  }

  double calcularTotal(List<DocumentSnapshot> produtos) {
    double total = 0;
    for (var doc in produtos) {
      var produto = doc.data() as Map<String, dynamic>;
      double preco = double.tryParse(produto['preco'].toString()) ?? 0;
      int quantidade = produto['quantidade'] ?? 1;
      total += preco * quantidade;
    }
    return double.parse(total.toStringAsFixed(2));
  }

  void incrementarQuantidade(String docId, int quantidadeAtual) {
    FirebaseFirestore.instance
        .collection('produtosCarrinho')
        .doc(docId)
        .update({
      'quantidade': quantidadeAtual + 1,
    });
  }

  void decrementarQuantidade(String docId, int quantidadeAtual) {
    if (quantidadeAtual > 1) {
      FirebaseFirestore.instance
          .collection('produtosCarrinho')
          .doc(docId)
          .update({
        'quantidade': quantidadeAtual - 1,
      });
    } else {
      FirebaseFirestore.instance
          .collection('produtosCarrinho')
          .doc(docId)
          .delete();
    }
  }

  void removerTodosProdutos(String marketId) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      FirebaseFirestore.instance
          .collection('produtosCarrinho')
          .where('marketId', isEqualTo: marketId)
          .where('uid', isEqualTo: userId)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.delete();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketId = Provider.of<MarketProvider>(context).marketId;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Carrinho de Compras'),
      ),
      backgroundColor: Color(0xFFBDBCBC),
      body: Column(
        children: [
          CustomNavbar(
            user: user,
            onLogout: () async {
              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/LoginPage');
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('produtosCarrinho')
                  .where('marketId', isEqualTo: marketId)
                  .where('uid',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                        'Ocorreu um erro ao carregar o carrinho: ${snapshot.error}'),
                  );
                }

                var produtos = snapshot.data?.docs ?? [];
                double totalCarrinho = calcularTotal(produtos);

                return Column(
                  children: [
                    Expanded(
                        child: produtos.isEmpty
                            ? Center(child: Text('Carrinho está vazio'))
                            : ListView.builder(
                                itemCount: produtos.length,
                                itemBuilder: (context, index) {
                                  var produto = produtos[index].data()
                                      as Map<String, dynamic>;
                                  return ListTile(
                                    title: Text(
                                      produto['nomeProduto'] ??
                                          'Nome do Produto',
                                      style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Preço: R\$ ${produto['preco'] ?? 'N/A'}',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          Text(
                                            'Quantidade: ${produto['quantidade'] ?? 1}',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove, size: 30),
                                          onPressed: () {
                                            decrementarQuantidade(
                                                produtos[index].id,
                                                produto['quantidade']);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.add, size: 30),
                                          onPressed: () {
                                            incrementarQuantidade(
                                                produtos[index].id,
                                                produto['quantidade']);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, size: 30),
                                          onPressed: () {
                                            FirebaseFirestore.instance
                                                .collection('produtosCarrinho')
                                                .doc(produtos[index].id)
                                                .delete();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Total: R\$ $totalCarrinho',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _ouvirDetalhes(totalCarrinho),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              backgroundColor: Colors.amber,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero),
                            ),
                            child: const Text(
                              'Ouvir Detalhes',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.black),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _speechToText.isListening
                                ? _stopListening
                                : _startListening,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(vertical: 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                            child: Text(
                              _speechToText.isListening
                                  ? 'Escutando...'
                                  : 'Microfone',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                );
              },
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/CodeReader');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        'Scanner',
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        removerTodosProdutos(marketId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        'Remover Todos',
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
