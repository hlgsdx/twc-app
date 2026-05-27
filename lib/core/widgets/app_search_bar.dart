import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    this.onChanged,
    this.onTap,
    this.hintText = 'search here',
    this.autofocus = false,
    this.showTrailingClear = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String hintText;
  final bool autofocus;
  final bool showTrailingClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            onSubmitted: onSubmitted,
            onChanged: onChanged,
            onTap: onTap,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: scheme.onSurfaceVariant),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: showTrailingClear && value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        controller.clear();
                        onChanged?.call('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        );
      },
    );
  }
}
