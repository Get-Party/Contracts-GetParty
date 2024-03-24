async function main() {
    const IterableMapping = await ethers.getContractFactory("IterableMapping");
    const iterableMapping = await IterableMapping.deploy() | await IterableMapping.deployed();

    console.log("IterableMapping deployed to:", iterableMapping.address);

    const GetPartyTokenV3 = await ethers.getContractFactory("GetPartyTokenV3", {
        libraries: {
            typedef: iterableMapping.address
        }
    });
    const getPartyTokenV3 = await GetPartyTokenV3.deploy(iterableMapping.address) | await GetPartyTokenV3.deployed();

    console.log("GetPartyTokenV3 deployed to:", getPartyTokenV3.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
