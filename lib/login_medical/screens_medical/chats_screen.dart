import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mi_app_flutter/login_medical/screens_medical/home.dart';
import 'package:provider/provider.dart';
import 'package:mi_app_flutter/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final String _botAvatarUrl = 'assets/doc.png';
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
      
      if (imagenUrl != null && imagenUrl.isNotEmpty) {
        setState(() {
          _userAvatarUrl = imagenUrl;
          print("✅ Imagen de usuario sincronizada en ChatScreen: $imagenUrl");
        });
      } else {
        // Si no hay imagen URL en SharedPreferences, intentar usar la imagen local
        final imagenLocalPath = prefs.getString('imagen_local_path');
        if (imagenLocalPath != null) {
          setState(() {
            _userAvatarUrl = 'file://$imagenLocalPath';
            print("✅ Usando imagen local en ChatScreen: $_userAvatarUrl");
            // Guardar para sincronizar con otras pantallas
            prefs.setString('imagen_url', _userAvatarUrl);
          });
        }
      }
    } catch (e) {
      print("❌ Error al cargar imagen de usuario en ChatScreen: $e");
    }
  }

  void _initializeChat() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-robotics-er-1.5-preview',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.2,  // Temperatura baja para respuestas más rápidas y directas
        maxOutputTokens: 2048,  // Tokens reducidos para respuestas más rápidas
        topK: 64,
        topP: 0.95,
      ),
    );
    _chat = _model.startChat(
      history: [
        Content.text("I am Maval, a health expert. I provide brief and clear advice on health topics only. I use emojis to make responses engaging. My answers are concise and practical. I strictly limit my responses to health topics. I must respond in the same language as the user. I always provide helpful responses.")
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
      
      // Intentar streaming primero
      try {
        final stream = _chat.sendMessageStream(content);
        String fullResponse = '';
        int botMessageIndex = -1;
        bool firstChunk = true;
        bool hasResponse = false;
        
        await stream.timeout(Duration(seconds: 10)).forEach((chunk) async {
          if (chunk.text != null && chunk.text!.isNotEmpty) {
            hasResponse = true;
            
            if (firstChunk) {
              botMessageIndex = _messages.length;
              setState(() {
                _isTyping = false;
                _messages.add(ChatMessage(
                  text: '',
                  isUser: false,
                  timestamp: DateTime.now(),
                ));
              });
              firstChunk = false;
            }
            
            fullResponse += chunk.text!;
            setState(() {
              _messages[botMessageIndex] = ChatMessage(
                text: fullResponse,
                isUser: false,
                timestamp: _messages[botMessageIndex].timestamp,
              );
            });
            _scrollToBottom();
            await Future.delayed(Duration(milliseconds: 15));
          }
        });
        
        // Si streaming no funcionó, usar método normal
        if (!hasResponse) {
          throw Exception('No streaming response');
        }
        
      } catch (streamError) {
        print('Streaming falló, usando método normal: $streamError');
        
        // Método de respaldo: usar sendMessage normal
        final response = await _chat.sendMessage(content).timeout(Duration(seconds: 10));
        
        setState(() {
          _isTyping = false;
          if (response.text != null && response.text!.isNotEmpty) {
            _messages.add(ChatMessage(
              text: response.text!,
              isUser: false,
              timestamp: DateTime.now(),
            ));
          } else {
            _messages.add(ChatMessage(
              text: 'Hola! Soy Maval, tu asistente de salud. ¿En qué puedo ayudarte hoy?',
              isUser: false,
              timestamp: DateTime.now(),
            ));
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('❌ Error en chat: $e');
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: 'Sorry, there was an error processing your message. Please try again. Error: $e',
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool darkModeEnabled = themeProvider.darkModeEnabled;
    
    final Color backgroundColor = darkModeEnabled ? const Color(0xFF121212) : Colors.white;
    final Color textColor = darkModeEnabled ? Colors.white : Colors.black87;
    final Color subtitleColor = darkModeEnabled ? Colors.grey[400]! : Colors.black54;
    final Color inputBackgroundColor = darkModeEnabled ? const Color(0xFF2C2C2C) : const Color.fromARGB(166, 187, 183, 183);
    final Color hintColor = darkModeEnabled ? Colors.grey[500]! : const Color.fromARGB(255, 150, 152, 156);
    final Color bubbleColorBot = darkModeEnabled ? const Color(0xFF2C2C2C) : Colors.white;

    return WillPopScope(
      onWillPop: () async {
        _navigateToHome();
        return false;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard when tapping outside
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
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
                      'Asistente Médico AI',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        _PulsingCircle(),
                        const SizedBox(width: 6),
                        Text(
                          'Disponible 24/7',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                  darkModeEnabled 
                    ? 'assets/fondo_chats/fondo_oscuro.webp'
                    : 'assets/fondo_chats/fondo_claro.webp',
                ),
                fit: BoxFit.cover,
                opacity: 1.0, // Asegurar opacidad completa
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/doc.png',
                                width: 120,
                                height: 120,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '¿Cómo puedo ayudarte hoy?',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Preguntame cualquier cosa sobre salud y bienestar. Estoy aquí para proporcionar información y apoyo.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: subtitleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return MessageBubble(
                              message: message,
                              userAvatarUrl: _userAvatarUrl,
                              botAvatarUrl: _botAvatarUrl,
                              textColor: darkModeEnabled ? Colors.white : Colors.black87,
                              subtitleColor: darkModeEnabled ? Colors.white70 : Colors.black54,
                              bubbleColorBot: darkModeEnabled ? Colors.grey[700]! : Colors.white,
                            );
                          },
                        ),
                ),
                if (_isTyping)
                  Container(
                    padding: const EdgeInsets.only(left: 16, bottom: 12),
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
                            color: bubbleColorBot,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: _TypingIndicator(
                            dotColor: darkModeEnabled ? Colors.grey[400] : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
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
                            decoration: InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              hintStyle: TextStyle(
                                color: hintColor,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
                              suffixIcon: IconButton(
                                icon: ImageIcon(
                                  const AssetImage('assets/icons/send.png'),
                                  color: const Color.fromARGB(255, 66, 134, 206),
                                  size: 24,
                                ),
                                onPressed: _sendMessage,
                              ),
                            ),
                            style: TextStyle(color: textColor),
                            onSubmitted: (_) => _sendMessage(),
                            textInputAction: TextInputAction.send,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.sentences,
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
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
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
  final Color textColor;
  final Color subtitleColor;
  final Color bubbleColorBot;

  const MessageBubble({
    super.key,
    required this.message,
    required this.userAvatarUrl,
    required this.botAvatarUrl,
    required this.textColor,
    required this.subtitleColor,
    required this.bubbleColorBot,
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
                color: message.isUser ? const Color.fromARGB(255, 66, 134, 206) : bubbleColorBot,
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
                            color: textColor,
                            fontSize: 14,
                          ),
                          strong: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser ? Colors.white70 : subtitleColor,
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
    } else if (imageUrl.isNotEmpty) {
      // Si es una ruta relativa del servidor
      return NetworkImage("https://inmigracion.maval.tech/storage/$imageUrl");
    } else {
      // Si no coincide con ninguno de los patrones anteriores o está vacío, usar imagen por defecto
      return AssetImage('assets/doctor.webp');
    }
  }
}

class _TypingIndicator extends StatefulWidget {
  final Color? dotColor;
  
  const _TypingIndicator({super.key, this.dotColor});

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
    final dotColor = widget.dotColor ?? Colors.grey[400];
    
    return Row(
      children: List.generate(3, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: dotColor,
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
                color: dotColor,
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
  const _PulsingCircle({super.key});

  @override
  _PulsingCircleState createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: false);
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16, // Ancho fijo para evitar movimiento
      height: 16, // Alto fijo para evitar movimiento
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Círculo exterior pulsante (ahora crece)
              Container(
                width: 8 + (8 * _animation.value), // Crece de 8 a 16px
                height: 8 + (8 * _animation.value), // Crece de 8 a 16px
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.7 * (1 - _animation.value)), // Se desvanece mientras crece
                ),
              ),
              // Círculo interior fijo
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}