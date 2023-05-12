import "NonFungibleToken"
import "KittyVerse"

/// KittyHats.cdc
///
/// This contract extends the data and functionality of KittyVerse NFTs with native Cadence attachments as an examle
/// of permissionless composability.
///
/// Learn more about composable resources in this tutorial: https://developers.flow.com/cadence/tutorial/resources-compose
///
pub contract KittyHats : NonFungibleToken {

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let ProviderPrivatePath: PrivatePath

    // KittyHat is a special resource type that represents a hat
    pub resource KittyHat : NonFungibleToken.INFT {
        pub let id: Int
        pub let name: String

        init(id: Int, name: String) {
            self.id = id
            self.name = name
        }

        // An example of a function someone might put in their hat resource
        access(self) fun tipHat(): String {
            if self.name == "Cowboy Hat" {
                return "Howdy Y'all"
            } else if self.name == "Top Hat" {
                return "Greetings, fellow aristocats!"
            }

            return "Hello"
        }
    }

    init() {
        self.CollectionStoragePath = /storage/KittVerseCollection
        self.CollectionPublicPath = /public/KittVerseCollection
        self.ProviderPrivatePath = /private/KittVerseProvider
    }
}
 