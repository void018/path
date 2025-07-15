import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 229, 243, 255),
      body: Column(
        children: [
/*


Title text


*/
          Padding(
            padding: EdgeInsets.fromLTRB(10, 150, 0, 19),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'Login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 59, 115),
                  fontSize: 32,
                  fontFamily: 'inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
/*


Subtitle text


*/
          Container(
            width: 300,
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 0, 10),
              child: Text(
                'The perfect companion for your public transportation trips!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 59, 115),
                  fontSize: 18,
                  fontFamily: 'inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
/*


Email text field


*/

          Container(
            child: Center(
              child: TextField(
                decoration: InputDecoration(
                  suffixIcon: Icon(Icons.person),
                  labelText: 'email address',
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      width: 1,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
/*


password text field


*/

          SizedBox(height: 10),
          //
          //password TextField

          Container(
            child: Center(
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  suffixIcon: Icon(Icons.lock),
                  labelText: 'password',
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      width: 1,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
