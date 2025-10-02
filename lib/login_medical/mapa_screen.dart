import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:mi_app_flutter/login_medical/screens_medical/home.dart';
import 'package:mi_app_flutter/login_medical/screens_medical/profile_screen.dart';
import 'package:mi_app_flutter/login_medical/screens_medical/chats_screen.dart';
import 'package:mi_app_flutter/login_medical/screens_medical/appointment_psychology_screen.dart';
import 'dart:math';
import 'dart:async';
// import 'dart:io'; // No se usa
import 'dart:core';
import 'package:mi_app_flutter/utils/text_decoder.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenStreetMapPage extends StatefulWidget {
  const OpenStreetMapPage({super.key});

  @override
  State<OpenStreetMapPage> createState() => _OpenStreetMapPageState();
}

class HospitalPinIcon extends StatelessWidget {
  const HospitalPinIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 80,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Pin shape
          Positioned(
            top: 0,
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.local_hospital,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                // Triángulo inferior
                Container(
                  width: 0,
                  height: 0,
                  margin: EdgeInsets.only(top: -2),
                  decoration: BoxDecoration(),
                  child: CustomPaint(
                    size: Size(20, 12),
                    painter: _PinTrianglePainter(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UrgentCarePinIcon extends StatelessWidget {
  const UrgentCarePinIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 80,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Pin shape
          Positioned(
            top: 0,
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.medical_services,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                // Triángulo inferior
                Container(
                  width: 0,
                  height: 0,
                  margin: EdgeInsets.only(top: -2),
                  decoration: BoxDecoration(),
                  child: CustomPaint(
                    size: Size(20, 12),
                    painter: _PinTrianglePainter(color: Colors.orange.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PinTrianglePainter extends CustomPainter {
  final Color color;
  _PinTrianglePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = ui.Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OpenStreetMapPageState extends State<OpenStreetMapPage> {
  // Método para lanzar una llamada telefónica
  Future<void> _launchPhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri.parse('tel:${phoneNumber.replaceAll(' ', '')}');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      print('No se pudo iniciar la llamada a $phoneNumber');
    }
  }

  // Método para abrir un website
  Future<void> _launchWebsite(String website) async {
    final Uri websiteUri = Uri.parse(website);
    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
    } else {
      print('No se pudo abrir el website $website');
    }
  }

  LatLng? userLocation;
  List<Map<String, dynamic>> hospitales = [];
  List<Map<String, dynamic>> urgentCares = [];
  // Solo una lista para cada tipo - ordenados por cercanía
  String? cityName;
  bool isLoading = true;

  // Controlador del mapa para optimizar la carga
  final MapController _mapController = MapController();
  
  // Variable para controlar si hay operaciones en curso
  bool _isCancelled = false;
  
  // Variable para controlar si el mapa está listo
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  @override
  void dispose() {
    // Marcar que las operaciones deben cancelarse
    _isCancelled = true;
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      // Verificar si el widget todavía está montado antes de actualizar el estado
      if (!mounted || _isCancelled) return;

      // Mostrar carga inmediatamente
      setState(() {
        isLoading = true;
      });

      // Verificar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted || _isCancelled) return;

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Se requieren permisos de ubicación para mostrar hospitales cercanos')));

          setState(() {
            isLoading = false;
          });
          return;
        }
      }

      // Obtener la última posición conocida primero (más rápido)
      Position? lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null && mounted && !_isCancelled) {
        // Usar la última posición conocida para mostrar el mapa rápidamente
        setState(() {
          userLocation = LatLng(lastPosition.latitude, lastPosition.longitude);
          isLoading = false;
        });

        // Iniciar la búsqueda de hospitales y urgent cares con esta ubicación inicial
        if (mounted && !_isCancelled) {
          await getCityName(lastPosition.latitude, lastPosition.longitude);
          await buscarHospitalesCercanos();
          await buscarUrgentCaresCercanos();
        }
      }

      // Si el widget ya no está montado, detener la ejecución
      if (!mounted || _isCancelled) return;

      // En paralelo, obtener la posición actual más precisa CON MANEJO DE ERRORES
      try {
        Position currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high, // PRECISIÓN ALTA PARA UBICACIÓN EXACTA
            timeLimit: Duration(seconds: 15) // Timeout aumentado para dar tiempo al GPS
            );

        // Verificar nuevamente si el widget está montado
        if (!mounted || _isCancelled) return;

        // Actualizar con la posición más precisa
        setState(() {
          userLocation =
              LatLng(currentPosition.latitude, currentPosition.longitude);
        });
        
        print('✅ Ubicación precisa obtenida: ${currentPosition.latitude}, ${currentPosition.longitude}');
        
        // Actualizar ciudad, hospitales y urgent cares con la ubicación precisa
        if (mounted && !_isCancelled) {
          await getCityName(currentPosition.latitude, currentPosition.longitude);
          await buscarHospitalesCercanos();
          await buscarUrgentCaresCercanos();
        }
      } catch (e) {
        print('⚠️ Error obteniendo ubicación precisa: $e');
        print('📍 Usando ubicación aproximada existente');
        // No hacer nada - usar la ubicación aproximada que ya tenemos
      }

      // Si el mapa ya está inicializado, moverlo a la nueva posición
      if (_isMapReady) {
        try {
          _mapController.move(userLocation!, _mapController.camera.zoom);
        } catch (e) {
          print('Error al mover el mapa: $e');
        }
      }
    } catch (e) {
      print('Error al obtener la ubicación: $e');

      // Verificar si el widget todavía está montado antes de actualizar el estado
      if (!mounted || _isCancelled) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener la ubicación: $e')));
    }
  }

  Future<void> getCityName(double lat, double lon) async {
    try {
      // Verificar si el widget todavía está montado
      if (!mounted || _isCancelled) return;

      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon';
      final response =
          await http.get(Uri.parse(url), headers: {'User-Agent': 'FlutterApp'});

      // Verificar nuevamente si el widget está montado después de la operación asíncrona
      if (!mounted || _isCancelled) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String city = data['address']['city'] ??
            data['address']['town'] ??
            data['address']['village'] ??
            data['address']['county'] ??
            'Ubicación actual';

        // Verificar si el widget todavía está montado antes de actualizar el estado
        if (mounted && !_isCancelled) {
          setState(() {
            cityName = city;
          });
        }
      }
    } catch (e) {
      print('Error al obtener el nombre de la ciudad: $e');
    }
  }

  Future<void> buscarHospitalesCercanos() async {
    if (userLocation == null || !mounted || _isCancelled) return;

    try {
      final lat = userLocation!.latitude;
      final lon = userLocation!.longitude;

      print('🏥 Buscando hospitales...');
      
      // Usar DIRECTAMENTE Overpass API (funciona sin API Key)
      await _buscarConOverpass(lat, lon);
      
      // Si Overpass no encuentra suficientes, usar Nominatim como refuerzo
      if (hospitales.length < 5 && mounted && !_isCancelled) {
        await _buscarHospitalesConNominatimBackup(lat, lon);
      }
      
      print('✅ ${hospitales.length} hospitales encontrados');
    } catch (e) {
      print('Error al buscar hospitales: $e');
      if (userLocation != null && mounted && !_isCancelled) {
        // Si hay algún error, usar datos simulados como último recurso
        await _buscarHospitalesConNominatim(
            userLocation!.latitude, userLocation!.longitude);
      }
    }
  }

  Future<void> buscarUrgentCaresCercanos() async {
    if (userLocation == null || !mounted || _isCancelled) return;

    try {
      final lat = userLocation!.latitude;
      final lon = userLocation!.longitude;

      print('🚑 Buscando centros médicos...');
      
      // Usar DIRECTAMENTE Overpass API (funciona sin API Key)
      await _buscarUrgentCaresConOverpass(lat, lon);
      
      // Si Overpass no encuentra suficientes, usar Nominatim como refuerzo
      if (urgentCares.length < 5 && mounted && !_isCancelled) {
        await _buscarUrgentCaresConNominatimBackup(lat, lon);
      }
      
      print('✅ ${urgentCares.length} centros médicos encontrados');
    } catch (e) {
      print('Error al buscar urgent cares: $e');
      if (userLocation != null && mounted && !_isCancelled) {
        // Si hay algún error, usar datos reales como último recurso
        await _buscarUrgentCaresConNominatim(
            userLocation!.latitude, userLocation!.longitude);
      }
    }
  }

  Future<void> _buscarUrgentCaresConOverpass(double lat, double lon) async {
    if (!mounted || _isCancelled) return;

    // Usar Overpass API para buscar urgent care centers
    final overpassUrl = 'https://overpass-api.de/api/interpreter';
    final query = '''
    [out:json];
    (
      node["amenity"="clinic"](around:6437,$lat,$lon);
      node["healthcare"="clinic"](around:6437,$lat,$lon);
      node["healthcare"="urgent_care"](around:6437,$lat,$lon);
      node["amenity"="doctors"](around:6437,$lat,$lon);
      node["healthcare"="doctor"](around:6437,$lat,$lon);
      way["amenity"="clinic"](around:6437,$lat,$lon);
      way["healthcare"="clinic"](around:6437,$lat,$lon);
      way["healthcare"="urgent_care"](around:6437,$lat,$lon);
      way["amenity"="doctors"](around:6437,$lat,$lon);
      relation["healthcare"="urgent_care"](around:6437,$lat,$lon);
      relation["amenity"="clinic"](around:6437,$lat,$lon);
    );
    out center body;
    '''; // Radio de 4 millas (6437m), buscando clínicas, urgent care y consultorios médicos

    final response = await http.post(Uri.parse(overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=$query');

    if (!mounted || _isCancelled) return;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final elements = data['elements'] as List;

      if (mounted && !_isCancelled) {
        List<Map<String, dynamic>> urgentCaresTemp = [];

        for (var uc in elements) {
          // Extraer coordenadas según el tipo de elemento
          double? elemLat =
              uc['lat'] ?? (uc['center'] != null ? uc['center']['lat'] : null);
          double? elemLon =
              uc['lon'] ?? (uc['center'] != null ? uc['center']['lon'] : null);

          // Solo procesar si tenemos coordenadas válidas
          if (elemLat != null && elemLon != null) {
            // Calcular distancia desde el usuario
            double distancia = _calcularDistancia(lat, lon, elemLat, elemLon);

            // SOLO agregar si tiene información mínima válida
            String nombre = uc['tags'] != null ? (uc['tags']['name'] ?? '') : '';
            // Construir dirección COMPLETA con todos los detalles disponibles
            String direccion = '';
            if (uc['tags'] != null) {
              String housenumber = uc['tags']['addr:housenumber'] ?? '';
              String street = uc['tags']['addr:street'] ?? '';
              String unit = uc['tags']['addr:unit'] ?? uc['tags']['addr:flats'] ?? uc['tags']['addr:suite'] ?? '';
              String city = uc['tags']['addr:city'] ?? '';
              String state = uc['tags']['addr:state'] ?? '';
              String postcode = uc['tags']['addr:postcode'] ?? '';
              
              // Construir dirección paso a paso: Número + Calle + Unidad
              if (housenumber.isNotEmpty && street.isNotEmpty) {
                direccion = '$housenumber $street';
                if (unit.isNotEmpty) {
                  direccion += ' #$unit'; // Agregar unidad/suite
                }
              } else if (street.isNotEmpty) {
                direccion = street;
              }
              
              // Agregar ciudad
              if (city.isNotEmpty) {
                direccion = direccion.isEmpty ? city : '$direccion, $city';
              }
              
              // Agregar estado
              if (state.isNotEmpty) {
                direccion = direccion.isEmpty ? state : '$direccion, $state';
              }
              
              // Agregar código postal
              if (postcode.isNotEmpty) {
                direccion = direccion.isEmpty ? postcode : '$direccion $postcode';
              }
            }
            
            // Filtrar lugares sin información útil
            if (nombre.isNotEmpty && !nombre.toLowerCase().contains('sin nombre') &&
                direccion.isNotEmpty && !direccion.toLowerCase().contains('no disponible')) {
              
              urgentCaresTemp.add({
                'lat': elemLat,
                'lon': elemLon,
                'name': nombre,
                'phone': uc['tags'] != null ? uc['tags']['phone'] : null, // Solo teléfono real o null
                'address': direccion,
                'emergency': 'Centro médico verificado',
                'id': uc['id'].toString(),
                'distancia': distancia,
                'rating': null, // Sin rating disponible
                'user_ratings_total': null, // Sin reseñas disponibles
                'business_status': 'OPERATIONAL',
              });
            }
          }
        }

        // Ordenar por distancia y limitar a 10 resultados
        urgentCaresTemp.sort((a, b) =>
            (a['distancia'] as double).compareTo(b['distancia'] as double));
        if (urgentCaresTemp.length > 10) {
          urgentCaresTemp = urgentCaresTemp.sublist(0, 10);
        }

        // Simplificado - solo ordenar por distancia

        setState(() {
          urgentCares = urgentCaresTemp;
          // Simplificado - solo una lista ordenada por distancia
        });
        
        // Logs reducidos
      }
    }
  }

  // Buscar urgent care reales usando Google Places API como fallback
  Future<void> _buscarUrgentCaresConNominatim(double lat, double lon) async {
    if (!mounted || _isCancelled) return;

    try {
      // Usar Google Places API para buscar clínicas y urgent care reales
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      
      // Buscar SOLO urgent care y clínicas
      final types = [
        'urgent_care',
        'clinic',
        'walk_in_clinic'
      ];
      List<Map<String, dynamic>> urgentCaresTemp = [];

      for (String type in types) {
        // Buscar urgent care centers en radio de 4 millas
        final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lon&radius=6437&type=$type&key=$apiKey'; // 4 millas = 6437 metros
        
        final response = await http.get(Uri.parse(url));

        if (!mounted || _isCancelled) return;

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final results = data['results'] as List;
          print('🔍 URGENT CARE - Tipo: $type - Encontrados: ${results.length} lugares');

          for (var place in results) {
            if (place['geometry'] != null && place['geometry']['location'] != null) {
              double elemLat = place['geometry']['location']['lat'].toDouble();
              double elemLon = place['geometry']['location']['lng'].toDouble();
              double distancia = _calcularDistancia(lat, lon, elemLat, elemLon);

              // Validar que tenga información mínima requerida
              String nombre = place['name']?.toString() ?? '';
              String direccion = place['vicinity']?.toString() ?? 
                               place['formatted_address']?.toString() ?? '';
              
              // Filtros más estrictos para datos de calidad
              bool tieneNombreValido = nombre.isNotEmpty && 
                                     !nombre.toLowerCase().contains('sin nombre') &&
                                     !nombre.toLowerCase().contains('unnamed');
              bool tieneDireccionValida = direccion.isNotEmpty && 
                                        !direccion.toLowerCase().contains('no disponible') &&
                                        !direccion.toLowerCase().contains('unavailable');
              
              // Filtros más permisivos para encontrar más lugares (4 millas)
              if ((tieneNombreValido || nombre.length > 3) && distancia <= 4.0) {
                String id = place['place_id'].toString();
                bool yaExiste = urgentCaresTemp.any((uc) => uc['id'] == id);
                
                if (!yaExiste) {
                  Map<String, dynamic> urgentCare = {
                    'lat': elemLat,
                    'lon': elemLon,
                    'name': nombre,
                    'phone': await _obtenerTelefonoReal(place['place_id']?.toString() ?? '') ?? place['formatted_phone_number']?.toString() ?? place['international_phone_number']?.toString() ?? 'Ver en Google Maps',
                    'address': direccion,
                    'emergency': 'Centro médico certificado',
                    'id': id,
                    'distancia': distancia,
                    'rating': place['rating']?.toString() ?? 'Sin calificación',
                    'user_ratings_total': place['user_ratings_total']?.toString() ?? '0',
                    'business_status': place['business_status']?.toString() ?? 'OPERATIONAL',
                  };
                  
                  // Solo agregar si está operativo
                  if (urgentCare['business_status'] == 'OPERATIONAL') {
                    // Solo obtener detalles si falta información crítica
                    if (urgentCare['phone'] == 'Ver en Google Maps' || 
                        urgentCare['address'].length < 20 ||
                        urgentCare['rating'] == 'Sin calificación') {
                      Map<String, dynamic> urgentCareCompleto = await _obtenerDetallesCompletos(urgentCare);
                      urgentCaresTemp.add(urgentCareCompleto);
                    } else {
                      urgentCaresTemp.add(urgentCare);
                    }
                  }
                }
              }
            }
          }
        }

        // Pequeña pausa entre consultas
        await Future.delayed(Duration(milliseconds: 300));
      }

      // Ordenar por distancia y limitar a 10
      urgentCaresTemp.sort((a, b) =>
          (a['distancia'] as double).compareTo(b['distancia'] as double));
      if (urgentCaresTemp.length > 10) {
        urgentCaresTemp = urgentCaresTemp.sublist(0, 10);
      }

      if (mounted && !_isCancelled && urgentCaresTemp.isNotEmpty) {
        setState(() {
          urgentCares = urgentCaresTemp;
        });
        // Logs reducidos
        return;
      }

      // Si Google Places no funciona, intentar con Nominatim
      await _buscarUrgentCaresConNominatimBackup(lat, lon);
    } catch (e) {
      print('Error al buscar urgent cares con Google Places: $e');
      await _buscarUrgentCaresConNominatimBackup(lat, lon);
    }
  }

  Future<void> _buscarUrgentCaresConNominatimBackup(double lat, double lon) async {
    if (!mounted || _isCancelled) return;

    try {
      final queries = ['urgent care', 'clinic', 'medical center'];
      List<Map<String, dynamic>> urgentCaresTemp = [];

      for (String query in queries) {
        final url = 'https://nominatim.openstreetmap.org/search?format=json&q=$query&limit=10&bounded=1&viewbox=${lon-0.1},${lat+0.1},${lon+0.1},${lat-0.1}';
        
        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'MedicalApp/1.0'},
        );

        if (!mounted || _isCancelled) return;

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as List;

          for (var item in data) {
            if (item['lat'] != null && item['lon'] != null) {
              double elemLat = double.parse(item['lat']);
              double elemLon = double.parse(item['lon']);
              double distancia = _calcularDistancia(lat, lon, elemLat, elemLon);

              if (distancia <= 4.0) {
                String id = item['place_id'].toString();
                bool yaExiste = urgentCaresTemp.any((uc) => uc['id'] == id);
                
                if (!yaExiste) {
                  urgentCaresTemp.add({
                    'lat': elemLat,
                    'lon': elemLon,
                    'name': item['display_name']?.split(',')[0] ?? 'Centro Médico',
                    'phone': await _obtenerTelefonoReal(id) ?? 'Contactar directamente',
                    'address': item['display_name'] ?? 'Dirección verificada',
                    'emergency': 'Centro médico verificado',
                    'id': id,
                    'distancia': distancia,
                  });
                }
              }
            }
          }
        }

        await Future.delayed(Duration(milliseconds: 200));
      }

      urgentCaresTemp.sort((a, b) =>
          (a['distancia'] as double).compareTo(b['distancia'] as double));
      if (urgentCaresTemp.length > 10) {
        urgentCaresTemp = urgentCaresTemp.sublist(0, 10);
      }

      if (mounted && !_isCancelled) {
        setState(() {
          urgentCares = urgentCaresTemp;
        });
        // Logs reducidos
      }
    } catch (e) {
      print('Error al buscar urgent cares con Nominatim: $e');
    }
  }

  // Método para obtener teléfono real usando Google Places Details API
  Future<String?> _obtenerTelefonoReal(String placeId) async {
    if (placeId.isEmpty) return null;
    
    try {
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      if (apiKey.isEmpty) return null;
      
      final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=formatted_phone_number,international_phone_number&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];
        
        if (result != null) {
          // Priorizar número formateado, luego internacional
          String? phone = result['formatted_phone_number']?.toString() ?? 
                         result['international_phone_number']?.toString();
          
          if (phone != null && phone.isNotEmpty) {
            return phone;
          }
        }
      }
      
      return null;
      
    } catch (e) {
      return null;
    }
  }

  // Métodos duplicados eliminados

  Future<void> _buscarConOverpass(double lat, double lon) async {
    if (!mounted || _isCancelled) return;

    // Usar Overpass API con una consulta más específica
    final overpassUrl = 'https://overpass-api.de/api/interpreter';
    final query = '''
    [out:json];
    (
      node["amenity"="hospital"](around:6437,$lat,$lon);
      node["healthcare"="hospital"](around:6437,$lat,$lon);
      node["amenity"="clinic"]["emergency"="yes"](around:6437,$lat,$lon);
      node["healthcare"="clinic"](around:6437,$lat,$lon);
      way["amenity"="hospital"](around:6437,$lat,$lon);
      way["healthcare"="hospital"](around:6437,$lat,$lon);
      way["amenity"="clinic"](around:6437,$lat,$lon);
      way["healthcare"="clinic"](around:6437,$lat,$lon);
      relation["amenity"="hospital"](around:6437,$lat,$lon);
      relation["healthcare"="hospital"](around:6437,$lat,$lon);
    );
    out center body;
    '''; // Radio de 4 millas (6437m), incluyendo hospitales y clínicas

    final response = await http.post(Uri.parse(overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=$query');

    if (!mounted || _isCancelled) return;

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final elements = data['elements'] as List;

      if (mounted && !_isCancelled) {
        List<Map<String, dynamic>> hospitalesTemp = [];

        for (var h in elements) {
          // Extraer coordenadas según el tipo de elemento
          double? elemLat =
              h['lat'] ?? (h['center'] != null ? h['center']['lat'] : null);
          double? elemLon =
              h['lon'] ?? (h['center'] != null ? h['center']['lon'] : null);

          // Solo procesar si tenemos coordenadas válidas
          if (elemLat != null && elemLon != null) {
            // Calcular distancia desde el usuario
            double distancia = _calcularDistancia(lat, lon, elemLat, elemLon);

            // SOLO agregar si tiene información mínima válida
            String nombre = h['tags'] != null ? (h['tags']['name'] ?? '') : '';
            // Construir dirección COMPLETA con todos los detalles disponibles
            String direccion = '';
            if (h['tags'] != null) {
              String housenumber = h['tags']['addr:housenumber'] ?? '';
              String street = h['tags']['addr:street'] ?? '';
              String unit = h['tags']['addr:unit'] ?? h['tags']['addr:flats'] ?? h['tags']['addr:suite'] ?? '';
              String city = h['tags']['addr:city'] ?? '';
              String state = h['tags']['addr:state'] ?? '';
              String postcode = h['tags']['addr:postcode'] ?? '';
              
              // Construir dirección paso a paso: Número + Calle + Unidad
              if (housenumber.isNotEmpty && street.isNotEmpty) {
                direccion = '$housenumber $street';
                if (unit.isNotEmpty) {
                  direccion += ' #$unit'; // Agregar unidad/suite
                }
              } else if (street.isNotEmpty) {
                direccion = street;
              }
              
              // Agregar ciudad
              if (city.isNotEmpty) {
                direccion = direccion.isEmpty ? city : '$direccion, $city';
              }
              
              // Agregar estado
              if (state.isNotEmpty) {
                direccion = direccion.isEmpty ? state : '$direccion, $state';
              }
              
              // Agregar código postal
              if (postcode.isNotEmpty) {
                direccion = direccion.isEmpty ? postcode : '$direccion $postcode';
              }
            }
            
            // Filtrar lugares sin información útil
            if (nombre.isNotEmpty && !nombre.toLowerCase().contains('sin nombre') &&
                direccion.isNotEmpty && !direccion.toLowerCase().contains('no disponible')) {
              
              hospitalesTemp.add({
                'lat': elemLat,
                'lon': elemLon,
                'name': nombre,
                'phone': h['tags'] != null ? h['tags']['phone'] : null, // Solo teléfono real o null
                'address': direccion,
                'emergency': h['tags'] != null && h['tags']['emergency'] == 'yes'
                    ? 'Hospital - Emergencias 24h'
                    : 'Hospital verificado',
                'id': h['id'].toString(),
                'distancia': distancia,
                'rating': null, // Sin rating disponible
                'user_ratings_total': null, // Sin reseñas disponibles
                'business_status': 'OPERATIONAL',
              });
            }
          }
        }

        // Ordenar por distancia y limitar a 10 resultados
        hospitalesTemp.sort((a, b) =>
            (a['distancia'] as double).compareTo(b['distancia'] as double));
        if (hospitalesTemp.length > 10) {
          hospitalesTemp = hospitalesTemp.sublist(0, 10);
        }

        // Simplificado - solo ordenar por distancia

        setState(() {
          hospitales = hospitalesTemp;
          // Simplificado - solo una lista ordenada por distancia
        });
        
        // Logs reducidos
      }
    }
  }

  // Función para calcular la distancia entre dos puntos en millas (fórmula de Haversine)
  double _calcularDistancia(
      double lat1, double lon1, double lat2, double lon2) {
    const double radioTierra = 3959; // Radio de la Tierra en millas
    double dLat = _toRadianes(lat2 - lat1);
    double dLon = _toRadianes(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadianes(lat1)) *
            cos(_toRadianes(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radioTierra * c; // Distancia en millas
  }

  double _toRadianes(double grados) {
    return grados * (pi / 180);
  }

  // Obtener detalles completos de un lugar usando Google Places Details API
  Future<Map<String, dynamic>> _obtenerDetallesCompletos(Map<String, dynamic> lugar) async {
    try {
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      final placeId = lugar['id'];
      
      // Usar Google Places Details API para obtener información completa
      final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,formatted_address,formatted_phone_number,international_phone_number,website,rating,user_ratings_total,opening_hours,business_status,types&key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];
        
        if (result != null) {
          // Combinar información original con detalles completos
          Map<String, dynamic> lugarCompleto = Map.from(lugar);
          
          // Actualizar con información más completa
          lugarCompleto['name'] = result['name'] ?? lugar['name'];
          lugarCompleto['address'] = result['formatted_address'] ?? lugar['address'];
          lugarCompleto['phone'] = result['formatted_phone_number'] ?? 
                                  result['international_phone_number'] ?? 
                                  lugar['phone'];
          lugarCompleto['website'] = result['website'] ?? 'No disponible';
          lugarCompleto['rating'] = result['rating']?.toString() ?? lugar['rating'];
          lugarCompleto['user_ratings_total'] = result['user_ratings_total']?.toString() ?? lugar['user_ratings_total'];
          lugarCompleto['business_status'] = result['business_status'] ?? lugar['business_status'];
          
          // Información de horarios
          if (result['opening_hours'] != null && result['opening_hours']['weekday_text'] != null) {
            List<String> horarios = List<String>.from(result['opening_hours']['weekday_text']);
            lugarCompleto['horarios'] = horarios.join('\n');
          } else {
            lugarCompleto['horarios'] = 'Horarios no disponibles';
          }
          
          // Información adicional basada en tipos
          List<String> tipos = List<String>.from(result['types'] ?? []);
          if (tipos.contains('hospital')) {
            lugarCompleto['emergency'] = 'Hospital - Emergencias 24h';
          } else if (tipos.contains('doctor') || tipos.contains('health')) {
            lugarCompleto['emergency'] = 'Centro médico - Consultas';
          } else {
            lugarCompleto['emergency'] = lugar['emergency'];
          }
          
          return lugarCompleto;
        }
      }
      
      return lugar; // Devolver información original si falla
      
    } catch (e) {
      return lugar; // Devolver información original si hay error
    }
  }

  // Buscar hospitales reales usando Google Places API como fallback
  Future<void> _buscarHospitalesConNominatim(double lat, double lon) async {
    if (!mounted || _isCancelled) return;

    try {
      // Usar Google Places API Nearby Search para hospitales y centros médicos reales
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
      
      // Buscar SOLO hospitales generales
      final types = [
        'hospital'
      ];
      List<Map<String, dynamic>> hospitalesTemp = [];

      for (String type in types) {
        // Buscar hospitales generales en radio de 4 millas
        final url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lon&radius=6437&type=$type&key=$apiKey'; // 4 millas = 6437 metros
        
        final response = await http.get(Uri.parse(url));

        if (!mounted || _isCancelled) return;

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final results = data['results'] as List;
          print('🏥 HOSPITALES - Tipo: $type - Encontrados: ${results.length} hospitales');

          for (var place in results) {
          if (place['geometry'] != null && place['geometry']['location'] != null) {
            double elemLat = place['geometry']['location']['lat'].toDouble();
            double elemLon = place['geometry']['location']['lng'].toDouble();
            double distancia = _calcularDistancia(lat, lon, elemLat, elemLon);

            // Validar que tenga información mínima requerida
            String nombre = place['name']?.toString() ?? '';
            String direccion = place['vicinity']?.toString() ?? 
                             place['formatted_address']?.toString() ?? '';
            
            // Filtros más estrictos para datos de calidad
            bool tieneNombreValido = nombre.isNotEmpty && 
                                   !nombre.toLowerCase().contains('sin nombre') &&
                                   !nombre.toLowerCase().contains('unnamed');
            bool tieneDireccionValida = direccion.isNotEmpty && 
                                      !direccion.toLowerCase().contains('no disponible') &&
                                      !direccion.toLowerCase().contains('unavailable');
            
            // Filtros más permisivos para encontrar más hospitales (4 millas máximo)
            if ((tieneNombreValido || nombre.length > 3) && distancia <= 4.0) {
              Map<String, dynamic> hospital = {
                'lat': elemLat,
                'lon': elemLon,
                'name': nombre,
                'phone': await _obtenerTelefonoReal(place['place_id']?.toString() ?? '') ?? place['formatted_phone_number']?.toString() ?? place['international_phone_number']?.toString() ?? 'Ver en Google Maps',
                'address': direccion,
                'emergency': place['types'].contains('hospital') ? 'Hospital certificado' : 'Centro médico',
                'id': place['place_id'].toString(),
                'distancia': distancia,
                'rating': place['rating']?.toString() ?? 'Sin calificación',
                'user_ratings_total': place['user_ratings_total']?.toString() ?? '0',
                'business_status': place['business_status']?.toString() ?? 'OPERATIONAL',
              };
              
              // Solo agregar si está operativo
              if (hospital['business_status'] == 'OPERATIONAL') {
                // Solo obtener detalles si falta información crítica
                if (hospital['phone'] == 'Ver en Google Maps' || 
                    hospital['address'].length < 20 ||
                    hospital['rating'] == 'Sin calificación') {
                  Map<String, dynamic> hospitalCompleto = await _obtenerDetallesCompletos(hospital);
                  hospitalesTemp.add(hospitalCompleto);
                } else {
                  hospitalesTemp.add(hospital);
                }
              }
            }
          }
        }
        } // Cierre del if (response.statusCode == 200)
        
        // Pausa entre consultas para evitar rate limiting
        await Future.delayed(Duration(milliseconds: 200));
      }

      // Ordenar por distancia y limitar a 10
      hospitalesTemp.sort((a, b) =>
          (a['distancia'] as double).compareTo(b['distancia'] as double));
      if (hospitalesTemp.length > 10) {
        hospitalesTemp = hospitalesTemp.sublist(0, 10);
      }

      if (mounted && !_isCancelled && hospitalesTemp.isNotEmpty) {
        setState(() {
          hospitales = hospitalesTemp;
        });
        print('✅ ${hospitalesTemp.length} hospitales encontrados con Google Places');
        return;
      }

      // Si Google Places no funciona, intentar con Nominatim
      await _buscarHospitalesConNominatimBackup(lat, lon);
    } catch (e) {
      print('Error al buscar hospitales con Google Places: $e');
      await _buscarHospitalesConNominatimBackup(lat, lon);
    }
  }

  Future<void> _buscarHospitalesConNominatimBackup(double lat, double lon) async {
    if (!mounted || _isCancelled) return;

    try {
      final url = 'https://nominatim.openstreetmap.org/search?format=json&q=hospital&limit=20&bounded=1&viewbox=${lon-0.1},${lat+0.1},${lon+0.1},${lat-0.1}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'MedicalApp/1.0'},
      );

      if (!mounted || _isCancelled) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        List<Map<String, dynamic>> hospitalesTemp = [];

        for (var item in data) {
          if (item['lat'] != null && item['lon'] != null) {
            double elemLat = double.parse(item['lat']);
            double elemLon = double.parse(item['lon']);
            double distancia = _calcularDistancia(lat, lon, elemLat, elemLon);

            if (distancia <= 4.0) {
              hospitalesTemp.add({
                'lat': elemLat,
                'lon': elemLon,
                'name': item['display_name']?.split(',')[0] ?? 'Hospital',
                'phone': await _obtenerTelefonoReal(item['place_id']?.toString() ?? '') ?? 'Contactar directamente',
                'address': item['display_name'] ?? 'Dirección verificada',
                'emergency': 'Hospital verificado',
                'id': item['place_id'].toString(),
                'distancia': distancia,
              });
            }
          }
        }

        hospitalesTemp.sort((a, b) =>
            (a['distancia'] as double).compareTo(b['distancia'] as double));
        if (hospitalesTemp.length > 10) {
          hospitalesTemp = hospitalesTemp.sublist(0, 10);
        }

        if (mounted && !_isCancelled) {
          setState(() {
            hospitales = hospitalesTemp;
          });
          print('✅ ${hospitalesTemp.length} hospitales encontrados con Nominatim');
        }
      }
    } catch (e) {
      print('Error al buscar hospitales con Nominatim: $e');
    }
  }

  // Métodos de datos simulados eliminados

  // Todo el código roto eliminado

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          cityName != null ? 'Hospitales en $cityName' : 'Hospitales cercanos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Al presionar atrás, navegar a la página de inicio
            // y actualizar el estado del navbar para resaltar Home
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userLocation == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No se pudo obtener tu ubicación'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _getUserLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4485FD),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: userLocation!,
                        initialZoom: 14.5,
                        minZoom: 4,
                        maxZoom: 18,
                        keepAlive: true,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.all,
                          enableMultiFingerGestureRace: true,
                        ),
                        onMapReady: () {
                          // Marcar el mapa como listo y centrarlo
                          setState(() {
                            _isMapReady = true;
                          });
                          
                          // Asegurar que el mapa esté centrado correctamente al cargar
                          Future.delayed(Duration(milliseconds: 300), () {
                            if (mounted && !_isCancelled && _isMapReady) {
                              try {
                                _mapController.move(userLocation!, 14.5);
                                // Una vez que el mapa está listo, buscar hospitales y urgent cares si aún no se ha hecho
                                if (hospitales.isEmpty) {
                                  buscarHospitalesCercanos();
                                }
                                if (urgentCares.isEmpty) {
                                  buscarUrgentCaresCercanos();
                                }
                              } catch (e) {
                                print('Error al inicializar el mapa: $e');
                              }
                            }
                          });
                        },
                      ),
                      children: [
                        // Usar un mapa con estilo adaptado al modo oscuro
                        TileLayer(
                          urlTemplate: Theme.of(context).brightness == Brightness.dark
                              ? "https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png"
                              : "https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png",
                          subdomains: ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.ejemplo.tuapp',
                          // Optimizaciones para carga más rápida
                          tileProvider: NetworkTileProvider(),
                          maxNativeZoom: 18,
                          tileSize: 256,
                          keepBuffer: 5,
                        ),
                        MarkerLayer(
                          markers: [
                            // Marcador del usuario
                            Marker(
                              point: userLocation!,
                              width: 60,
                              height: 60,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 6,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Marcadores de hospitales
                            ...hospitales.map((hospital) => Marker(
                                  point:
                                      LatLng(hospital['lat'], hospital['lon']),
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  rotate: false,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _mostrarDetallesHospital(hospital),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.local_hospital,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                            // Marcadores de urgent care
                            ...urgentCares.map((urgentCare) => Marker(
                                  point:
                                      LatLng(urgentCare['lat'], urgentCare['lon']),
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  rotate: false,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _mostrarDetallesUrgentCare(urgentCare),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.medical_services,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ],
                    ),
                    // Indicador de hospitales encontrados
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: SafeArea(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Color(0xFF2A2A2A) // Color oscuro para modo oscuro
                                : Colors.white,    // Color blanco para modo claro
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(Icons.local_hospital,
                                          color: Colors.white, size: 16),
                                    ),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Cercanos: ${hospitales.length} hospitales, ${urgentCares.length} urgent care',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Ordenados por cercanía',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: 11,
                                                color: Theme.of(context).brightness == Brightness.dark
                                                    ? Colors.white70
                                                    : Colors.black54),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _mostrarListaHospitales,
                                style: TextButton.styleFrom(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 8)),
                                child: Text('Ver lista',
                                    style: TextStyle(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.lightBlue[300]
                                          : Colors.blue
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      // Usar el mismo navbar que existe en HomePage
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Color(0xFF1E1E1E) // Color oscuro para modo oscuro
              : Colors.white,     // Color claro para modo claro
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                child: _buildNavItem(Icons.home_outlined, false),
              ),
              GestureDetector(
                onTap: () {
                  // Ya estamos en el mapa
                },
                child: _buildNavItem(Icons.location_on_outlined, true),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ChatScreen()),
                  );
                },
                child: _buildNavItem(Icons.calendar_today_outlined, false),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
                child: _buildNavItem(Icons.person_outline, false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Implementación del mismo método que existe en HomePage
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

    // Colores adaptados al modo oscuro
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Color de fondo para el ítem seleccionado
    final Color selectedBgColor = isDarkMode
        ? Color(0xFF3A3A3A) // Gris oscuro para modo oscuro
        : Color.fromARGB(255, 199, 200, 201); // Gris claro para modo claro
    
    // Color del ícono seleccionado
    final Color selectedIconColor = isDarkMode
        ? Colors.white // Blanco para modo oscuro
        : Color.fromARGB(255, 49, 47, 47); // Gris oscuro para modo claro
    
    // Color del ícono no seleccionado
    final Color unselectedIconColor = isDarkMode
        ? Color(0xFF9E9E9E) // Gris claro para modo oscuro
        : Color.fromARGB(255, 136, 140, 147); // Gris medio para modo claro

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isSelected ? selectedBgColor : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Image.asset(
          iconAsset,
          color: isSelected ? selectedIconColor : unselectedIconColor,
          width: 16,
          height: 16,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  void _mostrarDetallesHospital(Map<String, dynamic> hospital) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.local_hospital, color: Colors.red.shade700),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hospital['name'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(height: 24),
            if (hospital['address'] != null)
              _infoRow(Icons.location_on, TextDecoder.decode(hospital['address'])),
            if (hospital['phone'] != null && hospital['phone'] != 'Ver en Google Maps' && hospital['phone'].toString().isNotEmpty)
              GestureDetector(
                onTap: () => _launchPhoneCall(hospital['phone']),
                child: _infoRowWithLink(Icons.phone, hospital['phone']),
              ),
            if (hospital['rating'] != null && hospital['rating'] != 'Sin calificación' && hospital['user_ratings_total'] != null)
              _infoRow(Icons.star, '${hospital['rating']} ⭐ (${hospital['user_ratings_total']} reseñas)'),
            if (hospital['website'] != null && hospital['website'] != 'No disponible')
              GestureDetector(
                onTap: () => _launchWebsite(hospital['website']),
                child: _infoRowWithLink(Icons.language, hospital['website']),
              ),
            if (hospital['horarios'] != null)
              _infoRow(Icons.access_time, hospital['horarios']),
            if (hospital['emergency'] != null)
              _infoRow(Icons.emergency, hospital['emergency']),
            _infoRow(Icons.navigation, '${(hospital['distancia'] as double).toStringAsFixed(1)} millas de distancia'),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentPsychologyScreen(
                        id: 1,
                        nombre: 'General',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4485FD),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Agendar cita'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetallesUrgentCare(Map<String, dynamic> urgentCare) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.medical_services, color: Colors.orange.shade700),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    urgentCare['name'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(height: 24),
            if (urgentCare['address'] != null)
              _infoRow(Icons.location_on, TextDecoder.decode(urgentCare['address'])),
            if (urgentCare['phone'] != null && urgentCare['phone'] != 'Ver en Google Maps' && urgentCare['phone'].toString().isNotEmpty)
              GestureDetector(
                onTap: () => _launchPhoneCall(urgentCare['phone']),
                child: _infoRowWithLink(Icons.phone, urgentCare['phone']),
              ),
            if (urgentCare['rating'] != null && urgentCare['rating'] != 'Sin calificación' && urgentCare['user_ratings_total'] != null)
              _infoRow(Icons.star, '${urgentCare['rating']} ⭐ (${urgentCare['user_ratings_total']} reseñas)'),
            if (urgentCare['website'] != null && urgentCare['website'] != 'No disponible')
              GestureDetector(
                onTap: () => _launchWebsite(urgentCare['website']),
                child: _infoRowWithLink(Icons.language, urgentCare['website']),
              ),
            if (urgentCare['horarios'] != null)
              _infoRow(Icons.access_time, urgentCare['horarios']),
            if (urgentCare['emergency'] != null)
              _infoRow(Icons.medical_services, urgentCare['emergency']),
            _infoRow(Icons.navigation, '${(urgentCare['distancia'] as double).toStringAsFixed(1)} millas de distancia'),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentPsychologyScreen(
                        id: 1,
                        nombre: 'Urgent Care',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Agendar cita urgente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRowWithLink(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarListaHospitales() {
    // Combinar hospitales y urgent cares en una sola lista
    List<Map<String, dynamic>> todosLugares = [];
    
    // Agregar hospitales con tipo
    for (var hospital in hospitales) {
      todosLugares.add({
        ...hospital,
        'tipo': 'hospital',
      });
    }
    
    // Agregar urgent cares con tipo
    for (var urgentCare in urgentCares) {
      todosLugares.add({
        ...urgentCare,
        'tipo': 'urgent_care',
      });
    }
    
    // Ordenar por distancia
    todosLugares.sort((a, b) =>
        (a['distancia'] as double).compareTo(b['distancia'] as double));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Centros médicos cercanos',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: todosLugares.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final lugar = todosLugares[index];
                    final esHospital = lugar['tipo'] == 'hospital';
                    
                    return ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: esHospital ? Colors.red.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          esHospital ? Icons.local_hospital : Icons.medical_services,
                          color: esHospital ? Colors.red.shade700 : Colors.orange.shade700,
                          size: 20,
                        ),
                      ),
                      title: Text(TextDecoder.decode(lugar['name']),
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TextDecoder.decode(
                                lugar['address'] ?? 'Sin dirección disponible'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                esHospital ? 'Hospital' : 'Centro Médico',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: esHospital ? Colors.red : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (lugar['distancia'] as double) <= 2.0 ? Colors.red : Colors.blue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  (lugar['distancia'] as double) <= 2.0 ? 'MUY CERCA' : 'CERCANO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                '${(lugar['distancia'] as double).toStringAsFixed(1)}mi',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        if (esHospital) {
                          _mostrarDetallesHospital(lugar);
                        } else {
                          _mostrarDetallesUrgentCare(lugar);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
