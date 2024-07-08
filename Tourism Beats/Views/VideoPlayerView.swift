//
//  VideoPlayerView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 18/6/24.
//

import SwiftUI
import AVKit
import Combine

struct VideoPlayerView: UIViewRepresentable {
    var videoName: String

    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView(frame: .zero, videoName: videoName)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    class PlayerUIView: UIView {
        private var playerLayer = AVPlayerLayer()
        private var playerLooper: AVPlayerLooper?
        private var queuePlayer = AVQueuePlayer()
        private var cancellable: AnyCancellable?

        init(frame: CGRect, videoName: String) {
            super.init(frame: frame)
            setupPlayer(videoName: videoName)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        private func setupPlayer(videoName: String) {
            guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
                print("Video URL not found for \(videoName).mp4")
                return
            }
            
            print("Video URL found: \(url)")

            let playerItem = AVPlayerItem(url: url)
            playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

            playerLayer.player = queuePlayer
            playerLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(playerLayer)

            queuePlayer.isMuted = true
            queuePlayer.play()

            NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: queuePlayer.currentItem)
                .sink { [weak self] _ in
                    self?.queuePlayer.seek(to: .zero)
                    self?.queuePlayer.play()
                }
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
        
        deinit {
            cancellable?.cancel()
        }
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView(videoName: "big_ben_video")
            .edgesIgnoringSafeArea(.all)
    }
}
