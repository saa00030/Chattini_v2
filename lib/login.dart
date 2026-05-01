import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instachat_v2/pantallaChats.dart';
import 'package:instachat_v2/pantallaInicioVacia.dart';
import 'package:instachat_v2/registro.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKeys = GlobalKey<FormState>();
  bool _passwordVisible = false;

  // Estos controladores nos permiten extraer el texto de los campos
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFDAB5),
              Colors.white,
          ],
        ),
      ),
      child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child:Form(
          key: _formKeys,
          child: Center(
            child:SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Logo
              const Icon(Icons.chat_bubble_rounded,
                  size: 80,
                  color: Color(0xFFEAA64F)
              ),
              const SizedBox(height: 10),
                Text(
                "Chattini",
                style:TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEAA64F),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _emailController,
                decoration:  InputDecoration(
                  labelText: "Correo electrónico",
                  filled: true,
                  fillColor: Colors.white,
                  //Icono de email
                  prefixIcon: Icon(Icons.email,color: Color(0xFFEAA64F)),
                  border: OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(15),
                    borderSide:  BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color : Color(0xFFFFD9B3)),
                  ),
                ),
                validator: (value)=>(value == null || !value.contains('@'))?"Introduce un correro válido": null,
              ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: !_passwordVisible, // Para ocultar la contraseña
              decoration:  InputDecoration(
                labelText: "Contraseña",
                filled: true,
                fillColor:Colors.white,
                border: const OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock,color: Color(0xFFEAA64F)),
                suffix:IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Introduce una contraseña";
                }
                return null;
              },
            ),
          //Mensaje de resigtro
            TextButton(
              onPressed: () {
                // Acción al presionar, por ejemplo: navegar a la página de registro
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistroPagina()),
                );
              },
              child: Text(
                '¿No tienes cuenta? Registrate aquí',
                style:TextStyle(
                  color: const Color(0xFFEAA64F),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            //Debería recuperar la contraseña ????

            const SizedBox(height: 20),
            //Ingresar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAA64F),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {
                  print("Boton pulsado");
                  if (_formKeys.currentState!.validate()) {
                    print("Validacion correcta");
                    try {
                      await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                      );
                      if (mounted) {
                        print("Login en Firebase OK");
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Pantallainiciovacia()),
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      print("Error");
                      String mensajeError = "Ocurrió un error";
                      if (e.code == "user-not-found") {
                        mensajeError = "El usuario no existe";
                      } else if (e.code == "wrong-password") {
                        mensajeError = "Contraseña incorrecta";
                      } else if (e.code == "invalid-email") {
                        mensajeError = "El correo no es válido";
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(mensajeError))
                      );
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
      ),
      ),
      ),
    );

  }
}