import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:hava_kontrol/screens/homeScreen.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Center(
        // İçeriği ekranın ortasına almak için Center widget'ı kullanıldı
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // İçeriklerin toplam boyutunu minimuma indir
          children: [
            LottieBuilder.asset(
              "assets/Lottie/Weather.json",
              width: 300, // Lottie animasyonunun boyutunu ayarla
              height: 300,
            ),
            const SizedBox(height: 20), // Animasyon ile metin arasında boşluk
            const Text(
              'MG23 - Hava Kalite Kontrol Sistemi',
              style: TextStyle(
                fontSize: 18, // Metin boyutunu azalt
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      nextScreen: const HomeScreen(),
      splashIconSize: 350, // Splash ikonunun boyutunu azalt
      backgroundColor: const Color.fromARGB(255, 107, 159, 248),
    );
  }
}
