//
//  HNKItem.m
//  Haneke
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKItem.h"

@implementation HNKItem

+ (HNKItem*)itemWithIndex:(NSUInteger)index
{
    HNKItem *item = [[HNKItem alloc] init];
    item.index = index;
    return item;
}

#pragma mark - HNKCacheEntity

- (NSString*)cacheId
{
    return [NSString stringWithFormat:@"%ld", (long)self.index];
}

- (NSData*)cacheOriginalData
{
    return nil;
}

- (UIImage*)cacheOriginalImage
{
    // Photo by Paul Sableman, taken from http://www.flickr.com/photos/pasa/8636568094
    UIImage *sample = [UIImage imageNamed:@"sample.jpg"];
    return [HNKItem drawText:self.cacheId inImage:sample];
}

#pragma mark - Utils

+(UIImage*)drawText:(NSString*)text inImage:(UIImage*)image
{
    UIFont *font = [UIFont boldSystemFontOfSize:image.size.height / 2];
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    NSDictionary *attributes = @{NSFontAttributeName : font, NSForegroundColorAttributeName : [UIColor whiteColor]};
    CGSize textSize = [text sizeWithAttributes:attributes];
    CGRect rect = CGRectMake((image.size.width - textSize.width) / 2, (image.size.height - textSize.height) / 2, textSize.width, textSize.height);
    [text drawInRect:rect withAttributes:attributes];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
