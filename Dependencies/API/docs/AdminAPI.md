# AdminAPI

All URIs are relative to *http://localhost:3001*

Method | HTTP request | Description
------------- | ------------- | -------------
[**clearAllData**](AdminAPI.md#clearalldata) | **POST** /api/admin/clear-all | Clear all data
[**getRefreshMetadataStatus**](AdminAPI.md#getrefreshmetadatastatus) | **GET** /api/admin/refresh-metadata/status | Get metadata refresh status
[**refreshMetadata**](AdminAPI.md#refreshmetadata) | **POST** /api/admin/refresh-metadata | Refresh metadata for all tokens
[**replaceEvents**](AdminAPI.md#replaceevents) | **PUT** /api/admin/events | Replace all events


# **clearAllData**
```swift
    open class func clearAllData(clearAllDataRequest: ClearAllDataRequest, completion: @escaping (_ data: ClearAllDataResponse?, _ error: Error?) -> Void)
```

Clear all data

**DANGER:** Clears all data from the Redis database.  Requires explicit confirmation to proceed. Use with caution! 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let clearAllDataRequest = ClearAllDataRequest(confirm: "confirm_example") // ClearAllDataRequest | 

// Clear all data
AdminAPI.clearAllData(clearAllDataRequest: clearAllDataRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **clearAllDataRequest** | [**ClearAllDataRequest**](ClearAllDataRequest.md) |  | 

### Return type

[**ClearAllDataResponse**](ClearAllDataResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRefreshMetadataStatus**
```swift
    open class func getRefreshMetadataStatus(completion: @escaping (_ data: RefreshStatusResponse?, _ error: Error?) -> Void)
```

Get metadata refresh status

Returns the current status of the metadata refresh background task

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// Get metadata refresh status
AdminAPI.getRefreshMetadataStatus() { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**RefreshStatusResponse**](RefreshStatusResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refreshMetadata**
```swift
    open class func refreshMetadata(completion: @escaping (_ data: RefreshMetadataResponse?, _ error: Error?) -> Void)
```

Refresh metadata for all tokens

Triggers a background task to refresh metadata (symbol, name, decimals, logoURI)  for all existing tokens from Jupiter API. Useful for updating old tokens that  were added before automatic metadata fetching was implemented. 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// Refresh metadata for all tokens
AdminAPI.refreshMetadata() { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**RefreshMetadataResponse**](RefreshMetadataResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **replaceEvents**
```swift
    open class func replaceEvents(replaceEventsRequest: ReplaceEventsRequest, completion: @escaping (_ data: ReplaceEvents200Response?, _ error: Error?) -> Void)
```

Replace all events

Replaces all existing events with a new set of events. This completely overwrites the previous events.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let replaceEventsRequest = replaceEvents_request(events: [ImportantEvent(id: "id_example", title: "title_example", subtitle: "subtitle_example", content: "content_example", tokens: [EventToken(id: "id_example", name: "name_example", symbol: "symbol_example", imageUrl: "imageUrl_example")], publishedAt: Date())]) // ReplaceEventsRequest | 

// Replace all events
AdminAPI.replaceEvents(replaceEventsRequest: replaceEventsRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **replaceEventsRequest** | [**ReplaceEventsRequest**](ReplaceEventsRequest.md) |  | 

### Return type

[**ReplaceEvents200Response**](ReplaceEvents200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

