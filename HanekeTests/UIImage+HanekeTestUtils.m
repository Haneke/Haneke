//
//  UIImage+HanekeTestUtils.m
//  Haneke
//
//  Created by Hermes Pique on 20/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "UIImage+HanekeTestUtils.h"

@implementation UIImage (HanekeTestUtils)

+ (UIImage*)hnk_imageWithColor:(UIColor*)color size:(CGSize)size
{
    return [UIImage hnk_imageWithColor:color size:size opaque:YES];
}

+ (UIImage*)hnk_imageWithColor:(UIColor*)color size:(CGSize)size opaque:(BOOL)opaque
{
    UIGraphicsBeginImageContextWithOptions(size, opaque, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

+ (UIImage*)hnk_imageGradientFromColor:(UIColor*)fromColor toColor:(UIColor*)toColor size:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, NO /* opaque */, 0 /* scale */);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    const size_t gradientNumberOfLocations = 2;
    const CGFloat gradientLocations[2] = { 0.0, 1.0 };
    CGFloat r1, g1, b1, a1;
    [fromColor getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    CGFloat r2, g2, b2, a2;
    [toColor getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    const CGFloat gradientComponents[8] = {r1, g1, b1, a1, r2, g2, b2, a2};
    CGGradientRef gradient = CGGradientCreateWithColorComponents (colorspace, gradientComponents, gradientLocations, gradientNumberOfLocations);
    
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, size.height), 0);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorspace);
    return image;
}

- (BOOL)hnk_isEqualToImage:(UIImage*)image
{
    NSData *data = [image hnk_normalizedData];
    NSData *originalData = [self hnk_normalizedData];
    return [originalData isEqualToData:data];
}

- (NSData*)hnk_normalizedData
{
    const CGSize pixelSize = CGSizeMake(self.size.width * self.scale, self.size.height * self.scale);
    UIGraphicsBeginImageContext(pixelSize);
    [self drawInRect:CGRectMake(0, 0, pixelSize.width, pixelSize.height)];
    UIImage *drawnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return UIImagePNGRepresentation(drawnImage);
}

@end
