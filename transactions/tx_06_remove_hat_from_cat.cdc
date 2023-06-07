import "NonFungibleToken"
import "KittyVerse"
import "KittyHats"

/// This transaction removes an attached KittyHats NFT from a KittyVerse NFT and puts it back in the signer's
/// KittyHats Collection
///
transaction(catID: UInt64) {

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
        // Withdraw the KittyVerse NFT we want to remove the hat from
        let catNFT: @KittyVerse.NFT <- self.catsCollectionRef.withdraw(withdrawID: catID) as! @KittyVerse.NFT

        // Remove the hat from the cat
        let catWithHat: @NonFungibleToken.NFT <- self.hatsCollectionRef.removeHatFromKitty(fromKitty: <-catNFT)

        // Deposit the KittyVerse NFT back into the Collection
        self.catsCollectionRef.deposit(token: <-catWithHat)
    }
}
 