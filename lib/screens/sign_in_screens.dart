import 'package:booklist/screens/home_screens.dart';
import 'package:booklist/screens/sign_up_screens.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';


class SignInScreens extends StatefulWidget {
  const SignInScreens({super.key});

  @override
  SignInScreensState createState() => SignInScreensState();
}

class SignInScreensState extends State<SignInScreens> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sign In',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 25),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 70,
                    backgroundImage: AssetImage('assets/radius_booklist.png'),
                  ),
                  const SizedBox(height: 90),
                  TextFormField(
                    controller: _emailController,
                    textCapitalization: TextCapitalization.none,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      // labelStyle: TextStyle(color: colorScheme.primary),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.person,
                        // color: colorScheme.primary,
                      ),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          !_isValidEmail(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      // labelStyle: TextStyle(color: colorScheme.primary),
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          );
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(),
                      )
                      : ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        // style: ElevatedButton.styleFrom(
                        //   backgroundColor: colorScheme.primary,
                        //   minimumSize: const Size(120, 45),
                        //   shape: RoundedRectangleBorder(
                        //     borderRadius: BorderRadius.circular(10.0),
                        //   ),
                        // ),
                        child: Text(
                          'Login',
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  const SizedBox(height: 20.0),
                  RichText(
                    text: TextSpan(
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 16.0,
                        color: colorScheme.error,
                      ),
                      children: [
                        const TextSpan(text: "Belum punya akun? "),
                        TextSpan(
                          text: "Daftar",
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          recognizer:
                              TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignUpScreens(),
                                    ),
                                  );
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreens()),
        );
      }
    } on FirebaseAuthException catch (error) {
      _showSnackBar(_getAuthErrorMessage(error.code));
    } catch (error) {
      _showSnackBar('An error occurred: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: colorScheme.error),
    );
  }

  bool _isValidEmail(String email) {
    const emailRegex = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
    return RegExp(emailRegex).hasMatch(email);
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-not-found':
        return 'No user found with that email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Login failed. Please try again.';
    }
  }
}
