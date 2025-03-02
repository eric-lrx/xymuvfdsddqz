import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class AdminEmployeeFormScreen extends StatefulWidget {
  final String? employeeId; // Null pour un nouvel employé, non-null pour une modification

  AdminEmployeeFormScreen({this.employeeId});

  @override
  _AdminEmployeeFormScreenState createState() => _AdminEmployeeFormScreenState();
}

class _AdminEmployeeFormScreenState extends State<AdminEmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRole = 'worker'; // Par défaut: ouvrier
  bool _isLoading = false;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Charger les données de l'employé existant si en mode édition
    if (!_isInit && widget.employeeId != null) {
      _loadEmployeeData();
      _isInit = true;
    }
  }

  void _loadEmployeeData() {
    setState(() {
      _isLoading = true;
    });

    try {
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      final employee = employeeProvider.getEmployeeById(widget.employeeId!);

      if (employee != null) {
        _nameController.text = employee.name;
        _emailController.text = employee.email;
        _phoneController.text = employee.phoneNumber ?? '';
        _selectedRole = employee.role;
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des données de l\'employé'),
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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Générer un mot de passe aléatoire
  String _generateTemporaryPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (widget.employeeId == null) {
        // Générer un mot de passe temporaire pour le nouvel employé
        final temporaryPassword = _generateTemporaryPassword();
        
        // Création d'un nouvel employé
        final newEmployee = await employeeProvider.addEmployee(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _selectedRole,
          _phoneController.text.trim(),
          authProvider.userId!, // Admin qui crée l'employé
        );
        
        // Enregistrer le mot de passe temporaire
        authProvider.registerTemporaryPassword(
          _emailController.text.trim(),
          temporaryPassword,
        );
        
        // Afficher le mot de passe temporaire à l'administrateur
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: Text('Employé créé avec succès'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Un compte a été créé pour ${_nameController.text.trim()}.'),
                  SizedBox(height: 16),
                  Text(
                    'Mot de passe temporaire:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          temporaryPassword,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: temporaryPassword));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Mot de passe copié dans le presse-papier')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Important: Communiquez ce mot de passe à l\'employé. '
                    'Il devra le changer à sa première connexion.',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(); // Retour à la liste des employés
                  },
                  child: Text('Compris'),
                ),
              ],
            ),
          );
        }
      } else {
        // Mise à jour d'un employé existant
        await employeeProvider.updateEmployee(
          widget.employeeId!,
          _nameController.text.trim(),
          _emailController.text.trim(),
          _selectedRole,
          _phoneController.text.trim(),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employé mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Retour à l'écran précédent
        Navigator.of(context).pop();
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employeeId == null ? 'Nouvel employé' : 'Modifier l\'employé'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom complet',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un email';
                        }
                        if (!value.contains('@')) {
                          return 'Veuillez entrer un email valide';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Téléphone
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Téléphone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un numéro de téléphone';
                        }
                        if (value.length < 10) {
                          return 'Numéro de téléphone trop court';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    
                    // Rôle
                    Text(
                      'Rôle',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    
                    // Radio buttons pour le rôle
                    RadioListTile<String>(
                      title: Text('Ouvrier'),
                      value: 'worker',
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: Text('Chef d\'équipe'),
                      value: 'supervisor',
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    SizedBox(height: 32),
                    
                    // Note sur le mot de passe
                    if (widget.employeeId == null)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Un mot de passe temporaire sera généré. L\'employé devra le changer à sa première connexion.',
                                style: TextStyle(
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 32),
                    
                    // Bouton de soumission
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveForm,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: Text(
                          widget.employeeId == null ? 'Créer l\'employé' : 'Enregistrer les modifications',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}