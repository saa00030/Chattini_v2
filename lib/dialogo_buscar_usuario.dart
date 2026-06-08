import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

//Clase de busqueda de usuarios
//Se implementa como StatefulWidget para mutar de forma reactiva los resultados
class DialogoBuscarUsuario extends StatefulWidget {
  const DialogoBuscarUsuario({super.key});

  @override
  State<DialogoBuscarUsuario> createState() => _DialogoBuscarUsuarioState();
}

class _DialogoBuscarUsuarioState extends State<DialogoBuscarUsuario> {
  //Estado local que almacena la busqueda
  String _nombreBusqueda = "";
  //Controlador del campo de texto para gestionar la entrada del buffer
  final TextEditingController buscador = TextEditingController();

  @override
  void dispose() {
    // Liberamos la memoria del controlador al cerrar la pantalla
    buscador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chattini', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFEAA64F), //Color de la app
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Encontrar usuarios',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              //Barra de busqueda (SearchBar)
              TextField(
              controller: buscador,
              decoration: InputDecoration(
                labelText: 'Escribe el nombre de usuario...',
                prefixIcon: const Icon(Icons.search),
              ),
              //Sincronizacion de estado en linea
              onChanged: (value){
                setState(() {
                  //Se aplica .trim() para limpiar espacios y .toLowerCase para convertir a minusculas
                  _nombreBusqueda = value.trim().toLowerCase();
                });
              },
            ),
            Expanded(
              child:
              StreamBuilder<QuerySnapshot>(
                //Realizamos la busqueda
                  stream: FirebaseFirestore.instance
                  .collection('usuarios')
                    .where('busqueda',isGreaterThanOrEqualTo: _nombreBusqueda)
                    .where('busqueda',isLessThanOrEqualTo: '$_nombreBusqueda\uf8ff')
                    .snapshots(), //Flujo continuo de datos en tiempo real (Stream)
                builder: (context, snapshot) {
                    //Mensaje en caso de error
                  if (snapshot.hasError) return const Center(child: Text("Error"));
                  //Simbolo de busqueda por si esta cargando
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  //Filtra los usuarios que le salen al usuario al buscar
                  var usuarios = snapshot.data!.docs.where((doc) =>
                  doc['uid'] != FirebaseAuth.instance.currentUser!.uid
                  ).toList();

                  //En caso de que no se encuentren usuarios
                  if (usuarios.isEmpty){
                    return const Center(child: Text("No se encontraron usuarios"));
                  }
                  //Resultados de la busqueda
                  return ListView.builder(
                    itemCount: usuarios.length,
                    itemBuilder: (context, index) {
                      var datos = usuarios[index].data() as Map<String, dynamic>;


                      return ListTile(
                        leading: CircleAvatar(
                          // Usamos el operador ?? para dar un valor por defecto si es null
                          child: Text((datos['nombreUsuario'] ?? 'U')[0].toUpperCase()),
                        ),
                        title: Text(datos['nombreUsuario'] ?? 'Usuario sin nombre'),
                        subtitle: Text(datos['correo'] ?? 'Sin correo'),
                        onTap: () {
                          //Para que lo que aparezca sea String no de errores
                          Navigator.pop(context,{
                            'nombreUsuario': (datos['nombreUsuario'] ??  'Usuario').toString(),
                            'uid': (datos['uid'] ?? usuarios[index].id).toString(),
                            'correo': (datos['correo'] ?? '' ).toString(),
                          });
                        }
                      );
                    },
                  );
                },
              )
            ),
            ],
          ),
        )
    ),
    );
  }
}
