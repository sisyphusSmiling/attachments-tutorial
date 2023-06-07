import "NonFungibleToken"
import "KittyVerse"

/// This script returns a mapping of the of the KittyVerse NFT IDs and corresponding names found in the Collection of
/// the given Address
///
pub fun main(address: Address): {UInt64: String} {

    // Assign a return mapping
    let idsToNames: {UInt64: String} = {}
    
    // Get a reference to the CollectionPublic Capability from the specified Address
    let collectionPublicRef = getAccount(address).getCapability<&{KittyVerse.CollectionPublic}>(
        KittyVerse.CollectionPublicPath
    ).borrow()
    ?? panic("Couldn't find CollectionPublic Capability at given Address!")

    // Return the IDs of the NFTs in the KittyVerse Collection
    for id in collectionPublicRef.getIDs() {
        let name: String = collectionPublicRef.borrowKittyNFT(id: id)!.getName()
        idsToNames.insert(key: id, name)
    }

    // Return the final mapping
    return idsToNames
}