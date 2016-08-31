//
//  WelcomeController.swift
//  Keno
//
//  Created by Marcos Polanco on 8/29/16.
//  Copyright © 2016 Fanatize. All rights reserved.
//


import UIKit
import Money

class WelcomeController: UIViewController {
    
    @IBOutlet weak var balanceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBarHidden = true
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.balanceLabel.text = Player.player?.wallet.available().asUSD() ?? "$?"
    }
}