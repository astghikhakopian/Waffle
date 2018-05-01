//
//  ChatVIewController.swift
//  Waffle
//
//  Created by Ben on 4/17/18.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

final class ChatVIewController: JSQMessagesViewController {
    
    // MARK: - Properties
    
    private lazy var messages = [JSQMessage]()
    private lazy var avatars = [String: JSQMessagesAvatarImage]()
    var friendId: String!
    let photoCache = NSCache<AnyObject, AnyObject>()
    let ref = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid).child("messages")
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
       // addNavViewBarImage()
        if let currentUser = Auth.auth().currentUser {
            self.senderId = currentUser.uid
            self.senderDisplayName = "\(currentUser.displayName ?? "")"
        }
        observeMessages()
    }
    
    
    // MARK: - Private Methods
    
    private func observeUsers(_ id: String) {
       
        Database.database().reference().child("user").child(id).observe(DataEventType.value) { (snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                let avatarURL = dict["photoURL"] as! String
                self.setupAvatar(avatarURL, id)
            }
        }
    }
    
    private func setupAvatar(_ url: String, _ userID: String) {
       
        let fileURL = URL(string: url)
        let data = try? Data(contentsOf: fileURL!)
        if let data = data {
            let image = UIImage(data: data)
            let userImg = JSQMessagesAvatarImageFactory.avatarImage(with: image, diameter: 30)
            self.avatars[userID] = userImg
        } else {
            self.avatars[userID] = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatar"), diameter: 30)
        }
        collectionView.reloadData()
    }
    
    func addNavViewBarImage() {
        let navController = navigationController
        let logo = UIImage(named: "logo.png")
        let imageView = UIImageView(image:logo)
        self.navigationItem.titleView = imageView
        let bannerWidth = navController?.navigationBar.frame.size.width
        let bannerHeight = navController?.navigationBar.frame.size.height
        let bannerX = bannerWidth! / 2 - (logo?.size.width)! / 2
        let bannerY = bannerHeight! / 2 - (logo?.size.height)! / 2
        
        imageView.frame = CGRect(x: bannerX, y: bannerY, width: bannerWidth!, height:bannerHeight!)
        imageView.contentMode = .scaleAspectFit
        navigationItem.titleView = imageView
    }
    
    private func observeMessages() {
        
        ref.observe(DataEventType.childAdded) { (snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                
                if (dict["receiver"] as? String == self.senderId) && (dict["senderID"] as? String == self.friendId) || (dict["receiver"] as? String == self.friendId) && (dict["senderID"] as? String == self.senderId) {
                    
                let mediaType = dict["MediaType"] as! String
                let senderID = dict["senderID"] as! String
                let senderName = dict["senderName"] as! String
                self.observeUsers(senderID)
                switch mediaType {
                    case "TEXT":
                        let text = dict["text"] as! String
                        self.messages.append(JSQMessage(senderId: senderID, displayName: senderName, text: text))
                    case "PHOTO":
                        var photo = JSQPhotoMediaItem(image: nil)
                        let fileURL = dict["fileURL"] as! String
                        if let cachedPhoto = self.photoCache.object(forKey: fileURL as AnyObject) as? JSQPhotoMediaItem {
                            photo = cachedPhoto
                            self.collectionView.reloadData()
                        } else {
                            DispatchQueue.global().async {
                                let url = URL(string: fileURL)
                                let data = try? Data(contentsOf: url!)
                                DispatchQueue.main.async {
                                    if let data = data {
                                        let picture = UIImage(data: data)
                                        photo?.image = picture
                                        self.collectionView.reloadData()
                                        self.photoCache.setObject(photo!, forKey: fileURL as AnyObject)
                                    }
                                }
                            }
                            self.messages.append(JSQMessage(senderId: senderID, displayName: senderName, media: photo))
                            if self.senderId == senderID {
                                photo?.appliesMediaViewMaskAsOutgoing = true
                            } else {
                                photo?.appliesMediaViewMaskAsOutgoing = false
                            }
                        }
                        break
                    case "VIDEO":
                        let fileURL = dict["fileURL"] as! String
                        let videoURL = URL(string: fileURL)
                        let video = JSQVideoMediaItem(fileURL: videoURL, isReadyToPlay: true)
                        self.messages.append(JSQMessage(senderId: senderID, displayName: senderName, media: video))
                        if self.senderId == senderID {
                            video?.appliesMediaViewMaskAsOutgoing = true
                        } else {
                            video?.appliesMediaViewMaskAsOutgoing = false
                        }
                        break
                    
                    default:
                        break
                        }
                        self.finishReceivingMessage(animated: true)
                    }
                }
            }
        }
    
    private func getMedia(_ type: CFString) {
       
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.mediaTypes = [type as String]
        self.present(mediaPicker, animated: true, completion: nil)
    }
    
    private func sendMedia(_ image: UIImage?, _ video: URL?) {
        
        if let image = image {
            let filePath = "\(Auth.auth().currentUser!.uid)/\(Date.timeIntervalSinceReferenceDate)"
            Storage.storage().reference().child(filePath)
            let data = UIImageJPEGRepresentation(image, 0.5)
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpg"
            Storage.storage().reference().child(filePath).putData(data!, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                let messageRef = self.ref.childByAutoId()
                let fileURL = metadata!.downloadURLs![0].absoluteString
                let messageData = ["fileURL": fileURL, "receiver": self.friendId ,"senderID": self.senderId, "senderName": self.senderDisplayName, "MediaType": "PHOTO"]
                Database.database().reference().child("users").child(self.friendId).child("messages").childByAutoId().setValue(messageData)
                messageRef.setValue(messageData)
            }
            
        } else if let video = video {
            let filePath = "\(Auth.auth().currentUser!.uid)/\(Date.timeIntervalSinceReferenceDate)"
            Storage.storage().reference().child(filePath)
            let data = try? Data(contentsOf: video)
            let metadata = StorageMetadata()
            metadata.contentType = "video/mp4"
            Storage.storage().reference().child(filePath).putData(data!, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    return
                }
                let messageRef = self.ref.childByAutoId()
                let fileURL = metadata!.downloadURLs![0].absoluteString
                let messageData = ["fileURL": fileURL,"receiver": self.friendId ,"senderID": self.senderId, "senderName": self.senderDisplayName, "MediaType": "VIDEO"]
                messageRef.setValue(messageData)
            }
        }
    }
    
    
    // MARK: - JSQMessagesViewController DataSource
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        let messageRef = ref.childByAutoId()
        let messageData = ["text": text, "senderID": senderId, "senderName": senderDisplayName, "MediaType": "TEXT", "receiver": self.friendId]
        messageRef.setValue(messageData)
        Database.database().reference().child("users").child(self.friendId).child("messages").childByAutoId().setValue(messageData)
        self.finishSendingMessage(animated: true)
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        
        let sheet = UIAlertController(title: "Media Message", message: "Select a Media", preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let photoLibrary = UIAlertAction(title: "Photo Library", style: .default) { (alert) in
            self.getMedia(kUTTypeImage)
        }
        let videoLibrary = UIAlertAction(title: "Video Library", style: .default) { (alert) in
            self.getMedia(kUTTypeMovie)
        }
        sheet.addAction(photoLibrary)
        sheet.addAction(videoLibrary)
        sheet.addAction(cancel)
        self.present(sheet, animated: true, completion: nil)
    }
    
    
    // MARK: - UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        //        TODO:
        //        let message = messages[indexPath.row]
        //        return avatars[message.senderId]
        return JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatar"), diameter: 30)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let message = self.messages[indexPath.item]
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        if message.senderId == self.senderId {
            return bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.5))
        } else {
            return bubbleFactory?.incomingMessagesBubbleImage(with: .gray)
        }
    }
}


// MARK: - ChatVIewController Extension

extension ChatVIewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let picture = info[UIImagePickerControllerOriginalImage] as? UIImage {
            sendMedia(picture, nil)
        } else if let videoURL = info[UIImagePickerControllerImageURL] as? URL {
            let video = JSQVideoMediaItem(fileURL: videoURL, isReadyToPlay: true)
            messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: video))
            sendMedia(nil, videoURL)
        }
        self.dismiss(animated: true, completion: nil)
        collectionView.reloadData()
    }
}
