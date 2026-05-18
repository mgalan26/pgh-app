import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EntidadDetalleScreen extends StatelessWidget {
  final String id;
  const EntidadDetalleScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFF0E8D8)),
          onPressed: () => context.pop(),
        ),
        title: const Text('Entidad',
          style: TextStyle(color: Color(0xFFF0E8D8))),
      ),
      body: const Center(
        child: Text('Próximamente',
          style: TextStyle(color: Color(0xFF555555))),
      ),
    );
  }
}
