import 'package:flutter/material.dart';
//import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatelessWidget {
  //final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Bem-vindo ao Alia Inclui',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  //await _googleSignIn.signIn();
                  Navigator.pushReplacementNamed(context, '/home');
                } catch (error) {
                  print(error);
                }
              },
              child: Text('Login com Google'),
            ),
          ],
        ),
      ),
    );
  }
}