//
//  HNKDemoCollectionViewCell.m
//  Haneke
//
//  Created by Hermes on 13/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKDemoCollectionViewCell.h"
#import "UIImageView+Haneke.h"

@implementation HNKDemoCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _imageView = [[UIImageView alloc] initWithFrame:self.contentView.bounds];
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:_imageView];
    }
    return self;
}

- (void)prepareForReuse
{
    [self.imageView hnk_cancelImageRequest];
    self.imageView.image = nil;
}

@end
