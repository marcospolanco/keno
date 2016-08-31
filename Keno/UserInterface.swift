//
//  UserInterface.swift
//  Keno
//
//  Created by Marcos Polanco on 8/29/16.
//  Copyright © 2016 Fanatize. All rights reserved.
//

import UIKit
import THLabel
import AVFoundation

//The segue identifiers in the application. 
enum Segues: String {
    case Welcome = "Welcome"
    case PlayKeno = "PlayKeno"
}

//The color palette for the application
struct Colors {
    //http://www.colorcombos.com/color-schemes/8919/ColorCombo8919.html
//    static let darkStrong  = UIColor(netHex: 0x004C70)
//    static let darkMedium  = UIColor(netHex: 0x006495)
//    static let darkLight  = UIColor(netHex: 0x0093D1)
//    static let liteStrong  = UIColor(netHex: 0xF2635F)
//    static let liteMedium  = UIColor(netHex: 0xF4D00C)
//    static let liteLight  = UIColor(netHex: 0xE0A025)

    //http://www.colorcombos.com/color-schemes/173/ColorCombo173.html
    static let darkStrong  = UIColor(netHex: 0x206BA4)
    static let darkMedium  = UIColor(netHex: 0xBBD9EE)
    static let darkLight  = UIColor(netHex: 0xEBF4FA)
    static let liteStrong  = UIColor(netHex: 0xC0C0C0)
    static let liteMedium  = UIColor(netHex: 0xE7E4D3)
    static let liteLight  = UIColor(netHex: 0xF1EFE2)
}

enum Sounds: String {
    case Bet  = "bet"
    case Hit  = "hit"
    case Miss = "miss"
    case Play = "play"
    case Error = "error"
    case Undo = "undo"
    case Start = "start"
    case Cash = "cash"
    
    static var player: AVAudioPlayer?
    
    func play() {
        Sounds.player?.stop()
        
        if let path = NSBundle.mainBundle().pathForResource(self.rawValue, ofType:"mp3") {
            let sound = NSURL(fileURLWithPath: path)
            Sounds.player = try! AVAudioPlayer(contentsOfURL: sound)
            Sounds.player?.prepareToPlay()
            Threads.onMain{Sounds.player?.play()}
        }
    }
}

//make it easy to use hex values for UIColors
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}

//make it easy for controllers to style themselves
extension UIViewController {
    func style() {
        self.view.backgroundColor = Colors.liteMedium
    }
}

extension UIViewController {
    func dismissEmbeddedController() {
        self.willMoveToParentViewController(nil)
        self.view.superview?.removeFromSuperview()  //this is the container view
        self.view.removeFromSuperview()             //this is the controller's root view
        self.removeFromParentViewController()
    }
}

//Definies the look of each tile on the Keno board
class KenoLabel: THLabel {
    override func awakeFromNib() {
        self.layer.cornerRadius = 10
        self.layer.borderWidth = 4
        self.layer.borderColor = Colors.liteLight.CGColor
    }
}
