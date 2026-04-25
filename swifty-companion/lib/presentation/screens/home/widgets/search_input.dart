// Home ekranindaki arama kutusu. Kullanici login girer, onaylar ve
// Profile ekranina yonlendirilir. Validasyon burada yapilir; bos veya
// hatali input'ta inline mesaj gosterilir (API'ya hic cikmaz).

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/repositories/user_repository.dart';

class SearchInput extends StatefulWidget {
  const SearchInput({super.key});

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorKey;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorKey = 'errors.empty_login');
      return;
    }
    if (!UserRepository.isValidLogin(raw)) {
      setState(() => _errorKey = 'errors.invalid_login');
      return;
    }
    setState(() => _errorKey = null);
    _focusNode.unfocus();
    context.goNamed(
      'profile',
      queryParameters: {'login': raw.toLowerCase()},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          enableSuggestions: false,
          // 42 login kurallari: sadece kucuk harf, digit, - ve _.
          // Klavyeden direkt filtreliyoruz - hem UX iyilesir hem guvenlik.
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
            LengthLimitingTextInputFormatter(32),
          ],
          style: AppTextStyles.bodyLarge,
          onSubmitted: (_) => _submit(),
          onChanged: (_) {
            if (_errorKey != null) {
              setState(() => _errorKey = null);
            }
          },
          decoration: InputDecoration(
            hintText: 'home.search_hint'.tr(),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textTertiary,
            ),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _controller.clear();
                      setState(() => _errorKey = null);
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textTertiary,
                  ),
          ),
        ),
        if (_errorKey != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorKey!.tr(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
