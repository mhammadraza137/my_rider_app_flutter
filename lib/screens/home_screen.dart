import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_app/methods/database_methods.dart';
import 'package:rider_app/models/address.dart';
import 'package:rider_app/models/available_driver.dart';
import 'package:rider_app/models/direction_details.dart';
import 'package:rider_app/models/vehicle.dart';
import 'package:rider_app/providers/data_provider.dart';
import 'package:rider_app/responses/currency_response.dart';
import 'package:rider_app/responses/google_maps_response.dart';
import 'package:rider_app/screens/search_screen.dart';
import 'package:rider_app/utils/dimensions.dart';
import 'package:rider_app/widgets/auth_buttons.dart';
import 'package:rider_app/widgets/custom_Scrolling_text.dart';
import 'package:rider_app/widgets/nav_drawer.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:rider_app/widgets/progress_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../models/driver.dart';
import '../models/users.dart';
import '../utils/api_keys.dart';

class HomeScreen extends StatefulWidget {
  static const String idScreen = 'homeScreen';
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final Completer<GoogleMapController> _mapController = Completer();
  GoogleMapController? _newMapController;
  static const CameraPosition _kLahore =
      CameraPosition(target: LatLng(31.520370, 74.358749), zoom: 14.4746);
  // Position? currentPosition;
  double bottomPadding = 0;
  bool showBottom = true;
  // LatLng? latLng = const LatLng(0, 0);
  bool locationPermissionGranted = false;
  List<Vehicle> vehicleList = [
    Vehicle(name: 'Bike', image: 'images/bike.png'),
    Vehicle(name: 'Rickshaw', image: 'images/rickshaw.png'),
    Vehicle(name: 'Mini Car', image: 'images/car.png'),
    Vehicle(name: 'AC Car', image: 'images/premiumcar.png'),
  ];
  int selectedVehicleIndex = 0;
  late ScrollController _vehicleScrollController;
  bool scrollBtn = true;
  bool oneTimeScroll = true;
  Position? currentPosition;
  List<LatLng> polyLineCoordinates = [];
  Set<Polyline> polyLineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  late TextEditingController _faresTextEditingController;
  bool showSearchContainer = true;
  DirectionDetails? directionDetails;
  int rideFare = 0;
  bool rideFareContainerLoader = false;
  bool findDriverBtn = true;
  bool drawerOpen = true;
  bool findDriverContainer = false;
  bool showFareDetailsContainer = true;
  Users? currentUserInfo;
  bool userLoading = true;
  BitmapDescriptor? nearbyIcon;
  String? acceptedRideDriverId;
  Driver? acceptedRideDriver = Driver(name: 'name', phone: 'phone', carModel: 'carModel', carNumber: 'carNumber');
  // StreamSubscription<Position>? riderPositionStreamSubscription;
  /////
  bool oneTimeRideCompleteEvent = true;
  late final AnimationController _animationController = AnimationController(
      duration: const Duration(milliseconds: 500), vsync: this);
  late final Animation<Offset> offsetAnimation =
      Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1)).animate(
          CurvedAnimation(
              parent: _animationController, curve: Curves.decelerate));
  bool oneTimeAnimation = true;
  ////

  @override
  void initState() {
    super.initState();
    //
    _vehicleScrollController = ScrollController();
    _faresTextEditingController = TextEditingController();
    //
    currentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // after init state set icon for marker for available drivers
    getBytesFromAsset();
  }

  void currentUser() async {
    setState(() {
      userLoading = true;
    });
    currentUserInfo = await DatabaseMethods.getCurrentUserInfo();
    if (mounted) {
      setState(() {
        userLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    _newMapController?.dispose();
    _vehicleScrollController.dispose();
    _faresTextEditingController.dispose();

    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        drawer: NavDrawer(currentUser: currentUserInfo),
        body: userLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SafeArea(
                child: Stack(
                  children: [
                    GoogleMap(
                      padding: EdgeInsets.only(bottom: bottomPadding),
                      mapType: MapType.normal,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      initialCameraPosition: _kLahore,
                      zoomGesturesEnabled: true,
                      zoomControlsEnabled: false,
                      onMapCreated: (controller) async {
                        setState(() {
                          bottomPadding =
                              MediaQuery.of(context).size.height * 0.4;
                        });
                        //
                        if(!_mapController.isCompleted){
                          _mapController.complete(controller);
                        }
                        _newMapController = controller;
                        //
                        await getCurrentLocation();
                        //
                        getNearByVehicles();
                      },
                      polylines: polyLineSet,
                      markers: markerSet,
                      circles: circleSet,
                      onCameraMove: (position) {
                        if (oneTimeAnimation) {
                          _animationController.forward();
                          setState(() {
                            oneTimeAnimation = false;
                          });
                        }

                        // setState(() {
                        //   showBottom = false;
                        // });
                      },
                      onCameraIdle: () {
                        if (!oneTimeAnimation) {
                          _animationController.reverse();
                          setState(() {
                            oneTimeAnimation = true;
                          });
                        }

                        // setState(() {
                        //   showBottom = true;
                        // });
                      },
                    ),
                    Positioned(
                      top: 15,
                      left: 15,
                      child: GestureDetector(
                        onTap: () {
                          if (drawerOpen) {
                            scaffoldKey.currentState!.openDrawer();
                          } else {
                            cancelDirections();
                            // getNearByVehicles();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black54,
                                    spreadRadius: 0.5,
                                    blurRadius: 6,
                                    offset: Offset(0.7, 0.7))
                              ]),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: MediaQuery.of(context).size.width * 0.06,
                            child: Icon(
                              drawerOpen ? Icons.menu : Icons.close,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                        bottom: 0,
                        right: 0,
                        left: 0,
                        child: showSearchContainer
                            ? SlideTransition(
                                position: offsetAnimation,
                                child: Column(
                                  key: UniqueKey(),
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          right: 10, bottom: 10),
                                      child: FloatingActionButton(
                                        heroTag: null,
                                        onPressed: () {
                                          getCurrentLocation();
                                        },
                                        backgroundColor: Colors.white,
                                        child: const Icon(
                                          Icons.my_location,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.4,
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(20),
                                            topRight: Radius.circular(20),
                                          )),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.01,
                                            ),
                                            Text(
                                              'Hi there',
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          headingThreeSize),
                                            ),
                                            Text(
                                              'Where to?',
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          headingTwoSize,
                                                  fontFamily: 'Brand bold'),
                                            ),
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.01,
                                            ),
                                            GestureDetector(
                                              onTap: () async {
                                                var response =
                                                    await Navigator.pushNamed(
                                                        context,
                                                        SearchScreen.idScreen);
                                                if (response ==
                                                    'directionReceived') {
                                                  await getPlaceDirection();
                                                  // show close button on top
                                                  setState(() {
                                                    drawerOpen = false;
                                                  });
                                                  // initial get default bike ride amount
                                                  int rideAmount =
                                                      await calculateRideFares(
                                                          directionDetails!,
                                                          selectedVehicleIndex);
                                                  setState(() {
                                                    showSearchContainer = false;
                                                    rideFare = rideAmount;
                                                  });
                                                }
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 10),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5),
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: Colors.black54,
                                                        blurRadius: 3,
                                                        spreadRadius: 0.5,
                                                      ),
                                                    ]),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.search,
                                                        color: Colors.black54),
                                                    SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.01,
                                                    ),
                                                    Text(
                                                      'Search drop of',
                                                      style: TextStyle(
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              textFieldTextSize),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.03,
                                            ),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.home,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.01,
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.8,
                                                        height: 20,
                                                        child:
                                                            CustomScrollingText(
                                                          text: Provider.of<DataProvider>(
                                                                          context)
                                                                      .userPickUpAddress !=
                                                                  null
                                                              ? Provider.of<
                                                                          DataProvider>(
                                                                      context)
                                                                  .userPickUpAddress!
                                                                  .placeName!
                                                              : 'Add home',
                                                        )),
                                                    SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.005,
                                                    ),
                                                    Text(
                                                      'Your living home address',
                                                      style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              textFieldTextSize),
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.01,
                                            ),
                                            const Divider(),
                                            SizedBox(
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height *
                                                  0.01,
                                            ),
                                            GestureDetector(
                                              onTap: () {},
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.work,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.01,
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Add work',
                                                        style: TextStyle(
                                                            fontSize: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                textFieldTextSize),
                                                      ),
                                                      SizedBox(
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.005,
                                                      ),
                                                      Text(
                                                        'Your office address',
                                                        style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                textFieldTextSize),
                                                      )
                                                    ],
                                                  )
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            // Search container
                            // AnimatedSwitcher(
                            //     duration: const Duration(milliseconds: 300),
                            //     transitionBuilder: (child, animation) =>
                            //         SlideTransition(
                            //       position: Tween(
                            //               begin: const Offset(0, 1),
                            //               end: const Offset(0, 0))
                            //           .animate(animation),
                            //       child: child,
                            //     ),
                            //     child: showBottom
                            //         ? Column(
                            //             key: UniqueKey(),
                            //             crossAxisAlignment:
                            //                 CrossAxisAlignment.end,
                            //             children: [
                            //               Padding(
                            //                 padding: const EdgeInsets.only(
                            //                     right: 10, bottom: 10),
                            //                 child: FloatingActionButton(
                            //                   heroTag: null,
                            //                   onPressed: () {
                            //                     getCurrentLocation();
                            //                   },
                            //                   backgroundColor: Colors.white,
                            //                   child: const Icon(
                            //                     Icons.my_location,
                            //                     color: Colors.black,
                            //                   ),
                            //                 ),
                            //               ),
                            //               Container(
                            //                 height: MediaQuery.of(context)
                            //                         .size
                            //                         .height *
                            //                     0.4,
                            //                 width: double.infinity,
                            //                 padding: const EdgeInsets.symmetric(
                            //                     horizontal: 10, vertical: 5),
                            //                 decoration: const BoxDecoration(
                            //                     color: Colors.white,
                            //                     borderRadius: BorderRadius.only(
                            //                       topLeft: Radius.circular(20),
                            //                       topRight: Radius.circular(20),
                            //                     )),
                            //                 child: SingleChildScrollView(
                            //                   child: Column(
                            //                     crossAxisAlignment:
                            //                         CrossAxisAlignment.start,
                            //                     children: [
                            //                       SizedBox(
                            //                         height: MediaQuery.of(context)
                            //                                 .size
                            //                                 .height *
                            //                             0.01,
                            //                       ),
                            //                       Text(
                            //                         'Hi there',
                            //                         style: TextStyle(
                            //                             fontSize:
                            //                                 MediaQuery.of(context)
                            //                                         .size
                            //                                         .width *
                            //                                     headingThreeSize),
                            //                       ),
                            //                       Text(
                            //                         'Where to?',
                            //                         style: TextStyle(
                            //                             fontSize:
                            //                                 MediaQuery.of(context)
                            //                                         .size
                            //                                         .width *
                            //                                     headingTwoSize,
                            //                             fontFamily: 'Brand bold'),
                            //                       ),
                            //                       SizedBox(
                            //                         height: MediaQuery.of(context)
                            //                                 .size
                            //                                 .height *
                            //                             0.01,
                            //                       ),
                            //                       GestureDetector(
                            //                         onTap: () async {
                            //                           var response =
                            //                               await Navigator
                            //                                   .pushNamed(
                            //                                       context,
                            //                                       SearchScreen
                            //                                           .idScreen);
                            //                           if (response ==
                            //                               'directionReceived') {
                            //                             await getPlaceDirection();
                            //                             // show close button on top
                            //                             setState(() {
                            //                               drawerOpen = false;
                            //                             });
                            //                             // initial get default bike ride amount
                            //                             int rideAmount =
                            //                                 await calculateRideFares(
                            //                                     directionDetails!,
                            //                                     selectedVehicleIndex);
                            //                             setState(() {
                            //                               showSearchContainer =
                            //                                   false;
                            //                               rideFare = rideAmount;
                            //                             });
                            //                           }
                            //                         },
                            //                         child: Container(
                            //                           padding: const EdgeInsets
                            //                                   .symmetric(
                            //                               horizontal: 10,
                            //                               vertical: 10),
                            //                           margin: const EdgeInsets
                            //                                   .symmetric(
                            //                               horizontal: 5),
                            //                           decoration: BoxDecoration(
                            //                               color: Colors.white,
                            //                               borderRadius:
                            //                                   BorderRadius
                            //                                       .circular(8),
                            //                               boxShadow: const [
                            //                                 BoxShadow(
                            //                                   color:
                            //                                       Colors.black54,
                            //                                   blurRadius: 3,
                            //                                   spreadRadius: 0.5,
                            //                                 ),
                            //                               ]),
                            //                           child: Row(
                            //                             children: [
                            //                               const Icon(Icons.search,
                            //                                   color:
                            //                                       Colors.black54),
                            //                               SizedBox(
                            //                                 width: MediaQuery.of(
                            //                                             context)
                            //                                         .size
                            //                                         .width *
                            //                                     0.01,
                            //                               ),
                            //                               Text(
                            //                                 'Search drop of',
                            //                                 style: TextStyle(
                            //                                     fontSize: MediaQuery.of(
                            //                                                 context)
                            //                                             .size
                            //                                             .width *
                            //                                         textFieldTextSize),
                            //                               )
                            //                             ],
                            //                           ),
                            //                         ),
                            //                       ),
                            //                       SizedBox(
                            //                         height: MediaQuery.of(context)
                            //                                 .size
                            //                                 .height *
                            //                             0.03,
                            //                       ),
                            //                       Row(
                            //                         children: [
                            //                           const Icon(
                            //                             Icons.home,
                            //                             color: Colors.grey,
                            //                           ),
                            //                           SizedBox(
                            //                             width:
                            //                                 MediaQuery.of(context)
                            //                                         .size
                            //                                         .width *
                            //                                     0.01,
                            //                           ),
                            //                           Column(
                            //                             crossAxisAlignment:
                            //                                 CrossAxisAlignment
                            //                                     .start,
                            //                             children: [
                            //                               SizedBox(
                            //                                   width: MediaQuery.of(
                            //                                               context)
                            //                                           .size
                            //                                           .width *
                            //                                       0.8,
                            //                                   height: 20,
                            //                                   child:
                            //                                       CustomScrollingText(
                            //                                     text: Provider.of<DataProvider>(
                            //                                                     context)
                            //                                                 .userPickUpAddress !=
                            //                                             null
                            //                                         ? Provider.of<
                            //                                                     DataProvider>(
                            //                                                 context)
                            //                                             .userPickUpAddress!
                            //                                             .placeName!
                            //                                         : 'Add home',
                            //                                   )),
                            //                               SizedBox(
                            //                                 height: MediaQuery.of(
                            //                                             context)
                            //                                         .size
                            //                                         .height *
                            //                                     0.005,
                            //                               ),
                            //                               Text(
                            //                                 'Your living home address',
                            //                                 style: TextStyle(
                            //                                     color:
                            //                                         Colors.grey,
                            //                                     fontSize: MediaQuery.of(
                            //                                                 context)
                            //                                             .size
                            //                                             .width *
                            //                                         textFieldTextSize),
                            //                               )
                            //                             ],
                            //                           )
                            //                         ],
                            //                       ),
                            //                       SizedBox(
                            //                         height: MediaQuery.of(context)
                            //                                 .size
                            //                                 .height *
                            //                             0.01,
                            //                       ),
                            //                       const Divider(),
                            //                       SizedBox(
                            //                         height: MediaQuery.of(context)
                            //                                 .size
                            //                                 .height *
                            //                             0.01,
                            //                       ),
                            //                       GestureDetector(
                            //                         onTap: () {},
                            //                         child: Row(
                            //                           children: [
                            //                             const Icon(
                            //                               Icons.work,
                            //                               color: Colors.grey,
                            //                             ),
                            //                             SizedBox(
                            //                               width: MediaQuery.of(
                            //                                           context)
                            //                                       .size
                            //                                       .width *
                            //                                   0.01,
                            //                             ),
                            //                             Column(
                            //                               crossAxisAlignment:
                            //                                   CrossAxisAlignment
                            //                                       .start,
                            //                               children: [
                            //                                 Text(
                            //                                   'Add work',
                            //                                   style: TextStyle(
                            //                                       fontSize: MediaQuery.of(
                            //                                                   context)
                            //                                               .size
                            //                                               .width *
                            //                                           textFieldTextSize),
                            //                                 ),
                            //                                 SizedBox(
                            //                                   height: MediaQuery.of(
                            //                                               context)
                            //                                           .size
                            //                                           .height *
                            //                                       0.005,
                            //                                 ),
                            //                                 Text(
                            //                                   'Your office address',
                            //                                   style: TextStyle(
                            //                                       color:
                            //                                           Colors.grey,
                            //                                       fontSize: MediaQuery.of(
                            //                                                   context)
                            //                                               .size
                            //                                               .width *
                            //                                           textFieldTextSize),
                            //                                 )
                            //                               ],
                            //                             )
                            //                           ],
                            //                         ),
                            //                       )
                            //                     ],
                            //                   ),
                            //                 ),
                            //               ),
                            //             ],
                            //           )
                            //         : SizedBox(
                            //             key: UniqueKey(),
                            //           ),
                            //   )
                            : showFareDetailsContainer
                                ? SlideTransition(
                                    position: offsetAnimation,
                                    child: Container(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.45,
                                        width: double.infinity,
                                        decoration: const BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(20),
                                                topRight: Radius.circular(20))),
                                        child: Stack(
                                          children: [
                                            SingleChildScrollView(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                child: Column(
                                                  children: [
                                                    Stack(
                                                      children: [
                                                        SizedBox(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height *
                                                              0.10,
                                                          child: ListView
                                                              .separated(
                                                            itemBuilder:
                                                                (context,
                                                                    index) {
                                                              // handle scroll button on vehicle scroll listview
                                                              _vehicleScrollController
                                                                  .addListener(
                                                                      () {
                                                                if (_vehicleScrollController
                                                                            .position
                                                                            .pixels <=
                                                                        _vehicleScrollController.position.maxScrollExtent -
                                                                            10 &&
                                                                    oneTimeScroll) {
                                                                  setState(() {
                                                                    scrollBtn =
                                                                        true;
                                                                    oneTimeScroll =
                                                                        false;
                                                                  });
                                                                } else if (_vehicleScrollController
                                                                        .position
                                                                        .pixels ==
                                                                    _vehicleScrollController
                                                                        .position
                                                                        .maxScrollExtent) {
                                                                  setState(() {
                                                                    scrollBtn =
                                                                        false;
                                                                    oneTimeScroll =
                                                                        true;
                                                                  });
                                                                }
                                                              });
                                                              return GestureDetector(
                                                                onTap:
                                                                    () async {
                                                                  setState(() {
                                                                    selectedVehicleIndex =
                                                                        index;
                                                                    rideFareContainerLoader =
                                                                        true;
                                                                  });
                                                                  int rideAmount =
                                                                      await calculateRideFares(
                                                                          directionDetails!,
                                                                          index);
                                                                  setState(() {
                                                                    rideFare =
                                                                        rideAmount;
                                                                    rideFareContainerLoader =
                                                                        false;
                                                                  });
                                                                },
                                                                child:
                                                                    Container(
                                                                  width: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .width *
                                                                      0.3,
                                                                  decoration: BoxDecoration(
                                                                      color: selectedVehicleIndex ==
                                                                              index
                                                                          ? Colors.blue.withOpacity(
                                                                              0.1)
                                                                          : Colors
                                                                              .white,
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10)),
                                                                  child: Column(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceEvenly,
                                                                    children: [
                                                                      Image
                                                                          .asset(
                                                                        vehicleList[index]
                                                                            .image,
                                                                        width: MediaQuery.of(context).size.width *
                                                                            0.13,
                                                                        height: MediaQuery.of(context).size.height *
                                                                            0.05,
                                                                      ),
                                                                      Text(vehicleList[
                                                                              index]
                                                                          .name)
                                                                    ],
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            itemCount:
                                                                vehicleList
                                                                    .length,
                                                            shrinkWrap: true,
                                                            scrollDirection:
                                                                Axis.horizontal,
                                                            controller:
                                                                _vehicleScrollController,
                                                            separatorBuilder:
                                                                (BuildContext
                                                                        context,
                                                                    int index) {
                                                              return const SizedBox(
                                                                width: 10,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                        (_vehicleScrollController
                                                                .hasClients)
                                                            ? Positioned(
                                                                right: 0,
                                                                top: 10,
                                                                child: scrollBtn
                                                                    ? FloatingActionButton
                                                                        .small(
                                                                        backgroundColor:
                                                                            Colors.white,
                                                                        child:
                                                                            const Icon(
                                                                          Icons
                                                                              .arrow_forward_ios_outlined,
                                                                          color:
                                                                              Colors.black,
                                                                          size:
                                                                              15,
                                                                        ),
                                                                        onPressed:
                                                                            () {
                                                                          _vehicleScrollController.animateTo(
                                                                              _vehicleScrollController.position.maxScrollExtent,
                                                                              duration: const Duration(milliseconds: 400),
                                                                              curve: Curves.linear);
                                                                          Future
                                                                              .delayed(
                                                                            const Duration(milliseconds: 400),
                                                                            () {
                                                                              setState(() {
                                                                                scrollBtn = false;
                                                                              });
                                                                            },
                                                                          );
                                                                        },
                                                                      )
                                                                    : const SizedBox())
                                                            : const SizedBox(),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.03,
                                                    ),
                                                    Container(
                                                      width: double.infinity,
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 10,
                                                          vertical: 10),
                                                      decoration: BoxDecoration(
                                                          color: Colors.green
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5)),
                                                      child: Column(
                                                        children: [
                                                          RichText(
                                                              text: TextSpan(
                                                                  style: const TextStyle(
                                                                      color: Colors
                                                                          .black),
                                                                  children: [
                                                                const TextSpan(
                                                                    text:
                                                                        'The recommended fare is'),
                                                                TextSpan(
                                                                    text:
                                                                        ' Rs$rideFare',
                                                                    style: TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold)),
                                                                const TextSpan(
                                                                    text:
                                                                        ', travel time'),
                                                              ])),
                                                          RichText(
                                                              text: TextSpan(
                                                                  style: const TextStyle(
                                                                      color: Colors
                                                                          .black),
                                                                  children: [
                                                                TextSpan(
                                                                    text:
                                                                        ' ~${directionDetails!.durationText}',
                                                                    style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold))
                                                              ]))
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.03,
                                                    ),
                                                    Row(
                                                      children: [
                                                        const Text(
                                                          'Rs',
                                                          style: TextStyle(
                                                            fontSize: 25,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width *
                                                              0.02,
                                                        ),
                                                        Expanded(
                                                            child:
                                                                TextFormField(
                                                                    controller:
                                                                        _faresTextEditingController,
                                                                    onChanged:
                                                                        (value) {
                                                                      if (_faresTextEditingController
                                                                          .text
                                                                          .isNotEmpty) {
                                                                        setState(
                                                                            () {
                                                                          findDriverBtn =
                                                                              false;
                                                                        });
                                                                      } else if (_faresTextEditingController
                                                                          .text
                                                                          .isEmpty) {
                                                                        setState(
                                                                            () {
                                                                          findDriverBtn =
                                                                              true;
                                                                        });
                                                                      }
                                                                    },
                                                                    keyboardType:
                                                                        TextInputType
                                                                            .phone,
                                                                    decoration: InputDecoration(
                                                                        hintText:
                                                                            '$rideFare , Estimated fares (Adjustable)',
                                                                        enabledBorder:
                                                                            const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                                                                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))))),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.03,
                                                    ),
                                                    ElevatedButton(
                                                        style: ButtonStyle(
                                                            shape: MaterialStatePropertyAll(
                                                                RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10))),
                                                            backgroundColor:
                                                                const MaterialStatePropertyAll(Colors
                                                                    .lightGreen)),
                                                        onPressed: findDriverBtn
                                                            ? null
                                                            : () {
                                                                DatabaseMethods
                                                                    .saveRideRequest(
                                                                        context,
                                                                        currentUserInfo!);

                                                                setState(() {
                                                                  // show finding driver container
                                                                  findDriverContainer =
                                                                      true;
                                                                  // disable top close button
                                                                  drawerOpen =
                                                                      true;
                                                                  // hide fare detail container
                                                                  showFareDetailsContainer =
                                                                      false;
                                                                  //
                                                                  oneTimeRideCompleteEvent = true;
                                                                });
                                                                DatabaseReference
                                                                    databaseReference =
                                                                    FirebaseDatabase
                                                                        .instance
                                                                        .ref()
                                                                        .child(
                                                                            'ride requests')
                                                                        .child(currentUserInfo!
                                                                            .uid);
                                                                databaseReference
                                                                    .onValue
                                                                    .listen(
                                                                        (event) async {

                                                                  DataSnapshot
                                                                      snapshot =
                                                                      event
                                                                          .snapshot;
                                                                  if (snapshot
                                                                          .value !=
                                                                      null) {
                                                                    if ((snapshot.value as Map<
                                                                            dynamic,
                                                                            dynamic>)['driver_id'] !=
                                                                        'waiting') {
                                                                      //

                                                                      //
                                                                      acceptedRideDriverId =
                                                                      (snapshot.value
                                                                      as Map)['driver_id'];
                                                                      DatabaseReference driverDatabaseReference = FirebaseDatabase
                                                                          .instance
                                                                          .ref()
                                                                          .child('drivers')
                                                                          .child(acceptedRideDriverId!);
                                                                      await driverDatabaseReference
                                                                          .once()
                                                                          .then((value) {
                                                                        DataSnapshot
                                                                        snapshot =
                                                                            value.snapshot;
                                                                        if (snapshot.value !=
                                                                            null) {
                                                                          acceptedRideDriver =
                                                                              Driver.getDriverFromMap((snapshot.value as Map<dynamic, dynamic>));
                                                                          print('accepted ride driver : ${acceptedRideDriver!.phone}');
                                                                        }
                                                                      });
                                                                      setState(
                                                                              () {
                                                                            acceptedRideDriverId =
                                                                            (snapshot.value
                                                                            as Map)['driver_id'];
                                                                          });
                                                                      if(oneTimeRideCompleteEvent){
                                                                        setState(() {
                                                                          oneTimeRideCompleteEvent = false;
                                                                        });
                                                                        print('how many times');
                                                                        // ignore: use_build_context_synchronously
                                                                        Address? dropOff =  Provider.of<DataProvider>(context, listen: false).dropOffAddress;
                                                                        StreamSubscription? riderPositionStreamSubscription;

                                                                        riderPositionStreamSubscription = Geolocator.getPositionStream().listen((Position livePosition) async{
                                                                          print('live position is : $livePosition');
                                                                          print('latitude is = ${livePosition.latitude.toStringAsFixed(3)} : ${(31.524).toString()}');
                                                                          print('latitude is = ${livePosition.longitude.toStringAsFixed(3)} : ${(74.318).toString()}');
                                                                          if( livePosition.latitude.toStringAsFixed(3) == (dropOff!.latitude)!.toStringAsFixed(3) && livePosition.longitude.toStringAsFixed(3) == (dropOff.longitude)!.toStringAsFixed(3)){

                                                                            // cancelRiderPositionSubscription();
                                                                            await riderPositionStreamSubscription?.cancel().then((value){

                                                                              setState(()  {
                                                                                // hide finding your driver container
                                                                                findDriverContainer = false;
                                                                                //
                                                                                DatabaseMethods
                                                                                    .removeRideRequest(
                                                                                    currentUserInfo!);
                                                                                //
                                                                                cancelDirections();
                                                                                //
                                                                                // enable visibility of fare details container
                                                                                showFareDetailsContainer =
                                                                                true;
                                                                                //
                                                                                acceptedRideDriverId = null;
                                                                                acceptedRideDriver = Driver(name: 'name', phone: 'phone', carModel: 'carModel', carNumber: 'carNumber');
                                                                                //
                                                                                riderPositionStreamSubscription = null;

                                                                              });
                                                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('destination arrived')));
                                                                            });
                                                                          }
                                                                        });
                                                                      }
                                                                    }
                                                                  }
                                                                });

                                                                },
                                                        child: SizedBox(
                                                            width:
                                                                double.infinity,
                                                            height: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                authButtonsHeight,
                                                            child: const Center(
                                                                child:
                                                                    Text('Find Driver'))))
                                                  ],
                                                ),
                                              ),
                                            ),
                                            rideFareContainerLoader
                                                ? Container(
                                                    decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            const BorderRadius
                                                                    .only(
                                                                topLeft: Radius
                                                                    .circular(
                                                                        20),
                                                                topRight: Radius
                                                                    .circular(
                                                                        20))),
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ))
                                                : const SizedBox()
                                          ],
                                        )))
                                : const SizedBox()
                        // Ride details Container
                        // showFareDetailsContainer
                        //     ? AnimatedSwitcher(
                        //         duration: const Duration(milliseconds: 200),
                        //         transitionBuilder: (child, animation) =>
                        //             SlideTransition(
                        //           position: Tween(
                        //                   begin: const Offset(0, 1),
                        //                   end: const Offset(0, 0))
                        //               .animate(animation),
                        //           child: child,
                        //         ),
                        //         child: showBottom
                        //             ? Container(
                        //                 height: MediaQuery.of(context)
                        //                         .size
                        //                         .height *
                        //                     0.45,
                        //                 width: double.infinity,
                        //                 decoration: const BoxDecoration(
                        //                     color: Colors.white,
                        //                     borderRadius: BorderRadius.only(
                        //                         topLeft: Radius.circular(20),
                        //                         topRight:
                        //                             Radius.circular(20))),
                        //                 child: Stack(
                        //                   children: [
                        //                     SingleChildScrollView(
                        //                       child: Padding(
                        //                         padding: const EdgeInsets
                        //                                 .symmetric(
                        //                             horizontal: 10,
                        //                             vertical: 5),
                        //                         child: Column(
                        //                           children: [
                        //                             Stack(
                        //                               children: [
                        //                                 SizedBox(
                        //                                   height: MediaQuery.of(
                        //                                               context)
                        //                                           .size
                        //                                           .height *
                        //                                       0.10,
                        //                                   child: ListView
                        //                                       .separated(
                        //                                     itemBuilder:
                        //                                         (context,
                        //                                             index) {
                        //                                       // handle scroll button on vehicle scroll listview
                        //                                       _vehicleScrollController
                        //                                           .addListener(
                        //                                               () {
                        //                                         if (_vehicleScrollController
                        //                                                     .position
                        //                                                     .pixels <=
                        //                                                 _vehicleScrollController.position.maxScrollExtent -
                        //                                                     10 &&
                        //                                             oneTimeScroll) {
                        //                                           setState(
                        //                                               () {
                        //                                             scrollBtn =
                        //                                                 true;
                        //                                             oneTimeScroll =
                        //                                                 false;
                        //                                           });
                        //                                         } else if (_vehicleScrollController
                        //                                                 .position
                        //                                                 .pixels ==
                        //                                             _vehicleScrollController
                        //                                                 .position
                        //                                                 .maxScrollExtent) {
                        //                                           setState(
                        //                                               () {
                        //                                             scrollBtn =
                        //                                                 false;
                        //                                             oneTimeScroll =
                        //                                                 true;
                        //                                           });
                        //                                         }
                        //                                       });
                        //                                       return GestureDetector(
                        //                                         onTap:
                        //                                             () async {
                        //                                           setState(
                        //                                               () {
                        //                                             selectedVehicleIndex =
                        //                                                 index;
                        //                                             rideFareContainerLoader =
                        //                                                 true;
                        //                                           });
                        //                                           int rideAmount =
                        //                                               await calculateRideFares(
                        //                                                   directionDetails!,
                        //                                                   index);
                        //                                           setState(
                        //                                               () {
                        //                                             rideFare =
                        //                                                 rideAmount;
                        //                                             rideFareContainerLoader =
                        //                                                 false;
                        //                                           });
                        //                                         },
                        //                                         child:
                        //                                             Container(
                        //                                           width: MediaQuery.of(context)
                        //                                                   .size
                        //                                                   .width *
                        //                                               0.3,
                        //                                           decoration: BoxDecoration(
                        //                                               color: selectedVehicleIndex ==
                        //                                                       index
                        //                                                   ? Colors.blue.withOpacity(
                        //                                                       0.1)
                        //                                                   : Colors
                        //                                                       .white,
                        //                                               borderRadius:
                        //                                                   BorderRadius.circular(10)),
                        //                                           child:
                        //                                               Column(
                        //                                             mainAxisAlignment:
                        //                                                 MainAxisAlignment
                        //                                                     .spaceEvenly,
                        //                                             children: [
                        //                                               Image
                        //                                                   .asset(
                        //                                                 vehicleList[index]
                        //                                                     .image,
                        //                                                 width:
                        //                                                     MediaQuery.of(context).size.width * 0.13,
                        //                                                 height:
                        //                                                     MediaQuery.of(context).size.height * 0.05,
                        //                                               ),
                        //                                               Text(vehicleList[index]
                        //                                                   .name)
                        //                                             ],
                        //                                           ),
                        //                                         ),
                        //                                       );
                        //                                     },
                        //                                     itemCount:
                        //                                         vehicleList
                        //                                             .length,
                        //                                     shrinkWrap: true,
                        //                                     scrollDirection:
                        //                                         Axis.horizontal,
                        //                                     controller:
                        //                                         _vehicleScrollController,
                        //                                     separatorBuilder:
                        //                                         (BuildContext
                        //                                                 context,
                        //                                             int index) {
                        //                                       return const SizedBox(
                        //                                         width: 10,
                        //                                       );
                        //                                     },
                        //                                   ),
                        //                                 ),
                        //                                 (_vehicleScrollController
                        //                                         .hasClients)
                        //                                     ? Positioned(
                        //                                         right: 0,
                        //                                         top: 10,
                        //                                         child: scrollBtn
                        //                                             ? FloatingActionButton.small(
                        //                                                 backgroundColor:
                        //                                                     Colors.white,
                        //                                                 child:
                        //                                                     const Icon(
                        //                                                   Icons.arrow_forward_ios_outlined,
                        //                                                   color:
                        //                                                       Colors.black,
                        //                                                   size:
                        //                                                       15,
                        //                                                 ),
                        //                                                 onPressed:
                        //                                                     () {
                        //                                                   _vehicleScrollController.animateTo(_vehicleScrollController.position.maxScrollExtent,
                        //                                                       duration: const Duration(milliseconds: 400),
                        //                                                       curve: Curves.linear);
                        //                                                   Future.delayed(
                        //                                                     const Duration(milliseconds: 400),
                        //                                                     () {
                        //                                                       setState(() {
                        //                                                         scrollBtn = false;
                        //                                                       });
                        //                                                     },
                        //                                                   );
                        //                                                 },
                        //                                               )
                        //                                             : const SizedBox())
                        //                                     : const SizedBox(),
                        //                               ],
                        //                             ),
                        //                             SizedBox(
                        //                               height: MediaQuery.of(
                        //                                           context)
                        //                                       .size
                        //                                       .height *
                        //                                   0.03,
                        //                             ),
                        //                             Container(
                        //                               width: double.infinity,
                        //                               padding:
                        //                                   const EdgeInsets
                        //                                           .symmetric(
                        //                                       horizontal: 10,
                        //                                       vertical: 10),
                        //                               decoration: BoxDecoration(
                        //                                   color: Colors.green
                        //                                       .withOpacity(
                        //                                           0.2),
                        //                                   borderRadius:
                        //                                       BorderRadius
                        //                                           .circular(
                        //                                               5)),
                        //                               child: Column(
                        //                                 children: [
                        //                                   RichText(
                        //                                       text: TextSpan(
                        //                                           style: const TextStyle(
                        //                                               color: Colors
                        //                                                   .black),
                        //                                           children: [
                        //                                         const TextSpan(
                        //                                             text:
                        //                                                 'The recommended fare is'),
                        //                                         TextSpan(
                        //                                             text:
                        //                                                 ' Rs$rideFare',
                        //                                             style: TextStyle(
                        //                                                 fontWeight:
                        //                                                     FontWeight.bold)),
                        //                                         const TextSpan(
                        //                                             text:
                        //                                                 ', travel time'),
                        //                                       ])),
                        //                                   RichText(
                        //                                       text: TextSpan(
                        //                                           style: const TextStyle(
                        //                                               color: Colors
                        //                                                   .black),
                        //                                           children: [
                        //                                         TextSpan(
                        //                                             text:
                        //                                                 ' ~${directionDetails!.durationText}',
                        //                                             style: const TextStyle(
                        //                                                 fontWeight:
                        //                                                     FontWeight.bold))
                        //                                       ]))
                        //                                 ],
                        //                               ),
                        //                             ),
                        //                             SizedBox(
                        //                               height: MediaQuery.of(
                        //                                           context)
                        //                                       .size
                        //                                       .height *
                        //                                   0.03,
                        //                             ),
                        //                             Row(
                        //                               children: [
                        //                                 const Text(
                        //                                   'Rs',
                        //                                   style: TextStyle(
                        //                                     fontSize: 25,
                        //                                   ),
                        //                                 ),
                        //                                 SizedBox(
                        //                                   width: MediaQuery.of(
                        //                                               context)
                        //                                           .size
                        //                                           .width *
                        //                                       0.02,
                        //                                 ),
                        //                                 Expanded(
                        //                                     child:
                        //                                         TextFormField(
                        //                                             controller:
                        //                                                 _faresTextEditingController,
                        //                                             onChanged:
                        //                                                 (value) {
                        //                                               if (_faresTextEditingController
                        //                                                   .text
                        //                                                   .isNotEmpty) {
                        //                                                 setState(
                        //                                                     () {
                        //                                                   findDriverBtn =
                        //                                                       false;
                        //                                                 });
                        //                                               } else if (_faresTextEditingController
                        //                                                   .text
                        //                                                   .isEmpty) {
                        //                                                 setState(
                        //                                                     () {
                        //                                                   findDriverBtn =
                        //                                                       true;
                        //                                                 });
                        //                                               }
                        //                                             },
                        //                                             keyboardType:
                        //                                                 TextInputType
                        //                                                     .phone,
                        //                                             decoration: InputDecoration(
                        //                                                 hintText:
                        //                                                     '$rideFare , Estimated fares (Adjustable)',
                        //                                                 enabledBorder:
                        //                                                     const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        //                                                 focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey))))),
                        //                               ],
                        //                             ),
                        //                             SizedBox(
                        //                               height: MediaQuery.of(
                        //                                           context)
                        //                                       .size
                        //                                       .height *
                        //                                   0.03,
                        //                             ),
                        //                             ElevatedButton(
                        //                                 style: ButtonStyle(
                        //                                     shape: MaterialStatePropertyAll(
                        //                                         RoundedRectangleBorder(
                        //                                             borderRadius:
                        //                                                 BorderRadius.circular(
                        //                                                     10))),
                        //                                     backgroundColor:
                        //                                         const MaterialStatePropertyAll(Colors
                        //                                             .lightGreen)),
                        //                                 onPressed:
                        //                                     findDriverBtn
                        //                                         ? null
                        //                                         : () {
                        //                                             DatabaseMethods.saveRideRequest(
                        //                                                 context,
                        //                                                 currentUserInfo!);
                        //                                             setState(
                        //                                                 () {
                        //                                               // show finding driver container
                        //                                               findDriverContainer =
                        //                                                   true;
                        //                                               // disable top close button
                        //                                               drawerOpen =
                        //                                                   true;
                        //                                               // hide fare detail container
                        //                                               showFareDetailsContainer =
                        //                                                   false;
                        //                                             });
                        //                                           },
                        //                                 child: SizedBox(
                        //                                     width: double
                        //                                         .infinity,
                        //                                     height: MediaQuery.of(
                        //                                                 context)
                        //                                             .size
                        //                                             .height *
                        //                                         authButtonsHeight,
                        //                                     child: const Center(
                        //                                         child:
                        //                                             Text('Find Driver'))))
                        //                           ],
                        //                         ),
                        //                       ),
                        //                     ),
                        //                     rideFareContainerLoader
                        //                         ? Container(
                        //                             decoration: BoxDecoration(
                        //                                 color: Colors.black
                        //                                     .withOpacity(0.2),
                        //                                 borderRadius:
                        //                                     const BorderRadius
                        //                                             .only(
                        //                                         topLeft: Radius
                        //                                             .circular(
                        //                                                 20),
                        //                                         topRight: Radius
                        //                                             .circular(
                        //                                                 20))),
                        //                             child: const Center(
                        //                               child:
                        //                                   CircularProgressIndicator(),
                        //                             ))
                        //                         : const SizedBox()
                        //                   ],
                        //                 ))
                        //             : const SizedBox(),
                        //       )
                        //     : const SizedBox(),
                        ),
                    findDriverContainer
                        ? Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.2,
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20))),
                              child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: (acceptedRideDriverId == null)
                                      ? Column(
                                          children: [
                                            SizedBox(
                                              height: 40,
                                              child: DefaultTextStyle(
                                                style: const TextStyle(
                                                    letterSpacing: 2,
                                                    fontSize: 30,
                                                    color: Colors.green,
                                                    fontFamily: 'Signatra'),
                                                child: AnimatedTextKit(
                                                  repeatForever: true,
                                                  animatedTexts: [
                                                    FadeAnimatedText(
                                                        'Please wait...'),
                                                    FadeAnimatedText(
                                                        'Finding your driver'),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  // hide finding your driver container
                                                  findDriverContainer = false;
                                                  //
                                                  DatabaseMethods
                                                      .removeRideRequest(
                                                          currentUserInfo!);
                                                  //
                                                  cancelDirections();
                                                  //
                                                  // getNearByVehicles();
                                                  // enable visibility of fare details container
                                                  showFareDetailsContainer =
                                                      true;
                                                });
                                              },
                                              child: Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                          color: Colors.grey,
                                                          spreadRadius: 0.5,
                                                          blurRadius: 6,
                                                          offset:
                                                              Offset(0.7, 0.7))
                                                    ]),
                                                child: const Icon(Icons.close,
                                                    size: 25),
                                              ),
                                            )
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            Text(
                                              acceptedRideDriver!.name,
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            SizedBox(height: MediaQuery.of(context).size.height*0.01,),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    RichText(
                                                        text:
                                                            TextSpan(children: [
                                                      const TextSpan(
                                                          text: 'Car Model : ',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 20,
                                                          )),
                                                      TextSpan(
                                                          text:
                                                              acceptedRideDriver!
                                                                  .carModel,
                                                          style: const TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold))
                                                    ])),
                                                    SizedBox(height: MediaQuery.of(context).size.height*0.01,),
                                                    RichText(
                                                        text:
                                                        TextSpan(children: [
                                                          const TextSpan(
                                                              text: 'Car Number : ',
                                                              style: TextStyle(
                                                                color: Colors.black,
                                                                fontSize: 20,
                                                              )),
                                                          TextSpan(
                                                              text:
                                                              acceptedRideDriver!
                                                                  .carNumber,
                                                              style: const TextStyle(
                                                                  color:
                                                                  Colors.black,
                                                                  fontSize: 20,
                                                                  fontWeight:
                                                                  FontWeight
                                                                      .bold))
                                                        ])),
                                                  ],
                                                ),
                                                InkWell(
                                                    onTap: () async{
                                                      String url = "tel:${acceptedRideDriver!.phone}";
                                                      await canLaunchUrlString(url) ?
                                                      await launchUrlString(url) :
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to launch')));
                                                    },
                                                    child: const Icon(Icons.phone, color: Colors.green, size: 35,))
                                              ],
                                            )
                                          ],
                                        )),
                            ))
                        : const SizedBox(),
                  ],
                ),
              ));
  }

  getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Future.error('Location permissions are denied forever.');
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);
    // setState(() {
    //   latLng = latLngPosition;
    // });
    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 14);
    _newMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    // ignore: use_build_context_synchronously
    await GoogleMapsResponse.searchCoordinateAddress(position, context);
  }

  getPlaceDirection() async {
    Address? pickUpAddress =
        Provider.of<DataProvider>(context, listen: false).userPickUpAddress;
    Address? dropOffAddress =
        Provider.of<DataProvider>(context, listen: false).dropOffAddress;

    LatLng pickUpLatLng =
        LatLng(pickUpAddress!.latitude!, pickUpAddress.longitude!);
    LatLng dropOffLatLng =
        LatLng(dropOffAddress!.latitude!, dropOffAddress.longitude!);

    directionDetails = await GoogleMapsResponse.obtainPlaceDirectionDetails(
        pickUpLatLng, dropOffLatLng);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodePolyLinePointsResult =
        polylinePoints.decodePolyline(directionDetails!.encodedPoints!);

    polyLineCoordinates.clear();
    for (PointLatLng pointLatLng in decodePolyLinePointsResult) {
      polyLineCoordinates
          .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
    }
    Marker pickUpMarker = Marker(
        markerId: const MarkerId('pickUpMarker'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow:
            InfoWindow(title: pickUpAddress.placeName, snippet: 'My Location'),
        position: pickUpLatLng);
    Marker dropOfMarker = Marker(
        markerId: const MarkerId('dropOfMarker'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
            title: dropOffAddress.placeName, snippet: 'DropOff Location'),
        position: dropOffLatLng);
    Circle pickUpCircle = Circle(
        circleId: const CircleId('pickUpCircle'),
        fillColor: Colors.white,
        center: pickUpLatLng,
        radius: 12,
        strokeWidth: 10,
        strokeColor: Colors.white,
        visible: true);
    Circle dropOfCircle = Circle(
      circleId: const CircleId('dropOfCircle'),
      fillColor: Colors.redAccent,
      center: dropOffLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.red,
    );

    polyLineSet.clear();
    setState(() {
      markerSet.add(pickUpMarker);
      markerSet.add(dropOfMarker);
      circleSet.add(pickUpCircle);
      circleSet.add(dropOfCircle);
      Polyline polyline = Polyline(
          polylineId: const PolylineId('polyLineId'),
          color: Colors.pink,
          jointType: JointType.round,
          points: polyLineCoordinates,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true);
      polyLineSet.add(polyline);
    });

    LatLngBounds? latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }
    Future.delayed(
      const Duration(seconds: 1),
      () {
        _newMapController!
            .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds!, 50));
      },
    );
  }

  Future<int> calculateRideFares(
      DirectionDetails directionDetails, int index) async {
    // showDialog(context: context, builder: (context) => ProgressDialog(dialogText: 'wait...'),);
    double timeTravelFares = (directionDetails.durationValue! / 60) * 0.05;
    double distanceTravelFares =
        (directionDetails.distanceValue! / 1000) * 0.05;
    // print('duration : ${directionDetails.durationValue} ${directionDetails.durationText}');
    // print('distance : ${directionDetails.distanceValue} ${directionDetails.distanceText}');
    // double usdToPkr = await CurrencyResponse.getUSDToPKRRate();
    double totalAmount = (timeTravelFares + distanceTravelFares) * 285;
    await Future.delayed(
      const Duration(milliseconds: 500),
    );
    if (index == 0) {
      return totalAmount.toInt();
    } else if (index == 1) {
      return (totalAmount *= 1.1).toInt();
    } else if (index == 2) {
      return (totalAmount *= 1.3).toInt();
    } else if (index == 3) {
      return (totalAmount *= 1.4).toInt();
    }
    return totalAmount.toInt();
  }

  cancelDirections() {
    setState(() {
      drawerOpen = true;
      selectedVehicleIndex = 0;
      _faresTextEditingController.clear();
      findDriverBtn = true;
      showSearchContainer = true;

      markerSet.clear();
      circleSet.clear();
      polyLineSet.clear();
      polyLineCoordinates.clear();
    });
  }

  getNearByVehicles() async{
    DatabaseReference databaseReference =
        FirebaseDatabase.instance.ref().child('active_drivers');

    print('current position : ${currentPosition!.latitude}');
    databaseReference
        .orderByChild('latitude')
        .startAt(currentPosition!.latitude - 0.027027)
        .endAt(currentPosition!.latitude + 0.027027)
        .onValue
        .listen((event) async {
      DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        List<AvailableDriver> list = [];
        Set<Marker> driversMarkerSet = <Marker>{};
        print('snapshot value : ${snapshot.value}');
        print(currentPosition);
        Map map = snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          list.add(AvailableDriver.getAvailableDriverFromMap(value));
        });

        for (AvailableDriver availableDriver in list) {
          if (availableDriver.longitude >
                  (currentPosition!.longitude - 0.027027) &&
              availableDriver.longitude <
                  (currentPosition!.longitude + 0.027027)) {
            LatLng latLng =
                LatLng(availableDriver.latitude, availableDriver.longitude);
            Marker marker = Marker(
              markerId: MarkerId('driver${availableDriver.uid}'),
              position: latLng,
              icon: nearbyIcon!,
            );
            driversMarkerSet.add(marker);
          }
        }
        await Future.delayed(const Duration(seconds: 1)).then((value) {
          setState(() {
            markerSet = driversMarkerSet;
          });
        });

      }
    });
  }

  getBytesFromAsset() async {
    ByteData data = await rootBundle.load('images/car.png');
    Codec codec =
        await instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 80);
    FrameInfo fi = await codec.getNextFrame();

    Uint8List markerIcon =
        (await fi.image.toByteData(format: ImageByteFormat.png))!
            .buffer
            .asUint8List();
    setState(() {
      nearbyIcon = BitmapDescriptor.fromBytes(markerIcon);
    });
  }

}
