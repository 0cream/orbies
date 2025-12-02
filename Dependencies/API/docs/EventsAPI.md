# EventsAPI

All URIs are relative to *http://localhost:3001*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getEvents**](EventsAPI.md#getevents) | **GET** /api/events | Get all important events


# **getEvents**
```swift
    open class func getEvents(completion: @escaping (_ data: GetEvents200Response?, _ error: Error?) -> Void)
```

Get all important events

Returns a list of curated important events related to the Solana ecosystem

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// Get all important events
EventsAPI.getEvents() { (response, error) in
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

[**GetEvents200Response**](GetEvents200Response.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

