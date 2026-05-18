import 'package:flutter/material.dart';

class MiEntidadScreen extends StatelessWidget {
  const MiEntidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: const Center(
        child: Text('Mi Entidad — Próximamente',
          style: TextStyle(color: Color(0xFF555555))),
      ),
    );
  }
}
