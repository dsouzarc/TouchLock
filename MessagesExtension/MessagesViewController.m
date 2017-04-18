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

# pragma mark - Button Listeners

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
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSLog(@"NO CAMERA IN TAKE PHOTO");
        return;
    }
    
    self.cameraPickerController = [[UIImagePickerController alloc]init];
    self.cameraPickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.cameraPickerController.delegate = self;
    self.cameraPickerController.allowsEditing = NO;
    self.cameraPickerController.videoMaximumDuration = 60 * 60; //>60 minutes
    self.cameraPickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
    self.cameraPickerController.mediaTypes = @[(NSString*) kUTTypeMovie, (NSString*) kUTTypeImage];
    
    UIView *cameraPickerView = [self.cameraPickerController view];
    [cameraPickerView setFrame:CGRectMake(0, 80, self.view.frame.size.width, self.view.frame.size.height - 120)];
    [cameraPickerView setClipsToBounds:YES];
    [cameraPickerView sizeToFit];
    
    [self.view setAutoresizesSubviews:YES];
    [self.view addSubview:cameraPickerView];
}

- (void) pressedChoosePhotoButton
{
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
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

# pragma mark - QBImagePickerController Delegate

- (void) qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets
{
    const int totalNumberOfItems = (int) [assets count];
    
    if(totalNumberOfItems == 0) {
        [[self.imagePickerController view] removeFromSuperview];
        self.imagePickerController = nil;
    }
    
    else if(totalNumberOfItems == 1) {
        [self showLoadingHUDWithText:@"Compressing & Encrypting 1 object"];
    }
    
    else {
        [self showLoadingHUDWithText:[NSString stringWithFormat:@"Compressing & Encrypting %d objects", totalNumberOfItems]];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        
        PHImageManager *photoManager = [PHImageManager defaultManager];
        
        PHImageRequestOptions *photoRequestOptions = [Constants getPhotoRequestOptions];
        PHVideoRequestOptions *videoRequestOptions = [Constants getVideoRequestOptions];
        
        self.currentlyOpenMessageAttachment = [[MessageAttachments alloc] init];
        
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
                                         
                                         [self.currentlyOpenMessageAttachment addImageAttachment:originalImage];
        
                                         NSLog(@"Finished photo");
                                         numberOfOtherMediaSaved++;
                                     }
                 ];
            }
            
            else if([asset mediaType] == PHAssetMediaTypeVideo) {
                
                [photoManager requestAVAssetForVideo:asset
                                             options:videoRequestOptions
                                       resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                                           
                                           AVURLAsset *videoURLAsset = (AVURLAsset*) asset;
                                           [self.currentlyOpenMessageAttachment addVideoAttachmentAtURL:[videoURLAsset URL]];
                            
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
        
        //Since we can't load videos synchronously, wait for the rest to finish
        while((numberOfOtherMediaSaved + numberOfVideosSaved) < totalNumberOfItems) {
            sleep(0.5); //Wait half a second
            NSLog(@"Sleeping while waiting to process");
        }
        
        [self sendMessageWithAttachments:self.currentlyOpenMessageAttachment];
    });
}

- (void) qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    [[self.imagePickerController view] removeFromSuperview];
    self.imagePickerController = nil;
}


/****************************************************************
 *
 *              PrivateTextViewController Delegate
 *
 *****************************************************************/

# pragma mark - PrivateTextViewController Delegate

- (void) privateTextViewController:(id)privateTextViewController exitedEditorWithMessageTextData:(NSData *)messageTextData
{
    self.privateTextData = messageTextData;
    
    [self showLoadingHUDWithText:@"Encrypting text file"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        
        self.currentlyOpenMessageAttachment = [[MessageAttachments alloc] init];
        [self.currentlyOpenMessageAttachment addPrivateTextFileWithData:self.privateTextData];

        [self sendMessageWithAttachments:self.currentlyOpenMessageAttachment];
    });
    
    [self privateTextViewController:privateTextViewController didExit:YES];
}

- (void) privateTextViewController:(id)privateTextViewController didExit:(BOOL)didExit
{
    [self.privateTextViewController dismissViewControllerAnimated:YES completion:nil];
    [self requestPresentationStyle:MSMessagesAppPresentationStyleCompact];
    self.privateTextViewController = nil;
}


/****************************************************************
 *
 *              UIImagePickerController Delegate
 *
 *****************************************************************/

# pragma mark - UIImagePickerController Delegate

- (void) imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
    [self.cameraPickerController dismissViewControllerAnimated:YES completion:nil];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
    [self showLoadingHUDWithText:@"Compressing attachment"];
    
    self.currentlyOpenMessageAttachment = [[MessageAttachments alloc] init];
    
    [[self.imagePickerController view] removeFromSuperview];
    self.imagePickerController = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
        
        //Dealing with an image
        if([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString*) kUTTypeImage]) {
            
            UIImage *originalImage = (UIImage*) [info objectForKey:UIImagePickerControllerOriginalImage];
            [self.currentlyOpenMessageAttachment addImageAttachment:originalImage];
            
        }
        
        //Dealing with a movie
        else if([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString*) kUTTypeMovie]) {
            
            NSURL *recordedVideoURL = [info objectForKey:UIImagePickerControllerMediaURL];
            [self.currentlyOpenMessageAttachment addVideoAttachmentAtURL:recordedVideoURL];
        }
        
        [self sendMessageWithAttachments:self.currentlyOpenMessageAttachment];
    });
}


/****************************************************************
 *
 *              Show Compact & Expand Views
 *
 *****************************************************************/

# pragma mark - Show Compact & Expand Views

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

# pragma mark - Conversation Handling

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
    
    /*if([conversation selectedMessage]) {
        
        NSLog(@"ACTIVE NOW AND SELECTED");
        
        MSMessage *message = [conversation selectedMessage];
        
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:[message URL] resolvingAgainstBaseURL:NO];
        MessageParameters *messageParameters = [[MessageParameters alloc] initWithNSURLComponents:urlComponents];
        
        if(messageParameters.numberOfItems == 0) {
            NSLog(@"0 ITEMS IN MESSAGE PARAMETERS FOR: %@", messageParameters.messageID);
            return;
        }
        
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
            
            if(![decryptedData writeToFile:self.currentlyOpenMessageAttachment.pathToZippedAttachment options:NSDataWritingAtomic error:&error]) {
                NSLog(@"ERROR WRITING DECRYPTED TO FILE: %@", error);
            }
            
            if(error) {
                NSLog(@"ERROR WRITING DECRYPTED TO FILE: %@", [error description]);
                return;
            }
            decryptedData = nil;
            
            if(![SSZipArchive unzipFileAtPath:self.currentlyOpenMessageAttachment.pathToZippedAttachment toDestination:self.currentlyOpenMessageAttachment.pathToUnzippedAttachment overwrite:YES password:nil error:&error]) {
                NSLog(@"ERROR UNZIPPING FILE: %@", error);
            }
            if(error) {
                NSLog(@"ERROR UNZIPPING FILE HERE: %@", [error description]);
                return;
            }

            
            //Delete the ".zip" file
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                [[NSFileManager defaultManager] removeItemAtPath:self.currentlyOpenMessageAttachment.pathToZippedAttachment error:nil];
            });
            
            [self.currentlyOpenMessageAttachment loadMetaFileListFromFile];
            
            const int numberOfPrivateTextFiles = [self.currentlyOpenMessageAttachment numberOfPrivateTextFilesInMetaFileList];
            
            //Dealing with textfiles
            if(numberOfPrivateTextFiles > 0) {
                
                NSString *textFileName;
                for(NSMutableDictionary *fileAttributes in self.currentlyOpenMessageAttachment.metaFileList) {
                    if([[fileAttributes valueForKey:MEDIA_TYPE_KEY] isEqualToString:PRIVATE_TEXTFILE_IDENTIFIER]) {
                        textFileName = [fileAttributes valueForKey:FILE_NAME_KEY];
                    }
                }
                
                if(textFileName) {
                    NSString *textFilePath = [self.currentlyOpenMessageAttachment.pathToUnzippedAttachment stringByAppendingPathComponent:textFileName];
                    NSData *textFileData = [NSData dataWithContentsOfFile:textFilePath];
                    
                    NSLog(@"SHOWING TEXTFILE AT: %@", textFilePath);
                    
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        
                        self.privateTextViewController = [[PrivateTextViewController alloc] initWithNibName:@"PrivateTextViewController" bundle:[NSBundle mainBundle] isOutgoing:FALSE messageTextData:textFileData];
                        
                        self.privateTextViewController.delegate = self;
                        
                        [self presentViewController:self.privateTextViewController animated:YES completion:nil];
                        [self hideLoadingHUD];
                    });
                }
            }
            
            else {
                
                NSLog(@"GOING THROUGH MEDIA: %d", [self.currentlyOpenMessageAttachment totalNumberOfAttachments]);
                
                for(NSMutableDictionary *fileAttributes in self.currentlyOpenMessageAttachment.metaFileList) {
                    
                    if([[fileAttributes valueForKey:MEDIA_TYPE_KEY] isEqualToString:IMAGE_IDENTIFIER]) {
                        NSString *fileName = [fileAttributes valueForKey:FILE_NAME_KEY];
                        NSString *filePath = [self.currentlyOpenMessageAttachment.pathToUnzippedAttachment stringByAppendingPathComponent:fileName];
                        
                        MWPhoto *photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:filePath]];
                        [self.receivingMediaArray addObject:photo];
                    }
                    
                    else if([[fileAttributes valueForKey:MEDIA_TYPE_KEY] isEqualToString:VIDEO_IDENTIFIER]) {
                        NSString *fileName = [fileAttributes valueForKey:FILE_NAME_KEY];
                        NSString *filePath = [self.currentlyOpenMessageAttachment.pathToUnzippedAttachment stringByAppendingPathComponent:fileName];
                        
                        NSURL *videoFilePath = [NSURL fileURLWithPath:filePath];
            
                        UIImage *firstFrame = [Constants thumbnailImageForVideo:videoFilePath atTime:0.1];
                        
                        MWPhoto *video = [MWPhoto photoWithImage:firstFrame];
                        video.videoURL = videoFilePath;
                        video.isVideo = YES;
                        
                        [self.receivingMediaArray addObject:video];
                    }
                }
                
                NSLog(@"RECEIVING MEDIA ARRAY SIZE: %ld", [self.receivingMediaArray count]);
                
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
                    [photoBrowserView setFrame:CGRectMake(0, 80, self.view.frame.size.width, self.view.frame.size.height - 120)];
                    [photoBrowserView setClipsToBounds:YES];
                    [photoBrowserView sizeToFit];
                    
                    [self.view addSubview:photoBrowserView];
                    [self.view setAutoresizesSubviews:YES];
                    
                    [self hideLoadingHUD];
                });
            }
        });
    } */
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
    
    NSLog(@"RECEIVED MESSAGE WITH ATTACHMENTS: %d\tID: %@\t%@", messageParameters.numberOfItems, messageParameters.messageID, [receivedURL path]);
    
    [[NSUserDefaults standardUserDefaults] setObject:[receivedURL path] forKey:messageParameters.messageID];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSUserDefaults *sharedDefaults = [Constants sharedUserDefaults];
    
    [sharedDefaults setObject:[receivedURL path] forKey:messageParameters.messageID];
    [sharedDefaults synchronize];
}

- (void) didStartSendingMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    [super didStartSendingMessage:message conversation:conversation];
    
    [self.currentlyOpenMessageAttachment storeAttachmentsInDatabase];
    
    self.currentlyOpenMessageAttachment = nil;
    self.privateTextData = nil;
}

- (void) didCancelSendingMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    self.privateTextData = nil;
    
    if(self.currentlyOpenMessageAttachment) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
            
            NSError *error;
            [[NSFileManager defaultManager] removeItemAtPath:[self.currentlyOpenMessageAttachment pathToAttachmentFolder]
                                                       error:&error];
            
            
            [[NSFileManager defaultManager] removeItemAtPath:[self.currentlyOpenMessageAttachment pathToZipFolder]
                                                       error:&error];
            NSLog(@"DELETED IN CANCEL");
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

# pragma mark - MWPhotoBrowserDelegate

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
        
            if([defaultManager fileExistsAtPath:self.currentlyOpenMessageAttachment.pathToZipFolder]) {
                //[defaultManager removeItemAtPath:self.currentlyOpenMessageAttachment.pathToZipFolder error:&error];
            }
            
            if([defaultManager fileExistsAtPath:self.currentlyOpenMessageAttachment.pathToAttachmentFolder]) {
                //[defaultManager removeItemAtPath:self.currentlyOpenMessageAttachment.pathToAttachmentFolder error:&error];
            }
        });
    }
}


/****************************************************************
 *
 *              Loading HUD
 *
 *****************************************************************/

# pragma mark - Loading HUD

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
    [self.loadingHUD setMode:MBProgressHUDModeIndeterminate];
    [self.loadingHUD setLabelText:text];
    [self.loadingHUD show:YES];
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

# pragma mark - Miscellaneous Helper Methods

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
- (void) sendMessageWithAttachments:(MessageAttachments*)messageAttachments
{
    self.currentlyOpenMessageAttachment = messageAttachments;
    [self.currentlyOpenMessageAttachment saveMetaFileListToFile];
    
    [SSZipArchive createZipFileAtPath:self.currentlyOpenMessageAttachment.pathToZipFolder
              withContentsOfDirectory:self.currentlyOpenMessageAttachment.pathToAttachmentFolder];
    
    NSError *error;
    
    /*NSData *encryptedData = [RNEncryptor encryptData:[NSData dataWithContentsOfFile:messageAttachments.pathToZippedAttachment]
                                        withSettings:kRNCryptorAES256Settings
                                            password:encryptionKey
                                               error:&error];
    
    if(error) {
        NSLog(@"ERROR ENCRYPTING MESSAGE: %@: ", [error description]);
    }
    
    [encryptedData writeToFile:messageAttachments.pathToZippedAttachment atomically:YES];
    encryptedData = nil;*/
    
    MSMessageTemplateLayout *messageLayout = [[MSMessageTemplateLayout alloc] init];
    //TODO: Implement messageLayout.image = defaultImage;
    //messageLayout.imageTitle = @"iMessage extension";
    messageLayout.caption = @"Encrypted Message";
    messageLayout.subcaption = [messageAttachments getAttachmentsDescriptiveString];
    messageLayout.mediaFileURL = [NSURL fileURLWithPath:self.currentlyOpenMessageAttachment.pathToZipFolder];
    
    MessageParameters *messageParameters = [[MessageParameters alloc] initWithEncryptionKey:self.currentlyOpenMessageAttachment.messageEncryptionKey
                                                                             attachmentName:self.currentlyOpenMessageAttachment.pathToZipFolder
                                                                                  messageID:self.currentlyOpenMessageAttachment.messageID
                                                                              numberOfItems:[self.currentlyOpenMessageAttachment totalNumberOfAttachments]];
    
    MSSession *messageSession = [[MSSession alloc] init];
    MSMessage *message = [[MSMessage alloc] initWithSession:messageSession];
    [message setLayout:messageLayout];
    [message setURL:[[messageParameters generateURLComponents] URL]];
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        
        [self.activeConversation insertMessage:message
                             completionHandler:^(NSError *error) {
                                 
                                 if(error) {
                                     NSLog(@"ERROR SENDING HERE: %@", [error localizedDescription]);
                                 }
                                 
                                 //Delete the zipped/unzipped files after sending
                                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
                                     
                                     NSError *deleteError;
                                     //[[NSFileManager defaultManager] removeItemAtPath:messageAttachments.pathToUnzippedAttachment error:&deleteError];
                                     [[NSFileManager defaultManager] removeItemAtPath:self.currentlyOpenMessageAttachment.pathToZipFolder error:&deleteError];
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
