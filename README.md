# ReddimgurGallery
ReddimgurGallery is iOS an app made in Swift that shows images hosted in [Imgur](http://imgur.com/) related to a certain subreddit. You introduce a subreddit name in the search bar and the images will be asynchronously loaded.  

I made this app to get some practice working with `OperationQueue`, some `CoreData` features like `NSBatchDeleteRequest`, `DispatchQueue` and Swift coding in general. That is the reason why the app doesn't use simply `URLSession` and some cache like `NSCache` or `NSURLCache`.  

![Preview](img/reddimgur.gif)

## Requirements

The app makes use of the [Imgur API](https://apidocs.imgur.com/), so, in order to run the app you will need to get a Client ID to use the API.  

First, [create an account](https://imgur.com/register) in Imgur if you don't have one yet. Then, go [here](https://api.imgur.com/oauth2/addclient) to register an application, once there, introduce an application name, select "Anonymous" as authorization type, introduce a callback URL (won't be used) and an email. After submiting the information you will have your client ID.  
Open the XCode project open `ImgurToken.swift`, replace the `clientID` value with your token and remove the takes that provokes an error. You should see something like this:
```Swift
import Foundation

struct ImgurCredentials {
    static let clientID = "ad14ad14ad14ad14"
}
```
**Note:** "ad14ad14ad14ad14" is just an example, it represents your clientID.  

After updating the file you are ready to run the app.

## Contributions

By now, I'm not thinking in growing this project, but contributions via pull request are welcome.
