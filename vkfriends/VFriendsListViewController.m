//
//  VFriendsListViewController.m
//  vkfriends
//
//  Created by Alexander on 27/06/16.
//  Copyright © 2016 Alexander Brin. All rights reserved.
//

#import "VFriendsListViewController.h"
#import "VFriendsRepository.h"


@interface VFriendCell()

@property (weak, nonatomic) IBOutlet UILabel *firstNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *universityLabel;
@property (weak, nonatomic) IBOutlet UILabel *cityLabel;
@property (weak, nonatomic) IBOutlet UIImageView *photoImageView;

- (void)displayFriend:(VFriend*)friend;

@end

@implementation VFriendCell

- (void)displayFriend:(VFriend*)friend
{
    _firstNameLabel.text = [friend.firstName copy];
    _lastNameLabel.text = [friend.lastName copy];
    _universityLabel.text = [friend.university copy];
    _cityLabel.text = [friend.city copy];
    _photoImageView.image = (friend.photo.state == VFriendsPhotoStateDownloaded)
        ? friend.photo.image
        : nil;
}

@end

@interface VFriendsListViewController() <VFriendsRepositoryDelegate>
@end

@implementation VFriendsListViewController
{
    VFriendsRepository* _repository;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        _repository = [VFriendsRepository new];
        _repository.delegate = self;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_repository reload];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _repository.loadedCount;
}

- (UITableViewCell*)tableView:(UITableView *)tableView
        cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    VFriendCell* cell = (VFriendCell*)[tableView dequeueReusableCellWithIdentifier:@"friend"];
    [cell displayFriend:[_repository friendAtIndex:indexPath.row]];
    if (!tableView.dragging && !tableView.decelerating)
        [_repository fetchFriendPhotoAtIndexPath:indexPath];
    return cell;
}

-(void) tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Подгружаем данные если это необходимо
    if( [_repository isNeedToFetchNextFriendsForIndexPath:indexPath] )
    {
        [_repository fetchNextFriends];
    }
}

#pragma mark - VFriendsRepositoryDelegate

- (void)friendsRepositoryDidLoadFriends:(VFriendsRepository*)repository
{
    [self.tableView reloadData];
}

- (void)friendsRepositoryFailLoadingFriends:(VFriendsRepository*)repository
{
    [self.tableView reloadData];
}

- (void)friendsRepositoryLoadedPhotoAtIndexPath:(NSIndexPath*)indexPath
{
    [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - UIScrollViewDelegate

// Останавливаем текущие загрузки.
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [_repository suspendAllPhotosDownloads];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    // если замедления нет, то значит друго шанса загрузить фото не будет
    if (!decelerate)
    {
        [self scrollViewDidEndDecelerating:scrollView];
    }
}

// возобновляем загрузку фотографий
// и
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [_repository resumeAllPhotosDownloads];
    [_repository fetchFriendPhotosAtIndexPaths:self.tableView.indexPathsForVisibleRows];
}

@end
