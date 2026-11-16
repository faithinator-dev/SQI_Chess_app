import 'package:flutter/material.dart';

class OnboardingData {
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final String? chessEmoji;
  final bool isPicturehere;
  final String? chessPicture;
  final String badgeText;
  final Color themeColor;

  const OnboardingData({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.badgeText,
    required this.themeColor,
    required this.isPicturehere,
    this.chessEmoji,
    this.chessPicture,
  });
}

const onboardingPages = [
  OnboardingData(
    eyebrow: 'WELCOME TO SQI CHESS',
    title: 'Your next move\nstarts right here.',
    description:
        'Step onto the board with confidence. Discover clever tactics, test strategies, and make every move count.',
    icon: Icons.auto_awesome_rounded,
    chessEmoji: '♚',
    badgeText: 'Grandmaster Energy',
    chessPicture: 'assets/images/onboarding/king.png',
    isPicturehere: true,
    themeColor: Color(0xFF1E293B), // Premium Slate Black / Charcoal
  ),
  OnboardingData(
    eyebrow: 'TRAIN YOUR MIND',
    title: 'Sharpen tactics.\nPlay with joy.',
    description:
        'Puzzles, drills, and brain-teasers tailored to build intuition and elevate your calculation instincts.',
    icon: Icons.psychology_rounded,
    chessEmoji: '♞',
    chessPicture: 'assets/images/onboarding/knight.png',
    isPicturehere: true,
    badgeText: 'Tactics & Drills',
    themeColor: Color(0xFF0D9488), // Elegant Deep Teal
  ),
  OnboardingData(
    eyebrow: 'FIND YOUR OPPONENT',
    title: 'Friendly rivals\nevery single day.',
    description:
        'Connect with club members around your skill level and enjoy thrilling matches in real time.',
    icon: Icons.group_add_rounded,
    chessEmoji: '♝',
    chessPicture: 'assets/images/onboarding/bishop.png',
    isPicturehere: true,
    badgeText: 'Matchmaking',
    themeColor: Color(0xFF475569), // Slate Grey
  ),
  OnboardingData(
    eyebrow: 'THE REAL GAME',
    title: 'Live clocks.\nPure adrenaline.',
    description:
        'Experience smooth interactive chessboards, crisp clocks, move analytics, and precise notation recording.',
    icon: Icons.timer_rounded,
    chessPicture: 'assets/images/onboarding/rook.png',
    isPicturehere: true,
    chessEmoji: '♜',
    badgeText: 'Blitz & Rapid',
    themeColor: Color(0xFFD97706), // Warm Amber
  ),
  OnboardingData(
    eyebrow: 'SPECTATE & LEARN',
    title: 'Watch & cheer\nbrilliant games.',
    description:
        'Follow high-stakes club matches live, analyse brilliant sacrifices, and discuss novelties together.',
    icon: Icons.visibility_rounded,
    chessPicture: 'assets/images/onboarding/queen.png',
    isPicturehere: true,
    chessEmoji: '♛',
    badgeText: 'Live Broadcast',
    themeColor: Color(0xFF059669), // Forest Emerald
  ),
  OnboardingData(
    eyebrow: 'YOUR CHESS JOURNEY',
    title: 'Climb the ladder.\nClaim trophies.',
    description:
        'Track your ELO progress, unlock milestones, review your games, and show off your mastery.',
    icon: Icons.emoji_events_rounded,
    chessPicture: 'assets/images/onboarding/crown.png',
    isPicturehere: true,
    chessEmoji: '★',
    badgeText: 'Club Champion',
    themeColor: Color(0xFF1E293B), // Charcoal Gold
  ),
];
