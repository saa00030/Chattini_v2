import 'package:cloud_firestore/cloud_firestore.dart';
//Usando Singleton
class DataBase {
  //intancia de la clase
  static final DataBase _base = DataBase._internal();
  //constructor devuelve la misma instancia
  factory DataBase(){
    return _base;
  }
  //Contructor privado
  DataBase._internal();

  //Firestores para uso interno
  FirebaseFirestore get  _firestore => FirebaseFirestore.instance;

  Stream<QuerySnapshot> obtenerMensajes(String idChat){
    return _firestore
        .collection('chats')
        .doc(idChat)
        .collection('mensajes')
        .orderBy('fechaEnvio',descending: true)//salga los mensajes nuevos primero
        .snapshots();
  }
  //Metodo enviar mensaje
  Future<void> enviarMensaje({
    required String idChat,
    required String emisorId,
    required String  receptorId,
    String? texto,
    String? urlContenido, //Para audio o foto
    required String tipo, //Texto, audio o imagen
  }) async{
    //se llama donde estan los chats
    final chatDocumento = _firestore.collection('chats').doc(idChat);

    //Definimos que texto vera el usuario en la lista de chats como vista previa
    String vistaPrevia = "";
    if (tipo == "texto") vistaPrevia = texto ?? "";
    else if(tipo == "audio") vistaPrevia = "Nota de voz";
    else if(tipo == "imagen") vistaPrevia = "Foto";

    //Escribe la subcoleccion
    await chatDocumento.collection('mensajes').add({
      'emisorId':emisorId,//manda el mensaje con identificador
      'receptorId': receptorId, //usuario recibe el mensaje
      'texto' : texto ?? "", //string de mensaje que mandan
      'urlContenido': urlContenido ?? "", //Dependiendo si es audio o foto
      'tipo': tipo, //Texto, audio o imagen
      'leido': false,
      'fechaEnvio' : FieldValue.serverTimestamp(),
    });

    //Actualiza el chatDocumento conforme va leyendo mensajes
    await chatDocumento.set({
      'ultimoMensaje': vistaPrevia,//saber el ultimo mensaje que se envio en la conversacion
      'ultimaVez': FieldValue.serverTimestamp(),// saber cuando se conecto la ultima vez
      'usuarios':[emisorId,receptorId],//el identificador  y el del receptor
    }, SetOptions(merge: true));

    //Actualizamos la lista "mis_chats" de ambos usuarios
    await _actualizarListaMisChats(emisorId, receptorId);
  }

  Future<void> _actualizarListaMisChats(String emisorId, String receptorId) async{
    await _firestore.collection('usuarios').doc(emisorId).update({
      'mis_chats': FieldValue.arrayUnion([receptorId])
    });
    await _firestore.collection('usuarios').doc(receptorId).update({
      'mis_chats': FieldValue.arrayUnion([emisorId])
    });
  }
}