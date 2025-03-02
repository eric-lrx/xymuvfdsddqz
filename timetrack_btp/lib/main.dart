// Ce fichier est le point d'entrée de l'application
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/timesheet_provider.dart';
import 'providers/employee_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => TimesheetProvider()),
        ChangeNotifierProvider(create: (ctx) => EmployeeProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) {
          Widget homeScreen;
          
          // Déterminer l'écran à afficher en fonction de l'état d'authentification
          if (!auth.isAuth) {
            homeScreen = LoginScreen();
          } else if (auth.user!.isFirstLogin) {
            // Première connexion - rediriger vers le changement de mot de passe
            homeScreen = ChangePasswordScreen();
          } else if (auth.isAdmin) {
            // Utilisateur admin - rediriger vers le tableau de bord admin
            homeScreen = AdminDashboardScreen();
          } else {
            // Utilisateur standard - rediriger vers l'écran d'accueil
            homeScreen = HomeScreen();
          }
          
          return MaterialApp(
            title: 'TimeTrack BTP',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: homeScreen,
            routes: {
              LoginScreen.routeName: (ctx) => LoginScreen(),
              HomeScreen.routeName: (ctx) => HomeScreen(),
              ChangePasswordScreen.routeName: (ctx) => ChangePasswordScreen(),
              AdminDashboardScreen.routeName: (ctx) => AdminDashboardScreen(),
            },
          );
        },
      ),
    );
  }
}