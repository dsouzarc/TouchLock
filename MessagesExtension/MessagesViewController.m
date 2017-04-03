//
//  MessagesViewController.m
//  MessagesExtension
//
//  Created by Ryan D'souza on 2/18/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import "MessagesViewController.h"


@interface MessagesViewController ()

@property (strong, nonatomic) CompactDefaultView *compactDefaultView;
@property (strong, nonatomic) ExpandedDefaultView *expandedDefaultView;

@property (strong, nonatomic) YMSPhotoPickerViewController *photoPickerViewController;


@end

@implementation MessagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self showCompactDefaultView];
}

- (void) pressedSendTextButton
{
    
}

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    for (PHAsset *asset in assets) {
        // Do something with the asset
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) pressedChoosePhotoButton
{
    NSLog(@"CHOOSE PHOTO");
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypePhotoLibrary]) {
        NSLog(@"AVAILABLE");
    }
    else {
        NSLog(@"ERROR HERE");
        return;
    }
    
    
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (status == PHAuthorizationStatusAuthorized) {
        NSLog(@"AUTHORIZED");
        // Access has been granted.
        
        QBImagePickerController *imagePickerController = [QBImagePickerController new];
        imagePickerController.delegate = self;
        imagePickerController.allowsMultipleSelection = YES;
        imagePickerController.maximumNumberOfSelection = 6;
        imagePickerController.showsNumberOfSelectedAssets = YES;
        
        CGRect newSize = CGRectMake(0, self.topLayoutGuide.length, self.view.frame.size.width, self.view.frame.size.height - self.topLayoutGuide.length);
        [[imagePickerController view] setFrame:newSize];
        [self.view addSubview:[imagePickerController view]];
        
        //[self presentViewController:imagePickerController animated:YES completion:NULL];
        
        
        /*if(!self.photoPickerViewController) {
            self.photoPickerViewController = [[YMSPhotoPickerViewController alloc] init];
            self.photoPickerViewController.delegate = self;
            self.photoPickerViewController.numberOfPhotoToSelect = 10;
        }
        
        //[[self.photoPickerViewController view] setFrame:self.view.frame];
        //[self.view addSubview:[self.photoPickerViewController view]];
        
        [self presentViewController:self.photoPickerViewController animated:YES completion:nil];*/
    }
    
    else if (status == PHAuthorizationStatusDenied) {
        NSLog(@"DENIED");
        // Access has been denied.
    }
    
    else if (status == PHAuthorizationStatusNotDetermined) {
        
        NSLog(@"NOT DETERMINED");
        
        // Access has not been determined.
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            
            if (status == PHAuthorizationStatusAuthorized) {
                
                NSLog(@"NOW AUTHORIZED");
                
            }
            
            else {
                NSLog(@"NOW DENIED");
                // Access has been denied.
            }
        }];
    }
    
    else if (status == PHAuthorizationStatusRestricted) {
        // Restricted access - normally won't happen.
        NSLog(@"RESTRICTED");
    }
}

- (void) photoPickerViewControllerDidCancel:(YMSPhotoPickerViewController *)picker
{
    NSLog(@"CALLED CANCEL");
    [self.photoPickerViewController dismissViewControllerAnimated:YES completion:nil];
    //[[self.photoPickerViewController view] removeFromSuperview];
}

- (void) pressedTakePhotoButton
{
    NSLog(@"TAKE PHOTO");
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
}

- (void) photoPickerViewControllerDidReceiveCameraAccessDenied:(YMSPhotoPickerViewController *)picker
{
    
    NSLog(@"NO CAMERA");
}

- (void) photoPickerViewControllerDidReceivePhotoAlbumAccessDenied:(YMSPhotoPickerViewController *)picker
{
    NSLog(@"NO ALBUM");
}

- (void) showCompactDefaultView
{
    if(self.expandedDefaultView) {
        [self.expandedDefaultView removeFromSuperview];
    }
    
    if(!self.compactDefaultView) {
        self.compactDefaultView = (CompactDefaultView*) [[[NSBundle mainBundle] loadNibNamed:@"CompactDefaultView" owner:self options:nil] firstObject];
        self.compactDefaultView.delegate = self;
    }
    
    [self.compactDefaultView setFrame:self.view.frame];
    [self.view addSubview:self.compactDefaultView];
}


- (void) showExpandedDefaultView
{
    if(self.compactDefaultView) {
        [self.compactDefaultView removeFromSuperview];
    }
    
    if(!self.expandedDefaultView) {
        self.expandedDefaultView = (ExpandedDefaultView*) [[[NSBundle mainBundle] loadNibNamed:@"ExpandedDefaultView" owner:self options:nil] firstObject];
        self.expandedDefaultView.delegate = self;
    }
    
    [self.expandedDefaultView setFrame:self.view.frame];
    [self.view addSubview:self.expandedDefaultView];
}


#pragma mark - Conversation Handling

-(void)didBecomeActiveWithConversation:(MSConversation *)conversation
{
    // Called when the extension is about to move from the inactive to active state.
    // This will happen when the extension is about to present UI.
    
    // Use this method to configure the extension and restore previously stored state.
}

-(void)willResignActiveWithConversation:(MSConversation *)conversation
{
    // Called when the extension is about to move from the active to inactive state.
    // This will happen when the user dissmises the extension, changes to a different
    // conversation or quits Messages.
    
    // Use this method to release shared resources, save user data, invalidate timers,
    // and store enough state information to restore your extension to its current state
    // in case it is terminated later.
}

-(void)didReceiveMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    // Called when a message arrives that was generated by another instance of this
    // extension on a remote device.
    
    // Use this method to trigger UI updates in response to the message.
}

-(void)didStartSendingMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    // Called when the user taps the send button.
}

-(void)didCancelSendingMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    // Called when the user deletes the message without sending it.
    
    // Use this to clean up state related to the deleted message.
}

-(void)willTransitionToPresentationStyle:(MSMessagesAppPresentationStyle)presentationStyle
{
    
}

-(void)didTransitionToPresentationStyle:(MSMessagesAppPresentationStyle)presentationStyle
{
    if(presentationStyle == MSMessagesAppPresentationStyleExpanded) {
        NSLog(@"TRANSITIONING TO EXPANDED");
        [self showExpandedDefaultView];
    }
    
    //Compact or base case
    else {
        NSLog(@"TRANSITIONING TO SHOW COMPACT");
        [self showCompactDefaultView];
    }
}

@end
