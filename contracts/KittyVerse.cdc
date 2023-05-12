import "NonFungibleToken"

/// KittyVerse.cdc
///
/// The KittyVerse contract defines a basic NFT for the purpose of demonstrating how NFTs are defined in Cadence and how
/// to a resource can permissionlessly receive attachments
///
/// This is a simple example of how Cadence supports permissionless extensibility for smart contracts with attachments
///
/// Learn more about composable resources in this tutorial: https://developers.flow.com/cadence/tutorial/resources-compose
///
/// **NOTE:** This contract is intended for demoonstration & educational purposes and should not be used in production
///
access(all) contract KittyVerse : NonFungibleToken {

    access(all) var totalSupply: UInt64
    access(contract) let kittyNames: [String]

    /* Paths */
    //
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let ProviderPrivatePath: PrivatePath

    /* NFT Events */
    //
    access(all) event ContractInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)

    /* Kitty Events */
    //
    access(all) event KittyMinted(id: UInt64, name: String)

    /* KittyVerse NFT */
    //
    /// This simple NFT represents a Kitty
    ///
    access(all) resource NFT : NonFungibleToken.INFT {
        /// Unique ID of this NFT
        access(all) let id: UInt64
        /// Immutable of this Kitty NFT set on creation
        access(self) let name: String

        init(name: String) {
            self.id = self.uuid
            self.name = name
        }

        /// Returns the name of this KittyVerse NFT
        ///
        pub fun getName(): String {
            return self.name
        }
    }

    /* KittyVerse Collection */
    //
    /// Interface that an account would commonly expose publicly for their Collection
    ///
    access(all) resource interface CollectionPublic {
        access(all) fun deposit(token: @NonFungibleToken.NFT)
        access(all) fun getIDs(): [UInt64]
        access(all) fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        access(all) fun borrowKittyNFT(id: UInt64): &KittyVerse.NFT?
    }

    /// Allows for storage of any KittyVerse NFTs
    ///
    access(all) resource Collection : NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CollectionPublic {
        /// Dictionary to hold the NFTs in the Collection
        access(all) var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        init() {
            self.ownedNFTs <- {}
        }
        
        access(all) fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        access(all) fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            pre {
                self.ownedNFTs.containsKey(id): "NFT with given ID not found in this Collection!"
            }
            return (&self.ownedNFTs as! &NonFungibleToken.NFT?)!
        }

        access(all) fun borrowKittyNFT(id: UInt64): &KittyVerse.NFT? {
            return &self.ownedNFTs[id] as! &KittyVerse.NFT?
        }

        access(all) fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @KittyVerse.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        access(all) fun withdraw(id: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID)
                ?? panic("Invalid ID provided!")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    /// Creates a new KittyVerse Collection
    ///
    access(all) fun createEmptyCollection(): @Collection {
        return <- Collection()
    }

    /// Mints a new KittyVerse NFT
    ///
    access(all) fun mintNFT(): @NFT {
        // Increment total supply
        self.totalSupply = self.totalSupply + 1
        // Pick a random name from the contract name array
        let randomName = self.names[unsafeRandom() % UInt64(self.names.length)]
        // Create the NFT
        let nft <- create NFT(name: randomName)
        // Emit an event & return the created NFT
        emit KittyMinted(id: nft.id, name: randomName)
        return <- nft
    }

    init() {
        self.totalSupply = 0
        self.names = [
            "Catastrophe",
            "Feline Dion",
            "Fur-dinand",
            "Meowzart",
            "Pawssanova",
            "Purrlock Holmes",
            "Purrnest Hemingway",
            "Romeow",
            "Sir Pounce-a-Lot",
            "Sir Scratch-a-Lot"
        ]

        self.CollectionStoragePath = /storage/KittVerseCollection
        self.CollectionPublicPath = /public/KittVerseCollection
        self.ProviderPrivatePath = /private/KittVerseProvider
    }
}
 