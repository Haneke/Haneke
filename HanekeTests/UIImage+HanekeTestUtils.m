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

- (BOOL)hnk_isEqualToImage:(UIImage*)image
{
    NSData *data = [image hnk_normalizedData];
    NSData *originalData = [self hnk_normalizedData];
    return [originalData isEqualToData:data];
}

- (NSData*)hnk_normalizedData
{
    UIGraphicsBeginImageContext(self.size);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];
    UIImage *drawnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return UIImagePNGRepresentation(drawnImage);
}

@end
