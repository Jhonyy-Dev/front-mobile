import 'package:flutter/material.dart';
import 'package:mi_app_flutter/login_migration/screens_migration/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  List<Map<String, String>> _conversationHistory = [];
  int _currentKeyIndex = 0;
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
            _userAvatarUrl = "https://inmigracion.maval.tech/storage/$imagenUrl";
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
    _conversationHistory = [
      {
        'role': 'system',
        'content': 'Soy Maval, experto en inmigración de Estados Unidos. Doy respuestas CORTAS y directas sobre temas de inmigración únicamente. Máximo 3-4 oraciones por respuesta. Uso 1-2 emojis máximo. Sin listas largas. Respondo en el mismo idioma del usuario.',
      }
    ];
  }

  List<String> _getGroqKeys() {
    return [
      dotenv.env['GROQ_API_KEY'] ?? '',
      dotenv.env['GROQ_API_KEY_2'] ?? '',
      dotenv.env['GROQ_API_KEY_3'] ?? '',
      dotenv.env['GROQ_API_KEY_4'] ?? '',
      dotenv.env['GROQ_API_KEY_5'] ?? '',
    ].where((k) => k.isNotEmpty).toList();
  }

  Future<String> _sendGroqMessage(List<Map<String, String>> messages) async {
    final keys = _getGroqKeys();
    if (keys.isEmpty) throw Exception('No hay API keys de Groq configuradas');

    for (int i = 0; i < keys.length; i++) {
      final keyIndex = (_currentKeyIndex + i) % keys.length;
      final key = keys[keyIndex];

      try {
        final response = await http.post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $key',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'llama-3.3-70b-versatile',
            'messages': messages,
            'temperature': 0.2,
            'max_tokens': 600,
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          _currentKeyIndex = keyIndex;
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          return data['choices'][0]['message']['content'] as String;
        } else if (response.statusCode == 429) {
          print('🔄 Key Groq ${keyIndex + 1} agotada, probando siguiente...');
          continue;
        } else {
          throw Exception('Groq error ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        if (i == keys.length - 1) rethrow;
        print('⚠️ Error con key Groq ${keyIndex + 1}: $e');
      }
    }
    throw Exception('Todas las keys de Groq están agotadas');
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

    _conversationHistory.add({'role': 'user', 'content': userMessage});

    try {
      final responseText = await _sendGroqMessage(_conversationHistory);
      _conversationHistory.add({'role': 'assistant', 'content': responseText});

      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    } catch (e) {
      print('❌ Error en chat Groq: $e');
      _conversationHistory.removeLast();
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
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(context).viewPadding.bottom > 0 
                    ? MediaQuery.of(context).viewPadding.bottom 
                    : 8,
                ),
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
                  message.isUser 
                    ? Text(
                        message.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      )
                    : MarkdownBody(
                        data: message.text,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                          strong: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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