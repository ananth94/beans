import Foundation
import AVFoundation
import AudioToolbox

@MainActor
public class SoundService {
    public static let shared = SoundService()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        // Configure audio session for playback
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: - Sound Effects
    
    /// Play a "pour" sound when saving an article
    public func playPourSound() {
        playSystemSound(1104) // Soft tap sound
    }
    
    /// Play a "sip" sound when completing an article
    public func playSipSound() {
        playSystemSound(1057) // Success sound
    }
    
    /// Play a celebration sound for milestones
    public func playCelebrationSound() {
        playSystemSound(1025) // Celebration fanfare
    }
    
    // MARK: - Private
    
    private func playSystemSound(_ soundID: SystemSoundID) {
        AudioServicesPlaySystemSound(soundID)
    }
}
