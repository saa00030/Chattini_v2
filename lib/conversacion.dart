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

//Vista principal de conversacion
//Se implementa como StatefulWidget para controlar de forma sincrona los estados
class PantallaConversacion extends StatefulWidget {
  final Map<String, dynamic> receptor; //Datos del destinatario
  final String receptorId; //Id del destinatario


  const PantallaConversacion({super.key, required this.receptor, required this.receptorId});

  @override
  State<PantallaConversacion> createState() => _PantallaConversacionState();
}

class _PantallaConversacionState extends State<PantallaConversacion> {
  //Controlador de texto par el campo de entrada de mensajes
  final TextEditingController _mensajes = TextEditingController();
  //Instancia del singleton de la base de datos
  final DataBase _db = DataBase(); //Instancia del singleton
  //Id del usuario autenticado actualmente en la sesion local
  final String miUid = FirebaseAuth.instance.currentUser!.uid;

  //Estados
  bool _subiendoArchivo = false;
  bool _grabando = false; //Determina si el microfono esta captando audio
  String? _pathAudioActual; //Ruta local del archivo de voz grabado

  //Grabacion y audio, plugins empleados para el microfono y el audio
  final AudioRecorder audioRecorder = AudioRecorder();
  AudioPlayer audioplayer = AudioPlayer();

  @override
  void dispose(){
    //Liberacion obligatoria de memoria RAM y desvinculacion de los controladores hardware
    _mensajes.dispose();
    audioRecorder.dispose();
    audioplayer.dispose();
    super.dispose();
  }

  // Logica de identificacion, calcula ID unico y ordenado del chat bidireccional
  String obtenerId(){
    return _db.generarIdChatUnico(miUid, widget.receptorId);
  }

  //Actualiza el estado de lectura en la base de datos distribuida.
  void _marcarMensajesComoLeidos() async {
    final String idChat = obtenerId();
    var query = await FirebaseFirestore.instance
        .collection('chats')
        .doc(idChat)
        .collection('mensajes')
        .where('receptorId', isEqualTo: miUid) // Mensajes dirigidos a mí
        .where('leido', isEqualTo: false)
        .get();

    //Actualizacion de los documentos locales en la nube
    for (var doc in query.docs) {
      doc.reference.update({'leido': true});
    }
  }


  //Logica de audio
  Future<void> _empezarAGrabar() async {
    try {
      //Solicitar permisos al dispositivo para grabar
      if (await audioRecorder.hasPermission()) {
        //Localizar directorio temporal donde se puedan almacenar
        final directorio = await getApplicationDocumentsDirectory();
        //Creamos un nombre unico para un archivo temporal
        String path = '${directorio.path}/audio_${DateTime
            .now()
            .millisecondsSinceEpoch}.m4a';
        //Empezamos a grabar
        await audioRecorder.start(const RecordConfig(), path: path);

        setState(() {
          _grabando = true; //Notificamos a la interfaz, mostrando el icono de grabando
        });
      }
    }catch(e){
      print("Error al grabar: $e");
    }
  }
//Detnemos la captura de audio
  Future<void> _pararDeGrabar() async {
    final path = await audioRecorder.stop();
    
    setState((){
      _grabando = false;
      _pathAudioActual = path; //Guardamos el archivo temporalmente
    });

  }
  //Cancelamos el audio grabado
  void _cancelarAudio(){
    setState(() {
      _pathAudioActual = null;
      _grabando = false;
    });
  }
 //Subir archivos a Firebase
  Future<void> _subirArchivoAFirebase(File archivo, String tipo) async{
    setState(() {
      _subiendoArchivo = true; //Se empieza a subir el archivo
    });
    try{
      String carpeta = tipo == "audio" ? "audios" : "imagenes";
      String ext = tipo == "audio" ? ".m4a" : ".jpg";
      String nombre = "file_${DateTime.now().millisecondsSinceEpoch}$ext";

      //Subimos el archivo fisico al servidor
      Reference ref = FirebaseStorage.instance.ref().child(carpeta).child(nombre);
      await ref.putFile(archivo);
      String url = await ref.getDownloadURL(); //Extraemos la URL publica de alojamiento

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
        _subiendoArchivo = false; //Desactivamos de forma segura este proceso
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          // Gestión de Adaptabilidad y Giro: Obliga al árbol de widgets a encogerse dinámicamente
          // cuando el teclado se abre, evitando colisiones
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
            //El StreamBuilder escucha el canal constantemente abierto con Firebase
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.obtenerMensajes(obtenerId()), //Llamamos a la funcion de dataBase
              builder: (context,snapshot){
                if(!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                //Ejecutamos la logica de marcar como leido
                WidgetsBinding.instance.addPostFrameCallback((_) => _marcarMensajesComoLeidos());

                var mensajes_chat = snapshot.data!.docs;

                //devolvemos la lista de mensajes en forma de bocadillo(chat)
                return ListView.builder(
                  reverse: true,//de abajo hacia arriba(Para parecerse a un chat)
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
        //Si hay una subida multimedia en curso, se indica mediante un simbolo de carga
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

    //Gestion del tiempo en el chat
    dynamic fecha = datos['fechaEnvio'];
    String horaRelativa = '...';
    if (fecha != null && fecha is Timestamp) {
      // Usamos timeago para el "hace 2 min"
      horaRelativa = timeago.format(fecha.toDate(), locale: 'es_short');
    }


    return Align(
      //Interfaz de mensajeria: Emisor a la derecha, receptor a la izquierda
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
            //Evaluamos el tipo de mensaje para configurarlo de una forma u otra, para ponerle un estilo distinto
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
                    await audioplayer.stop(); // Detiene cualquier audio que esté sonando antes(Robustez)
                    await audioplayer.play(UrlSource(url)); // Reproduce el nuevo audio
                  } catch (e) {
                    print("Error al reproducir audio: $e");
                  }
                },
              ),
            if (datos['texto'] != null && datos['texto'].isNotEmpty)
              Text(datos['texto'], style: TextStyle(color: mi_mensaje ? Colors.white : Colors.black)),

            const SizedBox(height: 4),

            //Datos inferiores de la burbuja: Hora relativa y doble check

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
                    //Logica del estado Leido: Conmuta entre check o doble check azul
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
  //Barra de entrada inferior
  Widget _buildEntradaTexto() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Si ya ha grabado el audio y está pendiente de enviar o de ser eliminado, ocultamos el TextField
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
                      //Fuerza a una sola linea recortada con puntos suspensivos
                      child: Text(
                        "Audio grabado listo para enviar",
                        maxLines: 1, // Fuerza a que se quede en una sola línea
                        overflow: TextOverflow.ellipsis, //Si no cabe, añade "..."
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
                onChanged: (v) => setState(() {}), //Redibuja el boton enviar segun haya texto o no
                decoration: InputDecoration(
                  hintText: "Escribe...",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () async {
                      //Lanzamiento y captura de pantalla de camara independiente mediante rutas
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
                onPressed: _cancelarAudio, //Ejecucion de la accion Undo o descarte local
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
                  _mensajes.clear(); //Resetea el controlador de texto para poder enviar otro mensaje
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
