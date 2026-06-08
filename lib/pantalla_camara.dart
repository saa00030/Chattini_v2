import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

//Controlador de hardware nativo de la camara
//Se implementa como StatefulWidget para gestionar los cambios de estado
class PantallaCamara extends StatefulWidget {
  const PantallaCamara({super.key});

  @override
  State<PantallaCamara> createState() => _PantallaCamaraState();
}

class _PantallaCamaraState extends State<PantallaCamara> {
  CameraController? _controller; //Controlador de la camara
  Future<void>? _initializeControllerFuture; //Variable que gestiona la inicializacion de la camara
  List<CameraDescription> _camaras = []; //Matriz que detecta el numero de camaras detectadas
  int _camaraIndex = 0; //Indice para conmutar entre el numero de camaras

  @override
  void initState(){
    super.initState();
    //Llamada a la funcion
    _recuperarCamaras();
  }

  //En primer lugar obtenemos la lista de camaras disponibles
  Future<void> _recuperarCamaras() async{
    try {
      //Funcion para obtener las camaras disponibles
      _camaras = await availableCameras();
      if (_camaras.isNotEmpty) {
        //Inicializas con la primera camara de la lista(Que suele ser la principal, la trasera)
        _inicializarCamara(_camaras[_camaraIndex]);
      }
    } catch (e) {
      print("Error al obtener cámaras: $e");
    }
  }

  //Inicializamos la camara seleccionada de forma segura
  Future<void> _inicializarCamara(CameraDescription cameraDescription) async{

    //Si ya habia un controlador antes, lo cerramos antes de abrir el nuevo
    if (_controller != null){
    //Si existia un controlador previo activo, se destruye y se libera antes de instanciar el nuevo
      await _controller!.dispose();
    }

    //Configuracion del objeto controlador
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium, //Resolucion intermedia: Equilibrio entre calidad visual y peso del archivo
      enableAudio: false, //Desactivamos audio para las fotos (ahorra recursos)
    );
    //Verificacion: Aborta el estado si el widget ha sido desmontado de Flutter
    if(!mounted) return;

    setState(() {

      _initializeControllerFuture = _controller!.initialize();
    });
  }

  @override
  void dispose(){
    //IMPORTANTE PARA LA GESTION DE RECURSOS
    //Apaga y libera el sensor fisico al salir de la pantalla
    //Asi permitiendo que otras apps puedan usar la camara
    _controller?.dispose();
    super.dispose();
  }

  //Funcion para realizar fotografias
  Future<void> _hacerFoto(BuildContext context) async{
    try{
      //Se asegura que la camara este 100% inicializada
      await _initializeControllerFuture;
      //Captura el fotograma actual
      final image = await _controller!.takePicture();
      if(!mounted) return;

      //Importante: La pantalla de la camara no sube la foto a internet ni edita la base de datos
      //Simplemente destruye esta vista y devuelve la ruta local del texto a la pantalla de conversacion
      Navigator.pop(context, image.path);
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al hacer la foto: $e')),
      );
    }
  }

  //Funcion para alternar entre camara frontal y trasera
  void _conmutarCamara(){
    //Si el dispositivo tiene menos de 2 camaras, no se le hace caso a esta funcion
    if(_camaras.length < 2) return;
    //Rota entre las distintas camaras
    _camaraIndex = (_camaraIndex + 1) % _camaras.length;
    _inicializarCamara(_camaras[_camaraIndex]);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Hacer Foto'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          //Boton en el AppBar para girar la camara si hay mas de una disponible
          if (_camaras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: _conmutarCamara,
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture, //Escucha el estado de inicializacion de la camara
        builder: (context, snapshot) {
          //Caso 1: Se realiza con exito
          if (snapshot.connectionState == ConnectionState.done && _controller != null) {
            return Center(
              //CameraPreview: Paquete oficial de flutter, proyectando el contenido de la camara
              child: CameraPreview(_controller!),
            );
          } else {
            //Caso 2: Se esta cargando y ponemos simbolo de carga
            return const Center(child: CircularProgressIndicator(color: Color(0xFFEAA64F)));
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _hacerFoto(context),
        backgroundColor: Colors.white,
        child: const Icon(Icons.camera_alt, color: Colors.black, size: 30),
      ),
    );
  }
}

