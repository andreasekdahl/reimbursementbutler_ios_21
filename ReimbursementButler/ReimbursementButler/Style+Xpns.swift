//
//  Style+Xpns.swift
//
import UIKit
import Foundation

extension Style {
    static var xpnsApp: Style {
        return Style(
            backgroundColor: .black,
            preferredStatusBarStyle: .lightContent,
            attributesForStyle: { $0.xpnsAppAttributes }
        )
    }
}

private extension Style.TextStyle {
    var xpnsAppAttributes: Style.TextAttributes {
        switch self {
        case .navigationBar:
            return Style.TextAttributes(font: .xpnsAppTitle, color: .xpnsAppGreen, backgroundColor: .black)
        case .title:
            return Style.TextAttributes(font: .xpnsAppTitle, color: .xpnsAppGreen)
        case .subtitle:
            return Style.TextAttributes(font: .xpnsAppSubtitle, color: .xpnsAppBlue)
        case .body:
            return Style.TextAttributes(font: .xpnsAppBody, color: .black, backgroundColor: .white)
        case .button:
            return Style.TextAttributes(font: .xpnsAppSubtitle, color: .white, backgroundColor: .xpnsAppRed)
        }
    }
}

extension UIColor {
    static var xpnsAppRed: UIColor {
        return UIColor(red: 1, green: 0.1, blue: 0.1, alpha: 1)
    }
    static var xpnsAppGreen: UIColor {
        return UIColor(red: 0, green: 1, blue: 0, alpha: 1)
    }
    static var xpnsAppBlue: UIColor {
        return UIColor(red: 0, green: 0.1, blue: 0.9, alpha: 1)
    }
    static var xpnsAppGrey: UIColor {
        return UIColor(white: 0.5, alpha: 1)
    }
    static var xpnsAppLightGrey: UIColor {
        return UIColor(white: 0.7, alpha: 1)
    }
    static var xpnsAppDarkGrey: UIColor {
        return UIColor(white: 0.3, alpha: 1)
    }
}

extension UIFont {
    static var xpnsAppTitle: UIFont {
        return UIFont.systemFont(ofSize: 17)
    }
    static var xpnsAppSubtitle: UIFont {
        return UIFont.systemFont(ofSize: 15)
    }
    static var xpnsAppBody: UIFont {
        return UIFont.systemFont(ofSize: 14)
    }
}
