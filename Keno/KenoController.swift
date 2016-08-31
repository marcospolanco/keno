//
//  KenoController.swift
//  Keno
//
//  Created by Marcos Polanco on 8/28/16.
//  Copyright © 2016 Fanatize. All rights reserved.
//

import UIKit
import JellySlider
import SnapKit
import ZFRippleButton
import JellySlider
import THLabel

/*  Manages the interactions of a Player with the Keno machine. Enforces rules
 */
class KenoController: UIViewController {
    
    let DRAWING_INTERVAL = 0.75
    
    //The possible states of play.
    enum GameState: String {
        case NotPlaying = "Play Keno!"  //Before the user starts playing
        case Betting = "Pick Numbers!"    //While they are placing bets
        case Drawing = "Get Lucky!"     //While the machine is drawing
        case GameOver = "Game Over!"    //When the user has no more money
    }
    
    @IBOutlet weak var kenoBorder: UIView!
    @IBOutlet weak var balanceLabel: THLabel!
    @IBOutlet weak var betLabel: THLabel!
    @IBOutlet weak var playButton: ZFRippleButton!
    
    
    var betSlider = JellySlider()
    
    let keno = Keno()  //the machine
    
    //the numbers in the drawing, built (slowly) from the drawsource
    var drawing: [Int:Bool]?
    
    //the source from which the drawing is made
    var drawsource = [Int]()
    
    var state: GameState = .NotPlaying {
        didSet {
            self.playButton.setTitle(self.state.rawValue, forState: .Normal)
        }
    }
    
    var collectionController: KenoCollectionController?
    
    var player: Player {
        if let player = Player.player {return player}
        
        fatalError("KenoController started without a player, which should be impossible.")
    }
    
    var maximumBet = Float(MAXIMUM_BET)

    
    //numbers selected for betting
    var selected = [Int:Bool]()
    
    //populate the user interface
    private func updateUI() {
        
        //style the view according to palette
        self.style()
        self.kenoBorder.backgroundColor = Colors.liteLight
        
        self.balanceLabel.text = player.wallet.available().asUSD()
        
        //set the slider to max out at the balance or $50, whichever is slower
        self.maximumBet = player.wallet.available() >= MAXIMUM_BET ? Float(MAXIMUM_BET) : Float(player.wallet.available())
        
        //Since we adjusted the maximum, update the bet label accordingly by simulating the same user action
        let amount = amountFromSlider(self.betSlider.value)
        if amount > self.maximumBet {
            self.changeBet(amount)
        }
        
        //enforce rule of a minimum $1 bet. If player under that, game over
        if player.wallet.available() < 1.0 {
            self.state = .GameOver
            self.playButton.enabled = false
        }
    }
    
    private func amountFromSlider(value: CGFloat) -> Float {
        let value = Float(value)
        let minimum = Float(MINIMUM_BET)
        let maximum = self.maximumBet - minimum
        
        return value * maximum + minimum
    }
    
    private func loadSlider() {
        self.betLabel.addSubview(betSlider)
        betSlider.frame = betLabel.bounds
        betSlider.alpha = 0.05
        betSlider.snp_makeConstraints {make in
            make.edges.equalTo(betLabel).inset(UIEdgeInsetsMake(0, 0, 0, 0)).constraint
        }
        
        betSlider.trackColor = Colors.darkMedium
        betSlider.onValueChange = {[unowned self] value in
//            let value = Float(value)
//            let minimum = Float(MINIMUM_BET)
//            let maximum = self.maximumBet - minimum
            self.changeBet(self.amountFromSlider(value)) //from MINIMUM to MAXIMUM
        }
        betLabel.setNeedsLayout()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Player.player = Player(username:"", password:"")//DONOTSHIP - Here only for testing

        self.navigationController?.navigationBarHidden = true
        
        self.playButton.setTitleColor(Colors.liteLight, forState: .Normal)
        self.playButton.rippleColor = Colors.darkMedium
        self.playButton.backgroundColor = Colors.darkLight
        self.playButton.rippleOverBounds = true
        self.playButton.layer.cornerRadius = self.playButton.frame.height/2.0
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //load the slider; must wait for AutoLayout to run first
        self.loadSlider()
        
        //populate the user interface
        self.updateUI()
        
        //start the play action, but don't get in the way of iOS by placing call on the queue
        Threads.onMain{self.playAction(self)}
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    @IBAction func changeBet(value: Float) {
        if self.player.wallet.available() >= Double(value) {
            self.betLabel.text = Double(value).asUSD()
        }
    }
    
    func createBoard() {
        let random = Int(arc4random_uniform(UInt32(NUMBERS_MAX)))
        NUMBERS_COUNT = random * random //square it
    }
    
    @IBAction func playAction(sender: AnyObject){
        switch self.state {
        case .NotPlaying:
            if Player.isLoggedIn {Sounds.Start.play()}
            self.selected = Player.isLoggedIn ? [Int:Bool]() : self.keno.draw(BETTING_COUNT) //reset the values
            self.drawing = nil //reset the values
            self.collectionController?.collectionView?.reloadData() //redraw the UI
            self.state = .Betting       //change the play state
            self.playButton.enabled = false //disable the button until the drawing
        case .Betting:
            fatalError() // this should not happen, as the button should be disabled
        case .Drawing:
            if Player.isLoggedIn {Sounds.Start.play()}
            self.performSelector(#selector(startDrawing), withObject: nil, afterDelay: DRAWING_INTERVAL)
        case .GameOver:
            fatalError() //should never happen, since button is disabled when game over
        }
    }
    
    @objc private func startDrawing() {
        self.draw()
    }
    
    //cancel drawing; only called when the user
    func cancelDrawing() {
        self.state = .NotPlaying
        self.playAction(self)
    }
    
    //
    @objc private func performDrawing() {
        
        
        //if the drawing was cancelled, exit
        if self.drawing == nil {return}
        
        //add the number to the drawing
        self.drawing?[drawsource[index]] = true
        
        print(self.drawing?.keys.map{num in "\(num):"}.sort{$0 < $1}.reduce("", combine: +))

        if Player.isLoggedIn {
            self.selected[drawsource[index]] != nil ? Sounds.Hit.play() : Sounds.Miss.play()
        }
        
        //redraw the UI
        self.collectionController?.collectionView?.reloadData()
        
        //increment the index
        index += 1
        
        if index < drawsource.count {
            self.performSelector(#selector(performDrawing), withObject: nil, afterDelay: DRAWING_INTERVAL)
            self.view.setNeedsDisplay()
            
        } else if !Player.isLoggedIn {
            //support the animation while use is not logged in
            self.state = .Drawing
            self.playAction(self)
        } else {
            //the drawing is over, so celebrate
           self.performSelector(#selector(finishDrawing), withObject: nil, afterDelay: DRAWING_INTERVAL)
        }
    }
    
    @objc private func finishDrawing() {
        
        //construct the bet. Notice agressive unwrapping, since we know the values are numeric
        if let bet = self.player.wallet.bet(Double(self.betSlider.value), numbers: self.selected) {
            //emit payouts.
            let payout = self.keno.payout(bet, drawing: drawing!) //we can unwrap because we just drew
            
            //manage wallet balance
            self.player.wallet.payin(payout)
        } else {
            print("Error: We could not construct the bet.")
        }
        
        //update the user interface (wallet balance, slider, etc)
        self.updateUI()
        
        //change state back to Drawing & re-enable the button so player can play again
        self.state = .NotPlaying
        self.playButton.enabled = true

        Sounds.Cash.play()
    }
    
    var index = 0
    
    private func draw() {
        
        //clear out the drawing and perform the drawing from the keno.draw
        self.drawing = [Int:Bool]()
        self.drawsource = Array(keno.draw(DRAWING_COUNT).keys)
        print(drawsource.map{num in "\(num):"}.sort{$0 < $1}.reduce("", combine: +))
        self.index = 0
        self.playButton.enabled = false //disable the button until the drawing
        self.performDrawing()
    }
    
    func bet(number: Int) {
        
        //if we find the numbers, then the user is actually unselecting the item
        if let _ = selected[number] {
            Sounds.Undo.play()
            selected.removeValueForKey(number)
        } else {
            
            //if we had not selected it, see if we are past our limit
            guard selected.count < BETTING_COUNT else {return Sounds.Error.play()}
            
            //celebrate!
            Sounds.Bet.play()
            
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        self.collectionView?.backgroundColor = Colors.liteLight
    }
    
    //return the size of the board, which is NUMBERS_COUNT
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return NUMBERS_COUNT
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //create the cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(KenoCollectionViewCell.reuseIdentifier, forIndexPath: indexPath) as! KenoCollectionViewCell

        //establish the status of the cell
        let selected = kenoController?.selected[indexPath.row + 1] ?? false
        
        //hold whether we hit or missed the drawing. Leave it nil otherwise
        var drawn: Bool?
        
        //if we have a drawing, then was this cell in it?
        if let drawing = kenoController?.drawing where drawing[indexPath.row + 1] != nil {
            //if so, then hit if we selected the number
            drawn = selected
        }
        
        cell.load(indexPath.row + 1, selected: selected, drawn:drawn, drawing: kenoController?.drawing != nil)
        
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let kenoController = self.kenoController {
            
            //the buttons are only active if we are betting
            if kenoController.state == .Betting || kenoController.state == .Drawing {

                kenoController.bet(indexPath.row + 1)
                collectionView.reloadItemsAtIndexPaths([indexPath])//reload the looks!
            }
        }
    }
}

//Implementation of the UICollectionViewDelegateFlowLayout protocol; sizes board automatically
//as long as the size has a whole square root!
extension KenoCollectionController: UICollectionViewDelegateFlowLayout {
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        //take the square root of the NUMBERS_COUNT to figure out how many columns in the layout
        let cellWidth = collectionView.bounds.size.width / CGFloat(sqrt(Double(NUMBERS_COUNT)))
        return CGSizeMake(cellWidth, cellWidth)
        
    }
}

class KenoCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "KenoCollectionViewCell"
    
    @IBOutlet weak var label: UILabel!
    
    //states: miss / hit / select / unselect
    //load a particular number into the cell
    func load(number: Int, selected: Bool, drawn:Bool? = nil, drawing: Bool) {
        self.label.text = (number).description
        if let drawn = drawn {
            //animate green if we hit or red if we did not
            self.label.backgroundColor = drawn ? Colors.darkStrong : Colors.liteStrong
            self.label.layer.borderColor = drawn ? UIColor.greenColor().CGColor : Colors.liteStrong.CGColor
            self.label.alpha = drawn ? 1.0 : 0.4
            self.label.textColor = drawn ? .whiteColor() : .whiteColor()
        } else {
            self.label.layer.borderColor = Colors.liteLight.CGColor
            self.label.textColor = selected ?  .whiteColor() : .whiteColor()
            self.label.backgroundColor = selected ? Colors.darkLight : Colors.liteLight
            self.label.alpha = drawing ? 0.2 : 1.0
        }
    }
}