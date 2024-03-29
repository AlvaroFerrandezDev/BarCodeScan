//
//  ScanView.swift
//  BarCodeScan
//
//  Created sopra on 14/11/20.
//  Copyright © 2020 AFSopra. All rights reserved.
//

import AVFoundation
import UIKit

private enum BarCodeConstants {
    static let exitButtonHeight = CGFloat(44)
    static let exitButtonWidth = CGFloat(44)
    static let safeDistanceExitButtonX = CGFloat(10)
    static let safeDistanceExitButtonY = CGFloat(20)
    static let safeDistanceOverlay = CGFloat(40)
    static let overlayHalfHeight = CGFloat(130)
    static let overlayWidth = CGFloat(80)
    static let cornerHeight = CGFloat(0)
    static let cornerWidth = CGFloat(0)
    static let safeDistanceLabelX = CGFloat(20)
    static let topDistanceFrameLabel = CGFloat(60)
    static let paddingLabel = CGFloat(15)
    static let paddingCornersLayer = CGFloat(16)
    static let bottomLabelHeight = CGFloat(100)
    static let purpleColor = UIColor(red: CGFloat(78.0 / 255.0), green: CGFloat(77.0 / 255.0), blue: CGFloat(128.0 / 255.0), alpha: CGFloat(1.0))
    static let purpleColorBackground = UIColor(red: CGFloat(78.0 / 255.0), green: CGFloat(77.0 / 255.0), blue: CGFloat(128.0 / 255.0), alpha: CGFloat(0.4))
    static let blueColor = UIColor(red: CGFloat(22.0 / 255.0), green: CGFloat(25.0 / 255.0), blue: CGFloat(91.0 / 255.0), alpha: CGFloat(1.0))
}

final class ScanView: UIViewController {
    var presenter: ScanPresenterProtocol!

    @IBOutlet private weak var indicatorSpinner: UIActivityIndicatorView!

    // MARK: BarCodeScan components
    fileprivate var detectionView = UIView()
    fileprivate var captureSession: AVCaptureSession?
    fileprivate var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    lazy var bottomLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.backgroundColor = BarCodeConstants.purpleColor
        label.textColor = .white
        label.text = "Mueva el dispositivo y ajuste el código de barras dentro del espacio dedicado en la pantalla."
        label.leftInset = BarCodeConstants.paddingLabel
        label.rightInset = BarCodeConstants.paddingLabel
        label.shadowOffset = CGSize(width: 1, height: 1)
        label.shadowColor = UIColor.black
        return label
    }()

    // MARK: Lifecycle methods
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.presenter.viewDidDisappear()

        self.stopSpinner()
        self.stopBarCodeScan()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.presenter.viewWillAppear()

        self.videoPreviewLayer?.frame = self.view.bounds

        self.stopSpinner()
        self.setBarCodeScan()
        self.addOverlay()
        self.addLabelOverlay()
        self.createExitButton()
    }

    // MARK: Activity indicator methods
    fileprivate func startSpinner() {
        DispatchQueue.main.async {
            self.indicatorSpinner.startAnimating()
            self.indicatorSpinner.isHidden = false
        }
    }

    fileprivate func stopSpinner() {
        DispatchQueue.main.async {
            self.indicatorSpinner.stopAnimating()
            self.indicatorSpinner.isHidden = true
        }
    }

    // MARK: UI methods
    private func createExitButton() {
        let button = UIButton(frame: CGRect(x: self.view.frame.maxX - BarCodeConstants.exitButtonWidth - BarCodeConstants.safeDistanceExitButtonX, y: self.view.frame.minY + BarCodeConstants.exitButtonHeight + BarCodeConstants.safeDistanceExitButtonY, width: BarCodeConstants.exitButtonWidth, height: BarCodeConstants.exitButtonHeight))
        button.backgroundColor = BarCodeConstants.purpleColor
        button.layer.cornerRadius = BarCodeConstants.exitButtonWidth / 2
        button.setTitle("X", for: .normal)
        button.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)

        self.view.addSubview(button)
    }

    @objc func buttonAction() {
        self.presenter.onBackButtonTapped()
    }

    // MARK: BarCodeScan methods
    fileprivate func setBarCodeScan() {
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            return
        }

        do {
            guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
            self.captureSession = AVCaptureSession()
            self.captureSession?.addInput(input)
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [.ean13, .code128, .code39, .code93, .ean8, .dataMatrix]
            if let captureSession = captureSession {
                let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                videoPreviewLayer.frame = self.view.layer.bounds
                self.view.layer.addSublayer(videoPreviewLayer)
                captureSession.startRunning()
            }
        }
    }

    fileprivate func stopBarCodeScan() {
        self.captureSession?.stopRunning()
    }

    // MARK: Overlay scan methods
    func addOverlay() {
        self.detectionView = self.createOverlay()
        self.view.addSubview(self.detectionView)
    }

    func createOverlay() -> UIView {
        let overlayView = UIView(frame: view.frame)
        overlayView.backgroundColor = BarCodeConstants.purpleColorBackground

        let path = CGMutablePath()

        path.addRoundedRect(in: CGRect(x: BarCodeConstants.safeDistanceOverlay, y: overlayView.center.y - BarCodeConstants.overlayHalfHeight, width: overlayView.frame.width - BarCodeConstants.overlayWidth, height: 2 * BarCodeConstants.overlayHalfHeight), cornerWidth: BarCodeConstants.cornerWidth, cornerHeight: BarCodeConstants.cornerHeight)

        path.closeSubpath()

        let shape = CAShapeLayer()
        shape.path = path
        shape.lineWidth = 0.2
        shape.strokeColor = BarCodeConstants.purpleColor.cgColor
        shape.fillColor = BarCodeConstants.purpleColor.cgColor

        overlayView.layer.addSublayer(shape)

        path.addRect(CGRect(origin: .zero, size: overlayView.frame.size))

        let maskLayer = CAShapeLayer()
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.path = path
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd

        overlayView.layer.mask = maskLayer
        overlayView.clipsToBounds = true

        let cornersView = CornersView(frame: CGRect(x: BarCodeConstants.safeDistanceOverlay + BarCodeConstants.paddingCornersLayer, y: overlayView.center.y - BarCodeConstants.overlayHalfHeight + BarCodeConstants.paddingCornersLayer, width: overlayView.frame.width - BarCodeConstants.overlayWidth - 2 * BarCodeConstants.paddingCornersLayer, height: 2 * BarCodeConstants.overlayHalfHeight - 2 * BarCodeConstants.paddingCornersLayer))
        cornersView.color = BarCodeConstants.blueColor
        cornersView.thickness = 12
        cornersView.backgroundColor = .clear
        cornersView.layer.shadowColor = UIColor.black.cgColor
        cornersView.layer.shadowOpacity = 0.5
        cornersView.layer.shadowOffset = .zero
        cornersView.layer.shadowRadius = 5
        self.view.addSubview(cornersView)

        return overlayView
    }

    func addLabelOverlay() {
        self.view.addSubview(self.bottomLabel)

        let leadingConstraint = NSLayoutConstraint(item: self.bottomLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: BarCodeConstants.safeDistanceLabelX)
        let trailingConstraint = NSLayoutConstraint(item: self.view ?? UIView(), attribute: .trailing, relatedBy: .equal, toItem: self.bottomLabel, attribute: .trailing, multiplier: 1, constant: BarCodeConstants.safeDistanceLabelX)
        let topConstraint = NSLayoutConstraint(item: self.bottomLabel, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: BarCodeConstants.overlayHalfHeight + BarCodeConstants.topDistanceFrameLabel)
        let heighConstraint = self.bottomLabel.heightAnchor.constraint(equalToConstant: BarCodeConstants.bottomLabelHeight)

        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, topConstraint, heighConstraint])
    }
}

extension ScanView: ScanViewProtocol {}

extension ScanView: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let readableObjectCode = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let code = readableObjectCode.stringValue?.components(separatedBy: .whitespaces).joined()
        {
            DispatchQueue.main.async {
                self.startSpinner()
                self.captureSession?.stopRunning()

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.stopSpinner()
                    self.presenter.presentDetail(code: code)
                }
            }
        }
    }
}
