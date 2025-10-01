# Variables de Entorno

## Configuración

1. **Copia el archivo de ejemplo:**
   ```bash
   cp .env.example .env
   ```

2. **Edita el archivo `.env`** y agrega tus claves reales:
   ```env
   GEMINI_API_KEY= TU API KEY
   ```

## Uso en el código

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Obtener variable
final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
```

## Seguridad

- ✅ El archivo `.env` está en `.gitignore`
- ✅ Nunca subas claves reales al repositorio
- ✅ Usa `.env.example` para documentar variables necesarias
