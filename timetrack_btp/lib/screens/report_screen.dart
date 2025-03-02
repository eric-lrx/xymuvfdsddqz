import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/timesheet_provider.dart';
import '../models/report.dart';
import '../services/storage_service.dart';

class ReportScreen extends StatefulWidget {
  final String timesheetId;
  final String worksiteId;

  ReportScreen({
    required this.timesheetId,
    required this.worksiteId,
  });

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  List<String> _photoUrls = [];
  bool _isSubmitting = false;
  Report? _existingReport;

  @override
  void initState() {
    super.initState();
    _loadExistingReport();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadExistingReport() {
    final reports = Provider.of<TimesheetProvider>(context, listen: false).reports;
    
    try {
      _existingReport = reports.firstWhere(
        (report) => report.timesheetId == widget.timesheetId,
      );

      if (_existingReport != null) {
        _descriptionController.text = _existingReport!.description;
        _photoUrls = [..._existingReport!.photoUrls];
      }
    } catch (e) {
      // Aucun rapport existant trouvé, c'est normal
    }
  }

  Future<void> _capturePhoto() async {
    final photoPath = await StorageService.capturePhoto();
    
    if (photoPath != null) {
      setState(() {
        _photoUrls.add(photoPath);
      });
    }
  }

  Future<void> _pickPhoto() async {
    final photoPath = await StorageService.pickPhotoFromGallery();
    
    if (photoPath != null) {
      setState(() {
        _photoUrls.add(photoPath);
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      final path = _photoUrls[index];
      _photoUrls.removeAt(index);
      
      // Supprimer le fichier si c'est un nouveau rapport ou une nouvelle photo
      if (_existingReport == null || !_existingReport!.photoUrls.contains(path)) {
        StorageService.deletePhoto(path);
      }
    });
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final timesheetProvider = Provider.of<TimesheetProvider>(context, listen: false);
      
      final userId = authProvider.userId!;
      final description = _descriptionController.text.trim();
      
      final report = await timesheetProvider.addReport(
        userId,
        widget.worksiteId,
        widget.timesheetId,
        description,
        _photoUrls,
      );

      if (report != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(); // Retour à l'écran précédent
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement du rapport'),
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
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final worksite = Provider.of<TimesheetProvider>(context)
        .worksites
        .firstWhere((ws) => ws.id == widget.worksiteId);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Rapport de chantier'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                worksite.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Rapport du ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 24),
              
              // Description du travail effectué
              Text(
                'Description du travail effectué',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Décrivez le travail réalisé aujourd\'hui...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez décrire le travail effectué';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              // Photos
              Text(
                'Photos du chantier',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              if (_photoUrls.isEmpty)
                Text(
                  'Aucune photo ajoutée',
                  style: TextStyle(fontStyle: FontStyle.italic),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _photoUrls.length,
                  itemBuilder: (ctx, index) {
                    return Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_photoUrls[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                            onPressed: () => _removePhoto(index),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              SizedBox(height: 16),
              if (_photoUrls.length < 2) // Limite de 2 photos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _capturePhoto,
                      icon: Icon(Icons.camera_alt),
                      label: Text('Prendre une photo'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickPhoto,
                      icon: Icon(Icons.image),
                      label: Text('Galerie'),
                    ),
                  ],
                ),
              SizedBox(height: 32),
              
              // Bouton de soumission
              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: _isSubmitting
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          _existingReport != null
                              ? 'Mettre à jour le rapport'
                              : 'Enregistrer le rapport',
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