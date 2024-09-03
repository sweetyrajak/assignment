import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // You can remove the `apiUrl` variable since it's no longer needed

  Future<String?> login(String email, String password) async {
    if (email == 'user@maxmobility.in' && password == 'Abc@#123') {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('PREFS_LOGIN_FLAG', true);
      await prefs.setString('PREFS_USER_NAME', 'User Name');
      return 'Logged in successfully!';
    } else {
      return 'Invalid credentials';
    }
  }

  Future<void> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.clear(); // Clear all saved preferences on logout
      Fluttertoast.showToast(
        msg: "Logged out successfully",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        fontSize: 16.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "An error occurred while logging out: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        fontSize: 16.0,
      );
    }
  }
}
