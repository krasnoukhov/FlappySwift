//
//  GameViewController.swift
//  FlappyBird
//
//  Created by Nate Murray on 6/2/14.
//  Copyright (c) 2014 Fullstack.io. All rights reserved.
//

import UIKit
import SpriteKit
import Social
import Alamofire

extension SKNode {
    class func unarchiveFromFile(file : NSString) -> SKNode? {
        
        let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks")
        
        let sceneData = NSData(contentsOfFile: path!, options: .DataReadingMappedIfSafe, error: nil)
        let archiver = NSKeyedUnarchiver(forReadingWithData: sceneData!)
        
        archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
        let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as GameScene
        archiver.finishDecoding()
        return scene
    }
}

class GameViewController: UIViewController {
    let API_KEY = "8AjFOOZOm1ZTK624FvS"

    override func viewDidLoad() {
        super.viewDidLoad()

        if let scene = GameScene.unarchiveFromFile("GameScene") as? GameScene {
            // Configure the view.
            let skView = self.view as SKView
            // skView.showsFPS = true
            // skView.showsNodeCount = true
            
            /* Sprite Kit applies additional optimizations to improve rendering performance */
            skView.ignoresSiblingOrder = true
            
            /* Set the scale mode to scale to fit the window */
            scene.scaleMode = .AspectFill

            scene.controller = self
            skView.presentScene(scene)
        }

        self.initOpen()
    }

    override func shouldAutorotate() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    func initOpen() {
      Alamofire.request(.POST, "https://www.talkable.com/api/v2/origins", parameters: [
        "api_key": self.API_KEY,
        "site_slug": "krasnoukhov",
        "type": "Event",
        "data": [
          "email": UIDevice.currentDevice().identifierForVendor.UUIDString + "@uuid.com",
          "event_category": "app-open",
          "event_number": UIDevice.currentDevice().identifierForVendor.UUIDString,
          "campaign_tags": "ios"
        ]
      ])
    }

    func initShare() {
      Alamofire.request(.POST, "https://www.talkable.com/api/v2/origins", parameters: [
        "api_key": self.API_KEY,
        "site_slug": "krasnoukhov",
        "type": "Event",
        "data": [
          "email": UIDevice.currentDevice().identifierForVendor.UUIDString + "@uuid.com",
          "event_category": "app-share",
          "event_number": UIDevice.currentDevice().identifierForVendor.UUIDString,
          "campaign_tags": "ios"
        ]
      ]).responseJSON { (_, _, JSON, _) in
        if let object = JSON as? NSDictionary {
          self.showShare(object.valueForKey("result")!.valueForKey("offer")! as NSDictionary)
        }
      }
    }

    func showShare(offer: NSDictionary) {
      let shortCode = offer.valueForKey("short_url_code")! as NSString
      let claimUrl = offer.valueForKey("claim_url")! as NSString
      let tweetSheet = SLComposeViewController(forServiceType: SLServiceTypeTwitter)

      tweetSheet.completionHandler = {
        result in
        switch result {
        case SLComposeViewControllerResult.Cancelled:
          break

        case SLComposeViewControllerResult.Done:
          Alamofire.request(.POST, "https://www.talkable.com/api/v2/offers/"+shortCode+"/shares", parameters: [
            "api_key": self.API_KEY,
            "site_slug": "krasnoukhov",
            "channel": "twitter",
          ])
          break
        }
      }

      tweetSheet.setInitialText("Share me! " + claimUrl)
      self.presentViewController(tweetSheet, animated: false, completion: {})
    }
}
