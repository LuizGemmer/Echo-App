import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomNavbar extends StatelessWidget {
  final User? user;
  final VoidCallback onLogout;

  const CustomNavbar({Key? key, required this.user, required this.onLogout})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF8C8C8C),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              user != null
                  ? 'Olá, ${user!.displayName ?? 'Usuário'}'
                  : 'Olá, Visitante',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.logout,
                color: Colors.white,
                size: 30,
              ),
              onPressed: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}
