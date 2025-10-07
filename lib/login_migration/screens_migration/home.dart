import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mi_app_flutter/login_migration/screens_migration/profile_screen.dart';
import 'package:mi_app_flutter/login_migration/screens_migration/chats_screen.dart';
import '../models/news_article.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';

import 'package:mi_app_flutter/servicios/migracion_servicio.dart';
import 'package:mi_app_flutter/servicios/categoria_servicio.dart';
import '../../../servicios/notificaciones_servicio.dart';
import '../../../servicios/firebase_notificaciones_servicio.dart';
import '../../../servicios/cumpleanos_background_servicio.dart';
import '../../../servicios/session_manager.dart';
import 'package:http/http.dart' as http;

// import '../../widgets/cumpleanos_banner.dart'; // Comentado temporalmente

import 'package:image_picker/image_picker.dart';
import 'package:mi_app_flutter/servicios/preference_usuario.dart';
import 'package:mi_app_flutter/servicios/documentos_usuario.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
// import 'package:open_file/open_file.dart'; // Reemplazado por url_launcher
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
// Importaciones necesarias ya incluidas arriba

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final Key _newsListKey = Key('newsListKey');
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';
  final bool _isSearching = false;
 
  int _selectedNavIndex = 0;
  final DateTime _targetDate = DateTime(2025, 8, 20); 
  late Timer _timer;
  int? diasRestantes;
  
  // Variables para noticias
  List<NewsArticle> _newsArticles = [];
  int _displayedNewsCount = 2;
  
  // Variables para cumpleaños
  bool esCumpleanos = false;
  bool mostrarBannerCumpleanos = true;

  late Future<List<Map<String, dynamic>>> _futureDocumentos = Future.value([]);

 Future<void> _cargarDocumentos() async {
  try {
    // Verificar que hay datos de usuario válidos antes de cargar documentos
    final datosUsuario = await obtenerDatosUsuario();
    
    if (datosUsuario == null || datosUsuario['token'] == null) {
      print("⚠️ No hay token válido para cargar documentos");
      // Intentar actualizar la sesión o mostrar un mensaje apropiado
      setState(() {
        _futureDocumentos = Future.value([]);
      });
      return;
    }
    
    // Si hay token válido, cargar los documentos
    setState(() {
      _futureDocumentos = DocumentoUsuario().obtenerDocumentos();
    });
  } catch (e) {
    print("❌ Error al iniciar carga de documentos: $e");
    setState(() {
      _futureDocumentos = Future.value([]);
    });
  }
}


  // Variables para migración
  final List<Map<String, dynamic>> _migraciones = [];
  final bool _isLoading = true;
  
  // Variables para el tema
  late Color backgroundColor;
  late Color primaryTextColor;
  late Color secondaryTextColor;
  late Color cardBgColor;
  late Color migrationCardColor;
  late Color dividerColor;
  late Color accentColor;

  int _remainingDays = 0;
  
  // Variable para almacenar la última fecha de actualización de noticias
  DateTime? _lastNewsUpdate;

  late Future<List<Map<String, dynamic>>?> _futureCategorias;

  late Future<List<Map<String, dynamic>>> futureMigraciones;

  // Variables para documentos
  final List<Map<String, dynamic>> _documentos = [];
  bool _isUploading = false;

  String userName = '';
  String imagenUrl = '';
  bool isLoading = true;
  ImageProvider? _imagenLocal;

  Future<void> _cargarImagenLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagenLocalPath = prefs.getString('imagen_local_path');
      
      if (imagenLocalPath != null) {
        final file = File(imagenLocalPath);
        if (await file.exists()) {
          setState(() {
            _imagenLocal = FileImage(file);
            print("Imagen local cargada desde: $imagenLocalPath");
          });
        }
      }
    } catch (e) {
      print("Error al cargar imagen local: $e");
    }
  }

  void cargarUsuarioDatos() async {
    try {
      // Obtener datos del usuario desde SharedPreferences
      final userData = await obtenerDatosUsuario();

      if (userData != null) {
        setState(() {
          // Actualizar datos del usuario en esta pantalla
          userName = userData['usuario']['name'] ?? 'Usuario';
          imagenUrl = userData['usuario']['imagen_url'] ?? '';
          isLoading = false;
        });
        
        // Guardar datos en SharedPreferences para sincronización entre pantallas
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nombre_usuario', userName);
        await prefs.setString('imagen_url', imagenUrl);
        
        print("✅ Datos de usuario cargados en Home: $userName");
      }
      
      // Verificar si hay una imagen local guardada
      await _verificarImagenLocal();
      await _cargarImagenLocal();
    } catch (e) {
      print("❌ Error al cargar datos de usuario en Home: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Método para verificar si es cumpleaños
  Future<void> _verificarCumpleanos() async {
    try {
      final esCumpleanosHoy = await NotificacionesServicio.esCumpleanosHoy();
      if (mounted) {
        setState(() {
          esCumpleanos = esCumpleanosHoy;
        });
      }
      
      // Verificar y enviar notificación si es necesario
      if (esCumpleanosHoy) {
        await NotificacionesServicio.verificarCumpleanos();
      }
    } catch (e) {
      print('Error al verificar cumpleaños: $e');
    }
  }

  Future<void> _verificarImagenLocal() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Verificar si hay una imagen guardada en SharedPreferences (desde otra pantalla)
    final imagenUrlGuardada = prefs.getString('imagen_url');
    if (imagenUrlGuardada != null && imagenUrlGuardada.isNotEmpty && imagenUrlGuardada != imagenUrl) {
      setState(() {
        imagenUrl = imagenUrlGuardada;
        print("✅ Sincronizando imagen desde SharedPreferences en Home: $imagenUrl");
      });
      return;
    }
    
    // Si no hay imagen URL del servidor, intentar usar la imagen local
    if (imagenUrl.isEmpty) {
      final imagenLocalPath = prefs.getString('imagen_local_path');
      
      if (imagenLocalPath != null) {
        final file = File(imagenLocalPath);
        if (await file.exists()) {
          setState(() {
            // Usar la ruta local como URL
            imagenUrl = 'file://$imagenLocalPath';
            // Guardar para sincronizar con otras pantallas
            prefs.setString('imagen_url', imagenUrl);
            print("✅ Usando imagen local en Home: $imagenUrl");
          });
        }
      }
    } else {
      // Si tenemos una imagen URL, guardarla para sincronizar con otras pantallas
      prefs.setString('imagen_url', imagenUrl);
    }
  }

  @override
  void initState() {
    super.initState();
    
    cargarUsuarioDatos();
    _verificarCumpleanos(); // Verificar si es cumpleaños
    // Llamadas de prueba removidas para producción
    
    _calculateRemainingDays();
     _cargarDocumentos();
    _timer = Timer.periodic(Duration(days: 1), (timer) {
      _calculateRemainingDays();
    });

    cargarDatosMigracion();

    // Carga inmediata de noticias de respaldo para evitar pantalla vacía
    _loadMockNewsWithTodayDate();
    
    // Intenta cargar noticias reales después
    fetchHealthNews();

    // Configura el timer para actualizar las noticias cada 3 horas
    Timer.periodic(const Duration(hours: 3), (timer) {
      // Verificar si ha pasado un día desde la última actualización
      final DateTime now = DateTime.now();
      final String todayDate = now.toIso8601String().split('T')[0];
      
      // Si _lastNewsUpdate es de un día diferente o han pasado más de 3 horas, actualizar
      if (_lastNewsUpdate == null || 
          !_lastNewsUpdate!.toIso8601String().startsWith(todayDate) ||
          now.difference(_lastNewsUpdate!).inHours >= 3) {
        print('🔄 Actualizando noticias - Nueva fecha o han pasado 3+ horas');
        fetchHealthNews();
      } else {
        print('⏳ Omitiendo actualización - Noticias ya actualizadas hoy hace menos de 3 horas');
      }
    });

    _futureCategorias = CategoriaServicio().obtenerCategorias();
    
    // Asegurar que siempre haya al menos una cita
    futureMigraciones = MigracionServicio().obtenerMigracionesUsuarios()
      .then((value) {
        List<Map<String, dynamic>> migraciones = value ?? [];
        
        // Si no hay citas, agregar una cita de ejemplo
        if (migraciones.isEmpty) {
          // migraciones.add({
          //   'id': 1,
          //   'estado_caso': 'Audiencia Pendiente',
          //   'estado_asilo': 'En Proceso',
          //   'fecha_audiencia': '20/04/2025',
          //   'descripcion': 'Audiencia para revisión de caso de asilo',
          //   'lugar': 'Corte de Inmigración',
          //   'hora': '8:00 a.m.'
          // });
        }
        
        return migraciones;
      });
    
    _addDefaultDocuments(); // Añadir documentos por defecto
  }

  Future<void> fetchHealthNews() async {
    try {
      print('=== INICIO DE ACTUALIZACIÓN DE NOTICIAS ===');
      print('⌛ Iniciando carga de noticias migratorias...');

      // Obtener la fecha actual para el log y filtrado
      final DateTime now = DateTime.now();
      final String todayDate = now.toIso8601String().split('T')[0]; // Formato YYYY-MM-DD
      print('📅 Fecha de actualización: $todayDate');

      // Usando API completamente gratuita sin API key - JSONPlaceholder para demo
      final response = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Estado de la respuesta: ${response.statusCode}');
      
      // Si hay error 401, usar noticias mock directamente
      if (response.statusCode == 401) {
        print('❌ Error 401: API key inválida o expirada. Usando noticias de respaldo.');
        setState(() {
          _newsArticles = _getMockNews();
        });
        return;
      }
      
      if (response.statusCode == 200) {
        final List<dynamic> posts = json.decode(response.body);
        
        if (posts.isNotEmpty) {
          print('📚 Total de artículos encontrados: ${posts.length}');
          
          final List<dynamic> articles = posts.take(10).toList();
          
          if (articles.isNotEmpty) {
            // Títulos específicos sobre migración e ICE en español
            final List<String> migrationTitles = [
              'ICE anuncia nuevas políticas de deportación para 2025',
              'Departamento de Migración actualiza requisitos para visa de trabajo',
              'Nuevas medidas de ICE afectan a solicitantes de asilo en la frontera',
              'Cambios en el proceso de naturalización estadounidense',
              'ICE implementa tecnología avanzada en centros de detención',
              'Programa de reunificación familiar amplía sus beneficios',
              'Nuevas regulaciones para trabajadores agrícolas migrantes',
              'ICE y CBP coordinan operativos en ciudades santuario',
              'Actualización sobre el programa DACA y beneficiarios elegibles',
              'Departamento de Migración facilita trámites consulares'
            ];

            final List<NewsArticle> newArticles = articles.take(10).map((post) {
              final int index = articles.indexOf(post);
              final String title = migrationTitles[index % migrationTitles.length];
              
              print('📰 Artículo: $title');
              
              final String imageUrl = _getImageForIndex(index);
              
              return NewsArticle(
                title: title,
                description: 'Información actualizada sobre políticas migratorias, procedimientos de ICE y cambios en las regulaciones de inmigración en Estados Unidos.',
                content: 'El Departamento de Seguridad Nacional y ICE han anunciado importantes actualizaciones en las políticas migratorias que afectarán a miles de inmigrantes en Estados Unidos. Estas medidas buscan modernizar los procesos y mejorar la eficiencia en el sistema migratorio.',
                url: 'https://ice.gov/news/post/${post['id']}',
                urlToImage: imageUrl,
                author: 'Departamento de ICE',
                publishedAt: '${todayDate}T12:00:00Z',
              );
            }).toList();
            
            // Filtrar solo noticias de hoy
            final List<NewsArticle> todayArticles = newArticles.where((article) {
              if (article.publishedAt == null || article.publishedAt!.isEmpty) return false;
              return article.publishedAt!.startsWith(todayDate);
            }).toList();
            
            print('📅 Noticias de hoy encontradas: ${todayArticles.length}');
            
            if (todayArticles.isNotEmpty) {
              setState(() {
                // Reemplazar completamente las noticias anteriores con las nuevas de hoy
                _newsArticles = [...todayArticles];
                
                // Si hay menos de 4 noticias de hoy, agregar algunas de respaldo pero marcadas como de hoy
                if (_newsArticles.length < 4) {
                  final mockNews = _getMockNews();
                  _newsArticles.addAll(mockNews.take(4 - _newsArticles.length));
                }
                
                // Ordenar por hora de publicación (más reciente primero)
                _newsArticles.sort((a, b) {
                  if (a.publishedAt == null) return 1;
                  if (b.publishedAt == null) return -1;
                  return DateTime.parse(b.publishedAt!)
                      .compareTo(DateTime.parse(a.publishedAt!));
                });
                
                print('📅 Noticias ordenadas por hora: más recientes primero');
                print('📰 Total de noticias disponibles: ${_newsArticles.length}');
                
                // Guardar la fecha de última actualización
                _lastNewsUpdate = now;
              });
              return;
            }
          }
        }
        
        print('! No se encontraron artículos de hoy, usando noticias de respaldo con fecha actual');
        _loadMockNewsWithTodayDate();
      } else {
        print('❌ Error en la solicitud: ${response.statusCode}');
        _loadMockNewsWithTodayDate();
      }
    } catch (e) {
      print('❌ Excepción durante la carga de noticias: $e');
      _loadMockNewsWithTodayDate();
    }
  }
  
  // Carga noticias de respaldo pero con la fecha actual
  void _loadMockNewsWithTodayDate() {
    final DateTime now = DateTime.now();
    final String todayDate = now.toIso8601String().split('T')[0];
    
    setState(() {
      _newsArticles = _getMockNews().map((article) {
        // Mantener la misma imagen que ya tiene asignada cada artículo
        return NewsArticle(
          title: article.title,
          description: article.description,
          content: article.content,
          url: article.url,
          urlToImage: article.urlToImage,
          author: article.author,
          publishedAt: '${todayDate}T${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00Z',
        );
      }).toList();
      
      // Guardar la fecha de última actualización
      _lastNewsUpdate = now;
    });
  }

  List<NewsArticle> _getMockNews() {
    return [
      NewsArticle(
        title: 'USCIS anuncia nuevas políticas de asilo para solicitantes en la frontera sur',
        description: 'El Servicio de Ciudadanía e Inmigración de EE.UU. ha implementado cambios significativos en el proceso de asilo para agilizar las solicitudes.',
        urlToImage: 'https://media.diariolasamericas.com/p/50f9d8591896aba04f9428e16bf7083f/adjuntos/216/imagenes/100/061/0100061903/855x0/smart/inmigracion-ice-ap-denis-poroyjpg-2023.jpg',
        url: 'https://example.com/noticias/1',
        content: 'El Servicio de Ciudadanía e Inmigración de Estados Unidos (USCIS) anunció hoy la implementación de nuevas políticas que buscan agilizar el proceso de asilo para solicitantes que se presentan en la frontera sur. Según el comunicado oficial, estos cambios permitirán procesar más rápidamente las solicitudes legítimas mientras se mantienen los estándares de seguridad. "Nuestro objetivo es crear un sistema de asilo más eficiente y humano", declaró el director de USCIS. Las nuevas medidas incluyen entrevistas iniciales más breves y un mayor número de oficiales de asilo desplegados en la frontera.',
        author: 'Carlos Rodríguez',
        publishedAt: '2025-04-02T08:30:00Z',
      ),
      NewsArticle(
        title: 'USCIS reduce tiempos de procesamiento para permisos de trabajo',
        description: 'La oficina de Servicios de Ciudadanía e Inmigración ha implementado cambios para reducir los tiempos de espera para los permisos de trabajo.',
        urlToImage: 'https://www.getgordon.com/wp-content/uploads/2022/08/Flags-and-Immigration-Papers.jpg',
        url: 'https://example.com/noticias/2',
        content: 'USCIS anunció hoy una serie de medidas para reducir significativamente los tiempos de procesamiento de los formularios I-765, utilizados para solicitar la Autorización de Empleo (EAD). Según el comunicado, los solicitantes ahora pueden esperar recibir una respuesta en un plazo de 30 días, en comparación con los 90 días anteriores. Esta medida beneficiará a miles de inmigrantes que esperan poder trabajar legalmente en los Estados Unidos, incluyendo solicitantes de asilo, beneficiarios de DACA y titulares de visas que califican para autorización de empleo.',
        author: 'María González',
        publishedAt: '2025-04-02T10:15:00Z',
      ),
      NewsArticle(
        title: 'Organizaciones en California ofrecen recursos legales gratuitos para inmigrantes',
        description: 'Una coalición de organizaciones sin fines de lucro en California ha lanzado una iniciativa para proporcionar asesoramiento legal gratuito a inmigrantes.',
        urlToImage: 'https://www.ncronline.org/files/2024-11/11.13.24%20Immigration.JPG',
        url: 'https://example.com/noticias/3',
        content: 'Una coalición de organizaciones sin fines de lucro en California ha lanzado hoy una iniciativa para proporcionar asesoramiento legal gratuito a inmigrantes que enfrentan procesos de deportación o buscan regularizar su estatus migratorio. El programa, financiado por el estado de California y donaciones privadas, ofrecerá consultas individuales, talleres informativos y representación legal en la corte. "Queremos asegurarnos de que todos los inmigrantes en California conozcan sus derechos y tengan acceso a la representación legal que merecen", explicó la directora del programa. Los servicios estarán disponibles en español, inglés y otros idiomas según sea necesario.',
        author: 'Roberto Sánchez',
        publishedAt: '2025-04-02T12:45:00Z',
      ),
      NewsArticle(
        title: 'DHS anuncia cambios en los requisitos para obtener la Green Card',
        description: 'El Departamento de Seguridad Nacional ha actualizado los requisitos para solicitar la residencia permanente en Estados Unidos.',
        urlToImage: 'https://attlaw.com/wp-content/uploads/2020/03/ice-police.jpg',
        url: 'https://example.com/noticias/4',
        content: 'El Departamento de Seguridad Nacional (DHS) anunció hoy cambios significativos en los requisitos para obtener la residencia permanente legal en Estados Unidos, comúnmente conocida como Green Card. Entre las modificaciones más importantes se encuentra la simplificación del proceso de solicitud para cónyuges de ciudadanos estadounidenses y la clarificación de los criterios de "carga pública". Según el comunicado oficial, estos cambios buscan "crear un sistema de inmigración más justo y eficiente". Los nuevos formularios y requisitos entrarán en vigor a partir del próximo mes.',
        author: 'Ana Martínez',
        publishedAt: '2025-04-02T14:20:00Z',
      ),
      NewsArticle(
        title: 'Texas implementa controvertida ley que afecta a comunidades inmigrantes',
        description: 'La nueva legislación de Texas otorga a las autoridades estatales poderes adicionales para detener a personas sospechosas de haber cruzado la frontera ilegalmente.',
        urlToImage: 'https://assets-wp.boundless.com/uploads/2021/05/uscis-2-700x350.jpg',
        url: 'https://example.com/noticias/5',
        content: 'El estado de Texas comenzó a implementar hoy una controvertida ley que otorga a las autoridades estatales el poder de arrestar a personas sospechosas de haber cruzado la frontera ilegalmente. La medida, conocida como SB4, ha generado protestas en varias ciudades del estado y ha sido criticada por organizaciones de derechos civiles que argumentan que podría conducir a perfiles raciales. Defensores de la ley, por otro lado, afirman que es necesaria para abordar lo que consideran una crisis en la frontera. Varios grupos han presentado demandas desafiando la constitucionalidad de la ley, argumentando que la inmigración es competencia federal, no estatal.',
        author: 'Luis Hernández',
        publishedAt: '2025-04-02T16:05:00Z',
      ),
      NewsArticle(
        title: 'ICE modifica políticas de detención para familias migrantes',
        description: 'El Servicio de Inmigración y Control de Aduanas anuncia cambios significativos en cómo maneja la detención de familias con niños.',
        urlToImage: 'https://gdb.voanews.com/3a34beed-6344-46c2-9a2e-346329da3f78_cx0_cy1_cw0_w1200_r1.jpg',
        url: 'https://example.com/noticias/6',
        content: 'El Servicio de Inmigración y Control de Aduanas (ICE) anunció hoy modificaciones importantes en sus políticas de detención para familias migrantes con niños. Según el comunicado oficial, ICE limitará la detención de familias a un máximo de 20 días y priorizará alternativas a la detención, como programas de supervisión comunitaria. "Estas políticas reflejan nuestro compromiso con un sistema de inmigración humano que respeta la unidad familiar mientras mantiene la seguridad de nuestras fronteras", declaró el director de ICE. Grupos de defensa de inmigrantes han recibido positivamente estos cambios, aunque algunos argumentan que no son suficientes.',
        author: 'Elena Torres',
        publishedAt: '2025-04-02T17:30:00Z',
      ),
    ];
  }

  String _getImageForTopic(String title, String description) {
    // Este método se reemplaza por _getMigrationImage que cambia imágenes cada 24 horas
    return _getMigrationImage();
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
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barra de arrastre
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 10),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Imagen
                      if (_isValidImageUrl(article.urlToImage))
                        SizedBox(
                          width: double.infinity,
                          height: 200,
                          child: Image.network(
                            article.urlToImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.network(
                                _getImageForTopic(article.title ?? '', article.description ?? ''),
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 200,
                          child: Image.network(
                            _getImageForTopic(article.title ?? '', article.description ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                      // Contenido
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.title ?? 'Noticia migratoria',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : const Color(0xFF2D3142),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 16,
                                    color: isDarkMode ? Colors.white70 : Color(0xFF9BA0AB),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    article.author ?? 'Autor desconocido',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.white70 : Color(0xFF9BA0AB),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: isDarkMode ? Colors.white70 : Color(0xFF9BA0AB),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    article.publishedAt != null
                                        ? _formatDate(article.publishedAt!)
                                        : 'Fecha desconocida',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.white70 : Color(0xFF9BA0AB),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                article.description ?? 'No hay descripción disponible',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF2D3142),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                article.content ?? 'No hay contenido disponible',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDarkMode ? Colors.white70 : const Color(0xFF2D3142),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (article.url != null && article.url!.isNotEmpty)
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () => _launchURL(article.url!),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4485FD),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text(
                                      'Leer artículo completo',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
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

  Future<void> _launchURL(String url) async {
    // Verifica si la URL es de ejemplo y redirige a una URL real sobre inmigración
    if (url.contains('example.com')) {
      // Obtiene el número de la noticia desde la URL
      final String newsId = url.split('/').last;
      
      // URLs de noticias reales de medios de comunicación sobre temas migratorios
      final Map<String, String> realNewsUrls = {
        '1': 'https://cnnespanol.cnn.com/category/inmigracion/',
        '2': 'https://www.bbc.com/mundo/topics/c404v027pd4t',
        '3': 'https://www.univision.com/noticias/inmigracion',
        '4': 'https://www.telemundo.com/noticias/inmigracion',
        '5': 'https://www.nbcnews.com/latino',
        '6': 'https://www.nytimes.com/es/section/inmigration',
      };
      
      // Usa la URL específica para la noticia o una URL de noticias por defecto si no se encuentra
      url = realNewsUrls[newsId] ?? 'https://cnnespanol.cnn.com/category/inmigracion/';
    }

    final Uri uri = Uri.parse(url);
    try {
      print('🌐 Abriendo URL: $url');
      final bool launched = await launchUrl(
        uri, 
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
      
      if (!launched) {
        throw Exception('No se pudo lanzar $url');
      }
    } catch (e) {
      print('❌ No se pudo abrir la URL: $url - Error: $e');
      // Intenta abrir un sitio de noticias de inmigración como fallback
      final Uri fallbackUri = Uri.parse('https://cnnespanol.cnn.com/category/inmigracion/');
      try {
        await launchUrl(
          fallbackUri, 
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
      } catch (e) {
        print('❌ Tampoco se pudo abrir la URL de fallback: $e');
      }
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> cargarDatosMigracion() async {
    final data = await MigracionServicio().obtenerdiasMigratoriasUsuario();
    if (data != null) {
      setState(() {
        diasRestantes = (data['dias_restantes'] as num).toInt();
      });
    }
  }



  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateRemainingDays() {
    // Set to 0 days as requested
    _remainingDays = 0;
    diasRestantes = 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // NO guardar automáticamente - solo cuando el usuario elija manualmente
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.darkModeEnabled;
    
    // Define dynamic colors based on dark mode state
    backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    primaryTextColor = isDarkMode ? Colors.white : Color(0xFF2D3142);
    secondaryTextColor = isDarkMode ? Color(0xFFB0B3B8) : Color(0xFF9BA0AB);
    cardBgColor = isDarkMode ? Color(0xFF242526) : Colors.white;
    migrationCardColor = isDarkMode ? Color(0xFF3A3B3C) : const Color.fromARGB(255, 61, 93, 157);
    dividerColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    accentColor = isDarkMode ? Color(0xFF4485FD) : Color(0xFF4485FD);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          print('🔴 PROBANDO NOTIFICACIONES EN SEGUNDO PLANO - DELAY 1 MINUTO');
          
          // Obtener el primer nombre del usuario actual
          final primerNombre = userName.isNotEmpty ? userName.split(' ').first : 'Usuario';
          
          // Usar el nuevo método con delay de 60 segundos (1 minuto)
          await FirebaseNotificacionesServicio.enviarNotificacionLocalConDelay(
            titulo: '🎉 ¡Feliz Cumpleaños $primerNombre!',
            mensaje: '¡Que pases un día súper hermoso con tus seres amados! ❤️✨',
            segundosDelay: 60, // 1 minuto de delay
          );
        },
        child: Icon(Icons.notifications, color: Colors.white),
        backgroundColor: Colors.red, // Rojo para que sea muy visible
        tooltip: 'Probar notificación en segundo plano (1 min delay)',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width < 360 ? 12 : 20,
                  vertical: 16,
                ),
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
                                    fontSize: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width < 360 ? 8 : 16),
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
                            width: MediaQuery.of(context).size.width < 360 ? 40 : 50,
                            height: MediaQuery.of(context).size.width < 360 ? 40 : 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDarkMode ? Colors.grey[800]! : Colors.white,
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
                                          : "https://api-inmigracion.maval.tech/storage/usuarios/$imagenUrl"
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
                    const SizedBox(height: 24),
                    
                    // Banner de Cumpleaños (DISEÑO IDÉNTICO AL DE MEDICAL)
                    if (esCumpleanos && mostrarBannerCumpleanos)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF667eea), // Azul elegante
                              Color(0xFF764ba2), // Púrpura profundo
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667eea).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Icono de cumpleaños
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '🎂',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Texto principal
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¡Feliz Cumpleaños ${userName.isNotEmpty ? userName.split(' ').first : 'Usuario'}! 🎉',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                          color: Colors.black26,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '¡Que pases un día súper hermoso con tu familia! 🎈✨',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                          color: Colors.black26,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Botón de cerrar
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  mostrarBannerCumpleanos = false;
                                });
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    if (esCumpleanos && mostrarBannerCumpleanos)
                      const SizedBox(height: 16),

                    // Countdown Timer Container
                    SizedBox(
                      height: MediaQuery.of(context).size.width < 360 ? 140 : 160,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          // Gradient Background with Animation
                          AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF2E5CB8),
                                  Color(0xFF1E3C72),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          // Decorative Elements
                          Positioned(
                            top: -30,
                            right: -30,
                            child: Container(
                              width: MediaQuery.of(context).size.width < 360 ? 80 : 120,
                              height: MediaQuery.of(context).size.width < 360 ? 80 : 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -20,
                            left: -20,
                            child: Container(
                              width: MediaQuery.of(context).size.width < 360 ? 60 : 80,
                              height: MediaQuery.of(context).size.width < 360 ? 60 : 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width < 360 ? 16 : 24,
                              vertical: MediaQuery.of(context).size.width < 360 ? 16 : 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 6 : 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.calendar_today,
                                        color: Colors.white,
                                        size: MediaQuery.of(context).size.width < 360 ? 20 : 24,
                                      ),
                                    ),
                                    SizedBox(width: MediaQuery.of(context).size.width < 360 ? 10 : 16),
                                    Expanded(
                                      child: Text(
                                       'Te faltan ${diasRestantes ?? 365} días',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: MediaQuery.of(context).size.width < 360 ? 22 : 26,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: MediaQuery.of(context).size.width < 360 ? 8 : 12),
                                Text(
                                  'para poder solicitar tu asilo',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: MediaQuery.of(context).size.width < 360 ? 16 : 18,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: MediaQuery.of(context).size.width < 360 ? 6 : 8),
                                Text(
                                  '¡Recuerdalo y éxitos!',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: MediaQuery.of(context).size.width < 360 ? 13 : 15,
                                    fontStyle: FontStyle.italic,
                                    letterSpacing: 0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Upcoming Appointments Section
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return Text(
                          'Próximas Citas',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: themeProvider.darkModeEnabled 
                                ? Colors.white 
                                : const Color(0xFF2D3142),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    
                 FutureBuilder<List<Map<String, dynamic>>>(
                          future: futureMigraciones,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text("Error: ${snapshot.error}"));
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(child: Text("No hay citas programadas"));
                            }

                            final migraciones = snapshot.data!;

                            return SizedBox(
                              height: MediaQuery.of(context).size.width < 360 ? 160 : 177,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: migraciones.length,
                                itemBuilder: (context, index) {
                                  final migracion = migraciones[index];

                                  return Container(
                                    margin: const EdgeInsets.only(right: 16),
                                    width: MediaQuery.of(context).size.width < 360 ? 260 : 290,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: migrationCardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: MediaQuery.of(context).size.width < 360 ? 50 : 60,
                                              height: MediaQuery.of(context).size.width < 360 ? 50 : 60,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                                image: const DecorationImage(
                                                  image: AssetImage('assets/abogado.webp'), // Imagen de abogado
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    migracion['estado_caso'] ?? 'Desconocido',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: MediaQuery.of(context).size.width < 360 ? 18 : 20,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "Estado Asilo: ${migracion['estado_asilo'] ?? 'No disponible'}",
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => _mostrarDetalles(context, migracion), // Llama a la función al tocar
                                              child: Container(
                                                width: MediaQuery.of(context).size.width < 360 ? 32 : 36,
                                                height: MediaQuery.of(context).size.width < 360 ? 32 : 36,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white.withOpacity(0.2),
                                                ),
                                                child: Icon(
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
                                          color: dividerColor,
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  migracion['fecha_audiencia'] ?? 'Sin fecha',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  "8:00 a. m.",
                                                  style: TextStyle(
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

                  
                    const SizedBox(height: 52),

                    // Documento Upload Section
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: themeProvider.darkModeEnabled 
                                ? const Color(0xFF1E1E1E) 
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.upload_file,
                                    color: themeProvider.darkModeEnabled 
                                        ? Colors.white 
                                        : const Color(0xFF2D3142),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Documentos',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: themeProvider.darkModeEnabled 
                                          ? Colors.white 
                                          : const Color(0xFF2D3142),
                                    ),
                                  ),
                                  if (_isUploading)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            themeProvider.darkModeEnabled
                                                ? Colors.white
                                                : Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: themeProvider.darkModeEnabled ? Color(0xFF242526) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: themeProvider.darkModeEnabled ? Colors.grey.shade800 : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                            width: MediaQuery.of(context).size.width < 360 ? 60 : 70,
                                      height: MediaQuery.of(context).size.width < 360 ? 60 : 70,
                                      decoration: BoxDecoration(
                                        color: themeProvider.darkModeEnabled ? Colors.grey.shade800 : Colors.grey.shade200,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 36,
                                        color: themeProvider.darkModeEnabled ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Suba o tome una foto de su documento (PNG, JPG, PDF, Word, etc.):',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
                                        color: themeProvider.darkModeEnabled ? Colors.grey.shade400 : Colors.grey.shade600,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              _pickFiles();
                                            },
                                            icon: Icon(Icons.upload_file, color: Colors.white),
                                            label: Text('Subir archivo', style: TextStyle(color: Colors.white)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF4CAF50),
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              _takePicture();
                                            },
                                            icon: Icon(Icons.camera_alt, color: Colors.white),
                                            label: Text('Capturar foto', style: TextStyle(color: Colors.white)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF4485FD),
                                              padding: EdgeInsets.symmetric(vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
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
                      },
                    ),
                    
                    const SizedBox(height: 12),

                    // Lista de documentos subidos
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return _documentos.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  Text(
                                    'Archivos subidos',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: themeProvider.darkModeEnabled 
                                          ? Colors.white 
                                          : const Color(0xFF2D3142),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                              FutureBuilder<List<Map<String, dynamic>>>(
                                    future: _futureDocumentos,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Center(child: CircularProgressIndicator());
                                      } else if (snapshot.hasError) {
                                        return Center(child: Text('Error: ${snapshot.error}'));
                                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                        return Center(child: Text('No hay documentos.'));
                                      }

                                      final documentos = snapshot.data!;

                                      return ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: documentos.length,
                                        itemBuilder: (context, index) {
                                          final doc = documentos[index];
                                          final nombre = doc['nombre_documentos'] ?? '';
                                          final extension = nombre.split('.').last.toLowerCase();
                                          final isImage = ['jpg', 'jpeg', 'png'].contains(extension);
                                          final tamanoTexto = doc['tamaño'] ?? '0 KB';


                                          return Container(
                                            margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.width < 360 ? 6 : 8),
                                            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 360 ? 8 : 12),
                                            decoration: BoxDecoration(
                                              color: themeProvider.darkModeEnabled
                                                  ? Color(0xFF242526)
                                                  : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: themeProvider.darkModeEnabled
                                                    ? Colors.grey.shade700
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: MediaQuery.of(context).size.width < 360 ? 32 : 40,
                                                  height: MediaQuery.of(context).size.width < 360 ? 32 : 40,
                                                  decoration: BoxDecoration(
                                                    color: themeProvider.darkModeEnabled
                                                        ? Colors.grey.shade700
                                                        : Colors.white,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    isImage ? Icons.image : Icons.insert_drive_file,
                                                    color: isImage
                                                        ? Colors.blue
                                                        : (extension == 'pdf' ? Colors.red : Colors.orange),
                                                    size: 24,
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        nombre,
                                                        style: TextStyle(
                                                          fontSize: MediaQuery.of(context).size.width < 360 ? 12 : 14,
                                                          fontWeight: FontWeight.w500,
                                                          color: themeProvider.darkModeEnabled
                                                              ? Colors.white
                                                              : Colors.black87,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        '$tamanoTexto • ${extension.toUpperCase()}',
                                                        style: TextStyle(
                                                          fontSize: MediaQuery.of(context).size.width < 360 ? 10 : 12,
                                                          color: themeProvider.darkModeEnabled
                                                              ? Colors.grey.shade400
                                                              : Colors.grey.shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Icono de descarga
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.download_outlined,
                                                    color: Colors.blue.shade400,
                                                    size: 20,
                                                  ),
                                                  onPressed: () {
                                                    descargarDocumento(documentos[index]['nombre_documentos']);
                                                  },
                                                ),
                                                // Icono de eliminar
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red.shade300,
                                                    size: 20,
                                                  ),
                                               onPressed: () {
                                                    mostrarDialogoEliminarDocumento(
                                                      context: context,
                                                      onConfirmar: () {
                                                       eliminarDocumento(documentos[index]['id']);
                                                      },
                                                    );
                                                  },


                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  )
                                  ],


                              )
                            : SizedBox.shrink();
                      },
                    ),
                    
                    const SizedBox(height: 24),

                    // Categories Section
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     const Text(
                    //       'Categories',
                    //       style: TextStyle(
                    //         fontSize: 20,
                    //         fontWeight: FontWeight.w700,
                    //         color: Color(0xFF2D3142),
                    //       ),
                    //     ),
                    //     TextButton(
                    //       onPressed: () {
                    //         Navigator.push(
                    //           context,
                    //           MaterialPageRoute(
                    //             builder: (context) => const CategoriesScreen(),
                    //           ),
                    //         );
                    //       },
                    //       child: const Text(
                    //         'See All',
                    //         style: TextStyle(
                    //           fontSize: 14,
                    //           fontWeight: FontWeight.w600,
                    //           color: Color(0xFF4485FD),
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                   
                   
                    const SizedBox(height: 16),

                    // Categories Grid

                    
                  //  FutureBuilder<List<Map<String, dynamic>>>(
                  //   future: _futureCategorias,
                  //   builder: (context, snapshot) {
                  //     if (snapshot.connectionState == ConnectionState.waiting) {
                  //       return const Center(child: CircularProgressIndicator());
                  //     } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                  //       return const Center(child: Text("No hay categorías disponibles"));
                  //     }

                  //     final categorias = snapshot.data!.take(8).toList();

                  //     return GridView.builder(
                  //       shrinkWrap: true,
                  //       physics: const NeverScrollableScrollPhysics(),
                  //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  //         crossAxisCount: 4,
                  //         mainAxisSpacing: 16,
                  //         crossAxisSpacing: 16,
                  //         childAspectRatio: 1,
                  //       ),
                  //       itemCount: categorias.length,
                  //       itemBuilder: (context, index) {
                  //         final categoria = categorias[index];

                  //         return Container(
                  //           decoration: BoxDecoration(
                  //             color: Colors.white,
                  //             borderRadius: BorderRadius.circular(16),
                  //             boxShadow: [
                  //               BoxShadow(
                  //                 color: Colors.grey.withOpacity(0.1),
                  //                 spreadRadius: 0,
                  //                 blurRadius: 10,
                  //                 offset: const Offset(0, 4),
                  //               ),
                  //             ],
                  //           ),
                  //           child: Column(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               SizedBox(
                  //                 width: 32,
                  //                 height: 32,
                  //                 child: Image.network(
                  //                   categoria['icono'] ?? '', // Ajusta según tu API
                  //                   errorBuilder: (context, error, stackTrace) =>
                  //                       const Icon(Icons.image_not_supported),
                  //                 ),
                  //               ),
                  //               const SizedBox(height: 8),
                  //               Text(
                  //                 categoria['nombre']?.length > 10 
                  //                     ? '${categoria['nombre']?.substring(0, 10)}...' 
                  //                     : categoria['nombre'] ?? 'Sin nombre',
                  //                 style: TextStyle(
                  //                   fontSize: 12,
                  //                   color: primaryTextColor,
                  //                   fontWeight: FontWeight.w500,
                  //                 ),
                  //                 textAlign: TextAlign.center,
                  //                 overflow: TextOverflow.ellipsis,
                  //               ),
                  //             ],
                  //           ),
                  //         );
                  //       },
                  //     );
                  //   },
                  // ),

                    // Book Appointment Button
                    // Center(
                    //   child: PulsingButton(
                    //     width: MediaQuery.of(context).size.width * 0.8,
                    //     text: 'Book Appointment',
                    //     onPressed: () {
                    //       Navigator.push(
                    //         context,
                    //         MaterialPageRoute(
                    //           builder: (context) => const BookAppointmentScreen(),
                    //         ),
                    //       );
                    //     },
                    //   ),
                    // ),
                    
                    _buildNewsSection(),
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
                child: _buildNavItem(Icons.home, _selectedNavIndex == 0),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatScreen(),
                    ),
                  );
                  setState(() => _selectedNavIndex = 1);
                },
                child: _buildNavItem(Icons.chat, _selectedNavIndex == 1),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                  setState(() => _selectedNavIndex = 2);
                },
                child: _buildNavItem(Icons.person, _selectedNavIndex == 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalCenterCard(String name, String imagePath) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cardBgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              imagePath,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              name.length > 12 ? '${name.substring(0, 12)}...' : name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: primaryTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isSelected) {
    String iconAsset;
    if (icon == Icons.home) {
      iconAsset = 'assets/icons/home.png';
    } else if (icon == Icons.chat) {
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
  
  Widget _buildNewsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;
    final double horizontalPadding = isSmallScreen ? 12 : 20;
    final double titleFontSize = isSmallScreen ? 18 : 22;
    final double subtitleFontSize = isSmallScreen ? 12 : 14;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACTUALIDAD MIGRATORIA',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: accentColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmallScreen ? 4 : 6),
              Text(
                'Información relevante para tu proceso',
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Container(
                width: 60,
                height: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              if (_newsArticles.length > 2)
                Align(
                  alignment: Alignment.centerRight,
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
                      backgroundColor: accentColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 24, 
                        vertical: isSmallScreen ? 8 : 10
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Ver todas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 20
          ),
          child: ListView.builder(
            key: _newsListKey,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _newsArticles.isEmpty
                ? 1
                : _displayedNewsCount > _newsArticles.length
                    ? _newsArticles.length
                    : _displayedNewsCount,
            itemBuilder: (context, index) {
              if (_newsArticles.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Cargando noticias...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ),
                );
              }

              final article = _newsArticles[index];
              final double imageSize = isSmallScreen ? 80 : 100;
              
              return GestureDetector(
                onTap: () => _showNewsDetail(article, context),
                child: Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: SizedBox(
                          width: imageSize,
                          height: imageSize,
                          child: _isValidImageUrl(article.urlToImage)
                              ? Image.network(
                                  article.urlToImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Image.network(
                                  _getImageForTopic(article.title ?? '', article.description ?? ''),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.title ?? 'Noticia migratoria',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
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
                                  color: secondaryTextColor,
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
                  backgroundColor: accentColor,
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

  void _mostrarDetalles(BuildContext context, Map<String, dynamic> migracion) {

    print('Migración: $migracion');

  
  
  // Estado de asilo seleccionado (inicialmente el valor actual)
  String estadoAsiloSeleccionado;
  // Verificar si el valor de migracion['estado_asilo'] está en las opciones
  estadoAsiloSeleccionado = migracion['estado_asilo'] ?? "Pendiente";

  
  // Obtener los días restantes de la tarjeta azul
  // final diasParaSometer = diasRestantes?.toString() ?? '363';
  final diasParaSometer = migracion['dias_recordatorios']?.toString() ?? '365';
  // Usar el tema actual
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final isDarkMode = themeProvider.darkModeEnabled;
  
  // Colores según el tema
  final Color primaryColor = Color(0xFF4A9B7F); // Color verde de la versión migration
  final Color backgroundColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;
  final Color textColor = isDarkMode ? Colors.white : Colors.black87;
  final Color subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;
  final Color cardColor = isDarkMode ? Color(0xFF2A2A2A) : Colors.grey.shade50;
  final Color dividerColor = isDarkMode ? Colors.white24 : Colors.black12;
  
 showDialog(
  context: context,
  builder: (BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        // ✅ Función declarada ANTES de su uso
        Widget _buildInfoItem({
          required String title,
          required String value,
          required IconData icon,
          required Color textColor,
          required Color subtitleColor,
          required Color backgroundColor,
        }) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: subtitleColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(icon, color: primaryColor, size: 24),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Dialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: EdgeInsets.all(0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Encabezado
                Container(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Detalles del Caso",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido principal
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoItem(
                          title: "Estado del Caso",
                          value: migracion['estado_caso'] ?? 'Pendiente',
                          icon: Icons.gavel,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          backgroundColor: cardColor,
                        ),
                        SizedBox(height: 16),

                        // Estado de Asilo
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Estado de Asilo",
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: dividerColor),
                              ),
                              child: TextField(
                                controller: TextEditingController(text: estadoAsiloSeleccionado),
                                enabled: false,
                                decoration: InputDecoration.collapsed(hintText: ''),
                                style: TextStyle(color: textColor, fontSize: 16),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        _buildInfoItem(
                          title: "Fecha de Corte",
                          value: migracion['fecha_audiencia'] ?? '2025-04-23',
                          icon: Icons.calendar_today,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          backgroundColor: cardColor,
                        ),
                        SizedBox(height: 16),

                        _buildInfoItem(
                          title: "Fecha para",
                          value: "${migracion['fecha_audiencia'] ?? '2025-04-23'} - $estadoAsiloSeleccionado",
                          icon: Icons.event_note,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          backgroundColor: cardColor,
                        ),
                        SizedBox(height: 16),

                        // Someter Asilo antes de...
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.hourglass_top, color: Colors.white, size: 24),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Someter Asilo antes de",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          diasParaSometer,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          "días",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16),

                            if (migracion['nota'] != null && migracion['nota'] != 'Sin nota') ...[
                              Text(
                                "Nota",
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: dividerColor),
                                ),
                                child: Text(
                                  migracion['nota'] ?? 'Sin nota',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                  maxLines: null,
                                ),
                              ),
                              SizedBox(height: 16),
                            ],

                            // 🆕 Nuevos datos: Dirección, Tracking, Dirección Usial
                            if (migracion['direccion_id'] != null ||
                                migracion['tracking'] != null ||
                                migracion['direccion_usial'] != null) ...[
                              _buildInfoItem(
                                title: "Dirección ",
                               value: migracion['direccion'] != null
                                ? (migracion['direccion']['nombre']?.toString() ?? 'Sin dirección')
                                : 'Sin dirección',
                                icon: Icons.location_on,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                backgroundColor: cardColor,
                              ),
                              SizedBox(height: 16),

                              _buildInfoItem(
                                title: "Tracking",
                                value: migracion['tracking'] ?? 'Sin tracking',
                                icon: Icons.local_shipping,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                backgroundColor: cardColor,
                              ),
                              SizedBox(height: 16),

                              _buildInfoItem(
                                title: "Dirección Usial",
                                value: migracion['direccion_usial'] ?? 'Sin dirección',
                                icon: Icons.home,
                                textColor: textColor,
                                subtitleColor: subtitleColor,
                                backgroundColor: cardColor,
                              ),
                            ],

                        
                      ],
                    ),
                  ),
                ),

                // Botón Cerrar
                Container(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      minimumSize: Size(double.infinity, 48),
                    ),
                    child: Text(
                      "Cerrar",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

}

// Widget auxiliar para construir elementos de información
Widget _buildInfoItem({
  required String title,
  required String value,
  required IconData icon,
  required Color textColor,
  required Color subtitleColor,
  required Color backgroundColor,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          color: subtitleColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(height: 8),
      Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF4A9B7F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Color(0xFF4A9B7F),
                size: 20,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}  

  // Método para validar URLs de imágenes
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

  // Método para obtener una imagen de migración de EE.UU. basada en la fecha
  String _getMigrationImage() {
    // Obtener la fecha actual
    final DateTime now = DateTime.now();
    
    // Usar el día del año para seleccionar una imagen diferente cada día
    // El módulo asegura que siempre tengamos un índice válido
    final int dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final int imageIndex = dayOfYear % 6;
    
    print('📅 Día del año: $dayOfYear - Índice de imagen: $imageIndex');
    
    // Lista de imágenes específicas de migración en Estados Unidos (URLs directas proporcionadas por el usuario)
    final List<String> migrationImages = [
      'https://media.diariolasamericas.com/p/50f9d8591896aba04f9428e16bf7083f/adjuntos/216/imagenes/100/061/0100061903/855x0/smart/inmigracion-ice-ap-denis-poroyjpg-2023.jpg',
      'https://www.getgordon.com/wp-content/uploads/2022/08/Flags-and-Immigration-Papers.jpg',
      'https://www.ncronline.org/files/2024-11/11.13.24%20Immigration.JPG',
      'https://attlaw.com/wp-content/uploads/2020/03/ice-police.jpg',
      'https://assets-wp.boundless.com/uploads/2021/05/uscis-2-700x350.jpg',
      'https://gdb.voanews.com/3a34beed-6344-46c2-9a2e-346329da3f78_cx0_cy1_cw0_w1200_r1.jpg',
    ];
    
    return migrationImages[imageIndex];
  }

  // Método para obtener una imagen específica basada en el índice
  String _getImageForIndex(int index) {
    // Lista de imágenes específicas de migración en Estados Unidos
    final List<String> migrationImages = [
      'https://media.diariolasamericas.com/p/50f9d8591896aba04f9428e16bf7083f/adjuntos/216/imagenes/100/061/0100061903/855x0/smart/inmigracion-ice-ap-denis-poroyjpg-2023.jpg',
      'https://www.getgordon.com/wp-content/uploads/2022/08/Flags-and-Immigration-Papers.jpg',
      'https://www.ncronline.org/files/2024-11/11.13.24%20Immigration.JPG',
      'https://attlaw.com/wp-content/uploads/2020/03/ice-police.jpg',
      'https://assets-wp.boundless.com/uploads/2021/05/uscis-2-700x350.jpg',
      'https://gdb.voanews.com/3a34beed-6344-46c2-9a2e-346329da3f78_cx0_cy1_cw0_w1200_r1.jpg',
    ];
    
    // Asegurar que el índice esté dentro del rango
    final int safeIndex = index % migrationImages.length;
    return migrationImages[safeIndex];
  }

  // Método para seleccionar archivos
 Future<void> _pickFiles() async {
  try {
    setState(() {
      _isUploading = true;
    });

    final picker = ImagePicker();
    final result = await picker.pickMultipleMedia(imageQuality: 80);

    if (result.isNotEmpty) {
      for (final file in result) {
        final fileBytes = await file.readAsBytes();
        final fileSize = fileBytes.length;
        final fileName = file.name;
        final fileExtension = fileName.split('.').last.toLowerCase();

        // Crear un documento para mostrarlo localmente (opcional)
        Map<String, dynamic> newDoc = {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': fileName,
          'path': file.path,
          'size': fileSize,
          'extension': fileExtension,
          'date': DateTime.now().toIso8601String(),
          'type': 'file',
          'userId': 'current_user_id',
        };

        // ✅ Enviar el archivo al backend como MultipartFile usando los bytes
        final servicioDocumento = DocumentoUsuario();

        final response = await servicioDocumento.registraDocumento(
          archivoBytes: fileBytes,
          nombreArchivo: fileName,
        );

        setState(() {
          _documentos.add(newDoc);
        });
           _cargarDocumentos();
        _showSuccessMessage('Archivo "$fileName" subido correctamente');
      }
    }

    setState(() {
      _isUploading = false;
    });
  } catch (e) {
    print('Error al seleccionar archivo: $e');
    setState(() {
      _isUploading = false;
    });
    _showErrorMessage('Error al seleccionar el archivo: $e');
  }
}



  // Método para capturar fotos
 Future<void> _takePicture() async {
  try {
    setState(() {
      _isUploading = true;
    });

    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (photo != null) {
      final photoBytes = await photo.readAsBytes();
      final photoSize = photoBytes.length;

      // Generar nombre de archivo
      String fileName = 'Foto_${DateTime.now().toIso8601String().replaceAll(':', '-')}.jpg';

      // Crear un documento con la información de la foto
      Map<String, dynamic> newDoc = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': fileName,
        'path': photo.path,
        'size': photoSize,
        'extension': 'jpg',
        'date': DateTime.now().toIso8601String(),
        'type': 'photo',
        'userId': 'current_user_id',
      };

      // ✅ Enviar al backend
      final servicioDocumento = DocumentoUsuario();
      final response = await servicioDocumento.registraDocumento(
        archivoBytes: photoBytes,
        nombreArchivo: fileName,
      );

      setState(() {
        _documentos.add(newDoc);
        _isUploading = false;
      });
       _cargarDocumentos();
      _showSuccessMessage('Foto "$fileName" subida correctamente');
    } else {
      setState(() {
        _isUploading = false;
      });
    }
  } catch (e) {
    print('Error al capturar foto: $e');
    setState(() {
      _isUploading = false;
    });
    _showErrorMessage('Error al capturar la foto: $e');
  }
}


  // Método para mostrar mensaje de éxito
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Método para mostrar mensaje de error
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Método para añadir documentos por defecto
  void _addDefaultDocuments() {
    // Añadir algunos documentos de ejemplo
    _documentos.add({
      'id': '1',
      'name': 'documento_ejemplo.pdf',
      'path': '/ruta/simulada/documento.pdf',
      'size': 1024 * 1024, // 1MB
      'extension': 'pdf',
      'date': DateTime.now().toIso8601String(),
      'type': 'file',
      'base64': 'base64simulado...',
      'userId': 'current_user_id',
    });
    
    _documentos.add({
      'id': '2',
      'name': 'imagen_ejemplo.jpg',
      'path': '/ruta/simulada/imagen.jpg',
      'size': 2 * 1024 * 1024, // 2MB
      'extension': 'jpg',
      'date': DateTime.now().toIso8601String(),
      'type': 'photo',
      'base64': 'base64simulado...',
      'userId': 'current_user_id',
    });
    
    _documentos.add({
      'id': '3',
      'name': 'hoja_calculo.xlsx',
      'path': '/ruta/simulada/excel.xlsx',
      'size': 500 * 1024, // 500KB
      'extension': 'xlsx',
      'date': DateTime.now().toIso8601String(),
      'type': 'file',
      'base64': 'base64simulado...',
      'userId': 'current_user_id',
    });
  }


  void mostrarDialogoEliminarDocumento({
        required BuildContext context,
        required VoidCallback onConfirmar,
      }) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
                  SizedBox(width: 8),
                  Text('Eliminar documento'),
                ],
              ),
              content: Text('¿Estás seguro de que deseas eliminar este documento? Esta acción no se puede deshacer.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar'),
                ),
                ElevatedButton.icon(
                   icon: Icon(
                    Icons.delete_outline,
                    color: Colors.white, // Ícono blanco
                  ),
                  label: Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.white), // Texto blanco
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400, // Fondo rojo
                    ),
                  onPressed: () {
                    Navigator.of(context).pop(); 
                    onConfirmar();
                  },
                ),
              ],
            );
          },
        );
      }


 void eliminarDocumento(int id) async {

    final servicioDocumento = DocumentoUsuario();

    final response = await servicioDocumento.eliminarDocumento(id);
               
    if (response == null) {

    _cargarDocumentos();  
      _showSuccessMessage('Documento eliminado correctamente');

    } else {
      _showErrorMessage('Error al eliminar el documento: $response');
    }

}

void descargarDocumento(String documento) async {
    try {
      // Obtener la extensión del archivo
      final fileExtension = documento.contains('.') ? documento.split('.').last.toLowerCase() : '';
      String tipoArchivo = _getTipoArchivo(fileExtension);
      
      // Mostrar indicador inicial
      ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 16),
            Text('Preparando descarga...'),
          ],
        ),
        duration: Duration(seconds: 3),
        backgroundColor: Color(0xFF4485FD),
      ));
      
      // En Android, mostrar diálogo de permisos y solicitarlos
      if (Platform.isAndroid) {
        messenger.hideCurrentSnackBar();
        
        // El diálogo ahora solicita los permisos automáticamente cuando el usuario acepta
        bool? resultado = await _mostrarDialogoPermisos(tipoArchivo);
        if (resultado != true) {
          throw Exception("Descarga cancelada");
        }
      }
      
      // Mostrar indicador de descarga en progreso
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 16),
            Text('Descargando $tipoArchivo...'),
          ],
        ),
        duration: Duration(seconds: 30),
        backgroundColor: Color(0xFF4485FD),
      ));
      
      // Realizar la descarga
      final servicioDocumento = DocumentoUsuario();
      final downloadedPath = await servicioDocumento.descargarDocumento(documento);
      
      // Ocultar el indicador de progreso
      messenger.hideCurrentSnackBar();
      
      // Verificar si la descarga fue exitosa
      if (downloadedPath != null) {
        // Mostrar mensaje de éxito
        _showSuccessMessage('$tipoArchivo descargado correctamente');
        
        // Intentar abrir el archivo usando url_launcher
        try {
          final uri = Uri.file(downloadedPath);
          final canLaunch = await canLaunchUrl(uri);
          
          if (canLaunch) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            print("Archivo abierto exitosamente: $downloadedPath");
          } else {
            print("No se pudo abrir el archivo: $downloadedPath");
            // Mostrar diálogo informativo para ciertos tipos de archivos
            if (['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'].contains(fileExtension)) {
              _showFileInfoDialog(tipoArchivo, downloadedPath);
            }
          }
        } catch (e) {
          print("Error al abrir el archivo: $e");
          _showFileInfoDialog(tipoArchivo, downloadedPath);
        }
      } else {
        throw Exception('No se pudo descargar el archivo');
      }
    } catch (e) {
      // Simplificar el mensaje de error
      String mensajeError = e.toString();
      if (mensajeError.contains('Exception:')) {
        mensajeError = mensajeError.split('Exception:')[1].trim();
      }
      _showErrorMessage('Error: $mensajeError');
    }
  }
  
  // Función auxiliar para determinar el tipo de archivo
  String _getTipoArchivo(String extension) {
    extension = extension.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return "Imagen";
    } else if (extension == 'pdf') {
      return "Documento PDF";
    } else if (['doc', 'docx'].contains(extension)) {
      return "Documento Word";
    } else if (['xls', 'xlsx'].contains(extension)) {
      return "Hoja de cálculo Excel";
    } else if (['ppt', 'pptx'].contains(extension)) {
      return "Presentación PowerPoint";
    } else if (['mp4', 'avi', 'mov', 'wmv'].contains(extension)) {
      return "Video";
    } else if (['mp3', 'wav', 'ogg'].contains(extension)) {
      return "Audio";
    } else {
      return "Archivo";
    }
  }
  
  // La función de solicitud de permisos ahora está integrada directamente en _mostrarDialogoPermisos
  
  // Función para mostrar un diálogo explicativo de permisos y solicitarlos inmediatamente
  Future<bool?> _mostrarDialogoPermisos(String tipoArchivo) async {
    bool? resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.file_download, color: Color(0xFF4485FD)),
              SizedBox(width: 10),
              Flexible(child: Text('Descargar $tipoArchivo')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Desea descargar este archivo?',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Acciones:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                _buildPermissionItem(Icons.save_alt, 'Guardar archivos en tu dispositivo'),
                _buildPermissionItem(Icons.open_in_new, 'Abrir el archivo descargado'),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: const Color.fromARGB(255, 4, 146, 4)),
                      SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Se mostrará una previsualización tras la descarga.',
                          style: TextStyle(fontSize: 14, color: Colors.blue.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Cancelar'),
                );
              },
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4485FD),
                foregroundColor: Colors.white,
              ),
              child: Text('Descargar'),
            ),
          ],
        );
      },
    );
    
    // Si el usuario acepta, solicitar permisos inmediatamente
    if (resultado == true) {
      // Solicitar permiso de almacenamiento básico primero (funciona en todas las versiones de Android)
      await Permission.storage.request();
      
      // Para Android 11+, intentar solicitar permiso de gestión de almacenamiento
      if (android11OrHigher()) {
        await Permission.manageExternalStorage.request();
      }
      
      // Para Android 13+, solicitar permisos específicos para medios
      if (android13OrHigher()) {
        await Permission.photos.request();
      }
    }
    
    return resultado;
  }
  
  // Widget auxiliar para los elementos de la lista de permisos
  Widget _buildPermissionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Color(0xFF4485FD)),
          SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
  
  // Función para mostrar un diálogo con información del archivo
  void _showFileInfoDialog(String tipoArchivo, String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$tipoArchivo guardado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('El archivo se ha guardado correctamente en:'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  filePath,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              SizedBox(height: 12),
              Text('Es posible que necesites una aplicación compatible para abrir este tipo de archivo.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Entendido'),
            ),
          ],
        );
      },
    );
  }
  
  // Función para verificar si el dispositivo tiene Android 11 o superior
  bool android11OrHigher() {
    if (Platform.isAndroid) {
      try {
        // Android 11 es API 30
        return int.parse(Platform.operatingSystemVersion.split(' ').first) >= 30;
      } catch (e) {
        return false;
      }
    }
    return false;
  }
  
  // Función para verificar si el dispositivo tiene Android 13 o superior
  bool android13OrHigher() {
    if (Platform.isAndroid) {
      try {
        // Android 13 es API 33
        return int.parse(Platform.operatingSystemVersion.split(' ').first) >= 33;
      } catch (e) {
        return false;
      }
    }
    return false;
  }
}
