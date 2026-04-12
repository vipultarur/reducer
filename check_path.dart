import 'dart:isolate';

void main() async {
  final _ = await Isolate.resolvePackageUri(Uri.parse('package:google_sign_in/google_sign_in.dart'));
}
