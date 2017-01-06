//
//  SqueezeButton.swift
//  Expense Tracker
//
//  Created by Omar Alejel on 6/30/15.
//  Copyright © 2015 omar alejel. All rights reserved.
//

import UIKit

class SqueezeButton: UIButton {
    
    var completedSqueeze = true
    var pendingOut = false
    
    var shrinkTime = 0.2 ///animation time when shrinking
    var expandTime = 0.2 ///animation time when expanding
    
    var standardCornerRadius: CGFloat = 10
    
    ///Looks best when corners are round
    init(frame: CGRect, cornerRadius: CGFloat) {
        super.init(frame: frame)
        layer.cornerRadius = cornerRadius
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.cornerRadius = standardCornerRadius
    }
    
    ///Animates in when touches begin
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        press()
    }

    ///animates out when touch ends
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        rescaleButton()
    }
    
    func press() {
        UIView.animateKeyframes(withDuration: shrinkTime, delay: 0.0, options: UIViewKeyframeAnimationOptions.calculationModeCubic, animations: { () -> Void in
            self.completedSqueeze = false
            self.transform = self.transform.scaledBy(x: 1.2, y: 1.2)
            }) { (done) -> Void in
                self.completedSqueeze = true
                if self.pendingOut {
                    self.rescaleButton()
                    self.pendingOut = false
                }
        }
    }
    
    func rescaleButton() {
        if completedSqueeze {
            UIView.animateKeyframes(withDuration: expandTime, delay: 0.0, options: UIViewKeyframeAnimationOptions.calculationModeCubic, animations: { () -> Void in
                self.transform = self.transform.scaledBy(x: 1/1.2, y: 1/1.2)
                }) { (done) -> Void in
                    ///completion work once it rescales
            }
        } else {
            pendingOut = true
        }
    }
}
