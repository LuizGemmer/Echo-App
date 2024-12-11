import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/components/custom_navbar.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _textToSpeech = FlutterTts();

  bool _speechEnabled = false;
  String _wordsSpoken = "";
  User? _usuarioAtual;

  @override
  void initState() {
    super.initState();
    initSpeech();
    _obterUsuarioAtual();
    _lerTutorialAoAbrir();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _lerTutorialAoAbrir() async {
    String texto =
        "Bem-vindo ao Echo App! Utilize o botão de microfone para comandos de voz. "
        "O botão azul sempre se refere ao microfone. "
        "Pressione o microfone e diga 'avançar' para continuar para a próxima página.";

    await _textToSpeech.setLanguage("pt-BR");
    await _textToSpeech.setSpeechRate(0.75);
    await _textToSpeech.speak(texto);
  }

  void _ouvirDetalhes() async {
    String texto =
        "Bem-vindo ao Echo App! Utilize o botão de microfone para comandos de voz. "
        "O botão azul sempre se refere ao microfone. "
        "Pressione o microfone e diga 'avançar' para continuar para a próxima página.";
    await _textToSpeech.speak(texto);
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

    if (spokenWords.contains("avançar")) {
      Navigator.pushNamed(context, '/HomePage');
    } else if (spokenWords.contains("ouvir detalhes")) {
      _ouvirDetalhes();
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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo ao Echo App! '
                    '                       ',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Utilize o botão de microfone para comandos de voz. ',
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'O botão azul sempre se refere ao microfone.',
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Pressione o microfone e diga "avançar" para continuar para a próxima página.',
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _ouvirDetalhes,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: const Text(
                      'Ouvir Detalhes',
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
                    onPressed: () async {
                      Navigator.pushNamed(context, '/HomePage');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero),
                    ),
                    child: const Text(
                      'Avançar',
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
                      style: const TextStyle(fontSize: 20, color: Colors.black),
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
