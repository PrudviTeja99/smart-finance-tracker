import 'package:flutter/material.dart';

class IconHelper {
  static const Map<String, IconData> _iconMap = {
    // Food & Dining
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'cake': Icons.cake,
    'fastfood': Icons.fastfood,
    'local_bar': Icons.local_bar,
    'kitchen': Icons.kitchen,

    // Shopping
    'shopping_bag': Icons.shopping_bag,
    'shopping_cart': Icons.shopping_cart,
    'store': Icons.store,
    'local_mall': Icons.local_mall,
    'loyalty': Icons.loyalty,
    'card_giftcard': Icons.card_giftcard,

    // Transportation
    'directions_car': Icons.directions_car,
    'flight': Icons.flight,
    'directions_bike': Icons.directions_bike,
    'directions_bus': Icons.directions_bus,
    'train': Icons.train,
    'local_taxi': Icons.local_taxi,
    'ev_station': Icons.ev_station,

    // Utilities & Bills
    'receipt': Icons.receipt,
    'flash_on': Icons.flash_on,
    'water_drop': Icons.water_drop,
    'wifi': Icons.wifi,
    'phone_android': Icons.phone_android,
    'tv': Icons.tv,
    'home_repair_service': Icons.home_repair_service,

    // Entertainment & Leisure
    'movie': Icons.movie,
    'gamepad': Icons.gamepad,
    'music_note': Icons.music_note,
    'sports_esports': Icons.sports_esports,
    'theater_comedy': Icons.theater_comedy,
    'sports_soccer': Icons.sports_soccer,
    'fitness_center': Icons.fitness_center,
    'spa': Icons.spa,
    'book': Icons.book,

    // Medical & Health
    'medical_services': Icons.medical_services,
    'health_and_safety': Icons.health_and_safety,
    'vaccines': Icons.vaccines,
    'healing': Icons.healing,
    'local_hospital': Icons.local_hospital,

    // Income & Finance
    'attach_money': Icons.attach_money,
    'trending_up': Icons.trending_up,
    'savings': Icons.savings,
    'monetization_on': Icons.monetization_on,
    'work': Icons.work,
    'business_center': Icons.business_center,
    'credit_card': Icons.credit_card,

    // Education & Family
    'school': Icons.school,
    'child_care': Icons.child_care,
    'pets': Icons.pets,
    'family_restroom': Icons.family_restroom,
    'escalator_warning': Icons.escalator_warning,

    // Lifestyle & Home
    'home': Icons.home,
    'hotel': Icons.hotel,
    'cleaning_services': Icons.cleaning_services,
    'brush': Icons.brush,
    'local_laundry_service': Icons.local_laundry_service,

    // Others & Tools
    'more_horiz': Icons.more_horiz,
    'build': Icons.build,
    'settings': Icons.settings,
    'security': Icons.security,
    'public': Icons.public,
    'star': Icons.star,
  };

  // Convert key to IconData, falling back to a default
  static IconData getIcon(String? key) {
    if (key == null) return Icons.more_horiz;
    return _iconMap[key] ?? Icons.more_horiz;
  }

  // Get keys representing all icons in the library
  static List<String> getAllKeys() {
    return _iconMap.keys.toList();
  }

  // Get map of all icons
  static Map<String, IconData> getMap() {
    return _iconMap;
  }

  // Label matching/descriptions for search filtering
  static final Map<String, String> _searchKeywords = {
    'restaurant': 'food restaurant eating dining cafe hotel meal lunch dinner',
    'local_cafe': 'coffee tea cafe drink beverage local_cafe startbucks breakfast',
    'cake': 'cake birthday sweet desert party bakery celebration',
    'fastfood': 'burger fastfood pizza chips junk food cola snack',
    'local_bar': 'bar drink alcohol wine beer pub night party',
    'kitchen': 'kitchen grocery cooking fridge food house',
    'shopping_bag': 'shopping bag clothes fashion mall store purchase buy',
    'shopping_cart': 'shopping cart grocery super market e-commerce buy online',
    'store': 'store shop local business buy vendor market',
    'local_mall': 'mall shopping brand center plaza clothing',
    'loyalty': 'discount coupon voucher reward point membership tag loyalty',
    'card_giftcard': 'gift card present birthday voucher surprise celebration',
    'directions_car': 'car drive travel auto vehicle fuel petrol diesel road',
    'flight': 'flight plane travel holiday airport vacation ticket travel',
    'directions_bike': 'bike cycle fitness sport travel ride pedal',
    'directions_bus': 'bus travel transport public transit ticket ticket',
    'train': 'train metro railway transit ticket public',
    'local_taxi': 'taxi cab travel auto uber ola rent car',
    'ev_station': 'electric car ev station charge power battery auto',
    'receipt': 'receipt bill invoice tax document transaction paper utility',
    'flash_on': 'electricity power light flash energy current shock bill',
    'water_drop': 'water bill utility drop pipe liquid tap supply',
    'wifi': 'wifi internet data broadband network router connection bill',
    'phone_android': 'phone mobile recharge cell call android internet bill',
    'tv': 'tv television cable dth subscription netflix entertainment media bill',
    'home_repair_service': 'maintenance repair plumber electrician home service fix construct',
    'movie': 'movie cinema theater film show netflix ticket popcorn entertainment',
    'gamepad': 'game video playstation xbox computer play toy fun console',
    'music_note': 'music song audio spotify concert head phone instrument entertainment',
    'sports_esports': 'game controller esports playstation console play toys',
    'theater_comedy': 'comedy drama show ticket theater movie play actor standup',
    'sports_soccer': 'football soccer sport play match game stadium ground fit',
    'fitness_center': 'gym fitness exercise body workout weight sports health',
    'spa': 'spa massage salon hair beauty relax treatment care self',
    'book': 'book read study school library education book novel',
    'medical_services': 'medical doctor health clinic services hospital medicine pharmacy firstaid',
    'health_and_safety': 'insurance policy safety health cover shield life accident secure',
    'vaccines': 'vaccines injection covid medical health test cure disease',
    'healing': 'injury bandage healing health plaster wound hospital care medical',
    'local_hospital': 'hospital clinic doctor emergency local_hospital medical ambulance redcross',
    'attach_money': 'salary cash cash inflow currency dollar rupee money finance asset wealth',
    'trending_up': 'investment profit stock share mutual fund rise trend market growth crypto',
    'savings': 'savings piggy bank gold deposit future reserve safety money coin',
    'monetization_on': 'coin cash money inflow interest return royalty gold',
    'work': 'work job office salary business workspace employee desk career',
    'business_center': 'business bag office travel work conference deal client executive',
    'credit_card': 'card bank payment credit debit visa master card online',
    'school': 'school college education university course exam fees book study student',
    'child_care': 'kids baby child care school toy diaper nanny dress family',
    'pets': 'dog cat pet food vet animal birds fish care loyalty',
    'family_restroom': 'family parents house relative children warning restroom life',
    'escalator_warning': 'family children safety kids warning parenting parent',
    'home': 'home rent house mortgage room stay building property flat land EMI',
    'hotel': 'hotel stay tour travel holiday room resort booking vacation lodge',
    'cleaning_services': 'maid cleaning dust service broom clean wash laundry sweep garbage',
    'brush': 'paint art design decor repair brush hobby drawing color creative',
    'local_laundry_service': 'laundry wash clothes dry clean local_laundry_service iron detergent machine',
    'more_horiz': 'others misc general tools category extra dots option three',
    'build': 'tools repair fix construct labor plumbing maintenance hardware key wrench',
    'settings': 'settings configure system options preference security control',
    'security': 'security lock guard safety protection alarm system shield data private',
    'public': 'globe internet web online global foreign travel environment earth',
    'star': 'star favorite rating highlight reward premium special points',
  };

  // Search icons by a query string
  static List<String> searchIcons(String query) {
    if (query.isEmpty) return getAllKeys();
    final lowerQuery = query.toLowerCase();
    return _iconMap.keys.where((key) {
      if (key.toLowerCase().contains(lowerQuery)) return true;
      final keywords = _searchKeywords[key];
      return keywords != null && keywords.contains(lowerQuery);
    }).toList();
  }
}
