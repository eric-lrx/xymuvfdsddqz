import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/timesheet_provider.dart';
import '../../providers/employee_provider.dart';
import '../../models/report.dart';
import '../../models/worksite.dart';
import '../../models/user.dart';

class AdminReportsScreen extends StatefulWidget {
  static const routeName = '/admin-reports';

  @override
  _AdminReportsScreenState createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
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

  void _clearFilters() {
    setState(() {
      _selectedWorksiteId = null;
      _selectedEmployeeId = null;
      _selectedDate = null;
    });
  }

  void _showFilterDialog(BuildContext context, List<Worksite> worksites, List<User> employees) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Filtrer les rapports'),
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

  void _showPhotoDialog(BuildContext context, String photoPath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Photo'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Image.file(
                File(photoPath),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timesheetProvider = Provider.of<TimesheetProvider>(context);
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    
    final worksites = timesheetProvider.worksites;
    final employees = employeeProvider.employees;
    List<Report> reports = timesheetProvider.reports;
    
    // Appliquer les filtres
    if (_selectedWorksiteId != null) {
      reports = reports.where((r) => r.worksiteId == _selectedWorksiteId).toList();
    }
    
    if (_selectedEmployeeId != null) {
      reports = reports.where((r) => r.userId == _selectedEmployeeId).toList();
    }
    
    if (_selectedDate != null) {
      reports = reports.where((r) {
        return r.date.year == _selectedDate!.year &&
               r.date.month == _selectedDate!.month &&
               r.date.day == _selectedDate!.day;
      }).toList();
    }
    
    // Trier par date (plus récent en premier)
    reports.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text('Rapports de chantier'),
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
                  
                  // Liste des rapports
                  Expanded(
                    child: reports.isEmpty
                        ? Center(
                            child: Text('Aucun rapport trouvé'),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.all(16),
                            itemCount: reports.length,
                            itemBuilder: (ctx, index) {
                              final report = reports[index];
                              final worksite = _findWorksite(worksites, report.worksiteId);
                              final employee = _findEmployee(employees, report.userId);
                              
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
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: report.isSynced ? Colors.green : Colors.orange,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              report.isSynced ? 'Synchronisé' : 'En attente',
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
                                        'Chantier: ${worksite?.name ?? 'Inconnu'}',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Date: ${DateFormat('dd/MM/yyyy à HH:mm').format(report.date)}',
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Description:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(report.description),
                                      ),
                                      SizedBox(height: 16),
                                      if (report.photoUrls.isNotEmpty) ...[
                                        Text(
                                          'Photos (${report.photoUrls.length}):',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(height: 8),
                                        Container(
                                          height: 100,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: report.photoUrls.length,
                                            itemBuilder: (ctx, photoIndex) {
                                              return GestureDetector(
                                                onTap: () {
                                                  _showPhotoDialog(context, report.photoUrls[photoIndex]);
                                                },
                                                child: Container(
                                                  width: 100,
                                                  margin: EdgeInsets.only(right: 8),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.grey),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: Image.file(
                                                      File(report.photoUrls[photoIndex]),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
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
}