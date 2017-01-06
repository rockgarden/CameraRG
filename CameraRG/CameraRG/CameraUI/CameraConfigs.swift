//
//  CameraConfigs.swift
//  CameraRG
//
//  Created by wangkan on 2017/1/4.
//  Copyright © 2017年 rockgarden. All rights reserved.
//

import Foundation


public struct CameraConfigs {}

func imageFromContextOfSize(_ size: CGSize, closure: @escaping(_ size:CGSize) -> ()) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    closure(size)
    let result = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return result!
}

func imageOfSize(_ size:CGSize, closure: @escaping (_ size:CGSize) -> ()) -> UIImage {
    if #available(iOS 10.0, *) {
        let r = UIGraphicsImageRenderer(size:size)
        return r.image {
            _ in closure(size)
        }
    } else {
        return imageFromContextOfSize(size, closure: closure)
    }
}

func lend<T> (_ closure:(T)->()) -> T where T:NSObject {
    let orig = T()
    closure(orig)
    return orig
}


extension UIColor {
    
    static var applicationGreenColor: UIColor {
        return UIColor(red: 0.255, green: 0.804, blue: 0.470, alpha: 1)
    }

    static var applicationBlueColor: UIColor {
        return UIColor(red: 0.333, green: 0.784, blue: 1, alpha: 1)
    }

    static var applicationPurpleColor: UIColor {
        return UIColor(red: 0.659, green: 0.271, blue: 0.988, alpha: 1)
    }

    static var applicationAlphaGray: UIColor {
        return UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    }
}

extension CGRect {
    init(_ x:CGFloat, _ y:CGFloat, _ w:CGFloat, _ h:CGFloat) {
        self.init(x:x, y:y, width:w, height:h)
    }
}

extension CGSize {
    init(_ width:CGFloat, _ height:CGFloat) {
        self.init(width:width, height:height)
    }
}

extension CGPoint {
    init(_ x:CGFloat, _ y:CGFloat) {
        self.init(x:x, y:y)
    }
}

extension CGVector {
    init (_ dx:CGFloat, _ dy:CGFloat) {
        self.init(dx:dx, dy:dy)
    }
}

/// Set the button's title for normal state.
let normalTitleAttributes = [
    NSForegroundColorAttributeName: UIColor.yellow,
    NSFontAttributeName: UIFont(name:"GillSans-Bold", size:14)!
    ] as [String : Any]


let RoundedLine = imageOfSize(CGSize(44,44)) {size in
    UIColor.applicationAlphaGray.setFill()
    UIBezierPath(roundedRect: CGRect(0,0,size.width,size.height), cornerRadius: size.height/4).stroke()
}

let ArcLine = imageOfSize(CGSize(44,44)) {size in
    UIColor.applicationAlphaGray.setFill()
    //UIColor.white.setStroke()
    let r = size.width/2 - 1
    UIBezierPath(arcCenter: CGPoint(r,r), radius: r, startAngle: 0, endAngle: CGFloat(M_PI * 2), clockwise: true).stroke()
}

let EllipseShape = imageOfSize(CGSize(44,44)) {size in
    let con = UIGraphicsGetCurrentContext()!
    con.addEllipse(in: CGRect(0,0,size.width,size.height))
    con.setFillColor(UIColor.applicationAlphaGray.cgColor)
    con.fillPath()
}

let CircleShape = imageOfSize(CGSize(44,44)) {size in
    let con = UIGraphicsGetCurrentContext()!
    let r = size.width/2
    con.addArc(center: CGPoint(r,r), radius: r, startAngle: 0, endAngle: CGFloat(M_PI * 2), clockwise: true)
    con.setFillColor(UIColor.applicationAlphaGray.cgColor)
    con.fillPath()
}
