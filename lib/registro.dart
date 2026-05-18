import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:instachat_v2/modelos/firebase_service.dart';
import 'pantallaChats.dart';
import 'pantallaInicioVacia.dart';
import 'main.dart';

class RegistroPagina extends StatefulWidget{
  const RegistroPagina({super.key});

  @override
  State<RegistroPagina> createState() => _RegistroPagina();

}
class _RegistroPagina extends State<RegistroPagina>{
  final _formKeys = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _cargando = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repetirpasswordController = TextEditingController();
  final TextEditingController _nombreUsuarioController = TextEditingController();

  final FirebaseService autenticationService = FirebaseService();

  @override
  void dispose() {
    // Liberamos memoria de los controladores al destruir el widget
    _emailController.dispose();
    _passwordController.dispose();
    _repetirpasswordController.dispose();
    _nombreUsuarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Flecha para volver al login
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFEAA64F)),
          onPressed: _cargando ? null : () => Navigator.pop(context),
        ),
      ),
      //Para que el cuerpo se vea debajo del AppBar transparente
      extendBodyBehindAppBar: true,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end:  Alignment.bottomCenter,
            colors: [
              Color(0xFFFFDAB5),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child:Padding(
          padding: const EdgeInsets.all(25.0),
          child: Form(
            key: _formKeys,
          child:SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              const Text(
                "Registrarte",
                style: TextStyle(fontSize: 24,
                    color: Color(0xFFEAA64F),
                    fontWeight: FontWeight.bold),
              ),


            const SizedBox(height: 30),
            //Nombre usuario
            TextFormField(
              controller: _nombreUsuarioController,
              enabled: !_cargando,
              decoration: InputDecoration(
                labelText: "Nombre de usuario",
                filled: true,
                fillColor: Colors.white,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person_outline),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFFFFD9B3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15), // <--- CLAVE: Mantener el redondeo aquí
                  borderSide: const BorderSide(
                    color: Color(0xFFEAA64F), // Color naranja al escribir
                    width: 1.5,
                  ),
                ),

                // 3. BORDE DE ERROR (Por si la validación falla)
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),

                // 4. BORDE DE ERROR CUANDO ESTÁS ESCRIBIENDO
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
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
            //Email
            TextFormField(
              controller: _emailController,
              enabled: !_cargando,
              decoration: InputDecoration(
                labelText: "Correo electrónico",
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.email),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15), // Redondeado
                  borderSide: const BorderSide(color: Color(0xFFFFD9B3)), // Borde color crema (casi invisible)
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15), // <--- CLAVE: Mantener el redondeo aquí
                  borderSide: const BorderSide(
                    color: Color(0xFFEAA64F), // Color naranja al escribir
                    width: 1.5,
                  ),
                ),

                // 3. BORDE DE ERROR (Por si la validación falla)
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),

                // 4. BORDE DE ERROR CUANDO ESTÁS ESCRIBIENDO
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
              ),
              validator: (value){
                if(value == null || !value.contains("@")){
                  return "El correo debe contener @";
                }
                return null;
                },
            ),

            //Contraseña
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: !_passwordVisible, // Para ocultar la contraseña
              enabled: !_cargando,
              decoration: InputDecoration(
                labelText: "Contraseña",
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.lock),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15), // Redondeado
                  borderSide: const BorderSide(color: Color(0xFFFFD9B3)), // Borde color crema (casi invisible)
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15), // <--- CLAVE: Mantener el redondeo aquí
                  borderSide: const BorderSide(
                    color: Color(0xFFEAA64F), // Color naranja al escribir
                    width: 1.5,
                  ),
                ),

                // 3. BORDE DE ERROR (Por si la validación falla)
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),

                // 4. BORDE DE ERROR CUANDO ESTÁS ESCRIBIENDO
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
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
                  return "La contraseña debe incluir:\n• Una mayúscula y una minúscula\n• Un número\n• Un símbolo (@\$!%*?&)";
                }
                return null;
              },
            ),


            //Campo repetir contraseña
            const SizedBox(height: 20),
            TextFormField(
              controller: _repetirpasswordController,
              obscureText: !_passwordVisible,
              enabled: !_cargando,
              // Para ocultar la contraseña
              decoration: InputDecoration(
                labelText: "Repetir contraseña",
                filled: true,
                fillColor: Colors.white,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15), // Redondeado
                  borderSide: const BorderSide(color: Color(0xFFFFD9B3)), // Borde color crema (casi invisible)
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15), // <--- CLAVE: Mantener el redondeo aquí
                  borderSide: const BorderSide(
                    color: Color(0xFFEAA64F), // Color naranja al escribir
                    width: 1.5,
                  ),
                ),

                // 3. BORDE DE ERROR (Por si la validación falla)
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),

                // 4. BORDE DE ERROR CUANDO ESTÁS ESCRIBIENDO
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
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
                if (value != _passwordController.text) {
                  return "Las contraseñas no coinciden";
                }
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



            //Boton registro
            const SizedBox(height: 30),
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
                onPressed: _cargando
                  ? null
                  : () async {
                  if (_formKeys.currentState!.validate()) {

                    setState(() {
                      _cargando = true;
                    });
                    try {
                      await autenticationService.registrarUser(
                        nombreUser: _nombreUsuarioController.text,
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                      );

                      if (!mounted) return;

                      //Volvemos a la pantalla raiz, AuthWrapper se encarga del resto
                      Navigator.pop(context);

                    } on FirebaseAuthException catch (e) {

                      setState(() {
                        _cargando = false;
                      });

                      String mensajesError = "Error al registrar";
                      if (e.code == "email-already-in-use") {
                        mensajesError = "Este correo ya está registrado";
                      } else if (e.code == "weak-password") {
                        mensajesError = "Contraseña  debil";
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(mensajesError))
                      );
                    }
                  }
                },
                child: _cargando
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
                    : const Text("Registrarse", style: TextStyle(fontSize: 20)),
              ),
            ),

              //Boton para volver atras
              TextButton(
                onPressed: _cargando ? null : () => Navigator.pop(context), // Bloquea si está cargando
                child: const Text(
                  '¿Ya tienes cuenta? Inicia sesión',
                  style: TextStyle(
                    color: Color(0xFFEAA64F),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
        ),
      ),
        ),
      ),
    );
  }
}

