//
//  ASMRAudioService.swift
//  Focus4Good
//
//  Created by Shreya on 23/03/26.
//

import AVFoundation

// MARK: - Noise Profile

enum NoiseProfile {
    case white, pink, brown
    case rain, ocean, thunder, fire, ambient

    static func from(soundName: String) -> NoiseProfile {
        switch soundName {
        case "Pink Noise":      return .pink
        case "Brown Noise":     return .brown
        case "Forest Rain":     return .rain
        case "Ocean Waves":     return .ocean
        case "Thunderstorm":    return .thunder
        case "Light Drizzle":   return .rain
        case "Crackling Fire":  return .fire
        case "Coffee Shop":     return .ambient
        default:                return .white
        }
    }
}

// MARK: - Noise State (heap-allocated for audio thread)

private final class NoiseState: @unchecked Sendable {
    var brown: Float = 0
    var pinkRows = [Float](repeating: 0, count: 7)
    var pinkRunningSum: Float = 0
    var pinkIndex: Int = 0
    var phase: Float = 0
}

// MARK: - ASMRAudioService

final class ASMRAudioService: @unchecked Sendable {

    static let shared = ASMRAudioService()

    private var engine: AVAudioEngine?
    private(set) var isPlaying = false

    private init() {}

    // MARK: Playback Controls

    func play(soundName: String) {
        stop()

        let profile = NoiseProfile.from(soundName: soundName)

        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        // Build engine
        let engine = AVAudioEngine()
        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let state = NoiseState()

        let source = AVAudioSourceNode(format: format) { _, _, frameCount, bufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(bufferList)
            for frame in 0..<Int(frameCount) {
                let sample = Self.generate(profile, state: state, sampleRate: Float(sampleRate))
                for buf in abl {
                    buf.mData?.assumingMemoryBound(to: Float.self)[frame] = sample
                }
            }
            return noErr
        }

        engine.attach(source)
        engine.connect(source, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.5

        do {
            try engine.start()
            self.engine = engine
            isPlaying = true
        } catch {
            print("ASMRAudioService: failed to start — \(error)")
        }
    }

    func pause() {
        engine?.pause()
        isPlaying = false
    }

    func resume() {
        guard engine != nil else { return }
        try? engine?.start()
        isPlaying = true
    }

    func stop() {
        engine?.stop()
        engine?.reset()
        engine = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Sample Generation (runs on real-time audio thread)

    private static func generate(_ profile: NoiseProfile, state: NoiseState, sampleRate: Float) -> Float {
        switch profile {
        case .white:
            return Float.random(in: -1...1) * 0.25

        case .pink:
            return pinkSample(state) * 0.30

        case .brown:
            return brownSample(state) * 0.40

        case .rain:
            let base = pinkSample(state) * 0.25
            let sparkle: Float = Float.random(in: 0...1) < 0.003
                ? Float.random(in: -0.12...0.12) : 0
            return base + sparkle

        case .ocean:
            let base = brownSample(state)
            state.phase += 0.08 / sampleRate
            let mod = 0.20 + 0.15 * sin(state.phase * 2 * .pi)
            return base * mod

        case .thunder:
            let base = brownSample(state) * 0.30
            state.phase += 0.03 / sampleRate
            let swell = 0.30 + 0.25 * sin(state.phase * 2 * .pi)
            return base * swell

        case .fire:
            let base = brownSample(state) * 0.30
            let crackle: Float = Float.random(in: 0...1) < 0.002
                ? Float.random(in: 0.05...0.20) : 0
            return base + crackle

        case .ambient:
            let base = pinkSample(state) * 0.12
            state.phase += 0.02 / sampleRate
            let mod = 0.80 + 0.20 * sin(state.phase * 2 * .pi)
            return base * mod
        }
    }

    // MARK: Brown Noise (random walk)

    private static func brownSample(_ s: NoiseState) -> Float {
        s.brown += Float.random(in: -0.02...0.02)
        s.brown = max(-1, min(1, s.brown))
        s.brown *= 0.999
        return s.brown
    }

    // MARK: Pink Noise (Voss-McCartney)

    private static func pinkSample(_ s: NoiseState) -> Float {
        let idx = s.pinkIndex
        s.pinkIndex &+= 1

        var k = idx
        for row in 0..<7 {
            if k & 1 == 0 {
                s.pinkRunningSum -= s.pinkRows[row]
                s.pinkRows[row] = Float.random(in: -1...1)
                s.pinkRunningSum += s.pinkRows[row]
                break
            }
            k >>= 1
        }

        let white = Float.random(in: -1...1)
        return (s.pinkRunningSum + white) / 8.0
    }
}
