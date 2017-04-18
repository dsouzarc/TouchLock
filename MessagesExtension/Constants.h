//
//  Constants.h
//  TouchLock
//
//  Created by Ryan D'souza on 4/5/17.
//  Copyright © 2017 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

#import <Realm/Realm.h>
#import <UICKeyChainStore/UICKeyChainStore.h>

@interface Constants : NSObject

/** Returns an un-encrypted instance of the encrypted RealmDB that is shared across the app and MessagesExtension */ 
+ (RLMRealm*) getRealmDBInstance;

/** Returns the attachments directory --> shared between iOS app and Messages Extension */
+ (NSString*) getAttachmentsDirectory;

/** Creates a directory inside the attachments directory where the message contents will go */
+ (NSString*) generateAttachmentsDirectory;

/** With the folder name, creates a directory inside the attachments directory where the message contents will go */
+ (NSString*) generateAttachmentsDirectoryForFolderName:(NSString*)folderName;

+ (NSUserDefaults*) sharedUserDefaults;

+ (UIImage*) thumbnailImageForVideo:(NSURL *)videoURL atTime:(NSTimeInterval)time;

+ (NSArray*) getPHAssetCollectionSubtypes;

+ (NSString*) getDocumentsDirectory;
+ (NSString*) getSendFormatUsingCurrentDate;

+ (PHImageRequestOptions*) getPhotoRequestOptions;
+ (PHVideoRequestOptions*) getVideoRequestOptions;

+ (NSString*) generateEncryptionKey;

@end
