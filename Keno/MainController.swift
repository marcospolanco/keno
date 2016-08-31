//
//  MainController.swift
//  Keno
//
//  Created by Marcos Polanco on 8/29/16.
//  Copyright © 2016 Fanatize. All rights reserved.
//


import UIKit
import Money
import THLabel
import ZFRippleButton

class MainController: UIViewController {
    
    @IBOutlet weak var kenoBorder: UIView!
    @IBOutlet weak var balanceLabel: THLabel!
    @IBOutlet weak var betLabel: THLabel!
    @IBOutlet weak var playButton: ZFRippleButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.balanceLabel.text = "Balance: \(Player.player?.wallet.available().asUSD() ?? "")"
    }
    
    @IBAction func playAction(sender: AnyObject) {
//        UIView.animateWithDuration(2){
//            self.dismissEmbeddedController()
//        }
        self.performSegueWithIdentifier(Segues.PlayKeno.rawValue, sender: self)
    }
}

class WelcomeController: UIViewController {
    @IBOutlet weak var balanceLabel: UILabel!
}