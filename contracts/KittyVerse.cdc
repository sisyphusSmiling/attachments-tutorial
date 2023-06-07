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
    
    /// Total NFTs minted
    access(all) var totalSupply: UInt64
    /// Names of all KittyVerse cats
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
        access(all) fun getName(): String {
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
        access(all) fun borrowNFTSafe(id: UInt64): &NonFungibleToken.NFT?
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
        
        /// Returns all the NFT IDs in this Collection
        ///
        access(all) fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// Returns a reference to the NFT with given ID, panicking if not found
        ///
        access(all) fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            pre {
                self.ownedNFTs.containsKey(id): "NFT with given ID not found in this Collection!"
            }
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        /// Returns a reference to the NFT with given ID or nil if not found
        ///
        access(all) fun borrowNFTSafe(id: UInt64): &NonFungibleToken.NFT? {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT?
        }

        /// Returns a reference to the KittyVerse.NFT with given ID or nil if not found
        ///
        access(all) fun borrowKittyNFT(id: UInt64): &KittyVerse.NFT? {
            // **Optional Binding** - Assign if the value is not nil for given ID
            if let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT? {
                // Create an authorized reference to allow downcasting
                return ref as! &KittyVerse.NFT
            }
            // Otherwise return nil
            return nil
        }

        /// Adds the given NFT to the Collection
        ///
        access(all) fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @KittyVerse.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            // **Optional Chaining** - emit the address of the owner if not nil, otherwise emit nil
            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        /// Returns the contained NFT with given ID, panicking if not found
        ///
        access(all) fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID)
                ?? panic("Invalid ID provided!")

            // **Optional Chaining** - emit the address of the owner if not nil, otherwise emit nil
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
        return <- create Collection()
    }

    /// Mints a new KittyVerse NFT
    ///
    access(all) fun mintNFT(): @NFT {
        // Increment total supply
        self.totalSupply = self.totalSupply + 1
        // Pick a random name from the contract name array
        let randomName = self.kittyNames[
                unsafeRandom() % UInt64(self.kittyNames.length)
            ]
        // Create the NFT
        let nft <- create NFT(name: randomName)
        // Emit an event & return the created NFT
        emit KittyMinted(id: nft.id, name: randomName)
        return <- nft
    }

    init() {
        // Assign initial supply of 0
        self.totalSupply = 0
        // Assign all of the possible names - an Admin resource could have made this easily updatable
        self.kittyNames = [
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

        // Name canonical paths
        //
        self.CollectionStoragePath = /storage/KittVerseCollection
        self.CollectionPublicPath = /public/KittVerseCollection
        self.ProviderPrivatePath = /private/KittVerseProvider
    }
}
 