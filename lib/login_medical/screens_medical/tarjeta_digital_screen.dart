import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';

class TarjetaDigitalScreen extends StatelessWidget {
  const TarjetaDigitalScreen({Key? key}) : super(key: key);

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
          icon: Icon(
            Icons.arrow_back_ios,
            color: textColor,
          ),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de tarjeta
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
              
              // Título principal
              Text(
                'Aún no cuentas con tarjeta digital',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // Descripción
              Text(
                'Tu tarjeta digital será habilitada desde el panel administrativo. Una vez activada, podrás acceder a ella desde esta sección.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: subtitleColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              // Botón de acción
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: const Color(0xFF4A80F0),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Center(
                      child: Text(
                        'Volver al perfil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
