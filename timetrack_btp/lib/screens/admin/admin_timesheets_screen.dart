import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/timesheet_provider.dart';
import '../../providers/employee_provider.dart';
import '../../models/timesheet.dart';
import '../../models/worksite.dart';
import '../../models/user.dart';

class AdminTimesheetsScreen extends StatefulWidget {
  static const routeName = '/admin-timesheets';

  @override
  _AdminTimesheetsScreenState createState() => _AdminTimesheetsScreenState();
}

class _AdminTimesheetsScreenState extends State<AdminTimesheetsScreen> {
  bool _isLoading = false;
  String? _selectedWorksiteId;
  String? _selectedEmployeeId;
  DateTime? _selectedDate;

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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedWorksiteId = null;
      _selectedEmployeeId = null;
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final timesheetProvider = Provider.of<TimesheetProvider>(context);
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    
    final worksites = timesheetProvider.worksites;
    final employees = employeeProvider.employees;
    List<Timesheet> timesheets = timesheetProvider.timesheets;
    
    // Appliquer les filtres
    if (_selectedWorksiteId != null) {
      timesheets = timesheets.where((ts) => ts.worksiteId == _selectedWorksiteId).toList();
    }
    
    if (_selectedEmployeeId != null) {
      timesheets = timesheets.where((ts) => ts.userId == _selectedEmployeeId).toList();
    }
    
    if (_selectedDate != null) {
      timesheets = timesheets.where((ts) {
        return ts.checkInTime.year == _selectedDate!.year &&
               ts.checkInTime.month == _selectedDate!.month &&
               ts.checkInTime.day == _selectedDate!.day;
      }).toList();
    }
    
    // Trier par date (plus récent en premier)
    timesheets.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

    return Scaffold(
      appBar: AppBar(
        title: Text('Suivi des pointages'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: () {
              _showFilterDialog(context, worksites, employees);
            },
          ),
          if (_selectedWorksiteId != null || _selectedEmployeeId != null || _selectedDate != null)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: Column(
                children: [
                  // En-tête des filtres actifs
                  if (_selectedWorksiteId != null || _selectedEmployeeId != null || _selectedDate != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      color: Colors.blue.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Filtres actifs: ' +
                                  (_selectedWorksiteId != null
                                      ? worksites
                                          .firstWhere((w) => w.id == _selectedWorksiteId)
                                          .name
                                      : '') +
                                  (_selectedEmployeeId != null
                                      ? ((_selectedWorksiteId != null ? ', ' : '') +
                                          employees
                                              .firstWhere((e) => e.id == _selectedEmployeeId)
                                              .name)
                                      : '') +
                                  (_selectedDate != null
                                      ? (((_selectedWorksiteId != null || _selectedEmployeeId != null)
                                              ? ', '
                                              : '') +
                                          DateFormat('dd/MM/yyyy').format(_selectedDate!))
                                      : ''),
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.clear, size: 18, color: Colors.blue),
                            onPressed: _clearFilters,
                          ),
                        ],
                      ),
                    ),
                  
                  // Liste des pointages
                  Expanded(
                    child: timesheets.isEmpty
                        ? Center(
                            child: Text('Aucun pointage trouvé'),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: timesheets.length,
                            itemBuilder: (ctx, index) {
                              final timesheet = timesheets[index];
                              final worksite = _findWorksite(worksites, timesheet.worksiteId);
                              final employee = _findEmployee(employees, timesheet.userId);
                              
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
                                              employee?.name ?? 'Employé inconnu',
                                              style: Theme.of(context).textTheme.titleMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          _buildStatusBadge(timesheet),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Chantier: ${worksite?.name ?? 'Inconnu'}',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Date: ${DateFormat('dd/MM/yyyy').format(timesheet.checkInTime)}',
                                      ),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Début: ${DateFormat('HH:mm').format(timesheet.checkInTime)}',
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              timesheet.checkOutTime != null
                                                  ? 'Fin: ${DateFormat('HH:mm').format(timesheet.checkOutTime!)}'
                                                  : 'En cours',
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (timesheet.checkOutTime != null) ...[
                                        SizedBox(height: 4),
                                        Text(
                                          'Durée: ${_calculateDuration(timesheet)}',
                                        ),
                                      ],
                                      SizedBox(height: 8),
                                      if (!timesheet.isValid)
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.warning, color: Colors.red, size: 16),
                                              SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Pointage effectué hors de la zone du chantier',
                                                  style: TextStyle(color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        icon: Icon(Icons.map),
                                        label: Text('Voir les coordonnées'),
                                        onPressed: () {
                                          _showLocationDetails(context, timesheet);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Worksite? _findWorksite(List<Worksite> worksites, String worksiteId) {
    try {
      return worksites.firstWhere((ws) => ws.id == worksiteId);
    } catch (e) {
      return null;
    }
  }

  User? _findEmployee(List<User> employees, String userId) {
    try {
      return employees.firstWhere((emp) => emp.id == userId);
    } catch (e) {
      return null;
    }
  }

  Widget _buildStatusBadge(Timesheet timesheet) {
    if (!timesheet.isValid) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Hors zone',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      );
    }

    if (timesheet.checkOutTime == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'En cours',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Terminé',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  String _calculateDuration(Timesheet timesheet) {
    if (timesheet.checkOutTime == null) {
      return 'En cours';
    }

    final duration = timesheet.checkOutTime!.difference(timesheet.checkInTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return '$hours h ${minutes.toString().padLeft(2, '0')} min';
  }

  void _showFilterDialog(BuildContext context, List<Worksite> worksites, List<User> employees) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Filtrer les pointages'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filtre par chantier
                Text(
                  'Chantier',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  hint: Text('Tous les chantiers'),
                  value: _selectedWorksiteId,
                  items: [
                    ...worksites
                        .map((worksite) => DropdownMenuItem(
                              value: worksite.id,
                              child: Text(
                                worksite.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedWorksiteId = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                
                // Filtre par employé
                Text(
                  'Employé',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  hint: Text('Tous les employés'),
                  value: _selectedEmployeeId,
                  items: [
                    ...employees
                        .where((emp) => emp.role != 'admin') // Exclure les administrateurs
                        .map((employee) => DropdownMenuItem(
                              value: employee.id,
                              child: Text(
                                employee.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedEmployeeId = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                
                // Filtre par date
                Text(
                  'Date',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                InkWell(
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );

                    if (pickedDate != null) {
                      setDialogState(() {
                        _selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'Toutes les dates'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        ),
                        Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
                if (_selectedDate != null)
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        _selectedDate = null;
                      });
                    },
                    child: Text('Effacer la date'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Les filtres sont déjà appliqués via les setDialogState
                setState(() {}); // Rafraîchir l'interface
              },
              child: Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationDetails(BuildContext context, Timesheet timesheet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Détails de localisation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pointage du ${DateFormat('dd/MM/yyyy à HH:mm').format(timesheet.checkInTime)}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Coordonnées au pointage :'),
            SizedBox(height: 4),
            Text('Latitude: ${timesheet.checkInLatitude}'),
            Text('Longitude: ${timesheet.checkInLongitude}'),
            SizedBox(height: 16),
            if (timesheet.checkOutTime != null) ...[
              Text('Coordonnées à la fin :'),
              SizedBox(height: 4),
              Text('Latitude: ${timesheet.checkOutLatitude}'),
              Text('Longitude: ${timesheet.checkOutLongitude}'),
              SizedBox(height: 16),
            ],
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 16),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Dans une version complète, il serait possible de visualiser ces points sur une carte.',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}