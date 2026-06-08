import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:instachat_v2/conversacion.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dialogo_buscar_usuario.dart';
import 'pantallaInicioVacia.dart';

//Pantalla de los chats activos
class ListaContactos extends StatefulWidget {
  const ListaContactos({super.key});

  @override
  State<ListaContactos> createState() => _ListaContactosState();
}

class _ListaContactosState extends State<ListaContactos> {
  //Id del usuario extraido de Firebase
  final String miUid = FirebaseAuth.instance.currentUser!.uid;

  //Funcion que busca los usuarios con los que hemos chatteado
  void _mostrarBusqueda() async {

    final resultado = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (context) => const DialogoBuscarUsuario()),
    );

    //Si el usuario cancelo la busqueda, aborta la operacion
    if (resultado != null){

      // el StreamBuilder detectara el cambio en Firebase
      if (!mounted) return;

      //Transfiere el control de ejecucion a la pantalla de chat especifico
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PantallaConversacion(
                receptor: {
                  'nombreUsuario': resultado['nombreUsuario']!,
                  'uid': resultado['uid'],
                },
            receptorId: resultado['uid']!,
            ),
        ),
      );
    }

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chattini', style: TextStyle(fontWeight: FontWeight.normal)),
        centerTitle: true,
        backgroundColor: const Color(0xFFEAA64F),  //Color de la App
        actions: [
          //Acciones de busqueda
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: (){
              _mostrarBusqueda();
            },
          ),
          //Boton de cerrar sesion
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white,),
            tooltip: 'Cerrar sesion',
            onPressed: () async{
              bool? confirmar = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Cerrar Sesion"),
                  content: const Text("¿Quieres salir de Chattini?"),
                  actions: [
                    TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Salir", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                )
              );
              //Si efectivamente quiere cerrar sesion, se lo hacemos saber a la funcion AuthWrapper implementada en Main
              if (confirmar == true){
                await FirebaseAuth.instance.signOut();
                // El AuthWrapper detectará el cambio y te manda al Login solo.
              }
            },
          )
        ],
      ),
      // Primero obtenemos nuestro documento para leer la lista de IDs
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(miUid).snapshots(),
        builder: (context, userSnapshot) {
          //En caso de que haya fallos de red
          if (userSnapshot.hasError) {
            return const Center(child: Text('Error de conexión'));
          }
          //Mientras se resuelve el problema de red, mostramos un icono de carga
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Extraemos la lista de IDs con los que hemos hablado, y si no ha sido creada la creamos
          List<dynamic> misIds = userSnapshot.data?.get('mis_chats') ?? [];

          //Si no hay chats, le pasamos pantallaInicioVacia
          if (misIds.isEmpty) {
            return Pantallainiciovacia(onBuscar: _mostrarBusqueda); //Le pasamos la funcion que tendriamos que usar para la busqueda
          }

          // 2. Con los IDs obtenidos, lanzamos el StreamBuilder para ver SOLO esos usuarios
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('usuarios')
                .where(FieldPath.documentId, whereIn: misIds)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Error al cargar contactos'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var docs = snapshot.data!.docs;
              //Se muestran los usuarios
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> datos = docs[index].data() as Map<String, dynamic>;
                  String nombreReceptor = datos['nombreUsuario'] ?? 'Usuario sin nombre';
                  String uidReceptor = docs[index].id;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFFD9B3),
                      child: const Icon(Icons.person, color: Color(0xFFE7A247)),
                    ),
                    title: Text(
                      nombreReceptor,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text("Toca para chatear"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      //Si seleccionas a un usuario, te manda a la pantalla de conversacion con dicha persona
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PantallaConversacion(
                            receptor: {
                              'nombreUsuario': nombreReceptor,
                              'uid': uidReceptor,
                            },
                            receptorId: uidReceptor,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}