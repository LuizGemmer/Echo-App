import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../common/providers/market_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/components/custom_navbar.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ProductDetailsPage extends StatefulWidget {
  final String codBarras;

  ProductDetailsPage({required this.codBarras});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _textToSpeech = FlutterTts();

  User? _usuarioAtual;

  @override
  void initState() {
    super.initState();
    initSpeech();
    _obterUsuarioAtual();
    _verificarEAnunciarProduto();
  }

  void initSpeech() async {
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: _onSpeechResult,
      localeId: "pt_BR",
    );
  }

  void _verificarEAnunciarProduto() async {
    final marketId =
        Provider.of<MarketProvider>(context, listen: false).marketId;

    try {
      var produto = await buscarProdutoPorCodBarras(widget.codBarras, marketId);
      if (produto != null) {
        var produtoData = produto.data() as Map<String, dynamic>;
        _speakProductDetailsNoDescription(produtoData);
      } else {
        _textToSpeech.setLanguage('pt-BR');
        _textToSpeech.speak('Produto não encontrado');
      }
    } catch (e) {
      print('Erro ao verificar e anunciar produto: $e');
    }
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(result) async {
    String spokenWords = result.recognizedWords.toLowerCase();
    setState(() {});

    final marketId =
        Provider.of<MarketProvider>(context, listen: false).marketId;

    if (spokenWords.contains("scanner")) {
      Navigator.pushNamed(context, '/CodeReader');
    } else if (spokenWords.contains("carrinho")) {
      Navigator.pushNamed(context, '/CarrinhoDeCompras');
    } else if (spokenWords.contains("adicionar produto")) {
      var produto = await buscarProdutoPorCodBarras(widget.codBarras, marketId);
      if (produto != null) {
        adicionarProdutoAoCarrinho(
            produto.data() as Map<String, dynamic>, marketId);
      }
    } else if (spokenWords.contains("remover produto")) {
      removerProdutoDoCarrinho(widget.codBarras, marketId);
    }
  }

  void _speakProductDetailsNoDescription(Map<String, dynamic> productData) {
    String name = productData['nomeProduto'] ?? 'Desconhecido';
    String description = productData['descricao'] ?? 'Desconhecido';
    String price =
        (double.tryParse(productData['preco'] ?? '0')?.toStringAsFixed(2) ??
            '0.00');

    String speechText = "Produto encontrado. Nome: $name. Preço: R\$ $price.";

    _textToSpeech.setLanguage('pt-BR');
    _textToSpeech.setSpeechRate(0.75);
    _textToSpeech.speak(speechText);
  }

  void _speakProductDetails(Map<String, dynamic> productData) {
    String name = productData['nomeProduto'] ?? 'Desconhecido';
    String description = productData['descricao'] ?? 'Desconhecido';
    String price =
        (double.tryParse(productData['preco'] ?? '0')?.toStringAsFixed(2) ??
            '0.00');

    String speechText =
        "Nome: $name. Preço: R\$ $price. Descrição: $description.";

    _textToSpeech.setLanguage('pt-BR');
    _textToSpeech.setSpeechRate(0.75);
    _textToSpeech.speak(speechText);
  }

  Future<DocumentSnapshot?> buscarProdutoPorCodBarras(
      String codBarras, String marketId) async {
    try {
      QuerySnapshot produtosQuery = await FirebaseFirestore.instance
          .collection('empresas')
          .doc(marketId)
          .collection('produtos')
          .where('codBarras', isEqualTo: codBarras)
          .limit(1)
          .get();
      if (produtosQuery.docs.isNotEmpty) {
        return produtosQuery.docs.first;
      } else {
        return null;
      }
    } catch (e) {
      print('Erro ao buscar produto: $e');
      return null;
    }
  }

  Future<void> adicionarProdutoAoCarrinho(
      Map<String, dynamic> produto, String marketId) async {
    try {
      var carrinhoQuery = await FirebaseFirestore.instance
          .collection('produtosCarrinho')
          .where('codBarras', isEqualTo: produto['codBarras'])
          .where('marketId', isEqualTo: marketId)
          .limit(1)
          .get();
      if (carrinhoQuery.docs.isNotEmpty) {
        var produtoCarrinho = carrinhoQuery.docs.first;
        await FirebaseFirestore.instance
            .collection('produtosCarrinho')
            .doc(produtoCarrinho.id)
            .update({
          'quantidade': produtoCarrinho['quantidade'] + 1,
        });
      } else {
        produto['quantidade'] = 1;
        produto['marketId'] = marketId;
        produto['uid'] = FirebaseAuth.instance.currentUser?.uid;
        await FirebaseFirestore.instance
            .collection('produtosCarrinho')
            .add(produto);
      }
      print('Produto adicionado ao carrinho com sucesso');
    } catch (e) {
      print('Erro ao adicionar produto ao carrinho: $e');
    }
  }

  Future<void> removerProdutoDoCarrinho(
      String codBarras, String marketId) async {
    try {
      var carrinhoQuery = await FirebaseFirestore.instance
          .collection('produtosCarrinho')
          .where('codBarras', isEqualTo: codBarras)
          .where('marketId', isEqualTo: marketId)
          .limit(1)
          .get();
      if (carrinhoQuery.docs.isNotEmpty) {
        var produtoCarrinho = carrinhoQuery.docs.first;
        await FirebaseFirestore.instance
            .collection('produtosCarrinho')
            .doc(produtoCarrinho.id)
            .delete();
        print('Produto removido do carrinho');
      }
    } catch (e) {
      print('Erro ao remover produto do carrinho: $e');
    }
  }

  void _obterUsuarioAtual() {
    User? usuario = FirebaseAuth.instance.currentUser;
    setState(() {
      _usuarioAtual = usuario;
    });
  }

  @override
  Widget build(BuildContext context) {
    final marketId = Provider.of<MarketProvider>(context).marketId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Produto'),
      ),
      backgroundColor: Color(0xFFBDBCBC),
      body: Column(
        children: <Widget>[
          CustomNavbar(
            user: _usuarioAtual,
            onLogout: () async {
              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/LoginPage');
            },
          ),
          Expanded(
            child: FutureBuilder<DocumentSnapshot?>(
              future: buscarProdutoPorCodBarras(widget.codBarras, marketId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                        'Ocorreu um erro ao buscar o produto: ${snapshot.error}'),
                  );
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    if (!snapshot.hasData || snapshot.data == null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Produto não encontrado',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    else ...[
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildProductDetails(snapshot.data!),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                var produtoData = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                _speakProductDetails(produtoData);
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
                                'Ouvir Detalhes do Produto',
                                style: TextStyle(
                                    fontSize: 20, color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: snapshot.data != null &&
                                        snapshot.data!.data() != null
                                    ? () {
                                        var produtoData = snapshot.data!.data()
                                            as Map<String, dynamic>;
                                        adicionarProdutoAoCarrinho(
                                            produtoData, marketId);
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                child: Text(
                                  'Adicionar Produto',
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.black),
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
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.black),
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
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                child: Text(
                                  'Scanner',
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.black),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, '/CarrinhoDeCompras');
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
                                  'Carrinho',
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProductDetails(DocumentSnapshot produto) {
    final data = produto.data() as Map<String, dynamic>;
    return [
      Text(
        'Nome:',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 8),
      Text(
        produto['nomeProduto'] ?? 'Desconhecido',
        style: TextStyle(fontSize: 22),
      ),
      SizedBox(height: 16),
      Text(
        'Preço:',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 8),
      Text(
        'R\$ ${(double.tryParse(data['preco'] ?? '0')?.toStringAsFixed(2) ?? '0.00')}',
        style: TextStyle(fontSize: 22),
      ),
      SizedBox(height: 16),
      Text(
        'Descrição:',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      Text(
        produto['descricao'] ?? 'Desconhecido',
        style: TextStyle(fontSize: 22),
      ),
      SizedBox(height: 16),
    ];
  }
}
