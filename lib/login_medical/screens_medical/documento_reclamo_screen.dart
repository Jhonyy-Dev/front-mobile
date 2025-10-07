import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
import 'package:mi_app_flutter/servicios/documento_reclamos_service.dart';

class DocumentoReclamosScreen extends StatefulWidget {
  const DocumentoReclamosScreen({Key? key}) : super(key: key);

  @override
  State<DocumentoReclamosScreen> createState() => _DocumentoReclamosScreenState();
}

class _DocumentoReclamosScreenState extends State<DocumentoReclamosScreen> {
  final DocumentoReclamosService _service = DocumentoReclamosService();
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  bool _isDeleting = false;
  List<dynamic> _recibidos = [];
  List<dynamic> _subidos = [];

  @override
  void initState() {
    super.initState();
    _cargarDocumentos();
  }

  Future<void> _cargarDocumentos() async {
    final recibidosRes = await _service.obtenerRecibidos();
    final subidosRes = await _service.obtenerSubidos();

    setState(() {
      _recibidos = recibidosRes['exito'] ? recibidosRes['data'] : [];
      _subidos = subidosRes['exito'] ? subidosRes['data'] : [];
    });
  }

  Future<void> _subirDesdeCamara() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.camera);
    if (foto != null) await _subirArchivo(File(foto.path));
  }

  Future<void> _subirDesdeGaleria() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) await _subirArchivo(File(imagen.path));
  }

  Future<void> _subirArchivo(File archivo) async {
    setState(() => _isUploading = true);
    final res = await _service.subirDocumento(archivo);
    setState(() => _isUploading = false);

    if (res['exito']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Documento subido correctamente')),
      );
      _cargarDocumentos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${res['mensaje']}')),
      );
    }
  }

  Future<void> _descargarDocumento(dynamic doc) async {
    final id = doc['id'];
    final nombreArchivo = doc['documento'].toString().split('/').last;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📥 Descargando "$nombreArchivo"...')),
    );

    final path = await _service.descargarDocumentoReclamo(id, nombreArchivo);
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Archivo guardado en $path')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ No se pudo descargar el archivo')),
      );
    }
  }

  Future<void> _eliminarDocumento(dynamic doc) async {
    final id = doc['id'];
    final nombre = doc['documento'].toString().split('/').last;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Deseas eliminar el documento "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    await _service.eliminarDocumentoReclamo(id);
    setState(() => _isDeleting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🗑️ Documento "$nombre" eliminado')),
    );

    _cargarDocumentos();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final dark = theme.darkModeEnabled;

    final background = dark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final textColor = dark ? Colors.white : const Color(0xFF2D3142);
    final subtitleColor = dark ? Colors.grey[400]! : const Color(0xFF9BA0AB);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Documentos de Reclamos',
          style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: _cargarDocumentos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploader(context, dark, textColor, subtitleColor),
            const SizedBox(height: 32),
            _buildSection("Archivos recibidos", _recibidos, textColor, subtitleColor, recibidos: true),
            const SizedBox(height: 32),
            _buildSection("Archivos subidos", _subidos, textColor, subtitleColor, recibidos: false),
          ],
        ),
      ),
    );
  }

  /// 📤 Bloque para subir documentos
  Widget _buildUploader(BuildContext context, bool dark, Color textColor, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upload_file, color: textColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Subir documentos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
              ),
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(dark ? Colors.white : Colors.blue),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.cloud_upload_outlined, size: 36, color: dark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Text(
                  'Suba o tome una foto del documento\n(PNG, JPG, PDF, etc.)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subtitleColor, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _subirDesdeGaleria,
                        icon: const Icon(Icons.photo_library, color: Colors.white),
                        label: const Text('Desde galería', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _subirDesdeCamara,
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        label: const Text('Desde cámara', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📂 Sección con título y lista
  Widget _buildSection(String titulo, List<dynamic> docs, Color textColor, Color subtitleColor, {required bool recibidos}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 16),
        docs.isEmpty
            ? _buildEmptyBox(
                recibidos
                    ? Icons.inbox_outlined
                    : Icons.folder_open_outlined,
                recibidos
                    ? 'No hay documentos recibidos'
                    : 'No hay documentos subidos',
                recibidos
                    ? 'Los documentos confirmados aparecerán aquí.'
                    : 'Los documentos pendientes aparecerán aquí.',
                subtitleColor,
              )
            : _buildListaDocs(docs, textColor, subtitleColor, recibidos),
      ],
    );
  }

 
Widget _buildListaDocs(List<dynamic> docs, Color textColor, Color subtitleColor, bool recibidos) {
  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange.shade600;
      case 'cancelado':
        return Colors.red.shade600;
      case 'confirmado':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade500;
    }
  }

  Color _estadoFondo(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.orange.shade100;
      case 'cancelado':
        return Colors.red.shade100;
      case 'confirmado':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: docs.length,
    itemBuilder: (context, index) {
      final doc = docs[index];
      final nombre = doc['documento'].toString().split('/').last;
      final estado = doc['estado']?.toString() ?? 'desconocido';

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.97),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.insert_drive_file, color: Colors.blueAccent, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _estadoFondo(estado),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      estado.toUpperCase(),
                      style: TextStyle(
                        color: _estadoColor(estado),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.blueAccent),
                  tooltip: 'Descargar',
                  onPressed: () => _descargarDocumento(doc),
                ),
                if (!recibidos)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    tooltip: 'Eliminar',
                    onPressed: _isDeleting ? null : () => _eliminarDocumento(doc),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}


  Widget _buildEmptyBox(IconData icon, String title, String subtitle, Color subtitleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: subtitleColor),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 16, color: subtitleColor)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: subtitleColor)),
        ],
      ),
    );
  }
}
