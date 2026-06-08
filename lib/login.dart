import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:instachat_v2/modelos/firebase_service.dart';

import 'package:instachat_v2/registro.dart';

//Pantalla de acceso a la aplicacion(Login)
//La definimos como StatefulWidget ya que gestiona estados dinamicos
//como visibilidad de contraseña, estados de carga, etc
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //Clave global que identifica el formulario y valida los campos de entrada antes de enviar datos
  final _formKeys = GlobalKey<FormState>();
  //Estados de la interfaz de usuario
  bool _passwordVisible = false;
  bool _cargando = false;

  // Estos controladores nos permiten extraer y manipular el texto de los campos
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  //llamada a la instanciaFirebase
  final FirebaseService autenticationService = FirebaseService();

  @override
  void dispose() {
    // Liberamos la memoria de los controladores al destruir la pantalla o navegar fuera de ella
    //previniendo fugas de memoria
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Container(
        //Detalles visuales, añadiendole un degradado a la paleta de colores para un mejor aspecto
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
      //Mediante SafeArea, evitamos colisiones con elementos de hardware de cada telefono(barra de estado,..)
      child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child:Form(
          key: _formKeys, //La clave a emplear
          child: Center(
            //Previene errores de desbordamiento en caso de que el usuario gire la pantalla horizontalmente
            child:SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Insertamos el logo de nuestra app
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/iconochattinit.png',
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
                Text(
                "Chattini",
                style:TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEAA64F), //Color naranja de la aplicacion
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 30),

              //Ahora vamos con los distintos campos de entrada, empezamos con el correo electronico
              TextFormField(
                controller: _emailController,
                //Enabled: Deshabilita este campo mientras procesa una red asincrona. Esto sirve por ejemplo si el usuario
                //presiona 2 veces el campo, no se realicen 2 llamadas y se colapse la base de datos, con 1 llamada es suficiente
                enabled: !_cargando,
                decoration:  InputDecoration(
                  labelText: "Correo electrónico",
                  filled: true,
                  fillColor: Colors.white,
                  //Icono de email
                  prefixIcon: Icon(Icons.email,color: Color(0xFFEAA64F)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  //Detalles estéticos
                  border: OutlineInputBorder(
                    borderRadius: new BorderRadius.circular(15),
                    borderSide:  BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color : Color(0xFFFFD9B3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(
                      color: Color(0xFFEAA64F), // Color naranja al escribir
                      width: 1.5,
                    ),
                  ),

                  // 3. Borde de error (Por si la validación falla)
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),

                  // 4. Borde de error cuando estas escribiendo
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                  ),
                ),
                //Valida la presencia del caracter '@'
                validator: (value)=>(value == null || !value.contains('@'))?"Introduce un correo válido": null,
              ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: !_passwordVisible, // Para ocultar la contraseña
              enabled: !_cargando, //Lo explicado anteriormente
              decoration:  InputDecoration(
                labelText: "Contraseña",
                filled: true,
                fillColor:Colors.white,
                prefixIcon: Icon(Icons.lock,color: Color(0xFFEAA64F)),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                // SuffixIcon: Permite alternar la visibilidad de la contraseña
                suffixIcon: IconButton(
                  icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
                //Igual que antes, detalles visuales
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFFFFD9B3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color(0xFFEAA64F), // Color naranja al escribir
                    width: 1.5,
                  ),
                ),

                // 3. Borde de error (Por si la validación falla)
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),

                // 4. Borde de error cuando estas escribiendo
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
              ),
              //Validor de campo obligatorio vacio
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Introduce una contraseña";
                }
                return null;
              },
            ),
            //Boton en caso de que no te hayas registrado
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


            const SizedBox(height: 20),
            //Boton de ingresar
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
                  //Si la variable cargando es true, asigna null a onPressed. Esto desahibilita
                  // el boton por completo, impidiendo que un usuario impaciente presione multiples veces el boton
                  onPressed: _cargando
                      ? null // Deshabilita el botón si ya está cargando
                      : () async {
                    if (_formKeys.currentState!.validate()) {
                      setState(() {
                        _cargando = true; //Activa el simbolo de espera
                      });
                      try {
                        // trim: orden para enviar las credenciales limpias, sin espacios ni nada que se pueda colar
                        await autenticationService.iniciarSesion(
                          _emailController.text.trim(),
                          _passwordController.text,
                        );

                        // AuthWrapper detecta la sesión y cambia la pantalla automáticamente.

                      } on FirebaseAuthException catch (e) {
                        setState(() {
                          _cargando = false;
                        });

                        String mensajeError = "Ocurrió un error";
                        // Firebase maneja códigos ligeramente distintos para login (invalid-credential abarca ambos a veces)
                        if (e.code == "user-not-found" || e.code == "invalid-credential") {
                          mensajeError = "Credenciales incorrectas o el usuario no existe";
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
                child: const Text("Iniciar Sesión",style: TextStyle(fontSize: 20),),
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