//lib/utils/app_constants.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFFA53600);
  static const primaryContainer = Color(0xFFCB490E);
  static const primaryLight = Color(0xFFFFB59B);

  static const background = Color(0xFFFFF8F3);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFF4ECE6);
  static const surfaceContainerHigh = Color(0xFFEFE7E0);

  static const textDark = Color(0xFF1E1B17);
  static const textMedium = Color(0xFF594139);
  static const textGrey = Color(0xFF8D7167);
  static const outline = Color(0xFFE1BFB4);

  static const secondary = Color(0xFF5F5E5E);
  static const secondaryContainer = Color(0xFFE2DFDE);

  static const error = Color(0xFFBA1A1A);

  static const darkBackground = Color(0xFF1A1410);
  static const darkSurface = Color(0xFF24201C);
  static const darkCard = Color(0xFF2E2924);
  static const darkTextDark = Color(0xFFF7EFE9);
  static const darkTextGrey = Color(0xFF9E8E86);

  static const Map<String, Color> categoryColors = {
    'breakfast': Color(0xFFFFB347),
    'lunch': Color(0xFF87CEEB),
    'dinner': Color(0xFFDDA0DD),
    'dessert': Color(0xFFFFB6C1),
    'snack': Color(0xFF90EE90),
    'other': Color(0xFFD3D3D3),
  };
}

class AppCategories {
  static const List<Map<String, String>> categories = [
    {'key': 'breakfast', 'label': 'Kahvaltı', 'labelEn': 'Breakfast', 'emoji': '🍳'},
    {'key': 'lunch', 'label': 'Öğle Yemeği', 'labelEn': 'Lunch', 'emoji': '🥗'},
    {'key': 'dinner', 'label': 'Akşam Yemeği', 'labelEn': 'Dinner', 'emoji': '🍽️'},
    {'key': 'dessert', 'label': 'Tatlı', 'labelEn': 'Dessert', 'emoji': '🍰'},
    {'key': 'snack', 'label': 'Atıştırmalık', 'labelEn': 'Snack', 'emoji': '🥨'},
    {'key': 'other', 'label': 'Diğer', 'labelEn': 'Other', 'emoji': '🍴'},
  ];

  static String getLabelByKey(String key, {bool isEnglish = false}) {
    final cat = categories.firstWhere(
          (c) => c['key'] == key,
      orElse: () => {'label': 'Diğer', 'labelEn': 'Other'},
    );
    return isEnglish ? cat['labelEn']! : cat['label']!;
  }

  static String getEmojiByKey(String key) {
    return categories.firstWhere(
          (c) => c['key'] == key,
      orElse: () => {'emoji': '🍴'},
    )['emoji']!;
  }
}

class AppStrings {
  final bool isEnglish;
  const AppStrings({this.isEnglish = false});

  String get appName => 'Recipe App';
  String get tagline => isEnglish ? 'Share recipes, get inspired' : 'Tariflerini paylaş, ilham al';
  String get login => isEnglish ? 'Login' : 'Giriş Yap';
  String get register => isEnglish ? 'Register' : 'Kayıt Ol';
  String get logout => isEnglish ? 'Logout' : 'Çıkış Yap';
  String get profile => isEnglish ? 'Profile' : 'Profilim';
  String get home => isEnglish ? 'Home' : 'Ana Sayfa';
  String get search => isEnglish ? 'Search recipes...' : 'Tarif ara...';
  String get addRecipe => isEnglish ? 'New Recipe' : 'Yeni Tarif';
  String get save => isEnglish ? 'Save' : 'Kaydet';
  String get cancel => isEnglish ? 'Cancel' : 'İptal';
  String get delete => isEnglish ? 'Delete' : 'Sil';
  String get edit => isEnglish ? 'Edit' : 'Düzenle';
  String get myRecipes => isEnglish ? 'My Recipes' : 'Tariflerim';
  String get favorites => isEnglish ? 'Favorites' : 'Favorilerim';
  String get comments => isEnglish ? 'Comments' : 'Yorumlar';
  String get send => isEnglish ? 'Send' : 'Gönder';
  String get noRecipes => isEnglish ? 'No recipes yet' : 'Henüz tarif yok';
  String get noFavorites => isEnglish ? 'No favorites yet' : 'Henüz favori yok';
  String get noComments => isEnglish ? 'No comments yet. Be the first!' : 'Henüz yorum yok. İlk yorumu sen yap!';
  String get guestWarning => isEnglish ? 'Please login to use this feature' : 'Bu özellik için giriş yapmanız gerekiyor!';
  String get loginToContinue => isEnglish ? 'Login to Continue' : 'Giriş Yap';
  String get continueAsGuest => isEnglish ? 'Continue as Guest' : 'Misafir Olarak Devam Et';
  String get forgotPassword => isEnglish ? 'Forgot Password' : 'Şifremi Unuttum';
  String get email => isEnglish ? 'Email' : 'E-posta';
  String get password => isEnglish ? 'Password' : 'Şifre';
  String get emailRequired => isEnglish ? 'Email cannot be empty' : 'E-posta boş olamaz';
  String get invalidEmail => isEnglish ? 'Enter a valid email' : 'Geçerli e-posta girin';
  String get passwordRequired => isEnglish ? 'Password cannot be empty' : 'Şifre boş olamaz';
  String get enterEmailToReset => isEnglish ? 'Enter your email to receive a reset link' : 'Şifre sıfırlama bağlantısı için e-postanızı girin';
  String get darkTheme => isEnglish ? 'Dark Theme' : 'Karanlık Tema';
  String get language => isEnglish ? 'Language' : 'Dil';
  String get english => 'English';
  String get turkish => 'Türkçe';
  String get about => isEnglish ? 'About' : 'Hakkında';
  String get privacy => isEnglish ? 'Privacy Policy' : 'KVKK & Gizlilik';
  String get adminPanel => isEnglish ? 'Admin Panel' : 'Admin Paneli';
  String get ingredients => isEnglish ? 'Ingredients' : 'Malzemeler';
  String get steps => isEnglish ? 'Directions' : 'Yapılış';
  String get difficulty => isEnglish ? 'Difficulty' : 'Zorluk';
  String get duration => isEnglish ? 'Duration' : 'Süre';
  String get servings => isEnglish ? 'Servings' : 'Porsiyon';
  String get calories => isEnglish ? 'Calories' : 'Kalori';
  String get easy => isEnglish ? 'Easy' : 'Kolay';
  String get medium => isEnglish ? 'Medium' : 'Orta';
  String get hard => isEnglish ? 'Hard' : 'Zor';
  String get all => isEnglish ? 'All' : 'Tümü';
  String get newest => isEnglish ? 'Newest' : 'En Yeni';
  String get topRated => isEnglish ? 'Top Rated' : 'En Beğenilen';
  String ratingCount(int count) => isEnglish ? '$count ratings' : '$count değerlendirme';
  String get noRating => isEnglish ? 'Not rated yet' : 'Henüz değerlendirilmedi';
  String favoriteCount(int count) => isEnglish ? '$count people favorited' : '$count kişi favorilere ekledi';
  String get yourRating => isEnglish ? 'Your Rating: ' : 'Puanınız: ';
  String get writeComment => isEnglish ? 'Write a comment...' : 'Yorumunuzu yazın...';
  String get dietTags => isEnglish ? 'Diet Tags' : 'Diyet Etiketleri';
  String get recipeAdded => isEnglish ? 'Recipe added! 🎉' : 'Tarif başarıyla eklendi! 🎉';
  String get recipeUpdated => isEnglish ? 'Recipe updated! ✅' : 'Tarif güncellendi! ✅';
  String get commentAdded => isEnglish ? 'Comment added! 🎉' : 'Yorumunuz eklendi! 🎉';
  String get passwordResetSent => isEnglish ? 'Password reset email sent! 📧' : 'Şifre sıfırlama e-postası gönderildi! 📧';
  String get settings => isEnglish ? 'Settings' : 'Ayarlar';
  String get noAccountYet => isEnglish ? "Don't have an account? " : 'Hesabın yok mu? ';
  String get addPhoto => isEnglish ? 'Add Photo (optional)' : 'Fotoğraf Ekle (isteğe bağlı)';
  String get changePhoto => isEnglish ? 'Change Photo' : 'Fotoğraf Değiştir';
  String get recipeName => isEnglish ? 'Recipe Name *' : 'Tarif Adı *';
  String get description => isEnglish ? 'Description *' : 'Açıklama *';
  String get category => isEnglish ? 'Category' : 'Kategori';
  String get addIngredient => isEnglish ? 'Add ingredient...' : 'Malzeme ekle...';
  String get addStep => isEnglish ? 'Add step...' : 'Adım ekle...';
  String get add => isEnglish ? 'Add' : 'Ekle';
  String get deleteRecipeTitle => isEnglish ? 'Delete Recipe' : 'Tarifi Sil';
  String get deleteRecipeConfirm => isEnglish
      ? 'Are you sure you want to delete this recipe?'
      : 'Bu tarifi silmek istediğinizden emin misiniz?';
  String get loginRequired => isEnglish ? 'Login Required' : 'Giriş Yapmanız Gerekiyor';
  String get loginRequiredMsg => isEnglish
      ? 'Please login or create an account to use this feature.'
      : 'Bu özelliği kullanmak için lütfen giriş yapın veya hesap oluşturun.';

  // Spin Wheel Strings
  String get chooseOptionCount => isEnglish ? 'Select number of options' : 'Kaç adet seçenek olacağını seçiniz';
  String get selectRecipes => isEnglish ? 'Select Recipes' : 'Tarifleri Seçiniz';
  String get imFeelingLucky => isEnglish ? "I'm Feeling Lucky" : 'Şansıma Güveniyorum';
  String selectedRecipesCountLabel(int count) => isEnglish ? '$count recipes selected' : '$count tarif seçildi';
  String pickXRecipes(int x) => isEnglish ? 'Pick $x recipes' : '$x tarif seçin';
  String get luckyRecipeTitle => isEnglish ? '🎉 Here is your choice!' : '🎉 İşte senin seçimin!';
  String get viewRecipe => isEnglish ? 'View Recipe' : 'Tarifi Gör';
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      background: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.workSansTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.textDark),
      titleTextStyle: GoogleFonts.workSans(
        color: AppColors.textDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.textGrey),
      hintStyle: const TextStyle(color: AppColors.textGrey),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withOpacity(0.12),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceContainer,
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMedium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      side: BorderSide.none,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    textTheme: GoogleFonts.workSansTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.darkTextDark),
      titleTextStyle: GoogleFonts.workSans(
        color: AppColors.darkTextDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF3D3530), width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3D3530)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3D3530)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.darkTextGrey),
      hintStyle: const TextStyle(color: AppColors.darkTextGrey),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      indicatorColor: AppColors.primary.withOpacity(0.2),
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
