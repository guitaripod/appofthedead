import Foundation
import Testing

@testable import aotd

struct GenerativeFeatureVisibilityTests {
    @Test func hidesTheOracleAndModelWrittenTextWithoutOnDeviceGeneration() {
        let visibility = GenerativeFeatureVisibility(onDeviceGeneration: false)
        #expect(!visibility.showsOracle)
        #expect(!visibility.showsModelWrittenText)
    }

    @Test func keepsTheOracleAndModelWrittenTextWithOnDeviceGeneration() {
        let visibility = GenerativeFeatureVisibility(onDeviceGeneration: true)
        #expect(visibility.showsOracle)
        #expect(visibility.showsModelWrittenText)
    }

    @Test func settingsKeepsOnlyTheRemovalOfADownloadedModelWithoutOnDeviceGeneration() {
        var state = SettingsState()
        state.generative = GenerativeFeatureVisibility(onDeviceGeneration: false)
        state.oracleVoice = .notDownloaded
        state.modelBytesOnDisk = 1_000
        state.supportsHaptics = true
        let oracle = SettingsLayout.sections(for: state).first { $0.kind == .oracle }
        #expect(oracle?.items == [.removeModel(bytes: 1_000)])
    }

    @Test func settingsDropsTheOracleSectionWhenNothingIsDownloaded() {
        var state = SettingsState()
        state.generative = GenerativeFeatureVisibility(onDeviceGeneration: false)
        #expect(!SettingsLayout.sections(for: state).contains { $0.kind == .oracle })
    }

    @Test func settingsShowsTheVoiceWithOnDeviceGeneration() {
        var state = SettingsState()
        state.generative = GenerativeFeatureVisibility(onDeviceGeneration: true)
        state.oracleVoice = .appleIntelligence
        let oracle = SettingsLayout.sections(for: state).first { $0.kind == .oracle }
        #expect(oracle?.items.first == .oracleVoice(.appleIntelligence))
    }

    @Test func generalUpgradeCopyNamesNoOracleWithoutOnDeviceGeneration() {
        let journey = PaywallJourney(lessonsFinished: 9)
        let subtitle = PaywallPersonalCopy.subtitle(for: .generalUpgrade, journey: journey, showsOracle: false)
        #expect(subtitle?.contains("Oracle") != true)
        #expect(!PaywallReason.generalUpgrade.subtitle(showsOracle: false).contains("Oracle"))
        #expect(PaywallReason.generalUpgrade.subtitle().contains("Oracle"))
    }
}
