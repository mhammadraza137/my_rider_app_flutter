
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:rider_app/models/address.dart';
import 'package:rider_app/models/users.dart';
import 'package:rider_app/providers/data_provider.dart';

class DatabaseMethods{
  static Future<Users?> getCurrentUserInfo() async{
    Users? users;
    User currentUser = FirebaseAuth.instance.currentUser!;
    String uid = currentUser.uid;
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref().child('users').child(uid);
    DataSnapshot dataSnapshot = await databaseReference.get();
    if(dataSnapshot.value != null){
      users = Users.fromSnapshot(dataSnapshot);
    }
    return users;
  }
  static saveRideRequest(BuildContext context, Users user) async{
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref().child('ride requests').child(user.uid);
    Address? pickUp = Provider.of<DataProvider>(context, listen: false).userPickUpAddress;
    Address? dropOff = Provider.of<DataProvider>(context, listen: false).dropOffAddress;

    Map pickUpLocMap = {
      'latitude' : pickUp!.latitude,
      'longitude' : pickUp!.longitude
    };
    Map dropOffLocMap = {
      'latitude' : dropOff!.latitude,
      'longitude' : dropOff!.longitude
    };
    Map rideInfoMap = {
      'rider_uid' : user.uid,
      'driver_id' : 'waiting',
      'payment_method' : 'cash',
      'pickup' : pickUpLocMap,
      'drop-off' : dropOffLocMap,
      'created_date' : DateTime.now().toString(),
      'rider_name' : user.username,
      'rider_phone' : user.phone,
      'pickup_address' : pickUp.placeName,
      'drop_off_address' : dropOff.placeName

    };
    await databaseReference.set(rideInfoMap);
  }
  static removeRideRequest(Users user){
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref().child('ride requests').child(user.uid);
    databaseReference.remove();
  }
}