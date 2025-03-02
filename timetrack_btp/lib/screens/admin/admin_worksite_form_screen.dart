import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/timesheet_provider.dart';
import '../../models/worksite.dart';

class AdminWorksiteFormScreen extends StatefulWidget {
  final String? worksiteId; // Null pour un nouveau chantier, non-null pour une modification

  AdminWorksiteFormScreen({this.worksiteId});

  @override
  _AdminWorksiteFormScreenState createState() => _AdminWorksiteFormScreenState();
}

class _AdminWorksiteFormScreenState extends State<AdminWorksiteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _radiusController = TextEditingController(text: '200'); // Par défaut 200m
  
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  
  // Coordonnées de géolocalisation (pour un prototype, on utilisera des valeurs statiques)
  double _latitude = 48.8566;
  double _longitude = 2.3522;
  
  bool _isLoading = false;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Charger les données du chantier existant si en mode édition
    if (!_isInit && widget.worksiteId != null) {
      _loadWorksiteData();
      _isInit = true;
    }
  }

  void _loadWorksiteData() {
    setState(() {
      _isLoading = true;
    });

    try {
      final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
      final worksite = timesheetProvider.worksites.firstWhere(
        (ws) => ws.id == widget.worksiteId,
        orElse: () => throw Exception('Chantier non trouvé'),
      );

      _nameController.text = worksite.name;
      _addressController.text = worksite.address;
      _clientNameController.text = worksite.clientName ?? '';
      _descriptionController.text = worksite.description ?? '';
      _radiusController.text = worksite.radius.toString();
      _startDate = worksite.startDate;
      _endDate = worksite.endDate;
      _latitude = worksite.latitude;
      _longitude = worksite.longitude;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des données du chantier'),
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
    _addressController.dispose();
    _clientNameController.dispose();
    _descriptionController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: isStartDate ? DateTime(2020) : _startDate,
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
          // Si la date de fin est définie et avant la nouvelle date de début, on la réinitialise
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Note: Dans un prototype, nous n'avons pas réellement de méthode pour ajouter/modifier un chantier
      // Cette fonctionnalité devrait être ajoutée au TimesheetProvider dans une vraie application
      
      // Pour le prototype, on affiche simplement un message de succès et on retourne à l'écran précédent
      await Future.delayed(Duration(seconds: 1)); // Simuler le délai réseau
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.worksiteId == null
              ? 'Chantier ajouté avec succès'
              : 'Chantier mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Retour à l'écran précédent
      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
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
        title: Text(widget.worksiteId == null ? 'Nouveau chantier' : 'Modifier le chantier'),
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
                    // Nom du chantier
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du chantier',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom de chantier';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Adresse
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Adresse',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une adresse';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Client
                    TextFormField(
                      controller: _clientNameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du client (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (optionnel)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 24),
                    
                    // Dates
                    Text(
                      'Période du chantier',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    
                    // Date de début
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today),
                            SizedBox(width: 8),
                            Text('Date de début: ${DateFormat('dd/MM/yyyy').format(_startDate)}'),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Date de fin
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event),
                            SizedBox(width: 8),
                            Text(
                              _endDate == null
                                  ? 'Date de fin: Non définie'
                                  : 'Date de fin: ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_endDate != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: TextButton.icon(
                          icon: Icon(Icons.clear),
                          label: Text('Effacer la date de fin'),
                          onPressed: () {
                            setState(() {
                              _endDate = null;
                            });
                          },
                        ),
                      ),
                    SizedBox(height: 24),
                    
                    // Rayon de géolocalisation
                    TextFormField(
                      controller: _radiusController,
                      decoration: InputDecoration(
                        labelText: 'Rayon de géolocalisation (mètres)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un rayon';
                        }
                        try {
                          double radius = double.parse(value);
                          if (radius <= 0) {
                            return 'Le rayon doit être supérieur à 0';
                          }
                        } catch (e) {
                          return 'Veuillez entrer un nombre valide';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    
                    // Note sur la géolocalisation
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
                              'Dans une version complète, il serait possible de sélectionner la position du chantier sur une carte. Pour ce prototype, des coordonnées fixes sont utilisées.',
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
                          widget.worksiteId == null ? 'Créer le chantier' : 'Enregistrer les modifications',
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