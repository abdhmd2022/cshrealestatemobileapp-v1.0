import 'package:cshrealestatemobile/MaintenanceTicketCreation.dart';
import 'package:cshrealestatemobile/SalesDashboard.dart';
import 'package:cshrealestatemobile/TenantDashboard.dart';
import 'package:flutter/material.dart';
import 'Sidebar.dart';

class MaintenanceTicketReport extends StatefulWidget {
  @override
  _MaintenanceTicketReportState createState() =>
      _MaintenanceTicketReportState();
}

class _MaintenanceTicketReportState
    extends State<MaintenanceTicketReport> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> tickets = [
    {
      'ticketNumber': 'MT-001',
      'unitNumber': '101',
      'buildingName': 'Al Khaleej Center',
      'emirate': 'Dubai',
      'status': 'In Progress',
      'date': '24-12.2024',
      'maintenanceType': 'Electrical',
      'description': 'Fixing electrical wiring in the unit.',
    },
    {
      'ticketNumber': 'MT-002',
      'unitNumber': '402',
      'buildingName': 'Al Musalla Tower',
      'emirate': 'Dubai',
      'status': 'Resolved',
      'date': '20-12-2024',
      'maintenanceType': 'Carpentry',
      'description': 'Fixing the wooden door and frame.',
    },
  ];

  List<Map<String, dynamic>> filteredTickets = [];
  String searchQuery = "";

  List<bool> _expandedTickets = [];

  @override
  void initState() {
    super.initState();
    // Initialize all tickets to be collapsed by default
    _expandedTickets = List.generate(tickets.length, (index) => false);
    filteredTickets = tickets;
  }

  void _updateSearchQuery(String query) {
    setState(() {
      searchQuery = query;
      filteredTickets = tickets
          .where((ticket) =>
      ticket['ticketNumber'].toLowerCase().contains(query.toLowerCase()) ||
          ticket['unitNumber'].toLowerCase().contains(query.toLowerCase()) ||
          ticket['buildingName'].toLowerCase().contains(query.toLowerCase()) ||
          ticket['emirate'].toLowerCase().contains(query.toLowerCase()) ||
          ticket['status'].toLowerCase().contains(query.toLowerCase()) ||
          ticket['maintenanceType'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search Ticket',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
        leading: GestureDetector(
          onTap: ()
          {
            Navigator.of(context).pop();
          },
          child: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),),

        backgroundColor: Colors.blueGrey,
        centerTitle: true,
        title: Text(
          'Maintenance Tickets',
          style: TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 20.0,
            color: Colors.white,
          ),
        ),
      ),
      drawer: Sidebar(
          isDashEnable: true,
          isRolesVisible: true,
          isRolesEnable: true,
          isUserEnable: true,
          isUserVisible: true,
          Username: "",
          Email: "",
          tickerProvider: this),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          itemCount: filteredTickets.length,
          itemBuilder: (context, index) {
            final ticket = filteredTickets[index];
            return _buildTicketCard(ticket, index);
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey, Colors.blueGrey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MaintenanceTicketCreation()),

            );
          },
          label: Text(
            'New Ticket',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          icon: Icon(Icons.add, color: Colors.white),
          backgroundColor: Colors.transparent,
          elevation: 8,
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedTickets[index] = !_expandedTickets[index];
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10.0,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTicketHeader(ticket),
            Divider(color: Colors.grey[300]),
            _buildTicketDetails(ticket),



            if (_expandedTickets[index])
              _buildExpandedTicketView(ticket),
            SizedBox(height: 10), // Top space before the toggle
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _expandedTickets[index] = !_expandedTickets[index];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                  decoration: BoxDecoration(
                      color: Colors.transparent

                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expandedTickets[index] ? "View Less" : "View More",
                        style: TextStyle(
                          color: Colors.black26,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        _expandedTickets[index] ? Icons.expand_less : Icons.expand_more,
                        color: Colors.black26,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildTicketHeader(Map<String, dynamic> ticket) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.confirmation_number, color: Colors.teal, size: 24.0),
            SizedBox(width: 8.0),
            Text(
              ticket['ticketNumber'],
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        _getStatusBadge(ticket['status']),
      ],
    );
  }

  Widget _buildTicketDetails(Map<String, dynamic> ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Unit:', ticket['unitNumber']),
        _buildInfoRow('Building:', ticket['buildingName']),
        _buildInfoRow('Emirate:', ticket['emirate']),
        _buildInfoRow('Type:', ticket['maintenanceType']),
        _buildInfoRow('Date:', ticket['date']),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child:Text(
                value,
                style: TextStyle(
                  color: Colors.black87,
                ),

              ) ,
            )
          ),
        ],
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'In Progress':
        color = Colors.orange;
        break;
      case 'Resolved':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildExpandedTicketView(Map<String, dynamic> ticket) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Description:', ticket['description']),

        ],
      ),
    );
  }

}
