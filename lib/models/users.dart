import 'package:firebase_database/firebase_database.dart';

class Users {
  String uid;
  String email;
  String phone;
  String username;

  Users(
      {required this.uid,
      required this.username,
      required this.email,
      required this.phone});

  static Users fromSnapshot(DataSnapshot snapshot) {
    Map<dynamic, dynamic> map = snapshot.value as Map<dynamic, dynamic>;
    return Users(
        uid: snapshot.key!,
        username: map['name'] ,
        email: map['email'],
        phone: map['phone']);
  }
}
