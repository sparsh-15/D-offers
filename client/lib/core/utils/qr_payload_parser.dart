import 'dart:convert';

class ParsedQrPayload {
  final String couponCode;
  final String? offerId;

  const ParsedQrPayload({
    required this.couponCode,
    this.offerId,
  });
}

class QrPayloadParser {
  static final RegExp _jsonHint = RegExp(r'^\s*[\{\[]');

  static ParsedQrPayload parse(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return const ParsedQrPayload(couponCode: '');
    }

    final jsonPayload = _parseJsonPayload(value);
    if (jsonPayload != null && jsonPayload.couponCode.isNotEmpty) {
      return jsonPayload;
    }

    final uriPayload = _parseUriPayload(value);
    if (uriPayload != null && uriPayload.couponCode.isNotEmpty) {
      return uriPayload;
    }

    return ParsedQrPayload(couponCode: value);
  }

  static ParsedQrPayload? _parseJsonPayload(String value) {
    if (!_jsonHint.hasMatch(value)) return null;

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;

      final map = Map<String, dynamic>.from(decoded);
      final couponCode = _pick(map, const [
        'couponCode',
        'coupon_code',
        'coupon',
        'code',
        'coupon_code_value',
      ]);

      final offerId = _pick(map, const [
        'offerId',
        'offer_id',
        'offer',
        'offerID',
      ]);

      if (couponCode.isEmpty) return null;

      return ParsedQrPayload(
        couponCode: couponCode,
        offerId: offerId.isEmpty ? null : offerId,
      );
    } catch (_) {
      return null;
    }
  }

  static ParsedQrPayload? _parseUriPayload(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    final query = uri.queryParameters;
    String couponCode = _pick(query, const [
      'couponCode',
      'coupon_code',
      'coupon',
      'code',
    ]);

    String offerId = _pick(query, const [
      'offerId',
      'offer_id',
      'offer',
    ]);

    if (couponCode.isEmpty) {
      final segments =
          uri.pathSegments.where((s) => s.trim().isNotEmpty).toList();
      if (segments.isNotEmpty) {
        couponCode = segments.last.trim();
      }
    }

    if (couponCode.isEmpty) return null;

    return ParsedQrPayload(
      couponCode: couponCode,
      offerId: offerId.isEmpty ? null : offerId,
    );
  }

  static String _pick(Map map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }
    return '';
  }
}
