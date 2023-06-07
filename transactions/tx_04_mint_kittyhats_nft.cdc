import "KittyHats"
import "NonFungibleToken"

/// This transaction mints a new KittyVerse NFT and saves it in the signer's Collection
///
transaction {

    let collectionRef: &{KittyHats.CollectionPublic}

    prepare(signer: AuthAccount) {
        // Get a reference to the signer's KittyVerse Collection
        self.collectionRef = signer.getCapability<&{KittyHats.CollectionPublic}>(
                KittyHats.CollectionPublicPath
            ).borrow()
            ?? panic("Signer does not have a CollectionPublic Capability configured")
    }

    execute {
        // Deposit a newly minted NFT
        self.collectionRef.deposit(
            token: <-KittyHats.mintNFT()
        )
    }
}
 