import 'package:flutter/material.dart';

//Funcionara como pagina stless, el funcionamiento viene en pantallaChats. Aqui seria unicamente el diseño de la pagina
// Muestra cuando un usuario no tiene ningun chat empezado
class Pantallainiciovacia extends StatelessWidget {
  //Funcion que nos pasa la pantalla madre(ListaContactos), al guardarla podemos activarla cuando el usuario pulse el boton de buscar
  final VoidCallback onBuscar;

  const Pantallainiciovacia({super.key, required this.onBuscar});


  @override
  Widget build(BuildContext context) {

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, //Centra el contenido verticalmente
            children: [
              //Informacion para indicar que no tienes ningun chat
              const Icon(Icons.chat_bubble_outline, size: 100, color: Colors.grey),
              const SizedBox(height: 30),
              const Text('¡Qué silencio hay por aquí!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Busca a tus amigos para empezar a chatear.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 30),
              //Boton con icono para empezar la busqueda
              ElevatedButton.icon(
                onPressed: onBuscar,
                icon: const Icon(Icons.person_add),
                label: const Text('Buscar contactos'),
              ),
            ],
          ),
        ),
      );
  }

}
