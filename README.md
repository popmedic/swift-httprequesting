Code Coverage:<br/> 
![line coverage](https://gist.githubusercontent.com/popmedic/91a7a42d5a8b205ed4d4da6553969aa7/raw/swift-httprequesting-instantiations-coverage.svg) 
![line coverage](https://gist.githubusercontent.com/popmedic/66bf591f9bf0903867893afad30b8b2c/raw/swift-httprequesting-functions-coverage.svg)
![line coverage](https://gist.githubusercontent.com/popmedic/85d803a29268ce9ae5a6e59f3d8f7882/raw/swift-httprequesting-lines-coverage.svg)
![line coverage](https://gist.githubusercontent.com/popmedic/ac14c03f4beef83001796db0c3a4c112/raw/swift-httprequesting-regions-coverage.svg)

---
# swift-httprequest

Sometimes you need a little more control over your connection then `URLSession` allows.

This class use `NWConnection` to create a `HTTPRequest` that does not need ATS exceptions. 
Point the request at a `URL` and it will get the raw response from the URL.  

## Usage

### Install with Swift Package Manager

### Making a get request

```swift
guard let url = URL(string: "https://www.yahoo.com") else {
	print("bad url")
	exit(1)
}
let timeout = 30 //seconds
let requiredInterface: NWInterface.InterfaceType = .wifi

let request = NWHTTPRequest(url: url,
                            timeout: timeout,
                            required: requiredInterface)
try request.call(
    handle: { (error, data) in
        if let error = error { return print(error) }
        if let data = data {
            let result = String(data: data, encoding: .ascii) ??
                "data could not be string encoded"
            return print(result)
        }
        print("no error, no result")
    },
    complete: {
        // clean up if needed.
    }
)
```
