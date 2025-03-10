import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waterfinder/providers/water_source_provider.dart';
import 'package:waterfinder/models/water_source.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WaterSourceProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () => provider.loadWaterSources(),
            child: const CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: true,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Water Finder',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                      ),
                    ),
                    background: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.blue, Colors.blueAccent],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.water_drop,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مرحباً بك في تطبيق Water Finder',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ساعد مجتمعك في العثور على مصادر المياه النظيفة في السودان',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'كيف يمكنك المساعدة:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureCard(
                          context,
                          icon: Icons.location_on,
                          title: 'إضافة مصدر مياه',
                          description: 'شارك موقع مصدر مياه نظيف مع مجتمعك',
                          onTap: () => Navigator.pushNamed(context, '/add-source'),
                        ),
                        const SizedBox(height: 8),
                        _buildFeatureCard(
                          context,
                          icon: Icons.report_problem,
                          title: 'الإبلاغ عن مشكلة',
                          description: 'ساعد في تحذير الآخرين من المصادر الملوثة',
                          onTap: () => Navigator.pushNamed(context, '/report'),
                        ),
                        const SizedBox(height: 8),
                        _buildFeatureCard(
                          context,
                          icon: Icons.map,
                          title: 'البحث في الخريطة',
                          description: 'اعثر على أقرب مصدر مياه نظيف إليك',
                          onTap: () => Navigator.pushNamed(context, '/map'),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'مصادر المياه القريبة:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (provider.error != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        provider.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final source = provider.waterSources[index];
                        return _buildWaterSourceCard(context, source);
                      },
                      childCount: provider.waterSources.length,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterSourceCard(BuildContext context, WaterSource source) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          source.status == 'available' ? Icons.water_drop : Icons.warning,
          color: source.status == 'available' ? Colors.blue : Colors.red,
        ),
        title: Text(
          source.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        subtitle: Text(
          source.description,
          style: const TextStyle(fontFamily: 'Cairo'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/map',
            arguments: source,
          );
        },
      ),
    );
  }
}