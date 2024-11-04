import 'package:cshrealestatemobile/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
            child: Column(
                children: [

                  Text("Ticket Creation"),

                  SizedBox(height: 10,),

                  Text("Create your maintenance ticket"),

                  SizedBox(height: 10),

                  ListView.builder(
                  itemCount: checkboxtitles.length,
                      shrinkWrap: true,

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

                  SizedBox(height: 10),

                  Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[

                    Text("Description:"),

                    SizedBox(height:2),

                    Container(
                        margin: EdgeInsets.only(
                            top:10,
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

                        Text("Total Amount:"),

                        SizedBox(height:2),

                        Container(
                            margin: EdgeInsets.only(
                                top:10,
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
                      ])
                ]))
    );}}
