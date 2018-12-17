//
//  ViewController.swift
//  MemeMe
//
//  Created by Miriana Moura on 12/2/18.
//  Copyright © 2018 mmoura. All rights reserved.
//

import UIKit

struct Meme {
    var topText: String
    var bottomText: String
    var originalImage: UIImage
    var memedImage: UIImage
}

class ViewController: UIViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, UITextFieldDelegate {

    let memeTextAttributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key.strokeColor: UIColor.black,
        NSAttributedString.Key.foregroundColor: UIColor.white,
        NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSAttributedString.Key.strokeWidth:  -4.6
    ]
    
    // MARK: Outlets
    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var albumButton: UIBarButtonItem!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var bottomToolBar: UIToolbar!
    @IBOutlet weak var topToolBar: UIToolbar!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    

    override func viewWillAppear(_ animated: Bool) {
        //Will disable the camera button if camera isn't available
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        subscribeToKeyboardNotifications()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
        unsubscribeFromKeyboardNotifications()
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.topTextField.delegate = self
        self.bottomTextField.delegate = self
        
        configureText(textField: topTextField, text: "TOP", defaultAttributes: memeTextAttributes)
        configureText(textField: bottomTextField, text: "BOTTOM", defaultAttributes: memeTextAttributes)
        
        shareButton.isEnabled = false
        
    }

    // MARK: Actions
    @IBAction func pickAnImageFromCamera(_ sender: Any) {
        presentImagePicker(sourceType: .camera)
    }
  
    @IBAction func pickAnImageFromAlbum(_ sender: Any) {
        presentImagePicker(sourceType: .photoLibrary)
    }
    
    func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let originalImage = info[.originalImage] as? UIImage {
            self.imagePickerView.image = originalImage
        }
        self.dismiss(animated: true, completion: nil)
        
        shareButton.isEnabled = true
    }
    
    func configureText(textField: UITextField, text: String, defaultAttributes: [NSAttributedString.Key : Any]?) {
        textField.delegate = self
        textField.text = text
        textField.defaultTextAttributes = memeTextAttributes
        textField.textAlignment = .center

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //This will allow to click done once editing is complete
        textField.resignFirstResponder()
        return true
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        if bottomTextField.isFirstResponder {
            view.frame.origin.y -= getKeyboardHeight(notification)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
            view.frame.origin.y = 0
        }
    
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue// of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    func subscribeToKeyboardNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)

    }

    func save() {
        // Create the meme
        let meme = Meme(topText: topTextField.text!, bottomText: bottomTextField.text!, originalImage: imagePickerView.image!, memedImage: generateMemedImage())
        // Add it to the memes array in the Application Delegate
        let object = UIApplication.shared.delegate
        let appDelegate = object as! AppDelegate
        appDelegate.memes.append(meme)
        
    }
    
    func generateMemedImage() -> UIImage {
        
        // TODO: Hide toolbar and navbar
        self.bottomToolBar.isHidden = true
        self.topToolBar.isHidden = true
        
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // TODO: Show toolbar and navbar
        configureBars(true)

        
        return memedImage
    }
    
    
    func configureBars(_ isHidden: Bool) {
        self.bottomToolBar.isHidden = isHidden
        self.topToolBar.isHidden = isHidden
    }
    
    @IBAction func memeCancelButton(_ sender: Any) {
        imagePickerView.image = nil
        topTextField.text = "TOP"
        bottomTextField.text = "BOTTOM"
        shareButton.isEnabled = false
        if let _ = self.navigationController {
            self.navigationController!.popToRootViewController(animated: true)
        }
        
    }
    
    @IBAction func memeShareButton(_ sender: Any) {
        let memedImage = generateMemedImage()
        let activityViewController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
        activityViewController.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed:Bool, returnedItems:[Any]?, error: Error?) in
            if !completed {
                print("Cancelled!")
                return
            }else{
                self.save()
                if let _ = self.navigationController {
                    self.navigationController!.popToRootViewController(animated: true)
                }
                
            }
    
        }
    }
}
