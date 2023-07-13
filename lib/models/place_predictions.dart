
class PlacePredictions{
  String main_text;
  String secondary_text;
  String place_id;

  PlacePredictions({required this.main_text, required this.secondary_text, required this.place_id});

  static PlacePredictions fromJson(Map<String, dynamic> json){
    if(json['structured_formatting']['secondary_text'] != null ){
      return PlacePredictions(
          main_text: json['structured_formatting']['main_text'],
          secondary_text: json['structured_formatting']['secondary_text'],
          place_id: json['place_id']
      );
    }
    else{
      return PlacePredictions(
          main_text: json['structured_formatting']['main_text'],
          secondary_text: json['description'],
          place_id: json['place_id']
      );
    }

  }
}