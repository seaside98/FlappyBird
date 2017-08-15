//
//  GameScene.swift
//  FlappyBird
//
//  Created by Addison Miller on 4/13/16.
//  Copyright (c) 2016 Addison Miller. All rights reserved.
//

import SpriteKit


// Configuration variables
let kSpeed: Double = 0.005
let kScale: CGFloat = 2.9
var kVerticalPipeGap: CGFloat = 53
let kPipeSpawnTime: TimeInterval = 1.6
let kGravity: CGFloat = 9.8
let kImpulse: CGFloat = 7.65


class GameScene: SKScene, SKPhysicsContactDelegate {

    let birdCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3

    var Bird: SKSpriteNode!
    var SkyColor: SKColor!
    var pipeTexture1: SKTexture!
    var pipeTexture2: SKTexture!
    var movePipesAndRemove: SKAction!
    var moving: SKNode!
    var pipes: SKNode!
    var canRestart = true;
    var hasStarted = false;
    var scoreLabelNode: SKLabelNode!
    var startLabelNode: SKLabelNode!
    var highscoreLabelNode: SKLabelNode!
    var newHighscoreLabelNode: SKLabelNode!
    var score = 0
    var highScore: Int = 0

    override init(size: CGSize) {
        super.init(size: size)

        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -kGravity)
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.speed = 0

        // Create the sky

        SkyColor = SKColor(red: 113/255, green: 197/255, blue: 207/255, alpha: 1.0)
        scene?.backgroundColor = SkyColor

        moving = SKNode()
        addChild(moving)

        pipes = SKNode()
        moving.addChild(pipes)

        pipes.speed = 0


        // Create the ground

        let groundTexture = SKTexture(imageNamed: "Ground")
        groundTexture.filteringMode = .nearest

        // Animate the ground

        let groundSize = groundTexture.size()
        let groundWidth = groundSize.width * kScale
        let groundHeight = groundSize.height * kScale

        let moveGroundSprite = SKAction.moveBy(x: -groundWidth, y: 0, duration: kSpeed * Double(groundWidth))
        let resetGroundSprite = SKAction.moveBy(x: groundWidth, y: 0, duration: 0)
        let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroundSprite, resetGroundSprite]))

        for i in 0..<Int(2 + self.frame.size.width / groundWidth) {
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(kScale)
            sprite.anchorPoint = CGPoint(x: 0, y: 0)
            sprite.position = CGPoint(x: CGFloat(i) * sprite.size.width, y: -sprite.size.height / 4)
            sprite.run(moveGroundSpritesForever)
            moving.addChild(sprite)
        }

        // Create ground physics container

        let dummy = SKNode()
        dummy.position = CGPoint(x: self.frame.size.width / 2, y: -groundHeight / 4 + groundHeight / 2)
        dummy.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: groundHeight))
        dummy.physicsBody?.isDynamic = false
        dummy.physicsBody?.categoryBitMask = worldCategory
        addChild(dummy)

        // Top container

        let top = SKNode()
        top.position = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height)
        top.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: 1))
        top.physicsBody?.isDynamic = false
        top.physicsBody?.categoryBitMask = worldCategory
        addChild(top)


        // Create skyline

        let skylineTexture = SKTexture(imageNamed: "Skyline")
        skylineTexture.filteringMode = .nearest

        // Animate the skyline

        let skylineSize = skylineTexture.size()
        let skylineWidth = skylineSize.width * kScale

        let moveSkylineSprite = SKAction.moveBy(x: -skylineWidth, y: 0, duration: kSpeed * 3 * Double(skylineWidth))
        let resetSkylineSprite = SKAction.moveBy(x: skylineWidth, y: 0, duration: 0)
        let moveSkylineSpritesForever = SKAction.repeatForever(SKAction.sequence([moveSkylineSprite, resetSkylineSprite]))

        for i in 0..<Int(3 + self.frame.size.width / skylineWidth) {
            let sprite = SKSpriteNode(texture: skylineTexture)
            sprite.setScale(kScale)
            sprite.position = CGPoint(x: CGFloat(i) * sprite.size.width, y: groundHeight * 3 / 4)
            sprite.anchorPoint = CGPoint(x: 0, y: 0)
            sprite.zPosition = -2
            sprite.run(moveSkylineSpritesForever)
            moving.addChild(sprite)
        }


        // Create the pipes

        pipeTexture1 = SKTexture(imageNamed: "Pipe1")
        pipeTexture1.filteringMode = .nearest
        pipeTexture2 = SKTexture(imageNamed: "Pipe2")
        pipeTexture2.filteringMode = .nearest

        let distanceToMove = self.frame.size.width + kScale * pipeTexture1.size().width
        let movePipes = SKAction.moveBy(x: -distanceToMove, y: 0, duration: kSpeed * Double(distanceToMove))
        let removePipes = SKAction.removeFromParent()
        movePipesAndRemove = SKAction.sequence([movePipes, removePipes])

        let spawn = SKAction.perform(#selector(spawnPipes), onTarget: self)
        let delay = SKAction.wait(forDuration: kPipeSpawnTime)
        let spawnThenDelay = SKAction.sequence([spawn, delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        run(spawnThenDelayForever)


        /* Setup your scene here */
        let birdTexture1 = SKTexture(imageNamed: "Bird1")
        birdTexture1.filteringMode = .nearest
        let birdTexture2 = SKTexture(imageNamed: "Bird2")
        birdTexture2.filteringMode = .nearest

        // Animates the bird
        let flap = SKAction.repeatForever(SKAction.animate(with: [birdTexture1, birdTexture2], timePerFrame: 0.2))

        Bird = SKSpriteNode(texture: birdTexture1)
        Bird.setScale(kScale)
        Bird.position = CGPoint(x: self.frame.size.width / 4, y: self.frame.midY)
        Bird.zPosition = 1.0
        Bird.run(flap)

        // Add physics to the bird

        Bird.physicsBody = SKPhysicsBody(circleOfRadius: Bird.size.height / 2)
        Bird.physicsBody?.isDynamic = true
        Bird.physicsBody?.allowsRotation = false

        Bird.physicsBody?.categoryBitMask = birdCategory
        Bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        Bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory

        addChild(Bird)

        // Initialize label and create a label which holds the score
        score = 0
        scoreLabelNode = makeDropShadowString("\(score)")
        scoreLabelNode.position = CGPoint(x: self.frame.midX, y: 4 * self.frame.size.height / 5)
        scoreLabelNode.isHidden = true
        self.addChild(scoreLabelNode)

        // Tap to start
        startLabelNode = makeDropShadowString("Tap to start!")
        startLabelNode.position = CGPoint(x: self.frame.midX, y: 0.66 * self.frame.size.height)
        self.addChild(startLabelNode)

        let userDefaults = UserDefaults.standard
        if let high = userDefaults.value(forKey: "highscore") {
            self.highScore = Int(String(describing: high))!
            print(high)
        }

        newHighscoreLabelNode = makeDropShadowString("New Highscore!", fontSize: 28)
        newHighscoreLabelNode.position = CGPoint(x: self.frame.midX, y: 5 * self.frame.size.height / 7)
        newHighscoreLabelNode.isHidden = true
        self.addChild(newHighscoreLabelNode)

        highscoreLabelNode = makeDropShadowString("Highscore: \(self.highScore)", fontSize: 21)
        highscoreLabelNode.position = CGPoint(x: self.frame.midX, y: 0.6 * self.frame.size.height)
        self.addChild(highscoreLabelNode)
    }

    @objc func spawnPipes() {
        if pipes.speed > 0 {
            let pipePair = SKNode()
            pipePair.position = CGPoint(x: self.frame.size.width + pipeTexture1.size().width * 1.5, y: 0)
            pipePair.zPosition = -1

            let y = CGFloat(arc4random() % UInt32(self.frame.size.height / 3))

            let pipe1 = SKSpriteNode(texture: pipeTexture1)
            pipe1.setScale(kScale)
            pipe1.position = CGPoint(x: 0, y: y)
            pipe1.physicsBody = SKPhysicsBody(rectangleOf: pipe1.size)
            pipe1.physicsBody?.isDynamic = false
            pipe1.physicsBody?.categoryBitMask = pipeCategory
            pipe1.physicsBody?.contactTestBitMask = birdCategory
            pipePair.addChild(pipe1)

            let pipe2 = SKSpriteNode(texture: pipeTexture2)
            pipe2.setScale(kScale)
            pipe2.position = CGPoint(x: 0, y: y + pipe1.size.height + kVerticalPipeGap * kScale)
            pipe2.physicsBody = SKPhysicsBody(rectangleOf: pipe2.size)
            pipe2.physicsBody?.isDynamic = false
            pipe2.physicsBody?.categoryBitMask = pipeCategory
            pipe2.physicsBody?.contactTestBitMask = birdCategory
            pipePair.addChild(pipe2)

            let contactNode = SKNode()
            contactNode.position = CGPoint(x: pipe1.size.width / 2, y: self.frame.midY)
            contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pipe1.size.width, height: self.frame.size.height))
            contactNode.physicsBody?.isDynamic = false
            contactNode.physicsBody?.categoryBitMask = scoreCategory
            contactNode.physicsBody?.contactTestBitMask = birdCategory
            pipePair.addChild(contactNode)

            pipePair.run(movePipesAndRemove)

            pipes.addChild(pipePair)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        /* Called when a touch begins */
        if !hasStarted {
            // Start the game
            hasStarted = true
            canRestart = false
            self.physicsWorld.speed = 1
            scoreLabelNode.isHidden = false
            startLabelNode.isHidden = true
            pipes.removeAllChildren()
            pipes.speed = 1
            highscoreLabelNode.isHidden = true
        }

        if moving.speed > 0 {
            Bird.speed = 1
            Bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            Bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: kImpulse * kScale))
        } else if self.canRestart {
            self.resetScene()
        }
    }

    func clamp(_ lower: CGFloat, upper: CGFloat, value: CGFloat) -> CGFloat {
        return min(max(value, lower), upper)
    }

    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        if moving.speed > 0 {
            Bird.zRotation = clamp(-1, upper: 0.5, value: (Bird.physicsBody!.velocity.dy) * (Bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001))
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        if moving.speed > 0 {
            if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
                // Bird has contact with score entity
                score += 1
                scoreLabelNode.removeFromParent()
                scoreLabelNode = makeDropShadowString("\(score)")
                scoreLabelNode.position = CGPoint(x: self.frame.midX, y: 4 * self.frame.size.height / 5)
                scoreLabelNode.zPosition = 100
                self.addChild(scoreLabelNode)

                // Visual feedback
                scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration: 0.1), SKAction.scale(to: 1, duration: 0.1)]))

            } else {
                // Bird has collided with world
                moving.speed = 0

                Bird.physicsBody?.collisionBitMask = worldCategory

                let rotateAction = SKAction.sequence([
                    SKAction.rotate(byAngle: CGFloat(M_PI) * Bird.position.y * 0.01, duration: Double(Bird.position.y) * 0.003),
                    SKAction.run() {
                        self.Bird.speed = 0
                    }])

                Bird.run(rotateAction, withKey: "rotate")

                let flash = SKSpriteNode(color: UIColor.white, size: self.frame.size)
                flash.anchorPoint = CGPoint(x: 0, y: 0)
                flash.zPosition = 1000
                self.addChild(flash)

                if self.score > self.highScore {
                    self.newHighscoreLabelNode.isHidden = false

                    self.newHighscoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration: 0.1), SKAction.scale(to: 1, duration: 0.1)]))

                    self.highScore = self.score
                }

                flash.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.run() {
                        flash.removeFromParent()
                        self.canRestart = true;

                        // Save highscore
                        if self.score == self.highScore {
                            let userDefaults = UserDefaults.standard
                            userDefaults.setValue(self.score, forKey: "highscore")
                            userDefaults.synchronize()
                        }
                    }]))
            }
        }
    }

    func resetScene() {
        // Move bird to the original position and reset velocity
        Bird.position = CGPoint(x: self.frame.size.width / 4, y: self.frame.midY)
        Bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        Bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        Bird.speed = 1
        Bird.removeAction(forKey: "rotate")
        Bird.zRotation = 0

        // Stop the pipes
        pipes.removeAllChildren()
        pipes.speed = 0

        // Reset canResart
        canRestart = false;

        physicsWorld.speed = 0

        hasStarted = false

        // Restart animation
        moving.speed = 1

        score = 0
        scoreLabelNode.removeFromParent()
        scoreLabelNode = makeDropShadowString("\(score)")
        scoreLabelNode.position = CGPoint(x: self.frame.midX, y: 4 * self.frame.size.height / 5)
        scoreLabelNode.zPosition = 100
        scoreLabelNode.isHidden = true
        startLabelNode.isHidden = false
        newHighscoreLabelNode.isHidden = true

        self.addChild(scoreLabelNode)

        let pos = highscoreLabelNode.position
        highscoreLabelNode.removeFromParent()
        highscoreLabelNode = makeDropShadowString("Highscore: \(self.highScore)", fontSize: 21)
        highscoreLabelNode.position = pos
        self.addChild(highscoreLabelNode)
    }

    func makeDropShadowString(_ string: String, fontSize: CGFloat = 0) -> SKLabelNode {
        let offSetX: CGFloat = 0
        let offSetY: CGFloat = 3
        let blur: CGFloat = 0

        let completedString = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        completedString.fontColor = SKColor.white
        if fontSize > 0 {
            completedString.fontSize = fontSize
        } else {
            completedString.fontSize = completedString.fontSize + 5
        }
        completedString.text = string
        completedString.zPosition = 100

        let effectNode = SKEffectNode()
        effectNode.shouldEnableEffects = true
        effectNode.zPosition = -1

        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setDefaults()
        filter?.setValue(blur, forKey: "inputRadius")
        effectNode.filter = filter

        let dropShadow = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        dropShadow.fontColor = SKColor(hue: 0, saturation: 0, brightness: 0, alpha: 0.4)
        dropShadow.text = string
        dropShadow.fontSize = completedString.fontSize
        dropShadow.zPosition = completedString.zPosition - 1
        dropShadow.position = CGPoint(x: blur - offSetX, y: -blur - offSetY)

        effectNode.addChild(dropShadow)
        completedString.addChild(effectNode)

        return completedString
    }

}











