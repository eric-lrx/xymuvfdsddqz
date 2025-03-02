import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  User? _user;
  
  // Stockage des mots de passe temporaires (en mémoire seulement pour le prototype)
  // Dans une vraie application, cela serait géré par une base de données sécurisée
  Map<String, String> _tempPasswords = {};

  bool get isAuth {
    return token != null;
  }

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  String? get userId {
    return _userId;
  }

  User? get user {
    return _user;
  }

  // Méthode pour enregistrer un mot de passe temporaire pour un nouvel utilisateur
  void registerTemporaryPassword(String email, String password) {
    _tempPasswords[email] = password;
    print("Mot de passe temporaire enregistré pour: $email");
  }

  // Simulons un login pour le prototype (sans API réelle)
  Future<bool> login(String email, String password) async {
    try {
      // En production, remplacer par un appel API
      await Future.delayed(Duration(seconds: 1)); // Simuler le délai réseau
      
      // Utilisateurs de test pour le prototype
      Map<String, Map<String, dynamic>> testUsers = {
        'test@example.com': {
          'password': 'password123',
          'id': 'user123',
          'name': 'Jean Dupont',
          'role': 'worker',
          'phoneNumber': '0601020304',
          'isFirstLogin': false,
        },
        'admin@example.com': {
          'password': 'admin123',
          'id': 'admin123',
          'name': 'Admin Principal',
          'role': 'admin',
          'phoneNumber': '0708091011',
          'isFirstLogin': false,
        },
        'new@example.com': {
          'password': 'newuser123',
          'id': 'new123',
          'name': 'Nouvel Employé',
          'role': 'worker',
          'phoneNumber': '0612131415',
          'isFirstLogin': true,
        },
      };
      
      // Vérifier d'abord dans les mots de passe temporaires pour les nouveaux utilisateurs
      if (_tempPasswords.containsKey(email) && _tempPasswords[email] == password) {
        print("Connexion avec mot de passe temporaire pour: $email");
        
        // Charger les détails de l'utilisateur depuis EmployeeProvider (via les SharedPreferences)
        final prefs = await SharedPreferences.getInstance();
        if (prefs.containsKey('employees')) {
          final employeesData = json.decode(prefs.getString('employees')!) as List<dynamic>;
          final employees = employeesData.map((data) => User.fromJson(data)).toList();
          
          try {
            final userFound = employees.firstWhere(
              (emp) => emp.email == email,
            );
            
            _token = 'dummy_token';
            _userId = userFound.id;
            _expiryDate = DateTime.now().add(Duration(hours: 24));
            
            _user = userFound;
            
            // Sauvegarder les données d'authentification
            final userData = json.encode({
              'token': _token,
              'userId': _userId,
              'expiryDate': _expiryDate!.toIso8601String(),
              'user': _user!.toJson(),
            });
            prefs.setString('userData', userData);
            
            notifyListeners();
            return true;
          } catch (e) {
            print("Employé non trouvé: $e");
          }
        }
      }
      
      // Sinon, vérifier dans les utilisateurs de test
      if (testUsers.containsKey(email) && testUsers[email]!['password'] == password) {
        final userData = testUsers[email]!;
        
        _token = 'dummy_token';
        _userId = userData['id'];
        _expiryDate = DateTime.now().add(Duration(hours: 24));
        
        _user = User(
          id: _userId!,
          name: userData['name'],
          email: email,
          role: userData['role'],
          phoneNumber: userData['phoneNumber'],
          isFirstLogin: userData['isFirstLogin'],
        );
        
        // Sauvegarder les données d'authentification
        final prefs = await SharedPreferences.getInstance();
        final userDataJson = json.encode({
          'token': _token,
          'userId': _userId,
          'expiryDate': _expiryDate!.toIso8601String(),
          'user': _user!.toJson(),
        });
        prefs.setString('userData', userDataJson);
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (error) {
      print("Erreur de login: $error");
      return false;
    }
  }

  // Vérifier l'authentification stockée au démarrage
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }

    final extractedUserData = json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    final expiryDate = DateTime.parse(extractedUserData['expiryDate']);

    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }

    _token = extractedUserData['token'];
    _userId = extractedUserData['userId'];
    _expiryDate = expiryDate;
    _user = User.fromJson(extractedUserData['user']);
    
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    _user = null;
    
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userData');
    
    notifyListeners();
  }
  
  // Vérifier si l'utilisateur est un administrateur
  bool get isAdmin {
    return _user?.role == 'admin';
  }
  
  // Mettre à jour le mot de passe et le statut de première connexion
  Future<bool> updatePassword(String newPassword) async {
    try {
      // En production, remplacer par un appel API
      await Future.delayed(Duration(seconds: 1)); // Simuler le délai réseau
      
      if (_user == null) {
        return false;
      }
      
      // Mettre à jour l'utilisateur avec isFirstLogin à false
      _user = _user!.copyWith(isFirstLogin: false);
      
      // Sauvegarder les données mises à jour
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'userId': _userId,
        'expiryDate': _expiryDate!.toIso8601String(),
        'user': _user!.toJson(),
      });
      prefs.setString('userData', userData);
      
      notifyListeners();
      return true;
    } catch (error) {
      print(error);
      return false;
    }
  }
}