//
//  MessageAttachments.h
//  TouchLock
//
//  Created by Ryan D'souza on 4/10/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RNEncryptor.h"

#import "Constants.h"
#import "MessageAttachment.h"

/**
 Represents the attributes of a Message Attachment
 Like the file locations of various media
 */


static NSString *FILE_NAME_KEY = @"fileName";
static NSString *MEDIA_TYPE_KEY = @"mediaTypeKey";


@interface MessageAttachments : NSObject

- (instancetype) init;

@property (strong, nonatomic) NSString *folderName;
@property (strong, nonatomic) NSString *pathToAttachmentFolder;
@property (strong, nonatomic) NSString *pathToMetaFileInAttachmentFolder;

@property (strong, nonatomic) NSString *zipFolderName;
@property (strong, nonatomic) NSString *pathToZipFolder;

@property (strong, nonatomic) NSString *messageID;
@property (strong, nonatomic) NSString *messageEncryptionKey;

@property (strong, nonatomic) NSMutableArray<MessageAttachment*> *messageAttachments;
@property (strong, nonatomic) NSMutableArray<NSMutableDictionary*> *metaFileList;

- (void) addImageAttachment:(UIImage*)image;
- (void) addVideoAttachmentAtURL:(NSURL*)videoURL;
- (void) addPrivateTextFileWithData:(NSData*)textFileData;

- (void) storeAttachmentsInDatabase;

- (int) totalNumberOfAttachments;
- (int) numberOfImagesInMetaFileList;
- (int) numberOfVideosInMetaFileList;
- (int) numberOfPrivateTextFilesInMetaFileList;

- (NSString*) getAttachmentsDescriptiveString;

- (void) saveMetaFileListToFile;
- (void) loadMetaFileListFromFile;

@end
