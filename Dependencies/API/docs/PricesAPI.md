# PricesAPI

All URIs are relative to *http://localhost:3001*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getAllPrices**](PricesAPI.md#getallprices) | **GET** /api/tokens/{address}/prices | Get all price data
[**getHistoricalPrices**](PricesAPI.md#gethistoricalprices) | **GET** /api/tokens/{address}/prices/historical | Get historical prices
[**getRealtimePrice**](PricesAPI.md#getrealtimeprice) | **GET** /api/tokens/{address}/prices/realtime | Get latest price


# **getAllPrices**
```swift
    open class func getAllPrices(address: String, completion: @escaping (_ data: GetAllPricesResponse?, _ error: Error?) -> Void)
```

Get all price data

Returns all price data for a token in a single request.  Perfect for mobile apps - includes day (480 points, 3m), week (3360 points, 3m), month (1440 points, 30m), and year (~524+ points, 8H intervals) data. Note: Year data adjusts based on token creation date. 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let address = "address_example" // String | Solana token address

// Get all price data
PricesAPI.getAllPrices(address: address) { (response, error) in
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

[**GetAllPricesResponse**](GetAllPricesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getHistoricalPrices**
```swift
    open class func getHistoricalPrices(address: String, range: ModelRange_getHistoricalPrices? = nil, completion: @escaping (_ data: GetHistoricalPricesResponse?, _ error: Error?) -> Void)
```

Get historical prices

Returns historical price data for a token. Data is fetched from Birdeye API with aligned timestamps.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let address = "address_example" // String | Solana token address
let range = "range_example" // String | Time range for historical data (optional) (default to ._1d)

// Get historical prices
PricesAPI.getHistoricalPrices(address: address, range: range) { (response, error) in
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
 **range** | **String** | Time range for historical data | [optional] [default to ._1d]

### Return type

[**GetHistoricalPricesResponse**](GetHistoricalPricesResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getRealtimePrice**
```swift
    open class func getRealtimePrice(address: String, completion: @escaping (_ data: GetRealtimePriceResponse?, _ error: Error?) -> Void)
```

Get latest price

Returns the most recent price for a token from historical data. In production, prices are updated every 3 minutes.

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let address = "address_example" // String | Solana token address

// Get latest price
PricesAPI.getRealtimePrice(address: address) { (response, error) in
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

[**GetRealtimePriceResponse**](GetRealtimePriceResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

