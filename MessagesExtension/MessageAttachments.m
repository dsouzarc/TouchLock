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
    NSString *attachmentName = [Constants getSendFormatUsingCurrentDate];
    self = [self initWithAttachmentName:attachmentName];
    
    return self;
}

- (instancetype) initWithAttachmentName:(NSString*)attachmentName
{
    self = [super init];
    
    if(self) {
        
        self.attachmentName = attachmentName;
        self.isOutgoingMessage = NO;
        self.metaFileList = [[NSMutableArray alloc] init];
        
        //Zipped and Unzipped path locations
        NSString *documentsDirectory = [Constants getDocumentsDirectory];
        self.pathToUnzippedAttachment = [documentsDirectory stringByAppendingPathComponent:attachmentName];
        self.pathToZippedAttachment = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip", attachmentName]];
        
        self.pathToMetaFile = [self.pathToUnzippedAttachment stringByAppendingPathComponent:@"meta.out"];
        
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:self.pathToUnzippedAttachment
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
    }
    
    return self;
}

- (void) addImageWithNameToMetaFile:(NSString *)imageName
{
    NSMutableDictionary *fileDescription = [[NSMutableDictionary alloc] init];
    [fileDescription setValue:imageName forKey:FILE_NAME_KEY];
    [fileDescription setValue:IMAGE_IDENTIFIER forKey:MEDIA_TYPE_KEY];
    
    [self.metaFileList addObject:fileDescription];
}

- (void) addVideoWithNameToMetaFile:(NSString *)videoName
{
    NSMutableDictionary *fileDescription = [[NSMutableDictionary alloc] init];
    [fileDescription setValue:videoName forKey:FILE_NAME_KEY];
    [fileDescription setValue:VIDEO_IDENTIFIER forKey:MEDIA_TYPE_KEY];
    
    [self.metaFileList addObject:fileDescription];
}

- (void) addPrivateTextFileWithNameToMetaFile:(NSString *)privateTextFileName
{
    NSMutableDictionary *fileDescription = [[NSMutableDictionary alloc] init];
    [fileDescription setValue:privateTextFileName forKey:FILE_NAME_KEY];
    [fileDescription setValue:PRIVATE_TEXTFILE_IDENTIFIER forKey:MEDIA_TYPE_KEY];
    
    [self.metaFileList addObject:fileDescription];
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

- (void) saveMetaFileListToFile
{
    [self.metaFileList writeToFile:self.pathToMetaFile atomically:YES];
}

- (void) loadMetaFileListFromFile
{
    if([[NSFileManager defaultManager] fileExistsAtPath:self.pathToMetaFile]) {
        self.metaFileList = [[NSMutableArray alloc] initWithContentsOfFile:self.pathToMetaFile];
    }
    
    if(!self.metaFileList) {
        self.metaFileList = [[NSMutableArray alloc] init];
    }
}

@end
