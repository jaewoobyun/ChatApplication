//
//  ChatLogController.swift
//  ChatApplication
//
//  Created by 변재우 on 20181004//.
//  Copyright © 2018 변재우. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	
	var user: User? {
		didSet {
			navigationItem.title = user?.name
			
			observeMessages()
		}
		
	}
	
	var messages = [Message]()
	
	func observeMessages() {
		guard let uid = Auth.auth().currentUser?.uid, let toId = user?.id else {
			return
		}
		
		let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId)
		
		userMessagesRef.observe(.childAdded, with: { (snapshot) in
//			print(snapshot)
			
			let messageId = snapshot.key
			let messageRef = Database.database().reference().child("messages").child(messageId)
			messageRef.observeSingleEvent(of: .value, with: { (snapshot) in
//				print(snapshot)
				
				guard let dictionary = snapshot.value as? [String: Any] else {
					return
				}
				
				////FIXME: deprecated
				//                message.setValuesForKeys(dictionary)
				
				// MARK: this is matching the chatPartnerId(i.e. sender)'s messages ONLY 즉, 전송자가 보낸 메시지들을 그 전송자가 보낸것들로만 묵어서 보여주게 하는 로직
				//                print("We fetched a message from Firebase, and we need to decide whether or not to filter it out", message.text!)
				//Do we need to attempt filtering anymore?
				
				self.messages.append(Message(dictionary: dictionary as [String : AnyObject]))
				DispatchQueue.main.async {
					self.collectionView?.reloadData()
				}
				
			}, withCancel: nil)
			
		}, withCancel: nil)
	}
	

	
	let cellId = "cellId"
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		print("Chat Log Controller initiated")
		//        navigationItem.title = "Chat Log Controller"
		
		collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
		//        collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
		collectionView?.alwaysBounceVertical = true
		collectionView?.backgroundColor = UIColor.white
		collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
		
		collectionView?.keyboardDismissMode = .interactive
		
		setupKeyboardObservers()
		
	}
	
	lazy var inputContainerView: ChatInputContainerView = {
		
		let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
		chatInputContainerView.chatLogController = self
		return chatInputContainerView
	}()
	
	@objc func handleUploadTap() {
		print("Tap Upload!")
		let imagePickerController = UIImagePickerController()
		
		imagePickerController.allowsEditing = true
		imagePickerController.delegate = self
		imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
		
		present(imagePickerController, animated: true, completion: nil)
		
	}
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

		if let videoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
			// we selected a video
			print("video file URL: ", videoUrl)
			
			handleVideoSelectedForUrl(videoUrl)

			
		} else {
			//we selected an image
			
			// Local variable inserted by Swift 4.2 migrator.
			let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
			
			handleImageSelectedForInfo(info: info as [String : AnyObject])
			
			
		}
		
		
		dismiss(animated: true, completion: nil)
	}
	
	
	private func handleVideoSelectedForUrl(_ url: URL) {
		let filename = UUID().uuidString + ".mov"
		
		let ref = Storage.storage().reference().child("message_movies").child(filename)
		
		let uploadTask = ref.putFile(from: url, metadata: nil) { (metadata, error) in
			guard let metadata = metadata else {
				return
			}
			
			if let err = error {
				print("Failed upload of video:", err)
				return
			}
			
			ref.downloadURL(completion: { (downloadUrl, error) in
				if let err = error {
					print("Failed to get download url", err)
					return
				}
				guard let downloadUrl = downloadUrl else { return }
				print("downloadUrl!: ", downloadUrl)
				print("type of downloadUrl is")
				print(type(of: downloadUrl))
				
				
				if let thumbnailImage = self.thumbnailImageForFileUrl(fileUrl: url) {
					self.uploadToFirebaseStorageUsingImage(thumbnailImage, completion: { (imageUrl) in
						let properties: [String: AnyObject] = [
							"imageUrl": imageUrl as AnyObject,
							"imageWidth": thumbnailImage.size.width as AnyObject,
							"imageheight": thumbnailImage.size.height as AnyObject,
							"videoUrl": downloadUrl.absoluteString as AnyObject
						]
						self.sendMessageWithProperties(properties)
					})
				}

			})

		}

		uploadTask.observe(.progress) { (snapshot) in
//			print(snapshot.progress?.completedUnitCount)
			if let completedUnitCount = snapshot.progress?.completedUnitCount {
				self.navigationItem.title = String(completedUnitCount)
			}
		}
		
		uploadTask.observe(.success) { (snapshot) in
			self.navigationItem.title = self.user?.name
		}
		
	}

	private func thumbnailImageForFileUrl(fileUrl: URL) -> UIImage? {
		let asset = AVAsset(url: fileUrl)
		let imageGenerator = AVAssetImageGenerator(asset: asset)
		
		do {
			let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
			return UIImage(cgImage: thumbnailCGImage)
			
		} catch let err {
			print(err)
		}
		
		
		return nil
	}

	private func handleImageSelectedForInfo(info: [String: AnyObject]) {
		var selectedImageFromPicker: UIImage?
		
		//This gets the edited photo from the camera roll
		if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
			selectedImageFromPicker = editedImage
			print("editedImage: ", editedImage)
		}
			
			//This gets the original photo from the camera roll.
		else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
			
			print("originalImage: ", originalImage)
		}
		
		if let selectedImage = selectedImageFromPicker {
			uploadToFirebaseStorageUsingImage(selectedImage) { (imageUrl) in
				self.sendMessageWithImageUrl(imageUrl, image: selectedImage)
			}
		}
	}
	
	private func uploadToFirebaseStorageUsingImage(_ image: UIImage, completion: @escaping (_ imageUrl: String) -> ()) {
		print("Upload to Firebase!")
		let imageName = NSUUID().uuidString
		let storageRef = Storage.storage().reference().child("message_images").child(imageName)
		
		if let uploadData = image.jpegData(compressionQuality: 0.2) {
			storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
				
//				guard let metadata = metadata else { return } //
				
				if error != nil {
					print("Failed to upload image: ", error as Any)
					return
				}
				
//				print("metadata!!!!!!", metadata)
				
				storageRef.downloadURL(completion: { (url, error) in
					if error != nil {
						print(error)
						return
					}
//					print("url?.absoluteString!!: ", url?.absoluteString ?? "")
					completion(url?.absoluteString ?? "")
					
	
//					self.sendMessageWithImageUrl(url?.absoluteString ?? "", image: image)

				})
				
				
			}
		}
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: nil)
	}
	
	override var inputAccessoryView: UIView? {
		get {
			
			return inputContainerView
		}
	}
	override var canBecomeFirstResponder: Bool {
		return true
	}
	
	func setupKeyboardObservers() {
		NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		//catch memory leak for when keyboard shows and hides.
		NotificationCenter.default.removeObserver(self)
	}
	
	@objc func handleKeyboardWillShow(notification: Notification) {
//		print("\n---------- [ keyboard notification.userInfo ] ----------\n")
//		print(notification.userInfo!)//force unwrapping
		let keyboardFrame:CGRect = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey]! as! CGRect
		let keyboardDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]! as! Double
//		print("keyboardFrame: ", keyboardFrame)
//		print("keyboardFrame.height: ", keyboardFrame.height)
		
		//move the input area up as keyboard shows.
		containerViewBottomAnchor?.constant = -keyboardFrame.height
		UIView.animate(withDuration: keyboardDuration) {
			self.view.layoutIfNeeded()
		}
	}
	
	@objc func handleKeyboardWillHide(notification: Notification) {
		let keyboardDuration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]! as! Double
		//move the input area down as keyboard hides.
		containerViewBottomAnchor?.constant = 0
		UIView.animate(withDuration: keyboardDuration) {
			self.view.layoutIfNeeded()
		}
	}
	
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return messages.count
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		//        cell.backgroundColor = UIColor.blue
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
		
		cell.chatLogController = self
		
		let message = messages[indexPath.item]
		
		cell.message = message
		
		cell.textView.text = message.text
		
		setupCell(cell: cell, message: message)
		
		//modifying the bubbleView's width
		if let text = message.text {
			//text message
			cell.bubbleWidthAnchor?.constant = estimatedFrameForText(text: text).width + 32
			cell.textView.isHidden = false
			
		} else if message.imageUrl != nil {
			//fall in here if it is an image message.
			cell.bubbleWidthAnchor?.constant = 200
			cell.textView.isHidden = true
			
		}
		
//		if message.videoUrl != nil {
//			cell.playButton.isHidden = false
//		} else {
//			cell.playButton.isHidden = true
//		}
		cell.playButton.isHidden = message.videoUrl == nil
		
		
		return cell
	}
	
	fileprivate func setupCell(cell: ChatMessageCell, message: Message) {
		if let profileImageUrl = self.user?.profileImageUrl {
			cell.profileImageView.loadImageUsingCacheWithUrlString(profileImageUrl)
		}

		
		if message.fromId == Auth.auth().currentUser?.uid {
			//outgoing blue
			cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
			cell.textView.textColor = UIColor.white
			cell.profileImageView.isHidden = true
			
			cell.bubbleViewRightAnchor?.isActive = true
			cell.bubbleViewLeftAnchor?.isActive = false
			
		} else {
			//incoming gray
			cell.bubbleView.backgroundColor = UIColor(r: 240, g: 240, b: 240)
			cell.textView.textColor = UIColor.black
			cell.profileImageView.isHidden = false
			
			cell.bubbleViewRightAnchor?.isActive = false
			cell.bubbleViewLeftAnchor?.isActive = true
		}
		
		if let messageImageUrl = message.imageUrl {		cell.messageImageView.loadImageUsingCacheWithUrlString(messageImageUrl)
			cell.messageImageView.isHidden = false
			cell.bubbleView.backgroundColor = UIColor.clear
		} else {
			cell.messageImageView.isHidden = true
		}
		
		
		
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		collectionView?.collectionViewLayout.invalidateLayout()
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		var height: CGFloat = 80
		//get the estimated height for each text
		
		let message = messages[indexPath.item]
		if let text = message.text {
			height = estimatedFrameForText(text: text).height + 20
		} else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
			// h1/w1 = h2/w2 solve for h1
			// h1 = h2 / w2 * w1
			height = CGFloat(imageHeight / imageWidth * 200)
		}
		let width = UIScreen.main.bounds.width
		return CGSize(width: width, height: height)
	}
	
	fileprivate func estimatedFrameForText(text: String) -> CGRect {
		
		let size = CGSize(width: 200, height: 1000)
		let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
		
		return NSString(string: text).boundingRect(with: size, options: options, attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font): UIFont.systemFont(ofSize: 16)]), context: nil)
	}
	
	var containerViewBottomAnchor: NSLayoutConstraint?
	

	
	@objc func handleSend() {
		let properties = ["text": inputContainerView.inputTextField.text!]
		sendMessageWithProperties(properties as [String: AnyObject])
	}
	
	fileprivate func sendMessageWithImageUrl(_ imageUrl: String, image: UIImage) {
		let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": image.size.width as AnyObject, "imageHeight": image.size.height as AnyObject]
		sendMessageWithProperties(properties)
	}
	
	fileprivate func sendMessageWithProperties(_ properties: [String : AnyObject]) {
		let ref = Database.database().reference().child("messages")
//		var ref: DatabaseReference!
//		ref = Database.database().reference().child("messages")
		
		let childRef = ref.childByAutoId()
		let toId = user!.id!
		let fromId = Auth.auth().currentUser!.uid
		let timestamp = Int(Date().timeIntervalSince1970)
		
		var values: [String: AnyObject] = ["toId": toId as AnyObject, "fromId": fromId as AnyObject, "timestamp": timestamp as AnyObject]
		
		properties.forEach({values[$0] = $1})
		
		childRef.updateChildValues(values) { (error, ref) in
			if error != nil {
				print(error!)
				return
			}
			
			self.inputContainerView.inputTextField.text = nil
			
//			guard let messageId = childRef.key else { return }
			let messageId = childRef.key
			
			let userMessageRef = Database.database().reference().child("user-messages").child(fromId).child(toId).child(messageId)
			userMessageRef.setValue(1)
			
			let recipientUserMessageRef = Database.database().reference().child("user-messages").child(toId).child(fromId).child(messageId)
			recipientUserMessageRef.setValue(1)
			
			
		}
	}
	
//	var player: AVPlayer?
//	var playerLayer: AVPlayerLayer?
//	
//	func performZoomInForVideo(startingImageView: UIImageView, videoUrl: URL?) {
//		if let videoUrl = videoUrl {
//			
//			self.startingImageView = startingImageView
//			self.startingImageView?.isHidden = true
//			
//			startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
//			
//			player = AVPlayer(url: videoUrl)
//			playerLayer = AVPlayerLayer(player: player)
//			print("startingFrame: ", startingFrame)
//			
//			
//			player?.play()
//			
//			//FIXME: !!!!!!!!!
//		}
//
//		
//	}

	
	//custom zooming logic
	
	var startingFrame: CGRect?
	var blackBackgroundView: UIView?
	var startingImageView: UIImageView?
	
	func performZoomInForStartingImageView(startingImageView: UIImageView) {
		
		self.startingImageView = startingImageView
		self.startingImageView?.isHidden = true
		
		startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
//		print(startingFrame) //ex) optional((x, y, w, h))
		
		let zoomingImageView = UIImageView(frame: startingFrame!)
//		zoomingImageView.backgroundColor = UIColor.red
		zoomingImageView.image = startingImageView.image
		zoomingImageView.isUserInteractionEnabled = true
		zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
		
		if let keyWindow = UIApplication.shared.keyWindow {
			
			blackBackgroundView = UIView(frame: keyWindow.frame)
			blackBackgroundView?.backgroundColor = UIColor.black
			blackBackgroundView?.alpha = 0
			
			keyWindow.addSubview(blackBackgroundView!)
			keyWindow.addSubview(zoomingImageView)
			
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: UIView.AnimationOptions.curveEaseOut, animations: {
				
				self.blackBackgroundView?.alpha = 0.8
				self.inputContainerView.alpha = 0.2
				
				// math?
				// h2 / w1 = h1 / w1
				// h2 = h1 / w1 * w1
				
				let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
				
				zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
				
				zoomingImageView.center = keyWindow.center
				
			}, completion: nil)

			
		}
		
//		UIApplication.shared.keyWindow?.addSubview(zoomingImageView)
	}
	
	@objc func handleZoomOut(tapGesture: UITapGestureRecognizer) {
		print("Zooming out")
		
		if let zoomOutImageView = tapGesture.view {
			//need to animate back out to controller
			zoomOutImageView.layer.cornerRadius = 16
			zoomOutImageView.clipsToBounds = true
			
			UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: UIView.AnimationOptions.curveEaseOut, animations: {
				zoomOutImageView.frame = self.startingFrame!
				self.blackBackgroundView?.alpha = 0
				self.inputContainerView.alpha = 1
				
			}) { (completed) in
				zoomOutImageView.removeFromSuperview()
				self.startingImageView?.isHidden = false
			}
			
		}
		
	}
	
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
