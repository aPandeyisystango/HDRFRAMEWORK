//
//  HDRActivityIndicatorView.swift
//  HDRActivityIndicatorView
//
// The MIT License (MIT)

import UIKit

// swiftlint:disable:next class_delegate_protocol
protocol HDRActivityIndicatorAnimationDelegate {
    func setUpAnimation(in layer: CALayer, size: CGSize, color: UIColor)
}

public enum HDRActivityIndicatorType: CaseIterable {
    /**
     Blank.
     
     - returns: Instance of HDRActivityIndicatorAnimationBlank.
     */
    case blank
    /**
     BallPulse.
     
     - returns: Instance of HDRActivityIndicatorAnimationBallPulse.
     */
    case ballPulse
    /**
     BallGridPulse.
     
     - returns: Instance of HDRActivityIndicatorAnimationBallGridPulse.
     */
    case ballGridPulse
    /**
     BallClipRotate.
     
     - returns: Instance of HDRActivityIndicatorAnimationBallClipRotate.
     */
    case ballClipRotate
    /**
     SquareSpin.
     
     - returns: Instance of HDRActivityIndicatorAnimationSquareSpin.
     */
    case squareSpin
    
}

/// Function that performs fade in/out animation.
public typealias FadeInAnimation = (UIView) -> Void

/// Function that performs fade out animation.
///
/// - Note: Must call the second parameter on the animation completion.
public typealias FadeOutAnimation = (UIView, @escaping () -> Void) -> Void

/// Activity indicator view with nice animations
public final class HDRActivityIndicatorView: UIView {
    // swiftlint:disable identifier_name
    /// Default type. Default value is .BallSpinFadeLoader.
    public static var DEFAULT_TYPE: HDRActivityIndicatorType = .squareSpin
    
    /// Default color of activity indicator. Default value is UIColor.white.
    public static var DEFAULT_COLOR = UIColor.white
    
    /// Default color of text. Default value is UIColor.white.
    public static var DEFAULT_TEXT_COLOR = UIColor.white
    
    /// Default padding. Default value is 0.
    public static var DEFAULT_PADDING: CGFloat = 0
    
    /// Default size of activity indicator view in UI blocker. Default value is 60x60.
    public static var DEFAULT_BLOCKER_SIZE = CGSize(width: 60, height: 60)
    
    /// Default display time threshold to actually display UI blocker. Default value is 0 ms.
    ///
    /// - note:
    /// Default time that has to be elapsed (between calls of `startAnimating()` and `stopAnimating()`) in order to actually display UI blocker. It should be set thinking about what the minimum duration of an activity is to be worth showing it to the user. If the activity ends before this time threshold, then it will not be displayed at all.
    public static var DEFAULT_BLOCKER_DISPLAY_TIME_THRESHOLD = 0
    
    /// Default minimum display time of UI blocker. Default value is 0 ms.
    ///
    /// - note:
    /// Default minimum display time of UI blocker. Its main purpose is to avoid flashes showing and hiding it so fast. For instance, setting it to 200ms will force UI blocker to be shown for at least this time (regardless of calling `stopAnimating()` ealier).
    public static var DEFAULT_BLOCKER_MINIMUM_DISPLAY_TIME = 0
    
    /// Default message displayed in UI blocker. Default value is nil.
    public static var DEFAULT_BLOCKER_MESSAGE: String?
    
    /// Default message spacing to activity indicator view in UI blocker. Default value is 8.
    public static var DEFAULT_BLOCKER_MESSAGE_SPACING = CGFloat(8.0)
    
    /// Default font of message displayed in UI blocker. Default value is bold system font, size 20.
    public static var DEFAULT_BLOCKER_MESSAGE_FONT = UIFont.boldSystemFont(ofSize: 20)
    
    /// Default background color of UI blocker. Default value is UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    public static var DEFAULT_BLOCKER_BACKGROUND_COLOR = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    
    /// Default fade in animation.
    public static var DEFAULT_FADE_IN_ANIMATION: FadeInAnimation = { view in
        view.alpha = 0
        UIView.animate(withDuration: 0.25) {
            view.alpha = 1
        }
    }
    
    /// Default fade out animation.
    public static var DEFAULT_FADE_OUT_ANIMATION: FadeOutAnimation = { (view, complete) in
        UIView.animate(withDuration: 0.25,
                       animations: {
                        view.alpha = 0
        },
                       completion: { completed in
                        if completed {
                            complete()
                        }
        })
    }
    // swiftlint:enable identifier_name
    
    /// Animation type.
    public var type: HDRActivityIndicatorType = HDRActivityIndicatorView.DEFAULT_TYPE
    
    @available(*, unavailable, message: "This property is reserved for Interface Builder. Use 'type' instead.")
    @IBInspectable var typeName: String {
        get {
            return getTypeName()
        }
        set {
            _setTypeName(newValue)
        }
    }
    
    /// Color of activity indicator view.
    @IBInspectable public var color: UIColor = HDRActivityIndicatorView.DEFAULT_COLOR
    
    /// Padding of activity indicator view.
    @IBInspectable public var padding: CGFloat = HDRActivityIndicatorView.DEFAULT_PADDING
    
    /// Current status of animation, read-only.
    @available(*, deprecated)
    public var animating: Bool { return isAnimating }
    
    /// Current status of animation, read-only.
    private(set) public var isAnimating: Bool = false
    
    /**
     Returns an object initialized from data in a given unarchiver.
     self, initialized using the data in decoder.
     
     - parameter decoder: an unarchiver object.
     
     - returns: self, initialized using the data in decoder.
     */
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
        isHidden = true
    }
    
    /**
     Create a activity indicator view.
     
     Appropriate HDRActivityIndicatorView.DEFAULT_* values are used for omitted params.
     
     - parameter frame:   view's frame.
     - parameter type:    animation type.
     - parameter color:   color of activity indicator view.
     - parameter padding: padding of activity indicator view.
     
     - returns: The activity indicator view.
     */
    public init(frame: CGRect, type: HDRActivityIndicatorType? = nil, color: UIColor? = nil, padding: CGFloat? = nil) {
        self.type = type ?? HDRActivityIndicatorView.DEFAULT_TYPE
        self.color = color ?? HDRActivityIndicatorView.DEFAULT_COLOR
        self.padding = padding ?? HDRActivityIndicatorView.DEFAULT_PADDING
        super.init(frame: frame)
        isHidden = true
    }
    
    // Fix issue #62
    // Intrinsic content size is used in autolayout
    // that causes mislayout when using with MBProgressHUD.
    /**
     Returns the natural size for the receiving view, considering only properties of the view itself.
     
     A size indicating the natural size for the receiving view based on its intrinsic properties.
     
     - returns: A size indicating the natural size for the receiving view based on its intrinsic properties.
     */
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: bounds.height)
    }
    
    public override var bounds: CGRect {
        didSet {
            // setup the animation again for the new bounds
            if oldValue != bounds && isAnimating {
                setUpAnimation()
            }
        }
    }
    
    /**
     Start animating.
     */
    public final func startAnimating() {
        guard !isAnimating else {
            return
        }
        isHidden = false
        isAnimating = true
        layer.speed = 1
        setUpAnimation()
    }
    
    /**
     Stop animating.
     */
    public final func stopAnimating() {
        guard isAnimating else {
            return
        }
        isHidden = true
        isAnimating = false
        layer.sublayers?.removeAll()
    }
    
    // MARK: Internal
    
    // swiftlint:disable:next identifier_name
    func _setTypeName(_ typeName: String) {
        for item in HDRActivityIndicatorType.allCases {
            if String(describing: item).caseInsensitiveCompare(typeName) == ComparisonResult.orderedSame {
                type = item
                break
            }
        }
    }
    
    func getTypeName() -> String {
        return String(describing: type)
    }
    
    // MARK: Privates
    
    private final func setUpAnimation() {
        let animation: HDRActivityIndicatorAnimationDelegate = HDRActivityIndicatorAnimationSquareSpin()
        #if swift(>=4.2)
        var animationRect = frame.inset(by: UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding))
        #else
        var animationRect = UIEdgeInsetsInsetRect(frame, UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding))
        #endif
        let minEdge = min(animationRect.width, animationRect.height)
        
        layer.sublayers = nil
        animationRect.size = CGSize(width: minEdge, height: minEdge)
        animation.setUpAnimation(in: layer, size: animationRect.size, color: color)
    }
}

enum HDRActivityIndicatorShape {
    case circle
    case circleSemi
    case ring
    case ringTwoHalfVertical
    case ringTwoHalfHorizontal
    case ringThirdFour
    case rectangle
    case triangle
    case line
    case pacman
    case stroke
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func layerWith(size: CGSize, color: UIColor) -> CALayer {
           let layer: CAShapeLayer = CAShapeLayer()
           var path: UIBezierPath = UIBezierPath()
           let lineWidth: CGFloat = 2

           switch self {
           case .circle:
               path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                           radius: size.width / 2,
                           startAngle: 0,
                           endAngle: CGFloat(2 * Double.pi),
                           clockwise: false)
               layer.fillColor = color.cgColor
           case .circleSemi:
               path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                           radius: size.width / 2,
                           startAngle: CGFloat(-Double.pi / 6),
                           endAngle: CGFloat(-5 * Double.pi / 6),
                           clockwise: false)
               path.close()
               layer.fillColor = color.cgColor
           case .ring:
               path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                           radius: size.width / 2,
                           startAngle: 0,
                           endAngle: CGFloat(2 * Double.pi),
                           clockwise: false)
               layer.fillColor = nil
               layer.strokeColor = color.cgColor
               layer.lineWidth = lineWidth
           case .ringTwoHalfVertical:
               path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                           radius: size.width / 2,
                           startAngle: CGFloat(-3 * Double.pi / 4),
                           endAngle: CGFloat(-Double.pi / 4),
                           clockwise: true)
               path.move(
                   to: CGPoint(x: size.width / 2 - size.width / 2 * cos(CGFloat(Double.pi / 4)),
                               y: size.height / 2 + size.height / 2 * sin(CGFloat(Double.pi / 4)))
               )
               path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                           radius: size.width / 2,
                           startAngle: CGFloat(-5 * Double.pi / 4),
                           endAngle: CGFloat(-7 * Double.pi / 4),
                           clockwise: false)
               layer.fillColor = nil
               layer.strokeColor = color.cgColor
               layer.lineWidth = lineWidth
           case .ringTwoHalfHorizontal:
               path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                           radius: size.width / 2,
                           startAngle: CGFloat(3 * Double.pi / 4),
                           endAngle: CGFloat(5 * Double.pi / 4),
                           clockwise: true)
               path.move(
                   to: CGPoint(x: size.width / 2 + size.width / 2 * cos(CGFloat(Double.pi / 4)),
                               y: size.height / 2 - size.height / 2 * sin(CGFloat(Double.pi / 4)))
               )
               path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                           radius: size.width / 2,
                           startAngle: CGFloat(-Double.pi / 4),
                           endAngle: CGFloat(Double.pi / 4),
                           clockwise: true)
               layer.fillColor = nil
               layer.strokeColor = color.cgColor
               layer.lineWidth = lineWidth
           case .ringThirdFour:
               path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                           radius: size.width / 2,
                           startAngle: CGFloat(-3 * Double.pi / 4),
                           endAngle: CGFloat(-Double.pi / 4),
                           clockwise: false)
               layer.fillColor = nil
               layer.strokeColor = color.cgColor
               layer.lineWidth = 2
           case .rectangle:
               path.move(to: CGPoint(x: 0, y: 0))
               path.addLine(to: CGPoint(x: size.width, y: 0))
               path.addLine(to: CGPoint(x: size.width, y: size.height))
               path.addLine(to: CGPoint(x: 0, y: size.height))
               layer.fillColor = color.cgColor
           case .triangle:
               let offsetY = size.height / 4

               path.move(to: CGPoint(x: 0, y: size.height - offsetY))
               path.addLine(to: CGPoint(x: size.width / 2, y: size.height / 2 - offsetY))
               path.addLine(to: CGPoint(x: size.width, y: size.height - offsetY))
               path.close()
               layer.fillColor = color.cgColor
           case .line:
               path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height),
                                   cornerRadius: size.width / 2)
               layer.fillColor = color.cgColor
           case .pacman:
               path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                           radius: size.width / 4,
                           startAngle: 0,
                           endAngle: CGFloat(2 * Double.pi),
                           clockwise: true)
               layer.fillColor = nil
               layer.strokeColor = color.cgColor
               layer.lineWidth = size.width / 2
           case .stroke:
               path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                           radius: size.width / 2,
                           startAngle: -(.pi / 2),
                           endAngle: .pi + .pi / 2,
                           clockwise: true)
               layer.fillColor = nil
               layer.strokeColor = color.cgColor
               layer.lineWidth = 2
           }

           layer.backgroundColor = nil
           layer.path = path.cgPath
           layer.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

           return layer
    }
}
