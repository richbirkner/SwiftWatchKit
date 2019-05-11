//
//  ViewController.swift
//  WatchKitApplication
//
//  Created by Richard Birkner on 07.05.19.
//  Copyright © 2019 Richard Birkner. All rights reserved.
//

import UIKit
import WatchConnectivity

class ViewController: UIViewController, WCSessionDelegate {
    
    @IBAction func showItems(_ sender: Any) {
        let item = ["name": "Richard", "surname": "Birkner"]
        wcSession.sendMessage(item, replyHandler: nil, errorHandler: {error in print(error.localizedDescription)})
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    
    var wcSession: WCSession!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //Creating the connection
        wcSession = WCSession.default
        wcSession.delegate = self
        wcSession.activate()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

