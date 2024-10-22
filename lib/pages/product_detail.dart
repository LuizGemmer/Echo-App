import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ProductDetailsPage extends StatefulWidget {
  final String codBarras;

  ProductDetailsPage({required this.codBarras});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _wordsSpoken = "";

  @override
  void initState() {
    super.initState();
    initSpeech();
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

  void _onSpeechResult(result) async {
    String spokenWords = result.recognizedWords.toLowerCase();
    setState(() {
      _wordsSpoken = spokenWords;
    });

    if (spokenWords.contains("scanner")) {
      Navigator.pushNamed(context, '/CodeReader');
    } else if (spokenWords.contains("carrinho")) {
      Navigator.pushNamed(context, '/CarrinhoDeCompras');
    } else if (spokenWords.contains("adicionar produto")) {
      var produto = await buscarProdutoPorCodBarras(widget.codBarras);
      if (produto != null) {
        adicionarProdutoAoCarrinho(produto.data() as Map<String, dynamic>);
      }
    } else if (spokenWords.contains("remover produto")) {
      removerProdutoDoCarrinho(widget.codBarras);
    }
  }

  Future<DocumentSnapshot?> buscarProdutoPorCodBarras(String codBarras) async {
    try {
      String empresaId = 'a7e1a458-168e-4874-a4c2-2f187bef64a6';
      QuerySnapshot produtosQuery = await FirebaseFirestore.instance
          .collection('empresas')
          .doc(empresaId)
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

  Future<void> adicionarProdutoAoCarrinho(Map<String, dynamic> produto) async {
    try {
      var carrinhoQuery = await FirebaseFirestore.instance
          .collection('produtosCarrinho')
          .where('codBarras', isEqualTo: produto['codBarras'])
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
        await FirebaseFirestore.instance
            .collection('produtosCarrinho')
            .add(produto);
      }
      print('Produto adicionado ao carrinho com sucesso');
    } catch (e) {
      print('Erro ao adicionar produto ao carrinho: $e');
    }
  }

  Future<void> removerProdutoDoCarrinho(String codBarras) async {
    try {
      var carrinhoQuery = await FirebaseFirestore.instance
          .collection('produtosCarrinho')
          .where('codBarras', isEqualTo: codBarras)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Produto'),
      ),
      body: FutureBuilder<DocumentSnapshot?>(
        future: buscarProdutoPorCodBarras(widget.codBarras),
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

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Código de Barras: ${widget.codBarras}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                if (!snapshot.hasData || snapshot.data == null)
                  Text(
                    'Produto não encontrado',
                    style: TextStyle(fontSize: 16),
                  )
                else ...[
                  ..._buildProductDetails(snapshot.data!),
                  SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        var produtoData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        adicionarProdutoAoCarrinho(produtoData);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        'Adicionar ao Carrinho',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _speechToText.isListening ? _stopListening : _startListening,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 80),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                _speechToText.isListening ? 'Escutando...' : 'Microfone',
                style: TextStyle(fontSize: 24),
              ),
            ),
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
                    padding: EdgeInsets.symmetric(vertical: 80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    'Scanner',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/CarrinhoDeCompras');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                    'Carrinho',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProductDetails(DocumentSnapshot produtoSnapshot) {
    var produtoData = produtoSnapshot.data() as Map<String, dynamic>?;

    if (produtoData == null) {
      return [
        Text(
          'Produto não encontrado',
          style: TextStyle(fontSize: 16),
        ),
      ];
    }

    return [
      Text(
        produtoData['nomeProduto'] ?? 'Nome do Produto',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 10),
      Text(
        produtoData['descricao'] ?? 'Descrição do produto',
        style: TextStyle(fontSize: 18),
      ),
      SizedBox(height: 20),
      Text(
        'Preço: R\$ ${produtoData['preco'] ?? 'N/A'}',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    ];
  }
}
