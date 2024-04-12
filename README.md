FLACMetadataKit
===============

`FLACMetadataKit` is a Swift library designed to parse metadata from FLAC audio files either locally or streamed from the internet. It is able to extract information such as stream info, Vorbis comments, picture data, and other relevant metadata in a progressive and efficient manner.

Features
--------

*   **Local Parsing:** Parse FLAC metadata directly from local files.
*   **Streaming Parsing:** Fetch and parse metadata progressively from remote FLAC files.
*   **Support for Multiple Metadata Types:** Handles various types of metadata including StreamInfo, Vorbis Comments, Cue Sheets, Pictures, and more.
*   **Error Handling:** Handles parsing issues like incomplete data or non-FLAC content.

Installation
------------

### Swift Package Manager

You can add `FLACMetadataKit` to your project via Swift Package Manager.

Usage
-----

### Parsing Local FLAC Files

```swift
import FLACMetadataKit

let flacData = Data(contentsOf: URL(fileURLWithPath: "path/to/your/file.flac"))
let parser = FLACParser(data: flacData)

do {
    let metadata = try parser.parse()
    print("Parsed metadata successfully: \(metadata)")
} catch {
    print("Error parsing FLAC metadata: \(error)")
}
```

### Streaming FLAC Metadata from the Internet

```swift
import FLACMetadataKit
import Alamofire

let url = URL(string: "http://example.com/file.flac")!
let session = Alamofire.Session.default
let fetcher = FLACRemoteMetadataFetcher(url: url, session: session, headers: nil)

Task {
    if let metadata = await fetcher.fetch() {
        print("Successfully fetched and parsed metadata: \(metadata)")
    } else {
        print("Failed to fetch metadata.")
    }
}
```

Contributing
------------

Contributions to `FLACMetadataKit` are welcome! Here's how you can contribute:

*   **Issues:** Submit issues for bugs, enhancements, or features via GitHub Issues.
*   **Pull Requests:** We welcome pull requests. Please fork the repository and submit a PR for review.

License
-------

`FLACMetadataKit` is released under the LGPL V3 License. See the `LICENSE` file for more information.
