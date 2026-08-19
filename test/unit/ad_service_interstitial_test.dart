import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:name_twist_game/core/constants/app_constants.dart';

/// A deterministic mock simulating the exact frequency and cooldown
/// logic of AdService for interstitials, ensuring tests don't require
/// the Google Mobile Ads SDK or real delays.
class MockAdService {
  int campaignCompletionsThisSession = 0;
  DateTime? lastInterstitialTime;
  static const Duration cooldown = Duration(minutes: 2);
  bool isAdLoaded = true;
  bool simulateFailure = false;
  
  int adsShowed = 0;
  
  // Dependency inject the clock for fake_async support
  DateTime Function() clock = () => DateTime.now();

  Future<void> recordCampaignCompletionAndShowInterstitialIfNeeded({
    required void Function() onContinue,
  }) async {
    campaignCompletionsThisSession++;
    
    // Rule 1: Frequency
    if (campaignCompletionsThisSession < AppConstants.adFrequencyCampaignLevels) {
      onContinue();
      return;
    }
    
    // Rule 2: Cooldown
    if (lastInterstitialTime != null &&
        clock().difference(lastInterstitialTime!) < cooldown) {
      onContinue();
      return;
    }
    
    // Rule 3: Availability
    if (!isAdLoaded) {
      onContinue();
      return; // Defer to next completion
    }
    
    // Rule 4: Failure Handling
    if (simulateFailure) {
      // Simulate onAdFailedToShowFullScreenContent
      onContinue();
      return;
    }
    
    // Rule 5: Success & Dismissal
    // Simulate onAdShowedFullScreenContent and then onAdDismissedFullScreenContent
    adsShowed++;
    lastInterstitialTime = clock();
    campaignCompletionsThisSession = 0; // Reset only on success
    onContinue();
  }
}

void main() {
  group('Deterministic Interstitial Logic', () {
    test('1, 2, 3 completions show nothing, 4th shows ad', () async {
      final mockAdService = MockAdService();
      
      for (int i = 1; i <= 3; i++) {
        await mockAdService.recordCampaignCompletionAndShowInterstitialIfNeeded(onContinue: () {});
        expect(mockAdService.adsShowed, 0);
      }
      
      await mockAdService.recordCampaignCompletionAndShowInterstitialIfNeeded(onContinue: () {});
      expect(mockAdService.adsShowed, 1);
      expect(mockAdService.campaignCompletionsThisSession, 0); // Reset
    });
    
    test('Cooldown enforces 2-minute gap between ads', () {
      fakeAsync((async) {
        final mockAdService = MockAdService();
        mockAdService.clock = () => async.getClock(DateTime.now()).now();
        
        // Trigger first ad
        for (int i = 0; i < 4; i++) {
          mockAdService.recordCampaignCompletionAndShowInterstitialIfNeeded(onContinue: () {});
        }
        expect(mockAdService.adsShowed, 1);
        
        // Complete 4 more levels immediately (cooldown active)
        for (int i = 0; i < 4; i++) {
          mockAdService.recordCampaignCompletionAndShowInterstitialIfNeeded(onContinue: () {});
        }
        // Counter is blocked, shouldn't show ad
        expect(mockAdService.adsShowed, 1);
        expect(mockAdService.campaignCompletionsThisSession, 4); 
        
        // Advance time by 1 minute, still blocked
        async.elapse(const Duration(minutes: 1));
        mockAdService.recordCampaignCompletionAndShowInterstitialIfNeeded(onContinue: () {});
        expect(mockAdService.adsShowed, 1);
        expect(mockAdService.campaignCompletionsThisSession, 5);
        
        // Advance time past 2 minutes
        async.elapse(const Duration(minutes: 1, seconds: 1));
        mockAdService.recordCampaignCompletionAndShowInterstitialIfNeeded(onContinue: () {});
        
        // Should now show ad and reset
        expect(mockAdService.adsShowed, 2);
        expect(mockAdService.campaignCompletionsThisSession, 0);
      });
    });
    
    test('Failure to show does not reset counter or trigger cooldown', () async {
      final mockAdService = MockAdService();
      
      // Simulate failure on the 4th level
      mockAdService.simulateFailure = true;
      for (int i = 0; i < 4; i++) {
        await mockAdService.recordCampaignCompletionAndShowInterstitialIfNeeded(onContinue: () {});
      }
      expect(mockAdService.adsShowed, 0);
      expect(mockAdService.campaignCompletionsThisSession, 4); // Still intact
      expect(mockAdService.lastInterstitialTime, null); // No cooldown started
      
      // Fix failure, next level (5th) should trigger ad immediately
      mockAdService.simulateFailure = false;
      await mockAdService.recordCampaignCompletionAndShowInterstitialIfNeeded(onContinue: () {});
      
      expect(mockAdService.adsShowed, 1);
      expect(mockAdService.campaignCompletionsThisSession, 0);
    });
  });
}
