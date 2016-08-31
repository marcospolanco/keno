//
//  Wallet.swift
//  Keno
//
//  Created by Marcos Polanco on 8/28/16.
//  Copyright © 2016 Fanatize. All rights reserved.
//

//Question - concerned about losing cents due to rounding?

import Foundation

let DEFAULT_BALANCE = 500.0     //default balance in a wallet
let DRAWING_COUNT = 15          //the number of draws for Keno machine
let BETTING_COUNT = 10          //the number of bets the user must make
var NUMBERS_COUNT = 25          //the number of numbers on our board; this is just default...can vary, but 16 is minimum
let NUMBERS_MAX = 10            //sqrt of the highest number of board items
let MINIMUM_BET: Double = 1     //minimum dollar amount of a bet
let MAXIMUM_BET: Double = 50.0    //minimum dollar amount of a bet
let PAYOUT_RATE   = 0.10        //10% payout for each bet that hits draw

class Player {
    
    static var player: Player? //the currently logged in player, only one at a time!
    
    static var isLoggedIn = false
    
    let username: String    //immutable, so public
    let password: String    //immutable, so public
    let wallet = Wallet()   //immutable, so public
    
    required init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

struct Bet {
    let amount: Double
    let numbers: [Int:Bool]

}

class Wallet {
    private var balance: Double
    
    required init() {
        self.balance = DEFAULT_BALANCE
    }
    
    func available() -> Double {
        return  self.balance
    }
    
    func bet(amount: Double, numbers:[Int:Bool]) -> Bet? {
        //ensure the are 10 unique numbers in the bet
        guard numbers.count == BETTING_COUNT
            else {
                return nil
        }
        
        //ensure that the bet amount is more than minimum and less than balance
        guard amount >= MINIMUM_BET  && amount <= self.balance else {
            return nil
        }
        
        //ensure that the bet amount is less than or equal to MAXIMUM_BET
        guard amount <= MAXIMUM_BET  else {
            return nil
        }
        
        //deduct the amount from the balance
        self.balance -= amount
        
        return Bet(amount:amount, numbers:numbers)
    }
    
    func payin(amount: Double) {
        self.balance += amount
    }
}

class Keno {
    
    //return a drawing of DRAWING_COUNT unique random numbers (the keys); the dictionary values have no meaning
    func draw(maximum: Int) -> [Int:Bool] {
        var drawing = [Int:Bool]()
        
        //keep drawing numbers until we have DRAWING_COUNT
        while drawing.count < maximum {
            
            //generate a random number up to the count
            let random = Int(arc4random_uniform(UInt32(NUMBERS_COUNT))) + 1
            
            //insert it into our results; if we replace an earlier value, too bad!
            drawing[random] = true
        }
        
        return drawing
    }

    //compare the bet to the drawing and return an
    func payout(bet: Bet, drawing: [Int:Bool]) -> Double {
        var hits = 0
        
        //add up the number of hits, or coincidences between the bet and the draw
        drawing.keys.forEach{draw in if bet.numbers[draw] != nil {hits += 1}}
        
        //the payout is the bet amount times number of hits times the payout rate (10%)
        var result =  bet.amount * Double(hits) * PAYOUT_RATE
        
        //makes sure that the result is precise only to two decimal points (cents)
        result = Double(Int(result * 100))/100
        
        return result
    }
}

class Test {
    static func run() {
        let keno = Keno() //the machine
        let player = Player(username:"foo", password:"bar") //the player
        
        while true {
            
            //we will bet 10% of our money. To generate random results, we ask the machine to generate them for us
            let numbers = keno.draw(BETTING_COUNT)
            var amount = player.wallet.balance*PAYOUT_RATE
            if  amount < MINIMUM_BET {amount = 1.0}
            if let bet = player.wallet.bet(amount, numbers: numbers) {
                let payin = keno.payout(bet, drawing: keno.draw(DRAWING_COUNT)) //draw and pay out the bets, then pay into wallet
                player.wallet.payin(payin)
            } else {break} //break out if we can no longer bet
        }
    }
}
