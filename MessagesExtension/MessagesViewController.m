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

@end

@implementation MessagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self showCompactDefaultView];
}

- (void) clickedOnTakePhoto:(UIButton*)sender
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

- (void) clickedOnChoosePhoto:(UIButton*)button
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
        

        
        //YMSPhotoPickerViewController *pickerViewController = [[YMSPhotoPickerViewController alloc] init];
        //pickerViewController.numberOfPhotoToSelect = 10;
        //[self presentViewController:pickerViewController animated:YES completion:nil];
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


- (void) showCompactDefaultView
{
    if(self.expandedDefaultView) {
        [self.expandedDefaultView removeFromSuperview];
    }
    
    self.compactDefaultView = (CompactDefaultView*) [[[NSBundle mainBundle] loadNibNamed:@"CompactDefaultView" owner:self options:nil] firstObject];
    [self.compactDefaultView setFrame:self.view.frame];
    
    [self.compactDefaultView.takePhotoButton addTarget:self action:@selector(clickedOnTakePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.compactDefaultView.takePhotoButtonImage addTarget:self action:@selector(clickedOnTakePhoto:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.compactDefaultView.choosePhotoButton addTarget:self action:@selector(clickedOnChoosePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.compactDefaultView.choosePhotoButtonImage addTarget:self action:@selector(clickedOnChoosePhoto:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.compactDefaultView];
}


- (void) showExpandedDefaultView
{
    if(self.compactDefaultView) {
        [self.compactDefaultView removeFromSuperview];
    }
    
    self.expandedDefaultView = (ExpandedDefaultView*) [[[NSBundle mainBundle] loadNibNamed:@"ExpandedDefaultView" owner:self options:nil] firstObject];
    [self.expandedDefaultView setFrame:self.view.frame];
    
    [self.expandedDefaultView.takePhotoButton addTarget:self action:@selector(clickedOnTakePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.expandedDefaultView.takePhotoButtonImage addTarget:self action:@selector(clickedOnTakePhoto:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.expandedDefaultView.choosePhotoButton addTarget:self action:@selector(clickedOnChoosePhoto:) forControlEvents:UIControlEventTouchUpInside];
    [self.expandedDefaultView.choosePhotoButtonImage addTarget:self action:@selector(clickedOnChoosePhoto:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.expandedDefaultView];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        [self showExpandedDefaultView];
    }
    
    //Compact or base case
    else {
        [self showCompactDefaultView];
    }
    
}

@end
