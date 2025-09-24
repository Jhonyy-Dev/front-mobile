import 'package:flutter/material.dart';
import 'package:mi_app_flutter/servicios/citas_servicio.dart';
import 'package:mi_app_flutter/login_medical/screens_medical/home.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AppointmentPsychologyScreen extends StatefulWidget {
  final int id;
  final String nombre;

  const AppointmentPsychologyScreen({
    super.key,
    required this.id,
    required this.nombre,
  });

  @override
  State<AppointmentPsychologyScreen> createState() => _AppointmentPsychologyScreenState();
}

class _AppointmentPsychologyScreenState extends State<AppointmentPsychologyScreen> {
  // Método para obtener el nombre del mes
  String _getMonthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }
  DateTime selectedDate = DateTime.now();
  String selectedTime = '10:00 AM';
  final List<String> timeSlots = [
    '9:00 AM', '9:30 AM', '10:00 AM',
    '10:30 AM', '11:00 AM', '11:30 AM',
    '3:00 PM', '3:30 PM', '4:00 PM',
    '4:30 PM', '5:00 PM', '5:30 PM',
  ];
  
  // Lista para almacenar las citas existentes
  List<Map<String, dynamic>> citasExistentes = [];
  bool isLoading = true;
  
  // Timer para actualizar el estado periódicamente
  Timer? _actualizacionTimer;

  @override
  void initState() {
    super.initState();
    // Cargar las citas existentes al iniciar la pantalla
    _cargarCitasExistentes();
    // Seleccionar la primera hora disponible al iniciar
    _actualizarHoraSeleccionada();
    
    // Configurar un timer para verificar la hora actual cada 10 segundos
    _actualizacionTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      setState(() {
        // Esto forzará a que se vuelva a evaluar _horaOcupada para cada hora
        _actualizarHoraSeleccionada();
      });
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actualizarHoraSeleccionada();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Actualizar la hora seleccionada cuando cambia la fecha
    _actualizarHoraSeleccionada();
  }
  
  @override
  void dispose() {
    // Cancelar el timer cuando se destruye el widget
    _actualizacionTimer?.cancel();
    super.dispose();
  }
  
  // Método para cargar las citas existentes
  Future<void> _cargarCitasExistentes() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      CitasServicio citasServicio = CitasServicio();
      final resultado = await citasServicio.obtenerCitas();
      
      if (resultado['exito'] == true && resultado['citas'] != null) {
        setState(() {
          citasExistentes = List<Map<String, dynamic>>.from(resultado['citas']);
          isLoading = false;
        });
        print("Citas existentes cargadas: ${citasExistentes.length}");
      } else {
        setState(() {
          citasExistentes = [];
          isLoading = false;
        });
        print("No se encontraron citas existentes");
      }
    } catch (e) {
      setState(() {
        citasExistentes = [];
        isLoading = false;
      });
      print("Error al cargar citas existentes: $e");
    }
  }
  
  // Método para verificar si una fecha ya tiene todas las horas ocupadas
  bool _fechaCompleta(DateTime fecha) {
    final String fechaStr = fecha.toLocal().toString().split(' ')[0];
    int citasEnFecha = 0;
    
    for (var cita in citasExistentes) {
      if (cita['fecha_cita'] == fechaStr) {
        citasEnFecha++;
      }
    }
    
    // Si hay tantas citas como slots de tiempo disponibles, la fecha está completa
    return citasEnFecha >= timeSlots.length;
  }
  
  // Método para verificar si una hora específica ya está ocupada en la fecha seleccionada
  // o si es anterior a la hora actual
  bool _horaOcupada(String hora) {
    // Obtener la fecha y hora actual
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fechaSeleccionada = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    
    // Si la fecha seleccionada es anterior a hoy (mes anterior o día anterior)
    if (fechaSeleccionada.year < today.year ||
        (fechaSeleccionada.year == today.year && fechaSeleccionada.month < today.month) ||
        (fechaSeleccionada.year == today.year && fechaSeleccionada.month == today.month && fechaSeleccionada.day < today.day)) {
      return true; // Bloquear TODAS las horas de fechas anteriores
    }
    
    // Si es hoy, verificar si la hora ya pasó comparando con la hora actual
    if (fechaSeleccionada.year == today.year && 
        fechaSeleccionada.month == today.month && 
        fechaSeleccionada.day == today.day) {
      // Convertir la hora de la cita a un objeto DateTime para comparar
      final partes = hora.split(':');
      int horaInt = int.parse(partes[0]);
      final minutosInt = int.parse(partes[1].split(' ')[0]);
      final esPM = hora.contains('PM');
      
      // Ajustar la hora al formato 24 horas
      if (esPM && horaInt < 12) {
        horaInt += 12;
      } else if (!esPM && horaInt == 12) {
        horaInt = 0;
      }
      
      // Crear un DateTime con la hora de la cita
      final horaCita = DateTime(
        today.year,
        today.month,
        today.day,
        horaInt,
        minutosInt,
      );
      
      // Si la hora de la cita es anterior o igual a la hora actual
      if (horaCita.isBefore(now) || horaCita.isAtSameMomentAs(now)) {
        return true; // La hora ya pasó o está en curso
      }
    }
    
    // Verificar si la hora ya está ocupada por una cita existente
    final fechaStr = selectedDate.toLocal().toString().split(' ')[0];
    for (var cita in citasExistentes) {
      if (cita['fecha_cita'] == fechaStr && cita['hora_cita'] == hora) {
        return true; // La hora ya está ocupada
      }
    }
    
    return false; // La hora está disponible
  }
  
  // Variable para rastrear si hay alguna hora disponible
  bool hayHorasDisponibles = false;

  // Método para actualizar la hora seleccionada a la primera disponible
  void _actualizarHoraSeleccionada() {
    // Verificar si hay alguna hora disponible
    bool algunaDisponible = false;
    for (String hora in timeSlots) {
      if (!_horaOcupada(hora)) {
        algunaDisponible = true;
        setState(() {
          selectedTime = hora;
          hayHorasDisponibles = true;
        });
        return;
      }
    }
    
    // Si todas están ocupadas, establecer hayHorasDisponibles a false
    if (!algunaDisponible) {
      setState(() {
        // Mantener selectedTime pero marcar que no hay horas disponibles
        hayHorasDisponibles = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.darkModeEnabled;

    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Color(0xFF2D3142);
    final accentColor = const Color(0xFF4485FD);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.nombre,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: accentColor,
            shadows: [
              Shadow(
                blurRadius: 4,
                color: const Color.fromARGB(35, 0, 0, 0).withOpacity(0.1),
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            // Calendario sin contenedor externo
            _buildCalendar(),
            const SizedBox(height: 24),
            Text(
              'Select Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: timeSlots.length,
              itemBuilder: (context, index) {
                final bool isSelected = timeSlots[index] == selectedTime;
                final bool isOcupado = _horaOcupada(timeSlots[index]);
                
                return GestureDetector(
                  onTap: isOcupado ? null : () {
                    setState(() {
                      selectedTime = timeSlots[index];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: (isSelected && !isOcupado && hayHorasDisponibles) 
                          ? accentColor 
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          timeSlots[index],
                          style: TextStyle(
                            color: (isSelected && !isOcupado && hayHorasDisponibles)
                                ? Colors.white 
                                : isOcupado
                                    ? Colors.grey
                                    : textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        // Solo mostrar el punto rojo si la hora está realmente bloqueada
                        if (isOcupado && !isSelected)
                          Positioned(
                            right: 5,
                            top: 5,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                // Deshabilitar el botón si no hay horas disponibles
                onPressed: hayHorasDisponibles ? () => confirmarCita(context) : null,
                style: ElevatedButton.styleFrom(
                  // Cambiar el color de fondo según si está habilitado o no
                  backgroundColor: hayHorasDisponibles ? accentColor : Colors.grey.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: hayHorasDisponibles ? 2 : 0,
                ),
                child: Text(
                  'Confirm Appointment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: hayHorasDisponibles ? Colors.white : Colors.grey,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    // Obtener el primer día del mes actual
    final DateTime firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    
    // Obtener el número de días en el mes actual
    final int daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    
    // Obtener el día de la semana del primer día (1 = lunes, 7 = domingo)
    
    // Obtener el tema actual
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.darkModeEnabled;
    final textColor = isDarkMode ? Colors.white : Color(0xFF2D3142);
    final accentColor = const Color(0xFF4485FD); // Color azul para mantener el esquema de la app
    final backgroundColor = isDarkMode ? Color(0xFF1E1E1E) : Colors.white;

    
    // Crear una lista de widgets para los días de la semana
    final weekdayLabels = [
      'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'
    ].map((day) => SizedBox(
      width: 32,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor.withOpacity(0.7),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    )).toList();
    
    // Crear widgets para cada día del mes
    List<Widget> dayWidgets = [];
    
    // Agregar espacios vacíos para los días anteriores al primer día del mes
    // Ajustar para que la semana comience en lunes (1)
    int firstDayOffset = firstDayOfMonth.weekday - 1;
    if (firstDayOffset < 0) firstDayOffset = 6; // Ajuste para domingo
    
    for (int i = 0; i < firstDayOffset; i++) {
      dayWidgets.add(Container());
    }
    
    // Obtener la fecha actual
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Agregar los días del mes
    for (int i = 1; i <= daysInMonth; i++) {
      final currentDate = DateTime(selectedDate.year, selectedDate.month, i);
      final isSelected = currentDate.day == selectedDate.day;
      final isToday = currentDate.year == now.year &&
          currentDate.month == now.month &&
          currentDate.day == now.day;
      final isPastDate = currentDate.isBefore(today);
      final isFull = _fechaCompleta(currentDate);
      
      dayWidgets.add(
        GestureDetector(
          onTap: (isPastDate || isFull) ? null : () {
            setState(() {
              selectedDate = currentDate;
              // Actualizar la hora seleccionada cuando cambia la fecha
              _actualizarHoraSeleccionada();
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? accentColor : 
                     isToday && !isSelected ? accentColor.withOpacity(0.1) : 
                     Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Center(
              child: Text(
                i.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : isPastDate || isFull
                          ? Colors.grey.withOpacity(0.5)
                          : isToday
                              ? accentColor
                              : textColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Encabezado del mes y botones de navegación
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.chevron_left, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          // Al retroceder al mes anterior
                          final now = DateTime.now();
                          final targetMonth = selectedDate.month - 1;
                          final targetYear = selectedDate.year;
                          
                          // Si estamos navegando al mes actual, seleccionar el día actual
                          if (targetMonth == now.month && targetYear == now.year) {
                            selectedDate = DateTime(now.year, now.month, now.day);
                          } else {
                            // De lo contrario, seleccionar el día 1 del mes
                            selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
                          }
                          
                          _actualizarHoraSeleccionada();
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.chevron_right, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          // Al avanzar al mes siguiente
                          final now = DateTime.now();
                          final targetMonth = selectedDate.month + 1;
                          final targetYear = selectedDate.year;
                          
                          // Si estamos navegando al mes actual, seleccionar el día actual
                          if (targetMonth == now.month && targetYear == now.year) {
                            selectedDate = DateTime(now.year, now.month, now.day);
                          } else {
                            // De lo contrario, seleccionar el día 1 del mes
                            selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
                          }
                          
                          _actualizarHoraSeleccionada();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          // Separador horizontal
          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          SizedBox(height: 16),
          // Días de la semana
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdayLabels,
          ),
          SizedBox(height: 8),
          // Grid de días
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: EdgeInsets.zero,
            children: dayWidgets,
          ),
        ],
      ),
    );
  }



  void confirmarCita(BuildContext context) async {
    CitasServicio citasServicio = CitasServicio();

    final resultado = await citasServicio.registrarCita(
      fechaCita: selectedDate.toLocal().toString().split(' ')[0],
      horaCita: selectedTime,
      categoriaId: widget.id,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado['mensaje']),
        backgroundColor: resultado['exito'] ? Colors.green : Colors.red,
      ),
    );

    if (resultado['exito']) {
      // Guardar un flag en SharedPreferences para indicar que se ha creado una nueva cita
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cita_creada', true);
      
      // Redirigir a la pantalla Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
      );
    }

    print('------------------');
    print('Le diste al botón Confirmar');
    print('Fecha seleccionada: ${selectedDate.toLocal().toString().split(' ')[0]}');
    print('Hora seleccionada: $selectedTime');
    print('Nombre: ${widget.nombre}');
    print('ID: ${widget.id}');
    print('------------------');
  }
}
