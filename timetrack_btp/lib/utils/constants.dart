class AppConstants {
  // Configuration générale
  static const String appName = 'TimeTrack BTP';
  static const String appVersion = '1.0.0';

  // Préférences locales
  static const String prefsUserData = 'userData';
  static const String prefsWorksites = 'worksites';
  static const String prefsTimesheets = 'timesheets';
  static const String prefsReports = 'reports';

  // Configuration API (à remplacer par les vraies valeurs en production)
  static const String apiBaseUrl = 'https://api.timetrackbtp.com/v1';
  static const int apiTimeoutSeconds = 30;

  // Paramètres de localisation
  static const int defaultWorksiteRadius = 200; // 200 mètres par défaut
  static const int locationUpdateIntervalSeconds = 60; // Toutes les minutes
}

class ErrorMessages {
  static const String networkError = 'Erreur de connexion. Veuillez vérifier votre connexion internet.';
  static const String authError = 'Erreur d\'authentification. Veuillez vous reconnecter.';
  static const String locationError = 'Impossible d\'obtenir votre position. Veuillez activer la localisation.';
  static const String serverError = 'Erreur serveur. Veuillez réessayer plus tard.';
  static const String dataError = 'Erreur lors du chargement des données.';
}