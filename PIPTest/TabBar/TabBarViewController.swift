//
//  TabBarViewController.swift
//  PIPTest
//
//  Created by Den Jo on 2020/01/15.
//  Copyright © 2020 Den Jo. All rights reserved.
//

import UIKit

final class TabBarViewController: UITabBarController {

    // MARK: - IBOutlet
    @IBOutlet private var panGestureRecognizer: UIPanGestureRecognizer!
    
    
    
    // MARK: - Value
    // MARK: Private
    private var state: PictureInPictureState = .idle(at: .bottomRight)
    private let spring = DampedHarmonicSpring(dampingRatio: 0.75, frequencyResponse: 0.25)
    
    private lazy var playerContainerView: UIView = {
        guard let playerViewController = UIStoryboard(name: "Player", bundle: nil).instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController else { return UIView() }
        playerViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        let containerView = UIView()
        containerView.layer.cornerRadius = 15.0
        containerView.clipsToBounds      = true
        view.addSubview(containerView)
        
        containerView.addSubview(playerViewController.view)
        
        playerViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive   = true
        playerViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        playerViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor).isActive           = true
        playerViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive     = true
        
//        addChild(playerViewController)
//        playerViewController.didMove(toParent: self)
        return containerView
    }()
    
    
     
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playerContainerView.frame = frame(for: .bottomRight)
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerContainerView.frame = frame(for: .bottomRight)
    }
    
        
    // MARK: - Function
    // MARK: Private
    private func beginInteractiveTransition(with gesture: UIPanGestureRecognizer) {
        switch self.state {
        case .idle:         break
        case .interaction:  return
            
        case .animating(to: _, using: let animator):
            animator.stopAnimation(true)
        }
        
        state = .interaction(with: gesture, from: playerContainerView.center)
    }
    
    private func updateInteractiveTransition(with gesture: UIPanGestureRecognizer) {
        guard case .interaction(with: gesture, from: let startPoint) = state else { return }
        
        let scale = fmax(traitCollection.displayScale, 1.0)
        let translation = gesture.translation(in: view)
        
        var center = CGPoint(x: startPoint.x + translation.x, y: startPoint.y + translation.y)
        center.x = round(center.x * scale) / scale
        center.y = round(center.y * scale) / scale
        
        playerContainerView.center = center
    }
    
    private func endInteractiveTransition(with gesture: UIPanGestureRecognizer) {
        guard case .interaction(with: gesture, from: _) = state else { return }
        
        let velocity      = gesture.velocity(in: view)
        let currentCenter = playerContainerView.center
        let endpoint      = intendedEndpoint(with: velocity, from: currentCenter)
        let targetCenter  = CGPoint(x: frame(for: endpoint).midX, y: frame(for: endpoint).midY)
        
        let parameters = spring.timingFunction(withInitialVelocity: velocity, from: &playerContainerView.center, to: targetCenter, context: self)
        
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: parameters)
        animator.addAnimations({ self.playerContainerView.center = targetCenter })
        animator.addCompletion({ position in self.state = .idle(at: endpoint) })
        
        state = .animating(to: endpoint, using: animator)
        animator.startAnimation()
    }
    
    private func intendedEndpoint(with velocity: CGPoint, from currentPosition: CGPoint) -> PictureInPicturePoint {
        var velocity = velocity
        
        // Reduce movement along the secondary axis of the gesture.
        if velocity.x != 0 || velocity.y != 0 {
            let velocityInPrimaryDirection = fmax(abs(velocity.x), abs(velocity.y))
            
            velocity.x *= abs(velocity.x / velocityInPrimaryDirection)
            velocity.y *= abs(velocity.y / velocityInPrimaryDirection)
        }
        
        let factor            = -1.0 / (1000.0 * log(UIScrollView.DecelerationRate.normal.rawValue))
        let projectedPosition = CGPoint(x: currentPosition.x + factor * velocity.x, y: currentPosition.y + factor * velocity.y)
        
        let sorted = PictureInPicturePoint.allCases.map { ($0, projectedPosition.distance(to: CGPoint(x: frame(for: $0).midX, y: frame(for: $0).midY))) }.sorted { $0.1 < $1.1 }
        return sorted.first?.0 ?? .bottomRight
    }
    
    private func frame(for point: PictureInPicturePoint) -> CGRect {
        let insets = UIEdgeInsets(top: 64.0, left: 20.0, bottom: 83.0, right: 20.0)
        let rect = view.safeAreaLayoutGuide.layoutFrame.inset(by: insets)
        let size = CGSize(width: 150.0, height: 100.0)
        
        switch point {
        case .topLeft:      return CGRect(x: rect.minX, y: rect.minY, width: size.width, height: size.height).standardized
        case .topRight:     return CGRect(x: rect.maxX, y: rect.minY, width: -size.width, height: size.height).standardized
        case .bottomLeft:   return CGRect(x: rect.minX, y: rect.maxY, width: size.width, height: -size.height).standardized
        case .bottomRight:  return CGRect(x: rect.maxX, y: rect.maxY, width: -size.width, height: -size.height).standardized
        }
    }

    
    
    // MARK: - Event
    @IBAction private func panGestureRegcognizerAction(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:                beginInteractiveTransition(with: sender)
        case .changed:              updateInteractiveTransition(with: sender)
        case .ended, .cancelled:    endInteractiveTransition(with: sender)
        default:                    break
        }
    }
}
