# TokensAPI

All URIs are relative to *http://localhost:3001*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addToken**](TokensAPI.md#addtoken) | **POST** /api/tokens | Add token to index
[**addTokensBatch**](TokensAPI.md#addtokensbatch) | **POST** /api/tokens/batch | Add multiple tokens
[**getAllTokens**](TokensAPI.md#getalltokens) | **GET** /api/tokens | Get all indexed tokens
[**getToken**](TokensAPI.md#gettoken) | **GET** /api/tokens/{address} | Get specific token
[**searchTokens**](TokensAPI.md#searchtokens) | **GET** /api/tokens/search | Search tokens


# **addToken**
```swift
    open class func addToken(addTokenRequest: AddTokenRequest, completion: @escaping (_ data: AddTokenResponse?, _ error: Error?) -> Void)
```

Add token to index

Adds a new token to the indexing queue. Historical prices will be fetched automatically.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let addTokenRequest = AddTokenRequest(address: "address_example", symbol: "symbol_example", name: "name_example") // AddTokenRequest | 

// Add token to index
TokensAPI.addToken(addTokenRequest: addTokenRequest) { (response, error) in
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
 **addTokenRequest** | [**AddTokenRequest**](AddTokenRequest.md) |  | 

### Return type

[**AddTokenResponse**](AddTokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **addTokensBatch**
```swift
    open class func addTokensBatch(addTokensBatchRequest: AddTokensBatchRequest, completion: @escaping (_ data: AddTokensBatchResponse?, _ error: Error?) -> Void)
```

Add multiple tokens

Adds multiple tokens to the indexing queue in a single request. Perfect for bulk imports. Maximum 50 tokens per request.  **Fast Response:** Returns immediately after validation.  Tokens are processed in the background. Use queue status endpoint to track progress.  Tokens will be processed sequentially, one at a time. 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let addTokensBatchRequest = AddTokensBatchRequest(tokens: [AddTokensBatchRequest_tokens_inner(address: "address_example", symbol: "symbol_example", name: "name_example")]) // AddTokensBatchRequest | 

// Add multiple tokens
TokensAPI.addTokensBatch(addTokensBatchRequest: addTokensBatchRequest) { (response, error) in
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
 **addTokensBatchRequest** | [**AddTokensBatchRequest**](AddTokensBatchRequest.md) |  | 

### Return type

[**AddTokensBatchResponse**](AddTokensBatchResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getAllTokens**
```swift
    open class func getAllTokens(completion: @escaping (_ data: GetAllTokensResponse?, _ error: Error?) -> Void)
```

Get all indexed tokens

Returns a list of all tokens currently being tracked

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// Get all indexed tokens
TokensAPI.getAllTokens() { (response, error) in
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

[**GetAllTokensResponse**](GetAllTokensResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getToken**
```swift
    open class func getToken(address: String, completion: @escaping (_ data: GetTokenResponse?, _ error: Error?) -> Void)
```

Get specific token

Returns information about a specific indexed token

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let address = "address_example" // String | Solana token address

// Get specific token
TokensAPI.getToken(address: address) { (response, error) in
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
 **address** | **String** | Solana token address | 

### Return type

[**GetTokenResponse**](GetTokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **searchTokens**
```swift
    open class func searchTokens(q: String, completion: @escaping (_ data: SearchTokensResponse?, _ error: Error?) -> Void)
```

Search tokens

Search for tokens by name, symbol, or address. Returns matching tokens with their latest prices.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let q = "q_example" // String | Search query (minimum 2 characters)

// Search tokens
TokensAPI.searchTokens(q: q) { (response, error) in
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
 **q** | **String** | Search query (minimum 2 characters) | 

### Return type

[**SearchTokensResponse**](SearchTokensResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

