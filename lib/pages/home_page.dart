import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _wordsSpoken = ""; // Exibe o texto falado

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
      localeId: "pt_BR", // Define o idioma para português do Brasil
    );
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  // Função que trata o comando de voz
  void _onSpeechResult(result) {
    String spokenWords = result.recognizedWords.toLowerCase();
    setState(() {
      _wordsSpoken = spokenWords; // Exibe o texto falado
    });

    // Verifica os comandos de navegação
    if (spokenWords.contains("scanner")) {
      Navigator.pushNamed(context, '/CodeReader'); // Navega para o Scanner
    } else if (spokenWords.contains("carrinho")) {
      Navigator.pushNamed(
          context, '/CarrinhoDeCompras'); // Navega para o Carrinho
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Echo App'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Spacer(), // Empurra os botões para baixo

          // Botão do Microfone (Azul)
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _speechToText.isListening
                  ? _stopListening
                  : _startListening, // Usa o microfone para comandos de voz
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 100), // Botão mais alto
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // Quinas quadradas
                ),
              ),
              child: Text(
                _speechToText.isListening ? 'Escutando...' : 'Microfone',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),

          // Botões Scanner e Carrinho (Metade da tela cada)
          Row(
            children: [
              // Botão Scanner (Vermelho)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                        context, '/CodeReader'); // Função original
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.black,
                    padding:
                        EdgeInsets.symmetric(vertical: 100), // Botão mais alto
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Quinas quadradas
                    ),
                  ),
                  child: Text(
                    'Scanner',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),

              // Botão Carrinho (Verde)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                        context, '/CarrinhoDeCompras'); // Função original
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.black,
                    padding:
                        EdgeInsets.symmetric(vertical: 100), // Botão mais alto
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Quinas quadradas
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
}
