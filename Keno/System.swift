//
//  System.swift
//  Keno
//
//  Created by Marcos Polanco on 8/29/16.
//  Copyright © 2016 Fanatize. All rights reserved.
//

import Foundation

//simple method to execute a block on the main thread
extension NSOperationQueue {
    static func onMain(block: () -> Void) {
        NSOperationQueue.mainQueue().addOperation(NSBlockOperation(block: block))
    }
    
    static func onBack(block: () -> Void) {
        let queue = NSOperationQueue()
        queue.addOperationWithBlock(block)
    }
}

//alias to make code more readable
typealias Threads = NSOperationQueue

//display doubles as US dollars and centers
extension Double {
    private func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
    
    func asUSD() -> String {
        return "$\(self.format(".2"))"
    }
}
