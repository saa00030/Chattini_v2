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
import 'modelos/data_base.dart';
import 'pantalla_camara.dart';


class PantallaConversacion extends StatefulWidget {
  final Map<String, dynamic> receptor;
  final String receptorId;


  const PantallaConversacion({super.key, required this.receptor, required this.receptorId});

  @override
  State<PantallaConversacion> createState() => _PantallaConversacionState();
}

class _PantallaConversacionState extends State<PantallaConversacion> {
  final TextEditingController _mensajes = TextEditingController();
  final DataBase _db = DataBase(); //Instancia del singleton
  final String miUid = FirebaseAuth.instance.currentUser!.uid;

  //Estados
  bool _subiendoArchivo = false;
  bool _grabando = false;

  //Grabacion y audio
  final AudioRecorder audioRecorder = AudioRecorder();
  AudioPlayer audioplayer = AudioPlayer();

  @override
  void dispose(){
    _mensajes.dispose();
    audioRecorder.dispose();
    audioplayer.dispose();
    super.dispose();
  }

  // Logica de identificacion
  String obtenerId(){
    List<String> ids = [miUid, widget.receptorId];
    ids.sort();//ordenarlo
    return ids.join("-");
  }


  //Logica de audio
  Future<void> _empezarAGrabar() async {
    try {
      if (await audioRecorder.hasPermission()) {
        final directorio = await getApplicationDocumentsDirectory();
        //Creamos un nombre unico para un archivo temporal
        String path = '${directorio.path}/audio_${DateTime
            .now()
            .millisecondsSinceEpoch}.m4a';

        await audioRecorder.start(const RecordConfig(), path: path);

        setState(() {
          _grabando = true; //Notificamos a la interfaz
        });
      }
    }catch(e){
      print("Error al grabar: $e");
    }
  }

  Future<void> _pararYSubirGrabacion() async {
    final path = await audioRecorder.stop();
    
    setState((){
      _grabando = false;
    });

    if (path != null){
      _subirArchivoAFirebase(File(path),"audio");
    }
  }  

  Future<void> _subirArchivoAFirebase(File archivo, String tipo) async{
    setState(() {
      _subiendoArchivo = true;
    });
    try{
      String carpeta = tipo == "audio" ? "audios" : "imagenes";
      String ext = tipo == "audio" ? ".m4a" : ".jpg";
      String nombre = "file_${DateTime.now().millisecondsSinceEpoch}$ext";

      Reference ref = FirebaseStorage.instance.ref().child(carpeta).child(nombre);
      await ref.putFile(archivo);
      String url = await ref.getDownloadURL();

      //Llamamos a la clase DataBase para guardar en FireStore
      await _db.enviarMensaje(
        idChat: obtenerId(),
        emisorId: miUid,
        receptorId: widget.receptorId,
        urlContenido: url,
        tipo: tipo,
      );
    }catch(e){
      print("Error al subir: $e");
    }finally{
      setState(() {
        _subiendoArchivo = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.receptor['nombreUsuario'] ?? 'Chat'),
        backgroundColor: const Color(0xFFEAA64F),
      ),
      body: SafeArea(
        child: Column(
        children: [
          //Listado de mensajes en ese momento
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.obtenerMensajes(obtenerId()), //Llamamos a la funcion de dataBase
              builder: (context,snapshot){
                if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var mensajes_chat = snapshot.data!.docs;

                //devolvemos la lista de mensajes
                return ListView.builder(
                  reverse: true,//de abajo hacia arriba
                  padding: const EdgeInsets.all(12),
                  itemCount: mensajes_chat.length,
                  itemBuilder: (context,index){
                    var datos = mensajes_chat[index].data() as Map<String, dynamic>;
                    return _buildMensajeBurbuja(datos, datos['emisorId'] == miUid);
                  },
                );
              },
            ),
          ),
          //Barra de entrada mensajes, diseño de la vista al entrar , se llama al diseño
          _buildEntradaTexto(),
        ],
        ),
      ),
    ),
        if(_subiendoArchivo)
          const Center(child: CircularProgressIndicator(color: Color(0xFFEAA64F),),)
      ],
    );
  }

  // bOCADILLO PARA LOS MENSAJES
  Widget _buildMensajeBurbuja(Map<String, dynamic> datos, bool mi_mensaje) {
    String tipo = datos['tipo'] ?? 'texto';
    String url = datos['urlContenido'] ?? '';
    bool leido = datos['leido'] ?? false;

    dynamic fecha = datos['fechaEnvio'];
    String horaRelativa = '...';
    if (fecha != null && fecha is Timestamp) {
      // Usamos timeago para el "hace 2 min"
      horaRelativa = timeago.format(fecha.toDate(), locale: 'es_short');
    }


    return Align(
      alignment: mi_mensaje ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
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
            if (tipo == 'imagen')
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(url, width: 200),
              ),
            if (tipo == 'audio')
              IconButton(
                icon: Icon(Icons.play_circle, color: mi_mensaje ? Colors.white : Colors.black),
                onPressed: () => audioplayer.play(UrlSource(url)),
              ),
            if (datos['texto'] != null && datos['texto'].isNotEmpty)
              Text(datos['texto'], style: TextStyle(color: mi_mensaje ? Colors.white : Colors.black)),

            const SizedBox(height: 4),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  horaRelativa,
                  style: TextStyle(
                    fontSize: 10,
                    color: mi_mensaje ? Colors.white70 : Colors.black54,
                  ),
                ),
                if (mi_mensaje) ...[
                  const SizedBox(width: 4),
                  Icon(
                    leido ? Icons.done_all : Icons.done,
                    size: 14,
                    color: leido ? Colors.blueAccent : Colors.white70,
                  ),
                ],
              ],
            )
          ],
        ),
      ),
    );
  }
    Widget _buildEntradaTexto(){

      return Container(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mensajes,
                onChanged: (v) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Escribe...",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () async {
                      final path = await Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaCamara()));
                      if (path != null) _subirArchivoAFirebase(File(path), "imagen");
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _mensajes.text.isNotEmpty
                ? CircleAvatar(
              backgroundColor: const Color(0xFFEAA64F),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () {
                  _db.enviarMensaje(
                    idChat: obtenerId(),
                    emisorId: miUid,
                    receptorId: widget.receptorId,
                    texto: _mensajes.text,
                    tipo: "texto",
                  );
                  _mensajes.clear();
                  setState(() {});
                },
              ),
            )
                : GestureDetector(
              onLongPressStart: (_) => _empezarAGrabar(),
              onLongPressEnd: (_) => _pararYSubirGrabacion(),
              child: CircleAvatar(
                backgroundColor: _grabando ? Colors.red : const Color(0xFFEAA64F),
                child: Icon(_grabando ? Icons.stop : Icons.mic, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }


}
