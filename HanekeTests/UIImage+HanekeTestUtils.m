//
//  UIImage+HanekeTestUtils.m
//  Haneke
//
//  Created by Hermes on 20/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UIImage+HanekeTestUtils.h"

@implementation UIImage (HanekeTestUtils)

+ (UIImage*)hnk_imageWithColor:(UIColor*)color size:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
