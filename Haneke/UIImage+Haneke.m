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

+ (UIImage*)hnk_decompressedImageWithImage:(UIImage*)originalImage
{
    // Ideally we would simply use kCGImageSourceShouldCacheImmediately but as of iOS 7.1 it locks on copyImageBlockSetJPEG which makes it dangerous.
    // const CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    // CGImageRef imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, (__bridge CFDictionaryRef)@{(id)kCGImageSourceShouldCacheImmediately: @YES});
    
    CGImageRef originalImageRef = originalImage.CGImage;
    const CGBitmapInfo originalBitmapInfo = CGImageGetBitmapInfo(originalImageRef);
    
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
            return originalImage;
        }
            break;
    }
    
    const CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    const CGSize pixelSize = CGSizeMake(originalImage.size.width * originalImage.scale, originalImage.size.height * originalImage.scale);
    const CGContextRef context = CGBitmapContextCreate(NULL,
                                                       pixelSize.width,
                                                       pixelSize.height,
                                                       CGImageGetBitsPerComponent(originalImageRef),
                                                       0,
                                                       colorSpace,
                                                       bitmapInfo);
    CGColorSpaceRelease(colorSpace);
    
    UIImage *image;
    if (!context) return originalImage;
    
    const CGRect imageRect = CGRectMake(0, 0, pixelSize.width, pixelSize.height);
    UIGraphicsPushContext(context);
    
    // Flip coordinate system. See: http://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage
    CGContextTranslateCTM(context, 0, pixelSize.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // UIImage and drawInRect takes into account image orientation, unlike CGContextDrawImage.
    [originalImage drawInRect:imageRect];
    UIGraphicsPopContext();
    const CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    const CGFloat scale = [UIScreen mainScreen].scale;
    image = [UIImage imageWithCGImage:decompressedImageRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(decompressedImageRef);
    
    return image;
}

@end
