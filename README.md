![line coverage](https://gist.githubusercontent.com/popmedic/a555f644f50b16b6dd3a04a28af6f293/raw/swift-httprequesting-coverage.svg)

---

# swift-httprequest

Sometimes you need a little more control over your connection then `URLSession` allows.

This class use `NWConnection` to create a `HTTPRequest` that does not need ATS exceptions. 
Point the request at a `URL` and it will get the raw response from the URL.  

## ONLY SUPPORTS HTTP GET METHOD.

## Usage

### Install with Swift Package Manager

### Making a `GET` request

```swift
import Foundation
import HTTPRequesting
import Network

// create the url
guard let url = URL(string: "https://www.yahoo.com") else {
	print("bad url")
	exit(1)
}
// 30 seconds time to live on the request
let timeout = 30.0
// force the request over wifi
let required = NWInterface.InterfaceType.wifi
// allow self signed certs
let validation = .insecure
// better would be to use pinning.

// create the reqeust
let request = NWHTTPRequest(url: url,
                            timeout: timeout,
                            required: required)
// call the request
try request.call(
    certificate: validation
    handle: { (error, data) in
        // handle when data comes in
        // if there is an error, handle the error and return
        if let error = error { return print(error) }
        // if there is data, handle the data
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

## Security

You might want to use insecure that will allow any certificate to be used.

> This is really dangerious.  I suggest using the insecure options to get the hosts certificate
and then switch to using that certificates base64 encoded sha256 of the certificate for
pinned validation.

Pinning a certificate can be done by using the option `.certificate(String)`
Pass in a base64 encode SHA256 of the x509 certificate that is expected from the host.
This will validate that the host is using this certificate.
