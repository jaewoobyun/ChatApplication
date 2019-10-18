//
//  LoginController+handlers.swift
//  ChatApplication
//
//  Created by 변재우 on 20181001//.
//  Copyright © 2018 변재우. All rights reserved.
//

import Foundation
import UIKit
import Firebase

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @objc func handleRegister() {
        print("handleRegister")
        guard let email = emailTextField.text, let password = passwordTextField.text, let name = nameTextField.text else {
            print("Form is not valid")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let uid = authResult?.user.uid else {
                return
            }
            
            //successfully authenticated user
            //uploading image to Firebase Storage
            let imageName = NSUUID().uuidString
            let storageRef = Storage.storage().reference().child("profile_images").child("\(imageName).jpg")
            
            if let profileImage = self.profileImageView.image, let uploadData = profileImage.jpegData(compressionQuality: 0.1) {
            
//            if let uploadData = UIImageJPEGRepresentation(self.profileImageView.image!, 0.1) {
//            if let uploadData = UIImagePNGRepresentation(self.profileImageView.image!) {
                storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                    
                    if error != nil {
                        print(error as Any)
                        return
                    }
//                    print(metadata)
                    
                    storageRef.downloadURL(completion: { (url, error) in
                        if error != nil {
                            print(error as Any)
                            return
                        }
                        else {
                            let downloadUrl = url?.absoluteString
                            
                            let values = ["name": name, "email": email, "profileImageUrl": downloadUrl ]
									self.registerUserIntoDatabaseWithUID(uid: uid, values: values as [String: Any] as [String : AnyObject])
                        }
                    })
                })
            }
        }
    }
    
    private func registerUserIntoDatabaseWithUID(uid: String, values: [String: AnyObject]) {
//            let ref = Database.database().reference(fromURL: "https://practice-26cea.firebaseio.com/")
        let ref = Database.database().reference()
        let usersReference = ref.child("users").child(uid)
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
//                print(err)
                return
            }
            
//            self.messagesController?.fetchUserAndSetupNavBarTitle()
//            self.messagesController?.navigationItem.title = values["name"] as? String
            
            //This setter potentially crashes if keys don't match
			let user =
				
				User(dictionary: values)
            self.messagesController?.setupNavBarWithUser(user: user)
            self.dismiss(animated: true, completion: nil)
            
            print("Saved user successfully into Firebase DB")
            
        })
    }
    
    @objc func handleSelectProfileImageView() {
        let picker = UIImagePickerController()
        
        picker.delegate = self
        picker.allowsEditing = true
        
        present(picker, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        
        var selectedImageFromPicker: UIImage?
        
        //This gets the edited photo from the camera roll
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
            print(editedImage)
        }
        
        //This gets the original photo from the camera roll.
        else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            
            print(originalImage)
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        }
        
//        print(info)
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("cancel picker")
        dismiss(animated: true, completion: nil)
    }
    
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}
