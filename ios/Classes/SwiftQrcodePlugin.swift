import Flutter
import UIKit
import AVFoundation

@objc public class SwiftQrcodePlugin: NSObject, FlutterPlugin {
  
    var viewController: UIViewController!
    var navigationController: UINavigationController?
    var qrcodeViewController: UIViewController?
    
    var qrcodeView: UIView?
    
    var text: UILabel?
    
    var width = UIScreen.main.applicationFrame.size.width
    var height = UIScreen.main.applicationFrame.size.height
    
    var scanSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    var result: FlutterResult?
    
    let ration = CGFloat(0.6)
    
    lazy var scanPan: UIImageView = {
        let scanPan = UIImageView()
        scanPan.frame = CGRect(x: width / 2 - ration * width / 2, y: height / 2 - ration * width / 2, width: ration * width, height: ration * width)
        scanPan.image = UIImage(named: "scan_box.png")
        scanPan.contentMode = UIImageView.ContentMode.redraw
        return scanPan
    }()
    
    lazy var scanLine: UIImageView = {
        let scanLine = UIImageView()
        scanLine.frame = CGRect(x: 0, y: 0, width: self.scanPan.bounds.width, height: 3)
        scanLine.image = UIImage(named: "scan_line.png")
        return scanLine
    }()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "qrcode", binaryMessenger: registrar.messenger())
        let viewController = UIApplication.shared.delegate?.window??.rootViewController
        let instance = SwiftQrcodePlugin().initWithViewController(viewController: viewController!)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arg = call.arguments as! NSDictionary
        if call.method == "scanQRCode" {
            let title = arg["title"] as! String
            let text = arg["text"] as! String
            showQRCodeView(title: title, text: text)
            self.result = result
        } else {
            print("Unexpected call method: \(call.method)")
        }
    }
    
    fileprivate func initWithViewController(viewController: UIViewController) -> SwiftQrcodePlugin {
        self.viewController = viewController
        self.viewController.view.backgroundColor = UIColor.clear
        self.viewController.view.isOpaque = false
        return self
    }
    
    fileprivate func showQRCodeView(title: String, text: String) {
        qrcodeViewController = UIViewController()
        navigationController = UINavigationController(rootViewController: qrcodeViewController!)
        qrcodeViewController?.title = title
        UIApplication.shared.delegate?.window!!.rootViewController = navigationController
        UIApplication.shared.delegate?.window!!.makeKeyAndVisible()
        loadViewQRCode(content: text)
        viewQRCodeDidLoad()
        
    }
    
    fileprivate func loadViewQRCode(content: String) {
        qrcodeView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: height))
        qrcodeView?.isOpaque = true
        qrcodeView?.backgroundColor = UIColor.clear
        qrcodeViewController?.view = qrcodeView
        qrcodeView?.insertSubview(scanPan, at: 0)
        scanPan.addSubview(scanLine)
        setupScanSession()
        
        text = UILabel()
        text?.frame = CGRect(x: 0, y: scanPan.frame.origin.y + scanPan.frame.size.height + 20, width: width, height: 20)
        text?.textAlignment = NSTextAlignment.center
        text?.text = content
        text?.textColor = UIColor.black
        text?.backgroundColor = UIColor.clear
        text?.font = UIFont.systemFont(ofSize: 12)
    }
    
    fileprivate func viewQRCodeDidLoad() {
        qrcodeViewController?.view.addSubview(scanPan)
        qrcodeViewController?.view.addSubview(text!)
        if #available(iOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { (ktimer) in
                self.startScan()
            })
        } else {
            // Fallback on earlier versions
        }
    }
    
    fileprivate func startScan() {
        scanLine.layer.add(scanAnimation(), forKey: "scan")
        guard let scanSession = scanSession else {
            return
        }
        if !scanSession.isRunning {
            scanSession.startRunning()
        }
    }
    
    fileprivate func scanAnimation() -> CABasicAnimation {
        let startPoint = CGPoint(x: scanLine.center.x, y: 1)
        let endPoint = CGPoint(x: scanLine.center.x, y: scanPan.bounds.size.height - 2)
        let translation = CABasicAnimation(keyPath: "position")
        translation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        translation.fromValue = NSValue(cgPoint: startPoint)
        translation.toValue = NSValue(cgPoint: endPoint)
        translation.duration = 4.0
        translation.repeatCount = MAXFLOAT
        translation.autoreverses = true
        return translation
    }
    
    fileprivate func setupScanSession() {
        do {
            let device = AVCaptureDevice.default(for: AVMediaType.video)
            let input = try AVCaptureDeviceInput(device: device!)
            let output = AVCaptureMetadataOutput()
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            let scanSession = AVCaptureSession()
            scanSession.canSetSessionPreset(AVCaptureSession.Preset.high)
            if scanSession.canAddInput(input) {
                scanSession.addInput(input)
            }
            if scanSession.canAddOutput(output) {
                scanSession.addOutput(output)
            }
            output.metadataObjectTypes = [
                AVMetadataObject.ObjectType.qr,
                AVMetadataObject.ObjectType.code39,
                AVMetadataObject.ObjectType.code128,
                AVMetadataObject.ObjectType.code39Mod43,
                AVMetadataObject.ObjectType.ean13,
                AVMetadataObject.ObjectType.ean8,
                AVMetadataObject.ObjectType.code93
            ]
            let scanPreviewLayer = AVCaptureVideoPreviewLayer(session: scanSession)
            scanPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            scanPreviewLayer.frame = UIScreen.main.applicationFrame
            qrcodeView?.layer.addSublayer(scanPreviewLayer)
            NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureInputPortFormatDescriptionDidChange, object: nil, queue: nil, using: { (noti) in
                output.rectOfInterest = (scanPreviewLayer.metadataOutputRectConverted(fromLayerRect: self.scanPan.frame))
            })
            self.scanSession = scanSession
        } catch {
            
        }
    }
}

extension SwiftQrcodePlugin : AVCaptureMetadataOutputObjectsDelegate {
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        self.scanLine.layer.removeAllAnimations()
        self.scanSession!.stopRunning()
        
        if metadataObjects.count > 0 {
            if let resultObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
                print("result: \(resultObj.description)")
                result!(resultObj.stringValue)
                //navigationController?.popViewController(animated: true)
            }
        }
    }

}
