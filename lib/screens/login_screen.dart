import 'package:flutter/material.dart';
import 'package:rider_app/methods/auth_methods.dart';
import 'package:rider_app/screens/signup_screen.dart';
import 'package:rider_app/utils/colors.dart';
import 'package:rider_app/utils/dimensions.dart';
import 'package:rider_app/widgets/auth_buttons.dart';
import 'package:rider_app/widgets/custom_text_form_field.dart';
import 'package:rider_app/widgets/progress_dialog.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const String idScreen = 'loginScreen';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formField = GlobalKey<FormState>();
  bool passToggle = true;
  final RegExp emailRegExp = RegExp(r"""
^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+""");
  final TextEditingController _emailTextEditingController =
      TextEditingController();
  final TextEditingController _passwordTextEditingController =
      TextEditingController();
  String status = '';

  @override
  void dispose() {
    super.dispose();
    _emailTextEditingController.dispose();
    _passwordTextEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screenBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(
                    image: const AssetImage('images/logo.png'),
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: MediaQuery.of(context).size.height * 0.3,
                  ),
                ],
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.01,
              ),
              Text(
                'Login as Rider',
                style: TextStyle(
                    fontSize:
                        MediaQuery.of(context).size.width * headingOneSize,
                    fontFamily: 'Brand bold'),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Form(
                  key: _formField,
                  child: Column(
                    children: [
                      CustomTextFormField(
                        textEditingController: _emailTextEditingController,
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        textInputType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validate: (value) {
                          if (value!.isEmpty) {
                            return 'Email email';
                          }
                          if (!emailRegExp.hasMatch(value)) {
                            return 'Enter valid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      CustomTextFormField(
                        textEditingController: _passwordTextEditingController,
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        textInputType: TextInputType.text,
                        obscureText: passToggle,
                        suffixIcon: InkWell(
                          onTap: () {
                            setState(() {
                              passToggle = !passToggle;
                            });
                          },
                          child: Icon(passToggle
                              ? Icons.visibility
                              : Icons.visibility_off),
                        ),
                        textInputAction: TextInputAction.done,
                        validate: (value) {
                          if (value!.isEmpty) {
                            return 'Enter password';
                          } else if (value.trim().length < 6) {
                            return 'Password length should not be less than 6 characters ';
                          }
                          return null;
                        },
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02,
                      ),
                      AuthButton(
                        onPressed: () async {
                          if (_formField.currentState!.validate()) {
                            showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return const ProgressDialog(dialogText: 'Logging in please wait...');
                                },);
                             status = await AuthMethods().loginUser(
                                email: _emailTextEditingController.text.trim(),
                                password:
                                    _passwordTextEditingController.text.trim());
                             if(status == 'success')
                               {
                                 _emailTextEditingController.clear();
                                 _passwordTextEditingController.clear();
                                 // ignore: use_build_context_synchronously
                                 Navigator.pushNamedAndRemoveUntil(context, HomeScreen.idScreen, (route) => false);
                               }
                             else{
                               // ignore: use_build_context_synchronously
                               Navigator.pop(context);
                               // ignore: use_build_context_synchronously
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status)));
                             }
                          }
                        },
                        buttonTitle: 'Log in',
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, SignupScreen.idScreen, (route) => false);
                  },
                  child: const Text(
                    'Do not have an account? Register here.',
                    style: TextStyle(color: authTextButtonColor),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
