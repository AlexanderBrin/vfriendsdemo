//
//  VFriendsRepository.h
//  vkfriends
//
//  Created by Alexander on 27/06/16.
//  Copyright © 2016 Alexander Brin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@class VFriendsRepository;
@class VFriend;
@class VFriendPhoto;


typedef NS_ENUM(NSInteger, VFriendsPhotoState)
{
    VFriendsPhotoStatePending,
    VFriendsPhotoStateNoexists,
    VFriendsPhotoStateDownloaded,
    VFriendsPhotoStateFailed
};

@interface VFriendPhoto : NSObject

@property (nonatomic) VFriendsPhotoState state;
@property (nonatomic, retain) UIImage* image;
@property (nonatomic, retain) NSString* url;

@end


@interface VFriend : NSObject

@property (nonatomic, retain) NSString* firstName;
@property (nonatomic, retain) NSString* lastName;
@property (nonatomic, retain) NSString* university;
@property (nonatomic, retain) NSString* city;
@property (nonatomic, retain) VFriendPhoto* photo;

@end


@protocol VFriendsRepositoryDelegate <NSObject>

@required

- (void)friendsRepositoryDidLoadFriends:(VFriendsRepository*)repository;
- (void)friendsRepositoryFailLoadingFriends:(VFriendsRepository*)repository;
- (void)friendsRepositoryLoadedPhotoAtIndexPath:(NSIndexPath*)indexPath;

@end

@interface VFriendsRepository : NSObject

@property (weak, nonatomic) id<VFriendsRepositoryDelegate> delegate;

- (void)fetchNextFriends;
- (void)reload;

- (BOOL)hasFriendAtIndex:(NSUInteger)index;
- (BOOL)hasLoadedFriendAtIndex:(NSUInteger)index;

// returns count if has loaded data, otherwise return 0
- (NSUInteger)count;
- (NSUInteger)loadedCount;

- (VFriend*)friendAtIndex:(NSUInteger)index;
- (void)fetchFriendPhotoAtIndexPath:(NSIndexPath*)indexPath;
- (BOOL)isNeedToFetchNextFriendsForIndexPath:(NSIndexPath*)indexPath;


@end
