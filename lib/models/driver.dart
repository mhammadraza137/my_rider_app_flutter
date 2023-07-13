
class Driver{
  String name;
  String phone;
  String carModel;
  String carNumber;

  Driver({required this.name, required this.phone, required this.carModel, required this.carNumber });

  static Driver getDriverFromMap(Map map){
    return Driver(
        name: map['name'],
        phone: map['phone'],
        carModel: map['car_details']['car_model'],
        carNumber: map['car_details']['car_number']);
  }
}