import 'package:flutter/material.dart';

class RegistroUsuarioScreen extends StatelessWidget {
  const RegistroUsuarioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: const Center(
        child: Text('Registro Usuario — Próximamente',
          style: TextStyle(color: Color(0xFF555555))),
      ),
    );
  }
}
