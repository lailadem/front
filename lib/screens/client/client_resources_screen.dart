import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';

class ClientResourcesScreen extends StatelessWidget {
  const ClientResourcesScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources & Support'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Section
            _buildSection(
              title: 'Emergency Support',
              icon: Icons.emergency,
              color: AppColors.errorRed,
              children: [
                _buildEmergencyCard(
                  title: 'National Suicide Prevention Lifeline',
                  subtitle: '24/7 Crisis Support',
                  number: '988',
                  description: 'Free, confidential support for people in distress',
                ),
                _buildEmergencyCard(
                  title: 'Crisis Text Line',
                  subtitle: 'Text for Support',
                  number: '741741',
                  description: 'Text HOME to connect with a crisis counselor',
                ),
                _buildEmergencyCard(
                  title: 'Emergency Services',
                  subtitle: 'Immediate Help',
                  number: '911',
                  description: 'For life-threatening emergencies',
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Mental Health Organizations
            _buildSection(
              title: 'Mental Health Organizations',
              icon: Icons.psychology,
              color: AppColors.primaryBlue,
              children: [
                _buildResourceCard(
                  title: 'National Alliance on Mental Illness (NAMI)',
                  subtitle: 'Support and Education',
                  description: 'Provides support, education, and advocacy for people with mental illness',
                  url: 'https://www.nami.org',
                  icon: Icons.people,
                ),
                _buildResourceCard(
                  title: 'MentalHealth.gov',
                  subtitle: 'Government Resources',
                  description: 'Official government information and resources on mental health',
                  url: 'https://www.mentalhealth.gov',
                  icon: Icons.info,
                ),
                _buildResourceCard(
                  title: 'Psychology Today',
                  subtitle: 'Find Therapists',
                  description: 'Directory to find therapists, psychiatrists, and treatment centers',
                  url: 'https://www.psychologytoday.com',
                  icon: Icons.search,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Self-Help Resources
            _buildSection(
              title: 'Self-Help Resources',
              icon: Icons.self_improvement,
              color: AppColors.successGreen,
              children: [
                _buildResourceCard(
                  title: 'Headspace',
                  subtitle: 'Meditation & Mindfulness',
                  description: 'Guided meditation and mindfulness exercises',
                  url: 'https://www.headspace.com',
                  icon: Icons.spa,
                ),
                _buildResourceCard(
                  title: 'Calm',
                  subtitle: 'Sleep & Relaxation',
                  description: 'Meditation, sleep stories, and relaxation techniques',
                  url: 'https://www.calm.com',
                  icon: Icons.bedtime,
                ),
                _buildResourceCard(
                  title: 'BetterHelp',
                  subtitle: 'Online Therapy',
                  description: 'Professional online therapy and counseling',
                  url: 'https://www.betterhelp.com',
                  icon: Icons.computer,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Crisis Information
            Card(
              color: AppColors.lightPurple,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.warningOrange),
                        const SizedBox(width: 8),
                        const Text(
                          'If you\'re in crisis:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Call 988 for the National Suicide Prevention Lifeline\n'
                      '• Text HOME to 741741 for Crisis Text Line\n'
                      '• Call 911 for immediate emergency assistance\n'
                      '• Go to your nearest emergency room',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildEmergencyCard({
    required String title,
    required String subtitle,
    required String number,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.lightBlue,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.errorRed,
          child: Text(
            number,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            Text(description, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _callNumber(number),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorRed,
            foregroundColor: Colors.white,
          ),
          child: const Text('Call'),
        ),
      ),
    );
  }

  Widget _buildResourceCard({
    required String title,
    required String subtitle,
    required String description,
    required String url,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.lightBlue,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryBlue, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            Text(description, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _launchUrl(url),
          child: const Text('Visit'),
        ),
      ),
    );
  }
} 