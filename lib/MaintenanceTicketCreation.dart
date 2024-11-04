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
            child:    Column(
                children: [

                  Text("Ticket Creation"),

                  SizedBox(height: 10,),

                  Text("Create your maintenance ticket"),

                  SizedBox(height: 10),

                  ListView.builder(
                  itemCount: checkboxtitles.length,
                  itemBuilder: (context, index) {
                  return CheckboxListTile(
                  title: Text(checkboxtitles[index]), // Use custom title from the list
                  value: selectedCheckboxIndex == index,
                  onChanged: (bool? newValue) {
                  _onCheckboxChanged(index);
                  },
                  );})
                ]))
    );}}
