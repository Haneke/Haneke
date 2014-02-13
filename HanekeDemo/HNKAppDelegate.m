//
//  HNKAppDelegate.m
//  HanekeDemo
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKAppDelegate.h"
#import "HNKViewController.h"

@implementation HNKAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self prepareImages];
    HNKViewController *vc = [HNKViewController new];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)prepareImages
{
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    for (NSUInteger i = 0; i < 100; i++)
    {
        @autoreleasepool {
            NSLog(@"Creating image %ld of %d", (long)i + 1, 100);
            UIImage *image = [self imageWithIndex:i];
            NSData *data = UIImageJPEGRepresentation(image, 1);
            NSString *fileName = [NSString stringWithFormat:@"sample%ld.jpg", (long)i];
            NSString *path = [documents stringByAppendingPathComponent:fileName];
            [data writeToFile:path atomically:YES];
        }
    }
}

#pragma mark - Utils

- (UIImage*)imageWithIndex:(NSUInteger)index
{
    // Photo by Paul Sableman, taken from http://www.flickr.com/photos/pasa/8636568094
    UIImage *sample = [UIImage imageNamed:@"sample.jpg"];
    NSString *indexString = [NSString stringWithFormat:@"%ld", (long)index];
    return [self drawText:indexString inImage:sample];
}

- (UIImage*)drawText:(NSString*)text inImage:(UIImage*)image
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
