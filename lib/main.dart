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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //Para que salga en español el mensaje de leido
  timeago.setLocaleMessages('es', timeago.EsMessages());
  timeago.setLocaleMessages('es_short', timeago.EsShortMessages());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chattini',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFEAA64F)),
        useMaterial3: true,
      ),
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
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot){
          //Cargando conexion de auth
          if (authSnapshot.connectionState == ConnectionState.waiting){
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          //Si NO hay usuario, a la pantalla de login
          if(!authSnapshot.hasData){
            return const LoginPage();
          }

          //Si SI hay usuario, miramos su base de datos, mira si tiene chats o su lista esta vacia
          return const ListaContactos();
        },
    );
  }
}
