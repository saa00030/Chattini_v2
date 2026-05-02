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
                  return "Debe incluir mayúscula, minúscula, número y símbolo";
                }
                return null;
              },
            ),


            //Campo repetir contraseña
            const SizedBox(height: 20),
            TextFormField(
              controller: _repetirpasswordController,
              obscureText: !_passwordVisible,
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

              //Boton para volver atras
              TextButton(
                onPressed: () => Navigator.pop(context),
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

