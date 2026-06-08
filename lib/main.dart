import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:instachat_v2/pantallaInicioVacia.dart';
import 'package:instachat_v2/pantalla_camara.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pantallaChats.dart';
import 'package:timeago/timeago.dart' as timeago;


// Punto de entrada principal de la aplicación Chattini.
// Se marca como 'async' debido a que la inicialización de los servicios de Firebase es asíncrona.
void main() async {
  //Aseguramos que los widgets de flutter estan inicializados antes de ejecutar otro codigo (Firebase)
  WidgetsFlutterBinding.ensureInitialized();
  //Inicializamos firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //Configuracion del paquete 'timeago' para la gestion de tiempos de archivos multimedia
  timeago.setLocaleMessages('es', timeago.EsMessages()); //Queremos que sea en español
  timeago.setLocaleMessages('es_short', timeago.EsShortMessages());
  //Lanzamos de forma definitiva la aplicacion
  runApp(const MyApp());
}

//Widget de la aplicacion que configura el diseño global
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      debugShowCheckedModeBanner: false,
      title: 'Chattini',
      //Configuramos el diseño de la interfaz global
      theme: ThemeData(
        //Configuramos los colores de la aplicacion, a partir del color naranja
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFEAA64F)),
        useMaterial3: true,
      ),
      //En lugar de cargar una pantalla fija, delegamos el flujo de la aplicacion a la funcion AuthWrapper
      // programada abajo
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    //Este primer StreamBuilder mira si el usuario esta logueado
    return StreamBuilder<User?>(
        //Escucha al flujo 'authStateChanges()' para reaccionar en tiempo real
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot){
          //Caso 1: Estado de espera, por si firebase todavia esta verificando las credenciales
          if (authSnapshot.connectionState == ConnectionState.waiting){
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          //Caso 2: Usuario no autenticado y el flujo de datos no contiene información del usuario
          if(!authSnapshot.hasData){
            return const LoginPage();
          }

          //Caso 3: Usuario autenticado con exito, se envia a la lista principal de la aplicacion
          return const ListaContactos();
        },
    );
  }
}
