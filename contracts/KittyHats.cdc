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
        access(all) fun getLastKittyID(): UInt64? {
            return self.lastKittyID
        }
        
        /// An example of a function someone might put in their hat resource
        ///
        access(all) fun tipHat(): String {
            return KittyHats.hatsToGreetings[self.name] ?? "Hello!"
        }

        access(contract) fun updateLastKittyName(_ new: String) {
            self.lastKittyName = new
        }

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

        access(all) fun borrowHat(): &NFT? {
            return &self.hatNFT as &NFT?
        }

        access(all) fun addHatNFT(_ new: @NFT) {
            pre {
                self.hatNFT == nil: "Cannot add NFT while assigned - must remove first!"
            }
            self.hatNFT <-! new
        }

        access(contract) fun removeHatNFT(): @NFT? {
            var tmp: @NFT? <- nil
            tmp <-> self.hatNFT
            
            // Update the name & id of the base NFT as last seen
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
        
        access(all) fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        access(all) fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            pre {
                self.ownedNFTs.containsKey(id): "NFT with given ID not found in this Collection!"
            }
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        access(all) fun borrowKittyHatsNFT(id: UInt64): &KittyHats.NFT? {
            if self.ownedNFTs[id] != nil {
                // Create an authorized reference to allow downcasting
                let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &KittyHats.NFT
            }

            return nil
        }

        access(all) fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @KittyHats.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

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
            if toNFT[HatAttachment] == nil {
                return <- attach HatAttachment() to <- toNFT
            }
            return <-toNFT
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
        self.totalSupply = 0
        self.hatsToGreetings = {
            "Cowboy Hat": "Howdy Y'all",
            "Top Hat": "Greetings, fellow aristocats!"
        }

        self.CollectionStoragePath = /storage/KittHatsCollection
        self.CollectionPublicPath = /public/KittHatsCollection
        self.ProviderPrivatePath = /private/KittHatsProvider
    }
}
 