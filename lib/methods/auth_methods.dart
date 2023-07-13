import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference dataBaseRef = FirebaseDatabase.instance.ref();
  String status = 'Some error occurred';

  Future<String> signupUser(
      {required String username,
      required String email,
      required String phone,
      required String password}) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await dataBaseRef
          .child('users')
          .child(credential.user!.uid)
          .set({'name': username, 'email': email, 'phone': phone});
      status = 'success';
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        status = 'Email already exists';
      } else {
        status = error.code;
      }
    } catch (e) {
      status = e.toString();
    }
    return status;
  }

  Future<String> loginUser(
      {required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      status = 'success';
    } on FirebaseAuthException catch (error) {
      if(error.code == 'user-not-found'){
        status = 'User not found!';
      }
      else if(error.code == 'wrong-password'){
        status = 'Password entered is not correct. Try again.';
      }
      else if(error.code == 'too-many-requests'){
        status = 'Too many requests. Try again later.';
      }
      else{
        status = error.code;
      }
    } catch (e) {
      status = e.toString();
    }
    return status;
  }
  Future<void> logOut() async{
    await _auth.signOut();
  }
}
