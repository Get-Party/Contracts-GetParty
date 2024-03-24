const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const DEFAULT_INITIAL_SUPPLY = 1_000_000n;  // Asumiendo una cantidad de suministro inicial por defecto
const DEFAULT_BUY_FEE_PERCENT = 3n;  // Asumiendo un porcentaje de comisión de compra por defecto

module.exports = buildModule("GetPartyTokenModule", (m) => {
  const initialSupply = m.getParameter("initialSupply", DEFAULT_INITIAL_SUPPLY);
  const buyFeePercent = m.getParameter("buyFeePercent", DEFAULT_BUY_FEE_PERCENT);

  const getPartyToken = m.contract("GetPartyToken", [initialSupply, buyFeePercent]);

  return { getPartyToken };
});
