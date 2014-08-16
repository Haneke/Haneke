//
//  UIImageHanekeUtilsTests.m
//  Haneke
//
//  Created by Hermés Piqué on 18/05/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UIImage+HanekeTestUtils.h"
#import "HNKCache.h"

// Implemented in HNKCache

@interface UIImage (Tests)

+ (UIImage *)hnk_decompressedImageWithData:(NSData*)data;

@end

@interface UIImageHanekeUtilsTests : XCTestCase

@end

@implementation UIImageHanekeUtilsTests

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

#pragma mark Utils

- (void)_testDecompressedImageWithDataUsingColor:(UIColor*)color colorSpace:(CGColorSpaceRef)colorSpace alphaInfo:(CGImageAlphaInfo)alphaInfo bitsPerComponent:(size_t)bitsPerComponent
{
    const CGSize size = CGSizeMake(10, 10);
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

@end
