import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Widget para seleccionar y subir un logo a Supabase Storage.
/// Muestra la imagen actual (si existe) y un botón para cambiarla.
/// [storagePath] → ruta dentro del bucket, ej: 'entidades/uuid'
/// [onUploaded]  → callback con la nueva URL pública (o null si se borra)
class LogoUploadButton extends StatefulWidget {
  final String? currentUrl;
  final String storagePath;           // sin extensión; se añade al subir
  final String bucket;
  final ValueChanged<String?> onUploaded;
  final double size;

  const LogoUploadButton({
    super.key,
    this.currentUrl,
    required this.storagePath,
    this.bucket = 'logos',
    required this.onUploaded,
    this.size = 80,
  });

  @override
  State<LogoUploadButton> createState() => _LogoUploadButtonState();
}

class _LogoUploadButtonState extends State<LogoUploadButton> {
  String? _previewUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _previewUrl = widget.currentUrl;
  }

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 90,
    );
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final ext   = file.name.split('.').last.toLowerCase();
      final path  = '${widget.storagePath}.$ext';

      await Supabase.instance.client.storage
          .from(widget.bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );

      final url = Supabase.instance.client.storage
          .from(widget.bucket)
          .getPublicUrl(path);

      // Añadir timestamp para romper caché del navegador
      final urlFinal = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      setState(() => _previewUrl = urlFinal);
      widget.onUploaded(urlFinal);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al subir imagen: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return GestureDetector(
      onTap: _uploading ? null : _pickAndUpload,
      child: Stack(
        children: [
          // Imagen / placeholder
          Container(
            width: s,
            height: s,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(s * 0.15),
              border: Border.all(
                color: _previewUrl != null
                    ? const Color(0xFF333333)
                    : const Color(0xFFC9A84C).withOpacity(0.5),
                width: _previewUrl != null ? 1 : 1.5,
              ),
            ),
            child: _uploading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFC9A84C), strokeWidth: 2))
                : _previewUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(s * 0.15),
                        child: Image.network(
                          _previewUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _placeholder(s),
                        ),
                      )
                    : _placeholder(s),
          ),

          // Botón de cámara en esquina
          if (!_uploading)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: s * 0.32,
                height: s * 0.32,
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A84C),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0D0D0D), width: 2),
                ),
                child: Icon(Icons.camera_alt,
                    color: const Color(0xFF0D0D0D),
                    size: s * 0.17),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(double s) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined,
              color: const Color(0xFF444444), size: s * 0.38),
          const SizedBox(height: 4),
          Text('Logo',
              style: TextStyle(
                  color: const Color(0xFF555555), fontSize: s * 0.14)),
        ],
      );
}
