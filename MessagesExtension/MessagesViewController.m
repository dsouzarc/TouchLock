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

@property (strong, nonatomic) QBImagePickerController *imagePickerController;
@property (strong, nonatomic) NSMutableArray *assetsToSend;


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

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
       
        PHImageManager *manager = [PHImageManager defaultManager];
        
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        requestOptions.resizeMode   = PHImageRequestOptionsResizeModeNone;
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        requestOptions.synchronous = true;
        requestOptions.version = PHImageRequestOptionsVersionOriginal;
        
        UIImage *defaultImage = [UIImage imageNamed:@"default_blurred_image.jpg"];
        
        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        
        
        
        
        
        
        
        
    });
    
    self.assetsToSend = [[NSMutableArray alloc] init];
    PHImageManager *manager = [PHImageManager defaultManager];
    
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.resizeMode   = PHImageRequestOptionsResizeModeNone;
    requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    requestOptions.synchronous = true;
    requestOptions.version = PHImageRequestOptionsVersionOriginal;
    
    UIImage *defaultImage = [UIImage imageNamed:@"default_blurred_image.jpg"];
    
    for (PHAsset *asset in assets) {
        // Do something with the asset
        
        if([asset mediaType] == PHAssetMediaTypeImage) {
            
            [manager requestImageForAsset:asset
                               targetSize:PHImageManagerMaximumSize
                              contentMode:PHImageContentModeDefault
                                  options:requestOptions
                            resultHandler:^void(UIImage *originalImage, NSDictionary *info) {
                                
                                NSString *encryptionKey = @"Some super long password";
                                
                                //  Code for encrypting and saveing image
                                NSString  *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/encryptedImage.pdf"];
                                
                                NSData *data = UIImagePNGRepresentation(originalImage);
                                NSError *error;
                                NSData *encryptedData = [RNEncryptor encryptData:data
                                                                    withSettings:kRNCryptorAES256Settings
                                                                        password:encryptionKey
                                                                           error:&error];
                                
                                if(error) {
                                    NSLog(@"ERROR ENCRYPTING MESSAGE: %@: ", [error description]);
                                }
                                
                                [encryptedData writeToFile:imagePath atomically:YES];
                                NSURL *imageSavePath = [NSURL fileURLWithPath:imagePath];
                                
                                /*[self.activeConversation insertAttachment:imageSavePath withAlternateFilename:@"Alternative name" completionHandler:^(NSError *error) {
                                    if(error) {
                                        NSLog(@"ERROR INSERTING ATTACHMENT: %@", [error description]);
                                    } else {
                                        NSLog(@"INSERTED ATTACHMENT");
                                    }
                                }];*/
                            
                                
                                MSMessageTemplateLayout *messageLayout = [[MSMessageTemplateLayout alloc] init];
                                messageLayout.image = defaultImage;
                                messageLayout.imageTitle = @"iMessage extension";
                                messageLayout.caption = @"Hello World!";
                                messageLayout.subcaption = @"Sent by Ryan!";
                                
                                NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
                                NSURLQueryItem *firstItem = [[NSURLQueryItem alloc] initWithName:@"encryption_key" value:encryptionKey];
                                [urlComponents setQueryItems:@[firstItem]];
                                
                                MSSession *messageSession = [[MSSession alloc] init];
                                MSMessage *message = [[MSMessage alloc] initWithSession:messageSession];
                                messageLayout.mediaFileURL = imageSavePath;
                                message.layout = messageLayout;
                                message.URL = urlComponents.URL;
                                message.summaryText = @"Summary!";
                                
                
                                
                                [self.activeConversation insertMessage:message completionHandler:^(NSError *error) {
                                    if(error) {
                                        NSLog(@"ERROR SENDING HERE: %@", [error localizedDescription]);
                                    }
                                }];
                                return;
                            }
             ];
        }
    }

    [[self.imagePickerController view] removeFromSuperview];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    [[self.imagePickerController view] removeFromSuperview];
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
        
        self.imagePickerController = [QBImagePickerController new];
        self.imagePickerController.delegate = self;
        self.imagePickerController.allowsMultipleSelection = YES;
        self.imagePickerController.maximumNumberOfSelection = 10;
        self.imagePickerController.showsNumberOfSelectedAssets = YES;
        self.imagePickerController.mediaType = QBImagePickerMediaTypeAny;
        self.imagePickerController.prompt = @"Select the Photos And Videos to Securely Send";
        self.imagePickerController.assetCollectionSubtypes = @[
                                                               @(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
                                                               @(PHAssetCollectionSubtypeAlbumMyPhotoStream),
                                                               @(PHAssetCollectionSubtypeSmartAlbumFavorites),
                                                               @(PHAssetCollectionSubtypeSmartAlbumScreenshots),
                                                               @(PHAssetCollectionSubtypeAlbumRegular),
                                                               @(PHAssetCollectionSubtypeAlbumMyPhotoStream),
                                                               @(PHAssetCollectionSubtypeAlbumCloudShared),
                                                               @(PHAssetCollectionSubtypeSmartAlbumGeneric),
                                                               @(PHAssetCollectionSubtypeSmartAlbumUserLibrary),
                                                               @(PHAssetCollectionSubtypeSmartAlbumPanoramas),
                                                               @(PHAssetCollectionSubtypeSmartAlbumVideos),
                                                               @(PHAssetCollectionSubtypeSmartAlbumBursts),
                                                               @(PHAssetCollectionSubtypeSmartAlbumLivePhotos),
                                                               @(PHAssetCollectionSubtypeSmartAlbumSlomoVideos)
                                                               ];
        
        CGRect newSize = CGRectMake(0, self.topLayoutGuide.length, self.view.frame.size.width, self.view.frame.size.height - self.topLayoutGuide.length);
        [[self.imagePickerController view] setFrame:newSize];
        [self.view addSubview:[self.imagePickerController view]];
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

- (void) pressedTakePhotoButton
{
    NSLog(@"TAKE PHOTO");
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

- (void) willSelectMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    NSLog(@"ABOUT TO SELECT MESSAGE!!");
    
    
}


- (void) didSelectMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    NSLog(@"DID SELECT - ANALYZING NOW");
    
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:[message URL] resolvingAgainstBaseURL:NO];
    
    NSString *encryptionKey = @"";
    
    for(NSURLQueryItem *queryItem in [urlComponents queryItems]) {
        if([[queryItem name] isEqualToString:@"encryption_key"]) {
            encryptionKey = [queryItem value];
        }
    }
    
    //  Code for loading image by decryption
    NSString  *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/encryptedImage.pdf"];
    NSError *error;
    
    NSData *encryptedData = [NSData dataWithContentsOfFile:imagePath];
    NSData *decryptedData = [RNDecryptor decryptData:encryptedData
                                        withPassword:encryptionKey
                                               error:&error];
    
    if(error) {
        NSLog(@"ERROR DECRYPTING IMAGE: %@", [error description]);
        return;
    }

    UIImage *image = [UIImage imageWithData:decryptedData];
    
    UIViewController *someController = [[UIViewController alloc] init];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:image];
    [imgView setFrame:self.view.frame];
    [[someController view] setFrame:self.view.frame];
    
    [self presentViewController:someController animated:YES completion:nil];
    
}

-(void)didBecomeActiveWithConversation:(MSConversation *)conversation
{
    // Called when the extension is about to move from the inactive to active state.
    // This will happen when the extension is about to present UI.
    
    // Use this method to configure the extension and restore previously stored state.
    NSLog(@"ACTIVE NOW");
    
    if([conversation selectedMessage]) {
        NSLog(@"FOUND MESSAGE");
        
        MSMessage *message = [conversation selectedMessage];
        
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:[message URL] resolvingAgainstBaseURL:NO];
        
        NSString *encryptionKey = @"";
        
        for(NSURLQueryItem *queryItem in [urlComponents queryItems]) {
            if([[queryItem name] isEqualToString:@"encryption_key"]) {
                encryptionKey = [queryItem value];
            }
        }
        
        //  Code for loading image by decryption
        NSString  *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/encryptedImage.pdf"];
        NSError *error;
        
        NSData *encryptedData = [NSData dataWithContentsOfFile:imagePath];
        NSData *decryptedData = [RNDecryptor decryptData:encryptedData
                                            withPassword:encryptionKey
                                                   error:&error];
        
        if(error) {
            NSLog(@"ERROR DECRYPTING IMAGE: %@", [error description]);
            return;
        }
        
        UIImage *image = [UIImage imageWithData:decryptedData];

        if(image) {
            NSLog(@"RECREATED IMAGE SUCCESSFULLY");
        }
        
        
        MSMessageTemplateLayout *messageLayout = [[MSMessageTemplateLayout alloc] init];
        messageLayout.image = image; //originalImage;
        messageLayout.imageTitle = @"Reply iMessage extension";
        messageLayout.caption = @"Reply Hello World!";
        messageLayout.subcaption = @"Reply Sent by Ryan!";
        
        
        MSSession *messageSession = [[MSSession alloc] init];
        message = [[MSMessage alloc] initWithSession:messageSession];
        //messageLayout.mediaFileURL = imageSavePath;
        message.layout = messageLayout;
        message.URL = urlComponents.URL;
        message.summaryText = @"Summary!";
        
        
        
        [self.activeConversation insertMessage:message completionHandler:^(NSError *error) {
            if(error) {
                NSLog(@"ERROR SENDING HERE: %@", [error localizedDescription]);
            } else {
                NSLog(@"REPLY IS GUCCI");
            }
        }];
        
    }
    
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
    NSLog(@"RECEIVED MESSAGE");
}

- (void) didStartSendingMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    // Called when the user taps the send button.

    [super didStartSendingMessage:message conversation:conversation];
    
}

- (void) didCancelSendingMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    // Called when the user deletes the message without sending it.
    // Use this to clean up state related to the deleted message.
    [super didCancelSendingMessage:message conversation:conversation];
}


- (void) didTransitionToPresentationStyle:(MSMessagesAppPresentationStyle)presentationStyle
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
