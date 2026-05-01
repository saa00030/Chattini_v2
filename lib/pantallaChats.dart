import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instachat_v2/conversacion.dart';

class ListaContactos extends StatefulWidget {
  const ListaContactos({super.key});

  @override
  State<ListaContactos> createState() => _ListaContactosState();
}

class _ListaContactosState extends State<ListaContactos> {
  final _usuariosFirebase = FirebaseFirestore.instance.collection('usuarios').snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contactos'),
        backgroundColor: const Color(0xFFEAA64F),
      ),
      body: StreamBuilder(
        stream: _usuariosFirebase,
        builder: (context,snapshot){
          if(snapshot.hasError){
            return const Center(child : Text('Error de conexion')) ;
          }
          if(snapshot.connectionState == ConnectionState.waiting){
            return const Center(child :CircularProgressIndicator());
          }
          var docs = snapshot.data!.docs;

          if (docs.isEmpty){
            return const Center(child: Text('No hay usuarios registrados'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context,index){
              //extraer datos del usuario actual
              Map<String,dynamic> datos = docs[index].data() as Map<String,dynamic>;
              //Receptor es nombre y el uid del usuario
              String nombreReceptor = datos['nombreUsuario'] ?? 'Usuario sin nombre';
              String uidReceptor = docs[index].id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFD9B3), // Tu color ámbar pálido
                  child: const Icon(Icons.person, color: Color(0xFFE7A247)),
                ),
                title: Text(
                  nombreReceptor,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text("Toca para chatear"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PantallaConversacion(
                            receptor:{
                              'nombreUsuario':nombreReceptor,
                              'uid': uidReceptor,
                            },
                            receptorId: uidReceptor,
                        ),
                    ),
                  );
                },
              );
            }
          );
        },
      ),
    );
  }
}
