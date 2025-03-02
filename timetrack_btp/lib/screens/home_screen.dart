import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/timesheet_provider.dart';
import '../models/timesheet.dart';
import '../models/worksite.dart';
import 'timesheet_screen.dart';
import 'report_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  int _selectedIndex = 0;

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
      final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
      await timesheetProvider.loadWorksites();
      await timesheetProvider.loadLocalData();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildHomeContent() {
    final authProvider = Provider.of<AuthProvider>(context);
    final timesheetProvider = Provider.of<TimesheetProvider>(context);
    final user = authProvider.user;
    final activeTimesheet = timesheetProvider.activeTimesheet;
    final worksites = timesheetProvider.worksites;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, ${user?.name ?? "Utilisateur"}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 24),
            
            // Statut du pointage
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Votre statut',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: activeTimesheet != null ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          activeTimesheet != null ? 'Pointé - En service' : 'Non pointé',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    if (activeTimesheet != null) ...[
                      SizedBox(height: 8),
                      Text(
                        'Chantier: ${_getWorksiteName(worksites, activeTimesheet.worksiteId)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await _checkOut(activeTimesheet);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Terminer ma journée'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Liste des chantiers
            Text(
              'Mes chantiers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            if (worksites.isEmpty)
              Center(
                child: Text('Aucun chantier assigné'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: worksites.length,
                itemBuilder: (ctx, index) {
                  final worksite = worksites[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(worksite.name),
                      subtitle: Text(worksite.address),
                      trailing: activeTimesheet == null
                          ? ElevatedButton(
                              onPressed: () async {
                                await _checkIn(user!.id, worksite.id);
                              },
                              child: Text('Pointer'),
                            )
                          : null,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getWorksiteName(List<Worksite> worksites, String worksiteId) {
    final worksite = worksites.firstWhere(
      (ws) => ws.id == worksiteId,
      orElse: () => Worksite(
        id: '',
        name: 'Inconnu',
        address: '',
        latitude: 0,
        longitude: 0,
        radius: 0,
        startDate: DateTime.now(),
      ),
    );
    return worksite.name;
  }

  Future<void> _checkIn(String userId, String worksiteId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
      final timesheet = await timesheetProvider.checkIn(userId, worksiteId);

      if (timesheet != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pointage effectué avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du pointage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Une erreur est survenue'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkOut(Timesheet timesheet) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
      final updatedTimesheet = await timesheetProvider.checkOut(timesheet.id);

      if (updatedTimesheet != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fin de journée enregistrée'),
            backgroundColor: Colors.green,
          ),
        );

        // Rediriger vers l'écran de rapport
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ReportScreen(
              timesheetId: updatedTimesheet.id,
              worksiteId: updatedTimesheet.worksiteId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la fin de journée'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Une erreur est survenue'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text('TimeTrack BTP'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () async {
              final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
              await timesheetProvider.syncData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Données synchronisées'),
                  backgroundColor: Colors.green,
                ),
              );
            },
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
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeContent(),
                TimesheetScreen(),
                ProfileScreen(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}