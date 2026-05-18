import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

class PantallaCamara extends StatefulWidget {
  const PantallaCamara({super.key});

  @override
  State<PantallaCamara> createState() => _PantallaCamaraState();
}

class _PantallaCamaraState extends State<PantallaCamara> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<CameraDescription> _camaras = [];
  int _camaraIndex = 0;

  @override
  void initState(){
    super.initState();
    _recuperarCamaras();
  }

  //En primer lugar obtenemos la lista de camaras disponibles
  Future<void> _recuperarCamaras() async{
    try {
      _camaras = await availableCameras();
      if (_camaras.isNotEmpty) {
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
      await _controller!.dispose();
    }

    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false, //Desactivamos audio para las fotos (ahorra recursos)
    );

    if(!mounted) return;

    setState(() {
      _initializeControllerFuture = _controller!.initialize();
    });
  }

  @override
  void dispose(){
    //Se limpia el controlador cuando se destruye
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _hacerFoto(BuildContext context) async{
    try{
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      if(!mounted) return;

      Navigator.pop(context, image.path);
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al hacer la foto: $e')),
      );
    }
  }

  //Funcion para alternar entre camara frontal y trasera
  void _conmutarCamara(){
    if(_camaras.length < 2) return;

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
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && _controller != null) {
            return Center(
              //CameraPreview: Paquete oficial de flutter
              child: CameraPreview(_controller!),
            );
          } else {
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

