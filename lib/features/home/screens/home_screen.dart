import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pgh_app/core/router.dart';
import 'package:pgh_app/core/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              // Logo / cabecera
              Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFC9A84C), Color(0xFF8B6914)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Text('P',
                        style: TextStyle(
                          color: Color(0xFF0D0D0D),
                          fontWeight: FontWeight.bold,
                          fontSize: 32)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('PARLAMENTO GLOBAL HISPANO',
                    style: TextStyle(
                      color: AppTheme.goldColor,
                      fontSize: 11,
                      letterSpacing: 3)),
                  const SizedBox(height: 8),
                  const Text('Agenda de Eventos',
                    style: TextStyle(
                      color: Color(0xFFF0E8D8),
                      fontSize: 26,
                      fontWeight: FontWeight.w300)),
                ],
              ),
              const Spacer(flex: 2),
              // Opciones
              _MenuOption(
                icon: Icons.calendar_today_outlined,
                titulo: 'Ver agenda',
                subtitulo: 'Eventos del mundo hispano',
                onTap: () => context.go(AppRoutes.agenda),
              ),
              const SizedBox(height: 16),
              _MenuOption(
                icon: Icons.business_outlined,
                titulo: 'Represento una entidad',
                subtitulo: 'Gestiona los eventos de tu organización',
                onTap: () => context.go(AppRoutes.loginEntidad),
              ),
              const SizedBox(height: 16),
              _MenuOption(
                icon: Icons.admin_panel_settings_outlined,
                titulo: 'Soy administrador',
                subtitulo: 'Panel de gestión del Parlamento',
                onTap: () => context.go(AppRoutes.loginAdmin),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E1E1E)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.goldColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                    style: const TextStyle(
                      color: Color(0xFFF0E8D8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(subtitulo,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
              color: Color(0xFF333333), size: 20),
          ],
        ),
      ),
    );
  }
}
