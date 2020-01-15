//
//  PlayerViewController.swift
//  PIPTest
//
//  Created by Den Jo on 2020/01/15.
//  Copyright © 2020 Den Jo. All rights reserved.
//

import UIKit

final class PlayerViewController: UIViewController {

    // MARK: - Value
    // MARK: Private
    private lazy var gradient: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.frame      = view.bounds
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint   = CGPoint(x: 1.0, y: 1.0)
        gradient.colors     = [#colorLiteral(red: 0.95, green: 0.93, blue: 0.16, alpha: 1).cgColor, #colorLiteral(red: 0.97, green: 0.4724496278, blue: 0.16, alpha: 1).cgColor]
        
        view.layer.insertSublayer(gradient, at: 0)
        return gradient
    }()
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        gradient.bounds = view.bounds
        print(view.bounds)
    }
}
