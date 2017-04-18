//
//  Constants.m
//  TouchLock
//
//  Created by Ryan D'souza on 4/5/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import "Constants.h"

static NSString *attachmentsAppGroupIdentifier = @"group.com.ryan.Touch-Lock";

@implementation Constants

/** Generates a 64-byte encryption key */
+ (NSData*) generateEncryptionKeyForRealmDB
{
    NSMutableData *key = [NSMutableData dataWithLength:64];
    (void)SecRandomCopyBytes(kSecRandomDefault, key.length, (uint8_t *)key.mutableBytes);
    
    return key;
}

/** Returns a 64-byte encryption key to decrypt RealmDB. If it's not present, creates and saves the encryption key */
+ (NSData*) getEncryptionKeyForRealmDB
{
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"group.com.ryan.Touch-Lock-Shared-Secure"];
    
    NSData *encryptionKey = nil;
    
    if([keychain contains:@"realm_db_encryption_key"]) {
        encryptionKey = [keychain dataForKey:@"realm_db_encryption_key"];
    }
    
    else {
        encryptionKey = [Constants generateEncryptionKeyForRealmDB];
        [keychain setData:encryptionKey forKey:@"realm_db_encryption_key"];
    }
    
    return encryptionKey;
}

+ (RLMRealm*) getRealmDBInstance
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSURL *databaseLocation = [fileManager containerURLForSecurityApplicationGroupIdentifier:attachmentsAppGroupIdentifier];
    databaseLocation = [[databaseLocation URLByAppendingPathComponent:@"file_storage"] URLByAppendingPathExtension:@"realm"];
    
    RLMRealmConfiguration *realmConfiguration = [RLMRealmConfiguration defaultConfiguration];
    [realmConfiguration setEncryptionKey:[Constants getEncryptionKeyForRealmDB]];
    [realmConfiguration setFileURL:databaseLocation];
    
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:realmConfiguration error:&error];
    
    if (!realm) {
        NSLog(@"ERROR OPENING REALM: %@", error);
    }
    
    return realm;
}

+ (NSString*) getAttachmentsDirectory
{
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSString *sharedDirectory = [[defaultManager containerURLForSecurityApplicationGroupIdentifier:attachmentsAppGroupIdentifier] path];
    
    return [sharedDirectory stringByAppendingPathComponent:@"attachments"];
}

+ (NSString*) generateAttachmentsDirectory
{
    NSString *folderName = [[NSUUID UUID] UUIDString];
    return [self generateAttachmentsDirectoryForFolderName:folderName];
}

+ (NSString*) generateAttachmentsDirectoryForFolderName:(NSString *)folderName
{
    NSString *attachmentsDirectory = [Constants getAttachmentsDirectory];
    NSString *fullPath = [attachmentsDirectory stringByAppendingPathComponent:folderName];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
        
        [[NSFileManager defaultManager] createDirectoryAtPath:fullPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    
    return fullPath;
}

+ (NSUserDefaults*) sharedUserDefaults
{
    return [[NSUserDefaults alloc] initWithSuiteName:@"group.com.ryan.Touch-Lock-Shared"];
}

+ (UIImage*) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time
{
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    NSParameterAssert(asset);
    
    AVAssetImageGenerator *assetIG = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetIG.appliesPreferredTrackTransform = YES;
    assetIG.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    CFTimeInterval thumbnailImageTime = time;
    NSError *igError = nil;
    CGImageRef thumbnailImageRef = [assetIG copyCGImageAtTime:CMTimeMake(thumbnailImageTime, 60)
                                                   actualTime:NULL
                                                        error:&igError];
    
    if (!thumbnailImageRef) {
        NSLog(@"thumbnailImageGenerationError %@", igError );
    }
    
    UIImage *thumbnailImage = thumbnailImageRef ? [[UIImage alloc] initWithCGImage:thumbnailImageRef]: nil;
    
    return thumbnailImage;
}

+ (NSArray*) getPHAssetCollectionSubtypes
{
    return @[
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
}

+ (NSString*) getDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

+ (NSString*) getSendFormatUsingCurrentDate
{
    NSDateFormatter *currentSendFormat = [[NSDateFormatter alloc] init];
    [currentSendFormat setDateFormat:@"dd-MM-yy HH:mm:ss"];
    return [currentSendFormat stringFromDate:[NSDate date]];
}

+ (PHImageRequestOptions*) getPhotoRequestOptions
{
    PHImageRequestOptions *photoRequestOptions = [[PHImageRequestOptions alloc] init];
    [photoRequestOptions setResizeMode:PHImageRequestOptionsResizeModeNone];
    [photoRequestOptions setDeliveryMode:PHImageRequestOptionsDeliveryModeHighQualityFormat];
    [photoRequestOptions setSynchronous:YES];
    [photoRequestOptions setNetworkAccessAllowed:YES];
    [photoRequestOptions setVersion:PHImageRequestOptionsVersionOriginal];
    
    return photoRequestOptions;
}

+ (PHVideoRequestOptions*) getVideoRequestOptions
{
    PHVideoRequestOptions *videoRequestOptions = [[PHVideoRequestOptions alloc] init];
    [videoRequestOptions setDeliveryMode:PHVideoRequestOptionsDeliveryModeHighQualityFormat];
    [videoRequestOptions setVersion:PHVideoRequestOptionsVersionOriginal];
    [videoRequestOptions setNetworkAccessAllowed:YES];
    
    return videoRequestOptions;
}

+ (NSString*) generateEncryptionKey
{
    //Long, randomly generated string --> each UUID = 36 characters long
    NSMutableString *encryptionKey = [[NSMutableString alloc] init];
    for(int i = 0; i < 5; i++) {
        [encryptionKey appendString:[[NSUUID UUID] UUIDString]];
    }
    
    return encryptionKey;
}


@end
