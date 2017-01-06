//
//  CameraConfigs.swift
//  CameraRG
//
//  Created by wangkan on 2017/1/4.
//  Copyright © 2017年 rockgarden. All rights reserved.
//

import Foundation

public struct CameraConfigs {}


func CreateImageWithColor(_ color: UIColor) -> UIImage {
    let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
    UIGraphicsBeginImageContext(rect.size);
    let context = UIGraphicsGetCurrentContext()
    
    context?.setFillColor(color.cgColor)
    context?.fill(rect)
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image!
}


public let alphaLightGray = UIColor(red: 160, green: 160, blue: 160, alpha: 0.6)
