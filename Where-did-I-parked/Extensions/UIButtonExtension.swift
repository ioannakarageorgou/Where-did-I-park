//
//  UIButtonExtension.swift
//  Where-did-I-parked
//
//  Created by Ioanna Karageorgou on 29/11/22.
//

import Foundation
import UIKit

@IBDesignable extension UIButton {

    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }

    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
    
    func addBlurEffect(style: UIBlurEffect.Style = .regular, cornerRadius: CGFloat = 0, padding: CGFloat = 0) {
        backgroundColor = .clear
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        blurView.isUserInteractionEnabled = false
        blurView.backgroundColor = .clear
        if cornerRadius > 0 {
            blurView.layer.cornerRadius = cornerRadius
            blurView.layer.masksToBounds = true
        }
        self.insertSubview(blurView, at: 0)

        blurView.translatesAutoresizingMaskIntoConstraints = false
        self.leadingAnchor.constraint(equalTo: blurView.leadingAnchor, constant: padding).isActive = true
        self.trailingAnchor.constraint(equalTo: blurView.trailingAnchor, constant: -padding).isActive = true
        self.topAnchor.constraint(equalTo: blurView.topAnchor, constant: padding).isActive = true
        self.bottomAnchor.constraint(equalTo: blurView.bottomAnchor, constant: -padding).isActive = true

        if let imageView = self.imageView {
            imageView.backgroundColor = .clear
            self.bringSubviewToFront(imageView)
        }
    }
}
