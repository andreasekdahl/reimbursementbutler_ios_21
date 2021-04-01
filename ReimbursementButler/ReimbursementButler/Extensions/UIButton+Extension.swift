//
//  UIButton+Extension.swift
//
import UIKit
import Foundation

extension UIButton {
    func loadingIndicator(_ show: Bool) {
        let tag = 888844
        if show {
            setEnabled(false)
            let indicator = UIActivityIndicatorView()
            let buttonHeight = self.bounds.size.height
            let buttonWidth = self.bounds.size.width
            indicator.center = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
            indicator.tag = tag
            self.addSubview(indicator)
            indicator.startAnimating()
        } else {
            setEnabled(true)
            if let indicator = self.viewWithTag(tag) as? UIActivityIndicatorView {
                indicator.stopAnimating()
                indicator.removeFromSuperview()
            }
        }
    }
    func setEnabled(_ enabled:Bool) {
        if enabled {
            self.alpha = 1.0
            self.isEnabled = true
        } else {
            self.alpha = 0.5
            self.isEnabled = false
        }

    }
}
