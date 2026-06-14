import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/api_constants.dart';
import 'core/storage/local_storage.dart';

// TODO: uncomment once `flutterfire configure` is done and
// `firebase_options.dart` exists in lib/
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // 2. Init local storage — must happen before GoRouter's redirect
  //    (in app.dart) calls TokenStorage.hasToken() synchronously
  await TokenStorage.init();

  // 3. Init Firebase — BLOCKED until firebase_options.dart exists
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // 4. Init Supabase
  await Supabase.initialize(
    url: ApiConstants.supabaseUrl,
    anonKey: ApiConstants.supabaseAnonKey,
  );

  runApp(const MyApp());
}