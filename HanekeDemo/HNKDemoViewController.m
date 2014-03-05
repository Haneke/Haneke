//
//  HNKDemoViewController.m
//  Haneke
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HNKDemoViewController.h"
#import "UIImageView+Haneke.h"
#import "HNKDemoCollectionViewCell.h"
#import "UIImage+HanekeDemo.h" // To create random images

#define HNK_USE_CUSTOM_FORMAT 0
#define HNK_LOCAL_IMAGES 0

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
    // // UIImageView category default: -[UIImageView bounds].size, -[HNKCacheFormat initWithName:] default: CGSizeZero.
    
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

#pragma mark - UICollectionViewDatasource

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
    [cell.imageView hnk_setImageFromURL:url];
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
                    NSLog(@"Creating image %ld of %d", (long)i + 1, ImageCount);
                    UIImage *image = [UIImage demo_randomImageWithIndex:i];
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
}


@end
