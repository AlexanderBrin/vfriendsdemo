//
//  VFriendsRepository.m
//  vkfriends
//
//  Created by Alexander on 27/06/16.
//  Copyright © 2016 Alexander Brin. All rights reserved.
//

#import "VFriendsRepository.h"
#import <VKSdk.h>

#define V_FRIENDS_PER_REQUEST 5

@implementation VFriendPhoto
@end

@interface VFriend()

- (instancetype)initWithVKResponseDictionary:(NSDictionary*) vkFriend;

@end

@interface VFriendsRepository()

@property (nonatomic) NSUInteger allFriendsCount;
@property (nonatomic) NSUInteger nextOffset;
@property (nonatomic, retain) NSMutableArray* loadedFriends;
@property (nonatomic, retain) NSMutableDictionary* photoDownloadsInProgress;
@property (nonatomic, retain) NSOperationQueue* photoDownloadQueue;

@end


@interface VFriendsPhotoFetching : NSOperation

@property (weak, nonatomic) VFriendPhoto* photo;

@end


@implementation VFriendsPhotoFetching

- (void)main
{
    [super main];
    
    assert(_photo.state == VFriendsPhotoStatePending);
    if (self.cancelled) return;
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:_photo.url]];
    
    
    
    //if (self.cancelled) return;

    
    if (data.length > 0)
    {
        _photo.image = [UIImage imageWithData:data];
        _photo.state = VFriendsPhotoStateDownloaded;
    }
    else
    {
        _photo.image = nil;
        _photo.state = VFriendsPhotoStateFailed;
    }
    
    
}

@end


@implementation VFriend

- (instancetype)initWithVKResponseDictionary:( NSDictionary* _Nonnull ) vkFriend
{
    self = [super init];
    if (self)
    {
        // Устанавливаем параметры
        {
            _firstName = [vkFriend[@"first_name"] copy];
            _lastName = [vkFriend[@"last_name"] copy];
            _city = vkFriend[@"city"]
            ? [vkFriend[@"city"][@"title"] copy]
            : @"";
            _university = vkFriend[@"universities"] && ( (NSArray*)vkFriend[@"universities"] ).count > 0
            ? [vkFriend[@"universities"][0][@"name"] copy]
            : @"";
            
            // Фотография может не существовать, это нужно отметить
            // todo refactoring: перенести инициализацию в VFriendPhoto
            {
                _photo = [VFriendPhoto new];
                _photo.url = vkFriend[@"photo_100"] ? [vkFriend[@"photo_100"] copy] : nil;
                _photo.image = nil;
                _photo.state = vkFriend[@"photo_100"]
                    ? VFriendsPhotoStatePending
                    : VFriendsPhotoStateNoexists;
            }
            
        }
 
    }
    return self;
}
@end

@implementation VFriendsRepository
{
    NSUInteger _loadingOffset;
}


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self resetVars];
        _photoDownloadsInProgress = [NSMutableDictionary new];
        _photoDownloadQueue = [NSOperationQueue new];
        _photoDownloadQueue.name = @"photos";
        _photoDownloadQueue.maxConcurrentOperationCount = 2;
    }
    return self;
}

- (void)resetVars
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _loadedFriends = [NSMutableArray new];
    });
    [_loadedFriends removeAllObjects];
    _nextOffset = 0;
    _allFriendsCount = 0;
    _loadingOffset = NSUIntegerMax;
}


// Метод должен вызываться только из UI потока
- (void)fetchNextFriends
{
    // Если пошла загрузка то не
    if (_loadedFriends.count < _nextOffset || _loadingOffset == _nextOffset) return;
    _loadingOffset = _nextOffset;
    
    // VK SDK делает все в фоне
    // Оптимизируем пул чтобы быстрее чистил мусор
    //@autoreleasepool
    {
        id params = @{
                        VK_API_OWNER_ID : @"5524755",
                        VK_API_FIELDS: @"first_name,last_name,city,universities,photo_100",
                        VK_API_OFFSET: @(_nextOffset),
                        VK_API_COUNT: @(V_FRIENDS_PER_REQUEST),
                        VK_API_ORDER: @"name"
                      };
        
        VKRequest* getFriends = [VKRequest requestWithMethod:@"friends.get" parameters:params];
        
        [getFriends executeWithResultBlock:^(VKResponse * response) {
            NSLog(@"Json result: %@", response.json);
            
            
            for (NSDictionary* vkFriend in ( (NSArray*)response.json[@"items"] ))
                [_loadedFriends addObject:[[VFriend alloc] initWithVKResponseDictionary:vkFriend]];
            
            _allFriendsCount = ( (NSNumber*)response.json[@"count"] ).unsignedIntegerValue;
            _nextOffset += V_FRIENDS_PER_REQUEST;
            
            [self.delegate friendsRepositoryDidLoadFriends:self];
            
        } errorBlock:^(NSError * error) {
            if (error.code != VK_API_ERROR) {
                [error.vkError.request repeat];
            }
            else {
                NSLog(@"VK error: %@", error);
            }
        }];
    }
}

- (void)fetchFriendPhotoAtIndexPath:(NSIndexPath*)indexPath
{
    
    
    if ( _photoDownloadsInProgress[indexPath] )
        return;
    
    VFriend* friend = _loadedFriends[indexPath.row];
    assert(friend != nil);
    
    if (friend.photo.state == VFriendsPhotoStateNoexists || friend.photo.state == VFriendsPhotoStateDownloaded)
        return;
    
    
    VFriendsPhotoFetching* op = [VFriendsPhotoFetching new];
    op.photo = ( (VFriend*)_loadedFriends[indexPath.row] ).photo;
    
    __weak VFriendsPhotoFetching* opForBlock = op;
    op.completionBlock = ^{
        if (opForBlock.cancelled)
            return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.photoDownloadsInProgress removeObjectForKey:indexPath];
            [self.delegate friendsRepositoryLoadedPhotoAtIndexPath:indexPath];
        });
    };
    
    _photoDownloadsInProgress[indexPath] = op;
    [_photoDownloadQueue addOperation:op];
}

- (BOOL)isNeedToFetchNextFriendsForIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger lastRow = self.loadedCount - 1;
    return ( indexPath.row == lastRow - 1) // если последняя строка среди загруженных
    && ( lastRow < self.count ); // если меньше общего числа друзей
    
}

- (void)reload
{
    [self resetVars];
    [self fetchNextFriends];
}

- (BOOL)hasFriendAtIndex:(NSUInteger)index
{
    return index < _allFriendsCount;
}

- (BOOL)hasLoadedFriendAtIndex:(NSUInteger)index
{
    return index < _loadedFriends.count;
}

- (NSUInteger)count
{
    return _allFriendsCount;
}

- (NSUInteger)loadedCount
{
    return _loadedFriends.count;
}

- (VFriend*)friendAtIndex:(NSUInteger)index
{
    assert(_loadedFriends.count > index);
    return _loadedFriends[index];
}

@end
