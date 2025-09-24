import 'package:flutter/material.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/servicios/cambiar_contra.dart';
import 'package:mi_app_flutter/welcome_screen.dart';

class CambiarClaveScreen extends StatefulWidget {
  const CambiarClaveScreen({super.key});

  @override
  State<CambiarClaveScreen> createState() => _CambiarClaveScreenState();
}

class _CambiarClaveScreenState extends State<CambiarClaveScreen> {
  final _claveController = TextEditingController();
  final _confirmarClaveController = TextEditingController();

  bool _isClaveValida = false;
  bool _coinciden = false;
  bool _isLoading = false;
  bool _mostrarClave = false;
  bool _mostrarConfirmacion = false;

  @override
  void initState() {
    super.initState();
    _claveController.addListener(_validar);
    _confirmarClaveController.addListener(_validar);
  }

  @override
  void dispose() {
    _claveController.dispose();
    _confirmarClaveController.dispose();
    super.dispose();
  }

  void _validar() {
    final clave = _claveController.text.trim();
    final confirmar = _confirmarClaveController.text.trim();
    setState(() {
      _isClaveValida = clave.length >= 8;
      _coinciden = clave == confirmar;
    });
  }

  Future<void> _cambiarClave() async {
    CambiarContraServicio cambiarContraServicio = CambiarContraServicio();

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

  
    final nuevaClave = _claveController.text.trim();
    final confirmarClave = _confirmarClaveController.text.trim();

    final response = await cambiarContraServicio.cambiarContra(nuevaClave, confirmarClave);

    if (response == null) {
   

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña cambiada con éxito'),
          duration: Duration(seconds: 2),
        ),
      );

       Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
        ),
      );

    } else {

  
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response),
          duration: const Duration(seconds: 2),
        ),
      );


    }

    setState(() => _isLoading = false);

  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.darkModeEnabled;

    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2D3142);
    final inputFillColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50]!;
    final hintColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cambiar contraseña',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ingresa tu nueva contraseña. Debe tener al menos 8 caracteres.',
                  style: TextStyle(
                    fontSize: 16,
                    color: hintColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Campo: Nueva contraseña
                TextFormField(
                  controller: _claveController,
                  obscureText: !_mostrarClave,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    labelStyle: TextStyle(color: hintColor),
                    filled: true,
                    fillColor: inputFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4485FD), width: 2),
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: hintColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarClave ? Icons.visibility_off : Icons.visibility,
                        color: hintColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _mostrarClave = !_mostrarClave;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(color: textColor),
                ),

                const SizedBox(height: 16),

                // Campo: Confirmar contraseña
                TextFormField(
                  controller: _confirmarClaveController,
                  obscureText: !_mostrarConfirmacion,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    labelStyle: TextStyle(color: hintColor),
                    filled: true,
                    fillColor: inputFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF4485FD), width: 2),
                    ),
                    prefixIcon: Icon(Icons.lock_reset, color: hintColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarConfirmacion ? Icons.visibility_off : Icons.visibility,
                        color: hintColor,
                      ),
                      onPressed: () {

                        setState(() {
                          _mostrarConfirmacion = !_mostrarConfirmacion;
                        });

                      },
                    ),
                  ),
                  style: TextStyle(color: textColor),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isClaveValida && _coinciden && !_isLoading) ? _cambiarClave : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4485FD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Cambiar contraseña',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
