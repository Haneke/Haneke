//
//  NSString+HanekeTests.m
//  Haneke
//
//  Created by Hermes Pique on 8/30/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "HNKDiskCache.h"

@interface NSString (hnk_utils)

- (NSString*)hnk_MD5String;
- (BOOL)hnk_setValue:(NSString*)value forExtendedFileAttribute:(NSString*)attribute;
- (NSString*)hnk_stringByEscapingFilename;
- (NSString*)hnk_valueForExtendedFileAttribute:(NSString*)attribute;

@end

@interface NSString_HanekeTests : XCTestCase

@end

@implementation NSString_HanekeTests

- (void)tearStringByEscapingFilename
{
    XCTAssertEqualObjects([@"" hnk_stringByEscapingFilename], @"", @"");
    XCTAssertEqualObjects([@":" hnk_stringByEscapingFilename], @"%3A", @"");
    XCTAssertEqualObjects([@"/" hnk_stringByEscapingFilename], @"%2F", @"");
    XCTAssertEqualObjects([@" " hnk_stringByEscapingFilename], @" ", @"");
    XCTAssertEqualObjects([@"\\" hnk_stringByEscapingFilename], @"\\", @"");
    XCTAssertEqualObjects([@"test" hnk_stringByEscapingFilename], @"test", @"");
    XCTAssertEqualObjects([@"http://haneke.io" hnk_stringByEscapingFilename], @"http%3A%2F%2Fhaneke.io", @"");
    XCTAssertEqualObjects([@"/path/to/file" hnk_stringByEscapingFilename], @"%2Fpath%2Fto%2Ffile", @"");
}

@end
