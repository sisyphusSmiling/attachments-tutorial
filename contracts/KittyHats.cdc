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

    /// A mapping of hats to greetings
    access(contract) let hatsToGreetings: {String: String}

    /* NFT Events */
    //
    access(all) event ContractInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)

    /* KittyHats Events */
    access(all) event HatMinted(id: UInt64, name: String)
    access(all) event HatAddedToKitty(hatName: String, kittyName: String, kittyID: UInt64)

    // KittyHat is a special resource type that represents a hat
    access(all) resource NFT {
        access(all) let id: UInt64
        access(self) let name: String

        init(name: String) {
            self.id = self.uuid
            self.name = name
        }

        access(self) fun getName(): String {
            return self.name
        }
        
        // An example of a function someone might put in their hat resource
        access(self) fun tipHat(): String {
            return KittyHats.hatsToGreetings[self.name] ?? "Hello!"
        }
    }

    /* HatAttachment */
    //
    /// The object that attaches our hats to KittyVerse NFTs. In this way, you can think of attachments to be like glue
    /// that binds resources together.
    ///
    access(all) attachment HatAttachment for KittyVerse.NFT {
        /// The Hat contained by this attachment
        access(self) let hat: @Hat
        
        init() {
            let randomHat: String = KittyHats.hatsToGreetings.keys[
                unsafeRandom() % UInt64(KittyHats.hatsToGreetings.length)
            ]
            self.hat <- create Hat(name: randomHat)
        }

        access(self) fun borrowHat(): &Hat {
            return &self.hat as &Hat
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
            return (&self.ownedNFTs as! &NonFungibleToken.NFT?)!
        }

        access(all) fun borrowKittyHatsNFT(id: UInt64): &KittyHats.NFT? {
            return &self.ownedNFTs[id] as! &KittyHats.NFT?
        }

        access(all) fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @KittyHats.NFT

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

        access(all) fun attachHatToKitty(hatID: UInt64, toKitty: @KittyVerse.NFT): @KittyVerse.NFT {
            pre {
                self.ownedNFTs.containsKey(hatID): "No KittyHat NFT with given ID in this Collection!"
            }
            if nft[HatAttachmnt] == nil {
                HatAddedToKitty(hatName: String, kittyName: String, kittyID: UInt64)
                return <- attach HatAttachment() to <- nft
            }
            return <- nft
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

    /// Mints an NFT
    ///
    access(all) fun MintNFT(): @NFT {
        // Create an NFT
        let nft <- create NFT()
        // Emit the relevant event with the new NFT's info & return
        emit HatMinted(id: nft.id, name: nft.getName())
        return <- nft
    }

    init() {
        self.hatsToGreetings = {
            "Cowboy Hat": "Howdy Y'all",
            "Top Hat": "Greetings, fellow aristocats!"
        }
    }
}
 