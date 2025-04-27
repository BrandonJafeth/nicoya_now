import 'package:flutter/material.dart';
import 'package:nicoya_now/app.dart';
import 'package:nicoya_now/services/data/data_manager.dart';

void main() async {
  // Asegurarse de que los widgets de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar nuestra infraestructura de datos híbrida
  try {
    await DataManager.instance.initialize();
    print('Inicialización de datos híbrida completada con éxito');
  } catch (e) {
    print('Error inicializando el sistema de datos híbrido: $e');
    // Continuar con la aplicación de todos modos, usando solo datos locales si es necesario
  }
  
  runApp(const NicoyaNowApp());
}
