
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  //Creacion instancia Firebase
  final FirebaseAuth autentificacion = FirebaseAuth.instance;
  final FirebaseFirestore bbdd = FirebaseFirestore.instance;

  Future<User?> iniciarSesion(String email, String password) async{
    try{
      UserCredential userCredential = await autentificacion.signInWithEmailAndPassword(
          email: email,
          password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch  (e){
      //Error si hay se muestre en el SnackBar
      throw e;
    }
  }
  Future<User?> registrarUser({
    required String nombreUser,
    required String email,
    required String password,
}) async{
    try{
      //Usuario en Firebase Auth
      UserCredential credenciales = await autentificacion.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
      );
      //Guardamos datos si todo ha ido bien
      if (credenciales.user != null){
        await bbdd.collection('usuarios').doc(credenciales.user!.uid).set({
          'nombreUsuario': nombreUser.trim(),
          'correo': email.trim(),
          'uid': credenciales.user!.uid,
          'fechaRegistro': DateTime.now(),
          'busqueda': nombreUser.trim().toLowerCase(),
          'mis_chats': [],
        });
      }
      return credenciales.user;

    }on FirebaseAuthException catch  (e){
      //Error si hay se muestre en el SnackBar
      throw e;
    }
  }
}