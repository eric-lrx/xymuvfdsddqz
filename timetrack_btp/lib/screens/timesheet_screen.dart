import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/timesheet_provider.dart';
import '../models/timesheet.dart';
import '../models/worksite.dart';
import 'report_screen.dart';

class TimesheetScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final timesheetProvider = Provider.of<TimesheetProvider>(context);
    final timesheets = timesheetProvider.timesheets;
    final worksites = timesheetProvider.worksites;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await timesheetProvider.loadLocalData();
        },
        child: timesheets.isEmpty
            ? Center(
                child: Text('Aucun pointage enregistré'),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: timesheets.length,
                itemBuilder: (ctx, index) {
                  final timesheet = timesheets[index];
                  final worksite = _findWorksite(worksites, timesheet.worksiteId);
                  
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
                              Text(
                                worksite?.name ?? 'Chantier inconnu',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              _buildStatusBadge(timesheet),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Date: ${DateFormat('dd/MM/yyyy').format(timesheet.checkInTime)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Début: ${DateFormat('HH:mm').format(timesheet.checkInTime)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  timesheet.checkOutTime != null
                                      ? 'Fin: ${DateFormat('HH:mm').format(timesheet.checkOutTime!)}'
                                      : 'En cours',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                          if (timesheet.checkOutTime != null) ...[
                            SizedBox(height: 4),
                            Text(
                              'Durée: ${_calculateDuration(timesheet)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          SizedBox(height: 8),
                          if (!timesheet.isSynced)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.sync_problem,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'En attente de synchronisation',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          if (timesheet.checkOutTime != null)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => ReportScreen(
                                      timesheetId: timesheet.id,
                                      worksiteId: timesheet.worksiteId,
                                    ),
                                  ),
                                );
                              },
                              child: Text('Voir le rapport'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
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
}