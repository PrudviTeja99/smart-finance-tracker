import 'dart:convert';
import 'package:http/http.dart' as http;

class MerchantSearchService {
  // Queries public search APIs for the merchant name and scans the description.
  // Returns a list of suggested generic categories that match the description.
  static Future<List<String>> searchMerchantCategory(String merchant) async {
    final cleanMerchant = merchant.trim();
    if (cleanMerchant.isEmpty) return [];

    try {
      String description = '';

      // Try DuckDuckGo Instant Answer API first
      final ddgUrl = Uri.parse('https://api.duckduckgo.com/?q=${Uri.encodeComponent(cleanMerchant)}&format=json&no_html=1');
      final ddgResponse = await http.get(ddgUrl).timeout(const Duration(seconds: 4));

      if (ddgResponse.statusCode == 200) {
        final decoded = jsonDecode(ddgResponse.body) as Map<String, dynamic>;
        description = (decoded['AbstractText'] as String?) ?? '';
      }

      // If DuckDuckGo returns nothing, fallback to Wikipedia OpenSearch API
      if (description.isEmpty) {
        final wikiUrl = Uri.parse('https://en.wikipedia.org/w/api.php?action=opensearch&search=${Uri.encodeComponent(cleanMerchant)}&limit=1&format=json&origin=*');
        final wikiResponse = await http.get(wikiUrl).timeout(const Duration(seconds: 4));

        if (wikiResponse.statusCode == 200) {
          final decoded = jsonDecode(wikiResponse.body) as List;
          // Wikipedia OpenSearch format: [query, [title], [description], [url]]
          if (decoded.length > 2 && (decoded[2] as List).isNotEmpty) {
            description = decoded[2][0] as String;
          }
        }
      }

      if (description.isEmpty) return [];

      return parseCategoryFromDescription(description);
    } catch (e) {
      print('Online search error: $e');
      return [];
    }
  }

  // Scan a description for generic category keywords
  static List<String> parseCategoryFromDescription(String desc) {
    final lower = desc.toLowerCase();
    final suggestions = <String>{};

    final keywordMap = {
      'Food': [
        'restaurant', 'food', 'cafe', 'dine', 'dining', 'bakery', 'kitchen', 'eatery',
        'pizza', 'burger', 'coffee', 'beverage', 'snack', 'grocery', 'supermarket'
      ],
      'Shopping': [
        'retailer', 'clothing', 'shoes', 'store', 'fashion', 'shop', 'mall', 'apparel',
        'goods', 'department', 'electronic', 'boutique', 'accessory', 'furniture'
      ],
      'Travel': [
        'transport', 'transit', 'taxi', 'ride', 'metro', 'bus', 'train', 'flight',
        'airline', 'fuel', 'petrol', 'diesel', 'cabs', 'cab', 'commute', 'automotive'
      ],
      'Bills & Utilities': [
        'utility', 'electricity', 'water', 'gas', 'power', 'telecom', 'recharge',
        'internet', 'broadband', 'phone', 'jio', 'airtel', 'subscription', 'billing'
      ],
      'Health & Fitness': [
        'gym', 'fitness', 'health', 'workout', 'yoga', 'sports', 'athletic', 'club',
        'exercise', 'wellness', 'nutrition'
      ],
      'Entertainment': [
        'stream', 'subscription', 'video', 'music', 'gaming', 'cinema', 'theater',
        'movie', 'show', 'entertainment', 'play', 'game'
      ],
    };

    keywordMap.forEach((category, keywords) {
      for (var kw in keywords) {
        if (lower.contains(kw)) {
          suggestions.add(category);
          break;
        }
      }
    });

    return suggestions.toList();
  }
}
