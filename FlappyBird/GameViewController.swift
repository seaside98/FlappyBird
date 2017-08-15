//
//  GameViewController.swift
//  FlappyBird
//
//  Created by Addison Miller on 4/13/16.
//  Copyright (c) 2016 Addison Miller. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    var scene: GameScene!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure the view.
        let skView = view as! SKView
        skView.showsFPS = false
        skView.showsNodeCount = false
            
        /* Sprite Kit applies additional optimizations to improve rendering performance */
        skView.ignoresSiblingOrder = true

        scene = GameScene(size: skView.bounds.size);
        scene.scaleMode = .aspectFill

        // Present the scene
        skView.presentScene(scene)
    }

    override var prefersStatusBarHidden : Bool {
        return true
    }

    override var shouldAutorotate : Bool {
        return true
    }

    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

}
