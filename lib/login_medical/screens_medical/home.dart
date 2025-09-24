import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mi_app_flutter/login_medical/screens_medical/profile_screen.dart';
import 'package:mi_app_flutter/login_medical/screens_medical/settings_screen.dart';
import 'package:mi_app_flutter/login_medical/screens_medical/chats_screen.dart';
import 'package:mi_app_flutter/login_medical/screens_medical/categories_screen.dart';
import 'package:mi_app_flutter/login_medical/screens_medical/appointment_psychology_screen.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_app_flutter/servicios/categoria_servicio.dart';

import 'package:mi_app_flutter/servicios/citas_servicio.dart';
import 'package:mi_app_flutter/servicios/preference_usuario.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

import '../models/news_article.dart';
import 'package:mi_app_flutter/widgets/pulsing_button.dart';
import 'package:mi_app_flutter/login_medical/mapa_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = '';
  String imagenUrl = '';
  bool isLoading = true;
  ImageProvider? _imagenLocal;

  void cargarUsuarioDatos() async {
    // AuthService authService = AuthService();
    final userData = await obtenerDatosUsuario();

    if (userData != null) {
      setState(() {
        userName = userData['usuario']['nombre'];
      });
    }
  }

  int _currentPage = 0;
  int _selectedNavIndex = 0;
  final List<String> _bannerImages = [
    'assets/doctor.webp',
    'assets/doctor2.webp',
    'assets/doctor3.jpg',
  ];
  List<NewsArticle> _newsArticles = [];
  int _displayedNewsCount = 2;
  final String _unsplashApiKey = 'x05AHYZD0CS6fmJDTR0l9XgpLkzqmwZcwHFs7wILk4Y';
  final String _pexelsApiKey =
      'GhslZAVBFmjpXQELRkBgFEJzYxoGqXXoYRHrVQsKdgPNwuTDPZxLlVMb';
  Timer? _newsRefreshTimer;
  final _newsListKey = PageStorageKey('news_list_key');
  final ScrollController _scrollController = ScrollController();

  late Future<List<Map<String, dynamic>>?> _futureCategorias;

  final CitasServicio citasServicio = CitasServicio();
  late Future<Map<String, dynamic>> futureCitas;

  @override
  void initState() {
    super.initState();
    cargarUsuarioDatos();
    _cargarImagenLocal();

    _futureCategorias = CategoriaServicio().obtenerCategorias();
    
    // Cargar citas inmediatamente
    _cargarCitasActualizadas();

    print('Iniciando HomePage');
    startImageTransition();
    fetchHealthNews(); // Carga inicial de noticias

    // Configura el timer para actualizar las noticias cada 30 minutos
    _newsRefreshTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      fetchHealthNews();
    });
    
    // Verificar si hay una nueva cita creada
    _verificarNuevaCita();
    
    print('Métodos de inicialización llamados');
  }

  // Método para cargar citas actualizadas
  void _cargarCitasActualizadas() {
    setState(() {
      futureCitas = citasServicio.obtenerCitas();
    });
    print("Citas actualizadas cargadas");
  }

  // Método para verificar si hay una nueva cita creada
  Future<void> _verificarNuevaCita() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool? citaCreada = prefs.getBool('cita_creada');
      
      if (citaCreada == true) {
        // Limpiar el flag
        await prefs.setBool('cita_creada', false);
        
        // Actualizar la lista de citas
        setState(() {
          futureCitas = citasServicio.obtenerCitas();
        });
        
        print("Lista de citas actualizada después de crear una nueva cita");
      }
    } catch (e) {
      print("Error al verificar nueva cita: $e");
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Verificar si hay una nueva cita cada vez que la pantalla se vuelve visible
    _verificarNuevaCita();
  }

  Future<void> _cargarImagenLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Primero intentar obtener la imagen desde SharedPreferences (sincronizada con profile_screen)
      final imagenUrl = prefs.getString('imagen_url');
      if (imagenUrl != null && imagenUrl.isNotEmpty) {
        setState(() {
          this.imagenUrl = imagenUrl;
          print("✅ Imagen sincronizada en Home desde SharedPreferences: $imagenUrl");
        });
        return;
      }
      
      // Si no hay imagen URL en SharedPreferences, intentar usar la imagen local
      final imagenLocalPath = prefs.getString('imagen_local_path');
      if (imagenLocalPath != null) {
        final file = File(imagenLocalPath);
        if (await file.exists()) {
          setState(() {
            _imagenLocal = FileImage(file);
            this.imagenUrl = 'file://$imagenLocalPath';
            print("✅ Imagen local cargada en Home desde: $imagenLocalPath");
          });
        }
      }
    } catch (e) {
      print("❌ Error al cargar imagen local en Home: $e");
    }
  }

  void startImageTransition() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentPage = (_currentPage + 1) % _bannerImages.length;
        });
        startImageTransition();
      }
    });
  }

  void eliminarCita(int citaId) async {
    try {
      final response = await citasServicio.eliminarCita(citaId);
      print("Response: $response");
      if (response == null) {
         
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cita eliminada correctamente."),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
            futureCitas = citasServicio.obtenerCitas(); 
        });


      } else {
        print('Error al eliminar la cita: $response');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al eliminar la cita: $response"),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      print('Error al eliminar la cita: $e');
    }
  }

  void mostrarConfirmacionEliminar(BuildContext context, int citaId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirmar eliminación"),
        content: Text("¿Estás seguro que quieres eliminar la cita N° $citaId?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cierra este diálogo
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context); 

              eliminarCita(citaId);

            
            },
            child: const Text("Confirmar", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}


  Future<void> fetchHealthNews() async {
    try {
      print('=== INICIO DE ACTUALIZACIÓN DE NOTICIAS ===');
      print('⌛ Iniciando carga de noticias médicas...');

      // Obtener la fecha actual para logs
      final DateTime now = DateTime.now();
      final String todayDate = now.toIso8601String().split('T')[0];

      // Usando API completamente gratuita sin API key - JSONPlaceholder para demo
      final response = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Estado de la respuesta: ${response.statusCode}');
      print('📡 Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> posts = json.decode(response.body);
        
        if (posts.isNotEmpty) {
          // Títulos específicos sobre medicina y salud en español
          final List<String> medicalTitles = [
            'Nuevos avances en tratamientos contra el cáncer muestran resultados prometedores',
            'La importancia de la vitamina D para fortalecer el sistema inmunológico',
            'Ejercicios cardiovasculares: 10 minutos diarios que pueden cambiar tu vida',
            'Alimentación mediterránea reduce el riesgo de enfermedades cardíacas',
            'Telemedicina: el futuro de la atención médica ya está aquí',
            'Cómo el sueño reparador mejora tu salud mental y física',
            'Vacunas actualizadas: lo que necesitas saber para 2025',
            'Mindfulness y meditación: beneficios científicamente comprobados',
            'Prevención del diabetes tipo 2 con cambios simples en el estilo de vida',
            'Salud mental: señales de alerta que no debes ignorar'
          ];

          final List<dynamic> articles = posts.take(10).toList();

          print('📚 Total de artículos encontrados: ${articles.length}');

          if (articles.isNotEmpty) {
            final List<NewsArticle> newArticles = articles.take(10).map((post) {
              final int index = articles.indexOf(post);
              final String title = medicalTitles[index % medicalTitles.length];
              
              print('📰 Artículo: $title');
              
              return NewsArticle(
                title: title,
                description: 'Información actualizada sobre avances médicos, consejos de salud y bienestar para mejorar tu calidad de vida.',
                content: 'Los expertos en salud recomiendan seguir las últimas investigaciones médicas y adoptar hábitos saludables para prevenir enfermedades y mantener un estilo de vida óptimo.',
                url: 'https://salud.gov/news/post/${post['id']}',
                urlToImage: _getImageForIndex(index),
                author: 'Ministerio de Salud',
                publishedAt: '${todayDate}T12:00:00Z',
              );
            }).toList();
            
            setState(() {
              _newsArticles = newArticles;
            });
            
            print('✅ ${newArticles.length} noticias médicas cargadas exitosamente');
          } else {
            print('⚠️ No se encontraron artículos, cargando noticias de respaldo');
            await _loadMockNews();
          }
        } else {
          print('❌ Error al obtener noticias: ${response.statusCode}');
          await _loadMockNews();
        }
      } else {
        print('❌ Error en la respuesta: ${response.statusCode}');
        await _loadMockNews();
      }
    } catch (e) {
      print('❌ Error al actualizar noticias: $e');
      await _loadMockNews();
    }
  }

  List<NewsArticle> _getMockNews() {
    final DateTime now = DateTime.now();
    return [
      NewsArticle(
        title: 'Últimos Avances en Medicina Preventiva 2024',
        description:
            'Nuevos estudios del día revelan cómo la inteligencia artificial está revolucionando la medicina preventiva y mejorando la detección temprana de enfermedades.',
        urlToImage:
            'https://img.freepik.com/free-photo/medical-banner-with-stethoscope_23-2149611199.jpg',
        url:
            'https://www.who.int/news-room/fact-sheets/detail/primary-health-care',
        content:
            'La medicina preventiva está experimentando una transformación significativa gracias a la inteligencia artificial y el análisis de datos masivos...',
        author: 'Dr. Carlos Martínez',
        publishedAt: now.toIso8601String(),
      ),
      NewsArticle(
        title: 'Innovación Médica: Nueva Terapia Contra el Cáncer',
        description:
            'Investigadores anuncian hoy un nuevo tratamiento que combina inmunoterapia con edición genética, mostrando resultados prometedores.',
        urlToImage:
            'https://img.freepik.com/free-photo/scientists-working-lab_23-2148880431.jpg',
        url: 'https://www.cancer.gov/espanol/noticias',
        content:
            'Un equipo de investigadores ha desarrollado una innovadora terapia que combina la inmunoterapia con técnicas de edición genética...',
        author: 'Dra. María González',
        publishedAt: now.subtract(const Duration(hours: 2)).toIso8601String(),
      ),
      NewsArticle(
        title: 'Actualización: Guías de Salud Mental 2024',
        description:
            'Expertos publican hoy nuevas recomendaciones para el manejo del estrés y la ansiedad en la era digital.',
        urlToImage:
            'https://img.freepik.com/free-photo/side-view-woman-having-therapy-session_23-2149288874.jpg',
        url:
            'https://www.who.int/es/news-room/fact-sheets/detail/mental-health-strengthening-our-response',
        content:
            'Las nuevas guías incorporan técnicas innovadoras y recomendaciones actualizadas para el manejo de la salud mental...',
        author: 'Dr. Juan Pérez',
        publishedAt: now.subtract(const Duration(hours: 4)).toIso8601String(),
      ),
      NewsArticle(
        title: 'Telemedicina: Avances del Día',
        description:
            'Nuevas herramientas de diagnóstico remoto presentadas hoy prometen revolucionar la atención médica a distancia.',
        urlToImage:
            'https://img.freepik.com/free-photo/doctor-with-laptop-consulting-patient-online_23-2148877553.jpg',
        url:
            'https://www.who.int/es/news-room/fact-sheets/detail/digital-health',
        content:
            'La telemedicina alcanza nuevos hitos con la integración de IA y realidad aumentada en consultas remotas...',
        author: 'Dra. Ana López',
        publishedAt: now.subtract(const Duration(hours: 6)).toIso8601String(),
      ),
      NewsArticle(
        title: 'Breakthrough en Investigación Neurológica',
        description:
            'Científicos reportan hoy un importante descubrimiento sobre el funcionamiento de la memoria y el aprendizaje.',
        urlToImage:
            'https://img.freepik.com/free-photo/elderly-woman-doctor-checking-medical-report_23-2148877535.jpg',
        url: 'https://www.nih.gov/health-information/espanol',
        content:
            'Un estudio publicado hoy revela nuevos mecanismos cerebrales relacionados con la memoria y el aprendizaje...',
        author: 'Dr. Roberto Sánchez',
        publishedAt: now.subtract(const Duration(hours: 8)).toIso8601String(),
      ),
      NewsArticle(
        title: 'Actualización: Protocolos COVID-19',
        description:
            'Nuevas pautas publicadas hoy para el manejo y prevención de variantes emergentes.',
        urlToImage:
            'https://img.freepik.com/free-photo/healthy-food-medical-equipment_23-2148108966.jpg',
        url: 'https://www.who.int/es/news-room/fact-sheets/detail/healthy-diet',
        content:
            'Las autoridades sanitarias actualizan los protocolos de prevención y tratamiento...',
        author: 'Dra. Laura Ramírez',
        publishedAt: now.subtract(const Duration(hours: 10)).toIso8601String(),
      ),
    ];
  }

  Future<void> _loadMockNews() async {
    print('📚 Cargando noticias de respaldo...');
    setState(() {
      _newsArticles = _getMockNews()
        ..sort((a, b) {
          final DateTime dateA =
              DateTime.parse(a.publishedAt ?? DateTime.now().toIso8601String());
          final DateTime dateB =
              DateTime.parse(b.publishedAt ?? DateTime.now().toIso8601String());
          return dateB
              .compareTo(dateA); // Orden descendente (más reciente primero)
        });
      _displayedNewsCount = 2;
    });
    print('✅ Noticias de respaldo cargadas con éxito');
    print('📅 Noticias ordenadas por fecha: más recientes primero');
  }

  // Método para obtener una imagen específica basada en el índice
  String _getImageForIndex(int index) {
    // Lista de imágenes específicas de medicina y salud
    final List<String> medicalImages = [
      'https://img.freepik.com/free-photo/medical-banner-with-stethoscope_23-2149611199.jpg',
      'https://img.freepik.com/free-photo/scientists-working-lab_23-2148880431.jpg',
      'https://img.freepik.com/free-photo/side-view-woman-having-therapy-session_23-2149288874.jpg',
      'https://img.freepik.com/free-photo/doctor-with-laptop-consulting-patient-online_23-2148877553.jpg',
      'https://img.freepik.com/free-photo/elderly-woman-doctor-checking-medical-report_23-2148877535.jpg',
      'https://img.freepik.com/free-photo/healthy-food-medical-equipment_23-2148108966.jpg',
      'https://img.freepik.com/free-photo/woman-wearing-mask-covid-19-preventive-measure_53876-104035.jpg',
      'https://img.freepik.com/free-photo/young-male-psyciatrist-working-clinic_23-2148816173.jpg',
      'https://img.freepik.com/free-photo/elderly-couple-doing-their-exercises-outdoors_23-2148947226.jpg',
      'https://img.freepik.com/free-photo/scientist-working-laboratory-with-test-tubes_23-2148884483.jpg'
    ];
    
    return medicalImages[index % medicalImages.length];
  }

  Future<String> _getImageForTopic(String topic) async {
    try {
      String searchQuery = topic
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .split(' ')
          .take(3)
          .join(' ');

      if (!searchQuery.contains('medical') &&
          !searchQuery.contains('health') &&
          !searchQuery.contains('healthcare')) {
        searchQuery += ' medical health';
      }

      print('Buscando imagen para: $searchQuery');

      // Intentar primero con Unsplash
      try {
        print('Intentando con Unsplash...');
        final unsplashResponse = await http.get(
          Uri.parse(
              'https://api.unsplash.com/search/photos?query=$searchQuery&per_page=1&orientation=landscape'),
          headers: {
            'Authorization': 'Client-ID $_unsplashApiKey',
          },
        );

        print('Respuesta de Unsplash: ${unsplashResponse.statusCode}');
        if (unsplashResponse.statusCode == 200) {
          final data = json.decode(unsplashResponse.body);
          if (data['results'] != null && data['results'].isNotEmpty) {
            print('Imagen encontrada en Unsplash');
            return data['results'][0]['urls']['regular'];
          }
        }
      } catch (e) {
        print('Error en Unsplash: $e');
      }

      // Si Unsplash falla, intentar con Pexels
      try {
        print('Intentando con Pexels...');
        final pexelsResponse = await http.get(
          Uri.parse(
              'https://api.pexels.com/v1/search?query=$searchQuery&per_page=1&orientation=landscape'),
          headers: {
            'Authorization': _pexelsApiKey,
            'Content-Type': 'application/json',
          },
        );

        print('Respuesta de Pexels: ${pexelsResponse.statusCode}');
        if (pexelsResponse.statusCode == 200) {
          final data = json.decode(pexelsResponse.body);
          print('Respuesta de Pexels: ${pexelsResponse.body}');
          if (data['photos'] != null && data['photos'].isNotEmpty) {
            print('Imagen encontrada en Pexels');
            final imageUrl = data['photos'][0]['src']['large2x'];
            print('URL de imagen de Pexels: $imageUrl');
            return imageUrl;
          }
        } else {
          print('Error de Pexels: ${pexelsResponse.body}');
        }
      } catch (e) {
        print('Error general en _getImageForTopic: $e');
      }
    } catch (e) {
      print('Error general en _getImageForTopic: $e');
    }

    print('Usando imagen por defecto');
    // Si ambas APIs fallan, usar imágenes locales relevantes según el tema
    final Map<String, String> defaultImages = {
      'covid':
          'https://img.freepik.com/free-photo/woman-wearing-mask-covid-19-preventive-measure_53876-104035.jpg',
      'mental':
          'https://img.freepik.com/free-photo/young-male-psyciatrist-working-clinic_23-2148816173.jpg',
      'diet':
          'https://img.freepik.com/free-photo/healthy-food-medical-equipment_23-2148108966.jpg',
      'exercise':
          'https://img.freepik.com/free-photo/elderly-couple-doing-their-exercises-outdoors_23-2148947226.jpg',
      'research':
          'https://img.freepik.com/free-photo/scientist-working-laboratory-with-test-tubes_23-2148884483.jpg',
    };

    for (var entry in defaultImages.entries) {
      if (topic.toLowerCase().contains(entry.key)) {
        print('Usando imagen por defecto para tema: ${entry.key}');
        return entry.value;
      }
    }

    return 'https://img.freepik.com/free-photo/medical-banner-with-stethoscope_23-2149611199.jpg';
  }

  void _showNewsDetail(NewsArticle article, BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isDarkMode = themeProvider.darkModeEnabled;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true, // Permite cerrar al tocar fuera del modal
      enableDrag: true, // Permite arrastrar para cerrar
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Indicador de arrastre
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Contenido Principal
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      children: [
                        // Imagen Principal
                        Stack(
                          children: [
                            // Imagen con gradiente
                            Container(
                              height: 250,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image:
                                      _isValidImageUrl(article.urlToImage)
                                      ? NetworkImage(article.urlToImage!)
                                      : const NetworkImage(
                                          'https://img.freepik.com/free-photo/medical-banner-with-stethoscope_23-2149611199.jpg',
                                        ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Botón de cerrar
                            Positioned(
                              top: 16,
                              right: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Contenido
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Metadata (Autor y Fecha)
                              Row(
                                children: [
                                  const Icon(Icons.person_outline,
                                      size: 16, color: Color(0xFF4485FD)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      article.author ?? 'Autor desconocido',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (article.publishedAt != null) ...[
                                    const Icon(Icons.access_time,
                                        size: 16, color: Color(0xFF4485FD)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(article.publishedAt!),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Título
                              Text(
                                article.title ?? 'Sin título',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Descripción
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF4485FD).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  article.description ?? 'Sin descripción',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Contenido
                              Text(
                                '${article.description}\n\n${article.content}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Botón de acción
                              if (article.url != null)
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        String urlString = article.url!.trim();
                                        print('URL original: $urlString');

                                        if (!urlString.startsWith('http://') &&
                                            !urlString.startsWith('https://')) {
                                          urlString = 'https://$urlString';
                                        }

                                        final Uri? url =
                                            Uri.tryParse(urlString);
                                        if (url == null) {
                                          throw Exception('URL inválida');
                                        }

                                        print('Intentando abrir: $url');

                                        final bool launched = await launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        );

                                        if (!launched) {
                                          throw Exception(
                                              'No se pudo lanzar la URL');
                                        }
                                      } catch (e) {
                                        print('Error al abrir URL: $e');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'No se pudo abrir el enlace: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                              duration:
                                                  const Duration(seconds: 3),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.open_in_new,
                                        color: Colors.white),
                                    label: const Text('Leer artículo completo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4485FD),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
  
    // Verificar si la URL comienza con 'file:///'
    if (url.startsWith('file:///')) {
      // Si es una URL de archivo, verificar que tenga una ruta válida después del prefijo
      return url.length > 8; // 'file:///' tiene 8 caracteres, debe haber algo más
    }
  
    try {
      final Uri uri = Uri.parse(url);
      // Verificar que sea una URL absoluta con esquema http o https
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _newsRefreshTimer
        ?.cancel(); // Cancela el timer cuando se destruye el widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el ThemeProvider para acceder al estado del modo oscuro
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool darkModeEnabled = themeProvider.darkModeEnabled;
    
    // Definir colores según el tema
    final Color backgroundColor = darkModeEnabled ? const Color(0xFF121212) : Colors.white;
    final Color textColor = darkModeEnabled ? Colors.white : const Color(0xFF2D3142);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                child: Text(
                                  userName.isNotEmpty ? 'Hola $userName 👋' : 'Cargando...',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16), // Espacio entre el texto y el avatar
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: Container(
                            width: 50,  
                            height: 50,  
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: darkModeEnabled ? Colors.grey[800]! : Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              image: DecorationImage(
                                image: imagenUrl.isNotEmpty
                                  ? imagenUrl.startsWith('file://')
                                    ? FileImage(File(imagenUrl.replaceFirst('file://', '')))
                                    : NetworkImage(
                                        imagenUrl.startsWith('http') 
                                          ? imagenUrl 
                                          : "https://api-inmigracion.laimeweb.tech/storage/usuarios/$imagenUrl"
                                      ) as ImageProvider
                                  : _imagenLocal ?? const AssetImage('assets/doctor.webp') as ImageProvider,
                                fit: BoxFit.cover,
                                onError: (exception, stackTrace) {
                                  print('Error loading profile image: $exception');
                                  // Si hay un error al cargar la imagen, intentar usar la imagen local
                                  if (_imagenLocal != null) {
                                    setState(() {
                                      imagenUrl = '';  // Limpiar la URL para que use la imagen local
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Slider Banner
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          // Animated Image Background
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 800),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: Container(
                              key:
                                  ValueKey<String>(_bannerImages[_currentPage]),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image:
                                      AssetImage(_bannerImages[_currentPage]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          // Gradient Overlay
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Buscando\nDoctores Especialistas?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Programa una cita con\nnuestros mejores doctores.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Animated Indicators
                          Positioned(
                            bottom: 20,
                            left: 20,
                            child: Row(
                              children: List.generate(
                                _bannerImages.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: index == _currentPage ? 20 : 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(
                                      index == _currentPage ? 1 : 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Upcoming Appointments Section

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mis Citas',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Color(0xFF4485FD)),
                            onPressed: _actualizarCitas,
                            tooltip: 'Actualizar citas',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    FutureBuilder<Map<String, dynamic>>(
                      future:
                          futureCitas, 
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data == null) {
                          return const Center(child: Text('No hay datos'));
                        }

                        final result = snapshot.data!;
                        if (result['exito'] != true) {
                          return Center(child: Text(result['mensaje']));
                        }
                        final List citas = result['citas'];

                        if (citas.isEmpty) {
                          return const Center(child: Text('No tienes citas'));
                        }

                        return SizedBox(
                          height: 177,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: citas.length,
                            itemBuilder: (context, index) {
                              final cita = citas[index];
                              final String estado =
                                  cita['estado'] ?? 'Sin estado';
                              final String categoriaNombre =
                                  (cita['categoria'] != null &&
                                        cita['categoria']['nombre'] != null)
                                      ? cita['categoria']['nombre']
                                      : 'Sin categoría';
                              final String fecha = cita['fecha_cita'] ?? '';
                              final String hora = cita['hora_cita'] ?? '';

                              return Container(
                                margin: const EdgeInsets.only(right: 16),
                                width: 290,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4485FD),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4485FD).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        // Imagen de placeholder para la cita
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                            image: const DecorationImage(
                                              image: AssetImage(
                                                  'assets/doctor_placeholder.png'),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Se muestra el estado como "name"
                                              Text(
                                                estado,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              // Se muestra la categoría como "specialty"
                                              Text(
                                                categoriaNombre,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white.withOpacity(0.2),
                                            ),
                                            child: InkWell(
                                            onTap: () {
                                           showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                    title: const Text(
                                                      "Detalles de la Cita",
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                    ),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text("📌 Estado: $estado", style: TextStyle(fontSize: 16, color: textColor)),
                                                        const SizedBox(height: 10),
                                                        Text("🏥 Categoría: $categoriaNombre", style: TextStyle(fontSize: 16, color: textColor)),
                                                        const SizedBox(height: 10),
                                                        Text("📅 Fecha: $fecha", style: TextStyle(fontSize: 16, color: textColor)),
                                                        const SizedBox(height: 10),
                                                        Text("⏰ Hora: $hora", style: TextStyle(fontSize: 16, color: textColor)),
                                                        const SizedBox(height: 10),
                                                        if (cita['sede'] != null) ...[
                                                          Text("📍 Sede: ${cita['sede']}", style: TextStyle(fontSize: 16, color: textColor)),
                                                          const SizedBox(height: 10),
                                                        ],
                                                        if (cita['nota'] != null) ...[
                                                          Text("📝 Nota: ${cita['nota']}", style: TextStyle(fontSize: 16, color: textColor)),
                                                          const SizedBox(height: 10),
                                                        ],
                                                        if (cita['asunto'] != null) ...[
                                                          Text("📂 Asunto: ${cita['asunto']}", style: TextStyle(fontSize: 16, color: textColor)),
                                                          const SizedBox(height: 10),
                                                        ],
                                                        
                                                      ],
                                                    ),
                                                   actions: [
                                                          Center(
                                                            child: Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                ElevatedButton(
                                                                  onPressed: () => Navigator.pop(context),
                                                                  child: const Text("Cerrar"),
                                                                ),
                                                                const SizedBox(width: 10),
                                                                ElevatedButton(
                                                                  onPressed: () {
                                                                    mostrarConfirmacionEliminar(context, cita['id']);

                                                                  },
                                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                                    child: const Text(
                                                                      "Eliminar",
                                                                      style: TextStyle(color: Colors.white),
                                                                    ),

                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],


                                                  );
                                                },
                                              );

                                          },
                                              child: const Icon(
                                                Icons.chevron_right,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                          ),




                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      width: double.infinity,
                                      height: 1,
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today_outlined,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              fecha,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              hora,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              
                              
                              
                              );
                            },
                          ),
                        );
                      },
                    ),




                    const SizedBox(height: 24),

                    // Categories Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20, bottom: 16),
                          child: Text(
                            'Categorías',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CategoriesScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Ver más',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4485FD),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Categories Grid
                 FutureBuilder<List<Map<String, dynamic>>?>(
                    future: _futureCategorias,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                        return const Center(child: Text("No hay categorías disponibles"));
                      }

                      // Tomamos todas las categorías disponibles (máximo 6)
                      final categorias = snapshot.data!.take(6).toList();
                      
                      // Si hay categorías, usamos la primera para el botón general
                      final primeraCategoria = categorias.isNotEmpty ? categorias[0] : null;

                      return Column(
                        children: [
                          // Mostrar GridView de las categorías (excepto la primera)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1,
                            ),
                            itemCount: categorias.length,
                            itemBuilder: (context, index) {
                              final categoria = categorias[index];

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AppointmentPsychologyScreen(
                                        id: categoria['id'],
                                        nombre: categoria['nombre'],
                                      ),
                                    ),
                                  );
                                },
                                 child: Container(
                                  decoration: BoxDecoration(
                                    color: darkModeEnabled ? const Color(0xFF1E1E1E) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: darkModeEnabled
                                            ? const Color(0xFF1E1E1E).withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                        spreadRadius: 0,
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Contenedor para el icono con bordes redondeados
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: darkModeEnabled ? const Color(0xFF2A2A2A) : const Color(0xFFF5F7FA),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: darkModeEnabled ? Colors.grey[800]! : Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 32,
                                            height: 32,
                                            child: categoria['imagen_ruta'] == null || categoria['imagen_ruta'].isEmpty
                                              ? const Icon(Icons.image_not_supported)
                                              : Image.network(
                                                  categoria['imagen_ruta'].startsWith('http')
                                                    ? categoria['imagen_ruta']
                                                    : "https://api-inmigracion.maval.tech/storage/categorias/${categoria['imagen_ruta']}",
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return const Icon(Icons.broken_image);
                                                  },
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        categoria['nombre']?.length > 10
                                            ? '${categoria['nombre']?.substring(0, 10)}...'
                                            : categoria['nombre'] ?? 'Sin nombre',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 28),

                          // Botón para programar cita con la primera categoría
                          if (primeraCategoria != null)
                            Center(
                              child: PulsingButton(
                                width: MediaQuery.of(context).size.width * 0.8,
                                text: 'Programar Cita General',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AppointmentPsychologyScreen(
                                        id: primeraCategoria['id'],
                                        nombre: primeraCategoria['nombre'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),




                    const SizedBox(height: 24),


                    _buildNewsSection(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() => _selectedNavIndex = 0);
                },
                child:
                    _buildNavItem(Icons.home_outlined, _selectedNavIndex == 0),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OpenStreetMapPage(), // Aquí se navega a OpenStreetMapPage
                    ),
                  );
                  setState(() => _selectedNavIndex = 1);
                },
                child: _buildNavItem(
                  Icons.location_on_outlined,
                  _selectedNavIndex == 1,
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatScreen(),
                    ),
                  );
                  setState(() => _selectedNavIndex = 2);
                },
                child: _buildNavItem(
                    Icons.calendar_today_outlined, _selectedNavIndex == 2),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                  setState(() => _selectedNavIndex = 3);
                },
                child:
                    _buildNavItem(Icons.person_outline, _selectedNavIndex == 3),
              ),
            ],
          ),
        ),

      ),
    );
  }

  // Método para actualizar las citas manualmente
  Future<void> _actualizarCitas() async {
    _cargarCitasActualizadas();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Lista de citas actualizada"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildNewsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool darkModeEnabled = themeProvider.darkModeEnabled;
    
    // Definir colores según el tema
    final Color textColor = darkModeEnabled ? Colors.white : const Color(0xFF2D3142);
    
    if (_newsArticles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Noticias de Salud',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF4485FD)),
                onPressed: () async {
                  final double currentPosition =
                      _scrollController.position.pixels;
                  setState(() {
                    _newsArticles
                        .clear(); // Mostrar loading mientras se actualiza
                  });
                  await fetchHealthNews(); // Actualizar noticias
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollController.jumpTo(currentPosition);
                  });
                                },
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            key: _newsListKey,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _displayedNewsCount.clamp(0, _newsArticles.length),
            itemBuilder: (context, index) {
              final article = _newsArticles[index];
              return GestureDetector(
                onTap: () => _showNewsDetail(article, context),
                child: Container(
                  decoration: BoxDecoration(
                    color: darkModeEnabled 
                        ? Colors.blueGrey.shade800.withOpacity(0.7) 
                        : Colors.blue.shade50.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4485FD).withOpacity(0.15),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF4485FD).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 130,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(10)),
                              child: Image.network(
                                _isValidImageUrl(article.urlToImage)
                                  ? article.urlToImage!
                                  : 'https://img.freepik.com/free-photo/medical-banner-with-stethoscope_23-2149611199.jpg',
                                width: double.infinity,
                                height: 130,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.title ?? 'Noticia médica',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                article.description ??
                                    'No hay descripción disponible',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_newsArticles.length > 2)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    if (_displayedNewsCount >= _newsArticles.length) {
                      _displayedNewsCount = 2;
                    } else {
                      _displayedNewsCount += 2;
                    }
                  });
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF4485FD),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  _displayedNewsCount >= _newsArticles.length
                      ? 'Ocultar'
                      : 'Ver más',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, bool isSelected) {
    String iconAsset;
    if (icon == Icons.home_outlined) {
      iconAsset = 'assets/icons/home.png';
    } else if (icon == Icons.location_on_outlined) {
      iconAsset = 'assets/icons/location.png';
    } else if (icon == Icons.calendar_today_outlined) {
      iconAsset = 'assets/icons/chat.png';
    } else {
      iconAsset = 'assets/icons/profile.png';
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color.fromARGB(255, 199, 200, 201)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Image.asset(
          iconAsset,
          color: isSelected
              ? const Color.fromARGB(255, 49, 47, 47)
              : const Color.fromARGB(255, 136, 140, 147),
          width: 16,
          height: 16,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
