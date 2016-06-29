 //
//  AppDelegate.m
//  vkfriends
//
//  Created by Alexander on 27/06/16.
//  Copyright © 2016 Alexander Brin. All rights reserved.
//

#import "AppDelegate.h"
#import <VKSdk.h>
#import <VKAuthorizeController.h>
//#import <SFSafariViewControlle>

@import SafariServices;


@interface VKAuthorizeController ()
@property(nonatomic, strong) UIWebView *webView;
@property(nonatomic, strong) NSString *appId;
@property(nonatomic, strong) NSString *scope;
@property(nonatomic, strong) NSURL *redirectUri;
@property(nonatomic, strong) UIActivityIndicatorView *activityMark;
@property(nonatomic, strong) UILabel *warningLabel;
@property(nonatomic, strong) UILabel *statusBar;
@property(nonatomic, strong) VKError *validationError;
@property(nonatomic, strong) NSURLRequest *lastRequest;
@property(nonatomic, weak) UINavigationController *internalNavigationController;
@property(nonatomic, assign) BOOL finished;

@end


@interface AppDelegate ()

@end

@implementation AppDelegate
{
    __strong VKSdk *_vkSdk;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    if (!_vkSdk)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            //_vkSdk = [VKSdk initializeWithAppId:@"5524755"];
        });
    }
    
    _vkSdk = [VKSdk initializeWithAppId:@"5524755"];
    
    VKSdk *vkSdk = _vkSdk;
    [vkSdk registerDelegate:self];
    [vkSdk setUiDelegate:self];
    
    NSArray *scope = @[@"friends", @"email"];
    
    [VKSdk wakeUpSession:scope completeBlock:^(VKAuthorizationState state, NSError *error) {
        if (state == VKAuthorizationAuthorized)
        {
            [self showFriends];
        } else if (state == VKAuthorizationInitialized)
        {
            // todo разобраться с SafariController
           [VKSdk authorize:scope withOptions:VKAuthorizationOptionsDisableSafariController];
            //[VKSdk authorize:scope];
        } else if (error) {
            // Some error happend, but you may try later
        } 
    }];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "ch.alexchur.vkfriends" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"vkfriends" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"vkfriends.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - VK

//iOS 9 workflow
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
    [VKSdk processOpenURL:url fromApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]];
    return YES;
}

//iOS 8 and lower
-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    [VKSdk processOpenURL:url fromApplication:sourceApplication];
    return YES;
}

-(void) vkSdkReceivedNewToken:(VKAccessToken*) newToken
{
    
}

-(void) vkSdkUserDeniedAccess:(VKError*) authorizationError
{
    
}

- (void)vkSdkShouldPresentViewController:(UIViewController *)controller
{
    [self.window.rootViewController presentViewController:controller animated:NO completion:nil];
}

- (void)vkSdkAccessAuthorizationFinishedWithResult:(VKAuthorizationResult *)result
{
    // ОМГ, вконтактик...
    if (result.state == VKAuthorizationPending && result.token != nil)
    {
        // Это таки успех
        [self showFriends];
    }
}

- (void)showFriends
{
    // fixme реализовать через Segue и перенести всю работу с авторизацией в контроллер
    id vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]
             instantiateViewControllerWithIdentifier: @"friends"];
    [self.window.rootViewController presentViewController:vc animated:NO completion:nil];
}

@end
