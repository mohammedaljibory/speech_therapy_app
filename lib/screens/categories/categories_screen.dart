import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/themes.dart';
import '../../config/routes.dart';
import '../../models/category_model.dart';
import '../../providers/categories_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/permissions.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CategoriesProvider>().loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F0FF), Color(0xFFFFFBF5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Consumer<CategoriesProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.categories.isEmpty) {
                      return _buildEmptyState();
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: provider.categories.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryCard(
                          provider.categories[index],
                          index,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Permissions.canAddCategories(
              context.read<AuthProvider>().currentUser)
          ? GradientFAB(
              icon: Icons.add,
              onPressed: () => _showAddCategoryDialog(),
              gradient: AppColors.gradientPurple,
            )
          : null,
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final nameEnController = TextEditingController();
    String selectedIcon = 'category';
    int selectedColor = AppColors.primaryBlue.value;

    final icons = [
      ('category', Icons.category),
      ('pets', Icons.pets),
      ('home', Icons.home),
      ('directions_car', Icons.directions_car),
      ('restaurant', Icons.restaurant),
      ('sports_soccer', Icons.sports_soccer),
      ('school', Icons.school),
      ('favorite', Icons.favorite),
      ('star', Icons.star),
      ('music_note', Icons.music_note),
      ('nature', Icons.nature),
      ('face', Icons.face),
    ];

    final colors = [
      AppColors.primaryBlue.value,
      AppColors.primaryPink.value,
      AppColors.primaryOrange.value,
      AppColors.primaryPurple.value,
      Colors.green.value,
      Colors.red.value,
      Colors.teal.value,
      Colors.amber.value,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'إضافة قسم جديد',
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم القسم بالعربية',
                    hintText: 'مثال: الحيوانات',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameEnController,
                  decoration: InputDecoration(
                    labelText: 'اسم القسم بالإنجليزية',
                    hintText: 'Example: Animals',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('اختر الأيقونة:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((iconData) {
                    final isSelected = selectedIcon == iconData.$1;
                    return InkWell(
                      onTap: () {
                        setDialogState(() => selectedIcon = iconData.$1);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected ? Color(selectedColor).withOpacity(0.2) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border.all(color: Color(selectedColor), width: 2) : null,
                        ),
                        child: Icon(
                          iconData.$2,
                          color: isSelected ? Color(selectedColor) : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                const Text('اختر اللون:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((colorValue) {
                    final isSelected = selectedColor == colorValue;
                    return InkWell(
                      onTap: () {
                        setDialogState(() => selectedColor = colorValue);
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(colorValue),
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            Consumer<CategoriesProvider>(
              builder: (context, provider, _) => ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('يرجى إدخال اسم القسم')),
                          );
                          return;
                        }
                        final result = await provider.addCategory(
                          name: nameController.text.trim(),
                          nameEn: nameEnController.text.trim().isNotEmpty
                              ? nameEnController.text.trim()
                              : nameController.text.trim(),
                          icon: selectedIcon,
                          colorValue: selectedColor,
                        );
                        if (result != null && ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم إضافة القسم بنجاح'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(selectedColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('إضافة', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CustomIconButton(
            icon: Icons.arrow_forward,
            onPressed: () => Navigator.pop(context),
            backgroundColor: Colors.white,
          ),
          const SizedBox(width: 16),
          Text(
            'الأقسام',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: category.color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.navigateTo(
              Routes.categoryWords,
              arguments: {
                'categoryId': category.id,
                'categoryName': category.name,
              },
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    category.iconData,
                    color: category.color,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${category.wordCount} كلمة',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).scale(
          begin: const Offset(0.8, 0.8),
          delay: Duration(milliseconds: index * 50),
        );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text('لا توجد أقسام'),
        ],
      ),
    );
  }
}
