import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:assignment/auth_service.dart';
import 'package:assignment/login_screen.dart';
import 'package:assignment/customer.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'database_helper.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with RouteAware {
  final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
  List<Map<String, dynamic>> _attendanceRecords = [];
  DatabaseHelper dbHelper = DatabaseHelper();
  bool _isLoading = true;



  final AuthService _authService = AuthService();
  SharedPreferences? _prefs;
  String? _userName;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadLoginResponse();
    _fetchAttendanceRecords();

  }

  Future<void> _loadLoginResponse() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = _prefs?.getString('PREFS_USER_NAME');
      _userEmail = _prefs?.getString('PREFS_USER_EMAIL');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    RouteObserver<ModalRoute<void>>().subscribe(this, ModalRoute.of(context)!);
    _fetchAttendanceRecords();
  }

  @override
  void dispose() {
    RouteObserver<ModalRoute<void>>().unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when the current route has been popped back to.
    _fetchAttendanceRecords();  // Fetch the records again when returning to this screen.
  }

  Future<File> _getImageFile(String imagePath) async {
    Directory directory = await getApplicationDocumentsDirectory();
    String fullPath = path.join(directory.path, path.basename(imagePath));

    // Return the File instance for the image
    return File(fullPath);
  }


  Future<void> _fetchAttendanceRecords() async {
    try {
      List<Map<String, dynamic>> records = await dbHelper.getAttendanceRecords();
      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });
      // Debugging: Print the image paths to verify they are correct
      for (var record in records) {
        print('Fetched image path: ${record['Customer_Image']}');
        if (record['Customer_Image'] != null && record['Customer_Image'].isNotEmpty) {
          String imagePath = record['Customer_Image'];

          try {
            File imageFile = await _getImageFile(imagePath);
            bool exists = await imageFile.exists();
            print('Image file exists: $exists');

            if (exists) {
              // You can now use imageFile to display the image in your UI
            } else {
              print('Image file not found at $imagePath');
            }
          } catch (e) {
            print('Error accessing image file: $e');
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching customer records: $e')),
      );
    }
  }



  Future<bool> _onBackPressed() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Exit"),
        content: Text("Are you sure you want to exit the app?"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Yes"),
          ),
        ],
      ),
    ).then((value) => value ?? false);
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFF5E69EE),
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Customers List"),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Logout"),
                      content: Text("Are you sure you want to logout?"),
                      actions: [
                        TextButton(
                          child: Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text("Logout"),
                          onPressed: () async {
                            Navigator.of(context).pop(); // Close the dialog
                            await _authService.logout();
                            Fluttertoast.showToast(
                              msg: "Logged out successfully",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              timeInSecForIosWeb: 1,
                              fontSize: 16.0,
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),

        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: _attendanceRecords.isEmpty
                    ? Center(child: Text("No Customer records found."))
                    : ListView.builder(
                  itemCount: _attendanceRecords.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> record = _attendanceRecords[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image Section with Padding
                            Padding(
                              padding: const EdgeInsets.all(8.0), // Padding around the image
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: record['Customer_Image'] != null
                                        ? FutureBuilder<File>(
                                      future: _getImageFile(record['Customer_Image']),
                                      builder: (BuildContext context, AsyncSnapshot<File> snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return SizedBox(
                                            width: 120,
                                            height: 120,
                                            child: Center(child: CircularProgressIndicator()),
                                          );
                                        } else if (snapshot.hasError) {
                                          return SizedBox(
                                            width: 120,
                                            height: 120,
                                            child: Center(child: Text('Error loading image')),
                                          );
                                        } else if (snapshot.hasData && snapshot.data != null) {
                                          return Image.file(
                                            snapshot.data!,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          );
                                        } else {
                                          return Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Image.network(
                                              'https://via.placeholder.com/150',
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        }
                                      },
                                    )
                                        : Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.network(
                                        'https://via.placeholder.com/150',
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8), // Space between image and map icon
                                  IconButton(
                                    icon: Icon(
                                      Icons.location_on,
                                      color: Colors.green, // Customize icon color
                                      size: 24, // Customize icon size
                                    ),
                                    onPressed: () {
                                      final lat = double.tryParse(record['Lat'] ?? '0') ?? 0;
                                      final long = double.tryParse(record['Long'] ?? '0') ?? 0;

                                    },
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(width: 16), // Spacing between image and details
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFC5CAE9),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              record['Customer_Name'] ?? 'Customer Name',
                                              style: TextStyle(
                                                color: Color(0xFF1A237E),
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Mobile No.: ${record['Mobile'] ?? 'No Mobile'}",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Email Id: ${record['Email'] ?? 'No Email'}",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Address: ${record['Address'] ?? 'No Address'}",
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Lat Long: ${record['Lat'] ?? 'No Lat'} ${record['Long'] ?? 'No Long'}",
                                      style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.w500),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Geo Address: ${record['Geo_Address'] ?? 'No Geo Address'}",
                                      style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),




        bottomNavigationBar: BottomAppBar(
          shape: CircularNotchedRectangle(),
          color: Color(0xFF5E69EE),
          child: Container(height: 30.0),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: SpeedDial(
          icon: Icons.add,
          backgroundColor: Colors.deepOrangeAccent,
          children: [
            SpeedDialChild(
              child: Image.asset(
                'assets/images/add.png',
                width: 120,
                height: 120,
              ),
              label: 'Add Customer',
              labelStyle: TextStyle(color: Colors.white),
              labelBackgroundColor: Color(0xFF5E69EE),
              backgroundColor: Colors.white,
              onTap: () {
                _navigateToPage(Attendance());
              },
            ),

          ],
        ),
      ),
    );
  }
}
