import WaftCore

final class FakeFeedbackSoundPlayer: FeedbackSoundPlayer {
    private(set) var played: [FeedbackSound] = []

    func play(_ sound: FeedbackSound) {
        played.append(sound)
    }
}
