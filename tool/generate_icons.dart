// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() async {
  print('Generating high-resolution MangoAI App Icons...');

  const size = 1024;
  final image = img.Image(width: size, height: size);

  // Background dark gradient with squircle
  final center = size / 2.0;
  final cornerRadius = size * 0.22; // iOS/Android squircle curve

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      // Check rounded rectangle bounds
      final dx = (x < cornerRadius)
          ? cornerRadius - x
          : (x > size - cornerRadius)
              ? x - (size - cornerRadius)
              : 0.0;
      final dy = (y < cornerRadius)
          ? cornerRadius - y
          : (y > size - cornerRadius)
              ? y - (size - cornerRadius)
              : 0.0;
      final distToCorner = math.sqrt(dx * dx + dy * dy);

      if (distToCorner > cornerRadius) {
        // Outside squircle: transparent
        image.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }

      // Inside squircle: Rich deep dark green/slate gradient
      final normY = y / size;

      // Dark radial glow from center
      final distFromCenter = math.sqrt((x - center) * (x - center) + (y - center) * (y - center)) / (size * 0.7);
      
      int r = (12 * (1.0 - distFromCenter * 0.5) + 15 * (1.0 - normY)).clamp(5, 30).toInt();
      int g = (28 * (1.0 - distFromCenter * 0.4) + 25 * (1.0 - normY)).clamp(10, 45).toInt();
      int b = (12 * (1.0 - distFromCenter * 0.5) + 10 * (1.0 - normY)).clamp(5, 25).toInt();

      // Squircle subtle border highlight
      if (distToCorner > cornerRadius - 4 || 
          (dx == 0 && (y < 4 || y > size - 4)) || 
          (dy == 0 && (x < 4 || x > size - 4))) {
        r = 60;
        g = 90;
        b = 60;
      }

      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // Draw Glowing AI Scanner Rings
  final ringRadius = size * 0.38;
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - center;
      final dy = y - center;
      final dist = math.sqrt(dx * dx + dy * dy);
      final angle = math.atan2(dy, dx);

      // Outer radar ring
      final ringDist = (dist - ringRadius).abs();
      if (ringDist < 6.0) {
        final alpha = (1.0 - ringDist / 6.0);
        // Angle gradient from golden amber to emerald green
        final t = (math.sin(angle * 2) + 1) / 2;
        final ringR = (255 * (1 - t) + 67 * t).toInt();
        final ringG = (179 * (1 - t) + 160 * t).toInt();
        final ringB = (0 * (1 - t) + 71 * t).toInt();
        
        _blendPixel(image, x, y, ringR, ringG, ringB, (alpha * 0.65).clamp(0.0, 1.0));
      }

      // Inner tech ticks
      final innerRingDist = (dist - (ringRadius - 35)).abs();
      if (innerRingDist < 3.0) {
        if ((angle * 12).floor() % 2 == 0) {
          _blendPixel(image, x, y, 255, 193, 7, 0.45);
        }
      }
    }
  }

  // Mango Shape parametric rendering
  // Mango is slightly tilted, wider in bottom-middle, curved hook at base
  final mangoCenterX = center;
  final mangoCenterY = center + size * 0.04;
  final mangoScale = size * 0.30;

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      // Transform coordinates relative to mango center with 18-degree tilt
      final rad = -0.32;
      final cosA = math.cos(rad);
      final sinA = math.sin(rad);

      final relX = (x - mangoCenterX) * cosA - (y - mangoCenterY) * sinA;
      final relY = (x - mangoCenterX) * sinA + (y - mangoCenterY) * cosA;

      // Mango shape equation: egg-curve with asymmetrical belly
      final nx = relX / (mangoScale * 0.76);
      final ny = relY / (mangoScale * 1.05);

      // Organic mango deformation
      final asymmetry = 0.22 * ny * (1.0 - ny * 0.5);
      final taper = 1.0 - (ny * 0.35);
      final mangoDist = (nx - asymmetry) * (nx - asymmetry) / (taper * taper) + (ny * ny);

      if (mangoDist <= 1.0) {
        // Pixel is inside Mango!
        final edgeDist = 1.0 - math.sqrt(mangoDist);
        final antialias = (edgeDist * 40.0).clamp(0.0, 1.0);

        // Vertical ripeness gradient: Top is fresh green/yellow, Middle is vibrant yellow-orange, Bottom is deep golden orange
        final vertProgress = ((relY / (mangoScale * 1.1)) + 0.8) / 1.6;

        // Base color transition
        double mR, mG, mB;
        if (vertProgress < 0.3) {
          // Top: Emerald green transitioning to golden yellow
          final t = vertProgress / 0.3;
          mR = 60 * (1 - t) + 245 * t;
          mG = 160 * (1 - t) + 195 * t;
          mB = 40 * (1 - t) + 20 * t;
        } else if (vertProgress < 0.75) {
          // Mid: Golden yellow to juicy orange
          final t = (vertProgress - 0.3) / 0.45;
          mR = 245 * (1 - t) + 255 * t;
          mG = 195 * (1 - t) + 120 * t;
          mB = 20 * (1 - t) + 0 * t;
        } else {
          // Bottom: Rich mango orange to golden amber
          final t = (vertProgress - 0.75) / 0.25;
          mR = 255 * (1 - t) + 230 * t;
          mG = 120 * (1 - t) + 80 * t;
          mB = 0;
        }

        // 3D Spherical Lighting / Ambient shading
        final lightX = -0.35;
        final lightY = -0.45;
        final lightDist = math.sqrt((nx - lightX) * (nx - lightX) + (ny - lightY) * (ny - lightY));
        final diffuse = (1.3 - lightDist * 0.8).clamp(0.6, 1.3);

        mR *= diffuse;
        mG *= diffuse;
        mB *= diffuse;

        // Specular glossy reflection highlight
        final specDist = math.sqrt((nx + 0.25) * (nx + 0.25) + (ny + 0.35) * (ny + 0.35));
        if (specDist < 0.45) {
          final spec = math.pow((1.0 - specDist / 0.45), 2.5) * 0.75;
          mR = mR * (1 - spec) + 255 * spec;
          mG = mG * (1 - spec) + 250 * spec;
          mB = mB * (1 - spec) + 210 * spec;
        }

        // Outer rim shadow
        if (edgeDist < 0.15) {
          final rimFactor = 0.75 + (edgeDist / 0.15) * 0.25;
          mR *= rimFactor;
          mG *= rimFactor;
          mB *= rimFactor;
        }

        _blendPixel(image, x, y, mR.clamp(0, 255).toInt(), mG.clamp(0, 255).toInt(), mB.clamp(0, 255).toInt(), antialias);
      }
    }
  }

  // Draw Fresh Tropical Leaf on Mango Stem
  final leafStartX = mangoCenterX - size * 0.05;
  final leafStartY = mangoCenterY - size * 0.26;
  
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      // Leaf orientation & coordinate mapping
      final ldx = (x - leafStartX);
      final ldy = (y - leafStartY);
      
      final lRad = 0.65;
      final rotX = ldx * math.cos(lRad) - ldy * math.sin(lRad);
      final rotY = ldx * math.sin(lRad) + ldy * math.cos(lRad);

      final leafW = size * 0.07;
      final leafH = size * 0.16;

      if (rotY >= 0 && rotY <= leafH) {
        final leafProgress = rotY / leafH;
        final maxW = math.sin(leafProgress * math.pi) * leafW;
        if (rotX.abs() <= maxW) {
          final edgeDist = (1.0 - (rotX.abs() / (maxW + 0.001))).clamp(0.0, 1.0);
          final antialias = (edgeDist * 6.0).clamp(0.0, 1.0);

          // Leaf color & central vein
          int leafR = 46;
          int leafG = 139;
          int leafB = 50;

          if (rotX.abs() < 1.8) {
            // Central vein highlight
            leafR = 129;
            leafG = 199;
            leafB = 132;
          } else if (rotX > 0) {
            // Shadow side
            leafR = 30;
            leafG = 100;
            leafB = 35;
          }

          _blendPixel(image, x, y, leafR, leafG, leafB, antialias * 0.95);
        }
      }
    }
  }

  // Draw Glowing AI Laser Scanning Beam across Mango
  final laserY = center + size * 0.05;
  for (int y = (laserY - 25).toInt(); y <= (laserY + 25).toInt(); y++) {
    for (int x = (center - size * 0.32).toInt(); x <= (center + size * 0.32).toInt(); x++) {
      if (x < 0 || x >= size || y < 0 || y >= size) continue;

      final distY = (y - laserY).abs();
      final distX = (x - center).abs() / (size * 0.32);

      if (distX <= 1.0) {
        final taperX = math.cos(distX * math.pi * 0.5);
        
        // Laser core
        if (distY <= 2.5) {
          final coreAlpha = (1.0 - distY / 2.5) * taperX;
          _blendPixel(image, x, y, 255, 255, 255, (coreAlpha * 0.95).clamp(0.0, 1.0));
        } else if (distY <= 18.0) {
          // Glow halo
          final haloAlpha = (1.0 - distY / 18.0) * taperX * 0.45;
          _blendPixel(image, x, y, 255, 179, 0, (haloAlpha).clamp(0.0, 1.0));
        }
      }
    }
  }

  // Draw AI Target Nodes (4 subtle targeting corner dots)
  _drawGlowDot(image, (center - size * 0.28).toInt(), (center - size * 0.28).toInt(), 255, 179, 0);
  _drawGlowDot(image, (center + size * 0.28).toInt(), (center - size * 0.28).toInt(), 67, 160, 71);
  _drawGlowDot(image, (center - size * 0.28).toInt(), (center + size * 0.28).toInt(), 67, 160, 71);
  _drawGlowDot(image, (center + size * 0.28).toInt(), (center + size * 0.28).toInt(), 255, 179, 0);

  // Encode and save all app icon formats
  final pngBytes = img.encodePng(image);

  // 1. Save master asset
  final masterDir = Directory('assets/images');
  if (!masterDir.existsSync()) masterDir.createSync(recursive: true);
  File('assets/images/app_icon.png').writeAsBytesSync(pngBytes);
  print('Saved assets/images/app_icon.png (1024x1024)');

  // 2. Save Web Icons
  final webIconsDir = Directory('web/icons');
  if (!webIconsDir.existsSync()) webIconsDir.createSync(recursive: true);

  _saveResized(image, 512, 'web/icons/Icon-512.png');
  _saveResized(image, 512, 'web/icons/Icon-maskable-512.png');
  _saveResized(image, 192, 'web/icons/Icon-192.png');
  _saveResized(image, 192, 'web/icons/Icon-maskable-192.png');
  _saveResized(image, 64, 'web/favicon.png');
  print('Saved web icons & favicon.png');

  // 3. Save Android Mipmap Icons
  final androidSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in androidSizes.entries) {
    final dir = Directory('android/app/src/main/res/${entry.key}');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    _saveResized(image, entry.value, 'android/app/src/main/res/${entry.key}/ic_launcher.png');
  }
  print('Saved Android mipmap launcher icons.');

  print('✅ All App Icons successfully generated and installed!');
}

void _saveResized(img.Image src, int targetSize, String path) {
  final resized = img.copyResize(
    src,
    width: targetSize,
    height: targetSize,
    interpolation: img.Interpolation.linear,
  );
  File(path).writeAsBytesSync(img.encodePng(resized));
}

void _blendPixel(img.Image imgObj, int x, int y, int r, int g, int b, double alpha) {
  if (x < 0 || x >= imgObj.width || y < 0 || y >= imgObj.height || alpha <= 0.0) return;
  final pixel = imgObj.getPixel(x, y);
  
  final srcR = r;
  final srcG = g;
  final srcB = b;
  final srcA = (alpha * 255).clamp(0, 255).toInt();

  final dstR = pixel.r.toInt();
  final dstG = pixel.g.toInt();
  final dstB = pixel.b.toInt();
  final dstA = pixel.a.toInt();

  final outA = srcA + (dstA * (255 - srcA)) ~/ 255;
  if (outA == 0) return;

  final outR = (srcR * srcA + dstR * dstA * (255 - srcA) ~/ 255) ~/ outA;
  final outG = (srcG * srcA + dstG * dstA * (255 - srcA) ~/ 255) ~/ outA;
  final outB = (srcB * srcA + dstB * dstA * (255 - srcA) ~/ 255) ~/ outA;

  imgObj.setPixelRgba(x, y, outR.clamp(0, 255), outG.clamp(0, 255), outB.clamp(0, 255), outA.clamp(0, 255));
}

void _drawGlowDot(img.Image imgObj, int cx, int cy, int r, int g, int b) {
  for (int dy = -8; dy <= 8; dy++) {
    for (int dx = -8; dx <= 8; dx++) {
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist <= 8.0) {
        final alpha = (1.0 - dist / 8.0) * 0.8;
        _blendPixel(imgObj, cx + dx, cy + dy, r, g, b, alpha);
      }
    }
  }
}
