import 'package:cloud_firestore/cloud_firestore.dart';
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
    required String texto,
  }) async{
    //se llama donde estan los chats
    final chatDocumento = _firestore.collection('chats').doc(idChat);

    //Escribe la subcoleccion
    await chatDocumento.collection('mensajes').add({
      'emisorId':emisorId,//manda el mensaje con identificador
      'receptorId': receptorId, //usuario recibe el mensaje
      'texto' : texto, //string de mensaje que mandan
      'fechaEnvio' : FieldValue.serverTimestamp(),
    });

    //Actualiza el chatDocumento conforme va leyendo mensajes
    await chatDocumento.set({
      'ultimoMensaje': texto,//saber el ultimo mensaje que se envio en la conversacion
      'ultimaVez': FieldValue.serverTimestamp(),// saber cuando se conecto la ultima vez
      'usuarios':[emisorId,receptorId],//el identificador  y el del receptor
    }, SetOptions(merge: true));
  }
}