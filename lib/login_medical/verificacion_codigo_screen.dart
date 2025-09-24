import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
import 'package:mi_app_flutter/servicios/validar_codigo.dart';

import 'package:mi_app_flutter/login_medical/cambiar_clave_screen.dart';



class VerificacionCodigoScreen extends StatefulWidget {
  const VerificacionCodigoScreen({super.key});

  @override
  State<VerificacionCodigoScreen> createState() => _VerificacionCodigoScreenState();
}

class _VerificacionCodigoScreenState extends State<VerificacionCodigoScreen> {
  final _codigoController = TextEditingController();
  bool _isCodigoValido = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codigoController.addListener(_validarCodigo);
  }

  @override
  void dispose() {
    _codigoController.removeListener(_validarCodigo);
    _codigoController.dispose();
    super.dispose();
  }

  void _validarCodigo() {
    setState(() {
      _isCodigoValido = _codigoController.text.trim().length == 6;
    });
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
                  'Verificación de código',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ingresa el código de 6 dígitos que te enviamos por correo.',
                  style: TextStyle(
                    fontSize: 16,
                    color: hintColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _codigoController,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Código de verificación',
                    counterText: '',
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
                    prefixIcon: Icon(Icons.verified_outlined, color: hintColor),
                  ),
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 24),
               
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isCodigoValido && !_isLoading)
                        ? _verificarCodigo
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4485FD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor:
                          isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Verificar código',
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

  void _verificarCodigo() async {
  setState(() {
    _isLoading = true;
  });


  final codigo = _codigoController.text.trim();
  final servicio = ValidarCodigoServicio();


  String? response = await servicio.validarCodigo(codigo);

  if (response == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código verificado correctamente.'),
        backgroundColor: Color(0xFF4485FD),
      ),

    );

  
    setState(() {
        _isLoading = false;
    });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const CambiarClaveScreen(),
        ),
      );


  } else {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response),
        backgroundColor: Colors.red,
      ),
    );

     setState(() {
        _isLoading = false;
      });

  }
}



}
