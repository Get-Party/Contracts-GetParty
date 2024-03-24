async function main() {



    const IterableMapping = await ethers.getContractFactory("IterableMapping");
    const iterableMapping = await IterableMapping.deploy();
    const GetPartyTokenV3 = await ethers.getContractFactory("GetPartyTokenV3", {
        libraries: {
            IterableMapping: iterableMapping,
        },
    });
    const getPartyTokenV3 = await GetPartyTokenV3.deploy();
    const contractAddress = await getPartyTokenV3.getAddress();
    console.log("GetPartyTokenV3 deployed to:", contractAddress);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
