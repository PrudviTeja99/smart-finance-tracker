import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class DashboardSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;

  const DashboardSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.dashboardSearchHint,
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            return value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded,
                        color: Colors.white54, size: 18),
                    onPressed: () {
                      controller.clear();
                      onClear();
                    },
                  )
                : const SizedBox.shrink();
          },
        ),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
