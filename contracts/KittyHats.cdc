import "NonFungibleToken"
import "KittyVerse"

/// KittyHats.cdc
///
/// This contract extends the data and functionality of KittyVerse NFTs with native Cadence attachments as an examle
/// of permissionless composability.
///
/// Learn more about composable resources in this tutorial: https://developers.flow.com/cadence/tutorial/resources-compose
///
access(all) contract KittyHats : NonFungibleToken {
    
    /// Totat NFTs minted
    access(all) var totalSupply: UInt64
    /// A mapping of hats to greetings
    access(contract) let hatsToGreetings: {String: String}

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

    /* KittyHats Events */
    //
    access(all) event HatMinted(id: UInt64, name: String)
    access(all) event HatAddedToKitty(hatName: String, kittyName: String, kittyID: UInt64)
    access(all) event HatRemovedFromKitty(hatName: String, kittyName: String, kittyID: UInt64)

    /* KittyHats NFT */
    //
    /// This NFT represents a hat and is attached to a KittyVerse NFT with the HatAttachment defined below
    ///
    access(all) resource NFT : NonFungibleToken.INFT {
        /// Unique identifier
        access(all) let id: UInt64
        /// The name of this hat
        access(self) let name: String
        /// The name of the KittyVerse NFT this was last attached to
        access(contract) var lastKittyName: String?
        /// The ID of the KittyVerse NFT this was last attached to
        access(contract) var lastKittyID: UInt64?

        init(name: String) {
            self.id = self.uuid
            self.name = name
            self.lastKittyName = nil
            self.lastKittyID = nil
        }

        /// Simple getter for the hat name
        ///
        access(all) fun getHatName(): String {
            return self.name
        }
        
        /// Simple getter for the last KittyVerse name
        ///
        access(all) fun getLastKittyName(): String? {
            return self.lastKittyName
        }

        /// Simple getter for the last KittyVerse ID
        ///
        access(all) fun getLastKittyID(): UInt64? {
            return self.lastKittyID
        }
        
        /// An example of a function someone might put in their hat resource
        ///
        access(all) fun tipHat(): String {
            return KittyHats.hatsToGreetings[self.name] ?? "Hello!"
        }

        /// Allows containing attachment to update the last KittyVerse.NFT.name this NFT was attached to
        ///
        access(contract) fun updateLastKittyName(_ new: String) {
            self.lastKittyName = new
        }

        /// Allows containing attachment to update the last KittyVerse.NFT.id this NFT was attached to
        ///
        access(contract) fun updateLastKittyID(_ new: UInt64) {
            self.lastKittyID = new
        }
    }

    /* HatAttachment */
    //
    /// The object that attaches our hats to KittyVerse NFTs. In this way, you can think of attachments to be like glue
    /// that binds resources together.
    ///
    access(all) attachment HatAttachment for KittyVerse.NFT {
        /// The Hat contained by this attachment
        access(self) var hatNFT: @NFT?
        
        init() {
            self.hatNFT <- nil
        }

        /// Returns a reference to the contained KittyHats.NFT or nil if none contained
        ///
        access(all) fun borrowHat(): &NFT? {
            return &self.hatNFT as &NFT?
        }

        /// Adds a KittyHats.NFT to this attachment, panicking if one already assigned
        ///
        access(all) fun addHatNFT(_ new: @NFT) {
            pre {
                self.hatNFT == nil: "Cannot add NFT while assigned - must remove first!"
            }
            self.hatNFT <-! new
        }

        /// Removes the contained KittyHats.NFT if contained or nil otherwise
        ///
        access(contract) fun removeHatNFT(): @NFT? {
            // Cannot move nested resources, so we:
            // Assign a temporary optional resource as nil and swap
            var tmp: @NFT? <- nil
            // Swap nested and temporary resources
            tmp <-> self.hatNFT
            
            // Update the name & id of the base NFT as last seen in KittyHats.NFT before returning
            // **NOTE:** Attachments can access publicly accessible fields & methods from their base resources
            tmp?.updateLastKittyName(base.getName())
            tmp?.updateLastKittyID(base.id)
            
            return <- tmp
        }

        destroy() {
            destroy self.hatNFT
        }
    }

    /* Collection */
    //
    /// Interface that an account would commonly expose publicly for their Collection
    ///
    access(all) resource interface CollectionPublic {
        access(all) fun deposit(token: @NonFungibleToken.NFT)
        access(all) fun getIDs(): [UInt64]
        access(all) fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        access(all) fun borrowNFTSafe(id: UInt64): &NonFungibleToken.NFT?
        access(all) fun borrowKittyHatsNFT(id: UInt64): &KittyHats.NFT?
    }

    /// Allows for storage of any KittyHats NFTs
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

        /// Returns a reference to the KittyHats.NFT with given ID or nil if not found
        ///
        access(all) fun borrowKittyHatsNFT(id: UInt64): &KittyHats.NFT? {
            // **Optional Binding** - Assign if the value is not nil for given ID
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &KittyHats.NFT
            }
            // Otherwise return nil
            return nil
        }
        
        /// Adds the given NFT to the Collection
        ///
        access(all) fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @KittyHats.NFT

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

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        /// Attaches a KittyHats.NFT to a KittyVerse.NFT via the HatAttachment
        ///
        access(all) fun attachHatToKitty(hatID: UInt64, toKitty: @KittyVerse.NFT): @KittyVerse.NFT {
            pre {
                self.ownedNFTs.containsKey(hatID): "No KittyHat NFT with given ID in this Collection!"
            }
            // Make sure an attachment is added if need be
            let withAttachment: @KittyVerse.NFT <-self.addAttachment(toNFT: <-toKitty)

            // Withdraw the NFT we're going to put in the attachment
            let hat  <- self.withdraw(withdrawID: hatID) as! @NFT

            // Add the hat to the HatAttachment
            withAttachment[HatAttachment]!.addHatNFT(<-hat)
            
            // Get a reference to the KittyHats attachment.hatNFT & emit event
            let hatRef: &NFT = withAttachment[HatAttachment]!.borrowHat()!
            emit HatAddedToKitty(hatName: hatRef.getHatName(), kittyName: withAttachment.getName(), kittyID: withAttachment.id)
            
            // Return the NFT with the HatAttachment added
            // Note: the Hat resource is created in the HatAttachment init() body
            return <- withAttachment
        }

        /// Removes a KittyHats.NFT from a KittyVerse.NFT from a HatAttachment
        ///
        access(all) fun removeHatFromKitty(fromKitty: @KittyVerse.NFT): @KittyVerse.NFT {
            // Check if the KittyVerse NFT already has a HatAttachment
            if let attached: &HatAttachment = fromKitty[HatAttachment] {
                // If there's a KittyHats NFT in the attachment, remove it...
                if let removedHat: @NFT <- attached.removeHatNFT() {
                    emit HatRemovedFromKitty(
                        hatName: removedHat.getHatName(),
                        kittyName: removedHat.getLastKittyName()!,
                        kittyID: removedHat.getLastKittyID()!
                    )
                    // Then deposit it back to this Collection
                    self.deposit(token: <- removedHat)
                }
            }
            // Simply return the given KittyVerse NFT if there's no HatAttachment on it
            return <- fromKitty
        }

        /// Helper method that adds a HatAttachment if needed to the given KittyVerse NFT
        ///
        access(self) fun addAttachment(toNFT: @KittyVerse.NFT): @KittyVerse.NFT {
            // If attachment already exists, return
            if toNFT[HatAttachment] != nil {
                return <-toNFT
            }
            // Otherwise, add the attachment
            return <- attach HatAttachment() to <- toNFT
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

    /// Mints an NFT
    ///
    access(all) fun mintNFT(): @NFT {
        // Create an NFT
        let nft <- create NFT(name: self.getRandomHatName())
        // Emit the relevant event with the new NFT's info & return
        emit HatMinted(id: nft.id, name: nft.getHatName())
        return <- nft
    }

    /// Assigns a random hat name
    access(all) fun getRandomHatName(): String {
        // Assign a random hat
        return KittyHats.hatsToGreetings.keys[
            unsafeRandom() % UInt64(KittyHats.hatsToGreetings.length)
        ]
    }

    init() {
        // Assign initial supply of 0
        self.totalSupply = 0
        // Assign all of the possible hats + greetings - an Admin resource could have made this easily updatable
        self.hatsToGreetings = {
            "Cowboy Hat": "Howdy Y'all",
            "Top Hat": "Greetings, fellow aristocats!"
        }
        
        // Name canonical paths
        //
        self.CollectionStoragePath = /storage/KittHatsCollection
        self.CollectionPublicPath = /public/KittHatsCollection
        self.ProviderPrivatePath = /private/KittHatsProvider
    }
}
 