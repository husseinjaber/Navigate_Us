import 'package:cloud_firestore/cloud_firestore.dart';


class DataBaseService {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<QuerySnapshot<Map<String, dynamic>>> GetAllUsersLocation() async{

       return await firestore.collection("UsersLocation").get();

  }




    SendMyLocation(String privateId,String Location){

       firestore.collection("UsersLocation").doc(privateId).set(
         {
           "Location":Location,
         }
       );
  }

}
