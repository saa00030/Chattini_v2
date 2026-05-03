import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:instachat_v2/pantallaInicioVacia.dart';
import 'package:instachat_v2/pantalla_camara.dart';
import 'firebase_options.dart';
import 'login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pantallaChats.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot){
          //Cargando conexion de auth
          if (snapshot.connectionState == ConnectionState.waiting){
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          //Si NO hay usuario, a la pantalla de login
          if(!snapshot.hasData || snapshot.data == null){
            return const LoginPage();
          }

          //Si SI hay usuario, miramos su base de datos
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('usuarios')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot){
              if(userSnapshot.connectionState == ConnectionState.waiting){
                return const Scaffold(
                  backgroundColor: Color(0xFFFFDAB5),
                  body: Center(child: CircularProgressIndicator(color: Color(0xFFEAA64F))),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists){
                //Sacamos la lista de chats del usuario
                List<dynamic> misChats = userSnapshot.data!.get('mis_chats') ?? [];

                //Decision final
                if(misChats.isEmpty){
                  return const Pantallainiciovacia();
                }else{
                  return const ListaContactos();
                }
              }
              return const Pantallainiciovacia();
              },
          );
        },
    );
  }
}
