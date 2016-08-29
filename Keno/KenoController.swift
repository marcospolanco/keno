//
//  KenoController.swift
//  Keno
//
//  Created by Marcos Polanco on 8/28/16.
//  Copyright © 2016 Fanatize. All rights reserved.
//

import UIKit

/*  Manages the interactions of a Player with the Keno machine. Enforces rules
 */
class KenoController: UIViewController {
    
    enum GameState: String {
        case NotPlaying = "Play Keno!"
        case Betting = "Place Bets!"
        case Drawing = "Get Lucky!"
        case GameOver = "Game Over!"
    }
    
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var betLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var betSlider: UISlider!
    
    let player = Player(username:"foo", password:"bar") //the man
    let keno = Keno()  //the machine
    var drawing: [Int:Bool]?
    
    var state: GameState = .NotPlaying {
        didSet {
            self.playButton.setTitle(self.state.rawValue, forState: .Normal)
        }
    }
    var collectionController: KenoCollectionController?
    
    //numbers selected for betting
    var selected = [Int:Bool]()
    
    //populate the user interface
    private func updateUI() {
        self.balanceLabel.text = "\(player.wallet.available())" //FIX - add dollar signs and two decimal places
        
        //set the slider to max out at the balance or $50, whichever is slower
        self.betSlider.maximumValue = player.wallet.available() > MAXIMUM_BET ? Float(MAXIMUM_BET) : Float(player.wallet.available())
        
        //Since we adjusted the maximum, update the bet label accordingly by simulating the same user action. BUGGY - FIX
        self.changeBet(self.betSlider)
        
        //enforce rule of a minimum $1 bet. If player under that, game over
        if player.wallet.available() < 1.0 {
            self.state = .GameOver
            self.playButton.enabled = false
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //populate the user interface
        self.updateUI()
    }
    
    

    @IBAction func changeBet(sender: UISlider) {
        if self.player.wallet.available() >= Double(sender.value) {
            self.betLabel.text = sender.value.description
        }
    }
    
    @IBAction func playAction(sender: AnyObject){
        switch self.state {
        case .NotPlaying:
            self.selected = self.keno.draw(BETTING_COUNT - 1)//[Int:Bool]() //reset the values
            self.drawing = nil //reset the values
            self.collectionController?.collectionView?.reloadData() //redraw the UI
            self.state = .Betting       //change the play state
            self.playButton.enabled = false //disable the button until the drawing
        case .Betting:
            fatalError() // this should not happen, as the button should be disabled
        case .Drawing:
            self.draw()
        case .GameOver:
            fatalError() //should never happen, since button is disabled when game over
        }
    }
    
    private func draw() {
        
        //draw numbers
        self.drawing = keno.draw(DRAWING_COUNT)
        
        //redraw the board to show winning combinations
        collectionController?.collectionView?.reloadData()
    
        //construct the bet. Notice agressive unwrapping, since we know the values are numeric
        if let bet = self.player.wallet.bet(Double(self.betLabel.text!)!, numbers: self.selected) {
            //emit payouts.
            let payout = self.keno.payout(bet, drawing: drawing!) //we can unwrap because we just drew
            
            //manage wallet balance
            self.player.wallet.payin(payout)
        } else {
            print("Error: We could not construct the bet.")
        }
        
        //change state back to Drawing & re-enable the button so player can play again
        self.state = .NotPlaying
        self.playButton.enabled = true
        
        //update the user interface (wallet balance, slider, etc)
        self.updateUI()
    }
    
    func bet(number: Int) {
        
        //if we find the numbers, then the user is actually unselecting the item
        if let _ = selected[number] {
            selected.removeValueForKey(number)
        } else {
            
            //if we had not selected it, see if we are past our limit
            guard selected.count < BETTING_COUNT else {return}
            
            //ok, then we can select it
            selected[number] = true
        }
        
        //while betting, enable the button only once we have an exact match here
        self.playButton.enabled = selected.count == BETTING_COUNT
        self.state = selected.count == BETTING_COUNT ? .Drawing : .Betting
    }
 
    override func addChildViewController(childController: UIViewController) {
        super.addChildViewController(childController)
        if let controller = childController as? KenoCollectionController {
            self.collectionController = controller
        }
    }
}

class KenoCollectionController: UICollectionViewController {
    
    //reference back to the parent controller
    var kenoController: KenoController? {
        return self.parentViewController as? KenoController
    }
    
    //return the size of the board, which is NUMBERS_COUNT
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return NUMBERS_COUNT
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //create the cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(KenoCollectionViewCell.reuseIdentifier, forIndexPath: indexPath) as! KenoCollectionViewCell

        //establish the status of the cell
        let selected = kenoController?.selected[indexPath.row] ?? false
        
        //hold whether we hit or missed the drawing. Leave it nil otherwise
        var drawn: Bool?
        
        //if we have a drawing, then was this cell in it?
        if let drawing = kenoController?.drawing where drawing[indexPath.row] != nil {
            //if so, then hit if we selected the number
            drawn = selected
        }
        
        cell.load(indexPath.row, selected: selected, drawn:drawn)
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let kenoController = self.kenoController {
            
            //the buttons are only active if we are betting
            if kenoController.state == .Betting || kenoController.state == .Drawing {
                kenoController.bet(indexPath.row)
                collectionView.reloadItemsAtIndexPaths([indexPath])//reload the looks!
            }
        }
    }
}

extension KenoCollectionController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        //take the square root of the NUMBERS_COUNT to figure out how many columns in the layout
        let cellWidth = UIScreen.mainScreen().bounds.size.width / CGFloat(sqrt(Double(NUMBERS_COUNT)))
        return CGSizeMake(cellWidth, cellWidth)
        
    }
}

class KenoCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "KenoCollectionViewCell"
    
    @IBOutlet weak var label: UILabel!
    
    //states: miss / hit / select / unselect
    //load a particular number into the cell
    func load(number: Int, selected: Bool, drawn:Bool? = nil) {
        self.label.text = (number + 1).description
        if let drawn = drawn {
            //animate green if we hit or red if we did not
            UIView.animateWithDuration(2.0) {
                self.label.backgroundColor = drawn ? .greenColor() : .redColor()
            }
        } else {
            self.label.textColor = selected ? .yellowColor() : .blackColor()
            self.label.backgroundColor = selected ? .blueColor() : .darkGrayColor()
        }
    }
}