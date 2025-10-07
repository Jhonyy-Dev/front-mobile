import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
import 'package:mi_app_flutter/servicios/poliza_cobertura_servicio.dart';

class PolizasCoberturaScreen extends StatefulWidget {
  const PolizasCoberturaScreen({Key? key}) : super(key: key);

  @override
  State<PolizasCoberturaScreen> createState() => _PolizasCoberturaScreenState();
}

class _PolizasCoberturaScreenState extends State<PolizasCoberturaScreen> {
  final PolizaCobertura _service = PolizaCobertura();
  bool _cargando = true;
  String? _error;
  List<dynamic> _polizas = [];
  final Set<int> _expandidos = <int>{};

  @override
  void initState() {
    super.initState();
    _cargarPolizas();
  }

  Future<void> _cargarPolizas() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final resp = await _service.obtenerPolizaCobertura();
    if (!mounted) return;
    if (resp['exito'] == true) {
      final data = resp['polizaCobertura'];
      if (data is List) {
        setState(() {
          _polizas = data;
          _cargando = false;
        });
      } else {
        setState(() {
          _polizas = [];
          _cargando = false;
          _error = 'Formato de respuesta inválido';
        });
      }
    } else {
      setState(() {
        _cargando = false;
        _error = resp['mensaje']?.toString() ?? 'Error al cargar pólizas';
      });
    }
  }

  Future<void> _descargar(dynamic item) async {
    final int id = (item['id'] is int) ? item['id'] as int : int.tryParse('${item['id']}') ?? 0;
    final String nombre = (item['documento'] ?? 'archivo').toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Descargando $nombre...')),
    );
    final ruta = await _service.descargarDocumentoPoliza(id, nombre);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ruta != null ? 'Archivo guardado ' : 'No se pudo descargar el archivo',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final darkModeEnabled = themeProvider.darkModeEnabled;

    final backgroundColor = darkModeEnabled ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final textColor = darkModeEnabled ? Colors.white : const Color(0xFF2D3142);
    final subtitleColor = darkModeEnabled ? Colors.grey[400] : const Color(0xFF9BA0AB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pólizas y Coberturas',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: _cargarPolizas,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.redAccent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  Text(
                    'Archivos disponibles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _polizas.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: darkModeEnabled ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: darkModeEnabled ? Colors.grey.shade800 : Colors.grey.shade300,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.folder_open_outlined,
                                size: 48,
                                color: subtitleColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay archivos disponibles',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: subtitleColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Los archivos que suba el administrador aparecerán aquí',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _polizas.length,
                          itemBuilder: (context, index) {
                            final item = _polizas[index];
                            final nombre = (item['documento'] ?? 'Archivo').toString();
                            final descripcion = (item['descripcion'] ?? '').toString();
                            final int itemId = (item['id'] is int) ? item['id'] as int : index;
                            final bool expanded = _expandidos.contains(itemId);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: darkModeEnabled ? const Color(0xFF242526) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: darkModeEnabled ? Colors.grey.shade700 : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: darkModeEnabled ? Colors.grey.shade700 : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.insert_drive_file,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nombre,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: textColor,
                                          ),
                                        ),
                                        if (descripcion.isNotEmpty) ...[
                                          Text(
                                            descripcion,
                                            maxLines: expanded ? null : 1,
                                            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: subtitleColor,
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: TextButton(
                                              onPressed: () {
                                                setState(() {
                                                  if (expanded) {
                                                    _expandidos.remove(itemId);
                                                  } else {
                                                    _expandidos.add(itemId);
                                                  }
                                                });
                                              },
                                              child: Text(expanded ? 'Ver menos' : 'Ver más'),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _descargar(item),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Icon(Icons.download, color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}
