import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // Import image picker package
import 'package:path/path.dart' as path; // For handling file paths
import 'package:path_provider/path_provider.dart'; // For getting directory
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Attendance extends StatefulWidget {
  @override
  _AttendanceState createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>(); // Form key for validation

  File? _image; // Variable to hold selected image
  String _imageSource = ''; // To hold the source of the image

  // Controllers for the text fields
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController latController = TextEditingController();
  final TextEditingController longController = TextEditingController();
  final TextEditingController geoAddressController = TextEditingController();
  final TextEditingController customerImageController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final name = path.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${directory.path}/$name');

      setState(() {
        _image = savedImage;
        _imageSource = source == ImageSource.camera ? 'camera' : 'gallery';
        customerImageController.text = savedImage.path; // Update controller with image path
      });
    }
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Photo Library'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      latController.text = position.latitude.toString();
      longController.text = position.longitude.toString();

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        geoAddressController.text = '${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}';
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location')),
      );
    }
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState?.validate() ?? false) {
      Map<String, dynamic> customer = {
        'Customer_Name': customerNameController.text,
        'Mobile': mobileController.text,
        'Email': emailController.text,
        'Address': addressController.text,
        'Lat': latController.text,
        'Long': longController.text,
        'Geo_Address': geoAddressController.text,
        'Customer_Image': customerImageController.text,
      };

      await _databaseHelper.insertCustomer(customer);

      // Clear the text fields after saving
      customerNameController.clear();
      mobileController.clear();
      emailController.clear();
      addressController.clear();
      latController.clear();
      longController.clear();
      geoAddressController.clear();
      customerImageController.clear();
      setState(() {
        _image = null; // Reset the image
      });

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Customer saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5E69EE),
        foregroundColor: Colors.white,
        title: Text("Add New Customer"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey, // Set the form key
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: customerNameController,
                  decoration: InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter customer name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: mobileController,
                  keyboardType: TextInputType.number, // Allow numeric input
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Allow only digits
                    LengthLimitingTextInputFormatter(10), // Limit input to 10 digits
                  ],
                  decoration: InputDecoration(
                    labelText: 'Mobile',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mobile number';
                    }
                    if (value.length != 10) {
                      return 'Mobile number must be 10 digits';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    // Regular expression for validating an email
                    String pattern =
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                    RegExp regex = RegExp(pattern);
                    if (!regex.hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: latController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.location_on),
                      onPressed: _getCurrentLocation,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter latitude';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: longController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.location_on),
                      onPressed: _getCurrentLocation,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter longitude';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: geoAddressController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Geographical Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter geographical address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),

                // Image Container with Validation
                FormField<File>(
                  validator: (value) {
                    if (_image == null) {
                      return 'Please select an image';
                    }
                    return null;
                  },
                  builder: (FormFieldState<File> state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10.0),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Customer Image',
                                    style: TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[300], // Optional: Placeholder background color
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8), // Same radius as the container
                                  child: _image != null
                                      ? Image.file(_image!, fit: BoxFit.fill)
                                      : Center(child: Text('No image selected.')),
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  _showPicker(context);
                                },
                                child: Text('Choose Image'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size(double.infinity, 40),
                                ),
                              ),
                              SizedBox(height: 5),
                              if (state.hasError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: Text(
                                    state.errorText ?? '',
                                    style: TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                Center(
                  child: ElevatedButton(
                    onPressed: _saveCustomer,
                    child: Text('Save Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF66BB6A), // Button color
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
