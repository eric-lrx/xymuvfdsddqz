import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';

class EmployeeProvider with ChangeNotifier {
  List<User> _employees = [];
  
  List<User> get employees {
    return [..._employees];
  }
  
  // Charger les employés (simulé pour le prototype)
  Future<void> loadEmployees() async {
    try {
      // En production, remplacer par un appel API
      await Future.delayed(Duration(seconds: 1)); // Simuler le délai réseau
      
      // Récupérer depuis les préférences locales ou initialiser avec des données de test
      final prefs = await SharedPreferences.getInstance();
      
      if (prefs.containsKey('employees')) {
        final employeesData = json.decode(prefs.getString('employees')!) as List<dynamic>;
        _employees = employeesData.map((data) => User.fromJson(data)).toList();
      } else {
        // Données de test
        _employees = [
          User(
            id: 'user123',
            name: 'Jean Dupont',
            email: 'test@example.com',
            role: 'worker',
            phoneNumber: '0601020304',
            createdAt: DateTime.now().subtract(Duration(days: 30)),
          ),
          User(
            id: 'user456',
            name: 'Marie Martin',
            email: 'marie@example.com',
            role: 'supervisor',
            phoneNumber: '0607080910',
            createdAt: DateTime.now().subtract(Duration(days: 15)),
          ),
          User(
            id: 'new123',
            name: 'Nouvel Employé',
            email: 'new@example.com',
            role: 'worker',
            phoneNumber: '0612131415',
            isFirstLogin: true,
            createdAt: DateTime.now().subtract(Duration(days: 2)),
          ),
        ];
        
        // Sauvegarder dans les préférences
        await _saveEmployeesLocally();
      }
      
      notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }
  
  // Obtenir un employé par ID
  User? getEmployeeById(String id) {
    try {
      return _employees.firstWhere((employee) => employee.id == id);
    } catch (e) {
      return null;
    }
  }

  // Ajouter un nouvel employé
  Future<User> addEmployee(String name, String email, String role, String phoneNumber, String createdBy) async {
    try {
      // Vérifier si l'email est déjà utilisé
      final existingEmployee = _employees.where((emp) => emp.email == email).toList();
      if (existingEmployee.isNotEmpty) {
        throw Exception('Cet email est déjà utilisé par un autre employé.');
      }
      
      // En production, remplacer par un appel API
      await Future.delayed(Duration(seconds: 1)); // Simuler le délai réseau
      
      // Créer un nouvel employé
      final newEmployee = User(
        id: Uuid().v4(),
        name: name,
        email: email,
        role: role,
        phoneNumber: phoneNumber,
        isFirstLogin: true, // À sa première connexion, l'employé devra changer son mot de passe
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );
      
      _employees.add(newEmployee);
      
      // Dans une application réelle, nous stockerions le mot de passe haché 
      // dans la base de données ici
      
      // Sauvegarder localement
      await _saveEmployeesLocally();
      
      notifyListeners();
      return newEmployee;
    } catch (error) {
      print(error);
      throw error;
    }
  }
  
  // Mettre à jour un employé existant
  Future<User> updateEmployee(String id, String name, String email, String role, String phoneNumber) async {
    try {
      // Vérifier si l'employé existe
      final employeeIndex = _employees.indexWhere((emp) => emp.id == id);
      if (employeeIndex == -1) {
        throw Exception('Employé non trouvé.');
      }
      
      // Vérifier si l'email est déjà utilisé par un autre employé
      final existingEmailIndex = _employees.indexWhere((emp) => emp.email == email && emp.id != id);
      if (existingEmailIndex != -1) {
        throw Exception('Cet email est déjà utilisé par un autre employé.');
      }
      
      // En production, remplacer par un appel API
      await Future.delayed(Duration(seconds: 1)); // Simuler le délai réseau
      
      // Mettre à jour l'employé
      final updatedEmployee = _employees[employeeIndex].copyWith(
        name: name,
        email: email,
        role: role,
        phoneNumber: phoneNumber,
      );
      
      _employees[employeeIndex] = updatedEmployee;
      
      // Sauvegarder localement
      await _saveEmployeesLocally();
      
      notifyListeners();
      return updatedEmployee;
    } catch (error) {
      print(error);
      throw error;
    }
  }
  
  // Réinitialiser le mot de passe d'un employé
  Future<bool> resetEmployeePassword(String id) async {
    try {
      // Vérifier si l'employé existe
      final employeeIndex = _employees.indexWhere((emp) => emp.id == id);
      if (employeeIndex == -1) {
        throw Exception('Employé non trouvé.');
      }
      
      // En production, remplacer par un appel API
      await Future.delayed(Duration(seconds: 1)); // Simuler le délai réseau
      
      // Mettre à jour l'employé pour qu'il change son mot de passe à la prochaine connexion
      final updatedEmployee = _employees[employeeIndex].copyWith(
        isFirstLogin: true,
      );
      
      _employees[employeeIndex] = updatedEmployee;
      
      // Sauvegarder localement
      await _saveEmployeesLocally();
      
      notifyListeners();
      return true;
    } catch (error) {
      print(error);
      return false;
    }
  }
  
  // Supprimer un employé
  Future<bool> deleteEmployee(String id) async {
    try {
      // Vérifier si l'employé existe
      final employeeIndex = _employees.indexWhere((emp) => emp.id == id);
      if (employeeIndex == -1) {
        throw Exception('Employé non trouvé.');
      }
      
      // En production, remplacer par un appel API
      await Future.delayed(Duration(seconds: 1)); // Simuler le délai réseau
      
      _employees.removeAt(employeeIndex);
      
      // Sauvegarder localement
      await _saveEmployeesLocally();
      
      notifyListeners();
      return true;
    } catch (error) {
      print(error);
      return false;
    }
  }
  
  // Filtrer les employés par rôle
  List<User> getEmployeesByRole(String role) {
    return _employees.where((emp) => emp.role == role).toList();
  }
  
  // Sauvegarder les employés localement
  Future<void> _saveEmployeesLocally() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('employees', json.encode(
      _employees.map((emp) => emp.toJson()).toList(),
    ));
  }
}