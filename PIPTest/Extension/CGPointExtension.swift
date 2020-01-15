//
//  CGPointExtension.swift
//  PIPTest
//
//  Created by Den Jo on 2019/12/16.
//  Copyright © 2019 Den Jo. All rights reserved.
//

import UIKit

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow((point.x - x), 2.0) + pow((point.y - y), 2.0))
    }
}
