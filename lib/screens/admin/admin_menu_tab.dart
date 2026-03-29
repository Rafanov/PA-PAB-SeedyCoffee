import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../models/menu_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/brew_button.dart';
import '../../widgets/brew_snackbar.dart';
import 'admin_menu_form_screen.dart';

class AdminMenuTab extends StatelessWidget {
  const AdminMenuTab({super.key});

  void _openForm(BuildContext context, [MenuModel? editing]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true, // covers ENTIRE screen including admin header
        builder: (_) => AdminMenuFormScreen(editing: editing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return ListView(padding: const EdgeInsets.all(16), children: [
      BrewButton(label: 'Add New Menu', 
          onPressed: () => _openForm(context)),
      const SizedBox(height: 20),
      Text('Menu (${p.menus.length})',
          style: AppTextStyles.displaySmall.copyWith(fontSize: 16)),
      const SizedBox(height: 12),
      for (final m in p.menus)
        _MenuTile(
          menu: m,
          onEdit: () => _openForm(context, m),
          onDelete: () => _confirmDelete(context, p, m),
        ),
      if (p.menus.isEmpty)
        Padding(padding: const EdgeInsets.all(32),
          child: Column(children: [
            const Icon(Icons.restaurant_menu_outlined,
                size: 48, color: AppColors.lightGray),
            const SizedBox(height: 12),
            Text('No menu yet. Tap "+ Add" to start!',
                style: AppTextStyles.bodySmall),
          ])),
    ]);
  }

  void _confirmDelete(BuildContext ctx, AppProvider p, MenuModel m) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Delete "${m.name}"?',
          style: AppTextStyles.displaySmall.copyWith(fontSize: 16)),
      content: Text('Menu will be removed permanently.',
          style: AppTextStyles.bodySmall),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Navigator.pop(ctx);
            final err = await p.deleteMenu(m.id);
            if (!ctx.mounted) return;
            err != null
                ? BrewSnackbar.show(ctx, 'Error: $err', isError: true)
                : BrewSnackbar.show(ctx, '${m.name} deleted!');
          },
          child: const Text('Delete',
              style: TextStyle(color: AppColors.error))),
      ]));
  }
}

class _MenuTile extends StatelessWidget {
  final MenuModel menu;
  final VoidCallback onEdit, onDelete;
  const _MenuTile({required this.menu, required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(
          color: AppColors.black.withOpacity(0.07), blurRadius: 10)]),
    child: Row(children: [
      Container(width: 52, height: 52,
        decoration: BoxDecoration(color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(12),
          image: (menu.imageUrl != null && menu.imageUrl!.isNotEmpty)
              ? DecorationImage(image: NetworkImage(menu.imageUrl!),
                  fit: BoxFit.cover)
              : null),
        child: (menu.imageUrl == null || menu.imageUrl!.isEmpty)
            ? const Center(child: Icon(Icons.coffee_rounded,
                color: AppColors.lightGray, size: 26))
            : null),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text(menu.name, style: AppTextStyles.labelMedium,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text('${menu.categoryName} · ${Helpers.formatPrice(menu.price)}',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.midGray)),
      ])),
      IconButton(icon: const Icon(Icons.edit_outlined,
          size: 18, color: AppColors.midGray), onPressed: onEdit),
      IconButton(icon: const Icon(Icons.delete_outline_rounded,
          size: 18, color: AppColors.error), onPressed: onDelete),
    ]),
  );
}
