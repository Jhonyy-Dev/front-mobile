import 'package:flutter/material.dart';
import 'appointment_psychology_screen.dart';

import 'package:mi_app_flutter/servicios/categoria_servicio.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

 @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<Map<String, dynamic>>?> _futureCategorias;

  @override
  void initState() {
    super.initState();
    _futureCategorias = CategoriaServicio().obtenerCategorias();
  }
  
  @override
  Widget build(BuildContext context) {


   

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3142)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Category',
          style: TextStyle(
            color: Color(0xFF2D3142),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        
        future: _futureCategorias,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text("Error al cargar categorías"));
          } else if (snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay categorías disponibles"));
          }

          final categories = snapshot.data!;

          return ListView.builder(
  padding: const EdgeInsets.all(20),
  itemCount: categories.length,
  itemBuilder: (context, index) {
    final category = categories[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[200], 
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: category['imagen_ruta'] == null || category['imagen_ruta'].isEmpty
              ? const Icon(Icons.category, color: Colors.black)
              : Image.network(
                  category['imagen_ruta'].startsWith('http')
                    ? category['imagen_ruta']
                    : "https://api-inmigracion.maval.tech/storage/categorias/${category['imagen_ruta']}",
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.category, color: Colors.black);
                  },
                ),
          ),
        ),
        title: Text(
          category['nombre'], 
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3142),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFF9BA0AB),
          size: 24,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentPsychologyScreen(
                id: category['id'], 
                nombre: category['nombre'],
              ),
            ),
          );
        },
      ),
    );
  },
);

        
        },
      ),
    
    
    
      );
  }
}
