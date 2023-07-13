import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_app/providers/data_provider.dart';
import 'package:rider_app/responses/google_maps_response.dart';

import '../models/place_predictions.dart';
import '../utils/dimensions.dart';

class SearchScreen extends StatefulWidget {
  static String idScreen = 'searchScreen';
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _pickUpTextEditingController =
      TextEditingController();
  final TextEditingController _destinationTextEditingController =
      TextEditingController();
  List<PlacePredictions> placePredictions = [];

  @override
  void dispose() {
    super.dispose();
    _pickUpTextEditingController.dispose();
    _destinationTextEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String placeAddress =
        Provider.of<DataProvider>(context).userPickUpAddress?.placeName ?? '';
    _pickUpTextEditingController.text = placeAddress;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.3,
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                    color: Colors.black54,
                    blurRadius: 6.0,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7))
              ]),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.01,
                      ),
                      Row(
                        children: [
                          GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Icon(Icons.arrow_back)),
                          Expanded(
                              child: Text(
                            'Set drop of',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width *
                                    appBarTitleSize,
                                fontFamily: 'Brand bold'),
                          ))
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.05,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            'images/pickicon.png',
                            width:
                                MediaQuery.of(context).size.width * iconsSize,
                            height:
                                MediaQuery.of(context).size.width * iconsSize,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.02,
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black54,
                                        spreadRadius: 0.5,
                                        blurRadius: 6,
                                        offset: Offset(0.7, 0.7))
                                  ]),
                              child: TextField(
                                controller: _pickUpTextEditingController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Pickup location',
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 10)),
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.03,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            'images/desticon.png',
                            height:
                                MediaQuery.of(context).size.width * iconsSize,
                            width:
                                MediaQuery.of(context).size.width * iconsSize,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.02,
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 6,
                                        spreadRadius: 0.5,
                                        offset: Offset(0.7, 0.7))
                                  ]),
                              child: TextField(
                                onChanged: (value) async {
                                  var placeList =
                                      await GoogleMapsResponse.findPlace(value);
                                  setState(() {
                                    placePredictions = placeList;
                                  });
                                  print('list is : $placePredictions');
                                },
                                controller: _destinationTextEditingController,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Where to?',
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 10)),
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.03,
                      )
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.01,
            ),
            // place predictions listview
            placePredictions.isNotEmpty
                ? Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    child: ListView.separated(
                      itemBuilder: (context, index) {
                        return TextButton(
                          style: const ButtonStyle(
                            padding: MaterialStatePropertyAll(EdgeInsets.all(0.0)),
                            alignment: Alignment.topLeft
                          ),
                          onPressed: () async{
                            await GoogleMapsResponse.getPlaceAddressDetails(placePredictions[index].place_id, context);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                placePredictions[index].main_text,
                                style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width *
                                        headingThreeSize,
                                    color: Colors.black
                                ),
                              ),
                              Text(
                                placePredictions[index].secondary_text,
                                style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width *
                                        textFieldTextSize,
                                    color: Colors.grey),
                              )
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const Divider();
                      },
                      itemCount: placePredictions.length,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                    ),
                  )
                : const SizedBox()
          ],
        ),
      ),
    );
  }
}
