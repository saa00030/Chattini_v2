
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

//Mientras que datbase se encarga de chats y mensajes, este se encarga de seguridad y usuarios

class FirebaseService {
  //Creacion instancia Firebase
  //Controla emails, contraseñas y datos del perfil
  final FirebaseAuth autentificacion = FirebaseAuth.instance;
  final FirebaseFirestore bbdd = FirebaseFirestore.instance;

  //Valida si correo y contraseñas son validos en internet
  Future<User?> iniciarSesion(String email, String password) async{
    try{
      //Le pedimos a firebase que verifique las credenciales
      UserCredential userCredential = await autentificacion.signInWithEmailAndPassword(
          email: email,
          password: password,
      );
      //Si esta todo bien, nos devuelve datos del usuario
      return userCredential.user;
    } on FirebaseAuthException catch  (e){
      //Si hay algun error, lo capturamos y mostramos en el SnackBar (Aviso flotante=
      throw e;
    }
  }
  //Metodo para registrar usuario nuevo
  Future<User?> registrarUser({
    required String nombreUser,
    required String email,
    required String password,
}) async{
    try{
      //Crea el Usuario en Firebase Auth
      UserCredential credenciales = await autentificacion.createUserWithEmailAndPassword(
          email: email.trim(), //.trim borra espacios en blanco
          password: password,
      );
      //Guardamos datos si todo ha ido bien
      if (credenciales.user != null){
        await bbdd.collection('usuarios').doc(credenciales.user!.uid).set({
          'nombreUsuario': nombreUser.trim(),
          'correo': email.trim(),
          'uid': credenciales.user!.uid,
          'fechaRegistro': DateTime.now(), //Dia y hora del registro
          'busqueda': nombreUser.trim().toLowerCase(),
          'mis_chats': [],
        });
      }
      return credenciales.user;

    }on FirebaseAuthException catch  (e){
      //Error si el correo es repetido o contraseña debil, se muestra en snackbar
      throw e;
    }
  }
}