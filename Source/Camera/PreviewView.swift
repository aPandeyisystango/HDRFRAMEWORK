import UIKit
import AVFoundation
import CoreMotion

protocol PreviewViewDelegate: class {
    func captureWideAngle(numOfFramesCaptured: Int)
}

class PreviewView: UIView {
    
    private let orientationManager = OrientationManager()
    let levelStaticView = UIView()
    let levelView = UIView()
    let rectangleView = UIView()
    let leftRectangleView = UIView()
    let rightRectangleView = UIView()
    var wideAngleInitiated = false
    var imagesClicked = [false, false, false]
    weak  var delegate: PreviewViewDelegate?
    lazy var initialAttitude: CMAttitude? = {
        return orientationManager.motionUpdateManager.deviceMotion?.attitude
    }()
    var frameNumber = 0 {
        willSet {
            if frameNumber != newValue && newValue>0 && newValue < 4 && !imagesClicked[newValue-1] {
                if newValue == 2 {
                    self.rectangleView.layer.borderColor = UIColor.blue.cgColor
                } else if newValue == 3 {
                    self.rightRectangleView.layer.borderColor = UIColor.blue.cgColor
                }
                self.delegate?.captureWideAngle(numOfFramesCaptured: newValue)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.imagesClicked[ newValue - 1 ] = true
                }
            }
        }
    }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }

    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
		
        addLevelViews()
        setRectangleView()
        setRightRectangleView()
        setLeftRectangleView()
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
		
        orientationManager.startOrientationUpdate()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: .orientationChanged, object: nil)
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()
		
        NotificationCenter.default.removeObserver(self, name: .orientationChanged, object: nil)
    }

    func addLevelViews() {
        levelStaticView.backgroundColor = .gray
		levelStaticView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(levelStaticView)
		
        NSLayoutConstraint.activate([
            levelStaticView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 80),
            levelStaticView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -80),
            levelStaticView.heightAnchor.constraint(equalToConstant: 2),
            levelStaticView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            levelStaticView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])

        levelView.backgroundColor = .red
		levelView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(levelView)
        
        NSLayoutConstraint.activate([
            levelView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 80),
            levelView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -80),
            levelView.heightAnchor.constraint(equalToConstant: 2),
            levelView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            levelView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])

        orientationManager.orientationUpdateWithRotation( handler: { rotation in
            DispatchQueue.main.async {
                self.levelView.transform = CGAffineTransform(rotationAngle: rotation)

                var shiftedrotation = Double(rotation)

                switch self.orientationManager.orientation {
                case .landscapeRight :
                    shiftedrotation  = Double(rotation) + 3 * Double.pi/2
                case .landscapeLeft :
                    shiftedrotation  = Double(rotation) + Double.pi/2
                case .portraitUpsideDown :
                    shiftedrotation  = Double(rotation) + Double.pi
                default:
                    shiftedrotation =  Double(rotation)
                }
				
                self.manageLevelsWithRotation(shiftedrotation)
            }
        })
    }

    private func manageLevelsWithRotation(_ rotation: Double) {
        if -0.03 ... 0.03 ~= rotation || -6.5 ... -6.2 ~= rotation {
            UIView.animate(withDuration: 0.3) {
                self.levelView.backgroundColor = .clear
                self.levelStaticView.backgroundColor = .clear
            }
        } else if -0.05 ... 0.05 ~= rotation || -6.8 ... -6.0 ~= rotation {
            self.levelView.backgroundColor = .green
            self.levelStaticView.backgroundColor = .gray
        } else {
            self.levelView.backgroundColor = .red
            self.levelStaticView.backgroundColor = .gray
        }
    }

    func updatePreviewViewConstraints(cameraHeight: CGFloat, parentView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
		
        NSLayoutConstraint.activate([
            bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -((cameraHeight/3) * 2)),
            topAnchor.constraint(equalTo: parentView.topAnchor, constant: cameraHeight/3),
            leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            trailingAnchor.constraint(equalTo: parentView.trailingAnchor)
        ])
    }
    
    private func setLeftRectangleView () {
		leftRectangleView.backgroundColor = .clear
        leftRectangleView.translatesAutoresizingMaskIntoConstraints = false
        leftRectangleView.layer.borderWidth = 1
        leftRectangleView.layer.borderColor = UIColor.blue.cgColor
        setMovingCircleView(parentView: leftRectangleView)
		addSubview(leftRectangleView)
        
        NSLayoutConstraint.activate([
            leftRectangleView.heightAnchor.constraint(equalToConstant: 120),
            leftRectangleView.widthAnchor.constraint(equalToConstant: 80),
            leftRectangleView.trailingAnchor.constraint(equalTo: self.centerXAnchor, constant: -40),
            leftRectangleView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
    
    private func setRightRectangleView () {
		rightRectangleView.backgroundColor = .clear
        rightRectangleView.translatesAutoresizingMaskIntoConstraints = false
        rightRectangleView.layer.borderWidth = 1
        rightRectangleView.layer.borderColor = UIColor.red.cgColor
        setMovingCircleView(parentView: rightRectangleView)
        addSubview(rightRectangleView)
        
        NSLayoutConstraint.activate([
            rightRectangleView.heightAnchor.constraint(equalToConstant: 120),
            rightRectangleView.widthAnchor.constraint(equalToConstant: 80),
            rightRectangleView.leadingAnchor.constraint(equalTo: self.centerXAnchor, constant: 40),
            rightRectangleView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
     }
    
    private func setRectangleView () {
		rectangleView.backgroundColor = .clear
        rectangleView.translatesAutoresizingMaskIntoConstraints = false
        rectangleView.layer.borderWidth = 1
        rectangleView.layer.borderColor = UIColor.red.cgColor
        setMovingCircleView(parentView: rectangleView)
		addSubview(rectangleView)
        
        NSLayoutConstraint.activate([
            rectangleView.heightAnchor.constraint(equalToConstant: 120),
            rectangleView.widthAnchor.constraint(equalToConstant: 80),
            rectangleView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            rectangleView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        ])
    }
    @objc func orientationChanged() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0) {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    self.levelStaticView.transform = CGAffineTransform(rotationAngle: self.orientationManager.orientationAngle)
                }
            }
        }
    }
    
    private func setMovingCircleView (parentView: UIView) {
        let centerCircleView = UIView()
        centerCircleView.backgroundColor = .blue
        centerCircleView.translatesAutoresizingMaskIntoConstraints = false
        centerCircleView.layer.cornerRadius = 15
        centerCircleView.clipsToBounds = true
		parentView.addSubview(centerCircleView)
		
        NSLayoutConstraint.activate([
            centerCircleView.heightAnchor.constraint(equalToConstant: 30),
            centerCircleView.widthAnchor.constraint(equalToConstant: 30),
            centerCircleView.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
            centerCircleView.centerXAnchor.constraint(equalTo: parentView.centerXAnchor)
        ])
    }
  
    func didActivateWideAngle(active: Bool) {
        if active {
            rectangleView.isHidden = false
            rightRectangleView.isHidden = false
            leftRectangleView.isHidden = false
            leftRectangleView.layer.borderColor = UIColor.blue.cgColor
            rectangleView.layer.borderColor = UIColor.red.cgColor
            rightRectangleView.layer.borderColor = UIColor.red.cgColor
        } else {
            rectangleView.isHidden = true
            rightRectangleView.isHidden = true
            leftRectangleView.isHidden = true
        }
		
        wideAngleInitiated = false
		orientationManager.motionUpdates(active: false, handler: {_ in })
    }
    
    func activateWideAngle() {
        orientationManager.motionUpdates(active: true, handler: { data in
            if let data = data {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.05) {
                        guard let attitude = self.initialAttitude else {
                            print("failed to initialize attitude")
                            return
                        }
						
						self.wideAngleInitiated = true
						
                        // translate the attitude
                        data.multiply(byInverseOf: attitude)
                        if !( data.pitch > 0.1 || data.yaw > 0.1 ) {
                            self.frameNumber = Int(data.roll * -1.8) + 1
                        }
                        if self.frameNumber == 1 && self.imagesClicked[0] && !self.imagesClicked[1] && !self.imagesClicked[2] {
                            self.leftRectangleView.layer.borderColor = UIColor.green.cgColor
                            self.rectangleView.layer.borderColor = UIColor.red.cgColor
                            self.rightRectangleView.layer.borderColor = UIColor.red.cgColor
                        } else if self.frameNumber == 2  && self.imagesClicked[1] {
                            self.leftRectangleView.layer.borderColor = UIColor.green.cgColor
                            self.rectangleView.layer.borderColor = UIColor.green.cgColor
                            self.rightRectangleView.layer.borderColor = UIColor.red.cgColor
                        } else if self.frameNumber == 3 && self.imagesClicked[2] {
                            self.leftRectangleView.layer.borderColor = UIColor.green.cgColor
                            self.rectangleView.layer.borderColor = UIColor.green.cgColor
                            self.rightRectangleView.layer.borderColor = UIColor.green.cgColor
                        }
                    }
                }
            }
        })
    }
    
    func cameraCaptureClicked(active: Bool) {
        if  !self.wideAngleInitiated {
            activateWideAngle()
        }
    }
}
