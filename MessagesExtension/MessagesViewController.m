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

@property (strong, nonatomic) PrivateTextViewController *privateTextViewController;
@property (strong, nonatomic) NSData *privateTextData;

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


/****************************************************************
 *
 *              Button Listeners
 *
 *****************************************************************/

# pragma mark Button Listeners

- (void) pressedSendTextButton
{
    if([self presentationStyle] == MSMessagesAppPresentationStyleCompact) {
        [self requestPresentationStyle:MSMessagesAppPresentationStyleExpanded];
    }
    
    self.privateTextViewController = [[PrivateTextViewController alloc] initWithNibName:@"PrivateTextViewController"
                                                                                 bundle:[NSBundle mainBundle]
                                                                             isOutgoing:YES
                                                                        messageTextData:self.privateTextData];
    self.privateTextViewController.delegate = self;
    
    [self presentViewController:self.privateTextViewController animated:YES completion:nil];
}

- (void) pressedTakePhotoButton
{
    NSLog(@"TAKE PHOTO");
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        self.cameraPickerController = [[UIImagePickerController alloc]init];
        self.cameraPickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.cameraPickerController.delegate = self;
        self.cameraPickerController.allowsEditing = NO;
        self.cameraPickerController.videoMaximumDuration = 60 * 60; //>60 minutes
        self.cameraPickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
        
        NSArray *mediaTypes = @[(NSString*) kUTTypeMovie, (NSString*) kUTTypeImage];
        self.cameraPickerController.mediaTypes = mediaTypes;
        
        UIView *cameraPickerView = [self.cameraPickerController view];
        
        [cameraPickerView setFrame:CGRectMake(0, 80, self.view.frame.size.width, self.view.frame.size.height - 120)];
        [cameraPickerView setClipsToBounds:YES];
        [cameraPickerView sizeToFit];
        [self.view setAutoresizesSubviews:YES];
        
        [self.view addSubview:cameraPickerView];
    }
    
    else {
        NSLog(@"NO CAMERA");
    }
}

- (void) pressedChoosePhotoButton
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        NSLog(@"ERROR ACCESSING PHOTO LIBRARY");
        return;
    }
    
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (status == PHAuthorizationStatusAuthorized) {
        NSLog(@"AUTHORIZED");
        [self showQBImagePickerController];
    }
    
    else if (status == PHAuthorizationStatusDenied) {
        NSLog(@"DENIED");
    }
    
    else if (status == PHAuthorizationStatusNotDetermined) {
        
        NSLog(@"NOT DETERMINED");
        
        // Access has not been determined.
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            
            if (status == PHAuthorizationStatusAuthorized) {
                NSLog(@"NOW AUTHORIZED");
                [self showQBImagePickerController];
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


/****************************************************************
 *
 *              QBImagePickerController Delegate
 *
 *****************************************************************/

# pragma mark QBImagePickerController Delegate

- (void) qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets
{
    const int totalNumberOfItems = (int) [assets count];
    
    [self showLoadingHUDWithText:[NSString stringWithFormat:@"Compressing & Encrypting %d objects", totalNumberOfItems]];
    
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        
        //Managers
        NSFileManager *fileManager = [NSFileManager defaultManager];
        PHImageManager *photoManager = [PHImageManager defaultManager];
        
        PHImageRequestOptions *photoRequestOptions = [Constants getPhotoRequestOptions];
        PHVideoRequestOptions *videoRequestOptions = [Constants getVideoRequestOptions];
        
        NSString *currentSendName = [Constants getSendFormatUsingCurrentDate];
        MessageAttachments *messageAttachments = [[MessageAttachments alloc] initWithAttachmentName:currentSendName];
        
        __block int numberOfVideosSaved = 0;
        __block int numberOfOtherMediaSaved = 0;
        
        //Let's save all the photos and videos to this temporary directory
        for(PHAsset *asset in assets) {
            
            if([asset mediaType] == PHAssetMediaTypeImage) {
                
                [photoManager requestImageForAsset:asset
                                        targetSize:PHImageManagerMaximumSize
                                       contentMode:PHImageContentModeDefault
                                           options:photoRequestOptions
                                     resultHandler:^(UIImage *originalImage, NSDictionary *info) {
                                         
                                         NSString *imageFileName = [NSString stringWithFormat:@"%@.png", [[NSUUID UUID] UUIDString]];
                                         [messageAttachments addImageWithNameToMetaFile:imageFileName];
                                         
                                         NSData *pngImageData = UIImagePNGRepresentation(originalImage);
                                         [pngImageData writeToFile:[messageAttachments.pathToUnzippedAttachment stringByAppendingPathComponent:imageFileName] atomically:YES];
                                         
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
                                           [messageAttachments addVideoWithNameToMetaFile:videoFileName];
                                           
                                           NSURL *videoFileURL = [NSURL fileURLWithPath:[messageAttachments.pathToUnzippedAttachment stringByAppendingPathComponent:videoFileName]];
                                           
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
            sleep(0.5); //Half a second
            NSLog(@"Sleeping while waiting to process");
        }
        
        [self sendMessageWithAttachments:messageAttachments encryptionKey:encryptionKey totalNumberOfItems:totalNumberOfItems];
    });
}

- (void) qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    [[self.imagePickerController view] removeFromSuperview];
}


/****************************************************************
 *
 *              PrivateTextViewController Delegate
 *
 *****************************************************************/

# pragma mark PrivateTextViewController Delegate

- (void) privateTextViewController:(id)privateTextViewController exitedEditorWithMessageTextData:(NSData *)messageTextData
{
    self.privateTextData = messageTextData;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        
        NSString *currentSendName = [Constants getSendFormatUsingCurrentDate];
        MessageAttachments *messageAttachments = [[MessageAttachments alloc] initWithAttachmentName:currentSendName];
        
        NSString *fileName = [NSString stringWithFormat:@"%@.txt", [[NSUUID UUID] UUIDString]];
        [messageAttachments addPrivateTextFileWithNameToMetaFile:fileName];
        NSString *filePath = [messageAttachments.pathToUnzippedAttachment stringByAppendingPathComponent:fileName];
        
        [self.privateTextData writeToFile:filePath atomically:YES];
        
        NSString *encryptionKey = [Constants generateEncryptionKey];
        [self sendMessageWithAttachments:messageAttachments encryptionKey:encryptionKey totalNumberOfItems:1];
    });
    
    [self privateTextViewController:privateTextViewController didExit:YES];
    [self requestPresentationStyle:MSMessagesAppPresentationStyleCompact];
}

- (void) privateTextViewController:(id)privateTextViewController didExit:(BOOL)didExit
{
    [self.privateTextViewController dismissViewControllerAnimated:YES completion:nil];
    self.privateTextViewController = nil;
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
    MessageAttachments *messageAttachment = [[MessageAttachments alloc] init];
    
    [self showLoadingHUDWithText:@"Compressing attachment"];
    
    [[self.imagePickerController view] removeFromSuperview];
    self.imagePickerController = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        
        //Dealing with an image
        if([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString*) kUTTypeImage]) {
            
            UIImage *originalImage = (UIImage*) [info objectForKey:UIImagePickerControllerOriginalImage];
            NSData *pngImageData = UIImagePNGRepresentation(originalImage);
            
            NSString *imageFileName = [NSString stringWithFormat:@"%@.png", [[NSUUID UUID] UUIDString]];
            [messageAttachment addImageWithNameToMetaFile:imageFileName];
            
            NSString *imageFilePath = [messageAttachment.pathToUnzippedAttachment stringByAppendingPathComponent:imageFileName];
            [pngImageData writeToFile:imageFilePath atomically:YES];
        }
        
        //Dealing with a movie
        else if([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString*) kUTTypeMovie]) {
            
            NSString *recordedMoviePath = [[info objectForKey:UIImagePickerControllerMediaURL] path];
    
            NSString *sendVideofileName = [NSString stringWithFormat:@"%@.mov", [[NSUUID UUID] UUIDString]];
            [messageAttachment addImageWithNameToMetaFile:sendVideofileName];
            
            NSString *sendVideoFilePath = [messageAttachment.pathToUnzippedAttachment stringByAppendingPathComponent:sendVideofileName];
            
            NSError *copyError;
            
            [[NSFileManager defaultManager] copyItemAtPath:recordedMoviePath toPath:sendVideoFilePath error:&copyError];
        }
        
        NSString *encryptionKey = [Constants generateEncryptionKey];
        
        [self sendMessageWithAttachments:messageAttachment encryptionKey:encryptionKey totalNumberOfItems:1];
        
    });
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

- (void) didBecomeActiveWithConversation:(MSConversation *)conversation
{
    // Called when the extension is about to move from the inactive to active state.
    // This will happen when the extension is about to present UI.
    
    // Use this method to configure the extension and restore previously stored state.
    NSLog(@"ACTIVE NOW");
    
    if([conversation selectedMessage]) {
        
        MSMessage *message = [conversation selectedMessage];
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:[message URL] resolvingAgainstBaseURL:NO];
        MessageParameters *messageParameters = [[MessageParameters alloc] initWithNSURLComponents:urlComponents];
        
        if(messageParameters.numberOfItems == 1) {
            [self showLoadingHUDWithText:@"Decrypting 1 Attachment"];
        } else {
            [self showLoadingHUDWithText:[NSString stringWithFormat:@"Decrypting %d Attachments", messageParameters.numberOfItems]];
        }
        
        self.receivingMediaArray = [[NSMutableArray alloc] init];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
            
            NSError *error;
            NSString *zipFilePath = [[NSUserDefaults standardUserDefaults] objectForKey:messageParameters.messageID];
            
            while(!zipFilePath) {
                NSLog(@"Tried to get zipped file. Now waiting");
                sleep(0.5);
                zipFilePath = [[NSUserDefaults standardUserDefaults] objectForKey:messageParameters.messageID];
            }
            
            NSURL *zipFileURL = [NSURL fileURLWithPath:zipFilePath];
            NSData *decryptedData = [RNDecryptor decryptData:[NSData dataWithContentsOfURL:zipFileURL]
                                                withPassword:messageParameters.encryptionKey
                                                       error:&error];
            
            if(error || !decryptedData) {
                NSLog(@"ERROR DECRYPTING: %@", [error description]);
            }
            
            self.currentlyOpenMessageAttachment = [[MessageAttachments alloc] initWithAttachmentName:messageParameters.attachmentName];
            
            [decryptedData writeToFile:self.currentlyOpenMessageAttachment.pathToZippedAttachment atomically:YES];
            decryptedData = nil;
            
            [SSZipArchive unzipFileAtPath:self.currentlyOpenMessageAttachment.pathToZippedAttachment toDestination:self.currentlyOpenMessageAttachment.pathToUnzippedAttachment];
            
            //Delete the ".zip" file
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                [[NSFileManager defaultManager] removeItemAtPath:self.currentlyOpenMessageAttachment.pathToZippedAttachment error:nil];
            });
            
            [self.currentlyOpenMessageAttachment loadMetaFileListFromFile];
            
            
            
            NSArray *receivedImages = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.currentlyOpenMessageAttachment.pathToImagesFolder error:&error];
            NSArray *receivedVideos = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.currentlyOpenMessageAttachment.pathToVideosFolder error:&error];
            
            int numberOfImages = (int) [receivedImages count];
            int numberOfVideos = (int) [receivedVideos count];
            
            if(receivedImages) {
    
                for(NSString *fileName in receivedImages) {
                    if(![fileName isEqualToString:@".DS_Store"]) {
                        
                        NSString *filePath = [self.currentlyOpenMessageAttachment.pathToImagesFolder stringByAppendingPathComponent:fileName];
                        
                        MWPhoto *photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:filePath]];
                        [self.receivingMediaArray addObject:photo];
                    }
                }
            }
            
            if(receivedVideos) {
                
                for(NSString *fileName in receivedVideos) {
                    if(![fileName isEqualToString:@".DS_Store"]) {
                        
                        NSString *filePath = [self.currentlyOpenMessageAttachment.pathToVideosFolder stringByAppendingPathComponent:fileName];
                        NSURL *videoFilePath = [NSURL fileURLWithPath:filePath];
                        
                        UIImage *firstFrame = [Constants thumbnailImageForVideo:videoFilePath atTime:0.1];
                
                        MWPhoto *video = [MWPhoto photoWithImage:firstFrame];
                        video.videoURL = videoFilePath;
                        video.isVideo = YES;
                        
                        [self.receivingMediaArray addObject:video];
                    }
                }
            }
            
            NSLog(@"RECEIVING MEDIA ARRAY SIZE: %ld\t%d\t%d", [self.receivingMediaArray count], numberOfImages, numberOfVideos);
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                
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
                
                [self hideLoadingHUD];
            });
        });
    }
}

- (void) willResignActiveWithConversation:(MSConversation *)conversation
{
    [super willResignActiveWithConversation:conversation];
}

static NSURL *receivedURL;

- (void) didReceiveMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:[message URL] resolvingAgainstBaseURL:NO];
    MessageParameters *messageParameters = [[MessageParameters alloc] initWithNSURLComponents:urlComponents];
    
    MSMessageTemplateLayout *templateLayout = (MSMessageTemplateLayout*) message.layout;
    receivedURL = [templateLayout mediaFileURL];
    
    [[NSUserDefaults standardUserDefaults] setObject:[receivedURL path] forKey:messageParameters.messageID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) didStartSendingMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    [super didStartSendingMessage:message conversation:conversation];
    self.currentlyOpenMessageAttachment.isOutgoing = NO;
    self.privateTextData = nil;
}

- (void) didCancelSendingMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    self.privateTextData = nil;
    
    if(self.currentlyOpenMessageAttachment && [self.currentlyOpenMessageAttachment isOutgoing]) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
            
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:[self.currentlyOpenMessageAttachment pathToUnzippedAttachment]
                                                       error:&error];
            
        });
    }
    
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

/****************************************************************
 *
 *              Miscellaneous Helper Methods
 *
 *****************************************************************/

# pragma mark Miscellaneous Helper Methods

- (void) showQBImagePickerController
{
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

/** CALL THIS FROM A SEPARATE THREAD - handles actually sending the message*/
- (void) sendMessageWithAttachments:(MessageAttachments*)messageAttachments encryptionKey:(NSString*)encryptionKey totalNumberOfItems:(int)totalNumberOfItems
{
    self.currentlyOpenMessageAttachment = messageAttachments;
    self.currentlyOpenMessageAttachment.isOutgoing = YES;
    
    [SSZipArchive createZipFileAtPath:messageAttachments.pathToZippedAttachment
              withContentsOfDirectory:messageAttachments.pathToUnzippedAttachment];
    
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
    
    MSMessageTemplateLayout *messageLayout = [[MSMessageTemplateLayout alloc] init];
    //TODO: Implement messageLayout.image = defaultImage;
    messageLayout.imageTitle = @"iMessage extension";
    messageLayout.caption = @"Hello World!";
    messageLayout.subcaption = @"Sent by Ryan!";
    messageLayout.mediaFileURL = [NSURL fileURLWithPath:messageAttachments.pathToZippedAttachment];
    
    MessageParameters *messageParameters = [[MessageParameters alloc] initWithEncryptionKey:encryptionKey
                                                                             attachmentName:messageAttachments.attachmentName
                                                                                  messageID:[[NSUUID UUID] UUIDString]
                                                                              numberOfItems:totalNumberOfItems];
    
    MSSession *messageSession = [[MSSession alloc] init];
    MSMessage *message = [[MSMessage alloc] initWithSession:messageSession];
    [message setLayout:messageLayout];
    [message setURL:[[messageParameters generateURLComponents] URL]];
    message.layout = messageLayout;
    message.URL = [[messageParameters generateURLComponents] URL];
    message.summaryText = @"Summary!";
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        
        [self.activeConversation insertMessage:message
                             completionHandler:^(NSError *error) {
                                 
                                 if(error) {
                                     NSLog(@"ERROR SENDING HERE: %@", [error localizedDescription]);
                                 }
                                 
                                 //Delete the zipped/unzipped files after sending
                                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
                                     
                                     NSError *deleteError;
                                     [[NSFileManager defaultManager] removeItemAtPath:messageAttachments.pathToZippedAttachment error:&deleteError];
                                     [[NSFileManager defaultManager] removeItemAtPath:messageAttachments.pathToZippedAttachment error:&deleteError];
                                 });
                             }
         ];
        
        [self hideLoadingHUD];
        
        if(self.imagePickerController) {
            [[self.imagePickerController view] removeFromSuperview];
            self.imagePickerController = nil;
        }
    });
}

@end
