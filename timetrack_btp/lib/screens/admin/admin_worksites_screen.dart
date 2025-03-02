import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/timesheet_provider.dart';
import '../../models/worksite.dart';
import 'admin_worksite_form_screen.dart';

class AdminWorksitesScreen extends StatefulWidget {
  static const routeName = '/admin-worksites';

  @override
  _AdminWorksitesScreenState createState() => _AdminWorksitesScreenState();
}

class _AdminWorksitesScreenState extends State<AdminWorksitesScreen> {
  bool _isLoading = false;
  String _filter = 'Tous'; // Options: 'Tous', 'Actifs', 'Terminés'

  @override
  void initState() {
    super.initState();
    _loadWorksites();
  }

  Future<void> _loadWorksites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<TimesheetProvider>(context, listen: false).loadWorksites();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des chantiers'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation(BuildContext context, Worksite worksite) {
    // Dans une vraie application, cette fonctionnalité devrait être implémentée
    // Pour le prototype, nous allons juste afficher un message
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Fonctionnalité non implémentée'),
        content: Text(
            'La suppression de chantier n\'est pas implémentée dans ce prototype. Dans une application réelle, cela nécessiterait une gestion des relations avec les pointages et rapports existants.'),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timesheetProvider = Provider.of<TimesheetProvider>(context);
    List<Worksite> worksites = timesheetProvider.worksites;
    
    // Filtrer les chantiers en fonction du filtre sélectionné
    if (_filter == 'Actifs') {
      worksites = worksites
          .where((worksite) =>
              worksite.endDate == null || worksite.endDate!.isAfter(DateTime.now()))
          .toList();
    } else if (_filter == 'Terminés') {
      worksites = worksites
          .where((worksite) =>
              worksite.endDate != null && worksite.endDate!.isBefore(DateTime.now()))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des chantiers'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'Tous',
                child: Text('Tous les chantiers'),
              ),
              PopupMenuItem(
                value: 'Actifs',
                child: Text('Chantiers actifs'),
              ),
              PopupMenuItem(
                value: 'Terminés',
                child: Text('Chantiers terminés'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWorksites,
              child: worksites.isEmpty
                  ? Center(
                      child: Text('Aucun chantier trouvé'),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: worksites.length,
                      itemBuilder: (ctx, index) {
                        final worksite = worksites[index];
                        final bool isActive = worksite.endDate == null ||
                            worksite.endDate!.isAfter(DateTime.now());

                        return Card(
                          margin: EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        worksite.name,
                                        style: Theme.of(context).textTheme.titleMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive ? Colors.green : Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isActive ? 'Actif' : 'Terminé',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  worksite.address,
                                  style: TextStyle(color: Colors.grey),
                                ),
                                SizedBox(height: 8),
                                if (worksite.clientName != null)
                                  Text(
                                    'Client: ${worksite.clientName}',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Début: ${DateFormat('dd/MM/yyyy').format(worksite.startDate)}',
                                    ),
                                    SizedBox(width: 16),
                                    if (worksite.endDate != null) ...[
                                      Icon(
                                        Icons.event,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Fin: ${DateFormat('dd/MM/yyyy').format(worksite.endDate!)}',
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.map, color: Colors.blue),
                                      tooltip: 'Voir sur la carte',
                                      onPressed: () {
                                        // TODO: Implémenter la visualisation sur la carte
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Fonctionnalité non implémentée'),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.green),
                                      tooltip: 'Modifier',
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (ctx) => AdminWorksiteFormScreen(
                                              worksiteId: worksite.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Supprimer',
                                      onPressed: () {
                                        _showDeleteConfirmation(context, worksite);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => AdminWorksiteFormScreen(),
            ),
          );
        },
      ),
    );
  }
}