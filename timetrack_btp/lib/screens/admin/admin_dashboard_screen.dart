import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/timesheet_provider.dart';
import '../../providers/employee_provider.dart';
import 'admin_worksites_screen.dart';
import 'admin_employees_screen.dart';
import 'admin_timesheets_screen.dart';
import 'admin_reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  static const routeName = '/admin-dashboard';

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les données nécessaires pour le tableau de bord
      final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      
      await Future.wait([
        timesheetProvider.loadWorksites(),
        timesheetProvider.loadLocalData(),
        employeeProvider.loadEmployees(),
      ]);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement des données'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final timesheetProvider = Provider.of<TimesheetProvider>(context);
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    
    final worksites = timesheetProvider.worksites;
    final timesheets = timesheetProvider.timesheets;
    final employees = employeeProvider.employees;
    
    // Calculer quelques statistiques pour le tableau de bord
    final activeWorksites = worksites.where((ws) => ws.endDate == null || ws.endDate!.isAfter(DateTime.now())).length;
    final todayTimesheets = timesheets.where((ts) => ts.checkInTime.day == DateTime.now().day && ts.checkInTime.month == DateTime.now().month && ts.checkInTime.year == DateTime.now().year).length;
    final activeEmployees = employees.where((emp) => emp.role != 'admin').length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Administration'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue, ${authProvider.user?.name ?? "Administrateur"}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 24),
                    
                    // Cartes de statistiques
                    Row(
                      children: [
                        _buildStatCard(
                          context, 
                          'Chantiers actifs', 
                          activeWorksites.toString(),
                          Icons.business,
                          Colors.blue,
                        ),
                        SizedBox(width: 16),
                        _buildStatCard(
                          context, 
                          'Pointages aujourd\'hui', 
                          todayTimesheets.toString(),
                          Icons.access_time,
                          Colors.green,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatCard(
                          context, 
                          'Employés', 
                          activeEmployees.toString(),
                          Icons.people,
                          Colors.orange,
                        ),
                        SizedBox(width: 16),
                        _buildStatCard(
                          context, 
                          'Rapports', 
                          timesheetProvider.reports.length.toString(),
                          Icons.description,
                          Colors.purple,
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    
                    // Menu de gestion
                    Text(
                      'Gestion',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    
                    // Carte Gestion des chantiers
                    _buildManagementCard(
                      context,
                      'Gestion des chantiers',
                      'Créer, modifier et suivre les chantiers',
                      Icons.business,
                      Colors.blue,
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => AdminWorksitesScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Carte Gestion des employés
                    _buildManagementCard(
                      context,
                      'Gestion des employés',
                      'Ajouter, modifier et gérer les comptes employés',
                      Icons.people,
                      Colors.orange,
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => AdminEmployeesScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Carte Suivi des pointages
                    _buildManagementCard(
                      context,
                      'Suivi des pointages',
                      'Visualiser les pointages et les présences',
                      Icons.access_time,
                      Colors.green,
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => AdminTimesheetsScreen(),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Carte Rapports de chantier
                    _buildManagementCard(
                      context,
                      'Rapports de chantier',
                      'Consulter les rapports et photos des chantiers',
                      Icons.description,
                      Colors.purple,
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => AdminReportsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}