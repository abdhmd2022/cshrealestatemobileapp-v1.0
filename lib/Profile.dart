import 'package:cshrealestatemobile/MaintenanceTicketCreation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'constants.dart';

class Profile extends StatefulWidget {

  @override
  State<Profile> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<Profile> {

  @override
  void initState() {
    super.initState();

    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: GestureDetector(

            onTap: ()
            {
              Navigator.of(context).pop();

            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          title: Text(app_name,
            style: TextStyle(
                color: Colors.white
            ),),
        ),
        body: SingleChildScrollView(
          child:  Container(
              width: MediaQuery.of(context).size.width,

              child: Card(
                  margin: EdgeInsets.only(left: 20,right: 20,top: 30,bottom: 30),
                  surfaceTintColor: Theme.of(context).colorScheme.surface,
                  elevation: 8,

                  child: Container(

                    padding:EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 7.5,),
                          child:Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Name: ",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                ),),

                              Flexible(child: Text('value',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16

                                ),),)

                            ],)
                          ,),

                        Container(
                          margin: EdgeInsets.only(bottom: 7.5,),

                          child:Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Apartment No: ",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                ),),

                              Flexible(child: Text('value',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16

                                ),),)

                            ],)
                          ,),

                        Container(
                          margin: EdgeInsets.only(bottom: 7.5,),

                          child:Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Contract Expiry: ",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                ),),

                              Flexible(child: Text('value',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16

                                ),),)

                            ],)
                          ,),

                        Container(
                          margin: EdgeInsets.only(bottom: 7.5,),

                          child:Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Total Maintenance Tickets: ",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                ),),

                              Flexible(child: Text('value',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16

                                ),),)
                            ],)
                          ,),

                        Container(
                          margin: EdgeInsets.only(bottom: 7.5,),

                          child:Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Completed Maintenance Tickets: ",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                ),),

                              Flexible(child: Text('value',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16

                                ),),)
                            ],)
                          ,),

                        Container(
                          margin: EdgeInsets.only(bottom: 7.5,),

                          child:Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Pending Maintenance Tickets: ",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                ),),

                              Flexible(child: Text('value',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16
                                ),),)
                            ],)
                          ,),

                        Container(
                          margin: EdgeInsets.only(bottom: 7.5,),

                          child:Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Total Cheques: ",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                ),),

                              Flexible(child: Text('value',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16
                                ),),)
                            ],)
                          ,),

                        Container(
                          margin: EdgeInsets.only(bottom: 7.5,),

                          child:Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("No. of Cheques Cleared: ",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                ),),

                              Flexible(child: Text('value',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16

                                ),),)
                            ],)
                          ,),

                        Container(
                          margin: EdgeInsets.only(bottom: 7.5,),

                          child:Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("No. of Cheques Pending: ",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                ),),

                              Flexible(child: Text('value',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16

                                ),),)

                            ],)
                          ,),

                        Container(
                          margin: EdgeInsets.only(bottom: 7.5,),

                          child:Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Last Cheque Cleared Date: ",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                ),),

                              Flexible(child: Text('value',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16
                                ),),)
                            ],)
                          ,),

                        Container(
                          margin: EdgeInsets.only(bottom: 7.5,),

                          child:Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Next Cheque Due On: ",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                ),),

                              Flexible(child: Text('value',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16

                                ),),)
                            ],)
                          ,),

                        Container(
                          margin: EdgeInsets.only(bottom: 0,),

                          child:Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("No. of Parking's Occupied: ",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16
                                ),),

                              Flexible(child: Text('value',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16

                                ),),)
                            ],)
                        ),
                      ],
                    ),
                  )
              )) ,
        )
    );}}
