import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_app/providers/data_provider.dart';
import 'package:rider_app/screens/home_screen.dart';
import 'package:rider_app/screens/login_screen.dart';
import 'package:rider_app/screens/search_screen.dart';
import 'package:rider_app/screens/signup_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DataProvider(),)
      ],
      child: MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Brand regular',
        ),
        debugShowCheckedModeBanner: false,
        title: 'Rider App',
        home: StreamBuilder(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, AsyncSnapshot<User?> snapshot) {
              if(snapshot.hasData && snapshot.data != null){
                return const HomeScreen();
              }
              else if(snapshot.connectionState == ConnectionState.waiting){
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              return const LoginScreen();
            },
        ),
        routes: {
          LoginScreen.idScreen : (context) => const LoginScreen(),
          SignupScreen.idScreen : (context) => const SignupScreen(),
          HomeScreen.idScreen : (context) => const HomeScreen(),
          SearchScreen.idScreen : (context) => const SearchScreen()
        },

      ),
    );
  }
}
