//
//  NCPlayerToolBar.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 01/07/21.
//  Copyright © 2021 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import NCCommunication

class NCPlayerToolBar: UIView {
    
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playbackSlider: UISlider!
    @IBOutlet weak var labelOverallDuration: UILabel!
    @IBOutlet weak var labelCurrentTime: UILabel!
    
    enum sliderEventType {
        case began
        case ended
        case moved
    }
        
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private var ncplayer: NCPlayer?
    private var wasInPlay: Bool = false
    private var playbackSliderEvent: sliderEventType = .ended
    private let seekDuration: Float64 = 15

    // MARK: - View Life Cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // for disable gesture of UIPageViewController
        let panRecognizer = UIPanGestureRecognizer(target: self, action: nil)
        addGestureRecognizer(panRecognizer)
        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSingleTapWith(gestureRecognizer:)))
        addGestureRecognizer(singleTapGestureRecognizer)
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        
        self.layer.cornerRadius = 15
        self.layer.masksToBounds = true
        
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.insertSubview(blurEffectView, at:0)
        
        playbackSlider.value = 0
        playbackSlider.minimumValue = 0
        playbackSlider.maximumValue = 0
        playbackSlider.isContinuous = true
        playbackSlider.tintColor = .lightGray
        
        labelCurrentTime.text = NCUtility.shared.stringFromTimeInterval(interval: 0)
        labelCurrentTime.textColor = .lightGray
        labelOverallDuration.text = NCUtility.shared.stringFromTimeInterval(interval: 0)
        labelOverallDuration.textColor = .lightGray
        
        backButton.setImage(NCUtility.shared.loadImage(named: "gobackward.15", color: .lightGray), for: .normal)
        playButton.setImage(NCUtility.shared.loadImage(named: "play.fill", color: .lightGray), for: .normal)
        forwardButton.setImage(NCUtility.shared.loadImage(named: "goforward.15", color: .lightGray), for: .normal)
        muteButton.setImage(NCUtility.shared.loadImage(named: "audioOff", color: .lightGray), for: .normal)
    }
    
    deinit {
        print("deinit NCPlayerToolBar")
    }
    
    func setBarPlayer(ncplayer: NCPlayer) {
                        
        self.ncplayer = ncplayer
        
        playbackSlider.value = 0
        playbackSlider.minimumValue = 0
        playbackSlider.maximumValue = Float(ncplayer.getVideoDurationSeconds())
        playbackSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)

        labelCurrentTime.text = NCUtility.shared.stringFromTimeInterval(interval: 0)
        labelOverallDuration.text = "-" + NCUtility.shared.stringFromTimeInterval(interval:ncplayer.getVideoDurationSeconds())
                
        updateToolBar()
        
        appDelegate.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, preferredTimescale: 1), queue: .main, using: { (CMTime) in
            
            if self.appDelegate.player?.currentItem?.status == .readyToPlay {
                if self.isHidden == false {
                    self.updateToolBar()
                }
            }
        })        
    }
    
    @objc public func hideToolBar() {
        
        updateToolBar()
      
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }, completion: { (value: Bool) in
            self.isHidden = true
        })
    }
    
    @discardableResult
    @objc public func showToolBar(metadata: tableMetadata, detailView: NCViewerMediaDetailView?) -> Bool {
        
        if !self.isHidden { return false}
        if metadata.livePhoto { return false}
        if let detailView = detailView {
            if detailView.isShow() { return false }
        }
        if metadata.classFile == NCCommunicationCommon.typeClassFile.video.rawValue || metadata.classFile == NCCommunicationCommon.typeClassFile.audio.rawValue {
            
            updateToolBar()
            
            UIView.animate(withDuration: 0.3, animations: {
                self.alpha = 1
            }, completion: { (value: Bool) in
                self.isHidden = false
            })
            
            return true
            
        } else {
            
            return false
        }
    }
    
    public func updateToolBar() {

        var namedPlay = "play.fill"
        if appDelegate.player?.rate == 1 { namedPlay = "pause.fill"}
        let currentSeconds = ncplayer?.getVideoCurrentSeconds() ?? 0
        let durationSeconds = ncplayer?.getVideoDurationSeconds() ?? 0
        
        playbackSlider.value = Float(currentSeconds)
        playbackSlider.isEnabled = true
        
        backButton.setImage(NCUtility.shared.loadImage(named: "gobackward.15", color: .white), for: .normal)
        backButton.isEnabled = true
        
        if #available(iOS 13.0, *) {
            playButton.setImage(NCUtility.shared.loadImage(named: namedPlay, color: .white, symbolConfiguration: UIImage.SymbolConfiguration(pointSize: 30)), for: .normal)
        } else {
            playButton.setImage(NCUtility.shared.loadImage(named: namedPlay, color: .white), for: .normal)
        }
        playButton.isEnabled = true
        
        forwardButton.setImage(NCUtility.shared.loadImage(named: "goforward.15", color: .white), for: .normal)
        forwardButton.isEnabled = true
        
        if CCUtility.getAudioMute() {
            muteButton.setImage(NCUtility.shared.loadImage(named: "audioOff", color: .white), for: .normal)
        } else {
            muteButton.setImage(NCUtility.shared.loadImage(named: "audioOn", color: .white), for: .normal)
        }
        muteButton.isEnabled = true
        
        labelCurrentTime.text = NCUtility.shared.stringFromTimeInterval(interval: currentSeconds)
        labelOverallDuration.text = "-" + NCUtility.shared.stringFromTimeInterval(interval: durationSeconds - currentSeconds)
    }
    
    //MARK: - Event / Gesture
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        
        if let touchEvent = event.allTouches?.first {
            
            let seconds: Int64 = Int64(self.playbackSlider.value)
            let targetTime: CMTime = CMTimeMake(value: seconds, timescale: 1)
            
            switch touchEvent.phase {
            case .began:
                wasInPlay = appDelegate.player?.rate == 1 ? true : false
                ncplayer?.videoPause()
                playbackSliderEvent = .began
            case .moved:
                ncplayer?.videoSeek(time: targetTime)
                playbackSliderEvent = .moved
            case .ended:
                ncplayer?.videoSeek(time: targetTime)
                if wasInPlay {
                    ncplayer?.videoPlay()
                }
                playbackSliderEvent = .ended
            default:
                break
            }
        }
    }
    
    @objc func didSingleTapWith(gestureRecognizer: UITapGestureRecognizer) {
        
        hideToolBar()
    }
    
    //MARK: - Action
    
    @IBAction func buttonTouchInside(_ sender: UIButton) {
        
        hideToolBar()
    }
    
    @IBAction func playerPause(_ sender: Any) {
        
        if appDelegate.player?.timeControlStatus == .playing {
            ncplayer?.videoPause()
            ncplayer?.saveCurrentTime()
        } else if appDelegate.player?.timeControlStatus == .paused {
            ncplayer?.videoPlay()
        } else if appDelegate.player?.timeControlStatus == .waitingToPlayAtSpecifiedRate {
            ncplayer?.deleteLocalFile()
            print("timeControlStatus.waitingToPlayAtSpecifiedRate")
            if let reason = appDelegate.player?.reasonForWaitingToPlay {
                switch reason {
                case .evaluatingBufferingRate:
                    print("reasonForWaitingToPlay.evaluatingBufferingRate")
                case .toMinimizeStalls:
                    print("reasonForWaitingToPlay.toMinimizeStalls")
                case .noItemToPlay:
                    print("reasonForWaitingToPlay.noItemToPlay")
                default:
                    print("Unknown \(reason)")
                }
            }
        }
    }
        
    @IBAction func setMute(_ sender: Any) {
        
        let mute = CCUtility.getAudioMute()
        
        CCUtility.setAudioMute(!mute)
        appDelegate.player?.isMuted = !mute
        updateToolBar()
    }
    
    @IBAction func forwardButtonSec(_ sender: Any) {
        guard let ncplayer = ncplayer else { return }
        guard let player = appDelegate.player else { return }

        let playerCurrentTime = CMTimeGetSeconds(player.currentTime())
        let newTime = playerCurrentTime + seekDuration
        
        if newTime < ncplayer.getVideoDurationSeconds() {
            let time: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
            ncplayer.videoSeek(time: time)
        }
    }
    
    @IBAction func backButtonSec(_ sender: Any) {
        guard let ncplayer = ncplayer else { return }
        guard let player = appDelegate.player else { return }

        let playerCurrenTime = CMTimeGetSeconds(player.currentTime())
        var newTime = playerCurrenTime - seekDuration
        
        if newTime < 0 { newTime = 0 }
        let time: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        
        ncplayer.videoSeek(time: time)
    }
}