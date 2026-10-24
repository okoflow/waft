import UniformTypeIdentifiers
import WaftCore

enum TranscriptFormat {
    case text
    case subtitles

    var fileExtension: String {
        switch self {
        case .text: "txt"
        case .subtitles: "srt"
        }
    }

    var contentType: UTType {
        guard let type = UTType(filenameExtension: fileExtension) else { return .plainText }

        return type
    }

    func contents(of transcript: TimedTranscript) -> String {
        switch self {
        case .text: transcript.text + "\n"
        case .subtitles: SubtitleFormatter.srt(transcript)
        }
    }
}
