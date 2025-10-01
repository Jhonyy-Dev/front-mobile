import 'package:flutter/material.dart';

class DocumentosMedicosCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool darkModeEnabled;
  final double width;

  const DocumentosMedicosCard({
    Key? key,
    required this.onTap,
    required this.darkModeEnabled,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: darkModeEnabled ? const Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: darkModeEnabled 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icono
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.upload_file_outlined,
                      color: const Color(0xFFFF9800),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Documentos & Reclamos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: darkModeEnabled ? Colors.white : const Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sube/Recibe documentos y reclamos',
                          style: TextStyle(
                            fontSize: 14,
                            color: darkModeEnabled ? Colors.grey[400] : const Color(0xFF9BA0AB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Flecha
                  Icon(
                    Icons.arrow_forward_ios,
                    color: darkModeEnabled ? Colors.grey[400] : const Color(0xFF9BA0AB),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
