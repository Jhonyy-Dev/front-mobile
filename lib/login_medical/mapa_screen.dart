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
import 'dart:io';
import 'dart:core';
import 'package:mi_app_flutter/utils/text_decoder.dart';
import 'package:url_launcher/url_launcher.dart';

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

  LatLng? userLocation;
  List<Map<String, dynamic>> hospitales = [];
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

        // Iniciar la búsqueda de hospitales con esta ubicación inicial
        if (mounted && !_isCancelled) {
          await getCityName(lastPosition.latitude, lastPosition.longitude);
          await buscarHospitalesCercanos();
        }
      }

      // Si el widget ya no está montado, detener la ejecución
      if (!mounted || _isCancelled) return;

      // En paralelo, obtener la posición actual más precisa
      Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5) // Limitar el tiempo de espera
          );

      // Verificar nuevamente si el widget está montado
      if (!mounted || _isCancelled) return;

      // Actualizar con la posición más precisa
      setState(() {
        userLocation =
            LatLng(currentPosition.latitude, currentPosition.longitude);
      });

      // Si el mapa ya está inicializado, moverlo a la nueva posición
      if (_isMapReady) {
        try {
          _mapController.move(userLocation!, _mapController.camera.zoom);
        } catch (e) {
          print('Error al mover el mapa: $e');
        }
      }

      // Verificar nuevamente si el widget está montado
      if (!mounted || _isCancelled) return;

      // Actualizar ciudad y hospitales con la ubicación precisa
      await getCityName(currentPosition.latitude, currentPosition.longitude);
      await buscarHospitalesCercanos();
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

      // Intentar primero con la API de Overpass con un radio más pequeño y consulta mejorada
      await _buscarConOverpass(lat, lon);

      // Si no hay resultados, intentar con Google Places API simulada
      if (hospitales.isEmpty && mounted && !_isCancelled) {
        await _buscarHospitalesMockData(lat, lon);
      }
    } catch (e) {
      print('Error al buscar hospitales: $e');
      if (userLocation != null && mounted && !_isCancelled) {
        // Si hay algún error, usar datos simulados como último recurso
        await _buscarHospitalesMockData(
            userLocation!.latitude, userLocation!.longitude);
      }
    }
  }

  Future<void> _buscarConOverpass(double lat, double lon) async {
    if (!mounted || _isCancelled) return;

    // Usar Overpass API con una consulta más específica
    final overpassUrl = 'https://overpass-api.de/api/interpreter';
    final query = '''
    [out:json];
    (
      node["amenity"="hospital"](around:5000,$lat,$lon);
      node["healthcare"="hospital"](around:5000,$lat,$lon);
      way["amenity"="hospital"](around:5000,$lat,$lon);
      way["healthcare"="hospital"](around:5000,$lat,$lon);
      relation["amenity"="hospital"](around:5000,$lat,$lon);
      relation["healthcare"="hospital"](around:5000,$lat,$lon);
    );
    out center body;
    '''; // Radio de 5km, incluyendo diferentes tipos de objetos

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

            hospitalesTemp.add({
              'lat': elemLat,
              'lon': elemLon,
              'name': h['tags'] != null
                  ? (h['tags']['name'] ?? 'Hospital sin nombre')
                  : 'Hospital sin nombre',
              'phone': h['tags'] != null
                  ? (h['tags']['phone'] ?? 'No disponible')
                  : 'No disponible',
              'address': h['tags'] != null
                  ? (h['tags']['addr:street'] ?? 'Dirección no disponible')
                  : 'Dirección no disponible',
              'emergency': h['tags'] != null && h['tags']['emergency'] == 'yes'
                  ? 'Emergencias 24h'
                  : 'Emergencias no confirmadas',
              'id': h['id'].toString(),
              'distancia': distancia, // Guardar la distancia para ordenar
            });
          }
        }

        // Ordenar por distancia y limitar a 10 resultados
        hospitalesTemp.sort((a, b) =>
            (a['distancia'] as double).compareTo(b['distancia'] as double));
        if (hospitalesTemp.length > 10) {
          hospitalesTemp = hospitalesTemp.sublist(0, 10);
        }

        setState(() {
          hospitales = hospitalesTemp;
        });
      }
    }
  }

  // Función para calcular la distancia entre dos puntos en km (fórmula de Haversine)
  double _calcularDistancia(
      double lat1, double lon1, double lat2, double lon2) {
    const double radioTierra = 6371; // Radio de la Tierra en km
    double dLat = _toRadianes(lat2 - lat1);
    double dLon = _toRadianes(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadianes(lat1)) *
            cos(_toRadianes(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radioTierra * c; // Distancia en km
  }

  double _toRadianes(double grados) {
    return grados * (pi / 180);
  }

  // Datos simulados de hospitales cercanos cuando las APIs fallan
  Future<void> _buscarHospitalesMockData(double lat, double lon) async {
    if (!mounted || _isCancelled) return;

    // Generar 10 hospitales cercanos simulados en un radio de 2km
    List<Map<String, dynamic>> hospitalesCercanos = [];

    // Nombres realistas de hospitales
    List<String> nombresHospitales = [
      'Hospital General',
      'Hospital Universitario',
      'Centro Médico Regional',
      'Hospital San Juan',
      'Hospital Santa María',
      'Centro de Salud Familiar',
      'Hospital de Especialidades',
      'Clínica San José',
      'Hospital Infantil',
      'Centro Médico Nacional',
      'Hospital Metropolitano',
      'Hospital de Urgencias'
    ];

    // Generar ubicaciones aleatorias cercanas
    final random = Random();
    for (int i = 0; i < 10; i++) {
      // Generar offset aleatorio (máximo 2km en cualquier dirección)
      double latOffset =
          (random.nextDouble() * 0.018) * (random.nextBool() ? 1 : -1);
      double lonOffset =
          (random.nextDouble() * 0.018) * (random.nextBool() ? 1 : -1);

      double hospitalLat = lat + latOffset;
      double hospitalLon = lon + lonOffset;

      // Calcular distancia real
      double distancia = _calcularDistancia(lat, lon, hospitalLat, hospitalLon);

      // Solo incluir si está a menos de 2km
      if (distancia <= 2.0) {
        hospitalesCercanos.add({
          'lat': hospitalLat,
          'lon': hospitalLon,
          'name': nombresHospitales[random.nextInt(nombresHospitales.length)],
          'phone':
              '+1 ${random.nextInt(900) + 100}-${random.nextInt(900) + 100}-${random.nextInt(9000) + 1000}',
          'address': '${random.nextInt(1000) + 1} Calle Principal',
          'emergency': random.nextBool()
              ? 'Emergencias 24h'
              : 'Emergencias no confirmadas',
          'id': 'mock_${i + 1}',
          'distancia': distancia,
        });
      }
    }

    // Ordenar por distancia
    hospitalesCercanos.sort((a, b) =>
        (a['distancia'] as double).compareTo(b['distancia'] as double));

    // Asegurar que tengamos al menos 5 hospitales
    if (hospitalesCercanos.length < 5) {
      for (int i = hospitalesCercanos.length; i < 5; i++) {
        double latOffset =
            (random.nextDouble() * 0.009) * (random.nextBool() ? 1 : -1);
        double lonOffset =
            (random.nextDouble() * 0.009) * (random.nextBool() ? 1 : -1);

        double hospitalLat = lat + latOffset;
        double hospitalLon = lon + lonOffset;
        double distancia =
            _calcularDistancia(lat, lon, hospitalLat, hospitalLon);

        hospitalesCercanos.add({
          'lat': hospitalLat,
          'lon': hospitalLon,
          'name': nombresHospitales[random.nextInt(nombresHospitales.length)],
          'phone':
              '+1 ${random.nextInt(900) + 100}-${random.nextInt(900) + 100}-${random.nextInt(9000) + 1000}',
          'address': '${random.nextInt(1000) + 1} Calle Principal',
          'emergency': random.nextBool()
              ? 'Emergencias 24h'
              : 'Emergencias no confirmadas',
          'id': 'mock_${i + 1}',
          'distancia': distancia,
        });
      }

      // Ordenar nuevamente
      hospitalesCercanos.sort((a, b) =>
          (a['distancia'] as double).compareTo(b['distancia'] as double));
    }

    if (mounted && !_isCancelled) {
      setState(() {
        hospitales = hospitalesCercanos;
      });
    }
  }

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
                                // Una vez que el mapa está listo, buscar hospitales si aún no se ha hecho
                                if (hospitales.isEmpty) {
                                  buscarHospitalesCercanos();
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
                                      child: Text(
                                        '${hospitales.length} hospitales encontrados',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : Colors.black),
                                        overflow: TextOverflow.ellipsis,
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
            if (hospital['phone'] != null)
              GestureDetector(
                onTap: () => _launchPhoneCall(hospital['phone']),
                child: _infoRowWithLink(Icons.phone, hospital['phone']),
              ),
            if (hospital['emergency'] != null)
              _infoRow(Icons.emergency, hospital['emergency']),
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
                      'Hospitales cercanos',
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
                  itemCount: hospitales.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final hospital = hospitales[index];
                    return ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.local_hospital,
                            color: Colors.red.shade700, size: 20),
                      ),
                      title: Text(TextDecoder.decode(hospital['name']),
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        TextDecoder.decode(
                            hospital['address'] ?? 'Sin dirección disponible'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _mostrarDetallesHospital(hospital);
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
