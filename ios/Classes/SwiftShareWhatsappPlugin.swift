import Flutter
import UIKit

public class SwiftShareWhatsappPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "share_whatsapp", binaryMessenger: registrar.messenger())
        let instance = SwiftShareWhatsappPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "installed" {
            if let whatsappURL = URL(string: "whatsapp://send?text=installed") {
                result(UIApplication.shared.canOpenURL(whatsappURL) ? 1 : 0)
                return
            }
            result(FlutterError(code: "ERROR_INSTALLED", message: "Failed to generate whatsappURL", details: nil))
            return
        }
      
        if call.method == "share" {
            self.share(call.arguments, result: result)
            return
        }
        
        result(FlutterMethodNotImplemented)
    }
}

extension SwiftShareWhatsappPlugin {
    fileprivate func share(_ arguments: Any?, result: @escaping FlutterResult) {
        if let dict = arguments as? [String: String?] {
            var activityItems = [Any]()
            if let text = dict["text"] as? String {
                activityItems.append(WhatsAppActivityTextItem(text: text))
            }
            if let filePath = dict["file"] as? String {
                let file = URL(fileURLWithPath: filePath)
                activityItems.append(WhatsAppActivityFileItem(url: file))

            }

            let activityViewController = WhatsAppActivityViewController(activityItems: activityItems, applicationActivities: [WhatsAppUIActivity(activityItems: activityItems)])
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                activityViewController.popoverPresentationController?.sourceView = UIApplication.topViewController()?.view
                if let view = UIApplication.topViewController()?.view {
                    activityViewController.popoverPresentationController?.permittedArrowDirections = []
                    activityViewController.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
                }
            }
            
            if #available(iOS 15.4, *) {
                activityViewController.allowsProminentActivity = false
            } else {
                // Fallback on earlier versions
            }
            
            activityViewController.excludedActivityTypes = [
                UIActivity.ActivityType.copyToPasteboard,
                UIActivity.ActivityType.postToFacebook,
                UIActivity.ActivityType.postToTwitter,
                UIActivity.ActivityType.postToWeibo,
                UIActivity.ActivityType.message,
                UIActivity.ActivityType.print,
                UIActivity.ActivityType.assignToContact,
                UIActivity.ActivityType.saveToCameraRoll,
                UIActivity.ActivityType.addToReadingList,
                UIActivity.ActivityType.postToFlickr,
                UIActivity.ActivityType.postToVimeo,
                UIActivity.ActivityType.postToTencentWeibo,
                UIActivity.ActivityType.airDrop,
                UIActivity.ActivityType.mail,
                UIActivity.ActivityType(rawValue: "com.apple.CloudDocsUI.AddToiCloudDrive"),
                UIActivity.ActivityType(rawValue: "com.apple.mobilenotes.SharingExtension"),
                UIActivity.ActivityType(rawValue: "com.apple.reminders.RemindersEditorExtension"),
                UIActivity.ActivityType(rawValue: "com.apple.mobilenotes.SharingExtension"),
                UIActivity.ActivityType(rawValue: "com.amazon.Lassen.SendToKindleExtension"),
                UIActivity.ActivityType(rawValue: "com.google.chrome.ios.ShareExtension"),
                UIActivity.ActivityType(rawValue: "com.google.Drive.ShareExtension"),
                UIActivity.ActivityType(rawValue: "com.google.Gmail.ShareExtension"),
                UIActivity.ActivityType(rawValue: "com.google.inbox.ShareExtension"),
                UIActivity.ActivityType(rawValue: "com.google.hangouts.ShareExtension"),
                UIActivity.ActivityType(rawValue: "com.iwilab.KakaoTalk.Share"),
                UIActivity.ActivityType(rawValue: "com.hammerandchisel.discord.Share"),
                UIActivity.ActivityType(rawValue: "com.facebook.Messenger.ShareExtension"),
                UIActivity.ActivityType(rawValue: "com.nhncorp.NaverSearch.ShareExtension"),
                UIActivity.ActivityType(rawValue: "com.linkedin.LinkedIn.ShareExtension"),
                UIActivity.ActivityType(rawValue: "com.tinyspeck.chatlyio.share"), // Slack!
                UIActivity.ActivityType(rawValue: "ph.telegra.Telegraph.Share"),
                UIActivity.ActivityType(rawValue: "com.toyopagroup.picaboo.share"), // Snapchat!
                UIActivity.ActivityType(rawValue: "com.fogcreek.trello.trelloshare"),
                UIActivity.ActivityType(rawValue: "com.hammerandchisel.discord.Share"),
                UIActivity.ActivityType(rawValue: "com.riffsy.RiffsyKeyboard.RiffsyShareExtension"), //GIF Keyboard by Tenor
                UIActivity.ActivityType(rawValue: "com.ifttt.ifttt.share"),
                UIActivity.ActivityType(rawValue: "com.getdropbox.Dropbox.ActionExtension"),
                UIActivity.ActivityType(rawValue: "wefwef.YammerShare"),
                UIActivity.ActivityType(rawValue: "pinterest.ShareExtension"),
                UIActivity.ActivityType(rawValue: "pinterest.ActionExtension"),
                UIActivity.ActivityType(rawValue: "us.zoom.videomeetings.Extension"),
            ]

            
            DispatchQueue.main.async {
                self.presentActivityView(activityViewController: activityViewController)
            }
            
            result(1)
            return
        }
        
        result(FlutterError(code: "ERROR_SHARE", message: "Arguments is not a dictionary [String:String]", details: arguments.debugDescription))
    }
    
    fileprivate func presentActivityView(activityViewController: UIActivityViewController) {
        // using this fake view controller to prevent this iOS 13+ dismissing the top view when sharing with "Save Image" option
        let fakeViewController = TransparentViewController()
        fakeViewController.modalPresentationStyle = .overFullScreen

        activityViewController.completionWithItemsHandler = { [weak fakeViewController] _, _, _, _ in
            if let presentingViewController = fakeViewController?.presentingViewController {
                presentingViewController.dismiss(animated: false, completion: nil)
            } else {
                fakeViewController?.dismiss(animated: false, completion: nil)
            }
        }

        UIApplication.topViewController()?.present(fakeViewController, animated: true) { [weak fakeViewController] in
            fakeViewController?.present(activityViewController, animated: true, completion: nil)
        }
    }
}

class WhatsAppActivityViewController: UIActivityViewController {

}

extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

class TransparentViewController: UIViewController {
    override func viewDidLoad() {
        view.backgroundColor = UIColor.clear
        view.isOpaque = false
    }
}


class WhatsAppActivityTextItem: NSObject, UIActivityItemSource {
    var text: String?

    convenience init(text: String) {
        self.init()
        self.text = text
    }

    // This will be called BEFORE showing the user the apps to share (first step)
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return self.text ?? ""
    }

    // This will be called AFTER the user has selected an app to share (second step)
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
      var text = ""
      if activityType?.rawValue == "net.whatsapp.WhatsApp.ShareExtension" {
          text = self.text ?? ""
      }
      return text
    }
}

class WhatsAppActivityFileItem: NSObject, UIActivityItemSource {
    var url: URL?

    convenience init(url: URL?) {
        self.init()
    
        self.url = url
    }

    // This will be called BEFORE showing the user the apps to share (first step)
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url
    }

    // This will be called AFTER the user has selected an app to share (second step)
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        switch activityType {
        case UIActivity.ActivityType(rawValue: "net.whatsapp.WhatsApp.ShareExtension"),
            UIActivity.ActivityType.copyToPasteboard:
            return url
        default:
            return nil

        }
    }
}

class WhatsAppActivityImageItem: NSObject, UIActivityItemSource {
    var image: UIImage!


    convenience init(image: UIImage) {
        self.init()
        self.image = image

    }

    // This will be called BEFORE showing the user the apps to share (first step)
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return image as Any
    }

    // This will be called AFTER the user has selected an app to share (second step)
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        switch activityType {
        case UIActivity.ActivityType(rawValue: "net.whatsapp.WhatsApp.ShareExtension"):
            return image
        default:
            return nil

        }
    }
}

@objc(WhatsAppUIActivity)
class WhatsAppUIActivity: UIActivity {
    var activityItems : [Any] = []
    
    convenience init(activityItems: [Any]) {
        self.init()
        self.textToShare = ""
        self.activityItems = activityItems
    }
    
    var textToShare: String?

    override class var activityCategory: UIActivity.Category {
        return .share
    }

    override var activityType: UIActivity.ActivityType? {
        return .whatsappuiactivity
    }

    override var activityTitle: String? {
        return "WhatsApp"
    }

    override var activityImage: UIImage? {
        return UIImage(named: "ic_whatsapp")
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        for activityItem in self.activityItems
        {
            if ((activityItem as AnyObject).isKind(of: WhatsAppActivityTextItem.self))
            {
                self.textToShare = (activityItem as! WhatsAppActivityTextItem).text;
                let whatsAppURL : URL = self.getURLFromMessage(message: self.textToShare!)
                return UIApplication.shared.canOpenURL(whatsAppURL)
            }
        }
        return true;
    }
    
    func getURLFromMessage(message:String) -> URL
     {
         var url = "whatsapp://"
         var sendMessage = message
         if (sendMessage != "")
         {
             sendMessage = sendMessage.addingPercentEncoding(withAllowedCharacters: (NSCharacterSet.urlQueryAllowed)) ?? ""
             url = "\(url)send?text=\(sendMessage)"
         }
         return URL(string: url)!
     }


    override func prepare(withActivityItems activityItems: [Any]) {
        for activityItem in self.activityItems{
            if ((activityItem as AnyObject).isKind(of: WhatsAppActivityTextItem.self))
            {
                let message = (activityItem as! WhatsAppActivityTextItem).text ?? ""
                let whatsAppURL : URL = self.getURLFromMessage(message: message)
                if(UIApplication.shared.canOpenURL(whatsAppURL)){
                    UIApplication.shared.open(whatsAppURL)
                }
                break;
            }
        }
        

    }

    override func perform() {
        activityDidFinish(true)
    }
}

extension UIActivity.ActivityType {
    static let whatsappuiactivity =
        UIActivity.ActivityType("net.whatsapp.WhatsApp.ShareExtension")

}

