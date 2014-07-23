//
//  UIImage+Haneke.m
//  Haneke
//
//  Created by Hermes Pique on 7/23/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UIImage+Haneke.h"
@import ImageIO;

@implementation UIImage (Haneke)

+ (UIImage*)hnk_decompressedImageWithData:(NSData*)data
{
    const CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    
    // Ideally we would simply use kCGImageSourceShouldCacheImmediately but as of iOS 7.1 it locks on copyImageBlockSetJPEG which makes it dangerous.
    // CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, (__bridge CFDictionaryRef)@{(id)kCGImageSourceShouldCacheImmediately: @YES});
    
    UIImage *image = nil;
    const CGImageRef imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
    if (imageRef)
    {
        image = [UIImage hnk_decompressedImageWithCGImage:imageRef];
        CGImageRelease(imageRef);
    }
    CFRelease(sourceRef);
    
    return image;
}

+ (UIImage*)hnk_decompressedImageWithCGImage:(CGImageRef)imageRef
{
    const CGBitmapInfo originalBitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    // See: http://stackoverflow.com/questions/23723564/which-cgimagealphainfo-should-we-use
    const uint32_t alphaInfo = (originalBitmapInfo & kCGBitmapAlphaInfoMask);
    CGBitmapInfo bitmapInfo = originalBitmapInfo;
    switch (alphaInfo)
    {
        case kCGImageAlphaNone:
            bitmapInfo &= ~kCGBitmapAlphaInfoMask;
            bitmapInfo |= kCGImageAlphaNoneSkipFirst;
            break;
        case kCGImageAlphaPremultipliedFirst:
        case kCGImageAlphaPremultipliedLast:
        case kCGImageAlphaNoneSkipFirst:
        case kCGImageAlphaNoneSkipLast:
            break;
        case kCGImageAlphaOnly:
        case kCGImageAlphaLast:
        case kCGImageAlphaFirst:
        { // Unsupported
            return [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        }
            break;
    }
    
    const CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    const CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    const CGContextRef context = CGBitmapContextCreate(NULL,
                                                       imageSize.width,
                                                       imageSize.height,
                                                       CGImageGetBitsPerComponent(imageRef),
                                                       0,
                                                       colorSpace,
                                                       bitmapInfo);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image;
    const CGFloat scale = [UIScreen mainScreen].scale;
    if (context)
    {
        const CGRect imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
        CGContextDrawImage(context, imageRect, imageRef);
        const CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
        CGContextRelease(context);
        image = [UIImage imageWithCGImage:decompressedImageRef scale:scale orientation:UIImageOrientationUp];
        CGImageRelease(decompressedImageRef);
    }
    else
    {
        image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
    }
    return image;
}

@end
