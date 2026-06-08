import 'package:cloud_firestore/cloud_firestore.dart';
//Esta clase se encarga de guardar, leer y enviar toda la informacion hacia firebase
//El principal objetivo de esta clase es por si en un futuro se cambiase de firebase a otra plataforma
//Solo habria que cambiar esta clase en todo el proyecto
class DataBase {
  //intancia de la clase
  static final DataBase _base = DataBase._internal();
  //CUando pongamos database en cualquier parte de la app, este constructor nos
  //devolvera la instancia de arriba
  factory DataBase(){
    return _base;
  }
  //Contructor privado y oculto, nadie fuera de la clase puede usarlo
  DataBase._internal();

  //Firestores para uso interno y directo a las herramientas de FireStore
  FirebaseFirestore get  _firestore => FirebaseFirestore.instance;

  //Se crea un ID unico para el canal uniendo los dos UIDS
  //Por ejemplo: SI juan habla con ana, se crea id, chat ana_juan
  String generarIdChatUnico(String uid1, String uid2) {
    List<String> ids = [uid1, uid2];
    ids.sort(); // Ordena alfabéticamente (ej: ['abc', 'xyz'])
    return ids.join('_'); // Resultado estable: 'abc_xyz'
  }

  //Escucha en tiempo real, devuelve un flujo constante de mensajes
  Stream<QuerySnapshot> obtenerMensajes(String idChat){
    return _firestore
        .collection('chats')
        .doc(idChat)
        .collection('mensajes')
        .orderBy('fechaEnvio',descending: true)//salga los mensajes nuevos primero
        .snapshots();
  }
  //Metodo enviar mensaje, guarda el mensaje en internet
  Future<void> enviarMensaje({
    required String idChat,
    required String emisorId,
    required String  receptorId,
    String? texto,
    String? urlContenido, //Para audio o foto
    required String tipo, //Texto, audio o imagen
  }) async{
    //Apuntamos al documento de ese chat concreto
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

  //Se registra de forma segura que ambos usuarios tienen un chat comun
  Future<void> _actualizarListaMisChats(String emisorId, String receptorId) async{
    await _firestore.collection('usuarios').doc(emisorId).update({
      'mis_chats': FieldValue.arrayUnion([receptorId])
    });
    await _firestore.collection('usuarios').doc(receptorId).update({
      'mis_chats': FieldValue.arrayUnion([emisorId])
    });
  }
}