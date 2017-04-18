//
//  MessageAttachments.m
//  TouchLock
//
//  Created by Ryan D'souza on 4/10/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

/**
 Represents the attributes of a Message Attachment
 Like the file locations of various media
 */

#import "MessageAttachments.h"


@implementation MessageAttachments

- (instancetype) init
{
    self = [super init];
    
    if(self) {
    
        self.folderName = [[NSUUID UUID] UUIDString];
        self.pathToAttachmentFolder = [Constants generateAttachmentsDirectoryForFolderName:self.folderName];
        self.pathToMetaFileInAttachmentFolder = [self.pathToAttachmentFolder stringByAppendingPathComponent:@".META_FILE"];
        
        self.zipFolderName = [NSString stringWithFormat:@"%@.zip", self.folderName];
        self.pathToZipFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:self.zipFolderName];
        
        self.messageID = self.folderName;
        self.messageEncryptionKey = [Constants generateEncryptionKey];
        
        self.messageAttachments = [[NSMutableArray alloc] init];
        self.metaFileList = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void) addImageAttachment:(UIImage *)image
{
    NSString *imageName = [NSString stringWithFormat:@"%@.jpeg", [[NSUUID UUID] UUIDString]];
    NSString *pathToImage = [self.pathToAttachmentFolder stringByAppendingPathComponent:imageName];
    
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    [imageData writeToFile:pathToImage atomically:YES];
    imageData = nil;
    
    /* NSError *error;
    NSData *encryptedData = [RNEncryptor encryptData:imageData withSettings:kRNCryptorAES256Settings password:self.messageEncryptionKey error:&error];
    [encryptedData writeToFile:pathToImage atomically:YES];
    encryptedData = nil; */
    
    MessageAttachment *messageAttachment = [MessageAttachment generateMessageAttachmentForMessageID:self.messageID
                                                                                    messageSendTime:[NSDate date]
                                                                                  isOutgoingMessage:YES
                                                                                           fileType:IMAGE_IDENTIFIER
                                                                                       fileLocation:pathToImage
                                                                                      encryptionKey:self.messageEncryptionKey];
    [self.messageAttachments addObject:messageAttachment];
    
    
    NSMutableDictionary *fileDescription = [[NSMutableDictionary alloc] init];
    [fileDescription setValue:pathToImage forKey:FILE_NAME_KEY];
    [fileDescription setValue:IMAGE_IDENTIFIER forKey:MEDIA_TYPE_KEY];
    [self.metaFileList addObject:fileDescription];
}

- (void) addVideoAttachmentAtURL:(NSURL *)videoURL
{
    NSString *videoName = [NSString stringWithFormat:@"%@.MOV", [[NSUUID UUID] UUIDString]];
    NSString *pathToVideo = [self.pathToAttachmentFolder stringByAppendingPathComponent:videoName];
    
    NSError *error;
    [[NSFileManager defaultManager] copyItemAtPath:[videoURL path] toPath:pathToVideo error:&error];

    MessageAttachment *messageAttachment = [MessageAttachment generateMessageAttachmentForMessageID:self.messageID
                                                                                    messageSendTime:[NSDate date]
                                                                                  isOutgoingMessage:YES
                                                                                           fileType:VIDEO_IDENTIFIER
                                                                                       fileLocation:pathToVideo
                                                                                      encryptionKey:self.messageEncryptionKey];
    [self.messageAttachments addObject:messageAttachment];
    
    NSMutableDictionary *fileDescription = [[NSMutableDictionary alloc] init];
    [fileDescription setValue:pathToVideo forKey:FILE_NAME_KEY];
    [fileDescription setValue:IMAGE_IDENTIFIER forKey:MEDIA_TYPE_KEY];
    [self.metaFileList addObject:fileDescription];
}

- (void) addPrivateTextFileWithData:(NSData *)textFileData
{
    NSString *textfileName = [NSString stringWithFormat:@"%@.out", [[NSUUID UUID] UUIDString]];
    NSString *pathToTextFile = [self.pathToAttachmentFolder stringByAppendingPathComponent:textfileName];
    
    [textFileData writeToFile:pathToTextFile atomically:YES];
    
    MessageAttachment *messageAttachment = [MessageAttachment generateMessageAttachmentForMessageID:self.messageID
                                                                                    messageSendTime:[NSDate date]
                                                                                  isOutgoingMessage:YES
                                                                                           fileType:PRIVATE_TEXTFILE_IDENTIFIER
                                                                                       fileLocation:pathToTextFile
                                                                                      encryptionKey:self.messageEncryptionKey];
    [self.messageAttachments addObject:messageAttachment];
    
    NSMutableDictionary *fileDescription = [[NSMutableDictionary alloc] init];
    [fileDescription setValue:pathToTextFile forKey:FILE_NAME_KEY];
    [fileDescription setValue:PRIVATE_TEXTFILE_IDENTIFIER forKey:MEDIA_TYPE_KEY];
    [self.metaFileList addObject:fileDescription];
}

- (void) storeAttachmentsInDatabase
{
    RLMRealm *realmDB = [Constants getRealmDBInstance];
    [realmDB beginWriteTransaction];
    [realmDB addObjects:self.messageAttachments];
    [realmDB commitWriteTransaction];
    
    RLMResults<MessageAttachment*> *allMessageAttachments = [MessageAttachment allObjectsInRealm:realmDB];
    for(MessageAttachment *messageAttachment in allMessageAttachments) {
        NSLog(@"FOUND ATTACHMENT: %@", messageAttachment.fileLocation);
    }
}

- (int) totalNumberOfAttachments
{
    return (int) [self.metaFileList count];
}

- (int) numberOfImagesInMetaFileList
{
    return [self getCountOfMediaTypeKeyInMetaFileList:IMAGE_IDENTIFIER];
}

- (int) numberOfVideosInMetaFileList
{
    return [self getCountOfMediaTypeKeyInMetaFileList:VIDEO_IDENTIFIER];
}

- (int) numberOfPrivateTextFilesInMetaFileList
{
    return [self getCountOfMediaTypeKeyInMetaFileList:PRIVATE_TEXTFILE_IDENTIFIER];
}

- (int) getCountOfMediaTypeKeyInMetaFileList:(NSString*)mediaTypeKey
{
    int counter = 0;
    
    for(NSMutableDictionary *fileAttributes in self.metaFileList) {
        if([[fileAttributes valueForKey:MEDIA_TYPE_KEY] isEqualToString:mediaTypeKey]) {
            counter++;
        }
    }
    
    return counter;
}

- (NSString*) getAttachmentsDescriptiveString
{
    int numVideos = 0;
    int numPrivateTextFiles = 0;
    int numImages = 0;
    
    for(NSMutableDictionary *fileAttributes in self.metaFileList) {
        if([[fileAttributes valueForKey:MEDIA_TYPE_KEY] isEqualToString:VIDEO_IDENTIFIER]) {
            numVideos++;
        }
        
        else if([[fileAttributes valueForKey:MEDIA_TYPE_KEY] isEqualToString:PRIVATE_TEXTFILE_IDENTIFIER]) {
            numPrivateTextFiles++;
        }
        
        else if([[fileAttributes valueForKey:MEDIA_TYPE_KEY] isEqualToString:IMAGE_IDENTIFIER]) {
            numImages++;
        }
    }
    
    NSMutableString *descriptiveString = [[NSMutableString alloc] init];
    
    if(numImages == 1) {
        [descriptiveString appendString:@"1 Image, "];
    } else {
        [descriptiveString appendString:[NSString stringWithFormat:@"%d Images, ", numImages]];
    }
    
    if(numVideos == 1) {
        [descriptiveString appendString:@"1 Video, "];
    } else {
        [descriptiveString appendString:[NSString stringWithFormat:@"%d Videos, ", numVideos]];
    }
    
    if(numPrivateTextFiles == 1) {
        [descriptiveString appendString:@"1 Private TextFile, "];
    } else {
        [descriptiveString appendString:[NSString stringWithFormat:@"%d Private TextFiles, ", numPrivateTextFiles]];
    }
    
    return descriptiveString;
}

- (void) saveMetaFileListToFile
{
    [self.metaFileList writeToFile:self.pathToMetaFileInAttachmentFolder atomically:YES];
}

- (void) loadMetaFileListFromFile
{
    if([[NSFileManager defaultManager] fileExistsAtPath:self.pathToMetaFileInAttachmentFolder]) {
        self.metaFileList = [[NSMutableArray alloc] initWithContentsOfFile:self.pathToMetaFileInAttachmentFolder];
    }
    
    if(!self.metaFileList) {
        self.metaFileList = [[NSMutableArray alloc] init];
    }
}

@end
