import "KittyVerse"
import "NonFungibleToken"

/// This transaction sets up the signer with a KittyVerse Collection
///
transaction {
    prepare(signer: AuthAccount) {
        // Check if a Collection is already in Storage where expected
        if signer.type(at: KittyVerse.CollectionStoragePath) == nil {
            // Create and save
            signer.save(<-KittyVerse.createEmptyCollection(), to: KittyVerse.CollectionStoragePath)
        }

        // Prepare to link PublicPath
        signer.unlink(KittyVerse.CollectionPublicPath)
        // Link public Capabilities
        signer.link<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, KittyVerse.CollectionPublic}>(
            KittyVerse.CollectionPublicPath,
            target: KittyVerse.CollectionStoragePath
        )

        // Prepare to link PrivatePath
        signer.unlink(KittyVerse.ProviderPrivatePath)
        // Link private Capabilities
        signer.link<&{NonFungibleToken.Receiver}>(
            KittyVerse.ProviderPrivatePath,
            target: KittyVerse.CollectionStoragePath
        )
    }
}
 