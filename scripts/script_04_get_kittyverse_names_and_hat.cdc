import "NonFungibleToken"
import "KittyVerse"
import "KittyHats"

/// This script returns a mapping of the of the KittyVerse NFT name and corresponding attached hat names found in the
/// Collection of the given Address
///
pub fun main(address: Address): {String: String?} {

    // Assign a return mapping
    let catsAndHats: {String: String?} = {}
    
    // Get a reference to the CollectionPublic Capability from the specified Address
    let collectionPublicRef = getAccount(address).getCapability<&{KittyVerse.CollectionPublic}>(
        KittyVerse.CollectionPublicPath
    ).borrow()
    ?? panic("Couldn't find CollectionPublic Capability at given Address!")

    // Return the IDs of the NFTs in the KittyVerse Collection
    for id in collectionPublicRef.getIDs() {
        // Get a reference to the KittyVerse NFT
        let kittyNFTRef: &KittyVerse.NFT = collectionPublicRef.borrowKittyNFT(id: id)!
        // Assign our initial return mapping values
        let name: String = kittyNFTRef.getName()
        var hat: String? = nil
        // Reference the KittyHats attachment if there is one
        if let attachment = kittyNFTRef[KittyHats.HatAttachment] {
            // Get the name of the hat in the attachment if one exists
            hat = attachment.borrowHat()?.getHatName()
        }
        // Add the values to the mapping
        catsAndHats.insert(key: name, hat)
    }

    // Return the final mapping
    return catsAndHats
}