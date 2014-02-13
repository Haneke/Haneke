//
//  UIImage+HanekeDemo.m
//  Haneke
//
//  Created by Hermes on 13/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UIImage+HanekeDemo.h"

@implementation UIImage (HanekeDemo)

- (UIImage*)imageByCroppingRect:(CGRect)rect
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

- (UIImage*)imageByDrawingText:(NSString *)text
{
    CGSize size = self.size;
    UIFont *font = [UIFont boldSystemFontOfSize:size.height / 2];
    UIGraphicsBeginImageContext(self.size);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIColor *color = [UIImage randomColor];
    NSDictionary *attributes = @{NSFontAttributeName : font, NSForegroundColorAttributeName : color};
    CGSize textSize = [text sizeWithAttributes:attributes];
    CGRect rect = CGRectMake((size.width - textSize.width) / 2, (size.height - textSize.height) / 2, textSize.width, textSize.height);
    [text drawInRect:rect withAttributes:attributes];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIColor*)randomColor
{
    CGFloat r = arc4random_uniform(255 + 1) / 255.0;
    CGFloat g = arc4random_uniform(255 + 1) / 255.0;
    CGFloat b = arc4random_uniform(255 + 1) / 255.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:1];
}

@end
