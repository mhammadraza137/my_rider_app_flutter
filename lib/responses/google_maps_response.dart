import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_app/models/address.dart';
import 'package:rider_app/models/direction_details.dart';
import 'package:rider_app/providers/data_provider.dart';
import 'package:rider_app/responses/response_requests.dart';
import 'package:rider_app/utils/api_keys.dart';
import 'package:rider_app/widgets/progress_dialog.dart';

import '../models/place_predictions.dart';

class GoogleMapsResponse {
  static Future<String> searchCoordinateAddress(Position position, BuildContext context) async {
    String placeAddress = '';
    String st1, st2, st3, st4;
    String url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapAPIKey";
    var response = await ResponseRequest().getRequest(url);
    // ignore: unrelated_type_equality_checks
    if (response != 'Failed') {
      // placeAddress = response["results"][0]["formatted_address"];


      if((response['results'][0]['address_components'] as List).length > 6){
        st1 = response['results'][0]['address_components'][0]['long_name'];
        st2 = response['results'][0]['address_components'][1]['long_name'];
        st3 = response['results'][0]['address_components'][5]['long_name'];
        st4 = response['results'][0]['address_components'][6]['long_name'];
        placeAddress = '$st1, $st2, $st3, $st4';
      }
      else{
        st1 = response['results'][0]['address_components'][0]['long_name'];
        st2 = response['results'][0]['address_components'][1]['long_name'];
        st3 = response['results'][0]['address_components'][5]['long_name'];
        placeAddress = '$st1, $st2, $st3';
      }

      Address userPickUpAddress = Address();
      userPickUpAddress.placeName = placeAddress;
      userPickUpAddress.latitude = position.latitude;
      userPickUpAddress.longitude = position.longitude;

      // ignore: use_build_context_synchronously
      Provider.of<DataProvider>(context, listen: false).setUserPickUpAddress(userPickUpAddress);
    }
    return placeAddress;
  }
  static Future<List<PlacePredictions>> findPlace(String placeName) async{
    List<PlacePredictions> placePredictionsList = [];
    if(placeName.length > 1){
      String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&types=geocode&key=$mapAPIKey&components=country:pk";
      var response = await ResponseRequest().getRequest(url);
      if(response == 'Failed'){
        print('response failed');
      }
      else if(response['status'] == 'OK'){
        var placePredictions = response['predictions'];
        if((placePredictions as List).isNotEmpty){
          print('predddd : $placePredictions');
          List<PlacePredictions> placeList = (placePredictions).map((e) => PlacePredictions.fromJson(e)).toList();
          placePredictionsList = placeList;
        }
      }
    }
    return placePredictionsList;
  }

  static getPlaceAddressDetails(String placeId, BuildContext context) async{
    showDialog(
        context: context,
        builder: (context) {
          return const ProgressDialog(dialogText: 'Setting drop off, please wait...');
        },);
    String url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapAPIKey";
    var response = await ResponseRequest().getRequest(url);
    // ignore: use_build_context_synchronously
    Navigator.pop(context);
    if(response == 'Failed'){
      return;
    }
    if(response['status'] == 'OK'){
      Address address = Address();
      address.placeName = response['result']['name'];
      address.latitude = response['result']['geometry']['location']['lat'];
      address.longitude = response['result']['geometry']['location']['lng'];
      address.placeId = placeId;

      // ignore: use_build_context_synchronously
      Provider.of<DataProvider>(context, listen: false).setDropOffAddress(address);
      // ignore: use_build_context_synchronously
      Navigator.pop(context, 'directionReceived');
      print('drop off location is : ${address.placeName}');
    }
  }
  static Future<DirectionDetails> obtainPlaceDirectionDetails(LatLng initialPosition, LatLng finalPosition) async{
    DirectionDetails directionDetails = DirectionDetails();
    String url = "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$mapAPIKey";
    var response = await ResponseRequest().getRequest(url);
    if(response == 'Failed'){
    }
    if(response['status'] == 'OK'){
      directionDetails.encodedPoints = response['routes'][0]['overview_polyline']['points'];
      directionDetails.distanceText = response['routes'][0]['legs'][0]['distance']['text'];
      directionDetails.distanceValue = response['routes'][0]['legs'][0]['distance']['value'];
      directionDetails.durationText = response['routes'][0]['legs'][0]['duration']['text'];
      directionDetails.durationValue = response['routes'][0]['legs'][0]['duration']['value'];
    }
    return directionDetails;
  }
}
