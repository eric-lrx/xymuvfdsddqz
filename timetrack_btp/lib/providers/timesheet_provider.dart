import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import '../models/timesheet.dart';
import '../models/worksite.dart';
import '../models/report.dart';

class TimesheetProvider with ChangeNotifier {
  List<Timesheet> _timesheets = [];
  List<Report> _reports = [];
  List<Worksite> _worksites = [];
  Timesheet? _activeTimesheet;

  List<Timesheet> get timesheets {
    return [..._timesheets];
  }

  List<Report> get reports {
    return [..._reports];
  }

  // Récupérer tous les chantiers
  List<Worksite> get worksites {
    return [..._worksites];
  }
  
  // Récupérer uniquement les chantiers assignés à un employé spécifique
  List<Worksite> getWorksitesForEmployee(String userId) {
    // Pour un administrateur, montrer tous les chantiers
    if (_isUserAdmin(userId)) {
      return [..._worksites];
    }
    
    // Pour les autres utilisateurs, ne montrer que les chantiers assignés
    return _worksites.where((ws) => 
      ws.assignedEmployees.contains(userId)
    ).toList();
  }
  
  // Vérifier si un utilisateur est administrateur
  bool _isUserAdmin(String userId) {
    // Pour le prototype, nous avons un ID fixe pour l'admin
    return userId == 'admin123';
  }
  
  // Ajouter un employé à un chantier
  Future<bool> assignEmployeeToWorksite(String employeeId, String worksiteId) async {
    try {
      final worksiteIndex = _worksites.indexWhere((ws) => ws.id == worksiteId);
      if (worksiteIndex == -1) {
        return false;
      }
      
      // Créer une nouvelle instance du chantier
      final worksite = _worksites[worksiteIndex];
      
      // Vérifier si l'employé est déjà assigné
      if (worksite.assignedEmployees.contains(employeeId)) {
        return true; // Déjà assigné, considéré comme un succès
      }
      
      // Créer une nouvelle liste d'assignations avec l'employé ajouté
      final newAssignedEmployees = [...worksite.assignedEmployees, employeeId];
      
      // Créer un nouveau chantier avec la liste mise à jour
      final updatedWorksite = Worksite(
        id: worksite.id,
        name: worksite.name,
        address: worksite.address,
        latitude: worksite.latitude,
        longitude: worksite.longitude,
        radius: worksite.radius,
        startDate: worksite.startDate,
        endDate: worksite.endDate,
        clientName: worksite.clientName,
        description: worksite.description,
        assignedEmployees: newAssignedEmployees,
      );
      
      // Mettre à jour la liste
      _worksites[worksiteIndex] = updatedWorksite;
      
      // Sauvegarder localement
      await _saveWorksitesLocally();
      
      notifyListeners();
      return true;
    } catch (error) {
      print('Error assigning employee to worksite: $error');
      return false;
    }
  }
  
  // Retirer un employé d'un chantier
  Future<bool> unassignEmployeeFromWorksite(String employeeId, String worksiteId) async {
    try {
      final worksiteIndex = _worksites.indexWhere((ws) => ws.id == worksiteId);
      if (worksiteIndex == -1) {
        return false;
      }
      
      final worksite = _worksites[worksiteIndex];
      
      // Vérifier si l'employé est assigné
      if (!worksite.assignedEmployees.contains(employeeId)) {
        return true; // Déjà non assigné, considéré comme un succès
      }
      
      // Créer une nouvelle liste d'assignations sans l'employé
      final newAssignedEmployees = worksite.assignedEmployees.where((id) => id != employeeId).toList();
      
      // Créer un nouveau chantier avec la liste mise à jour
      final updatedWorksite = Worksite(
        id: worksite.id,
        name: worksite.name,
        address: worksite.address,
        latitude: worksite.latitude,
        longitude: worksite.longitude,
        radius: worksite.radius,
        startDate: worksite.startDate,
        endDate: worksite.endDate,
        clientName: worksite.clientName,
        description: worksite.description,
        assignedEmployees: newAssignedEmployees,
      );
      
      // Mettre à jour la liste
      _worksites[worksiteIndex] = updatedWorksite;
      
      // Sauvegarder localement
      await _saveWorksitesLocally();
      
      notifyListeners();
      return true;
    } catch (error) {
      print('Error unassigning employee from worksite: $error');
      return false;
    }
  }
  
  // Sauvegarder les chantiers localement
  Future<void> _saveWorksitesLocally() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('worksites', json.encode(
      _worksites.map((ws) => ws.toJson()).toList(),
    ));
  }

  Timesheet? get activeTimesheet {
    return _activeTimesheet;
  }

  // Simuler le chargement des chantiers (en production, récupérer depuis l'API)
  Future<void> loadWorksites() async {
    try {
      // Simuler un délai réseau
      await Future.delayed(Duration(seconds: 1));
      
      // Données de test pour les chantiers
      _worksites = [
        Worksite(
          id: 'site1',
          name: 'Immeuble Les Roses',
          address: '123 Avenue des Fleurs, 75001 Paris',
          latitude: 48.8566,
          longitude: 2.3522,
          radius: 200.0,
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().add(Duration(days: 60)),
          clientName: 'SCI Les Fleurs',
          description: 'Rénovation complète d\'un immeuble de 6 étages',
          assignedEmployees: ['user123', 'user456'], // Assignation de deux employés de test
        ),
        Worksite(
          id: 'site2',
          name: 'Pont de la Liberté',
          address: '45 Quai du Fleuve, 69001 Lyon',
          latitude: 45.7640,
          longitude: 4.8357,
          radius: 300.0,
          startDate: DateTime.now().subtract(Duration(days: 60)),
          endDate: DateTime.now().add(Duration(days: 120)),
          clientName: 'Métropole de Lyon',
          description: 'Réfection du tablier du pont',
          assignedEmployees: ['user123'],  // Assignation d'un seul employé
        ),
      ];
      
      notifyListeners();
      
      // Enregistrer localement pour utilisation hors-ligne
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('worksites', json.encode(
        _worksites.map((ws) => ws.toJson()).toList(),
      ));
    } catch (error) {
      print(error);
    }
  }

  // Charger les données stockées localement
  Future<void> loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (prefs.containsKey('worksites')) {
        final worksitesData = json.decode(prefs.getString('worksites')!) as List<dynamic>;
        _worksites = worksitesData.map((ws) => Worksite.fromJson(ws)).toList();
      }
      
      if (prefs.containsKey('timesheets')) {
        final timesheetsData = json.decode(prefs.getString('timesheets')!) as List<dynamic>;
        _timesheets = timesheetsData.map((ts) => Timesheet.fromJson(ts)).toList();
        
        // Vérifier s'il y a un pointage actif (sans check-out)
        _activeTimesheet = _timesheets.firstWhere(
          (ts) => ts.checkOutTime == null,
          orElse: () => null as Timesheet,
        );
      }
      
      if (prefs.containsKey('reports')) {
        final reportsData = json.decode(prefs.getString('reports')!) as List<dynamic>;
        _reports = reportsData.map((r) => Report.fromJson(r)).toList();
      }
      
      notifyListeners();
    } catch (error) {
      print(error);
    }
  }

  // Contrôler si un utilisateur est dans la zone du chantier
  Future<bool> isUserInWorksite(String worksiteId) async {
    try {
      final worksite = _worksites.firstWhere((ws) => ws.id == worksiteId);
      
      // Vérifier les permissions de localisation
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
      
      // Obtenir la position actuelle
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Calculer la distance entre l'utilisateur et le chantier
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        worksite.latitude,
        worksite.longitude,
      );
      
      // Vérifier si l'utilisateur est dans le rayon du chantier
      return distance <= worksite.radius;
    } catch (error) {
      print(error);
      return false;
    }
  }

  // Créer un nouveau pointage (check-in)
  Future<Timesheet?> checkIn(String userId, String worksiteId) async {
    try {
      // Vérifier si l'utilisateur est assigné à ce chantier
      final worksite = _worksites.firstWhere((ws) => ws.id == worksiteId);
      
      // Si l'utilisateur n'est pas un admin et n'est pas assigné à ce chantier
      if (!_isUserAdmin(userId) && !worksite.assignedEmployees.contains(userId)) {
        throw Exception('Vous n\'êtes pas autorisé à pointer sur ce chantier');
      }
      
      // Vérifier si l'utilisateur est dans la zone du chantier
      final isInWorksite = await isUserInWorksite(worksiteId);
      
      // Obtenir la position actuelle
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Créer un nouveau pointage
      final newTimesheet = Timesheet(
        id: Uuid().v4(),
        userId: userId,
        worksiteId: worksiteId,
        checkInTime: DateTime.now(),
        checkInLatitude: position.latitude,
        checkInLongitude: position.longitude,
        isValid: isInWorksite,
        isSynced: false,
      );
      
      _timesheets.add(newTimesheet);
      _activeTimesheet = newTimesheet;
      
      // Sauvegarder localement
      await _saveTimesheetsLocally();
      
      notifyListeners();
      return newTimesheet;
    } catch (error) {
      print(error);
      return null;
    }
  }

  // Finaliser un pointage (check-out)
  Future<Timesheet?> checkOut(String timesheetId) async {
    try {
      final timesheetIndex = _timesheets.indexWhere((ts) => ts.id == timesheetId);
      
      if (timesheetIndex == -1) {
        return null;
      }
      
      // Obtenir la position actuelle
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Mettre à jour le pointage
      final updatedTimesheet = _timesheets[timesheetIndex].copyWith(
        checkOutTime: DateTime.now(),
        checkOutLatitude: position.latitude,
        checkOutLongitude: position.longitude,
      );
      
      _timesheets[timesheetIndex] = updatedTimesheet;
      _activeTimesheet = null;
      
      // Sauvegarder localement
      await _saveTimesheetsLocally();
      
      notifyListeners();
      return updatedTimesheet;
    } catch (error) {
      print(error);
      return null;
    }
  }

  // Créer un nouveau rapport
  Future<Report?> addReport(String userId, String worksiteId, String timesheetId, String description, List<String> photoUrls) async {
    try {
      final newReport = Report(
        id: Uuid().v4(),
        userId: userId,
        worksiteId: worksiteId,
        timesheetId: timesheetId,
        date: DateTime.now(),
        description: description,
        photoUrls: photoUrls,
        isSynced: false,
      );
      
      _reports.add(newReport);
      
      // Sauvegarder localement
      await _saveReportsLocally();
      
      notifyListeners();
      return newReport;
    } catch (error) {
      print(error);
      return null;
    }
  }

  // Sauvegarder les pointages localement
  Future<void> _saveTimesheetsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('timesheets', json.encode(
      _timesheets.map((ts) => ts.toJson()).toList(),
    ));
  }

  // Sauvegarder les rapports localement
  Future<void> _saveReportsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('reports', json.encode(
      _reports.map((r) => r.toJson()).toList(),
    ));
  }

  // Synchroniser les données avec le serveur (à implémenter avec une vraie API)
  Future<void> syncData() async {
    // Simuler une synchronisation
    await Future.delayed(Duration(seconds: 2));
    
    // Marquer les données comme synchronisées
    _timesheets = _timesheets.map((ts) => ts.copyWith(isSynced: true)).toList();
    _reports = _reports.map((r) => r.copyWith(isSynced: true)).toList();
    
    // Sauvegarder localement
    await _saveTimesheetsLocally();
    await _saveReportsLocally();
    
    notifyListeners();
  }
}