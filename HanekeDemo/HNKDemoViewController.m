//
//  HNKDemoViewController.m
//  Haneke
//
//  Created by Hermes Pique on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "HNKDemoViewController.h"
#import "Haneke.h"
#import "HNKDemoCollectionViewCell.h"
#import "UIImage+HanekeDemo.h" // To create random images

#define HNK_USE_CUSTOM_FORMAT 0
#define HNK_LOCAL_IMAGES 0
#define HNK_USE_GIFS 1

#if HNK_USE_GIFS
// This is a Gif serilaization snippet taken from https://github.com/mattt/AnimatedGIFImageSerialization

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>

NSString * const AnimatedGIFImageErrorDomain = @"com.compuserve.gif.image.error";

__attribute__((overloadable)) UIImage * UIImageWithAnimatedGIFData(NSData *data, CGFloat scale, NSTimeInterval duration, NSError * __autoreleasing *error) {
    if (!data) {
        return nil;
    }
    
    NSDictionary *userInfo = nil;
    {
        NSMutableDictionary *mutableOptions = [NSMutableDictionary dictionary];
        [mutableOptions setObject:@(YES) forKey:(NSString *)kCGImageSourceShouldCache];
        [mutableOptions setObject:(NSString *)kUTTypeGIF forKey:(NSString *)kCGImageSourceTypeIdentifierHint];
        
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, (__bridge CFDictionaryRef)mutableOptions);
        
        size_t numberOfFrames = CGImageSourceGetCount(imageSource);
        NSMutableArray *mutableImages = [NSMutableArray arrayWithCapacity:numberOfFrames];
        
        NSTimeInterval calculatedDuration = 0.0f;
        for (size_t idx = 0; idx < numberOfFrames; idx++) {
            CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSource, idx, (__bridge CFDictionaryRef)mutableOptions);
            
            NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, idx, NULL);
            calculatedDuration += [[[properties objectForKey:(__bridge NSString *)kCGImagePropertyGIFDictionary] objectForKey:(__bridge  NSString *)kCGImagePropertyGIFDelayTime] doubleValue];
            
            [mutableImages addObject:[UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp]];
            
            CGImageRelease(imageRef);
        }
        
        CFRelease(imageSource);
        
        if (numberOfFrames == 1) {
            return [mutableImages firstObject];
        } else {
            return [UIImage animatedImageWithImages:mutableImages duration:(duration <= 0.0f ? calculatedDuration : duration)];
        }
    }
_error: {
    if (error) {
        *error = [[NSError alloc] initWithDomain:AnimatedGIFImageErrorDomain code:-1 userInfo:userInfo];
    }
    
    return nil;
}
}

__attribute__((overloadable)) UIImage * UIImageWithAnimatedGIFData(NSData *data) {
    return UIImageWithAnimatedGIFData(data, [[UIScreen mainScreen] scale], 0.0f, nil);
}

static BOOL AnimatedGifDataIsValid(NSData *data) {
    if (data.length > 4) {
        const unsigned char * bytes = [data bytes];
        
        return bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46;
    }
    
    return NO;
}

__attribute__((overloadable)) NSData * UIImageAnimatedGIFRepresentation(UIImage *image, NSTimeInterval duration, NSUInteger loopCount, NSError * __autoreleasing *error) {
    if (!image.images) {
        return nil;
    }
    
    NSDictionary *userInfo = nil;
    {
        size_t frameCount = image.images.count;
        NSTimeInterval frameDuration = (duration <= 0.0 ? image.duration / frameCount : duration / frameCount);
        NSDictionary *frameProperties = @{
                                          (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                                                  (__bridge NSString *)kCGImagePropertyGIFDelayTime: @(frameDuration)
                                                  }
                                          };
        
        NSMutableData *mutableData = [NSMutableData data];
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)mutableData, kUTTypeGIF, frameCount, NULL);
        
        NSDictionary *imageProperties = @{ (__bridge NSString *)kCGImagePropertyGIFDictionary: @{
                                                   (__bridge NSString *)kCGImagePropertyGIFLoopCount: @(loopCount)
                                                   }
                                           };
        CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)imageProperties);
        
        for (size_t idx = 0; idx < image.images.count; idx++) {
            CGImageDestinationAddImage(destination, [[image.images objectAtIndex:idx] CGImage], (__bridge CFDictionaryRef)frameProperties);
        }
        
        BOOL success = CGImageDestinationFinalize(destination);
        CFRelease(destination);
        
        if (!success) {
            userInfo = @{
                         NSLocalizedDescriptionKey: NSLocalizedString(@"Could not finalize image destination", nil)
                         };
            
            goto _error;
        }
        
        return [NSData dataWithData:mutableData];
    }
_error: {
    if (error) {
        *error = [[NSError alloc] initWithDomain:AnimatedGIFImageErrorDomain code:-1 userInfo:userInfo];
    }
    
    return nil;
}
}

__attribute__((overloadable)) NSData * UIImageAnimatedGIFRepresentation(UIImage *image) {
    return UIImageAnimatedGIFRepresentation(image, 0.0f, 0, nil);
}

@interface HNKGifNetworkFetcher : HNKNetworkFetcher

@end

@implementation HNKGifNetworkFetcher

- (UIImage *)imageFromData:(NSData *)data
{
    if (AnimatedGifDataIsValid(data)) {
        return UIImageWithAnimatedGIFData(data);
    } else {
        return [super imageFromData:data];
    }
}

@end


#endif

@implementation HNKDemoViewController {
    NSArray *_items;
}

#if HNK_USE_CUSTOM_FORMAT
+ (void)initialize
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"thumbnail"];
    
    format.compressionQuality = 0.5;
    // UIImageView category default: 0.75, -[HNKCacheFormat initWithName:] default: 1.
    
    format.allowUpscaling = YES;
    // UIImageView category default: YES, -[HNKCacheFormat initWithName:] default: NO.
    
    format.diskCapacity = 0.5 * 1024 * 1024;
    // UIImageView category default: 10 * 1024 * 1024 (10MB), -[HNKCacheFormat initWithName:] default: 0 (no disk cache).
    
    format.preloadPolicy = HNKPreloadPolicyLastSession;
    // Default: HNKPreloadPolicyNone.
    
    format.scaleMode = HNKScaleModeAspectFill;
    // UIImageView category default: -[UIImageView contentMode], -[HNKCacheFormat initWithName:] default: HNKScaleModeFill.
    
    format.size = CGSizeMake(100, 100);
    // UIImageView category default: -[UIImageView bounds].size, -[HNKCacheFormat initWithName:] default: CGSizeZero.
    
    format.postResizeBlock = ^UIImage* (NSString *key, UIImage *image) {
        NSString *title = [key.lastPathComponent stringByDeletingPathExtension];
        title = [title stringByReplacingOccurrencesOfString:@"sample" withString:@""];
        UIImage *modifiedImage = [image demo_imageByDrawingColoredText:title];
        return modifiedImage;
    };
    
    [[HNKCache sharedCache] registerFormat:format];
}

#elif HNK_USE_GIFS

+ (void)initialize
{
    HNKCacheFormat *format = [[HNKCacheFormat alloc] initWithName:@"GIF"];
    
    format.diskCapacity = 50 * 1024 * 1024;
    // UIImageView category default: 10 * 1024 * 1024 (10MB), -[HNKCacheFormat initWithName:] default: 0 (no disk cache).
    
    format.preloadPolicy = HNKPreloadPolicyLastSession;
    // Default: HNKPreloadPolicyNone.
    
    format.scaleMode = HNKScaleModeAspectFill;
    // UIImageView category default: -[UIImageView contentMode], -[HNKCacheFormat initWithName:] default: HNKScaleModeFill.
    
    format.size = CGSizeMake(100, 100);
    // UIImageView category default: -[UIImageView bounds].size, -[HNKCacheFormat initWithName:] default: CGSizeZero.
    
    // This is to create animated UIImages from gif data.
    format.deserializeImageBlock = ^UIImage* (NSString *key, NSData *data) {
        return UIImageWithAnimatedGIFData(data);
    };
    
    // This saves the images to disk as Gifs
    format.serializeImageBlock = ^NSData* (NSString *key, UIImage *image) {
        return UIImageAnimatedGIFRepresentation(image);
    };
    
    [[HNKCache sharedCache] registerFormat:format];
}
#endif

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[HNKDemoCollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
#if HNK_LOCAL_IMAGES
    [self initializeItemsWithLocalImages];
#else
    [self initializeItemsWithURLs];
#endif
}

#pragma mark - Public

+ (HNKDemoViewController*)viewController
{
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(100, 100);
    HNKDemoViewController *viewController = [[HNKDemoViewController alloc] initWithCollectionViewLayout:layout];
    return viewController;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return _items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    HNKDemoCollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
#if HNK_USE_CUSTOM_FORMAT
    cell.imageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"thumbnail"];
#endif
#if HNK_LOCAL_IMAGES
    NSString *path = _items[indexPath.row];
    [cell.imageView hnk_setImageFromFile:path];
#else
    NSString *urlString = _items[indexPath.row];
    NSURL *url = [NSURL URLWithString:urlString];
#if HNK_USE_GIFS
    cell.imageView.hnk_cacheFormat = [HNKCache sharedCache].formats[@"GIF"];
    HNKGifNetworkFetcher *fetcher = [[HNKGifNetworkFetcher alloc] initWithURL:url];
    [cell.imageView hnk_setImageFromFetcher:fetcher];
#else
    [cell.imageView hnk_setImageFromURL:url];
#endif
#endif
    return cell;
}

#pragma mark - Utils

- (void)initializeItemsWithLocalImages
{
    _items = [NSArray array];
    static NSUInteger ImageCount = 100;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSMutableArray *items = [NSMutableArray array];
        for (NSUInteger i = 0; i < ImageCount; i++)
        {
            @autoreleasepool {
                NSString *fileName = [NSString stringWithFormat:@"sample%ld.jpg", (long)i];
                NSString *path = [documents stringByAppendingPathComponent:fileName];
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:path])
                {
                    NSLog(@"Creating image %ld of %ld", (long)i + 1, (long)ImageCount);
                    UIImage *image = [UIImage demo_randomImage];
                    NSData *data = UIImageJPEGRepresentation(image, 1);
                    [data writeToFile:path atomically:YES];
                }
                [items addObject:path];
            }
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            _items = items;
            [self.collectionView reloadData];
        });
    });
}

- (void)initializeItemsWithURLs
{
#if HNK_USE_GIFS
    _items = @[@"http://media.giphy.com/media/5xaOcLx8A5zjZzUTSx2/giphy.gif",
               @"http://media.giphy.com/media/TlK63EBGpEZy7vwwF68/giphy.gif",
               @"http://media.giphy.com/media/TlK63EvcvghyJU105zy/giphy.gif",
               @"http://media.giphy.com/media/TlK63EGsLT8BMkFehLW/giphy.gif",
               @"http://media.giphy.com/media/5xaOcLt873f8hAq44nu/giphy.gif",
               @"http://media.giphy.com/media/3rgXBN8IFhnt4agoSI/giphy.gif",
               @"http://media.giphy.com/media/3rgXBAe5ZCUNrc952o/giphy.gif",
               @"http://media.giphy.com/media/5xaOcLxHchkTXFyCV4k/giphy.gif",
               @"http://media.giphy.com/media/5xaOcLv9wcDZA3WRWco/giphy.gif",
               @"http://media.giphy.com/media/5xaOcLrmz6zmDZSZs40/giphy.gif",
               @"http://media.giphy.com/media/5xaOcLDazF4tShPf2us/giphy.gif",
               @"http://media.giphy.com/media/Kljo2HSHCta36/giphy.gif",
               @"http://media2.giphy.com/media/12eLcLqw13e6WY/giphy.gif",
               @"http://media.giphy.com/media/11caEgnSDg0avS/giphy.gif",
               @"http://media.giphy.com/media/yO8qLCUbTfiBG/giphy.gif",
               @"http://media.giphy.com/media/aDTM8BkD9hhgQ/giphy.gif",
               @"http://media.giphy.com/media/oIR6xeOffCEBa/giphy.gif",
               @"http://media.giphy.com/media/N3xTwLRGAzPTW/giphy.gif",
               @"http://media.giphy.com/media/B0mIM25D8fpOo/giphy.gif",
               @"http://media.giphy.com/media/ydwKWHRCwFT5S/giphy.gif",
               @"http://media.giphy.com/media/kf7SvRAUB25Ww/giphy.gif",
               @"http://media.giphy.com/media/Tr10zt02CSMOQ/giphy.gif",
               @"http://media.giphy.com/media/AiGuigOqE5ot2/giphy.gif",
               @"http://media.giphy.com/media/ghVtt3BfMwYhi/giphy.gif",
               @"http://media1.giphy.com/media/u36Ow6jBvWCFW/giphy.gif",
               @"http://media.giphy.com/media/lcmYVxHTvkOLC/giphy.gif",
               @"http://media1.giphy.com/media/ghAbYUswkmXHq/200w.gif",
               @"http://media4.giphy.com/media/l41lIvPtFdU3cLQjK/200w.gif",
               @"http://media1.giphy.com/media/2aAcLrYtiX8YM/giphy.gif",
               @"http://media2.giphy.com/media/RO9VDe4SULS7K/200w.gif"];
#else
    _items = @[@"http://imgs.xkcd.com/comics/election.png",
               @"http://imgs.xkcd.com/comics/scantron.png",
               @"http://imgs.xkcd.com/comics/secretary_part_5.png",
               @"http://imgs.xkcd.com/comics/secretary_part_4.png",
               @"http://imgs.xkcd.com/comics/secretary_part_3.png",
               @"http://imgs.xkcd.com/comics/secretary_part_2.png",
               @"http://imgs.xkcd.com/comics/secretary_part_1.png",
               @"http://imgs.xkcd.com/comics/actuarial.png",
               @"http://imgs.xkcd.com/comics/scrabble.png",
               @"http://imgs.xkcd.com/comics/twitter.png",
               @"http://imgs.xkcd.com/comics/morning_routine.png",
               @"http://imgs.xkcd.com/comics/going_west.png",
               @"http://imgs.xkcd.com/comics/steal_this_comic.png",
               @"http://imgs.xkcd.com/comics/numerical_sex_positions.png",
               @"http://imgs.xkcd.com/comics/i_am_not_a_ninja.png",
               @"http://imgs.xkcd.com/comics/depth.png",
               @"http://imgs.xkcd.com/comics/flash_games.png",
               @"http://imgs.xkcd.com/comics/fiction_rule_of_thumb.png",
               @"http://imgs.xkcd.com/comics/height.png",
               @"http://imgs.xkcd.com/comics/listen_to_yourself.png",
               @"http://imgs.xkcd.com/comics/spore.png",
               @"http://imgs.xkcd.com/comics/tones.png",
               @"http://imgs.xkcd.com/comics/the_staple_madness.png",
               @"http://imgs.xkcd.com/comics/typewriter.png",
               @"http://imgs.xkcd.com/comics/one-sided.png",
               @"http://imgs.xkcd.com/comics/further_boomerang_difficulties.png",
               @"http://imgs.xkcd.com/comics/turn-on.png",
               @"http://imgs.xkcd.com/comics/still_raw.png",
               @"http://imgs.xkcd.com/comics/house_of_pancakes.png",
               @"http://imgs.xkcd.com/comics/aversion_fads.png",
               @"http://imgs.xkcd.com/comics/the_end_is_not_for_a_while.png",
               @"http://imgs.xkcd.com/comics/improvised.png",
               @"http://imgs.xkcd.com/comics/fetishes.png",
               @"http://imgs.xkcd.com/comics/x_girls_y_cups.png",
               @"http://imgs.xkcd.com/comics/moving.png",
               @"http://imgs.xkcd.com/comics/quantum_teleportation.png",
               @"http://imgs.xkcd.com/comics/rba.png",
               @"http://imgs.xkcd.com/comics/voting_machines.png",
               @"http://imgs.xkcd.com/comics/freemanic_paracusia.png",
               @"http://imgs.xkcd.com/comics/google_maps.png",
               @"http://imgs.xkcd.com/comics/paleontology.png",
               @"http://imgs.xkcd.com/comics/holy_ghost.png",
               @"http://imgs.xkcd.com/comics/regrets.png",
               @"http://imgs.xkcd.com/comics/frustration.png",
               @"http://imgs.xkcd.com/comics/cautionary.png",
               @"http://imgs.xkcd.com/comics/hats.png",
               @"http://imgs.xkcd.com/comics/rewiring.png",
               @"http://imgs.xkcd.com/comics/upcoming_hurricanes.png",
               @"http://imgs.xkcd.com/comics/mission.png",
               @"http://imgs.xkcd.com/comics/impostor.png",
               @"http://imgs.xkcd.com/comics/the_sea.png",
               @"http://imgs.xkcd.com/comics/things_fall_apart.png",
               @"http://imgs.xkcd.com/comics/good_morning.png",
               @"http://imgs.xkcd.com/comics/too_old_for_this_shit.png",
               @"http://imgs.xkcd.com/comics/in_popular_culture.png",
               @"http://imgs.xkcd.com/comics/i_am_not_good_with_boomerangs.png",
               @"http://imgs.xkcd.com/comics/macgyver_gets_lazy.png",
               @"http://imgs.xkcd.com/comics/know_your_vines.png",
               @"http://imgs.xkcd.com/comics/xkcd_loves_the_discovery_channel.png",
               @"http://imgs.xkcd.com/comics/babies.png",
               @"http://imgs.xkcd.com/comics/road_rage.png",
               @"http://imgs.xkcd.com/comics/thinking_ahead.png",
               @"http://imgs.xkcd.com/comics/internet_argument.png",
               @"http://imgs.xkcd.com/comics/suv.png",
               @"http://imgs.xkcd.com/comics/how_it_happened.png",
               @"http://imgs.xkcd.com/comics/purity.png",
               @"http://imgs.xkcd.com/comics/xkcd_goes_to_the_airport.png",
               @"http://imgs.xkcd.com/comics/journal_5.png",
               @"http://imgs.xkcd.com/comics/journal_4.png",
               @"http://imgs.xkcd.com/comics/delivery.png",
               @"http://imgs.xkcd.com/comics/every_damn_morning.png",
               @"http://imgs.xkcd.com/comics/fantasy.png",
               @"http://imgs.xkcd.com/comics/starwatching.png",
               @"http://imgs.xkcd.com/comics/bad_timing.png",
               @"http://imgs.xkcd.com/comics/geohashing.png",
               @"http://imgs.xkcd.com/comics/fortune_cookies.png",
               @"http://imgs.xkcd.com/comics/security_holes.png",
               @"http://imgs.xkcd.com/comics/finish_line.png",
               @"http://imgs.xkcd.com/comics/a_better_idea.png",
               @"http://imgs.xkcd.com/comics/making_hash_browns.png",
               @"http://imgs.xkcd.com/comics/jealousy.png",
               @"http://imgs.xkcd.com/comics/forks_and_spoons.png",
               @"http://imgs.xkcd.com/comics/stove_ownership.png",
               @"http://imgs.xkcd.com/comics/the_man_who_fell_sideways.png",
               @"http://imgs.xkcd.com/comics/zealous_autoconfig.png",
               @"http://imgs.xkcd.com/comics/restraining_order.png",
               @"http://imgs.xkcd.com/comics/mistranslations.png",
               @"http://imgs.xkcd.com/comics/new_pet.png",
               @"http://imgs.xkcd.com/comics/startled.png",
               @"http://imgs.xkcd.com/comics/techno.png",
               @"http://imgs.xkcd.com/comics/math_paper.png",
               @"http://imgs.xkcd.com/comics/electric_skateboard_double_comic.png",
               @"http://imgs.xkcd.com/comics/overqualified.png",
               @"http://imgs.xkcd.com/comics/cheap_gps.png",
               @"http://imgs.xkcd.com/comics/venting.png",
               @"http://imgs.xkcd.com/comics/journal_3.png",
               @"http://imgs.xkcd.com/comics/convincing_pickup_line.png",
               @"http://imgs.xkcd.com/comics/1000_miles_north.png",
               @"http://imgs.xkcd.com/comics/large_hadron_collider.png",
               @"http://imgs.xkcd.com/comics/important_life_lesson.png"];
#endif
}

@end
