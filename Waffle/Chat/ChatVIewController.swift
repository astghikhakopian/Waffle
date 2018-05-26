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
import TesseractOCR
import MessageUI

final class ChatVIewController: JSQMessagesViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var mySwitch: UISwitch!
    
    
    private lazy var messages = [JSQMessage]()
    private lazy var avatars = [String: JSQMessagesAvatarImage]()
    private var containsText = false
    private let photoCache = NSCache<AnyObject, AnyObject>()
    private let ref = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid).child("messages")
    private var friendNumber: String = ""
    var friendId: String!
    
    @IBAction func switchButtonAction(_ sender: UISwitch) {
        if sender.isOn == true {
            navigationItem.title = "Immediate Snap"
        } else {
            navigationItem.title = "Chat"
        }
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let currentUser = Auth.auth().currentUser {
            senderId = currentUser.uid
            senderDisplayName = "\(currentUser.displayName ?? "")"
        }
        navigationController?.navigationBar.tintColor = .white
        if mySwitch.isOn {
            self.navigationItem.title = "Immediate Snap"
        } else {
            self.navigationItem.title = "Chat"
        }
        observeMessages()
        scrollToBottom(animated: true)
        
        let leftButton = UIButton(frame: .zero)
        leftButton.setImage(#imageLiteral(resourceName: "more"), for: .normal)
        inputToolbar.contentView.leftBarButtonItemWidth = CGFloat(34.0)
        inputToolbar.contentView.leftBarButtonItem = leftButton
        
        let rightButton = UIButton(frame: .zero)
        rightButton.setImage(#imageLiteral(resourceName: "send"), for: .normal)
        inputToolbar.contentView.rightBarButtonItemWidth = CGFloat(34.0)
        inputToolbar.contentView.rightBarButtonItem = rightButton
        inputToolbar.contentView.textView.placeHolder = "Type Message ..."
        
        let avatarSize = CGSize(width: 38, height: 38)
        collectionView?.collectionViewLayout.incomingAvatarViewSize = avatarSize
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = avatarSize
        
        observeFriendsNumber()
    }
    
    // MARK: - Private Methods
    
    private func observeFriendsNumber() {
        Database.database().reference().child("users").child(friendId).observe(.value) { (snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                self.friendNumber = dict["phone number"] as? String ?? ""
                if self.friendNumber == "" {
                    self.mySwitch.isEnabled = false
                }
            }
        }
    }
    
    private func observeUsers(_ id: String) {
        Database.database().reference().child("users").child(id).observe(.value) { (snapshot) in
            if let dict = snapshot.value as? [String: Any] {
                let avatarURL = dict["photoUrl"] as! String
                self.setupAvatar(avatarURL, id)
            }
        }
    }
    
    private func setupAvatar(_ url: String, _ userID: String) {
        DispatchQueue.global(qos: .userInteractive).async {
            let fileURL = URL(string: url)
            if fileURL != nil {
                let data = try? Data(contentsOf: fileURL!)
                let image = UIImage(data: data!)
                let userImg = JSQMessagesAvatarImageFactory.avatarImage(with: image, diameter: 30)
                self.avatars[userID] = userImg
            } else {
                self.avatars[userID] = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatar"), diameter: 30)
            }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
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
                            DispatchQueue.global(qos: .userInteractive).async {
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
    
    private func getMediaURL(_ filePath: String, _ mediaType: String) {
        
        StorageReference().child(filePath).downloadURL(completion: { (url, error) in
            if error == nil {
                if let downloadString = url {
                    let messageRef = self.ref.childByAutoId()
                    let downloadURL = downloadString.absoluteString
                    let messageData = ["fileURL": downloadURL, "receiver": self.friendId, "senderID": self.senderId, "senderName": self.senderDisplayName, "MediaType": mediaType]
                    if self.friendId != self.senderId {
                        messageRef.setValue(messageData)
                        Database.database().reference().child("users").child(self.friendId).child("messages").childByAutoId().setValue(messageData)
                    } else {
                        messageRef.setValue(messageData)
                    }
                }
            } else {
                print("Something went wrong!!")
            }
        })

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
                self.getMediaURL(filePath, "PHOTO")
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
                self.getMediaURL(filePath, "VIDEO")
            }
        }
    }
    
    
    // MARK: - JSQMessagesViewController DataSource
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        if MFMessageComposeViewController.canSendText() && mySwitch.isOn {
            
            let controller = MFMessageComposeViewController()
            controller.body = keyboardController.textView.text
            controller.recipients = [friendNumber]
            controller.messageComposeDelegate = self
            present(controller, animated: true, completion: nil)
        }
        navigationItem.title = "Immediate Snap"
        let messageRef = ref.childByAutoId()
        let messageData = ["text": text, "senderID": senderId, "senderName": senderDisplayName, "MediaType": "TEXT", "receiver": friendId]
        if friendId != senderId {
            messageRef.setValue(messageData)
            Database.database().reference().child("users").child(friendId).child("messages").childByAutoId().setValue(messageData)
        } else {
            messageRef.setValue(messageData)
        }
        finishSendingMessage(animated: true)
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let sheet = UIAlertController(title: "Media Message", message: "Select a Media", preferredStyle: .actionSheet)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let photoLibrary = UIAlertAction(title: "Photo Library", style: .default) { (alert) in
            self.getMedia(kUTTypeImage)
        }
       /* let videoLibrary = UIAlertAction(title: "Video Library", style: .default) { (alert) in
            self.getMedia(kUTTypeMovie)
        }
     */
        let imgToText = UIAlertAction(title: "Image to Text", style: .default) { (alert) in
            self.containsText = !self.containsText
            self.getMedia(kUTTypeImage)
        }
        sheet.addAction(imgToText)
        sheet.addAction(photoLibrary)
       // sheet.addAction(videoLibrary)
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
        let message = messages[indexPath.row]
        return avatars[message.senderId]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        if message.senderId == senderId {
            return bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.5))
        } else {
            return bubbleFactory?.incomingMessagesBubbleImage(with: .gray)
        }
    }
}


// MARK: - PickerControllerDelegate implementation

extension ChatVIewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let picture = info[UIImagePickerControllerOriginalImage] as? UIImage {
            if containsText {
                if let tessercat = G8Tesseract(language: "eng") {
                    tessercat.delegate = self
                    tessercat.image = picture.g8_blackAndWhite()
                    tessercat.recognize()
                    containsText = false
                    keyboardController.textView.text = tessercat.recognizedText
                    inputToolbar.contentView.rightBarButtonItem.isEnabled = true
                }
            } else {
                sendMedia(picture, nil)
            }
        } else if let videoURL = info[UIImagePickerControllerImageURL] as? URL {
            let video = JSQVideoMediaItem(fileURL: videoURL, isReadyToPlay: true)
            messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: video))
            sendMedia(nil, videoURL)
        }
        dismiss(animated: true, completion: nil)
        containsText = !containsText
        collectionView.reloadData()
    }
}

//MARK: - MFMessage Delegation

extension ChatVIewController: MFMessageComposeViewControllerDelegate, G8TesseractDelegate {
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(animated: true, completion: nil)
        mySwitch.isOn = false
    }
    
    func progressImageRecognition(for tesseract: G8Tesseract!) {
        print("\(tesseract.progress) %")
    }
    
}
