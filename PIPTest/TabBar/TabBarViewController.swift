//
//  TabBarViewController.swift
//  PIPTest
//
//  Created by Den Jo on 2020/01/15.
//  Copyright © 2020 Den Jo. All rights reserved.
//

import UIKit

final class TabBarViewController: UITabBarController {

    // MARK: - Value
    // MARK: Private
    
    
    private lazy var playerContainerView: UIView = {
        guard let playerViewController = UIStoryboard(name: "Player", bundle: nil).instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController else { return UIView() }
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(playerViewController)
        
        let containerView = UIView()
//        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.frame.size = CGSize(width: 150, height: 100.0)
        containerView.layer.cornerRadius = 15.0
        containerView.clipsToBounds = true
        view.addSubview(containerView)
        
        
//        containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive   = true
//        containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//        containerView.topAnchor.constraint(equalTo: view.topAnchor).isActive           = true
//        containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive     = true
        
        containerView.addSubview(playerViewController.view)
        
        playerViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive   = true
        playerViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        playerViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor).isActive           = true
        playerViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive     = true
        
        
        
        playerViewController.didMove(toParent: self)
        return containerView
    }()
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
     
        
        playerContainerView.frame.origin = CGPoint(x: 10, y: 10)
        
    }
    

    
}
