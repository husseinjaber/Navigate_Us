import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'db.dart';
// import 'package:flutter_map/flutter_map.dart';
// // import 'package:latlng/latlng.dart';
// import 'package:latlong2/latlong.dart' as latLng;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoder/geocoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_google_places/flutter_google_places.dart';
// import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Navigate Me',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Navigate Us',),

    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  DataBaseService dataBaseService = new DataBaseService();
  String PrivateId ="";
  String MyLocation="";

  String BTN1TEXT = 'Find Meeting Point';
  late GoogleMapController _controller ;

  List<Address> results = [];
  Set<Marker> _markers={};

  Timer? timer;


  List<LatLng> MeetingPoints = [];
  List<LatLng> StartPoints = [];
  List<LatLng> UsersPoints = [];
  late LatLng MyLocationLatLng;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    CheckId();
    changeImagesToBitmap();
    AddIntialPoints();

    GetUsersLocation();

    timer = Timer.periodic(const Duration(seconds: 5), (Timer t) => getCurrentLocation());


  }

  @override
  void dispose(){
    timer?.cancel();
    super.dispose();
}



  void GetUsersLocation() async{
     await dataBaseService.GetAllUsersLocation().then((value) => DisplayAllUsers(value));
  }

  DisplayAllUsers(QuerySnapshot<Map<String, dynamic>> Users){
    for(int i=0;i<Users.size;i++){
      if(Users.docs[i].id!=PrivateId){
        String Temp= Users.docs[i].data()["Location"];
        // print (Temp);
        var splitted = Temp.split(",");
        double lat = double.parse(splitted[0]);
        double lng = double.parse(splitted[1]);
        // double.parse('1.1');
        UsersPoints.add(LatLng(lat, lng));
      }
    }
    getCurrentLocation();
  }

  late BitmapDescriptor customAssetsPin ;
  late BitmapDescriptor customAssetsFlag ;
  late BitmapDescriptor customAssetsLocation ;
  late BitmapDescriptor customAssetsUsers ;

  changeImagesToBitmap(){

    getBytesFromAsset('lib/assets/pin.png', 80).then((onValue) {
      customAssetsPin =BitmapDescriptor.fromBytes(onValue);

    });
       getBytesFromAsset('lib/assets/flag.png', 80).then((onValue) {
         customAssetsFlag =BitmapDescriptor.fromBytes(onValue);

    });
       getBytesFromAsset('lib/assets/location.png', 80).then((onValue) {
         customAssetsLocation =BitmapDescriptor.fromBytes(onValue);

    });
    getBytesFromAsset('lib/assets/user.png', 80).then((onValue) {
      customAssetsUsers =BitmapDescriptor.fromBytes(onValue);

    });

  }

  static Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  AddIntialPoints(){
    MeetingPoints.add(const LatLng(47.653839737122505, 6.86737729617935));
    MeetingPoints.add(const LatLng(47.63923277206831, 6.863572781610977));
    MeetingPoints.add(const LatLng(47.49443497847347, 6.801736362336341));
    MeetingPoints.add(const LatLng(47.49713662355553, 6.83381702157399));

    StartPoints.add(const LatLng(47.510721803052625, 6.801545199876815));
    StartPoints.add(const LatLng(47.63461352984286, 6.844004018927421));

  }


  getLocation() async
  {
    // _markers={};
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      MyLocationLatLng = LatLng(position.latitude, position.longitude);
      MyLocation = position.latitude.toString()+","+position.longitude.toString();
      // print("-------Mylocation: " +MyLocationLatLng.latitude.toString()+" "+MyLocationLatLng.longitude.toString());

      SendMyLocation();
      LatLng latlong=new LatLng(position.latitude, position.longitude);
      // adding marker on my location
      _markers.add(Marker(markerId: MarkerId("MyLocation"),draggable:true,position: latlong,
          icon: customAssetsPin,

      ));

      // adding markers on meeting point
      for(int i=0;i<MeetingPoints.length;i++){
        _markers.add(Marker(markerId: MarkerId("MeetingPoints"+i.toString()),draggable:true,position: MeetingPoints[i],
          icon:customAssetsFlag,
        ));
      }

      //adding markers on start points
      print("StartPoints Length: "+StartPoints.length.toString());
      for(int i=0;i<StartPoints.length;i++){
        _markers.add(Marker(markerId: MarkerId("StartPints"+i.toString()),draggable:true,position: StartPoints[i],
          icon:customAssetsLocation,

        ));
      }

      //adding markers on all users
      for(int i=0;i<UsersPoints.length;i++){
        _markers.add(Marker(markerId: MarkerId("UsersPoints"+i.toString()),draggable:true,position: UsersPoints[i],
          icon:customAssetsUsers,
          // BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      }




    });
  }

  Future getCurrentLocation() async {
    // GetUsersLocation();
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission != PermissionStatus.granted) {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission != PermissionStatus.granted)
        getLocation();
      return;
    }
    getLocation();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          child: Column(
            children: [
              Flexible(
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target:LatLng(47.5707735914572, 6.835046122977794),
                    zoom: 11.5,
                  ),
                  onMapCreated: (GoogleMapController controller){
                    _controller=(controller);
                  },
                  markers:_markers ,
                  polylines: Set<Polyline>.of(polylines.values),
                  onCameraIdle: (){
                  setState(() {

                  });

                  },

                // layers: [
                //
                // ],

            ),
              ),
            ]
          ),
        ),
      ),

      // floatingActionButtonLocation:
      // FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: FloatingActionButton.extended(
      //
      //   onPressed: (){},
      //
      //   label: Container(
      //     // color: Colors.blue,
      //     width: 200,
      //     height: 50,
      //     decoration: BoxDecoration(borderRadius: BorderRadius.circular(3),color: Colors.blue),
      //     child: FittedBox(
      //       child: Text(BTN1TEXT,style:const TextStyle(fontSize: 20,color: Colors.white),),
      //     ),
      //   ),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
      persistentFooterButtons: [
        Center(
          child: InkWell(
            onTap: (){
              // dataBaseService.SendMyLocation(PrivateId,MyLocation);
              // print("Mylocation: " +MyLocationLatLng.latitude.toString()+" "+MyLocationLatLng.longitude.toString());
              // print("End: " +MeetingPoints[3].latitude.toString()+" "+MeetingPoints[3].longitude.toString());
              // _getPolyline(MyLocationLatLng,MeetingPoints[3]);
                FindMeetingPoint();
            },
            child: Container(
            // color: Colors.blue,
            width: 150,
            height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(3),color: Colors.blue),
            child: FittedBox(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(5, 1, 5, 1),
                  child: Text(BTN1TEXT,style:const TextStyle(fontSize: 20,color: Colors.white,),)),
            ),

      ),
          ),
        ),

      ],
    );




  }


  void SendMyLocation() async{
    await dataBaseService.SendMyLocation(PrivateId,MyLocation);
  }


  //checking local storage for user id, if not found we create it

  void CheckId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String UserPersonalId = prefs.getString('PersonalID').toString();

    if (UserPersonalId!= "null") {
      setState(() {
        PrivateId = UserPersonalId;
      });
      return;
    }else{
      PrivateId=getRandomString(15);
      prefs.setString('PersonalID', PrivateId);
    }

  }

  //Random Generator

  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final math.Random _rnd = math.Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));




  //for Meeting Point
  List<List<List<double>>> MyMatrix = [];

  FindMeetingPoint() {
    MyMatrix = [];
    List<List<double>> Temp = [];
    List<double> TempInside = [];
    // for me

    for(int i = 0; i < MeetingPoints.length;i++){
      TempInside = [];
      double firstDist =  CalculateDistanceOf2Points(MyLocationLatLng, MeetingPoints[i]);
      double secondDist =  CalculateDistanceOf2Points(MyLocationLatLng, StartPoints[0])  + CalculateDistanceOf2Points(MeetingPoints[i], StartPoints[1]) ;
      double thirdDist =  CalculateDistanceOf2Points(MyLocationLatLng, StartPoints[1])  + CalculateDistanceOf2Points(MeetingPoints[i], StartPoints[0]) ;
      if(firstDist<secondDist && firstDist <thirdDist){
        TempInside.add(0);
        TempInside.add(firstDist);
      }else if(secondDist<thirdDist && secondDist < firstDist){
        TempInside.add(1);
        TempInside.add(secondDist);
      }else if (thirdDist<secondDist && thirdDist <firstDist){
        TempInside.add(2);
        TempInside.add(thirdDist);
      }
      Temp.add(TempInside);
      if(i == MeetingPoints.length -1){
        MyMatrix.add(Temp);
      }
    }
    Temp = [];
    // for other users

    for(int j=0;j<UsersPoints.length;j++){
      Temp = [];
      for(int i = 0; i < MeetingPoints.length;i++){
        TempInside = [];
        double firstDist =  CalculateDistanceOf2Points(UsersPoints[j], MeetingPoints[i]);
        double secondDist =  CalculateDistanceOf2Points(UsersPoints[j], StartPoints[0])  + CalculateDistanceOf2Points(MeetingPoints[i], StartPoints[1]) ;
        double thirdDist =  CalculateDistanceOf2Points(UsersPoints[j], StartPoints[1])  + CalculateDistanceOf2Points(MeetingPoints[i], StartPoints[0]) ;
        if(firstDist<secondDist && firstDist <thirdDist){
          TempInside.add(0);
          TempInside.add(firstDist);
        }else if(secondDist<thirdDist && secondDist < firstDist){
          TempInside.add(1);
          TempInside.add(secondDist);
        }else if (thirdDist<secondDist && thirdDist <firstDist){
          TempInside.add(2);
          TempInside.add(thirdDist);
        }
        Temp.add(TempInside);
        if(i == MeetingPoints.length -1){
          MyMatrix.add(Temp);
        }
      }
    }
    print(MyMatrix);
    LatLng CenterOfUsers = getCenterLatLong(UsersPoints);
    // for(int i=0;i<UsersPoints.length,i++)
    int MeetingId=0;
    double tempdistance=1000000;
    for(int i=0;i<MeetingPoints.length;i++){
      if(CalculateDistanceOf2Points(CenterOfUsers, MeetingPoints[i]) < tempdistance) {
        tempdistance = CalculateDistanceOf2Points(CenterOfUsers, MeetingPoints[i]);
        MeetingId = i;
      }
    }

    _markers.add(Marker(markerId: MarkerId("MeetingPoints"+MeetingId.toString()),draggable:true,position: MeetingPoints[MeetingId],
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      // customAssetsFlag,
    ));
    setState(() {});

    double pathOfUser = MyMatrix[0][MeetingId][0];

    if(pathOfUser==0){
      _getPolyline(MyLocationLatLng,MeetingPoints[MeetingId]);
    }else if(pathOfUser == 1){
      _getPolyline(MyLocationLatLng,StartPoints[0]);
      _getPolyline(StartPoints[0],StartPoints[1]);
      _getPolyline(MeetingPoints[MeetingId],StartPoints[1]);
    }else if(pathOfUser == 2){
      _getPolyline(MyLocationLatLng,StartPoints[1]);
      _getPolyline(StartPoints[0],StartPoints[1]);
      _getPolyline(MeetingPoints[MeetingId],StartPoints[0]);
    }


    for(int i=0;i<UsersPoints.length;i++){
      double pathOfUser = MyMatrix[i+1][MeetingId][0];

      if(pathOfUser==0){
        _getPolyline(UsersPoints[i],MeetingPoints[MeetingId]);
      }else if(pathOfUser == 1){
        _getPolyline(UsersPoints[i],StartPoints[0]);
        _getPolyline(StartPoints[0],StartPoints[1]);
        _getPolyline(MeetingPoints[MeetingId],StartPoints[1]);
      }else if(pathOfUser == 2){
        _getPolyline(UsersPoints[i],StartPoints[1]);
        _getPolyline(StartPoints[0],StartPoints[1]);
        _getPolyline(MeetingPoints[MeetingId],StartPoints[0]);
      }
    }

  }



  //calculate distance
  double CalculateDistanceOf2Points(LatLng First, LatLng Second) {
    return  Geolocator.distanceBetween(
      First.latitude,
      First.longitude,
      Second.latitude,
      Second.longitude,
    ).abs();
  }


  LatLng getCenterLatLong(List<LatLng> latLongList) {
    double pi = math.pi / 180;
    double xpi = 180 / math.pi;
    double x = 0, y = 0, z = 0;

    if(latLongList.length==1)
    {
      return latLongList[0];
    }
    for (int i = 0; i < latLongList.length; i++) {
      double latitude = latLongList[i].latitude * pi;
      double longitude = latLongList[i].longitude * pi;
      double c1 = math.cos(latitude);
      x = x + c1 * math.cos(longitude);
      y = y + c1 * math.sin(longitude);
      z = z + math.sin(latitude);
    }

    int total = latLongList.length;
    x = x / total;
    y = y / total;
    z = z / total;

    double centralLongitude = math.atan2(y, x);
    double centralSquareRoot = math.sqrt(x * x + y * y);
    double centralLatitude = math.atan2(z, centralSquareRoot);

    return LatLng(centralLatitude*xpi,centralLongitude*xpi);
  }

  //for paths

  DrawAllPaths(){

  }

  Map<PolylineId, Polyline> polylines = {};

  PolylinePoints polylinePoints = PolylinePoints();

  _addPolyLine(List<LatLng> polylineCoordinates) {

    PolylineId id = PolylineId(getRandomString(8));
    Polyline polyline = Polyline(
      polylineId: id,
      points: polylineCoordinates,
      width: 4,
      color: Colors.pink
    );
    polylines[id] = polyline;
    setState(() {});
  }

  void _getPolyline(LatLng first, LatLng last) async {
    List<LatLng> polylineCoordinates = [];

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      "AIzaSyCkmyOs51_MDXRDLLSoRYrjd3Q4LQBvqPA",
      PointLatLng(first.latitude, first.longitude),
      PointLatLng(last.latitude, last.longitude),
      travelMode: TravelMode.walking,
    );


    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }

    _addPolyLine(polylineCoordinates);
  }

}







