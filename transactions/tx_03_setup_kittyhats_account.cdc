import "NonFungibleToken"
import "KittyHats"

/// This transaction sets up the signer with a KittyHats Collection
///
transaction {
    prepare(signer: AuthAccount) {
        // Check if a Collection is already in Storage where expected
        if signer.type(at: KittyHats.CollectionStoragePath) == nil {
            // Create and save
            signer.save(<-KittyHats.createEmptyCollection(), to: KittyHats.CollectionStoragePath)
            
            // Prepare to link PublicPath
            signer.unlink(KittyHats.CollectionPublicPath)
            // Link public Capabilities
            signer.link<&{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, KittyHats.CollectionPublic}>(
                KittyHats.CollectionPublicPath,
                target: KittyHats.CollectionStoragePath
            )

            // Prepare to link PrivatePath
            signer.unlink(KittyHats.ProviderPrivatePath)
            // Link private Capabilities
            signer.link<&{NonFungibleToken.Receiver}>(
                KittyHats.ProviderPrivatePath,
                target: KittyHats.CollectionStoragePath
            )
        }
    }
}
 