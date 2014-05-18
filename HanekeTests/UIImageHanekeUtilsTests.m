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

+ (UIImage *)hnk_decompressedImageWithCGImage:(CGImageRef)imageRef;

@end

@interface UIImageHanekeUtilsTests : XCTestCase

@end

@implementation UIImageHanekeUtilsTests

- (void)testDecompressedImageWithCGImage_UIGraphicsContext_OpaqueYES
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10) opaque:YES];
    CGImageRef imageRef = image.CGImage;
    
    UIImage *decompressedImage = [UIImage hnk_decompressedImageWithCGImage:imageRef];
    
    XCTAssertTrue([decompressedImage hnk_isEqualToCGImage:imageRef], @"");
}

- (void)testDecompressedImageWithCGImage_UIGraphicsContext_OpaqueNO
{
    UIImage *image = [UIImage hnk_imageWithColor:[UIColor redColor] size:CGSizeMake(10, 10) opaque:NO];
    CGImageRef imageRef = image.CGImage;
    
    UIImage *decompressedImage = [UIImage hnk_decompressedImageWithCGImage:imageRef];
    
    XCTAssertTrue([decompressedImage hnk_isEqualToCGImage:imageRef], @"");
}

- (void)testDecompressedImageWithCGImage_RGBA
{
    const CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    [self _testDecompressedImageWithCGImageUsingColor:[UIColor colorWithRed:255 green:0 blue:0 alpha:0.5]
                                           colorSpace:colorSpaceRef
                                            alphaInfo:kCGImageAlphaPremultipliedLast
                                     bitsPerComponent:8];
    CGColorSpaceRelease(colorSpaceRef);
}

- (void)testDecompressedImageWithCGImage_ARGB
{
    const CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    [self _testDecompressedImageWithCGImageUsingColor:[UIColor colorWithRed:255 green:0 blue:0 alpha:0.5]
                                           colorSpace:colorSpaceRef
                                            alphaInfo:kCGImageAlphaPremultipliedFirst
                                     bitsPerComponent:8];
    CGColorSpaceRelease(colorSpaceRef);
}

- (void)testDecompressedImageWithCGImage_RGBX
{
    const CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    [self _testDecompressedImageWithCGImageUsingColor:[UIColor redColor]
                                           colorSpace:colorSpaceRef
                                            alphaInfo:kCGImageAlphaNoneSkipLast
                                     bitsPerComponent:8];
    CGColorSpaceRelease(colorSpaceRef);
}

- (void)testDecompressedImageWithCGImage_XRGB
{
    const CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    [self _testDecompressedImageWithCGImageUsingColor:[UIColor redColor]
                                           colorSpace:colorSpaceRef
                                            alphaInfo:kCGImageAlphaNoneSkipFirst
                                     bitsPerComponent:8];
    CGColorSpaceRelease(colorSpaceRef);
}

- (void)testDecompressedImageWithCGImage_Gray_kCGImageAlphaNone
{
    const CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceGray();
    [self _testDecompressedImageWithCGImageUsingColor:[UIColor grayColor]
                                           colorSpace:colorSpaceRef
                                            alphaInfo:kCGImageAlphaNone
                                     bitsPerComponent:8];
    CGColorSpaceRelease(colorSpaceRef);
}

#pragma mark Utils

- (void)_testDecompressedImageWithCGImageUsingColor:(UIColor*)color colorSpace:(CGColorSpaceRef)colorSpace alphaInfo:(CGImageAlphaInfo)alphaInfo bitsPerComponent:(size_t)bitsPerComponent
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
    
    UIImage *decompressedImage = [UIImage hnk_decompressedImageWithCGImage:imageRef];
    
    XCTAssertTrue([decompressedImage hnk_isEqualToCGImage:imageRef], @"");
    
    CGImageRelease(imageRef);
}

@end
