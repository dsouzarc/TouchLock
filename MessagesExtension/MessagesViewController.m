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
        
        //Managers
        NSFileManager *fileManager = [NSFileManager defaultManager];
        PHImageManager *photoManager = [PHImageManager defaultManager];
        
        //Image request options
        PHImageRequestOptions *photoRequestOptions = [[PHImageRequestOptions alloc] init];
        [photoRequestOptions setResizeMode:PHImageRequestOptionsResizeModeNone];
        [photoRequestOptions setDeliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat];
        [photoRequestOptions setSynchronous:YES];
        [photoRequestOptions setNetworkAccessAllowed:YES];
        [photoRequestOptions setVersion:PHImageRequestOptionsVersionOriginal];
        
        //Video request options
        PHVideoRequestOptions *videoRequestOptions = [[PHVideoRequestOptions alloc] init];
        [videoRequestOptions setDeliveryMode:PHVideoRequestOptionsDeliveryModeHighQualityFormat];
        [videoRequestOptions setVersion:PHVideoRequestOptionsVersionOriginal];
        [videoRequestOptions setNetworkAccessAllowed:YES];
        
        __block int numberOfVideosSaved = 0;
        __block int numberOfOtherMediaSaved = 0;
        const int totalNumberOfItems = (int) [assets count];
        
        //Set up folders for temporarily saving everything
        NSError *error;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSDateFormatter *currentSendFormat = [[NSDateFormatter alloc] init];
        [currentSendFormat setDateFormat:@"dd-MM-yy HH:mm:ss"];
        NSString *currentSendName = [currentSendFormat stringFromDate:[NSDate date]];
        
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
        NSMutableString *encryptionKey = [[NSMutableString alloc] init];
        for(int i = 0; i < 5; i++) {
            [encryptionKey appendString:[[NSUUID UUID] UUIDString]];
        }
        
        //Since we can't load videos synchronously, wait for the rest to finish
        while((numberOfOtherMediaSaved + numberOfVideosSaved) < totalNumberOfItems) {
            sleep(100); //100 milliseconds
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
        [urlComponents setQueryItems:@[encryptionItem, sendNameItem]];
        
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
        MSMessageTemplateLayout *messageLayout = (MSMessageTemplateLayout*) [message layout];
        
        NSURL *zipFileURL = receivedURL; //[messageLayout mediaFileURL];
        
        NSLog(@"RECEIVED ZIP FILE URL: %@", [zipFileURL path]);
        
        NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:[message URL] resolvingAgainstBaseURL:NO];
        
        NSString *encryptionKey = @"";
        NSString *fileName = @"";
        for(NSURLQueryItem *queryItem in [urlComponents queryItems]) {
            if([[queryItem name] isEqualToString:@"encryption_key"]) {
                encryptionKey = [queryItem value];
            }
            
            else if([[queryItem name] isEqualToString:@"send_name"]) {
                fileName = [queryItem value];
            }
        }
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        
        NSString *zippedFilePath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip", fileName]];
        NSString *unzippedFolderPath = [documentsDirectory stringByAppendingPathComponent:fileName];
        
        if([NSData dataWithContentsOfURL:zipFileURL]) {
            NSLog(@"RECEIVED ENCRYPTED DATA: %@\t%@\t%@", zipFileURL.path, zippedFilePath, unzippedFolderPath);
            
        }

        NSData *decryptedData = [RNDecryptor decryptData:[NSData dataWithContentsOfURL:zipFileURL]
                                            withPassword:encryptionKey
                                                   error:&error];
        
        if(error || !decryptedData) {
            NSLog(@"ERROR DECRYPTING: %@", [error description]);
        } else {
            NSLog(@"DECRYPTED SUCCESSFULLY");
        }
        
        [decryptedData writeToFile:zippedFilePath atomically:YES];
        decryptedData = nil;
        
        [SSZipArchive unzipFileAtPath:zippedFilePath toDestination:unzippedFolderPath];
        
        NSString *currentImagesFolder = [unzippedFolderPath stringByAppendingPathComponent:@"images"];
        NSString *currentVideosFolder = [unzippedFolderPath stringByAppendingPathComponent:@"videos"];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:currentVideosFolder]) {
            NSLog(@"FOUND IMAGES!!!!");
        }
        
        int numberOfImages = (int) [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:currentImagesFolder error:&error] count];
        int numberOfVideos = (int) [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:currentVideosFolder error:&error] count];
        
        NSLog(@"RECEIVED: %d\t%d", numberOfImages, numberOfVideos);
        
        
        //  Code for loading image by decryption
       /* NSString  *imagePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/encryptedImage.pdf"];
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
        }];*/
        
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
static NSURL *receivedURL;

-(void)didReceiveMessage:(MSMessage *)message conversation:(MSConversation *)conversation
{
    // Called when a message arrives that was generated by another instance of this
    // extension on a remote device.
    
    // Use this method to trigger UI updates in response to the message.
    
    NSLog(@"RECEIVED MESSAGE");
    
    MSMessageTemplateLayout *templateLayout = (MSMessageTemplateLayout*) message.layout;
    
    NSLog(@"%@", templateLayout ? @"GOT TEMPLATE" : @"NO TEMPLATE");
    receivedURL = [templateLayout mediaFileURL];
    if([[NSFileManager defaultManager] fileExistsAtPath:[[templateLayout mediaFileURL] path]]) {
        NSLog(@"GOT IT!!L :%@", [[templateLayout mediaFileURL] path]);
    }
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
