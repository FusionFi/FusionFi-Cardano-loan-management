import { mintOracle, oracleClose, oAutoUpdate, oManualUpdate, oracleDatum1, oracleDatum2, oracleDatum3, oracleDatum4 } from "./offchain/mod.ts"

// deno run --allow-net --allow-read --allow-env oracle.ts

// mintOracle 
const mintOracleTx = await mintOracle()
console.log(`Mint Oracle Tx: 
 `, mintOracleTx, `

SAVE THE ORACLE UNIT AT LINE 338
  Or the other transactions will not work!
`)

// closeOracle
const closeOracleTx = await oracleClose()
console.log(`Burned Oracle Tx: `, closeOracleTx, `
`)

// updateOracle
const updateOracleTX = await oAutoUpdate()
console.log("Update Oracle Tx: ", updateOracleTX,`
  new Oracle Datum: `, oracleDatum2, `
  `
)

// updateOracleManual
const updateOracleManualTx = await oManualUpdate()
console.log(`Update Oracle Manual Tx: 
  `, updateOracleManualTx, `

New Oracle Datum: 
  `, oracleDatum3
)
