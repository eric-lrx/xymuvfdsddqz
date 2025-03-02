import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import 'admin_employee_form_screen.dart';

class AdminEmployeesScreen extends StatefulWidget {
  static const routeName = '/admin-employees';

  @override
  _AdminEmployeesScreenState createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<AdminEmployeesScreen> {
  bool _isLoading = false;
  String _filter = 'Tous'; // Options: 'Tous', 'worker', 'supervisor'

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<EmployeeProvider>(context, listen: false).loadEmployees();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des employés'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeleteConfirmation(BuildContext context, User employee) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer l\'employé'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${employee.name} ?'),
        actions: [
          TextButton(
            child: Text('Annuler'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _deleteEmployee(employee.id);
            },
          ),
        ],
      ),
    );
  }

  void _showResetPasswordConfirmation(BuildContext context, User employee) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Réinitialiser le mot de passe'),
        content: Text(
            'Êtes-vous sûr de vouloir réinitialiser le mot de passe de ${employee.name} ?\n\nL\'employé devra changer son mot de passe à la prochaine connexion.'),
        actions: [
          TextButton(
            child: Text('Annuler'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          TextButton(
            child: Text('Réinitialiser'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _resetEmployeePassword(employee.id);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEmployee(String id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await Provider.of<EmployeeProvider>(context, listen: false).deleteEmployee(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employé supprimé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression de l\'employé'),
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

  Future<void> _resetEmployeePassword(String id) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await Provider.of<EmployeeProvider>(context, listen: false).resetEmployeePassword(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mot de passe réinitialisé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la réinitialisation du mot de passe'),
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

  String _getRoleName(String role) {
    switch (role) {
      case 'worker':
        return 'Ouvrier';
      case 'supervisor':
        return 'Chef d\'équipe';
      case 'admin':
        return 'Administrateur';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'worker':
        return Colors.blue;
      case 'supervisor':
        return Colors.orange;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Filtrer les employés en fonction du filtre sélectionné
    List<User> filteredEmployees = employeeProvider.employees;
    if (_filter != 'Tous') {
      filteredEmployees = filteredEmployees.where((emp) => emp.role == _filter).toList();
    }
    
    // Exclure les administrateurs de la liste (ils sont gérés différemment)
    filteredEmployees = filteredEmployees.where((emp) => emp.role != 'admin').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des employés'),
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
                child: Text('Tous les employés'),
              ),
              PopupMenuItem(
                value: 'worker',
                child: Text('Ouvriers'),
              ),
              PopupMenuItem(
                value: 'supervisor',
                child: Text('Chefs d\'équipe'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEmployees,
              child: filteredEmployees.isEmpty
                  ? Center(
                      child: Text('Aucun employé trouvé'),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: filteredEmployees.length,
                      itemBuilder: (ctx, index) {
                        final employee = filteredEmployees[index];
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
                                        employee.name,
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
                                        color: _getRoleColor(employee.role),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getRoleName(employee.role),
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
                                  employee.email,
                                  style: TextStyle(color: Colors.grey),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tél: ${employee.phoneNumber ?? "Non renseigné"}',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                if (employee.isFirstLogin)
                                  Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.orange,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Mot de passe à changer',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.lock_reset, color: Colors.blue),
                                      tooltip: 'Réinitialiser le mot de passe',
                                      onPressed: () {
                                        _showResetPasswordConfirmation(context, employee);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit, color: Colors.green),
                                      tooltip: 'Modifier',
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (ctx) => AdminEmployeeFormScreen(
                                              employeeId: employee.id,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Supprimer',
                                      onPressed: () {
                                        _showDeleteConfirmation(context, employee);
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
              builder: (ctx) => AdminEmployeeFormScreen(),
            ),
          );
        },
      ),
    );
  }
}