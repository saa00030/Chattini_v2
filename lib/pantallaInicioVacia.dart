import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'conversacion.dart';
import 'dialogo_buscar_usuario.dart';
import 'pantallaChats.dart';

class Pantallainiciovacia extends StatefulWidget {
  const Pantallainiciovacia({super.key});

  @override
  State<Pantallainiciovacia> createState() => _pantalla_inicio_vaciaState();
}

class _pantalla_inicio_vaciaState extends State<Pantallainiciovacia> {

  List<Map<String,String>> misChats = [];

  void _mostrarBusqueda() async {
    final resultado = await showDialog<Map<String,String>>(
      context: context,
      builder: (context) => const DialogoBuscarUsuario(),
    );

    if(resultado != null){
      setState(() {
        misChats.add(resultado);
      });
      //Si al buscarlo te lleve directamente al chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PantallaConversacion(
            receptor: {
              'nombreUsuario': resultado['nombreUsuario']!,
              'uid': resultado['uid']!,
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
        title: const Text('Chattini', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFEAA64F),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () => _mostrarBusqueda(),
          ),
        ],
      ),

      body: misChats.isEmpty
            ? _buildListaVacia()
            : _buildListaContactosActivo(),
    );
  }
  Widget _buildListaContactosActivo(){
    return ListView.builder(
      itemCount: misChats.length,
      itemBuilder: (context,index){
        final contacto = misChats[index];

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFFFD9B3),
            child: Text(contacto['nombreUsuario']![0].toUpperCase()),
          ),
          title: Text(contacto['nombreUsuario']!),
          subtitle: const Text("Toca para continuar la conversación"),
          onTap: (){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PantallaConversacion(
                  receptor: {
                    'nombreUsuario': contacto['nombreUsuario']!,
                    'uid': contacto['uid']!,
                  },
                  receptorId: contacto['uid']!,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListaVacia() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 100, color: Colors.grey),
            const SizedBox(height: 30),
            const Text('¡Qué silencio hay por aquí!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Busca a tus amigos para empezar a chatear.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _mostrarBusqueda,
              icon: const Icon(Icons.person_add),
              label: const Text('Buscar contactos'),
            ),
          ],
        ),
      ),
    );
  }
}


