//
//  ChatVIewController.swift
//  Waffle
//
//  Created by Ben on 4/17/18.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices

final class ChatVIewController: JSQMessagesViewController {
    //MARK: - Properties
    private var messages = [JSQMessage]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.senderId = "1"
        self.senderDisplayName = "Ben"
    }
    
   override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        print("didPressSend button tapped !!")
    messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, text: text))
    collectionView.reloadData()
    print(messages)
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
    
    private func getMedia(_ type: CFString) {
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.mediaTypes = [type as String]
        self.present(mediaPicker, animated: true, completion: nil)
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
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        return bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.5))
    }
    
}
 //MARK: - Implementing some Delegates below
extension ChatVIewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let picture = info[UIImagePickerControllerOriginalImage] as? UIImage {
        let image = JSQPhotoMediaItem(image: picture)
        messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: image))
        } else if let videoURL = info[UIImagePickerControllerImageURL] as? URL {
            let video = JSQVideoMediaItem(fileURL: videoURL, isReadyToPlay: true)
            messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: video))
        }
        self.dismiss(animated: true, completion: nil)
        collectionView.reloadData()
    }
}





