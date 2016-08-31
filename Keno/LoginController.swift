//
//  LoginController.swift
//  Keno
//
//  Created by Marcos Polanco on 8/29/16.
//  Copyright © 2016 Fanatize. All rights reserved.
//

import UIKit
import AVFoundation
import ZFRippleButton
class LoginController: UIViewController {
    
    @IBOutlet weak var usernameField: UITextField!  //field for username
    @IBOutlet weak var passwordField: UITextField!  //field for password
    @IBOutlet weak var loginButton: ZFRippleButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBarHidden = true
        self.usernameField.becomeFirstResponder()
        self.loginButton.backgroundColor = Colors.darkStrong
        self.loginButton.setTitleColor(.whiteColor(), forState: .Normal)
        
        for field in [usernameField, passwordField] {
            field.backgroundColor = Colors.liteLight
            field.textColor = Colors.darkStrong
        }
        
        loginButton.setTitleColor(Colors.liteLight, forState: .Normal)
        loginButton.backgroundColor = Colors.darkStrong
        loginButton.rippleColor = Colors.darkMedium
        loginButton.rippleOverBounds = false
        loginButton.rippleBackgroundColor = Colors.darkLight
    }
    
    var audioPlayer: AVAudioPlayer?
    
    private var kenoController: KenoController? {
        return  self.parentViewController as? KenoController
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if let kenoController = kenoController where kenoController.state == .NotPlaying {
            Threads.onMain{
//                kenoController.state = .Drawing
//                kenoController.playAction(self)
            }
        }
    }
    
    //Respond to user action of logging in, either when they enter a password or tap the button
    @IBAction func login(sender: AnyObject) {
        
        //cancel the animation
        self.kenoController?.cancelDrawing()
        
        //flag that the user has logged in,
        Player.isLoggedIn = true
        
        //set the player with the given credentials
        Player.player = Player(username: usernameField.text ?? "", password: passwordField.text ?? "")
        
//        UIView.animateWithDuration(2){
//            self.dismissEmbeddedController()
//        }
        
        
        //welcome them to the game
        self.performSegueWithIdentifier(Segues.Welcome.rawValue, sender: self)
    }
}

extension LoginController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else {
            login(self)
        }
        return true
    }
}