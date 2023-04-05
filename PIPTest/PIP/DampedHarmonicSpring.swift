import UIKit

/// A type modeling a damped harmonic spring in the real world, offering a more design-friendly interface and additional functionality than UIKit does out of  the box.
struct DampedHarmonicSpring {

    // MARK: - Value
    // MARK: Public
    /// The mass `m` attached to the spring, measured in kilograms.
    var mass: CGFloat

    /// The spring constant `k`, measured in kilograms per second squared.
    var stiffness: CGFloat

    /// The viscous damping coefficient `c`, measured in kilograms per second.
    var dampingCoefficient: CGFloat

    /// The unitless damping ratio `ζ`, i.e. the ratio of the actual damping coefficient to the critical damping coeffcient.
    var dampingRatio: CGFloat {
        return dampingCoefficient / (2 * sqrt(stiffness * mass))
    }
    
    /// The duration of one period in the undamped system, measured in seconds.
    var frequencyResponse: CGFloat {
        return 2 * .pi / undampedNaturalFrequency
    }

    
    // MARK: Private
    /// The undamped natural frequency `ω_0`, measured in radians per second.
    private var undampedNaturalFrequency: CGFloat {
        return sqrt(stiffness / mass)
    }
    
    /// The damped natural frequency `ω_r`, measured in radians per second.
    private var dampedNaturalFrequency: CGFloat {
        return undampedNaturalFrequency * sqrt(abs(1 - pow(dampingRatio, 2)))
    }
    

    
    // MARK: - Initializter
    /// Creates a damped harmonic spring using the specified underlying physical parameters.
    ///
    /// - parameter mass: The mass `m` attached to the spring, measured in kilograms.
    /// - parameter stiffness: The spring constant `k`, measured in kilograms per second squared.
    /// - parameter dampingCoefficient: The viscous damping coefficient `c`, measured in kilograms per second.
    init(mass: CGFloat, stiffness: CGFloat, dampingCoefficient: CGFloat) {
        precondition(mass > 0)
        precondition(stiffness > 0)
        precondition(dampingCoefficient >= 0)

        self.mass = mass
        self.stiffness = stiffness
        self.dampingCoefficient = dampingCoefficient
    }

    /// Creates a damped harmonic spring using the specified design-friendly parameters.
    ///
    /// - parameter dampingRatio: The ratio of the actual damping coefficient to the critical damping coeffcient.
    /// - parameter frequencyResponse: The duration of one period in the undamped system, measured in seconds.
    ///
    /// See https://developer.apple.com/videos/play/wwdc2018/803/ at 33:46.
    init(dampingRatio: CGFloat, frequencyResponse: CGFloat) {
        precondition(dampingRatio >= 0)
        precondition(frequencyResponse > 0)
        
        mass               = 1
        stiffness          = pow(2 * .pi / frequencyResponse, 2) * mass
        dampingCoefficient = 4 * .pi * dampingRatio * mass / frequencyResponse
    }
    
    

    // MARK: - Evaluation
    /// Calculates the spring's displacement from equilibrium at the specified time.
    ///
    /// - parameter time: The time after which the displacement from equilibrium is to be computed, measured in seconds.
    /// - parameter initialPosition: The spring's displacement from equilibrium at `t = 0`.
    /// - parameter initialVelocity: The spring's velocity at `t = 0`, measured per second.
    func position(at time: TimeInterval, initialPosition: CGFloat = 1, initialVelocity: CGFloat = 0) -> CGFloat {
        let ζ   = dampingRatio
        let λ   = dampingCoefficient / mass / 2
        let ω_d = dampedNaturalFrequency
        let s_0 = initialPosition
        let v_0 = initialVelocity
        let t   = CGFloat(time)

        if abs(ζ - 1) < 1e-6 {
            let c_1 = s_0
            let c_2 = v_0 + λ * s_0

            return exp(-λ * t) * (c_1 + c_2 * t)
        
        } else if ζ < 1 {
            let c_1 = s_0
            let c_2 = (v_0 + λ * s_0) / ω_d

            return exp(-λ * t) * (c_1 * cos(ω_d * t) + c_2 * sin(ω_d * t))
        
        } else {
            let c_1 = (v_0 + s_0 * (λ + ω_d)) / (2 * ω_d)
            let c_2 = s_0 - c_1

            return exp(-λ * t) * (c_1 * exp(ω_d * t) + c_2 * exp(-ω_d * t))
        }
    }

    /// Calculates the maximum displacement from equilibrium the spring reaches when pushed with the specified velocity in its equilibrium state.
    ///
    /// - parameter initialVelocity: The velocity with which the spring is pushed at `t = 0`.
    private func maximumDisplacementFromEquilibrium(initialVelocity: CGFloat) -> CGFloat {
        let ζ   = dampingRatio
        let λ   = dampingCoefficient / mass / 2
        let ω_d = dampedNaturalFrequency
        let v_0 = initialVelocity

        var t: TimeInterval {
            if abs(ζ - 1) < 1e-6 {
                return TimeInterval(1 / λ)
                
            } else if ζ < 1 {
                return TimeInterval(atan(ω_d / λ) / ω_d)
                
            } else {
                return TimeInterval(log((λ + ω_d) / (λ - ω_d)) / (2 * ω_d))
            }
        }

        return abs(position(at: t, initialPosition: 0, initialVelocity: v_0))
    }


    // MARK: - Creating Timing Functions
    /// Creates an animation timing function using the spring's parameters and the specified relative initial velocity towards equilibrium, measured as fraction complete per second.
    func timingFunction(withRelativeInitialVelocity initialVelocity: CGVector) -> UISpringTimingParameters {
        return UISpringTimingParameters(mass: mass, stiffness: stiffness, damping: dampingCoefficient, initialVelocity: initialVelocity)
    }

    /// Creates an animation timing function using the spring's parameters and the specified relative initial velocity towards equilibrium, measured as fraction complete per second.
    func timingFunction(withRelativeInitialVelocity initialVelocity: CGFloat) -> UISpringTimingParameters {

        // If we happen to animate a two-dimensional property with the created timing parameters, we want both dimensions to be affected by the initial velocity.
        return timingFunction(withRelativeInitialVelocity: CGVector(dx: initialVelocity, dy: initialVelocity))
    }

    /// Creates an animation timing function using the spring's parameters,  intended to be used for an animation with the specified endpoints and  initial velocity.
    /// If the current and target values match already, the current value is slightly displaced so that the initial velocity can be respected.
    ///
    /// - parameter currentValue: The current value of the animated property.
    /// - parameter targetValue: The target value of the animated property.
    /// - parameter initialVelocity: The velocity at which the animated property initially changes, measured per second.
    func timingFunction(withInitialVelocity initialVelocity: CGFloat, from currentValue: inout CGFloat, to targetValue: CGFloat) -> UISpringTimingParameters {

        // A thousandth of the velocity is far less than the change in a single
        // frame and is therefore negligible regardless of the semantics of the
        // start and end values.
        let epsilon = abs(1e-3 * initialVelocity)
        return timingFunction(withRelativeInitialVelocity: relativeVelocity(forVelocity: initialVelocity, from: &currentValue, to: targetValue, epsilon: epsilon))
    }

    /// Creates an animation timing function using the spring's parameters, intended to be used for an animation with the specified endpoints and initial velocity.
    /// If the current and target values match already, the current value is slightly displaced so that the initial velocity can be respected.
    ///
    /// - parameter currentValue: The current value of the animated property.
    /// - parameter targetValue: The target value of the animated property.
    /// - parameter initialVelocity: The velocity at which the animated property initially changes, measured per second.
    /// - parameter context: The context in which the animation takes place, used to align values on pixel boundaries.
    func timingFunction(withInitialVelocity initialVelocity: CGFloat, from currentValue: inout CGFloat, to targetValue: CGFloat, context: UITraitEnvironment) -> UISpringTimingParameters {

        // We want to align values on pixel boundaries.
        let epsilon = 1 / fmax(1, context.traitCollection.displayScale)
        return timingFunction(withRelativeInitialVelocity: relativeVelocity(forVelocity: initialVelocity, from: &currentValue, to: targetValue, epsilon: epsilon))
    }

    /// Creates an animation timing function using the spring's parameters, intended to be used for an animation with the specified endpoints and initial velocity.
    /// If on an axis the current and target values match already, the current value is slightly displaced so that the initial velocity can be respected.
    ///
    /// - parameter currentValue: The current value of the animated property.
    /// - parameter targetValue: The target value of the animated property.
    /// - parameter initialVelocity: The velocity at which the animated property initially changes, measured per second.
    /// - parameter context: The context in which the animation takes place, used to align values on pixel boundaries.
    func timingFunction(withInitialVelocity initialVelocity: CGPoint, from currentValue: inout CGPoint, to targetValue: CGPoint, context: UITraitEnvironment) -> UISpringTimingParameters {

        // We want to align values on pixel boundaries.
        let epsilon = 1 / fmax(1, context.traitCollection.displayScale)
        let relativeXVelocity = relativeVelocity(forVelocity: initialVelocity.x, from: &currentValue.x, to: targetValue.x, epsilon: epsilon)
        let relativeYVelocity = relativeVelocity(forVelocity: initialVelocity.y, from: &currentValue.y, to: targetValue.y, epsilon: epsilon)
        let relativeVelocity  = CGVector(dx: relativeXVelocity, dy: relativeYVelocity)

        return timingFunction(withRelativeInitialVelocity: relativeVelocity)
    }

    /// Transforms the specified velocity to a relative velocity with a value of `1` indicating that the distance from the specified current value to the specified target value is covered in one second.
    /// If the current and target values match already, the current value is slightly displaced so that the initial velocity can be respected.
    ///
    /// - parameter velocity: The velocity at which the property currently changes, measured per second.
    /// - parameter currentValue: The current value of some property.
    /// - parameter targetValue: The target value of the property.
    /// - parameter epsilon: The distance up to which the current and target values are considered to be equal. If the current value needs to be tweaked, it is displaced by integral multiples of this parameter.
    private func relativeVelocity(forVelocity velocity: CGFloat, from currentValue: inout CGFloat, to targetValue: CGFloat, epsilon: CGFloat) -> CGFloat {
        precondition(epsilon > 0)

        if abs(targetValue - currentValue) >= epsilon {
            return velocity / (targetValue - currentValue)
        
        } else if maximumDisplacementFromEquilibrium(initialVelocity: velocity) >= 2 * epsilon {
            currentValue = velocity >= 0 ? targetValue + epsilon : targetValue - epsilon
            return velocity / (targetValue - currentValue)
            
        } else {
            return 0
        }
    }
}
