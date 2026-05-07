import 'dart:ui';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'pantalla_camara.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';


class PantallaConversacion extends StatefulWidget {
  final Map<String, dynamic> receptor;
  final String receptorId;


  const PantallaConversacion({super.key, required this.receptor, required this.receptorId});

  @override
  State<PantallaConversacion> createState() => _PantallaConversacionState();
}

class _PantallaConversacionState extends State<PantallaConversacion> {
  final TextEditingController _mensajes = TextEditingController();
  final String miUid = FirebaseAuth.instance.currentUser!.uid;
  bool _subiendoImagen = false;
  bool _grabando = false;

  final AudioRecorder audioRecorder = AudioRecorder();
  AudioPlayer audioplayer = AudioPlayer();

  //Iniciamos grabacion
  Future<void> _empezarAGrabar() async {
    if(await audioRecorder.hasPermission()){
      final directorio = await getApplicationDocumentsDirectory();
      //Creamos un nombre unico para un archivo temporal
      String path = '${directorio.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await audioRecorder.start(const RecordConfig(), path: path);

      setState((){
        _grabando = true; //Notificamos a la interfaz
      });
    }
  }

  Future<void> _pararGrabacion() async {
    final path = await audioRecorder.stop();
    
    setState((){
      _grabando = false;
    });

    if (path != null){
      _subirAudioAFirebase(File(path));
    }
  }  

  Future<void> _subirAudioAFirebase(File file) async{
    String nombre = "audio_${DateTime.now().millisecondsSinceEpoch}.m4a";
    var ref = FirebaseStorage.instance.ref().child("audios").child(nombre);

    await ref.putFile(file);
    String url = await ref.getDownloadURL();

    //Guardar en Firestore como mensaje
    _enviarMensajes(url: url, tipo: "audio");
  }

  @override
  void initState() {
    super.initState();
    _marcarMensajesLeidos();
}
  // Generar un id para los mismo usuarios
  String obtenerId(){
    List<String> ids = [miUid, widget.receptorId];
    ids.sort();//ordenarlo
    return ids.join("-");
  }

  Future<void> _enviarFoto(String rutaLocal) async{
    setState(() {
      _subiendoImagen = true;
    });
    try{
      String idGrupoMensajes = obtenerId();
      // Nombre unico para el archivo en Storage
      String nombreArchivo = "img_${DateTime.now().millisecondsSinceEpoch}.jpg";

      //Subida a Storage
      Reference ref = FirebaseStorage.instance
        .ref()
        .child("chats")
        .child(idGrupoMensajes)
        .child(nombreArchivo);

      UploadTask uploadTask = ref.putFile(File(rutaLocal));
      TaskSnapshot snapshot = await uploadTask;

      //Obtenemos la URL
      String urlImagen = await snapshot.ref.getDownloadURL();

      //Guardamos en Firestore(Misma escritura que en los mensajes)
      await FirebaseFirestore.instance
        .collection('chats')
        .doc(idGrupoMensajes)
        .collection('mensajes')
        .add({
        'emisorId': miUid,
        'receptorId': widget.receptorId,
        'texto': '', //Texto vacio
        'urlImagen': urlImagen, //Guardamos la URL
        'tipo': 'imagen', //Importante para saber que dibujar
        'leido': false,
        'fechaEnvio': FieldValue.serverTimestamp(),
      });
      
      //Actualizamos ultimo mensaje en la lista de chats
      await FirebaseFirestore.instance.collection('chats').doc(idGrupoMensajes).set({
        'ultimoMensaje': 'Foto',
        'ultimaVez': FieldValue.serverTimestamp(),
        'usuarios': [miUid, widget.receptorId],
      }, SetOptions(merge: true));

      //Añadir al receptor a MI lista de chats
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(miUid)
          .update({
        'mis_chats': FieldValue.arrayUnion([widget.receptorId])
      });

      //Añadirme a mi en la lista de chats del receptor
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.receptorId)
          .update({
        'mis_chats': FieldValue.arrayUnion([miUid])
      });
      
    } catch(e){
      print("Error al subir imagen: $e");
    } finally{
      setState(() {
        _subiendoImagen = false;
      });
    }
  }

  //Funcion se van a mandar mensajes usuarios
  void _enviarMensajes() async{
    //si estan vacios los mensajes devuelve vacío
    if (_mensajes.text.trim().isEmpty) return;

    String texto = _mensajes.text.trim();
    //vayan limpiando lo que ya se ha escrito
    _mensajes.clear();
    try{
      String idGrupoMensajes = obtenerId();

      //Guarda el mensaje en sucolecciones por cada usuarios
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(idGrupoMensajes)
          .collection('mensajes')
          .add({
        'emisorId':miUid,//manda el mensaje con identificador
        'receptorId': widget.receptorId, //usuario recibe el mensaje
        'texto' : texto, //string de mensaje que mandan
        'leido': false,
        'fechaEnvio' : FieldValue.serverTimestamp(),//para tener un control de cuando se mandan los mensajes segun el servidor Google
      });
      //Actualiza la informacion de chats principal
      await FirebaseFirestore.instance.collection('chats').doc(idGrupoMensajes).set({
        'ultimoMensaje': texto,//saber el ultimo mensaje que se envio en la conversacion
        'ultimaVez': FieldValue.serverTimestamp(),// saber cuando se conecto la ultima vez
        'usuarios':[miUid,widget.receptorId],//el identificador  y el del receptor
      }, SetOptions(merge: true));

      //Añadir al receptor a MI lista de chats
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(miUid)
          .update({
          'mis_chats': FieldValue.arrayUnion([widget.receptorId])
      });

      //Añadirme a mi en la lista de chats del receptor
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.receptorId)
          .update({
        'mis_chats': FieldValue.arrayUnion([miUid])
      });
    }catch(e){
      print("Error al enviar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo enviar el mensaje")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
      appBar: AppBar(
        title: Text(widget.receptor['nombreUsuario'] ?? 'Chat'),
        backgroundColor: const Color(0xFFEAA64F),
      ),
      body: Column(
        children: [
          //Listado de mensajes en ese momento
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(obtenerId())
                    .collection('mensajes')
                    .orderBy('fechaEnvio',descending: true)//salga los mensajes nuevos primero
                    .snapshots(),
              builder: (context,snapshot){
                if (snapshot.hasError) return const Center(child: Text("Error al cargar mensajes"));
                if (snapshot.connectionState == ConnectionState.waiting){
                  return const Center(child: CircularProgressIndicator());
                }
                //Si llegan mensajes mientras los envio 
                WidgetsBinding.instance.addPostFrameCallback((_) => _marcarMensajesLeidos());
                var mensajes_chat = snapshot.data!.docs;

                //devolvemos la lista de mensajes
                return ListView.builder(
                  reverse: true,//de abajo hacia arriba
                  padding: const EdgeInsets.all(12),
                  itemCount: mensajes_chat.length,
                  itemBuilder: (context,index){
                    Map<String, dynamic> datosMensaje = mensajes_chat[index].data() as Map<String, dynamic>;
                    bool mi_mensaje = datosMensaje['emisorId'] == miUid;
                    return _buildMensajeBurbuja(datosMensaje, mi_mensaje);
                  },
                );
              },
            ),
          ),
          //Barra de entrada mensajes, diseño de la vista al entrar , se llama al diseño
          _buildDisenioConversacion(),
        ],
      ),
    ),
        if(_subiendoImagen)
          Container(
            color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0XFFEAA64F)),
                    SizedBox(height: 15),
                    Text("Subiendo foto...", style: TextStyle(color: Colors.white, decoration: TextDecoration.none, fontSize: 16)),
                  ],
                ),
              ),
          ),
      ],
    );
  }

  // bOCADILLO PARA LOS MENSAJES
  Widget _buildMensajeBurbuja(Map<String, dynamic> datos, bool mi_mensaje) {
    // Usamos ?? '' para evitar errores si el campo no existe en documentos viejos
    String? urlImagen = datos['urlImagen'];
    String texto = datos['texto'] ?? '';

    bool leido = datos['leido'] ?? false;

    //Controlando la fecha de mensajes
    dynamic fecha = datos['fechaEnvio'];
    String horaRelativa = '...';

    if (fecha != null && fecha is Timestamp){
      horaRelativa = timeago.format(fecha.toDate(), locale: 'es_short');
    }



    return Align(
      alignment: mi_mensaje ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mi_mensaje ? const Color(0xFFEAA64F) : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(mi_mensaje ? 15 : 0),
            bottomRight: Radius.circular(mi_mensaje ? 0 : 15),
          ),
        ),

        child: Column( // Usamos Column para poner texto y fotos juntas
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            //Si hay imagen
            if (urlImagen != null && urlImagen.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                urlImagen,
                width: 200,
                // Mientras carga la imagen de la nube:
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
            // Si además de la foto hubiera texto, lo podrías poner aquí abajo:
            if (texto.isNotEmpty)
              Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                  texto,
                  style: TextStyle(
                      color: mi_mensaje ? Colors.white : Colors.black,
                      fontSize : 16,
                  ),
              ),
            ),


            const SizedBox(height: 4),
              //Hora y check mensaje
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    horaRelativa,
                    style: TextStyle(
                      fontSize: 10,
                      color: mi_mensaje ? Colors.white : Colors.black
                    ),
                  ),
                  //el condicional que confirma la validacion
                  if (mi_mensaje) ...[
                    const SizedBox(width: 4),
                    Icon(
                      leido ? Icons.done_all : Icons.done,
                      size: 14 ,
                      color: leido ? Colors.blueAccent : (mi_mensaje ? Colors.white70 : Colors.grey),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildDisenioConversacion(){
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.white,
        child: Row(
          children: [
            //añado el boton de la cámara
            Expanded(
              child: TextField(
                controller: _mensajes,
                decoration: InputDecoration(
                  hintText: "Escribe aqui...",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.grey,),
                    onPressed: () async{
                      final String? rutaFoto = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PantallaCamara(),
                        ),
                      );

                      if(rutaFoto != null){
                        _enviarFoto(rutaFoto);
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius:  BorderRadius.circular(25)
                  ) ,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: const Color(0xFFEAA64F),
              child: IconButton(
                icon: const Icon(Icons.send , color: Colors.white),
                onPressed: _enviarMensajes,
              ),
            ),
          ],
        ),
      );
  }

  void _marcarMensajesLeidos() async{
    String idChat = obtenerId();
    var query = await FirebaseFirestore.instance
      .collection('chats')
      .doc(idChat)
      .collection('mensajes')
      .where('receptorId',isEqualTo: miUid) //Mensajes enviados a mí
      .where('leido',isEqualTo: false)
      .get();

    for (var doc in query.docs){
      doc.reference.update({'leido' : true});
    }
  }
}
