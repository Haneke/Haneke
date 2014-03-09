//
//  UIImage+HanekeDemo.h
//  Haneke
//
//  Created by Hermes on 13/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (HanekeDemo)

- (UIImage*)demo_imageByCroppingRect:(CGRect)rect;

- (UIImage*)demo_imageByDrawingColoredText:(NSString*)text;

+ (UIImage*)demo_randomImage;

@end
