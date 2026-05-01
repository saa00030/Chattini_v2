import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DialogoBuscarUsuario extends StatefulWidget {
  const DialogoBuscarUsuario({super.key});

  @override
  State<DialogoBuscarUsuario> createState() => _DialogoBuscarUsuarioState();
}

class _DialogoBuscarUsuarioState extends State<DialogoBuscarUsuario> {

  String _nombreBusqueda = "";
  final TextEditingController buscador = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chattini', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFEAA64F),
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
            TextField(
              controller: buscador,
              decoration: InputDecoration(
                labelText: 'Escribe el nombre de usuario...',
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value){
                setState(() {
                  _nombreBusqueda = value.trim().toLowerCase();
                });
              },
            ),
            Expanded(
              child:
              StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                  .collection('usuarios')
                    .where('busqueda',isGreaterThanOrEqualTo: _nombreBusqueda)
                    .where('busqueda',isLessThanOrEqualTo: '$_nombreBusqueda\uf8ff')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Error"));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  var usuarios = snapshot.data!.docs.where((doc) =>
                  doc['uid'] != FirebaseAuth.instance.currentUser!.uid
                  ).toList();

                  if (usuarios.isEmpty){
                    return const Center(child: Text("No se encontraron usuarios"));
                  }

                  return ListView.builder(
                    itemCount: usuarios.length,
                    itemBuilder: (context, index) {
                      var datos = usuarios[index].data() as Map<String, dynamic>;

                      //No poder buscarme a mi mismo
                      // (se puede cambiar si es que quiero que se yo el unico usuario al principio
                      //if (datos['uid'] == FirebaseAuth.instance.currentUser!.uid){
                      //return const SizedBox.shrink();
                      //}
                      //La foto que sale al lado del usuario al buscarlo
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
