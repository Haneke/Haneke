//
//  UIImage+HanekeDemo.h
//  Haneke
//
//  Created by Hermes on 13/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (HanekeDemo)

- (UIImage*)imageByCroppingRect:(CGRect)rect;

- (UIImage*)imageByDrawingText:(NSString*)text;

@end
