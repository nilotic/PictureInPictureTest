//
//  ViewController.swift
//  PIPTest
//
//  Created by Den Jo on 2019/12/15.
//  Copyright © 2019 Den Jo. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {

    
    private var state: State = .idle(at: .bottomRight)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    
    // MARK: - Function
    // MARK: Private
    func beginInteractiveTransition(with gesture: UIPanGestureRecognizer) {
           switch self.state {
           case .idle:                  break
           case .interaction:           return
           case .animating(to: _, using: let animator):
               animator.stopAnimation(true)
           }

           let startPoint = self.pictureInPictureView.center

           self.state = .interaction(with: gesture, from: startPoint)
       }
    
    
    
    
    // MARK: - Event
    
    
    @IBAction private func panGestureRegcognizerAction(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:                beginInteractiveTransition(with: sender)
            //        case .changed:              updateInteractiveTransition(with: sender)
        //        case .ended, .cancelled:    endInteractiveTransition(with: sender)
        default:                    break
        }
    }
}


// MARK: - UIGestureRecognizer Delegate
extension ViewController: UIGestureRecognizerDelegate {
    
    
    
}
