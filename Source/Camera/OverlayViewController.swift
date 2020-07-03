//
//  OverlayViewController.swift
//  HDRKit
//
//  Created by macmini41 on 13/05/20.
//  Copyright © 2020 Immosquare. All rights reserved.
//

import UIKit

protocol OverlayViewControllerDelegate: class {
    func useTheImageClicked(proccessedImage: UIImage?)
    func resetWideAngle()
}

class OverlayViewController: UIViewController {
    
    // MARK: - Properties
    
    var centreImageView: UIImageView = UIImageView()
    var bottomView: UIView = UIView()
    var retakeBtn: UIButton = UIButton()
    var useBtn: UIButton = UIButton()
    var proccessedImage: UIImage?
    let previewView = PreviewView()
    
    weak var delegate: OverlayViewControllerDelegate?
    
    private lazy var activityIndicatorView = HDRActivityIndicatorView(frame: CGRect(x: view.center.x-25, y: view.center.y-25, width: 50, height: 50), type: .squareSpin)
    
    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        centreImageView.backgroundColor = .clear
        centreImageView.contentMode = .scaleAspectFit
        
        addImageView()
        addBottomView()
        bottomView.isHidden = true
    }
    
    // MARK: - Actions
    
    @IBAction func retakeAction(_ sender: UIButton) {
        delegate?.resetWideAngle()
        navigationController?.popViewController(animated: false)
    }
    
    @IBAction func useAction(_ sender: UIButton) {
        if let proccessedImage = self.proccessedImage {
            self.dismiss(animated: false) {
                self.delegate?.useTheImageClicked(proccessedImage: proccessedImage)
            }
        }
    }
    
    // MARK: - Internal functions
    
    func showActivityIndicator() {
        activityIndicatorView.center = view.center
        activityIndicatorView.startAnimating()
        view.addSubview(activityIndicatorView)
    }
    
    func setImage(processedImage: UIImage) {
        centreImageView.image = processedImage
        self.proccessedImage = processedImage
        activityIndicatorView.stopAnimating()
        bottomView.isHidden = false
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    // MARK: - Private functions
    
    private func addImageView() {
        view.addSubview(centreImageView)
        centreImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            centreImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            centreImageView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            centreImageView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            centreImageView.heightAnchor.constraint(equalToConstant: Constants.screenHeight)
        ])
    }
    
    private func addBottomView() {
        view.addSubview(bottomView)
        
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.backgroundColor = .clear
        bottomView.addSubview(retakeBtn)
        bottomView.addSubview(useBtn)
        
        retakeBtn.setTitle("retake".localized, for: .normal)
        retakeBtn.addTarget(self, action: #selector(retakeAction(_:)), for: .touchUpInside)
        retakeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        retakeBtn.setTitleColor(UIColor.white, for: .normal)
        retakeBtn.translatesAutoresizingMaskIntoConstraints = false
        
        useBtn.setTitle("use".localized, for: .normal)
        useBtn.addTarget(self, action: #selector(useAction(_:)), for: .touchUpInside)
        useBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        useBtn.setTitleColor(UIColor.white, for: .normal)
        useBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            bottomView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            bottomView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            bottomView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            bottomView.heightAnchor.constraint(equalToConstant: 60),
            retakeBtn.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30),
            retakeBtn.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 30),
            retakeBtn.heightAnchor.constraint(equalToConstant: 30),
            useBtn.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -30),
            useBtn.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -30),
            useBtn.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}
