//
//  HNKImageViewEntity.m
//  Pods
//
//  Created by Aleix Ventayol on 26/05/14.
//
//

#import "HNKImageViewEntity.h"
#import "HNKCache.h"

@implementation HNKImageViewEntity {
    NSString *_key;
    UIImage *_image;
    NSData *_data;
}

+ (HNKImageViewEntity*)entityWithImage:(UIImage*)image key:(NSString*)key
{
    HNKImageViewEntity *entity = [[HNKImageViewEntity alloc] init];
    entity->_key = key.copy;
    entity->_image = image;
    return entity;
}

+ (HNKImageViewEntity*)entityWithData:(NSData*)data key:(NSString*)key
{
    HNKImageViewEntity *entity = [[HNKImageViewEntity alloc] init];
    entity->_key = key.copy;
    entity->_data = data;
    return entity;
}

- (NSString*)cacheKey
{
    return _key;
}

- (UIImage*)cacheOriginalImage
{
    return _image;
}

- (NSData*)cacheOriginalData
{
    return _data;
}

@end
