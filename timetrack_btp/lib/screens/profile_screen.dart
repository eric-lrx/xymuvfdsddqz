import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Center(
        child: Text('Utilisateur non connecté'),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 16),
          
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            child: user.profileImage != null
                ? null
                : Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey[700],
                  ),
          ),
          SizedBox(height: 16),
          
          // Nom d'utilisateur
          Text(
            user.name,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          
          // Rôle
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _formatRole(user.role),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 32),
          
          // Informations de l'utilisateur
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.email),
                    title: Text('Email'),
                    subtitle: Text(user.email),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.phone),
                    title: Text('Téléphone'),
                    subtitle: Text(user.phoneNumber ?? 'Non renseigné'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          
          // Actions
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Paramètres'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      // À implémenter: écran des paramètres
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.help),
                    title: Text('Aide'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      // À implémenter: écran d'aide
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text(
                      'Déconnexion',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Déconnexion'),
                          content: Text('Voulez-vous vraiment vous déconnecter ?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                              },
                              child: Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                authProvider.logout();
                              },
                              child: Text('Déconnexion'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32),
          
          // Version de l'application
          Text(
            'TimeTrack BTP v1.0.0',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
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
}