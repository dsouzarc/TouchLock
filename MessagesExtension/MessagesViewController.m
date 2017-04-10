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

@property (strong, nonatomic) MBProgressHUD *loadingHUD;
@property (strong, nonatomic) QBImagePickerController *imagePickerController;

@property (strong, nonatomic) MWPhotoBrowser *photoBrowserViewController;
@property (strong, nonatomic) NSMutableArray *receivingMediaArray;

@property (strong, nonatomic) UIImagePickerController *cameraPickerController;

@property (strong, nonatomic) MessageAttachments *currentlyOpenMessageAttachment;

@end

@implementation MessagesViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    if(!self) {
        self.receivingMediaArray = [[NSMutableArray alloc] init];
    }
    
    [self showCompactDefaultView];
}

- (void) qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets
{
    const int totalNumberOfItems = (int) [assets count];
    
    [self showLoadingHUDWithText:[NSString stringWithFormat:@"Compressing & Encrypting %d objects", totalNumberOfItems]];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        
        //Managers
        NSFileManager *fileManager = [NSFileManager defaultManager];
        PHImageManager *photoManager = [PHImageManager defaultManager];
        
        //PHAsset Request Options
        PHImageRequestOptions *photoRequestOptions = [Constants getPhotoRequestOptions];
        
        //Video request options
        PHVideoRequestOptions *videoRequestOptions = [Constants getVideoRequestOptions];
        
        __block int numberOfVideosSaved = 0;
        __block int numberOfOtherMediaSaved = 0;
        
        NSString *currentSendName = [Constants getSendFormatUsingCurrentDate];
        MessageAttachments *messageAttachments = [[MessageAttachments alloc] initWithAttachmentName:currentSendName];
        
        //Let's save all the photos and videos to this temporary directory
        for(PHAsset *asset in assets) {
            
            NSLog(@"Going through asset");
            
            if([asset mediaType] == PHAssetMediaTypeImage) {
                
                [photoManager requestImageForAsset:asset
                                        targetSize:PHImageManagerMaximumSize
                                       contentMode:PHImageContentModeDefault
                                           options:photoRequestOptions
                                     resultHandler:^(UIImage *originalImage, NSDictionary *info) {
                                         
                                         NSString *imageFileName = [NSString stringWithFormat:@"%@.png", [[NSUUID UUID] UUIDString]];
                                         NSData *pngImageData = UIImagePNGRepresentation(originalImage);
                                         [pngImageData writeToFile:[messageAttachments.pathToImagesFolder stringByAppendingPathComponent:imageFileName] atomically:YES];
                                         
                                         NSLog(@"Finished photo");
                                         
                                         numberOfOtherMediaSaved++;
                                     }
                 ];
            }
            
            else if([asset mediaType] == PHAssetMediaTypeVideo) {
                
                [photoManager requestAVAssetForVideo:asset
                                             options:videoRequestOptions
                                       resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                                           
                                           NSString *videoFileName = [NSString stringWithFormat:@"%@.MOV", [[NSUUID UUID] UUIDString]];
                                           NSURL *videoFileURL = [NSURL fileURLWithPath:[messageAttachments.pathToVideosFolder stringByAppendingPathComponent:videoFileName]];
                                           
                                           NSError *error;
                                           AVURLAsset *videoURLAsset = (AVURLAsset*) asset;
                                           
                                           [fileManager copyItemAtURL:[videoURLAsset URL]
                                                                toURL:videoFileURL
                                                                error:&error];
                                           
                                           NSLog(@"Finished video");
                                           
                                           numberOfVideosSaved++;
                                       }
                 ];
                
                
                /*[photoManager requestExportSessionForVideo:asset
                 options:videoRequestOptions
                 exportPreset:AVAssetExportPreset3840x2160
                 resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
                 
                 NSString *videoFileName = [NSString stringWithFormat:@"%@.MOV", [[NSUUID UUID] UUIDString]];
                 NSURL *videoFilePath = [NSURL fileURLWithPath:[currentSendVideosFolder stringByAppendingPathComponent:videoFileName]];
                 
                 exportSession.outputFileType = AVFileTypeQuickTimeMovie;
                 exportSession.outputURL = videoFilePath;
                 
                 [exportSession exportAsynchronouslyWithCompletionHandler:^{
                 
                 }];
                 
                 }
                 ];*/
            }
            
            //Some other form of media or unknown file
            else {
                numberOfOtherMediaSaved++;
            }
        }
        
        //Long, randomly generated string --> each UUID = 36 characters long
        NSString *encryptionKey = [Constants generateEncryptionKey];
        
        //Since we can't load videos synchronously, wait for the rest to finish
        while((numberOfOtherMediaSaved + numberOfVideosSaved) < totalNumberOfItems) {
            sleep(1); //100 milliseconds
            NSLog(@"Sleeping while waiting to process");
        }
        
        
        [SSZipArchive createZipFileAtPath:messageAttachments.pathToZippedAttachment withContentsOfDirectory:messageAttachments.pathToUnzippedAttachment];
        
        NSError *error;
        NSData *encryptedData = [RNEncryptor encryptData:[NSData dataWithContentsOfFile:messageAttachments.pathToZippedAttachment]
                                            withSettings:kRNCryptorAES256Settings
                                                password:encryptionKey
                                                   error:&error];
        
        if(error) {
            NSLog(@"ERROR ENCRYPTING MESSAGE: %@: ", [error description]);
        }
        
        [encryptedData writeToFile:messageAttachments.pathToZippedAttachment atomically:YES];
        encryptedData = nil;
        
        UIImage *defaultImage = [UIImage imageNamed:@"default_blurred_image.jpg"];
        
        MSMessageTemplateLayout *messageLayout = [[MSMessageTemplateLayout alloc] init];
        //TODO: Implement //messageLayout.image = defaultImage;
        messageLayout.imageTitle = @"iMessage extension";
        messageLayout.caption = @"Hello World!";
        messageLayout.subcaption = @"Sent by Ryan!";
        
        NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
        NSURLQueryItem *encryptionItem = [[NSURLQueryItem alloc] initWithName:@"encryption_key" value:encryptionKey];
        NSURLQueryItem *sendNameItem = [[NSURLQueryItem alloc] initWithName:@"send_name" value:currentSendName];
        NSURLQueryItem *messageIDItem = [[NSURLQueryItem alloc] initWithName:@"message_id" value:[[NSUUID UUID] UUIDString]];
        [urlComponents setQueryItems:@[encryptionItem, sendNameItem, messageIDItem]];
        
        NSLog(@"SEND ZIP: %@", messageAttachments.pathToZippedAttachment);
        
        MSSession *messageSession = [[MSSession alloc] init];
        MSMessage *message = [[MSMessage alloc] initWithSession:messageSession];
        messageLayout.mediaFileURL = [NSURL fileURLWithPath:messageAttachments.pathToZippedAttachment];
        message.layout = messageLayout;
        message.URL = urlComponents.URL;
        message.summaryText = @"Summary!";
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            [self.activeConversation insertMessage:message
                                 completionHandler:^(NSError *error) {
                                     if(error) {
                                         NSLog(@"ERROR SENDING HERE: %@", [error localizedDescription]);
                                     }
                                     
                                     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
                                         
                                         NSError *deleteError;
                                         [fileManager removeItemAtPath:messageAttachments.pathToZippedAttachment error:&deleteError];
                                     });
                                 }
             ];
            
            [self hideLoadingHUD];
            [[self.imagePickerController view] removeFromSuperview];
            
        });
        
        [fileManager removeItemAtPath:messageAttachments.pathToUnzippedAttachment error:&error];
    });
}

- (void) qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    [[self.imagePickerController view] removeFromSuperview];
}

- (void) pressedSendTextButton
{
    
}

- (void) pressedChoosePhotoButton
{
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
        self.imagePickerController.assetCollectionSubtypes = [Constants getPHAssetCollectionSubtypes];
        
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
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        self.cameraPickerController = [[UIImagePickerController alloc]init];
        self.cameraPickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.cameraPickerController.delegate = self;
        self.cameraPickerController.allowsEditing = YES;
        
        NSArray *mediaTypes = @[(NSString*) kUTTypeMovie, (NSString*) kUTTypeImage];
        self.cameraPickerController.mediaTypes = mediaTypes;
        
        [self presentViewController:self.cameraPickerController animated:YES completion:nil];
        
    }
    
    else {
        NSLog(@"NO CAMERA");
        
        //UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil message:@"I'm afraid there's no camera on this device!" delegate:nil cancelButtonTitle:@"Dang!" otherButtonTitles:nil, nil];
        //[alertView show];
    }
    
}


/****************************************************************
 *
 *              UIImagePickerController Delegate
 *
 *****************************************************************/

# pragma mark UIImagePickerController Delegate

- (void) imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
    [self.cameraPickerController dismissViewControllerAnimated:YES completion:nil];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // grab our movie URL
    NSURL *chosenMovie = [info objectForKey:UIImagePickerControllerMediaURL];
    
    // save it to the documents directory (option 1)
    /*NSURL *fileURL = [self grabFileURL:@"video.mov"];
    NSData *movieData = [NSData dataWithContentsOfURL:chosenMovie];
    [movieData writeToURL:fileURL atomically:YES];
    
    // save it to the Camera Roll (option 2)
    UISaveVideoAtPathToSavedPhotosAlbum([chosenMovie path], nil, nil, nil);
    
    // and dismiss the picker
    [self dismissViewControllerAnimated:YES completion:nil]; */
    
}


/****************************************************************
 *
 *              Show Compact & Expand Views
 *
 *****************************************************************/

# pragma mark Show Compact & Expand Views

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


/****************************************************************
 *
 *              Conversation Handling
 *
 *****************************************************************/

# pragma mark Conversation Handling

- (void) willSelectMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    NSLog(@"ABOUT TO SELECT MESSAGE!!");
}


- (void) didSelectMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    NSLog(@"DID SELECT - ANALYZING NOW");
}

-(void)didBecomeActiveWithConversation:(MSConversation *)conversation
{
    // Called when the extension is about to move from the inactive to active state.
    // This will happen when the extension is about to present UI.
    
    // Use this method to configure the extension and restore previously stored state.
    NSLog(@"ACTIVE NOW");
    
    if([conversation selectedMessage]) {
        
        NSError *error;
        
        MSMessage *message = [conversation selectedMessage];
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:[message URL] resolvingAgainstBaseURL:NO];
        
        NSString *encryptionKey = @"";
        NSString *fileName = @"";
        NSString *messageID = @"";
        
        for(NSURLQueryItem *queryItem in [urlComponents queryItems]) {
            if([[queryItem name] isEqualToString:@"encryption_key"]) {
                encryptionKey = [queryItem value];
            }
            
            else if([[queryItem name] isEqualToString:@"send_name"]) {
                fileName = [queryItem value];
            }
            
            else if([[queryItem name] isEqualToString:@"message_id"]) {
                messageID = [queryItem value];
                NSLog(@"IN ACTIVE WITH ID: %@", messageID);
            }
        }
        
        NSString *zipFilePath = [[NSUserDefaults standardUserDefaults] objectForKey:messageID];
        while(!zipFilePath) {
            NSLog(@"Tried to get zipped file. Now waiting");
            sleep(1);
            zipFilePath = [[NSUserDefaults standardUserDefaults] objectForKey:messageID];
        }
        
        NSURL *zipFileURL = [NSURL fileURLWithPath:zipFilePath];
        NSData *decryptedData = [RNDecryptor decryptData:[NSData dataWithContentsOfURL:zipFileURL]
                                            withPassword:encryptionKey
                                                   error:&error];
        
        if(error || !decryptedData) {
            NSLog(@"ERROR DECRYPTING: %@", [error description]);
        }
        
        self.currentlyOpenMessageAttachment = [[MessageAttachments alloc] initWithAttachmentName:fileName];
        
        [decryptedData writeToFile:self.currentlyOpenMessageAttachment.pathToZippedAttachment atomically:YES];
        decryptedData = nil;
        
        [SSZipArchive unzipFileAtPath:self.currentlyOpenMessageAttachment.pathToZippedAttachment toDestination:self.currentlyOpenMessageAttachment.pathToUnzippedAttachment];
        
        //Delete the ".zip" file
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [[NSFileManager defaultManager] removeItemAtPath:self.currentlyOpenMessageAttachment.pathToZippedAttachment error:nil];
        });
        
        int numberOfImages = (int) [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.currentlyOpenMessageAttachment.pathToImagesFolder error:&error] count];
        int numberOfVideos = (int) [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.currentlyOpenMessageAttachment.pathToVideosFolder error:&error] count];
        
        self.receivingMediaArray = [[NSMutableArray alloc] init];
        
        NSArray *receivedImages = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.currentlyOpenMessageAttachment.pathToImagesFolder error:&error];
        NSArray *receivedVideos = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.currentlyOpenMessageAttachment.pathToVideosFolder error:&error];
        
        if(receivedImages) {
            for(NSString *fileName in receivedImages) {
                if(![fileName isEqualToString:@".DS_Store"]) {
                    NSString *filePath = [self.currentlyOpenMessageAttachment.pathToImagesFolder stringByAppendingPathComponent:fileName];
                    
                    NSLog(@"GOING THROUGH PHOTO: %@", filePath);
                    
                    //MWPhoto *photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:filePath]];
                    MWPhoto *photo = [MWPhoto photoWithImage:[UIImage imageWithContentsOfFile:filePath]];
                    
                    if([UIImage imageWithContentsOfFile:filePath] && photo) {
                        NSLog(@"CREATED ");
                    } else {
                        NSLog(@"ERROR CREATING");
                    }
                    
                    [self.receivingMediaArray addObject:photo];
                }
            }
        }
        
        if(receivedVideos) {
            for(NSString *fileName in receivedVideos) {
                
                if(![fileName isEqualToString:@".DS_Store"]) {
                    
                    NSString *filePath = [self.currentlyOpenMessageAttachment.pathToVideosFolder stringByAppendingPathComponent:fileName];
                    
                    
                    NSLog(@"GOING THROUGH VIDEO: %@", filePath);
                    
                    NSURL *videoFilePath = [NSURL fileURLWithPath:filePath];
                    
                    UIImage *firstFrame = [Constants thumbnailImageForVideo:videoFilePath atTime:0.1];
                    
                    MWPhoto *video = [MWPhoto photoWithImage:firstFrame];
                    video.videoURL = videoFilePath;
                    video.isVideo = YES;
                    
                    [self.receivingMediaArray addObject:video];
                }
            }
        }
        
        NSLog(@"RECEIVING MEDIA ARRAY SIZE: %ld", [self.receivingMediaArray count]);
        
        NSLog(@"RECEIVED: %d\t%d", numberOfImages, numberOfVideos);
        
        self.photoBrowserViewController = [[MWPhotoBrowser alloc] initWithPhotos:self.receivingMediaArray];
        self.photoBrowserViewController.delegate = self;
        
        // Set options
        self.photoBrowserViewController.displayActionButton = YES;
        self.photoBrowserViewController.displayNavArrows = YES;
        self.photoBrowserViewController.displaySelectionButtons = NO;
        self.photoBrowserViewController.zoomPhotosToFill = YES;
        self.photoBrowserViewController.alwaysShowControls = YES;
        self.photoBrowserViewController.enableGrid = YES;
        self.photoBrowserViewController.startOnGrid = YES;
        self.photoBrowserViewController.autoPlayOnAppear = NO;
        
        UIView *photoBrowserView = [self.photoBrowserViewController view];
        
        [self.view addSubview:photoBrowserView];
        [photoBrowserView setFrame:CGRectMake(0, 80, self.view.frame.size.width, self.view.frame.size.height - 120)];
        [photoBrowserView setClipsToBounds:YES];
        [photoBrowserView sizeToFit];
        [self.view setAutoresizesSubviews:YES];
        
        
        // Manipulate
        //[self.photoBrowserViewController showNextPhotoAnimated:YES];
        //[self.photoBrowserViewController showPreviousPhotoAnimated:YES];
        
    }
    
}

- (void) willResignActiveWithConversation:(MSConversation *)conversation
{
    // Called when the extension is about to move from the active to inactive state.
    // This will happen when the user dissmises the extension, changes to a different
    // conversation or quits Messages.
    
    // Use this method to release shared resources, save user data, invalidate timers,
    // and store enough state information to restore your extension to its current state
    // in case it is terminated later.
}

static NSURL *receivedURL;

- (void) didReceiveMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    // Called when a message arrives that was generated by another instance of this
    // extension on a remote device.
    
    // Use this method to trigger UI updates in response to the message.
    
    NSLog(@"RECEIVED MESSAGE");
    
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:[message URL] resolvingAgainstBaseURL:NO];
    
    NSString *messageID = @"";
    for(NSURLQueryItem *queryItem in [urlComponents queryItems]) {
        if([[queryItem name] isEqualToString:@"message_id"]) {
            messageID = [queryItem value];
        }
    }
    
    MSMessageTemplateLayout *templateLayout = (MSMessageTemplateLayout*) message.layout;
    receivedURL = [templateLayout mediaFileURL];
    
    [[NSUserDefaults standardUserDefaults] setObject:[receivedURL path] forKey:messageID];
    [[NSUserDefaults standardUserDefaults] synchronize];
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


/****************************************************************
 *
 *              MWPhotoBrowserDelegate
 *
 *****************************************************************/

# pragma mark MWPhotoBrowserDelegate

- (NSUInteger) numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return [self.receivingMediaArray count];
}

- (id <MWPhoto>) photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index
{
    NSLog(@"Thumb Delegate Called!");
    
    if(index < [self.receivingMediaArray count]) {
        return [self.receivingMediaArray objectAtIndex:index];
    }
    
    return nil;
}

- (id <MWPhoto>) photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    NSLog(@"CHECKING INDEX: %ld", index);
    
    if (index < [self.receivingMediaArray count]) {
        return [self.receivingMediaArray objectAtIndex:index];
    }
    
    return nil;
}

- (void) photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser
{
    if(self.currentlyOpenMessageAttachment) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            
            NSFileManager *defaultManager = [NSFileManager defaultManager];
            NSError *error;
        
            if([defaultManager fileExistsAtPath:self.currentlyOpenMessageAttachment.pathToUnzippedAttachment]) {
                [defaultManager removeItemAtPath:self.currentlyOpenMessageAttachment.pathToUnzippedAttachment error:&error];
            }
            
            if([defaultManager fileExistsAtPath:self.currentlyOpenMessageAttachment.pathToZippedAttachment]) {
                [defaultManager removeItemAtPath:self.currentlyOpenMessageAttachment.pathToZippedAttachment error:&error];
            }
        });
    }
}


/****************************************************************
 *
 *              Loading HUD
 *
 *****************************************************************/

# pragma mark Loading HUD

- (void) showLoadingHUD
{
    [self showLoadingHUDWithText:@"Loading"];
}

- (void) showLoadingHUDWithText:(NSString*)text
{
    if(self.loadingHUD) {
        [self.loadingHUD removeFromSuperview];
    }
    
    
    self.loadingHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    self.loadingHUD.mode = MBProgressHUDModeIndeterminate;
    [self.loadingHUD setLabelText:text];
    [self.loadingHUD show:YES];
    //[self.loadingHUD showAnimated:YES whileExecutingBlock:nil];
    [self.loadingHUD setRemoveFromSuperViewOnHide:YES];
}

- (void) hideLoadingHUD
{
    if(!self.loadingHUD) {
        return;
    }
    
    [self.loadingHUD setRemoveFromSuperViewOnHide:YES];
    [self.loadingHUD hide:YES];
    
    self.loadingHUD = nil;
}

@end
