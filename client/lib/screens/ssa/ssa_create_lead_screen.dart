import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/theme_helper.dart';
import '../../screens/common/create_lead_form.dart';
import '../../services/ssa_service.dart';

class SsaCreateLeadScreen extends StatelessWidget {
  const SsaCreateLeadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: ThemeHelper.getBackgroundGradient(context),
      ),
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          leading: ThemeHelper.buildBackButton(context),
          title: const Text('New Lead'),
        ),
        body: SafeArea(
          child: CreateLeadForm(
            title: 'Create a new shop lead',
            subtitle: 'Capture basic shop details and optionally attach a coupon code.',
            submitButtonLabel: 'Create Lead',
            loadCoupons: SsaService.instance.getCoupons,
            createLead: ({
              required String shopName,
              required String phone,
              String? ownerName,
              String? pincode,
              String? city,
              String? category,
              String? notes,
              String? couponCode,
              String? address,
              String? description,
            }) async {
              return SsaService.instance.createLead(
                shopName: shopName,
                phone: phone,
                ownerName: ownerName,
                pincode: pincode,
                city: city,
                category: category,
                notes: notes,
                couponCode: couponCode,
                address: address,
                description: description,
              );
            },
          ),
        ),
      ),
    );
  }
}
