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
  String? _pathAudioActual;

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
    return _db.generarIdChatUnico(miUid, widget.receptorId);
  }

  void _marcarMensajesComoLeidos() async {
    final String idChat = obtenerId();
    var query = await FirebaseFirestore.instance
        .collection('chats')
        .doc(idChat)
        .collection('mensajes')
        .where('receptorId', isEqualTo: miUid) // Mensajes dirigidos a mí
        .where('leido', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      doc.reference.update({'leido': true});
    }
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

  Future<void> _pararDeGrabar() async {
    final path = await audioRecorder.stop();
    
    setState((){
      _grabando = false;
      _pathAudioActual = path; //Guardamos el archivo temporalmente
    });

  }

  void _cancelarAudio(){
    setState(() {
      _pathAudioActual = null;
      _grabando = false;
    });
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

                WidgetsBinding.instance.addPostFrameCallback((_) => _marcarMensajesComoLeidos());

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
          Container(
            color: Colors.black26, // Aplica un sombreado gris transparente
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFEAA64F)), //Carga
            ),
          )
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
                onPressed: () async {
                  try {
                    await audioplayer.stop(); // Detiene cualquier audio que esté sonando antes
                    await audioplayer.play(UrlSource(url)); // Reproduce el nuevo audio
                  } catch (e) {
                    print("Error al reproducir audio: $e");
                  }
                },
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
  Widget _buildEntradaTexto() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Si ya ha grabado el audio y está pendiente de enviar, ocultamos el TextField
          if (_pathAudioActual != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.mic, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Audio grabado listo para enviar",
                        maxLines: 1, // <--- OBLIGATORIO: Fuerza a que se quede en una sola línea
                        overflow: TextOverflow.ellipsis, // <--- CLAVE: Si no cabe, añade "..." de forma elegante
                        style: const TextStyle(
                          fontSize: 16, // Ajusta el tamaño si lo necesitas
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
          // Si no hay audio grabado, mostramos el TextField de siempre
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

          // LÓGICA DE BOTONES DINÁMICOS
          if (_pathAudioActual != null) ...[
            // BOTÓN CANCELAR (Papelera)
            CircleAvatar(
              backgroundColor: Colors.grey[400],
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: _cancelarAudio,
              ),
            ),
            const SizedBox(width: 8),
            // BOTÓN ENVIAR AUDIO
            CircleAvatar(
              backgroundColor: const Color(0xFFEAA64F),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () {
                  _subirArchivoAFirebase(File(_pathAudioActual!), "audio");
                  _cancelarAudio(); // Limpiamos el estado al terminar
                },
              ),
            ),
          ] else if (_mensajes.text.isNotEmpty) ...[
            // BOTÓN ENVIAR TEXTO NORMAL
            CircleAvatar(
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
            ),
          ] else ...[
            // BOTÓN DE GRABACIÓN DE AUDIO (Pulsar una vez para grabar, otra para parar)
            CircleAvatar(
              backgroundColor: _grabando ? Colors.red : const Color(0xFFEAA64F),
              child: IconButton(
                icon: Icon(_grabando ? Icons.stop : Icons.mic, color: Colors.white),
                onPressed: _grabando ? _pararDeGrabar : _empezarAGrabar,
              ),
            ),
          ],
        ],
      ),
    );
  }


}
