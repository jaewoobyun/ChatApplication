//
//  ChatMessageCell.swift
//  ChatApplication
//
//  Created by 변재우 on 20181011//.
//  Copyright © 2018 변재우. All rights reserved.
//

import UIKit
import AVFoundation

class ChatMessageCell: UICollectionViewCell {
	
	var message: Message?
	
	var chatLogController: ChatLogController?
	
	let activityIndicatorView: UIActivityIndicatorView = {
		let aiv = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
		aiv.translatesAutoresizingMaskIntoConstraints = false
		aiv.hidesWhenStopped = true
		
		return aiv
	}()
	
	lazy var playButton: UIButton = {
		let button = UIButton(type: .system)
		button.translatesAutoresizingMaskIntoConstraints = false
		let image = UIImage(named: "play")
		button.tintColor = UIColor.white
		button.setImage(image, for: UIControl.State.normal)
		
		button.addTarget(self, action: #selector(handlePlay), for: UIControl.Event.touchUpInside)
		return button
	}()
	
	var player: AVPlayer?
	var playerLayer: AVPlayerLayer?
	
	@objc func handlePlay() {
		if let videoUrlString = message?.videoUrl, let url = URL(string: videoUrlString) {
			player = AVPlayer(url: url)
			
			playerLayer = AVPlayerLayer(player: player)
			playerLayer?.frame = bubbleView.bounds
			bubbleView.layer.addSublayer(playerLayer!)
			
			player?.play()
			activityIndicatorView.startAnimating()
			playButton.isHidden = true
			
			print("Attempting to play video..")
		}
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		playerLayer?.removeFromSuperlayer()
		player?.pause()
		activityIndicatorView.stopAnimating()
	}
	
	let textView: UITextView = {
		let tv = UITextView()
		tv.text = "Sample Text For Now"
		tv.font = UIFont.systemFont(ofSize: 16)
		tv.backgroundColor = UIColor.clear
		tv.textColor = UIColor.white
		tv.translatesAutoresizingMaskIntoConstraints = false
		tv.isEditable = false
//		tv.backgroundColor = UIColor.yellow
		return tv
	}()
	
	static let blueColor = UIColor(r: 0, g: 137, b: 249)
	
	let bubbleView: UIView = {
		let view = UIView()
		view.backgroundColor = blueColor
		view.translatesAutoresizingMaskIntoConstraints = false
		view.layer.cornerRadius = 16
		view.layer.masksToBounds = true
		return view
	}()
	
	let profileImageView: UIImageView = {
		let imageView = UIImageView()
		imageView.image = UIImage(named: "photo")
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.layer.cornerRadius = 16
		imageView.layer.masksToBounds = true
		imageView.contentMode = .scaleAspectFill
		return imageView
	}()
	
	lazy var messageImageView: UIImageView = {
		let imageView = UIImageView()
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.layer.cornerRadius = 16
		imageView.layer.masksToBounds = true
		imageView.contentMode = .scaleAspectFill
		imageView.isUserInteractionEnabled = true
		//        imageView.backgroundColor = UIColor.brown
		
		imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomTap)))
		
		return imageView
	}()
	
	@objc func handleZoomTap(tapGesture: UITapGestureRecognizer) {
//		print("handleZoomTap")
		//PRO Tip: don't perform a lot of custom logic inside of a view class
		
//		if message?.videoUrl != nil {
//			//FIXME: now - if not video, do not zoom. later - zoom out and play
//			if let imageView = tapGesture.view as? UIImageView {
//				self.chatLogController?.performZoomInForVideo(startingImageView: imageView, videoUrl: message?.videoUrl as? URL)
//			}
////			return
//		}
		
//		if let videoView = tapGesture.view as? UIImageView, let videoUrl = message?.videoUrl {
//
//			let videoUrl = URL(string: videoUrl)
//			self.chatLogController?.performZoomInForVideo(startingImageView: videoView, videoUrl: videoUrl)
//		}
		
		if message?.videoUrl != nil {
			return
		}
		
		if let imageView = tapGesture.view as? UIImageView {
			self.chatLogController?.performZoomInForStartingImageView(startingImageView: imageView)
		}
	}
	
	var bubbleWidthAnchor: NSLayoutConstraint?
	var bubbleViewRightAnchor: NSLayoutConstraint?
	var bubbleViewLeftAnchor: NSLayoutConstraint?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		addSubview(bubbleView)
		addSubview(textView)
		addSubview(profileImageView)
		
		bubbleView.addSubview(messageImageView)
		
		//x,y,w,h
		messageImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
		messageImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
		messageImageView.widthAnchor.constraint(equalTo: bubbleView.widthAnchor).isActive = true
		messageImageView.heightAnchor.constraint(equalTo: bubbleView.heightAnchor).isActive = true
		
		bubbleView.addSubview(playButton)
		playButton.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
		playButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
		playButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
		playButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
		
		bubbleView.addSubview(activityIndicatorView)
		activityIndicatorView.centerXAnchor.constraint(equalTo: bubbleView.centerXAnchor).isActive = true
		activityIndicatorView.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor).isActive = true
		activityIndicatorView.widthAnchor.constraint(equalToConstant: 50).isActive = true
		activityIndicatorView.heightAnchor.constraint(equalToConstant: 50).isActive = true
		
		//x,y,w,h
		profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
		profileImageView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
		profileImageView.widthAnchor.constraint(equalToConstant: 32).isActive = true
		profileImageView.heightAnchor.constraint(equalToConstant: 32).isActive = true
		
		//x,y,w,h
		bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
		bubbleViewRightAnchor?.isActive = true
		
		bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8)
		//        bubbleViewLeftAnchor?.isActive = false
		
		bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
		
		bubbleWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
		bubbleWidthAnchor?.isActive = true
		
		bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
		
		//x,y,w,h
		//        textView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
		textView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8).isActive = true
		textView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
		
		textView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true
		//        textView.widthAnchor.constraint(equalToConstant: 200).isActive = true
		textView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}
