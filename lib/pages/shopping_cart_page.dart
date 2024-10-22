import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ShoppingCartPage extends StatefulWidget {
  @override
  _ShoppingCartPageState createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

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
    await _speechToText.listen(onResult: _onSpeechResult, localeId: "pt_BR");
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(result) async {
    String spokenWords = result.recognizedWords.toLowerCase();

    if (spokenWords.contains("scanner")) {
      Navigator.pushNamed(context, '/CodeReader');
    } else if (spokenWords.contains("remover todos")) {
      removerTodosProdutos();
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
    return total;
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

  void removerTodosProdutos() {
    FirebaseFirestore.instance
        .collection('produtosCarrinho')
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carrinho de Compras'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('produtosCarrinho')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                  'Ocorre um erro ao carregar o carrinho: ${snapshot.error}'),
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
                          var produto =
                              produtos[index].data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(
                                produto['nomeProduto'] ?? 'Nome do Produto'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Preço: R\$ ${produto['preco'] ?? 'N/A'}'),
                                Text(
                                    'Quantidade: ${produto['quantidade'] ?? 1}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    decrementarQuantidade(produtos[index].id,
                                        produto['quantidade']);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    incrementarQuantidade(produtos[index].id,
                                        produto['quantidade']);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
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
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total: R\$ $totalCarrinho',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão do Microfone
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _speechToText.isListening
                          ? _stopListening
                          : _startListening,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 80),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        _speechToText.isListening
                            ? 'Escutando...'
                            : 'Microfone',
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
                            removerTodosProdutos();
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
                            'Remover Todos',
                            style: TextStyle(fontSize: 20),
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
    );
  }
}
