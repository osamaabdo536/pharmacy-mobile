import 'package:flutter/material.dart';

enum OnboardingOverlayType { locationPill, availabilityCard, confirmedCard, discountPill }

class OnboardingOverlayData {
  final OnboardingOverlayType type;
  final Alignment alignment;

  const OnboardingOverlayData({
    required this.type,
    required this.alignment,
  });
}

class OnboardingPageData {
  final String imageAsset;
  final String title;
  final String description;
  final List<String> checklistItems;
  final List<OnboardingOverlayData> overlays;
  final String primaryButtonLabel;

  const OnboardingPageData({
    required this.imageAsset,
    required this.title,
    required this.description,
    required this.checklistItems,
    required this.overlays,
    required this.primaryButtonLabel,
  });
}

const onboardingPages = <OnboardingPageData>[
  OnboardingPageData(
    imageAsset: 'assets/images/onboarding-1.png',
    title: 'Find Medicines Nearby',
    description:
        'Search by medicine name, generic name, or active ingredient and instantly discover nearby pharmacies with real-time availability.',
    checklistItems: [
      'Real-time medicine availability',
      'Nearby pharmacy search',
      'Fast and easy medicine lookup',
    ],
    overlays: [
      OnboardingOverlayData(
        type: OnboardingOverlayType.locationPill,
        alignment: Alignment.topRight,
      ),
      OnboardingOverlayData(
        type: OnboardingOverlayType.availabilityCard,
        alignment: Alignment.bottomLeft,
      ),
    ],
    primaryButtonLabel: 'Next',
  ),
  OnboardingPageData(
    imageAsset: 'assets/images/onboarding-2.png',
    title: 'Reserve & Pick Up Easily',
    description:
        'Reserve your medicine in seconds, receive a unique pickup code, and collect it from the pharmacy before the reservation expires.',
    checklistItems: [
      'Instant reservation',
      'Unique pickup code',
      'Pharmacy discounts and offers',
    ],
    overlays: [
      OnboardingOverlayData(
        type: OnboardingOverlayType.confirmedCard,
        alignment: Alignment.topRight,
      ),
      OnboardingOverlayData(
        type: OnboardingOverlayType.discountPill,
        alignment: Alignment.bottomLeft,
      ),
    ],
    primaryButtonLabel: 'Get Started',
  ),
];
