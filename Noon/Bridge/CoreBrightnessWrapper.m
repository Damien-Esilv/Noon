//
//  CoreBrightnessWrapper.m
//  Noon
//
//  Copyright © 2026 Sunazur. All rights reserved.
//  Licensed under CC BY-NC-SA 4.0.
//

#import "CoreBrightnessWrapper.h"
#import "CoreBrightnessHeaders.h"

NSString * const CBWrapperErrorDomain = @"com.noon.CoreBrightnessWrapper";

@interface CoreBrightnessWrapper ()

@property (nonatomic, strong) id blueLightClient;   // CBBlueLightClient instance
@property (nonatomic, strong) id trueToneClient;     // CBTrueToneClient instance
@property (nonatomic, assign) BOOL frameworkLoaded;

@end

@implementation CoreBrightnessWrapper

// MARK: - Singleton

+ (instancetype)shared {
    static CoreBrightnessWrapper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CoreBrightnessWrapper alloc] init];
    });
    return instance;
}

// MARK: - Initialization

- (instancetype)init {
    self = [super init];
    if (self) {
        _frameworkLoaded = NO;
        [self loadFramework];
    }
    return self;
}

- (void)loadFramework {
    // Attempt to load CoreBrightness.framework dynamically
    NSBundle *bundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/CoreBrightness.framework"];
    
    if (!bundle) {
        NSLog(@"[Noon] CoreBrightness.framework not found at expected path.");
        self.frameworkLoaded = NO;
        return;
    }
    
    NSError *loadError = nil;
    if (![bundle loadAndReturnError:&loadError]) {
        NSLog(@"[Noon] Failed to load CoreBrightness.framework: %@", loadError.localizedDescription);
        self.frameworkLoaded = NO;
        return;
    }
    
    // Instantiate CBBlueLightClient
    Class BlueLightClass = NSClassFromString(@"CBBlueLightClient");
    if (BlueLightClass) {
        self.blueLightClient = [[BlueLightClass alloc] init];
        NSLog(@"[Noon] CBBlueLightClient instantiated successfully.");
    } else {
        NSLog(@"[Noon] CBBlueLightClient class not found in CoreBrightness.");
    }
    
    // Instantiate CBTrueToneClient
    Class TrueToneClass = NSClassFromString(@"CBTrueToneClient");
    if (TrueToneClass) {
        self.trueToneClient = [[TrueToneClass alloc] init];
        NSLog(@"[Noon] CBTrueToneClient instantiated successfully.");
    } else {
        NSLog(@"[Noon] CBTrueToneClient class not found in CoreBrightness.");
    }
    
    self.frameworkLoaded = (self.blueLightClient != nil || self.trueToneClient != nil);
    NSLog(@"[Noon] CoreBrightness framework loaded: %@", self.frameworkLoaded ? @"YES" : @"NO");
}

// MARK: - Properties

- (BOOL)isFrameworkLoaded {
    return self.frameworkLoaded;
}

- (BOOL)isTrueToneSupported {
    if (!self.trueToneClient) return NO;
    
    @try {
        return [(CBTrueToneClient *)self.trueToneClient supported];
    } @catch (NSException *exception) {
        NSLog(@"[Noon] Exception checking True Tone support: %@", exception.reason);
        return NO;
    }
}

// MARK: - Night Shift

- (BOOL)isNightShiftEnabledWithError:(NSError **)error {
    if (!self.blueLightClient) {
        if (error) {
            *error = [self errorWithCode:CBWrapperErrorClientNotAvailable
                                 message:@"CBBlueLightClient is not available."];
        }
        return NO;
    }
    
    @try {
        CBBlueLightStatus status;
        memset(&status, 0, sizeof(CBBlueLightStatus));
        BOOL success = [(CBBlueLightClient *)self.blueLightClient getBlueLightStatus:&status];
        
        if (!success) {
            if (error) {
                *error = [self errorWithCode:CBWrapperErrorOperationFailed
                                     message:@"Failed to get Night Shift status."];
            }
            return NO;
        }
        
        return status.enabled;
    } @catch (NSException *exception) {
        if (error) {
            *error = [self errorWithCode:CBWrapperErrorOperationFailed
                                 message:[NSString stringWithFormat:@"Exception: %@", exception.reason]];
        }
        return NO;
    }
}

- (BOOL)setNightShiftEnabled:(BOOL)enabled error:(NSError **)error {
    if (!self.blueLightClient) {
        if (error) {
            *error = [self errorWithCode:CBWrapperErrorClientNotAvailable
                                 message:@"CBBlueLightClient is not available."];
        }
        return NO;
    }
    
    @try {
        BOOL success = [(CBBlueLightClient *)self.blueLightClient setEnabled:enabled];
        
        if (!success) {
            if (error) {
                *error = [self errorWithCode:CBWrapperErrorOperationFailed
                                     message:@"Failed to set Night Shift state."];
            }
            return NO;
        }
        
        NSLog(@"[Noon] Night Shift set to: %@", enabled ? @"ON" : @"OFF");
        return YES;
    } @catch (NSException *exception) {
        if (error) {
            *error = [self errorWithCode:CBWrapperErrorOperationFailed
                                 message:[NSString stringWithFormat:@"Exception: %@", exception.reason]];
        }
        return NO;
    }
}

- (float)nightShiftStrengthWithError:(NSError **)error {
    if (!self.blueLightClient) {
        if (error) {
            *error = [self errorWithCode:CBWrapperErrorClientNotAvailable
                                 message:@"CBBlueLightClient is not available."];
        }
        return 0.0;
    }
    
    @try {
        float strength = 0.0;
        BOOL success = [(CBBlueLightClient *)self.blueLightClient getStrength:&strength];
        
        if (!success) {
            if (error) {
                *error = [self errorWithCode:CBWrapperErrorOperationFailed
                                     message:@"Failed to get Night Shift strength."];
            }
            return 0.0;
        }
        
        return strength;
    } @catch (NSException *exception) {
        if (error) {
            *error = [self errorWithCode:CBWrapperErrorOperationFailed
                                 message:[NSString stringWithFormat:@"Exception: %@", exception.reason]];
        }
        return 0.0;
    }
}

// MARK: - True Tone

- (BOOL)isTrueToneEnabledWithError:(NSError **)error {
    if (!self.trueToneClient) {
        if (error) {
            *error = [self errorWithCode:CBWrapperErrorClientNotAvailable
                                 message:@"CBTrueToneClient is not available."];
        }
        return NO;
    }
    
    @try {
        return [(CBTrueToneClient *)self.trueToneClient enabled];
    } @catch (NSException *exception) {
        if (error) {
            *error = [self errorWithCode:CBWrapperErrorOperationFailed
                                 message:[NSString stringWithFormat:@"Exception: %@", exception.reason]];
        }
        return NO;
    }
}

- (BOOL)setTrueToneEnabled:(BOOL)enabled error:(NSError **)error {
    if (!self.trueToneClient) {
        if (error) {
            *error = [self errorWithCode:CBWrapperErrorClientNotAvailable
                                 message:@"CBTrueToneClient is not available."];
        }
        return NO;
    }
    
    if (![self isTrueToneSupported]) {
        if (error) {
            *error = [self errorWithCode:CBWrapperErrorNotSupported
                                 message:@"True Tone is not supported on this hardware."];
        }
        return NO;
    }
    
    @try {
        BOOL success = [(CBTrueToneClient *)self.trueToneClient setEnabled:enabled];
        
        if (!success) {
            if (error) {
                *error = [self errorWithCode:CBWrapperErrorOperationFailed
                                     message:@"Failed to set True Tone state."];
            }
            return NO;
        }
        
        NSLog(@"[Noon] True Tone set to: %@", enabled ? @"ON" : @"OFF");
        return YES;
    } @catch (NSException *exception) {
        if (error) {
            *error = [self errorWithCode:CBWrapperErrorOperationFailed
                                 message:[NSString stringWithFormat:@"Exception: %@", exception.reason]];
        }
        return NO;
    }
}

// MARK: - Lifecycle

- (BOOL)reloadFramework {
    self.blueLightClient = nil;
    self.trueToneClient = nil;
    self.frameworkLoaded = NO;
    
    [self loadFramework];
    return self.frameworkLoaded;
}

// MARK: - Helpers

- (NSError *)errorWithCode:(CBWrapperErrorCode)code message:(NSString *)message {
    return [NSError errorWithDomain:CBWrapperErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

@end
