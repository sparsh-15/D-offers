import 'package:flutter_test/flutter_test.dart';

import 'package:my_offers/core/utils/qr_payload_parser.dart';

void main() {
  group('QrPayloadParser', () {
    test('parses raw coupon text as couponCode', () {
      final result = QrPayloadParser.parse('SAVE20-ABC');

      expect(result.couponCode, 'SAVE20-ABC');
      expect(result.offerId, isNull);
    });

    test('parses json payload with couponCode and offerId', () {
      final result = QrPayloadParser.parse(
        '{"couponCode":"CPN-0099","offerId":"off-123"}',
      );

      expect(result.couponCode, 'CPN-0099');
      expect(result.offerId, 'off-123');
    });

    test('parses url payload query params', () {
      final result = QrPayloadParser.parse(
        'https://d-offers.app/redeem?coupon=AA11BB&offer_id=offer-9',
      );

      expect(result.couponCode, 'AA11BB');
      expect(result.offerId, 'offer-9');
    });

    test('falls back to path segment when no coupon query param', () {
      final result = QrPayloadParser.parse(
        'doffers://redeem/coupon/CODE777',
      );

      expect(result.couponCode, 'CODE777');
      expect(result.offerId, isNull);
    });
  });
}
