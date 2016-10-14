//
// Encapsulate a conversation thread for PullString's Web API.
//
// Copyright (c) 2016 PullString, Inc.
//
// The following source code is licensed under the MIT license.
// See the LICENSE file, or https://opensource.org/licenses/MIT.
//

#import "PSConversation.h"
#import "PSRequest.h"
#import "PSResponse.h"
#import "PSVersionInfo.h"

NSString * const PSCopyright = @"Copyright 2016 PullString, Inc.";
NSString * const PSVersion = @"1.0.1";
NSString * const PSLicense = @"MIT";

@implementation PSConversation
{
    PSRequest *lastRequest;
    PSResponse *lastResponse;
    PSRequest *audioRequest;
    NSMutableData *audioData;
}

- (void) start: (NSString *) projectName
   withRequest: (PSRequest *) request
withCompletion: (void (^)(PSResponse *response))block
{
    projectName = [projectName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    projectName = [projectName lowercaseString];

    NSString *build_type = @"";
    if (request && request.buildType == PSBuildTypeSandbox) {
        build_type = @"sandbox";
    } else if (request && request.buildType == PSBuildTypeStaging) {
        build_type = @"staging";
    }

    NSDictionary *body = [[NSDictionary alloc] initWithObjectsAndKeys:
                          projectName, @"project",
                          build_type, @"build_type",
                          [NSNumber numberWithInt:(request) ? request.timeZoneOffset : 0], @"time_zone_offset",
                          (request && request.participantId) ? request.participantId : @"", @"participant",
                          nil];

    lastRequest = nil;
    lastResponse = nil;
    
    [self sendRequest: [self psGetEndpoint:false]
      withQueryParams: nil
             withBody: [self dictionaryToJson:body]
          withHeaders: nil
          withRequest: request
       withCompletion: block];
}

- (void) sendText: (NSString *) text
      withRequest: (PSRequest *) request
   withCompletion: (void (^)(PSResponse *response))block
{
    NSDictionary *body = [[NSDictionary alloc] initWithObjectsAndKeys:
                          text, @"text",
                          nil];
    
    [self sendRequest: [self psGetEndpoint:true]
      withQueryParams: nil
             withBody: [self dictionaryToJson:body]
          withHeaders: nil
          withRequest: request
       withCompletion: block];
}

- (void) sendActivity: (NSString *) activity
          withRequest: (PSRequest *) request
       withCompletion: (void (^)(PSResponse *response))block
{
    NSDictionary *body = [[NSDictionary alloc] initWithObjectsAndKeys:
                          activity, @"activity",
                          nil];
    
    [self sendRequest: [self psGetEndpoint:true]
      withQueryParams: nil
             withBody: [self dictionaryToJson:body]
          withHeaders: nil
          withRequest: request
       withCompletion: block];
}

- (void) sendEvent: (NSString *) event
        withParams: (NSDictionary *) parameters
       withRequest: (PSRequest *) request
    withCompletion: (void (^)(PSResponse *response))block
{
    NSMutableDictionary *ev = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                               event, @"name",
                               parameters, @"parameters",
                               nil];

    NSDictionary *body = [[NSDictionary alloc] initWithObjectsAndKeys:
                          ev, @"event",
                          nil];
    
    [self sendRequest: [self psGetEndpoint:true]
      withQueryParams: nil
             withBody: [self dictionaryToJson:body]
          withHeaders: nil
          withRequest: request
       withCompletion: block];
}

- (void) goTo: (NSString *) responseId
  withRequest: (PSRequest *) request
withCompletion: (void (^)(PSResponse *response))block
{
    NSDictionary *body = [[NSDictionary alloc] initWithObjectsAndKeys:
                          responseId, @"goto",
                          nil];
    
    [self sendRequest: [self psGetEndpoint:true]
      withQueryParams: nil
             withBody: [self dictionaryToJson:body]
          withHeaders: nil
          withRequest: request
       withCompletion: block];
}

- (void) checkForTimedResponse: (PSRequest *) request
                withCompletion: (void (^)(PSResponse *response))block
{
    if (! lastResponse || lastResponse.timedResponseInterval < 0) {
        if (block) {
            block(NULL);
        }
        return;
    }
    
    [self sendRequest: [self psGetEndpoint:true]
      withQueryParams: nil
             withBody: nil
          withHeaders: nil
          withRequest: request
       withCompletion: block];
}

- (void) sendAudio: (NSData *) bytes
        withFormat: (PSAudioFormat) format
       withRequest: (PSRequest *) request
    withCompletion: (void (^)(PSResponse *response))block
{
    // check that we have a supported audio data format
    if (format == PSFormatWAV16k) {
        bytes = [self getWavData:bytes];
    } else if (format != PSFormatRawPCM16k) {
        NSLog(@"Unsupported audio format sent to sendAudio:");
        bytes = nil;
    }

    // get out now if we don't have valid audio data
    if (! bytes) {
        block(nil);
        return;
    }

    // set up custom HTTP headers for the audio data
    NSMutableDictionary *headers = [NSMutableDictionary new];
    [headers setObject:@"audio/l16; rate=16000" forKey:@"Content-Type"];
    [headers setObject:@"application/json" forKey:@"Accept"];

    // send the audio to the Web API for ASR processing
    [self sendRequest: [self psGetEndpoint:true]
      withQueryParams: nil
             withBody: bytes
          withHeaders: headers
          withRequest: request
       withCompletion: block];
}

- (NSData *) getWavData:(NSData *)data
{
    if (! data || [data length] < 36) {
        return nil;
    }
    
    // check the RIFF header
    const char *bytes = [data bytes];
    if (bytes[0] != 'R' || bytes[1] != 'I' || bytes[2] != 'F' || bytes[3] != 'F') {
        NSLog(@"Data is now a WAV file");
        return nil;
    }

    // check that we have 16-bit mono data at 16000 samples/sec
    uint16_t channels = CFSwapInt16LittleToHost(*((uint16_t *)(bytes+22)));
    uint32_t sampleRate = CFSwapInt32LittleToHost(*((uint32_t *)(bytes+24)));
    uint16_t bitsPerSample = CFSwapInt16LittleToHost(*((uint16_t *)(bytes+34)));
    if (bitsPerSample != 16 || sampleRate != 16000 || channels != 1) {
        NSLog(@"WAV data is not mono 16-bit data at 16000 sample rate");
        return nil;
    }

    // find the data chunk in the WAV file by iterating through the
    // subchunks looking for a chunk called 'data' (don't assume 44
    // bytes). First chunk at 12 bytes (4 bytes name, 4 bytes size).
    int offset = 12;
    const char *chunkName = bytes + offset;
    int chunkSize = CFSwapInt32LittleToHost(*((uint32_t *)(bytes+offset+4)));
    int fileSize = CFSwapInt32LittleToHost(*((uint32_t *)(bytes+4)));
    while (chunkName[0] != 'd' || chunkName[1] != 'a' || chunkName[2] != 't' || chunkName[3] != 'a') {
        if (offset > fileSize) {
            NSLog(@"Cannot find data segment in WAV data");
            return nil;
        }
        offset += chunkSize + 8;
        chunkName = bytes + offset;
        chunkSize = CFSwapInt32LittleToHost(*((uint32_t *)(bytes+offset+4)));
    }
    
    // return the data segment as an NSData object
    int dataStart = offset + 8;
    return [NSData dataWithBytes:bytes + dataStart length:([data length] - dataStart)];
}

- (void) startAudio: (PSRequest *) request
{
    audioRequest = request;
    audioData = [NSMutableData new];
}

- (void) addAudio: (NSData *) bytes
{
    [audioData appendData:bytes];
}

- (void) endAudio: (void (^)(PSResponse *response))block
{
    [self sendAudio: audioData
         withFormat: PSFormatRawPCM16k
        withRequest: audioRequest
     withCompletion: block];
}

- (void) getEntities: (NSArray *) entities
         withRequest: (PSRequest *) request
      withCompletion: (void (^)(PSResponse *response))block
{
    NSMutableArray *names = [NSMutableArray new];
    for (PSEntity *entity in entities) {
        [names addObject:entity.name];
    }

    NSDictionary *body = [[NSDictionary alloc] initWithObjectsAndKeys:
                          names, @"get_entities",
                          nil];
    
    [self sendRequest: [self psGetEndpoint:true]
      withQueryParams: nil
             withBody: [self dictionaryToJson:body]
          withHeaders: nil
          withRequest: request
       withCompletion: block];

}

- (void) setEntities: (NSArray *) entities
         withRequest: (PSRequest *) request
      withCompletion: (void (^)(PSResponse *response))block
{
    NSMutableDictionary *values = [NSMutableDictionary new];
    
    for (PSEntity *entity in entities) {
        if (entity.type == PSEntityLabel) {
            PSLabel *label = (PSLabel *) entity;
            [values setObject:label.value forKey:entity.name];
        } else if (entity.type == PSEntityCounter) {
            PSCounter *counter = (PSCounter *) entity;
            NSNumber *value = [[NSNumber alloc] initWithDouble: counter.value];
            [values setObject:value forKey:entity.name];
        } else if (entity.type == PSEntityFlag) {
            PSFlag *flag = (PSFlag *) entity;
            NSNumber *value = [[NSNumber alloc] initWithBool:flag.value];
            [values setObject:value forKey:entity.name];
        }
    }
    
    NSDictionary *body = [[NSDictionary alloc] initWithObjectsAndKeys:
                          values, @"set_entities",
                          nil];
    
    [self sendRequest: [self psGetEndpoint:true]
      withQueryParams: nil
             withBody: [self dictionaryToJson:body]
          withHeaders: nil
          withRequest: request
       withCompletion: block];
}

- (NSString *) getConversationId
{
    if (lastResponse) {
        return lastResponse.conversationId;
    } else {
        return @"";
    }
}

- (NSString *) getParticipantId
{
    if (lastResponse) {
        return lastResponse.participantId;
    } else {
        return @"";
    }
}

- (BOOL) isEmptyString: (NSString *) str
{
    if (! str) {
        return true;
    }
    return [str isEqualToString:@""];
}

- (PSRequest *) getRequest: (PSRequest *) new_request
           withLastRequest: (PSRequest *) old_request
{
    PSRequest *r = [PSRequest new];
    
    if (old_request == nil) {
        old_request = [PSRequest new];
    }
    if (new_request == nil) {
        new_request = old_request;
    }
    
    r.apiKey = (! [self isEmptyString: new_request.apiKey]) ?
        new_request.apiKey : old_request.apiKey;
    r.participantId = (! [self isEmptyString: new_request.participantId]) ?
        new_request.participantId : old_request.participantId;
    r.restartIfModified = (new_request.restartIfModified == NO) ?
        new_request.restartIfModified : old_request.restartIfModified;
    r.buildType = (new_request.buildType != PSBuildTypeProduction) ?
        new_request.buildType : old_request.buildType;
    r.conversationId = (! [self isEmptyString: new_request.conversationId]) ?
        new_request.conversationId : old_request.conversationId;
    r.language = (! [self isEmptyString: new_request.language]) ?
        new_request.language : old_request.language;
    r.locale = (! [self isEmptyString: new_request.locale]) ?
        new_request.locale : old_request.locale;
    r.timeZoneOffset = (new_request.timeZoneOffset != 0) ?
        new_request.timeZoneOffset : old_request.timeZoneOffset;
    
    return r;
}

- (void) sendRequest: (NSString *) endpoint
     withQueryParams: (NSMutableDictionary *) params
            withBody: (NSData *) body
         withHeaders: (NSMutableDictionary *) headers
         withRequest: (PSRequest *) request
      withCompletion: (void (^)(PSResponse *response))block
{
    request = [self getRequest: request withLastRequest: lastRequest];
    lastRequest = request;
    
    if (! params) {
        params = [NSMutableDictionary new];
    }
    
    if (! [self isEmptyString: request.language]) {
        [params setObject:request.language forKey:@"language"];
    } else {
        [params setObject:@"en-US" forKey:@"language"];
    }
    
    if (! [self isEmptyString: request.locale]) {
        [params setObject:request.locale forKey:@"locale"];
    }

    if (! request.restartIfModified) {
        [params setObject:@"false" forKey:@"restart_if_modified"];
    }
    
    if (! headers) {
        headers = [NSMutableDictionary new];
        [headers setObject:@"application/json" forKey:@"Content-Type"];
        [headers setObject:@"application/json" forKey:@"Accept"];
    }
    [headers setObject:[NSString stringWithFormat:@"Bearer %@", request.apiKey] forKey:@"Authorization"];

    if (! body) {
        body = [self dictionaryToJson:[NSDictionary new]];
    }
    
    NSString *url = [NSString stringWithFormat:@"%@/%@", [PSVersionInfo getApiBaseUrl], endpoint];
    
    [self httpHelper: url
     withQueryParams: params
         withHeaders: headers
            withData: body
      withCompletion: block];
}

- (NSString *) psGetEndpoint: (BOOL) addId
{
    NSString *endpoint = @"conversation";
    if (addId && lastResponse != nil && lastResponse.conversationId) {
        endpoint = [NSString stringWithFormat:@"%@/%@", endpoint, lastResponse.conversationId];
    }
    return endpoint;
}

- (NSData *) dictionaryToJson: (NSDictionary *) dict
{
    // convert an NSDictionary into a JSON data string
    NSError *error;
    NSData *jsonData =
        [NSJSONSerialization dataWithJSONObject:dict
                                        options:NSJSONWritingPrettyPrinted
                                          error:&error];

    NSString *result;
    if (! jsonData) {
        result = @"{}";
    } else {
        result = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    return [result dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *) stringForKey: (NSDictionary *) dict
                        key: (NSString *) key
{
    // return a string value for a dictionary key, or a default if no such key
    NSString *value = [dict objectForKey:key];
    if (! value) {
        return @"";
    }
    return value;
}

- (double) doubleForKey: (NSDictionary *) dict
                    key: (NSString *) key
           defaultValue: (double) defVal
{
    // return a double value for a dictionary key, or a default if no such key
    NSNumber *value = [dict objectForKey:key];
    if (! value) {
        return defVal;
    }
    return [value doubleValue];
}

- (PSResponse *) httpResponseToPsResponse: (NSData *) data
                             httpResponse: (NSHTTPURLResponse *) response
                                    error: (NSError *)error
{
    PSResponse *r = [PSResponse new];
    
    // fill in the status of the response based on the HTTP code
    r.status.statusCode = (int)[response statusCode];
    r.status.success = (r.status.statusCode < 400);
    
    // return with an error if we got an HTTP error code
    if (! r.status.success) {
        r.status.errorMessage = [NSString stringWithFormat:@"Server returned HTTP error code %d", r.status.statusCode];
        return r;
    }

    // return with an error if the HTTP request generated a NSError
    if (error) {
        r.status.success = false;
        r.status.errorMessage = [error localizedDescription];
        return r;
    }
    
    // return with an error if there's no response body
    if (! data) {
        r.status.success = false;
        r.status.errorMessage = @"Empty body returned by HTTPS query";
        return r;
    }
    
    // parse the response as JSON
    NSError *JSONError = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONError];
    if (JSONError) {
        r.status.success = false;
        r.status.errorMessage = [JSONError localizedDescription];
        return r;
    }
    
    // parse out the top-level entries in the JSON response
    r.conversationId = [self stringForKey:json key:@"conversation"];
    r.participantId = [self stringForKey:json key:@"participant"];
    r.lastModified = [self stringForKey:json key:@"last_modified"];
    r.etag = [self stringForKey:json key:@"etag"];
    r.asrHypothesis = [self stringForKey:json key:@"asr_hypothesis"];
    r.timedResponseInterval = [self doubleForKey:json key: @"timed_response_interval" defaultValue:-1.0];
    
    // parse out the array of outputs from the JSON response
    NSMutableArray *outputs = [NSMutableArray new];
    NSArray *json_outputs = [json objectForKey:@"outputs"];
    for (NSDictionary *json_output in json_outputs) {
        NSString *type = [json_output objectForKey:@"type"];
        if (! type) {
            continue;
        }
        if ([type isEqualToString:@"dialog"]) {
            PSDialogOutput *output = [PSDialogOutput new];
            output.guid = [self stringForKey:json_output key:@"id"];
            output.text = [self stringForKey:json_output key:@"text"];
            output.uri = [self stringForKey:json_output key:@"uri"];
            output.character = [self stringForKey:json_output key:@"character"];
            output.userData = [self stringForKey:json_output key:@"user_data"];
            output.duration = [self doubleForKey:json_output key:@"duration" defaultValue:0.0];
            
            NSMutableArray *phonemes = [NSMutableArray new];
            NSArray *json_phonemes = [json_output objectForKey:@"phonemes"];
            if (json_phonemes) {
                for (NSDictionary *json_phoneme in json_phonemes) {
                    PSPhoneme *phoneme = [PSPhoneme new];
                    phoneme.name = [self stringForKey:json_phoneme key:@"name"];
                    phoneme.secondsSinceStart = [self doubleForKey:json_phoneme key:@"seconds_since_start" defaultValue:0.0];
                    [phonemes addObject:phoneme];
                }
            }
            output.phonemes = phonemes;
            
            [outputs addObject: output];

        } else if ([type isEqualToString:@"behavior"]) {
            PSBehaviorOutput *output = [PSBehaviorOutput new];
            output.behavior = [self stringForKey:json_output key:@"behavior"];
            NSDictionary *params = [json_output objectForKey:@"parameters"];
            if (params) {
                output.parameters = params;
            }
            
            [outputs addObject: output];
        }
    }
    r.outputs = outputs;
    
    // parse out all of the entity information (counters, flags, labels)
    NSMutableArray *entities = [NSMutableArray new];
    NSDictionary *json_entities = [json objectForKey:@"entities"];
    if (json_entities != nil) {
        for (NSString *key in json_entities) {
            // figure out the entity type based on the dictionary value type
            id value = [json_entities objectForKey:key];
            
            if ([value isKindOfClass:[NSNumber class]]) {
                // NSNumber can hold a number or a bool (among others)
                NSNumber *number_value = (NSNumber *)value;
                NSString *className = NSStringFromClass([number_value class]);
                
                if ([className rangeOfString:@"NSCFNumber"].location != NSNotFound) {
                    // parse out numbers as counters
                    PSCounter *counter = [PSCounter new];
                    counter.name = key;
                    counter.value = [number_value doubleValue];
                    [entities addObject:counter];
                } else if  ([className rangeOfString:@"NSCFBoolean"].location != NSNotFound) {
                    // parse out booleans as flags
                    PSFlag *flag = [PSFlag new];
                    flag.name = key;
                    NSNumber *number_value = (NSNumber *)value;
                    flag.value = [number_value boolValue];
                    [entities addObject:flag];
                }
                
            } else if ([value isKindOfClass:[NSString class]]) {
                // parse out strings as labels
                PSLabel *label = [PSLabel new];
                label.name = key;
                label.value = (NSString *)value;
                [entities addObject:label];
            }
        }
    }

    r.entities = entities;
    
    // remember the response for the next call to the API
    lastResponse = r;
    
    return r;
}

- (void) httpHelper: (NSString *) url
    withQueryParams: (NSDictionary *) params
        withHeaders: (NSDictionary *) headers
           withData: (NSData *) data
     withCompletion: (void (^)(PSResponse *response))block
{
    // add the query parameters to the URL
    if (params && [params count] > 0) {
        bool first = true;
        for (id key in params) {
            NSString *value = [params objectForKey:key];
            NSString *escaped = [value stringByAddingPercentEncodingWithAllowedCharacters: [NSCharacterSet URLQueryAllowedCharacterSet]];
            if (first) {
                url = [NSString stringWithFormat:@"%@?", url];
                first = false;
            } else {
                url = [NSString stringWithFormat:@"%@&", url];
            }
            url = [NSString stringWithFormat:@"%@%@=%@", url, (NSString *)key, escaped];
        }
    }
    NSURL *nsurl = [NSURL URLWithString:url];
    
    // create the HTTPS request
    NSMutableURLRequest *request =
       [NSMutableURLRequest requestWithURL:nsurl
                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                           timeoutInterval:60.0];
    
    // add in all of the headers
    for (NSString *key in headers) {
        NSString *value = [headers objectForKey:key];
        [request addValue:value forHTTPHeaderField:key];
    }
    
    // and add in the POST body
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        PSResponse *r = [self httpResponseToPsResponse:data httpResponse:httpResponse error: error];
        if (block) {
            block(r);
        }
    }];
    [dataTask resume];
}

@end
