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

@property (strong, nonatomic) MWPhotoBrowser *photoBrowserViewController;
@property (strong, nonatomic) NSMutableArray *receivingMediaArray;

@end

@implementation MessagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(!self) {
        self.receivingMediaArray = [[NSMutableArray alloc] init];
    }
    
    [self showCompactDefaultView];
}

- (void) pressedSendTextButton
{
    
}

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets
{
    
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
        const int totalNumberOfItems = (int) [assets count];
        
        //Set up folders for temporarily saving everything
        NSError *error;
        
        NSString *documentsDirectory = [Constants getDocumentsDirectory];
        NSString *currentSendName = [Constants getSendFormatUsingCurrentDate];
        
        NSString *currentSendZIPPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip", currentSendName]];
        
        NSString *currentSendFolder = [documentsDirectory stringByAppendingPathComponent:currentSendName];
        [fileManager createDirectoryAtPath:currentSendFolder withIntermediateDirectories:YES attributes:nil error:&error];
        
        NSString *currentSendImagesFolder = [currentSendFolder stringByAppendingPathComponent:@"images"];
        [fileManager createDirectoryAtPath:currentSendImagesFolder withIntermediateDirectories:YES attributes:nil error:&error];
        
        NSString *currentSendVideosFolder = [currentSendFolder stringByAppendingPathComponent:@"videos"];
        [fileManager createDirectoryAtPath:currentSendVideosFolder withIntermediateDirectories:YES attributes:nil error:&error];
        
        
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
                                    [pngImageData writeToFile:[currentSendImagesFolder stringByAppendingPathComponent:imageFileName] atomically:YES];
                                    
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
                                           NSURL *videoFileURL = [NSURL fileURLWithPath:[currentSendVideosFolder stringByAppendingPathComponent:videoFileName]];
                                           
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
        
        
        [SSZipArchive createZipFileAtPath:currentSendZIPPath withContentsOfDirectory:currentSendFolder];
        
        NSData *encryptedData = [RNEncryptor encryptData:[NSData dataWithContentsOfFile:currentSendZIPPath]
                                            withSettings:kRNCryptorAES256Settings
                                                password:encryptionKey
                                                   error:&error];
        
        if(error) {
            NSLog(@"ERROR ENCRYPTING MESSAGE: %@: ", [error description]);
        }
        
        [encryptedData writeToFile:currentSendZIPPath atomically:YES];
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
        NSLog(@"MESSAGE ID: %@", [messageIDItem value]);
        
        [urlComponents setQueryItems:@[encryptionItem, sendNameItem, messageIDItem]];
        
        NSLog(@"SEND ZIP: %@", currentSendZIPPath);
        
        MSSession *messageSession = [[MSSession alloc] init];
        MSMessage *message = [[MSMessage alloc] initWithSession:messageSession];
        messageLayout.mediaFileURL = [NSURL fileURLWithPath:currentSendZIPPath];
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
                                         [fileManager removeItemAtPath:currentSendZIPPath error:&deleteError];
                                     });
                                 }
             ];
            
            [[self.imagePickerController view] removeFromSuperview];
            
        });
        
        [fileManager removeItemAtPath:currentSendFolder error:&error];
        
    });

    [[self.imagePickerController view] removeFromSuperview];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController
{
    [[self.imagePickerController view] removeFromSuperview];
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
}

-(void)didBecomeActiveWithConversation:(MSConversation *)conversation
{
    // Called when the extension is about to move from the inactive to active state.
    // This will happen when the extension is about to present UI.
    
    // Use this method to configure the extension and restore previously stored state.
    NSLog(@"ACTIVE NOW");
    
    if([conversation selectedMessage]) {
        NSLog(@"FOUND MESSAGE");
        
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
    
        NSString *documentsDirectory = [Constants getDocumentsDirectory];
        NSString *zippedFilePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip", fileName]];
        NSString *unzippedFolderPath = [documentsDirectory stringByAppendingPathComponent:fileName];
        
        NSString *currentImagesFolder = [unzippedFolderPath stringByAppendingPathComponent:@"images"];
        NSString *currentVideosFolder = [unzippedFolderPath stringByAppendingPathComponent:@"videos"];
        
        NSURL *zipFileURL = [NSURL fileURLWithPath:[[NSUserDefaults standardUserDefaults] objectForKey:messageID]];
        NSData *decryptedData = [RNDecryptor decryptData:[NSData dataWithContentsOfURL:zipFileURL]
                                            withPassword:encryptionKey
                                                   error:&error];
        
        if(error || !decryptedData) {
            NSLog(@"ERROR DECRYPTING: %@", [error description]);
        }
        
        [decryptedData writeToFile:zippedFilePath atomically:YES];
        decryptedData = nil;
        
        [SSZipArchive unzipFileAtPath:zippedFilePath toDestination:unzippedFolderPath];
        
        int numberOfImages = (int) [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:currentImagesFolder error:&error] count];
        int numberOfVideos = (int) [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:currentVideosFolder error:&error] count];
        
        self.receivingMediaArray = [[NSMutableArray alloc] init];
        
        NSArray *receivedImages = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:currentImagesFolder error:&error];
        NSArray *receivedVideos = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:currentVideosFolder error:&error];
        
        
        if(receivedImages) {
            for(NSString *fileName in receivedImages) {
                if(![fileName isEqualToString:@".DS_Store"]) {
                    NSString *filePath = [currentImagesFolder stringByAppendingPathComponent:fileName];
                    
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
                    
                    NSString *filePath = [currentVideosFolder stringByAppendingPathComponent:fileName];
                    
                    
                    NSLog(@"GOING THROUGH VIDEO: %@", filePath);
                    
                    NSURL *videoFilePath = [NSURL fileURLWithPath:filePath];
                    
                    UIImage *firstFrame = [MessagesViewController thumbnailImageForVideo:videoFilePath atTime:0.1];
                    
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
        
        CGRect newSize = CGRectMake(0, self.topLayoutGuide.length, self.view.frame.size.width, self.view.frame.size.height - self.topLayoutGuide.length);
        
        [[self.photoBrowserViewController view] setFrame:newSize];
        [self.view addSubview:[self.photoBrowserViewController view]];
        
        
        // Manipulate
        [self.photoBrowserViewController showNextPhotoAnimated:YES];
        [self.photoBrowserViewController showPreviousPhotoAnimated:YES];
        
    }
    
}

-(id <MWPhoto>) photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index{
    NSLog(@"Thumb Delegate Called!");
    if(index < [self.receivingMediaArray count]) {
        return [self.receivingMediaArray objectAtIndex:index];
    }
    return nil;
}

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return [self.receivingMediaArray count];
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    NSLog(@"CHECKING INDEX: %ld", index);
    
    if (index < [self.receivingMediaArray count]) {
        return [self.receivingMediaArray objectAtIndex:index];
    }
    return nil;
}


+ (UIImage *)thumbnailImageForVideo:(NSURL *)videoURL
                             atTime:(NSTimeInterval)time
{
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    AVAssetImageGenerator *assetIG =
    [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetIG.appliesPreferredTrackTransform = YES;
    assetIG.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CGImageRef thumbnailImageRef = NULL;
    CFTimeInterval thumbnailImageTime = time;
    NSError *igError = nil;
    thumbnailImageRef =
    [assetIG copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)
                    actualTime:NULL
                         error:&igError];
    
    if (!thumbnailImageRef)
        NSLog(@"thumbnailImageGenerationError %@", igError );
    
    UIImage *thumbnailImage = thumbnailImageRef
    ? [[UIImage alloc] initWithCGImage:thumbnailImageRef]
    : nil;
    
    return thumbnailImage;
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

static NSURL *receivedURL;

-(void)didReceiveMessage:(MSMessage *)message conversation:(MSConversation *)conversation
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

@end
