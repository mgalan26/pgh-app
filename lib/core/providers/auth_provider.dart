import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pgh_app/core/models/models.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

final sessionProvider = Provider<Session?>((ref) {
  return ref.watch(supabaseProvider).auth.currentSession;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(supabaseProvider).auth.currentUser?.id;
});

final organizadorProvider = FutureProvider<Organizador?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
      .from('organizadores')
      .select('*, entidades(*)')
      .eq('id', userId)
      .maybeSingle();

  if (data == null) return null;
  return Organizador.fromJson(data);
});

final usuarioProvider = FutureProvider<Usuario?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
      .from('usuarios')
      .select()
      .eq('id', userId)
      .maybeSingle();

  if (data == null) return null;
  return Usuario.fromJson(data);
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final org = await ref.watch(organizadorProvider.future);
  return org?.isAdmin ?? false;
});

final isOrganizadorAprobadoProvider = FutureProvider<bool>((ref) async {
  final org = await ref.watch(organizadorProvider.future);
  return org?.isAprobado ?? false;
});

final usuarioAutorizadoProvider =
    FutureProvider<List<UsuarioAutorizado>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
      .from('usuarios_autorizados')
      .select('*, entidades(*)')
      .eq('usuario_id', userId)
      .eq('estado', 'activo');
  return (data as List).map((e) => UsuarioAutorizado.fromJson(e)).toList();
});

final isPonenteProvider = FutureProvider<bool>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return false;
  final supabase = ref.watch(supabaseProvider);
  final data = await supabase
      .from('ponentes')
      .select('id')
      .eq('usuario_id', userId)
      .maybeSingle();
  return data != null;
});
