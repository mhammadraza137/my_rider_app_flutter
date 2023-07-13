
import 'package:flutter/cupertino.dart';
import 'package:rider_app/models/address.dart';

class DataProvider extends ChangeNotifier{
  Address? userPickUpAddress, dropOffAddress;

  void setUserPickUpAddress(Address pickUpAddress){
    userPickUpAddress = pickUpAddress;
    notifyListeners();
  }
  void setDropOffAddress(Address dropAddress){
    dropOffAddress = dropAddress;
    notifyListeners();
  }
}