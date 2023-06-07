import "NonFungibleToken"
import "KittyVerse"
import "KittyHats"

/// This transaction attaches a KittyHats NFT to a KittyVerse NFT and puts it back in the signer's KittyVerse
/// Collection
///
transaction(hatID: UInt64, catID: UInt64) {

    let catsCollectionRef: &KittyVerse.Collection
    let hatsCollectionRef: &KittyHats.Collection

    prepare(signer: AuthAccount) {
        // Get a reference to the signer's KittyVerse Collection
        self.catsCollectionRef = signer.borrow<&KittyVerse.Collection>(
                from: KittyVerse.CollectionStoragePath
            ) ?? panic("Signer does not have a KittyVerse Collection in storage")
        // Get a reference to the signer's KittyHats Collection
        self.hatsCollectionRef = signer.borrow<&KittyHats.Collection>(
                from: KittyHats.CollectionStoragePath
            ) ?? panic("Signer does not have a KittyHats Collection in storage")
    }

    execute {
        // Withdraw the KittyVerse NFT we want to put a hat on
        let catNFT: @KittyVerse.NFT <- self.catsCollectionRef.withdraw(withdrawID: catID) as! @KittyVerse.NFT

        // Put the hat on the cat
        let catWithHat: @NonFungibleToken.NFT <- self.hatsCollectionRef.attachHatToKitty(hatID: hatID, toKitty: <-catNFT)

        // Deposit the KittyVerse NFT back into the Collection
        self.catsCollectionRef.deposit(token: <-catWithHat)
    }
}
 