
class AvailableDriver{
  String uid;
  double latitude;
  double longitude;

  AvailableDriver({required this.uid, required this.latitude, required this.longitude});

  static AvailableDriver getAvailableDriverFromMap(Map map){
    return AvailableDriver(
        uid: map['uid'],
        latitude: map['latitude'],
        longitude: map['longitude']
    );
  }
}