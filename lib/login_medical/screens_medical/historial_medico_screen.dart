import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
import 'package:mi_app_flutter/servicios/historial_medico_service.dart';

class HistorialMedicoScreen extends StatefulWidget {
  const HistorialMedicoScreen({Key? key}) : super(key: key);

  @override
  State<HistorialMedicoScreen> createState() => _HistorialMedicoScreenState();
}

class _HistorialMedicoScreenState extends State<HistorialMedicoScreen> {
  final HistorialMedico _historialService = HistorialMedico();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final darkModeEnabled = themeProvider.darkModeEnabled;

    final backgroundColor =
        darkModeEnabled ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final textColor =
        darkModeEnabled ? Colors.white : const Color(0xFF2D3142);
    final subtitleColor =
        darkModeEnabled ? Colors.grey[400] : const Color(0xFF9BA0AB);

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
          'Historial Médico',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _historialService.obtenerHistorialMedico(),
        builder: (context, snapshot) {
          // MIENTRAS CARGA
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ERROR
          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!['exito'] == false) {
            return _sinHistorial(context, textColor, subtitleColor);
          }

          final List historial = snapshot.data!['historialMedico'];

          if (historial.isEmpty) {
            return _sinHistorial(context, textColor, subtitleColor);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historial.length,
            itemBuilder: (context, index) {
              final item = historial[index];
              final descripcion = item['descripcion'] ?? '';

              bool expandido = false; // 👈 mover aquí, fuera del builder

              return StatefulBuilder(
                builder: (context, setInnerState) {
                  return Card(
                    color: darkModeEnabled
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título y botón de descarga
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.description_outlined,
                                  color: Color(0xFF4A80F0), size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['documento'] ?? 'Sin nombre',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.download_rounded,
                                    color: Color(0xFF4A80F0)),
                                onPressed: () async {
                                  final mensaje = await _historialService
                                      .descargarDocumentoHistorialMedico(
                                    item['id'],
                                    item['documento'],
                                  );

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text(mensaje ?? 'Descarga iniciada')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Descripción corta o completa
                          Text(
                            expandido
                                ? descripcion
                                : (descripcion.length > 60
                                    ? '${descripcion.substring(0, 60)}...'
                                    : descripcion),
                            style: TextStyle(color: subtitleColor, fontSize: 14),
                          ),

                          // Botón "Ver más" si hay texto largo
                          if (descripcion.length > 60)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setInnerState(() {
                                    expandido = !expandido; // 👈 ahora sí cambia el estado real
                                  });
                                },
                                child: Text(
                                  expandido ? 'Ver menos' : 'Ver más',
                                  style: const TextStyle(
                                    color: Color(0xFF4A80F0),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );

        },
      ),
    );
  }

  /// Widget que se muestra cuando no hay historial
  Widget _sinHistorial(
      BuildContext context, Color textColor, Color? subtitleColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4A80F0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.medical_information_outlined,
                size: 80,
                color: const Color(0xFF4A80F0),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Aún no tienes historial médico',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu historial médico aparecerá aquí una vez que tengas consultas registradas desde el panel administrativo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}
