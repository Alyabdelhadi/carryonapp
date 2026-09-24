import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../domain/entities/entities.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/text/typography.dart';
import 'order_form_section_card.dart';

/// The other party of the exchange: name and phone with the country
/// phone-code picker (the Ionic `s_name` / `s_phone` or `r_name` /
/// `r_phone` inputs, depending on the flow).
class OrderFormContactSection extends StatelessWidget {
  const OrderFormContactSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.nameHint,
    required this.phoneHint,
    required this.nameController,
    required this.phoneController,
    required this.country,
    required this.onPickCountry,
    required this.countriesLoading,
  });

  final String title;
  final String subtitle;
  final String nameHint;
  final String phoneHint;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final Country? country;
  final VoidCallback onPickCountry;
  final bool countriesLoading;

  @override
  Widget build(BuildContext context) {
    return OrderFormSectionCard(
      icon: Icons.person_outline_rounded,
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: nameHint,
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
          ),
          Gap(context.dimensions.space.s12),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.start,
            decoration: InputDecoration(
              hintText: phoneHint,
              prefixIcon: _CountryCodeButton(
                country: country,
                loading: countriesLoading,
                onTap: onPickCountry,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The flag + phone code + caret that opens the country picker.
class _CountryCodeButton extends StatelessWidget {
  const _CountryCodeButton({
    required this.country,
    required this.loading,
    required this.onTap,
  });

  final Country? country;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = country == null
        ? (loading ? '…' : '+')
        : '${country!.flag ?? ''} ${country!.phoneCode ?? ''}'.trim();
    // "🇱🇧 +961" keeps its plus sign in front of the digits in Arabic too.
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.dimensions.radius.medium),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.dimensions.space.s12),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LabelText(label),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: context.dimensions.size.iconLarge,
                color: context.color.text.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
