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

  @override
  void initState(){
    super.initState();
    _inicializarCamara();
  }

  Future<void> _inicializarCamara() async{

    final camaras = await availableCameras();
    if(camaras.isEmpty) return;

    //Cogemos la primera que se detecte que suele ser la trasera
    final primeraCamara = camaras.first;

    _controller = CameraController(
      primeraCamara,
      ResolutionPreset.medium,
    );

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

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Hacer Foto'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.done){
            return CameraPreview(_controller!);
          }else{
            return const Center(child: CircularProgressIndicator());
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

