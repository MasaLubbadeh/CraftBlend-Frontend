import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Overview Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOverviewCard(
                  title: 'Followers',
                  value: '12.5K',
                  icon: Icons.person,
                  color: Colors.blue,
                ),
                _buildOverviewCard(
                  title: 'Engagement',
                  value: '8.7%',
                  icon: Icons.favorite,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Activities or Metrics
            const Text(
              'Top Posts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildPostTile(
              title: 'Post 1',
              subtitle: 'Engagement: 12%',
              imageUrl: 'https://via.placeholder.com/150',
            ),
            _buildPostTile(
              title: 'Post 2',
              subtitle: 'Engagement: 8%',
              imageUrl: 'https://via.placeholder.com/150',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTile({
    required String title,
    required String subtitle,
    required String imageUrl,
  }) {
    return Card(
      elevation: 3,
      child: ListTile(
        leading: Image.network(imageUrl, width: 50, height: 50),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navigate to post details
        },
      ),
    );
  }
}
