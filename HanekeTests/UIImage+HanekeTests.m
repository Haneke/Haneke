//
//  UIImage+HanekeTests.m
//  Haneke
//
//  Created by Hermés Piqué on 18/05/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIImage+Haneke.h"
#import "UIImage+HanekeTestUtils.h"
@import ImageIO;
@import MobileCoreServices;

typedef NS_ENUM(NSInteger, HNKExifOrientation) {
    HNKExifOrientationUp = 1,
    HNKExifOrientationDown = 3,
    HNKExifOrientationLeft = 8,
    HNKExifOrientationRight = 6,
    HNKExifOrientationUpMirrored = 2,
    HNKExifOrientationDownMirrored = 4,
    HNKExifOrientationLeftMirrored = 5,
    HNKExifOrientationRightMirrored= 7,
};

@interface UIImage_HanekeTests : XCTestCase

@end

@implementation UIImage_HanekeTests

- (void)testDecompressedImageWithData_UIGraphicsContext_OpaqueYES
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10) opaque:YES];
    NSData *data = UIImagePNGRepresentation(image);
    
    UIImage *decompressedImage = [UIImage hnk_decompressedImageWithData:data];
    
    XCTAssertTrue([decompressedImage hnk_isEqualToImage:image], @"");
}

- (void)testDecompressedImageWithData_UIGraphicsContext_OpaqueNO
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10) opaque:NO];
    NSData *data = UIImagePNGRepresentation(image);
    
    UIImage *decompressedImage = [UIImage hnk_decompressedImageWithData:data];
    
    XCTAssertTrue([decompressedImage hnk_isEqualToImage:image], @"");
}

- (void)testDecompressedImageWithData_RGBA
{
    const CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    [self _testDecompressedImageWithDataUsingColor:[UIColor colorWithRed:255 green:0 blue:0 alpha:0.5]
                                           colorSpace:colorSpaceRef
                                            alphaInfo:kCGImageAlphaPremultipliedLast
                                     bitsPerComponent:8];
    CGColorSpaceRelease(colorSpaceRef);
}

- (void)testDecompressedImageWithData_ARGB
{
    const CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    [self _testDecompressedImageWithDataUsingColor:[UIColor colorWithRed:255 green:0 blue:0 alpha:0.5]
                                           colorSpace:colorSpaceRef
                                            alphaInfo:kCGImageAlphaPremultipliedFirst
                                     bitsPerComponent:8];
    CGColorSpaceRelease(colorSpaceRef);
}

- (void)testDecompressedImageWithData_RGBX
{
    const CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    [self _testDecompressedImageWithDataUsingColor:[UIColor redColor]
                                           colorSpace:colorSpaceRef
                                            alphaInfo:kCGImageAlphaNoneSkipLast
                                     bitsPerComponent:8];
    CGColorSpaceRelease(colorSpaceRef);
}

- (void)testDecompressedImageWithData_XRGB
{
    const CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    [self _testDecompressedImageWithDataUsingColor:[UIColor redColor]
                                           colorSpace:colorSpaceRef
                                            alphaInfo:kCGImageAlphaNoneSkipFirst
                                     bitsPerComponent:8];
    CGColorSpaceRelease(colorSpaceRef);
}

- (void)testDecompressedImageWithData_Gray_kCGImageAlphaNone
{
    const CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceGray();
    [self _testDecompressedImageWithDataUsingColor:[UIColor grayColor]
                                           colorSpace:colorSpaceRef
                                            alphaInfo:kCGImageAlphaNone
                                     bitsPerComponent:8];
    CGColorSpaceRelease(colorSpaceRef);
}

- (void)testDecompressedImageWithData_OrientationUp
{
    [self _testDecompressedImageWithOrientation:HNKExifOrientationUp];
}

- (void)testDecompressedImageWithData_OrientationDown
{
    [self _testDecompressedImageWithOrientation:HNKExifOrientationDown];
}

- (void)testDecompressedImageWithData_OrientationLeft
{
    [self _testDecompressedImageWithOrientation:HNKExifOrientationLeft];
}

- (void)testDecompressedImageWithData_OrientationRight
{
    [self _testDecompressedImageWithOrientation:HNKExifOrientationRight];
}

- (void)testDecompressedImageWithData_OrientationUpMirrored
{
    [self _testDecompressedImageWithOrientation:HNKExifOrientationUpMirrored];
}

- (void)testDecompressedImageWithData_OrientationDownMirrored
{
    [self _testDecompressedImageWithOrientation:HNKExifOrientationDownMirrored];
}

- (void)testDecompressedImageWithData_OrientationLeftMirrored
{
    [self _testDecompressedImageWithOrientation:HNKExifOrientationLeftMirrored];
}

- (void)testDecompressedImageWithData_OrientationRightMirrored
{
    [self _testDecompressedImageWithOrientation:HNKExifOrientationRightMirrored];
}

#pragma mark Utils

- (void)_testDecompressedImageWithDataUsingColor:(UIColor*)color colorSpace:(CGColorSpaceRef)colorSpace alphaInfo:(CGImageAlphaInfo)alphaInfo bitsPerComponent:(size_t)bitsPerComponent
{
    const CGSize size = CGSizeMake(10, 20);
    const CGBitmapInfo bitmapInfo = alphaInfo | kCGBitmapByteOrderDefault;
    const CGContextRef context = CGBitmapContextCreate(NULL,
                                                       size.width,
                                                       size.height,
                                                       bitsPerComponent,
                                                       0,
                                                       colorSpace,
                                                       bitmapInfo);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    const CGImageRef imageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    NSData *data = UIImagePNGRepresentation(image);
    
    UIImage *decompressedImage = [UIImage hnk_decompressedImageWithData:data];
    
    XCTAssertTrue([decompressedImage hnk_isEqualToImage:image], @"");
    
    CGImageRelease(imageRef);
}

- (void)_testDecompressedImageWithOrientation:(HNKExifOrientation)orientation
{
    // Create a gradient image to truly test orientation
    UIImage *gradientImage = [UIImage hnk_imageGradientFromColor:[UIColor redColor]
                                                         toColor:[UIColor greenColor]
                                                            size:CGSizeMake(10, 20)];

    // Use TIFF because PNG doesn't store EXIF orientation
    NSDictionary *exifProperties = @{(__bridge NSString*)kCGImagePropertyOrientation : @(orientation)};
    NSMutableData *data = [NSMutableData data];
    CGImageDestinationRef imageDestinationRef = CGImageDestinationCreateWithData((__bridge  CFMutableDataRef)(data), kUTTypeTIFF, 1, NULL);
    CGImageDestinationAddImage(imageDestinationRef, gradientImage.CGImage, (__bridge CFDictionaryRef)exifProperties);
    CGImageDestinationFinalize(imageDestinationRef);
    CFRelease(imageDestinationRef);
    
    UIImage *image = [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
    
    UIImage *decompressedImage = [UIImage hnk_decompressedImageWithData:data];
    
    XCTAssertTrue([decompressedImage hnk_isEqualToImage:image], @"");
}

@end
