import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
import 'package:mi_app_flutter/servicios/tarjeta_digital_service.dart';

class TarjetaDigitalScreen extends StatefulWidget {
  const TarjetaDigitalScreen({Key? key}) : super(key: key);

  @override
  State<TarjetaDigitalScreen> createState() => _TarjetaDigitalScreenState();
}

class _TarjetaDigitalScreenState extends State<TarjetaDigitalScreen> {
  final TarjetaDigital _tarjetaService = TarjetaDigital();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final darkModeEnabled = themeProvider.darkModeEnabled;

    final backgroundColor =
        darkModeEnabled ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final textColor = darkModeEnabled ? Colors.white : const Color(0xFF2D3142);
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
          'Tarjeta Digital',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _tarjetaService.obtenerTarjetaDigital(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!['exito'] == false) {
            return _sinTarjeta(textColor, subtitleColor);
          }

          final List tarjetas = snapshot.data!['tarjetaDigital'];

          if (tarjetas.isEmpty) {
            return _sinTarjeta(textColor, subtitleColor);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1, // 2 columnas
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: tarjetas.length,
            itemBuilder: (context, index) {
              final item = tarjetas[index];
              final imagenUrl = item['imagen'];

              return GestureDetector(
                onTap: () {
                  _mostrarImagenGrande(context, imagenUrl);
                },
                child: Card(
                  color: darkModeEnabled
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imagenUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// ✅ Pantalla o diálogo para mostrar la imagen grande
  void _mostrarImagenGrande(BuildContext context, String imagenUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 1,
            maxScale: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imagenUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ Si no hay tarjetas
  Widget _sinTarjeta(Color textColor, Color? subtitleColor) {
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
                Icons.credit_card_outlined,
                size: 80,
                color: const Color(0xFF4A80F0),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Aún no tienes tarjeta digital',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu tarjeta digital se mostrará aquí una vez activada por el administrador.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }
}
