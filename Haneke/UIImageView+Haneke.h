//
//  UIImageView+Haneke.h
//  Haneke
//
//  Created by Hermes on 12/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (Haneke)

- (void)hnk_setImageFromFile:(NSString*)path;

- (void)hnk_setImage:(UIImage*)image withKey:(NSString*)key;

@end
