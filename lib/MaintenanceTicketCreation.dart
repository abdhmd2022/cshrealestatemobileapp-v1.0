import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'Login.dart';

class MaintenanceTicketCreation extends StatefulWidget
{
  const MaintenanceTicketCreation({Key? key}) : super(key: key);
  @override
  _MaintenanceTicketCreationPageState createState() => _MaintenanceTicketCreationPageState();
}


class _MaintenanceTicketCreationPageState extends State<MaintenanceTicketCreation> {

  int? selectedCheckboxIndex; // Holds the index of the selected checkbox
  final List<String> checkboxtitles = [
    'Electrical Works',
    'A/C Works',
    'Plumbing Works',
    'Paint Works',
    'Pest Control',
    'Tile Works',
    'Others'
  ]; // List of custom titles

  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _totalamountController = TextEditingController();

  // Function to handle checkbox selection
  void _onCheckboxChanged(int index) {
    setState(() {
      selectedCheckboxIndex = index;
    });
  }

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
          ),),

          title: Text(app_name,
            style: TextStyle(
                color: Colors.white
            ),),
        ),
        body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            /*decoration:BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Color(0xFFD9FCF6),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter
              ),
            ),*/
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      margin: EdgeInsets.only(left: 20,right: 20,bottom: 3,top: 20),
                      child: Text("Ticket Creation",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28
                      ),)
                    ),

                    Container(
                      margin: EdgeInsets.only(left: 20,right: 20,bottom: 30),
                      child: Text("Create your maintenance ticket",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54
                      ),),
                    ),


                    Container(

                      padding: EdgeInsets.all(20),

                      decoration: BoxDecoration(
                        color: Colors.black12,

                          borderRadius: BorderRadius.circular(10)

                      ),
                      width: MediaQuery.of(context).size.width,

                      margin: EdgeInsets.only(left: 20,right: 20),

                        child:  Column(
                          children: [

                          Container(
                            margin: EdgeInsets.only(bottom: 5,),

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
                              margin: EdgeInsets.only(bottom: 5),
                              child: Row(
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

                                  ),))
                              ],),),

                          Container(margin: EdgeInsets.only(bottom: 5),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text("Maintenance: ",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16

                              ),),

                            Flexible(child: Text('value',
                              style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 16

                              ),),)
                          ],),),

                          Container(child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Text("Building Name: ",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16

                                ),),

                              Flexible(child: Text('value',
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 16

                                ),),)
                            ],),)
                        ],)
                      ),

                    Container(
                      margin: EdgeInsets.only(left:20, right:20, top: 20,bottom: 0),
                      child: Text('Maintenance Type:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                          fontSize: 16

                      ),),),

                    ListView.builder(
                        itemCount: checkboxtitles.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),

                        itemBuilder: (context, index) {
                          return CheckboxListTile(
                            activeColor: Colors.black,
                            title: Text(checkboxtitles[index]), // Use custom title from the list
                            value: selectedCheckboxIndex == index,
                            onChanged: (bool? newValue) {
                              _onCheckboxChanged(index);
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          );}),

                    Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[

                          Container(
                            margin: EdgeInsets.only(
                                top:0,
                                bottom: 2,
                                left: 20,
                                right: 20
                            ),
                            child: Text("Description:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16

                                )
                            ),
                          ),

                          Container(
                              margin: EdgeInsets.only(
                                  top:0,
                                  bottom: 20,
                                  left: 20,
                                  right: 20
                              ),
                              child: TextField(
                                  controller: _descriptionController,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,

                                  decoration: InputDecoration(
                                    hintText: 'Enter Description',
                                    contentPadding: EdgeInsets.all(15),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10), // Set the border radius
                                      borderSide: BorderSide(
                                        color: Colors.black, // Set the border color
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:  Colors.black, // Set the focused border color
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                  ))),
                        ]),

                    SizedBox(height: 10),

                    Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:[

                          Container(
                            margin: EdgeInsets.only(
                                top:0,
                                bottom: 2,
                                left: 20,
                                right: 20
                            ),
                            child: Text("Total Amount:",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16

                                )
                            ),),

                          Container(
                              margin: EdgeInsets.only(
                                  top:0,
                                  bottom: 20,
                                  left: 20,
                                  right: 20
                              ),
                              child: TextField(
                                  controller: _totalamountController,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,

                                  decoration: InputDecoration(
                                    hintText: 'Enter Amount',
                                    contentPadding: EdgeInsets.all(15),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10), // Set the border radius
                                      borderSide: BorderSide(
                                        color: Colors.black, // Set the border color
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color:  Colors.black, // Set the focused border color
                                      ),
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                  ))),
                        ]),


                    Container(
                      width: MediaQuery.of(context).size.width,
                      margin: EdgeInsets.only(left: 20,right: 20,top: 20,bottom: 80),
                      child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        elevation: 5, // Adjust the elevation to make it look elevated
                        shadowColor: Colors.black.withOpacity(0.5), // Optional: adjust the shadow color
                      ),
                      onPressed: () {
                        {

                        }
                      },
                      child: Text('Submit',
                          style: TextStyle(
                              color: Colors.white
                          )),
                    ),)

                  ])
            )
            )

    );}}
