//
//  VideoPlayerView.swift
//  Tourism Beats
//
//  Created by Ariel Tyson on 18/6/24.
//

import SwiftUI
import AVKit

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

        init(frame: CGRect, videoName: String) {
            super.init(frame: frame)
            setupPlayer(videoName: videoName)
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupPlayer(videoName: "")
        }

        private func setupPlayer(videoName: String) {
            guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
                print("Video URL not found for \(videoName).mp4")
                return
            }

            let playerItem = AVPlayerItem(url: url)
            playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

            playerLayer.player = queuePlayer
            playerLayer.videoGravity = .resizeAspectFill
            layer.addSublayer(playerLayer)

            queuePlayer.play()

            NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: queuePlayer.currentItem)
        }

        @objc private func playerItemDidReachEnd(notification: Notification) {
            queuePlayer.seek(to: .zero)
            queuePlayer.play()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
    }
}

struct VideoPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        VideoPlayerView(videoName: "big_ben_video")
            .edgesIgnoringSafeArea(.all)
    }
}
