import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pantallaChats.dart';
import 'pantallaInicioVacia.dart';

class RegistroPagina extends StatefulWidget{
  const RegistroPagina({super.key});

  @override
  State<RegistroPagina> createState() => _RegistroPagina();

}
class _RegistroPagina extends State<RegistroPagina>{
  final _formKeys = GlobalKey<FormState>();
  bool _passwordVisible = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repetirpasswordController = TextEditingController();
  final TextEditingController _nombreUsuarioController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bienvenido a Instachat"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKeys,
        child:SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Registrarte",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _nombreUsuarioController,
              decoration: const InputDecoration(
                labelText: "Nombre de usuario",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline)
              ),
              validator: (value){
                if (value == null || value.isEmpty)
                  return "Escribe un nombre de usuario";
                if (value.length < 4 || value.length > 15)
                  return "Debe tener entre 4 y 15 caracteres";
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Correo electrónico",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value){
                if(value == null || !value.contains("@")){
                  return "El correo debe contener @";
                }
                return null;
                },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: !_passwordVisible, // Para ocultar la contraseña
              decoration: InputDecoration(
                labelText: "Contraseña",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon:IconButton(
                  icon: _passwordVisible ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return "Escribe una constraseña";
                if (value.length < 8 || value.length > 20)
                  return "Debe tener entre 8 y 20 caracteres";
                bool tieneFormato = RegExp(
                    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]')
                    .hasMatch(value);
                if (!tieneFormato) {
                  return "Debe incluir mayúscula, minúscula, número y símbolo";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _repetirpasswordController,
              obscureText: !_passwordVisible,
              // Para ocultar la contraseña
              decoration: InputDecoration(
                labelText: "Repetir contraseña",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: _passwordVisible ? const Icon(Icons.visibility) : const Icon(Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return "Escribe una constraseña";
                if (value.length < 8 || value.length > 20)
                  return "Debe tener entre 8 y 20 caracteres";
                bool tieneFormato = RegExp(
                    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]')
                    .hasMatch(value);
                if (!tieneFormato) {
                  return "Debe incluir mayúscula, minúscula, número y símbolo";
                }
                return null;
              },

            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  if (_formKeys.currentState!.validate()) {
                    try {
                      UserCredential credencial = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                      );

                      await FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(credencial.user!.uid)
                          .set({
                        'nombreUsuario': _nombreUsuarioController.text.trim(),
                        'correo': _emailController.text.trim(),
                        'uid': credencial.user!.uid,
                        'fechaRegistro': DateTime.now(),
                        'busqueda': _nombreUsuarioController.text.trim().toLowerCase(),
                      });

                      if (mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Pantallainiciovacia()),
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      // tu código de errores ya existente
                    }
                  }
                },
                child: const Text("Ingresar",style: TextStyle(fontSize: 20),),
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}

