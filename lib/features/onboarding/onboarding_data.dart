import 'package:flutter/material.dart';

class OnboardingData {
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;

  const OnboardingData({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
  });
}

const onboardingPages = [
  OnboardingData(
    eyebrow: 'WELCOME TO THE ARENA',
    title: 'Your next move\nstarts here.',
    description:
        'Enter the world of competitive chess. Practice, compete, and make every move count.',
    icon: Icons.grid_view_rounded,
  ),
  OnboardingData(
    eyebrow: 'TRAIN YOUR MIND',
    title: 'Practice.\nImprove. Repeat.',
    description:
        'Build confidence, sharpen your tactics, and prepare yourself for the next challenge.',
    icon: Icons.psychology_rounded,
  ),
  OnboardingData(
    eyebrow: 'FIND YOUR OPPONENT',
    title: 'Every player\nhas a match.',
    description:
        'Find opponents around your skill level and discover where your chess can take you.',
    icon: Icons.people_alt_rounded,
  ),
  OnboardingData(
    eyebrow: 'THE REAL GAME',
    title: 'Think fast.\nPlay smart.',
    description:
        'Experience competitive chess with live boards, game clocks, and move tracking.',
    icon: Icons.bolt_rounded,
  ),
  OnboardingData(
    eyebrow: 'BE PART OF THE ACTION',
    title: 'Watch every\nbrilliant move.',
    description:
        'Follow live matches, explore the action, and share games with your friends.',
    icon: Icons.visibility_rounded,
  ),
  OnboardingData(
    eyebrow: 'YOUR CHESS JOURNEY',
    title: 'Make your\nmoves matter.',
    description:
        'Keep track of your games, results, and progress as you grow into a stronger player.',
    icon: Icons.emoji_events_rounded,
  ),
];
