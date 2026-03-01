import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String error = '';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gastos Casa - Login'), elevation: 0),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 50.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Iniciar Sesión',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Correo',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Ingrese un correo' : null,
                onChanged: (val) {
                  setState(() => email = val);
                },
              ),
              const SizedBox(height: 20.0),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (val) => val!.length < 6
                    ? 'La contraseña debe tener más de 6 caracteres'
                    : null,
                onChanged: (val) {
                  setState(() => password = val);
                },
              ),
              const SizedBox(height: 20.0),
              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Entrar'),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => loading = true);
                          dynamic result = await _auth
                              .signInWithEmailAndPassword(email, password);
                          if (result == null) {
                            setState(() {
                              error =
                                  'No se pudo iniciar sesión con esas credenciales';
                              loading = false;
                            });
                          }
                        }
                      },
                    ),
              const SizedBox(height: 12.0),
              Text(
                error,
                style: const TextStyle(color: Colors.red, fontSize: 14.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
