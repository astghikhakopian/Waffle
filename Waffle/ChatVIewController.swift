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
    //MARK: - Properties
    private lazy var messages = [JSQMessage]()
    private lazy var avatars = [String: JSQMessagesAvatarImage]()
    let ref = Database.database().reference().child("message")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let currenUser = Auth.auth().currentUser  {
            self.senderId = currenUser.uid
            self.senderDisplayName = "\(currenUser.displayName!)"
        }
//        self.setupAvatar("https://lh4.googleusercontent.com/-r1oG9eAgCJE/AAAAAAAAAAI/AAAAAAAAAAA/ACLGyWC_paQ3Cxax6aOqH_6rcDfiDUKuJg/s96-c/photo.jpg", "DVhTeIEOOQPVOCAefXueFxrCOIo1")
        observeMessages()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
   override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
    let messageRef = ref.childByAutoId()
    let messageData = ["text": text, "senderID": senderId, "senderName": senderDisplayName, "MediaType": "TEXT"]
    messageRef.setValue(messageData)
    self.finishSendingMessage()
    }
    
    //MARK: - Private Methods
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
    
    private func observeMessages() {
        ref.observe(DataEventType.childAdded) { (snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                let mediaType = dict["MediaType"] as! String
                let senderID = dict["senderID"] as! String
                let senderName = dict["senderName"] as! String
                self.observeUsers(senderID)
                
                switch mediaType {
                    
                case "TEXT":
                    let text = dict["text"] as! String
                    self.messages.append(JSQMessage(senderId: senderID, displayName: senderName, text: text))
                    
                case "PHOTO":
                    let fileURL = dict["fileURL"] as! String
                    let url = URL(string: fileURL)
                    let data = try? Data(contentsOf: url!)
                    if let data = data {
                        let picture = UIImage(data: data)
                        let photo = JSQPhotoMediaItem(image: picture)
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
                
                self.collectionView.reloadData()
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
            let messageData = ["fileURL": fileURL, "senderID": self.senderId, "senderName": self.senderDisplayName, "MediaType": "PHOTO"]
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
                let messageData = ["fileURL": fileURL, "senderID": self.senderId, "senderName": self.senderDisplayName, "MediaType": "VIDEO"]
                messageRef.setValue(messageData)
            }

        }
    }
    
    //MARK: - JSQMessagesViewController DataSource
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
        let message = messages[indexPath.row]
        return avatars[message.senderId]
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
 //MARK: - Implementing some Delegates below
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





