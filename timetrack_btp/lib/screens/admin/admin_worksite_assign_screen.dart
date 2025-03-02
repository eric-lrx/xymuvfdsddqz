import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/timesheet_provider.dart';
import '../../providers/employee_provider.dart';
import '../../models/worksite.dart';
import '../../models/user.dart';

class AdminWorksiteAssignScreen extends StatefulWidget {
  final String worksiteId;

  AdminWorksiteAssignScreen({required this.worksiteId});

  @override
  _AdminWorksiteAssignScreenState createState() => _AdminWorksiteAssignScreenState();
}

class _AdminWorksiteAssignScreenState extends State<AdminWorksiteAssignScreen> {
  bool _isLoading = false;

  Future<void> _toggleEmployeeAssignment(
      TimesheetProvider timesheetProvider, String employeeId, bool isAssigned) async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (isAssigned) {
        // Désassigner l'employé du chantier
        success = await timesheetProvider.unassignEmployeeFromWorksite(
            employeeId, widget.worksiteId);
      } else {
        // Assigner l'employé au chantier
        success = await timesheetProvider.assignEmployeeToWorksite(
            employeeId, widget.worksiteId);
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isAssigned ? 'Employé désassigné' : 'Employé assigné'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'opération'),
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
    final timesheetProvider = Provider.of<TimesheetProvider>(context);
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    
    // Récupérer le chantier concerné
    final worksite = timesheetProvider.worksites.firstWhere(
      (ws) => ws.id == widget.worksiteId,
      orElse: () => throw Exception('Chantier non trouvé'),
    );
    
    // Récupérer tous les employés (exclure les administrateurs)
    final employees = employeeProvider.employees
        .where((employee) => employee.role != 'admin')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des employés du chantier'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations sur le chantier
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.blue.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worksite.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 4),
                      Text(worksite.address),
                      if (worksite.clientName != null) ...[
                        SizedBox(height: 4),
                        Text('Client: ${worksite.clientName}'),
                      ],
                    ],
                  ),
                ),
                
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Assignation des employés',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                
                // Liste des employés
                Expanded(
                  child: employees.isEmpty
                      ? Center(child: Text('Aucun employé trouvé'))
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: employees.length,
                          itemBuilder: (ctx, index) {
                            final employee = employees[index];
                            final isAssigned = worksite.assignedEmployees
                                .contains(employee.id);

                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(employee.name.substring(0, 1)),
                                ),
                                title: Text(employee.name),
                                subtitle: Text(
                                  employee.role == 'worker'
                                      ? 'Ouvrier'
                                      : 'Chef d\'équipe',
                                ),
                                trailing: Switch(
                                  value: isAssigned,
                                  onChanged: (value) {
                                    _toggleEmployeeAssignment(
                                        timesheetProvider,
                                        employee.id,
                                        isAssigned);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
                
                // Note explicative
                Container(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Note: Les employés qui ne sont pas assignés à ce chantier ne pourront pas le voir dans leur liste ni y effectuer de pointage.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}