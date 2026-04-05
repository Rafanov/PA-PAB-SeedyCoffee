import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/helpers.dart';
import '../../models/menu_model.dart';
import '../../providers/app_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/brew_button.dart';
import '../../widgets/brew_snackbar.dart';

class AdminMenuFormScreen extends StatefulWidget {
  final MenuModel? editing;
  const AdminMenuFormScreen({super.key, this.editing});

  @override
  State<AdminMenuFormScreen> createState() => _State();
}

class _State extends State<AdminMenuFormScreen> {
  bool _saving = false;
  Uint8List? _croppedBytes;

  late final _name  = TextEditingController(text: widget.editing?.name ?? '');
  late final _price = TextEditingController(
      text: widget.editing != null ? '${widget.editing!.price}' : '');
  late final _orig  = TextEditingController(
      text: widget.editing?.originalPrice != null
          ? '${widget.editing!.originalPrice}' : '');
  late final _desc  = TextEditingController(
      text: widget.editing?.description ?? '');

  late String  _catId       = widget.editing?.categoryId   ?? '';
  late String  _catName     = widget.editing?.categoryName ?? '';
  late String? _label       = widget.editing?.badge;
  late bool    _isAvailable = widget.editing?.isAvailable ?? true;
  late bool    _hasSizes    = widget.editing?.sizeOptions  != null;
  late bool    _hasSugar    = widget.editing?.sugarOptions != null;
  late bool    _hasIce      = widget.editing?.iceOptions   != null;

  @override
  void initState() {
    super.initState();
    if (_catId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cats = context.read<AppProvider>().categories;
        if (cats.isNotEmpty && mounted) {
          setState(() { _catId = cats.first.id; _catName = cats.first.name; });
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _price, _orig, _desc]) c.dispose();
    super.dispose();
  }

  Future<void> _pickAndCrop() async {
    final bytes = await StorageService.instance.pickAndCrop(
      context, aspectRatio: 1.0, title: 'Crop Menu Photo');
    if (bytes != null) setState(() => _croppedBytes = bytes);
  }

  Future<void> _save() async {
    final p = context.read<AppProvider>();
    if (_name.text.isEmpty || _price.text.isEmpty || _catId.isEmpty) {
      BrewSnackbar.show(context, 'Name, price & category are required!', isError: true);
      return;
    }
    final price = int.tryParse(_price.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (price == null) {
      BrewSnackbar.show(context, 'Price must be a number!', isError: true);
      return;
    }

    setState(() => _saving = true);

    String? imageUrl = widget.editing?.imageUrl;
    if (_croppedBytes != null) {
      imageUrl = await StorageService.instance.uploadMenuImageFromBytes(_croppedBytes!);
      if (imageUrl == null && mounted) {
        BrewSnackbar.show(context,
            'Upload failed — check Supabase Storage policy.', isError: true);
        setState(() => _saving = false);
        return;
      }
    }

    final menu = MenuModel(
      id:           widget.editing?.id ?? '${DateTime.now().millisecondsSinceEpoch}',
      categoryId:   _catId,
      categoryName: _catName,
      name:         _name.text.trim(),
      description:  _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      price:        price,
      originalPrice: _orig.text.isNotEmpty
          ? int.tryParse(_orig.text.replaceAll(RegExp(r'[^0-9]'), '')) : null,
      badge:        _label,
      isAvailable:  _isAvailable,
      imageUrl:     imageUrl,
      sizeOptions:  _hasSizes ? ['Small', 'Medium', 'Large'] : null,
      sugarOptions: _hasSugar ? ['Normal', 'Less', 'No Sugar'] : null,
      iceOptions:   _hasIce   ? ['Hot', 'Iced'] : null,
    );

    final error = widget.editing != null
        ? await p.updateMenu(menu)
        : await p.addMenu(menu);

    setState(() => _saving = false);
    if (!mounted) return;

    if (error != null) {
      BrewSnackbar.show(context, 'Error: $error', isError: true);
    } else {
      BrewSnackbar.show(context,
          widget.editing != null ? '✅ Menu updated!' : '✅ Menu added!');
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.editing != null ? 'Edit Menu' : 'Add Menu',
          style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // ── Image picker ──────────────────────────────────────
        GestureDetector(
          onTap: _pickAndCrop,
          child: Container(
            height: 180, width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.silverGray, width: 1.5)),
            clipBehavior: Clip.hardEdge,
            child: Stack(fit: StackFit.expand, children: [
              if (_croppedBytes != null)
                Image.memory(_croppedBytes!, fit: BoxFit.cover)
              else if (widget.editing?.imageUrl != null &&
                  widget.editing!.imageUrl!.isNotEmpty)
                Image.network(widget.editing!.imageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgPlaceholder())
              else
                _imgPlaceholder(),
              if (_croppedBytes != null ||
                  (widget.editing?.imageUrl?.isNotEmpty == true))
                Positioned(bottom: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.crop_rotate_rounded, color: Colors.white, size: 13),
                      SizedBox(width: 4),
                      Text('Change & Crop', style: TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ]))),
              Positioned(top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.black45, borderRadius: BorderRadius.circular(6)),
                  child: const Text('1:1 Square', style: TextStyle(
                      color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)))),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // ── Form fields ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
                color: AppColors.black.withOpacity(0.08), blurRadius: 16)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Name
            _field('Menu Name *', _name, 'e.g. Velvet Cappuccino', maxLength: 100,
                formatters: [FilteringTextInputFormatter.deny(RegExp(r'[^\x00-\xFF]'))]),

            // Category
            Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CATEGORY', style: AppTextStyles.labelSmall),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _catId.isEmpty ? null : _catId,
                  items: p.categories.map((c) => DropdownMenuItem(
                      value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v) {
                    final cat = p.categories.firstWhere((c) => c.id == v!);
                    setState(() { _catId = cat.id; _catName = cat.name; });
                  },
                  decoration: const InputDecoration(),
                  hint: const Text('Select category'),
                ),
              ])),

            // Price
            _field('Price (Rp) *', _price, '35000',
                type: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6),

            // Original Price
            _field('Original Price (optional)', _orig, '45000',
                type: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6),

            // Menu Label
            Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('MENU LABEL (OPTIONAL)', style: AppTextStyles.labelSmall),
                const SizedBox(height: 6),
                DropdownButtonFormField<String?>(
                  value: _label,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Label')),
                    ...MenuModel.labels.map((l) =>
                        DropdownMenuItem(value: l, child: Text(l))),
                  ],
                  onChanged: (v) => setState(() => _label = v),
                  decoration: const InputDecoration(),
                ),
              ])),

            // Availability toggle
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _isAvailable ? AppColors.successBg : AppColors.errorBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isAvailable
                      ? AppColors.success.withOpacity(0.4)
                      : AppColors.error.withOpacity(0.4))),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('KETERSEDIAAN MENU', style: AppTextStyles.labelSmall),
                  const SizedBox(height: 2),
                  Text(_isAvailable ? 'Tersedia' : 'Sold Out',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: _isAvailable ? AppColors.successText : AppColors.error,
                          fontWeight: FontWeight.w700)),
                ]),
                Switch.adaptive(
                  value: _isAvailable,
                  onChanged: (v) => setState(() => _isAvailable = v),
                  activeColor: Colors.white,
                  activeTrackColor: AppColors.black,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: AppColors.error,
                ),
              ])),

            // ── CUSTOMIZATION TOGGLES ─────────────────────────
            Text('CUSTOMIZATION OPTIONS', style: AppTextStyles.labelSmall),
            const SizedBox(height: 10),

            // Size toggle
            _toggle(
              label: 'Size',
              subtitle: _hasSizes ? 'Small · Medium · Large' : 'Tidak ada pilihan size',
              icon: Icons.straighten_rounded,
              value: _hasSizes,
              onChange: (v) => setState(() => _hasSizes = v),
            ),
            const SizedBox(height: 8),

            // Sugar toggle
            _toggle(
              label: 'Sugar Level',
              subtitle: _hasSugar ? 'Normal · Less · No Sugar' : 'Tidak ada pilihan gula',
              icon: Icons.water_drop_outlined,
              value: _hasSugar,
              onChange: (v) => setState(() => _hasSugar = v),
            ),
            const SizedBox(height: 8),

            // Ice/Temp toggle
            _toggle(
              label: 'Ice / Temp',
              subtitle: _hasIce ? 'Hot · Iced' : 'Tidak ada pilihan suhu',
              icon: Icons.thermostat_rounded,
              value: _hasIce,
              onChange: (v) => setState(() => _hasIce = v),
            ),
            const SizedBox(height: 16),

            // Description
            _field('Description', _desc, 'Describe this menu...',
                maxLines: 3,
                formatters: [FilteringTextInputFormatter.deny(RegExp(r'[^\x00-\xFF]'))],
                maxLength: 500),
          ]),
        ),
        const SizedBox(height: 16),
        BrewButton(
          label: widget.editing != null ? 'Save Changes' : 'Add Menu',
          isLoading: _saving,
          onPressed: _save,
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _imgPlaceholder() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.midGray),
      const SizedBox(height: 8),
      Text('Tap to pick & crop photo', style: AppTextStyles.bodySmall),
      Text('1:1 square · max 2MB', style: AppTextStyles.caption),
    ]);

  Widget _field(String label, TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text, int maxLines = 1,
       List<TextInputFormatter>? formatters, int? maxLength}) =>
    Padding(padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: AppTextStyles.labelSmall),
        const SizedBox(height: 6),
        TextField(
            controller: ctrl, keyboardType: type, maxLines: maxLines,
            maxLength: maxLength,
            inputFormatters: formatters,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
                hintText: hint,
                counterText: maxLength != null ? null : '')),
      ]));

  // ── Toggle card yang proper ───────────────────────────────
  Widget _toggle({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChange,
  }) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: value ? AppColors.brown50 : AppColors.offWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppColors.brown300 : AppColors.silverGray,
          width: 1.5)),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(
            color: value ? AppColors.brown100 : Colors.white,
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18,
              color: value ? AppColors.brown500 : AppColors.midGray)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.labelMedium),
          Text(subtitle, style: AppTextStyles.caption.copyWith(
              color: value ? AppColors.brown400 : AppColors.textMuted)),
        ])),
        Switch.adaptive(
          value: value,
          onChanged: onChange,
          activeColor: Colors.white,
          activeTrackColor: AppColors.black,
          inactiveThumbColor: AppColors.lightGray,
          inactiveTrackColor: AppColors.silverGray,
        ),
      ]));
}