const { ethers } = require("hardhat");
async function main() {
    const [deployer] = await ethers.getSigners();

    // Suponiendo que ya tienes un contrato de token desplegado
    const getPartyTokenAddress = "0x7379d7B6e52d020F6487Bcf68706a04Cff34A00e";
    const getPartyTokenContract = await ethers.getContractAt("GetPartyTokenV3", getPartyTokenAddress);

    // Dirección del Router V2 que has desplegado
    const routerAddress = "0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008";
    const routerContract = await ethers.getContractAt("IUniswapV2Router02", routerAddress);

    // Aprobar tokens para el Router
    const approved = await getPartyTokenContract.approve(routerAddress, ethers.parseEther("10000"));
    console.log("Approved: ", approved);
    // Agregar liquidez
    const liquidity = await routerContract.addLiquidityETH(
        getPartyTokenAddress, // dirección de tu token
        ethers.parseEther("1000000"), // cantidad de tokens que deseas agregar
        0, // cantidad mínima de tokens
        0, // cantidad mínima de ETH
        deployer.address, // dirección del proveedor de liquidez
        Math.floor(Date.now() / 1000) + 60 * 10, // timestamp de caducidad
        { value: ethers.parseEther("0.1") } // ETH enviado con la transacción
    );

    console.log("Liquidity: ", liquidity);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
