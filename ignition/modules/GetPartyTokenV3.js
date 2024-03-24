const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("GetPartyTokenV3Module", (m) => {
    try {
        // Deploy the IterableMapping library first
        const IterableMapping = m.library("IterableMapping");
        console.log("IterableMapping deployed to:", IterableMapping);
        // Link the IterableMapping library to the GetPartyTokenV3 contract
        const GetPartyTokenV3 = m.contract("GetPartyTokenV3", [], {
            libraries: {
                IterableMapping
            }
        });
        console.log("GetPartyTokenV3 deployed to:", GetPartyTokenV3);

        return { GetPartyTokenV3 };
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
});
