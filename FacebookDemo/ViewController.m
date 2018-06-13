//
//  ViewController.m
//  FacebookDemo
//
//  Created by Gocy on 2018/6/13.
//  Copyright © 2018 Gocy. All rights reserved.
//

#import "ViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginManager.h>
#import <FBSDKLoginKit/FBSDKLoginManagerLoginResult.h>

#import <FBSDKShareKit/FBSDKShareKit.h>

@interface ViewController () <FBSDKSharingDelegate>

@property (nonatomic, strong) FBSDKLoginManager *fblogin;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}


- (IBAction)share:(id)sender {
    [self _checkPublishPermissionThen:^(BOOL granted) {
        if (!granted) {
            return ;
        }
        
        FBSDKSharePhotoContent *photoContent = [FBSDKSharePhotoContent new];
        
        photoContent.photos = @[[FBSDKSharePhoto photoWithImage:[UIImage imageNamed:@"racing"] userGenerated:YES]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // after this line, the app is "dead", waiting for fbsdk to callback.
            // as i mentioned in the report, this is due to the  [FBSDKShareUtility _stageImagesForPhotoContent:withCompletionHandler:] is calling a deprecated graph api, and not leaving the group.
            [FBSDKShareDialog showFromViewController:self withContent:photoContent delegate:self];
        });
    }];
}
- (IBAction)shareWithMediaContent:(id)sender {
    [self _checkPublishPermissionThen:^(BOOL granted) {
        if (!granted) {
            return ;
        }
        
        FBSDKShareMediaContent *mediaContent = [FBSDKShareMediaContent new];
        mediaContent.media = @[[FBSDKSharePhoto photoWithImage:[UIImage imageNamed:@"racing"] userGenerated:YES]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // alternatively, using mediaContent will successfully jump to Facebook app, however the images are gone.
            // as i mentioned in the report, this is because [FBSDKShareUtility parametersForShareContent: shouldFailOnDataError:] does not handle FBSDKShareMediaContent.
            [FBSDKShareDialog showFromViewController:self withContent:mediaContent delegate:self];
        });
    }];
}

- (void)_checkPublishPermissionThen:(void(^)(BOOL granted))completion
{
    NSString *publishPermission = @"publish_pages";
    NSString *managePermission = @"manage_pages";
    if ([[FBSDKAccessToken currentAccessToken] hasGranted:publishPermission] && [[FBSDKAccessToken currentAccessToken] hasGranted:managePermission]) {
        completion(YES);
    }else {
        [[self fblogin] logInWithPublishPermissions:@[publishPermission,managePermission] fromViewController:self handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
            if (error || ![result.grantedPermissions containsObject: publishPermission] || ![result.grantedPermissions containsObject: managePermission]) {
                
                completion(NO);
            }else {
                completion(YES);
            }
        }];
    }
}


#pragma mark - FBSDKSharingDelegate
- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
    NSLog(@"Complete with %@", results);
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
    NSLog(@"Fail with error: %@",error);
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
    
}



- (FBSDKApplicationDelegate *)fbapp
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[FBSDKApplicationDelegate sharedInstance] application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:@{}];
    });
    return [FBSDKApplicationDelegate sharedInstance];
}

- (FBSDKLoginManager *)fblogin
{
    if (!_fblogin) {
        _fblogin = [FBSDKLoginManager new];
        _fblogin.defaultAudience = FBSDKDefaultAudienceEveryone;
    }
    return _fblogin;
}

@end
