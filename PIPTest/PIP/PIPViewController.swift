//
//  PIPViewController.swift
//  PIPTest
//
//  Created by Den Jo on 2019/12/15.
//  Copyright © 2019 Den Jo. All rights reserved.
//

import UIKit

final class PIPViewController: UIViewController {

    // MARK: - IBOutlet
    @IBOutlet private var topLeftView: UIView!
    @IBOutlet private var topRightView: UIView!
    @IBOutlet private var bottomLeft: UIView!
    @IBOutlet private var bottomRight: UIView!
    @IBOutlet private var pictureInPictureView: UIView!
    
    
    
    // MARK: - Value
    // MARK: Private
    private var state: PictureInPictureState = .idle(at: .bottomRight)
    private let spring = DampedHarmonicSpring(dampingRatio: 0.75, frequencyResponse: 0.25)
    
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setViews()
    }
    
    
    
    // MARK: - Function
    // MARK: Private
    private func setViews() {
        // Point view
        var shapeLayer: CAShapeLayer {
            let shapeLayer = CAShapeLayer()
            shapeLayer.strokeColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.8).cgColor
            shapeLayer.lineDashPattern = [7]
            shapeLayer.lineWidth       = 4.0
            shapeLayer.fillColor = nil
            shapeLayer.path = UIBezierPath(roundedRect: topLeftView.bounds, cornerRadius: 15.0).cgPath
            return shapeLayer
        }
        
        var border = shapeLayer
        border.frame = topLeftView.bounds
        topLeftView.layer.addSublayer(border)
        

        border = shapeLayer
        border.frame = topRightView.bounds
        topRightView.layer.addSublayer(border)


        border = shapeLayer
        border.frame = bottomLeft.bounds
        bottomLeft.layer.addSublayer(border)

        border = shapeLayer
        border.frame = bottomRight.bounds
        bottomRight.layer.addSublayer(border)

        // Picture in picture view
        pictureInPictureView.translatesAutoresizingMaskIntoConstraints = false
        pictureInPictureView.frame.origin = frame(for: .bottomRight).origin
        
        let gradient = CAGradientLayer()
        gradient.frame      = pictureInPictureView.bounds
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint   = CGPoint(x: 1.0, y: 1.0)
        gradient.colors     = [#colorLiteral(red: 0.95, green: 0.93, blue: 0.16, alpha: 1).cgColor, #colorLiteral(red: 0.97, green: 0.67, blue: 0.16, alpha: 1).cgColor]
              
        pictureInPictureView.layer.addSublayer(gradient)
    }
    
    private func beginInteractiveTransition(with gesture: UIPanGestureRecognizer) {
        switch self.state {
        case .idle:         break
        case .interaction:  return
            
        case .animating(to: _, using: let animator):
            animator.stopAnimation(true)
        }
        
        state = .interaction(with: gesture, from: pictureInPictureView.center)
    }
    
    private func updateInteractiveTransition(with gesture: UIPanGestureRecognizer) {
        guard case .interaction(with: gesture, from: let startPoint) = state else { return }
        
        let scale = fmax(traitCollection.displayScale, 1.0)
        let translation = gesture.translation(in: view)
        
        var center = CGPoint(x: startPoint.x + translation.x, y: startPoint.y + translation.y)
        center.x = round(center.x * scale) / scale
        center.y = round(center.y * scale) / scale
        
        pictureInPictureView.center = center
    }
    
    private func endInteractiveTransition(with gesture: UIPanGestureRecognizer) {
        guard case .interaction(with: gesture, from: _) = state else { return }
        
        let velocity      = gesture.velocity(in: view)
        let currentCenter = pictureInPictureView.center
        let endpoint      = intendedEndpoint(with: velocity, from: currentCenter)
        let targetCenter  = CGPoint(x: frame(for: endpoint).midX, y: frame(for: endpoint).midY)
        
        let parameters = spring.timingFunction(withInitialVelocity: velocity, from: &pictureInPictureView.center, to: targetCenter, context: self)
        
        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: parameters)
        animator.addAnimations({ self.pictureInPictureView.center = targetCenter })
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
        let insets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
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
