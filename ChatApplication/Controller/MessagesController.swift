//
//  ViewController.swift
//  ChatApplication
//
//  Created by 변재우 on 20180921//.
//  Copyright © 2018 변재우. All rights reserved.
//

import UIKit
import Firebase


// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

class MessagesController: UITableViewController {
    
    var tapGestureRecognizer: UIGestureRecognizer!
    
    let cellId = "cellId"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        let newMessagesIcon = UIImage(named: "new_message_icon")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: newMessagesIcon, style: .plain, target: self, action: #selector(handleNewMessage))
        
//        navigationItem.titleView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChatController)))
        
        
        checkIfUserIsLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
//        observeMesssages()
        
        observeUserMessages()
		
		tableView.allowsMultipleSelectionDuringEditing = true
       
    }
	
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		
		
		guard let uid = Auth.auth().currentUser?.uid else {
			return
		}
		
		let message = self.messages[indexPath.row]
		
		if let chatPartnerId = message.chatPartnerId() {
			Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue { (error, ref) in
				if error != nil {
					print("Failed to delete message: ", error as Any)
					return
				}
				
				self.messagesDictionary.removeValue(forKey: chatPartnerId)
				self.attemptReloadOfTable()
				
//             !!!one way of updating, but not safe.
//				self.messages.remove(at: indexPath.row)
//				self.tableView.deleteRows(at: [indexPath], with: .automatic)
				
				
				
			}
			
		}
	
		
		
	}
    
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference().child("user-messages").child(uid)
		// MARK: observing whenever a child is added
        ref.observe(.childAdded, with: { (snapshot) in
//            print(snapshot)
            let userId = snapshot.key
            Database.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
//                print(snapshot)
					
                let messageId = snapshot.key
                self.fetchMessageWithMessageId(messageId: messageId)
                
            }, withCancel: nil)
            
        }, withCancel: nil)
		
		// MARK: observing whenever a child is removed (from outside source)
		ref.observe(.childRemoved, with: { (snapshot) in
			print(snapshot)
			print(self.messagesDictionary)
			
			self.messagesDictionary.removeValue(forKey: snapshot.key)
			self.attemptReloadOfTable()
			
		}, withCancel: nil)

    }
    
    var timer: Timer?
    
    private func fetchMessageWithMessageId(messageId: String) {
        let messageReference = Database.database().reference().child("messages").child(messageId)
        
        messageReference.observeSingleEvent(of: .value, with: { (snapshot) in
//            print(snapshot)
			
            if let dictionary = snapshot.value as? [String: Any] {
					let message = Message(dictionary: dictionary as [String : AnyObject])
                //                message.setValuesForKeys(dictionary)
                self.messages.append(message)
                
                if let chatPartnerId = message.chatPartnerId() {
                    self.messagesDictionary[chatPartnerId] = message
                }
                self.attemptReloadOfTable()
            }
        }, withCancel: nil)
    }
    
    private func attemptReloadOfTable() {
        //#96 & 97 is for reloading the data for the minimal amount of times.
        self.timer?.invalidate()
//        print("we just canceled our timer")
		
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
//        print("schedule a table reload in 0.1 sec")
        //                print(message.text!)
    }
    
    @objc func handleReloadTable() {
        self.messages = Array(self.messagesDictionary.values)//
        
        self.messages.sort(by: { (message1, message2) -> Bool in
            return message1.timestamp?.intValue > message2.timestamp?.intValue
        })
        
        //this will crash because of background thread, so lets call this on dispatchQueue.main.async
        DispatchQueue.main.async {
//            print("we reloaded the table")
            self.tableView.reloadData()
        }
    }
    
//    func observeMesssages() {
//        let ref = Database.database().reference().child("messages")
//        ref.observe(.childAdded, with: { (snapshot) in
//
//            if let dictionary = snapshot.value as? [String: Any] {
//                let message = Message(dictionary: dictionary)
////                message.setValuesForKeys(dictionary)
//                self.messages.append(message)
//
//                if let toId = message.toId {
//                    self.messagesDictionary[toId] = message
//
//                    self.messages = Array(self.messagesDictionary.values)//
//
//                    self.messages.sort(by: { (message1, message2) -> Bool in
//                        return message1.timestamp?.intValue > message2.timestamp?.intValue
//                    })
//                }
//
//                //this will crash because of background thread, so lets call this on dispatchQueue.main.async
//
//                DispatchQueue.main.async {
//                    self.tableView.reloadData()
//                }
//
////                print(message.text!)
//            }
//
////            print(snapshot)
//
//        }, withCancel: nil)
//    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let message = messages[indexPath.row]
        cell.message = message
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = self.messages[indexPath.row]
        
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        
        let ref = Database.database().reference().child("users").child(chatPartnerId)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            print(snapshot)
            guard let dictionary = snapshot.value as? [String: Any] else {
                return
            }

            let user = User(dictionary: dictionary)
            user.id = chatPartnerId
            self.showChatControllerForUser(user: user)
            
        }, withCancel: nil)
//        print(message.text, message.toId, message.fromId)
    }
    
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageController()
        //
        newMessageController.messagesController = self
        present(UINavigationController(rootViewController: newMessageController), animated: true, completion: nil)
    }
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
            handleLogout()
        } else {
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    func fetchUserAndSetupNavBarTitle() {
        guard let uid = Auth.auth().currentUser?.uid else {
            //for some reason uid = nil
            return
        }
        Database.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            print("\n---------- [ snapshot ] ----------\n")
            print(snapshot)
            
            if let dictionary = snapshot.value as? [String: Any] {
//                self.navigationItem.title = dictionary["name"] as? String
                
                let user = User(dictionary: dictionary)
                self.setupNavBarWithUser(user: user)
            }
            
        }, withCancel: nil)
    }
    
    func setupNavBarWithUser(user: User) {
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
        
//        self.navigationItem.title = user.name
        
        let titleView = UIView()
        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChatControllerForUser(user: ))))
        
       self.navigationItem.titleView = titleView
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
//        titleView.backgroundColor = UIColor.blue
      
        
      
        
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        
        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImageUsingCacheWithUrlString(profileImageUrl)
        }
        
        containerView.addSubview(profileImageView)
        //iOS 9 constraint anchors // need x,y,width,height anchors
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel = UILabel()
        
        containerView.addSubview(nameLabel)
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        //need xywidthheight anchors
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        

    }
    
    
    @objc func showChatControllerForUser(user: User) {
        print("\n---------- [ push to ChatLogController ] ----------\n")
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
        
    }
    
    @objc func handleLogout() {
        
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
    }

}

