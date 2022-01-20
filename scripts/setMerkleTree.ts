

import { BigNumber, Contract } from "ethers"
import { ethers } from "hardhat"
import { abi } from "../artifacts/contracts/Dao.sol/Dao.json"
const { MerkleTree } = require('merkletreejs')

const keccak256 = require('keccak256');


const contractAddr: string = "0x02228a401B43F138d45C1734D609586C6063BBD1"


const main = async (): Promise<any> => {
    //let accounts = await ethers.provider.listAccounts()
    let signer1 = await ethers.provider.getSigner(0)
    //console.log(signer1)
    const contract: Contract = new Contract(contractAddr, abi, ethers.provider)
    let contractAsSigner1 = contract.connect(signer1)
    const leaves = [
        ["0x938E2bd645b03a4aFF49D6f764663d8746c7fcF5", "1020000000000000000000"],
        ["0x60Ba51eE230B30Fc499D09C13112C36d36A1889a", "320000000000000000000"],
        ["0x91B24aCC646Ea48924ECf823E7Dd513373DE730f", "420000000000000000000"],
        ["0xA35eBAE339A3d03B6cAED1F5aEC8d43C372a88B4", "620000000000000000000"],
    ].map(x => keccak256(ethers.utils.solidityPack(["address", "uint256", "uint256"], [x[0], BigNumber.from(x[1]), 1642067999])));
    console.log(leaves);
    const tree = new MerkleTree(leaves, keccak256, { sort: true });
    const root = tree.getHexRoot();
    let res = await contractAsSigner1.setMerkleRoot(root);
    console.log(res.hash);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })


