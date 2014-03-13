//
//  UIImage+HanekeDemo.m
//  Haneke
//
//  Created by Hermes Pique on 13/02/14.
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

#import "UIImage+HanekeDemo.h"

@implementation UIImage (HanekeDemo)

- (UIImage*)demo_imageByCroppingRect:(CGRect)rect
{
    rect = CGRectMake(rect.origin.x * self.scale,
                      rect.origin.y * self.scale,
                      rect.size.width * self.scale,
                      rect.size.height * self.scale);
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *result = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}

- (UIImage*)demo_imageByDrawingColoredText:(NSString *)text
{
    const CGSize size = self.size;
    const CGFloat pointSize = MIN(size.width, size.height) / 2;
    UIFont *font = [UIFont boldSystemFontOfSize:pointSize];
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIColor *color = [UIImage demo_randomColor];
    NSDictionary *attributes = @{NSFontAttributeName : font, NSForegroundColorAttributeName : color};
    CGSize textSize = [text sizeWithAttributes:attributes];
    CGRect rect = CGRectMake((size.width - textSize.width) / 2, (size.height - textSize.height) / 2, textSize.width, textSize.height);
    [text drawInRect:rect withAttributes:attributes];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage*)demo_randomImage
{
    // Photo by Paul Sableman, taken from http://www.flickr.com/photos/pasa/8636568094
    UIImage *sample = [UIImage imageNamed:@"sample.jpg"];
    
    CGFloat width = arc4random_uniform(sample.size.width - 100) + 1 + 100;
    CGFloat height = arc4random_uniform(sample.size.height - 100) + 1 + 100;
    CGFloat x = arc4random_uniform(sample.size.width - width + 1);
    CGFloat y = arc4random_uniform(sample.size.height - height + 1);
    CGRect cropRect = CGRectMake(x, y, width, height);
    UIImage *cropped = [sample demo_imageByCroppingRect:cropRect];
    return cropped;
}

+ (UIColor*)demo_randomColor
{
    CGFloat r = arc4random_uniform(255 + 1) / 255.0;
    CGFloat g = arc4random_uniform(255 + 1) / 255.0;
    CGFloat b = arc4random_uniform(255 + 1) / 255.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:1];
}

@end
