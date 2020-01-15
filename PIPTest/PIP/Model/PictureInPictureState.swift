//
//  PictureInPictureState.swift
//  PIPTest
//
//  Created by Den Jo on 2019/12/15.
//  Copyright © 2019 Den Jo. All rights reserved.
//

import UIKit

enum PictureInPictureState {
    case idle(at: PictureInPicturePoint)
    case interaction(with: UIPanGestureRecognizer, from: CGPoint)
    case animating(to: PictureInPicturePoint, using: UIViewPropertyAnimator)
}
