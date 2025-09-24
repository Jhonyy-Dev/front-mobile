import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mi_app_flutter/login_migration/screens_migration/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late GenerativeModel _model;
  late ChatSession _chat;
  bool _isTyping = false;
  final String _botAvatarUrl = 'assets/abogado.webp';
  String _userAvatarUrl = 'assets/doctor.webp';

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _cargarImagenUsuario();
  }
  
  Future<void> _cargarImagenUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagenUrl = prefs.getString('imagen_url');
      final imagenLocalPath = prefs.getString('imagen_local_path');
      
      if (imagenUrl != null && imagenUrl.isNotEmpty) {
        setState(() {
          if (imagenUrl.startsWith('file://')) {
            // Es una imagen local
            _userAvatarUrl = imagenUrl;
          } else if (imagenUrl.startsWith('http')) {
            // Es una URL de red
            _userAvatarUrl = imagenUrl;
          } else {
            // Es una imagen del servidor
            _userAvatarUrl = "https://api-inmigracion.laimeweb.tech/storage/usuarios/$imagenUrl";
          }
        });
      } else if (imagenLocalPath != null && imagenLocalPath.isNotEmpty) {
        // Si no hay URL pero sí hay una ruta local guardada
        final file = File(imagenLocalPath);
        if (await file.exists()) {
          setState(() {
            _userAvatarUrl = 'file://$imagenLocalPath';
          });
        }
      }
    } catch (e) {
      print('Error al cargar imagen de usuario: $e');
    }
  }

  void _initializeChat() {
    const apiKey = 'AIzaSyBizcJ95cfJFN6n3VS8ktttE_KvF4zIqiQ';
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,  // Temperatura reducida para respuestas más consistentes
        topK: 64,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
    _chat = _model.startChat(
      history: [
        Content.text("Perfecto, soy Maval, un experto abogado de inmigración de los Estados Unidos. Proporciono <b>excelentes pautas y consejos</b> exclusivamente sobre temas de inmigración y legales. Uso emojis (1-2 por mensaje) para hacer las respuestas más atractivas. Mis respuestas son <b>concisas y prácticas</b>, e incluyo saltos de línea para una mejor legibilidad. Me limito estrictamente a temas de inmigración y legales. Cuando me preguntan '¿Quién eres?', respondo con 'Soy <b>Maval</b>, un experto abogado de inmigración, creado por expertos en tecnología, desarrolladores de software, profesionales web, mercadólogos y entusiastas legales. Puedes encontrar más información sobre mis creadores en <b>https://maval.tech/</b>.' Mis creadores son la empresa tecnológica <b>https://maval.tech/</b>, especializada en desarrollo web, software y marketing desde los Estados Unidos. Debo responder en el mismo idioma que el usuario, ya sea en español o en inglés. También puedo orientar a los usuarios en términos legales basándome en toda la información que busque de internet para brindar una mejor respuesta. Proporciono una respuesta clara al usuario sin salirme del tema y orientándolo a que hable más sobre el tema que desee comunicar.")
      ]
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final content = Content.text(userMessage);
      final response = await _chat.sendMessage(content);
      
      setState(() {
        _isTyping = false;
        if (response.text != null) {
          _messages.add(ChatMessage(
            text: response.text!,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        } else {
          // Si la respuesta es nula pero no hubo excepción
          _messages.add(ChatMessage(
            text: 'No se pudo obtener una respuesta. Por favor, intenta nuevamente.',
            isUser: false,
            timestamp: DateTime.now(),
          ));
          print('⚠️ Respuesta nula de la API de Gemini');
        }
      });
      _scrollToBottom();
    } catch (e) {
      print('❌ Error al procesar mensaje con Gemini: $e');
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: 'Lo siento, hubo un error al procesar tu mensaje. Por favor, intenta nuevamente.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtener los colores del tema actual
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final appBarColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final inputBackgroundColor = isDarkMode ? Colors.grey[800] : Colors.grey[100];
    
    return WillPopScope(
      onWillPop: () async {
        _navigateToHome();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: appBarColor,
          elevation: 0,
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(_botAvatarUrl),
                radius: 20,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Asistente Legal IA',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Disponible 24/7',
                        style: TextStyle(
                          color: const Color(0xFF4CAF50), // Color verde fijo para mejor visibilidad
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Círculo pulsante
                      _PulsingCircle(),
                    ],
                  ),
                ],
              ),
            ],
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: textColor),
            onPressed: _navigateToHome,
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                isDarkMode 
                  ? 'assets/fondo_chats/fondo_oscuro.webp' 
                  : 'assets/fondo_chats/fondo_claro.webp'
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return MessageBubble(
                      message: message,
                      userAvatarUrl: _userAvatarUrl,
                      botAvatarUrl: _botAvatarUrl,
                      isDarkMode: isDarkMode,
                    );
                  },
                ),
              ),
              if (_isTyping)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(_botAvatarUrl),
                        radius: 16,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            _TypingIndicator(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: inputBackgroundColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Escribe un mensaje...',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
                            suffixIcon: IconButton(
                              icon: Image.asset(
                                'assets/icons/send.png',
                                width: 24,
                                height: 24,
                                color: isDarkMode ? Colors.white : null,
                              ),
                              onPressed: _sendMessage,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String userAvatarUrl;
  final String botAvatarUrl;
  final bool isDarkMode;

  const MessageBubble({
    super.key,
    required this.message,
    required this.userAvatarUrl,
    required this.botAvatarUrl,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundImage: AssetImage(botAvatarUrl),
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser ? const Color.fromARGB(255, 66, 134, 206) : isDarkMode ? Colors.grey[700] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser ? Colors.white70 : isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundImage: _getImageProvider(userAvatarUrl),
              radius: 16,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
  
  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    } else if (imageUrl.startsWith('file://')) {
      return FileImage(File(imageUrl.replaceFirst('file://', '')));
    } else if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    } else {
      // Si no coincide con ninguno de los patrones anteriores, usar imagen por defecto
      return AssetImage('assets/doctor.webp');
    }
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[400],
            shape: BoxShape.circle,
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final t = (((_controller.value + delay) % 1.0) * 2 - 1).abs();
              return Transform.translate(
                offset: Offset(0, -4 * t),
                child: child,
              );
            },
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey[400],
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _PulsingCircle extends StatefulWidget {
  const _PulsingCircle();

  @override
  _PulsingCircleState createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo base (siempre visible)
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
          // Efecto radar pulsante
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: 1.0 - _controller.value,
                child: Container(
                  width: 12 * _controller.value,
                  height: 12 * _controller.value,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4CAF50),
                      width: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}