import 'package:flutter/material.dart';
import 'package:rider_app/methods/auth_methods.dart';
import 'package:rider_app/screens/home_screen.dart';
import 'package:rider_app/screens/login_screen.dart';
import 'package:rider_app/utils/colors.dart';
import 'package:rider_app/widgets/auth_buttons.dart';
import 'package:rider_app/widgets/custom_text_form_field.dart';
import 'package:rider_app/widgets/progress_dialog.dart';

import '../utils/dimensions.dart';

class SignupScreen extends StatefulWidget {
  static const String idScreen = 'signupScreen';
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formState = GlobalKey<FormState>();
  bool passToggle = true;
  final RegExp emailRegExp = RegExp(r"""
^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+""");
  final TextEditingController _usernameTextEditingController =
      TextEditingController();
  final TextEditingController _emailTextEditingController =
      TextEditingController();
  final TextEditingController _passwordTextEditingController =
      TextEditingController();
  final TextEditingController _phoneTextEditingController =
      TextEditingController();
  String status = '';

  @override
  void dispose() {
    super.dispose();
    _usernameTextEditingController.dispose();
    _emailTextEditingController.dispose();
    _passwordTextEditingController.dispose();
    _phoneTextEditingController.dispose();
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
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Image(
                        image: const AssetImage('images/logo.png'),
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: MediaQuery.of(context).size.height * 0.3,
                      )
                    ]),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    Text(
                      'Register as user',
                      style: TextStyle(
                          fontSize:
                          MediaQuery.of(context).size.width * headingOneSize,
                          fontFamily: 'Brand bold'),
                      textAlign: TextAlign.center,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: Form(
                          key: _formState,
                          child: Column(
                            children: [
                              CustomTextFormField(
                                  labelText: 'Username',
                                  hintText: 'Enter your user name',
                                  textInputType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                  validate: (value) {
                                    if (value!.isEmpty) {
                                      return 'Enter username';
                                    } else if (value.length < 4) {
                                      return 'Username should be at least 4 characters';
                                    }
                                    return null;
                                  },
                                  textEditingController:
                                  _usernameTextEditingController),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.02),
                              CustomTextFormField(
                                  labelText: 'Email',
                                  hintText: 'Enter your email',
                                  textInputType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validate: (value) {
                                    if (value!.isEmpty) {
                                      return 'Enter email';
                                    } else if (!emailRegExp.hasMatch(value)) {
                                      return 'Enter valid email';
                                    }
                                    return null;
                                  },
                                  textEditingController: _emailTextEditingController),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.02),
                              CustomTextFormField(
                                  labelText: 'Phone',
                                  hintText: 'Enter your phone number',
                                  textInputType: TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  validate: (value) {
                                    if(value!.isEmpty){
                                      return 'Enter phone number';
                                    }
                                    else if (value.trim().length < 11) {
                                      return 'Format phone number as 03001123456';
                                    }
                                    return null;
                                  },
                                  textEditingController: _phoneTextEditingController),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.02),
                              CustomTextFormField(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                textInputType: TextInputType.text,
                                textInputAction: TextInputAction.done,
                                validate: (value) {
                                  if (value!.isEmpty) {
                                    return 'Enter your password';
                                  } else if (value.trim().length < 6) {
                                    return 'Password should be at least 6 characters';
                                  }
                                  return null;
                                },
                                textEditingController: _passwordTextEditingController,
                                obscureText: passToggle,
                                suffixIcon: InkWell(
                                    onTap: () {
                                      setState(() {
                                        passToggle = !passToggle;
                                      });
                                    },
                                    child: Icon(passToggle
                                        ? Icons.visibility
                                        : Icons.visibility_off)),
                              ),
                              SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.02),
                              AuthButton(
                                  onPressed: () async {
                                    if (_formState.currentState!.validate()) {
                                      showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) {
                                            return const ProgressDialog(
                                                dialogText: 'Signing up please wait...');
                                          },);
                                      status = await AuthMethods().signupUser(
                                          username: _usernameTextEditingController
                                              .text
                                              .trim(),
                                          email:
                                          _emailTextEditingController.text.trim(),
                                          phone:
                                          _phoneTextEditingController.text.trim(),
                                          password: _passwordTextEditingController
                                              .text
                                              .trim());

                                      if(status == 'success'){
                                        _usernameTextEditingController.clear();
                                        _emailTextEditingController.clear();
                                        _phoneTextEditingController.clear();
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
                                  buttonTitle: 'Sign up')
                            ],
                          )),
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                              context, LoginScreen.idScreen, (route) => false);
                        },
                        child: const Text(
                          'Already have an account? Login here.',
                          style: TextStyle(color: authTextButtonColor),
                        ))
                  ],
                ),
              ),
            ),
          );

  }
}
