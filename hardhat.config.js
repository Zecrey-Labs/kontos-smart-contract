require('@nomicfoundation/hardhat-toolbox')
require('@openzeppelin/hardhat-upgrades')
require('hardhat-abi-exporter')
// require("@nomicfoundation/hardhat-verify")
// --vv
// require("hardhat-tracer");
// npm install hardhat-gas-reporter --save-dev
require('hardhat-gas-reporter')
// require("xdeployer");
const dotenv = require('dotenv')
dotenv.config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    kontos_test: {
      url: 'http://52.221.248.70:8545',
      accounts: ['d3c309c1a6f71dd91f4200824ea8594e897d5e7a58823d42d876cf41711e1ec1'],
      timeout: 100000
    },
    eth_local: {
      url: 'http://52.221.248.70:8888',
      accounts: ['bc46d0ff13316102fe14dc0f74641fe9e692b615ae20a25f0c52919da460ab61'],
      timeout: 10000000
    },
    arbitrum_local: {
      url: 'http://52.221.248.70:8890',
      accounts: ['bc46d0ff13316102fe14dc0f74641fe9e692b615ae20a25f0c52919da460ab61'],
      timeout: 10000000
    },
    bsc: {
      url: 'https://late-withered-model.bsc.quiknode.pro/f9c4a61390828a5752acae96e5e5d1a311c33a7d/',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000,
    },
    polygon: {
      // url: 'https://rpc.ankr.com/polygon/3a9e97411a02f95ed9faf0f12e7cab03ee47854876ea9844e8f2215e0fe4eca1',
      // url: 'https://virulent-frequent-meadow.matic.quiknode.pro/d6d42c2d3e905700da31732e31262427dd20631d/',
      url: 'https://polygon-mainnet.nodereal.io/v1/04bf211bd5db46f4ae97044fc9ab1a6f',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    eth: {
      url: 'https://wild-cold-model.quiknode.pro/10b60ea465b348f9f49064b3feb723862e0be4b7/',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 1000000
    },
    optimism: {
      url: 'https://soft-delicate-general.optimism.quiknode.pro/5810b943d5a77d0c7a58c6e973fbefb92e4f7087/',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    arbitrum: {
      // url: 'https://rpc.ankr.com/arbitrum/3a9e97411a02f95ed9faf0f12e7cab03ee47854876ea9844e8f2215e0fe4eca1',
      url: 'https://arb1.arbitrum.io/rpc',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 10000000
    },
    base: {
      url: 'https://lively-chaotic-star.base-mainnet.quiknode.pro/5be380c059b3b32c8144ea76ac3cda0f72cf6c72/',
      // url: 'https://base-pokt.nodies.app',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    avalanche: {
      url: 'https://shy-yolo-lambo.avalanche-mainnet.quiknode.pro/71ee369d3faa96b7384c39075812fa096a7feeb8/ext/bc/C/rpc/',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    zksync: {
      url: 'https://rpc.ankr.com/zksync_era/3a9e97411a02f95ed9faf0f12e7cab03ee47854876ea9844e8f2215e0fe4eca1',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    fantom: {
      url: 'https://fabled-wispy-wave.fantom.quiknode.pro/17a9de1f5a0798401fe6f25e4f139fa38916b7be/',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    opbnb: {
      url: 'https://opbnb-mainnet.nodereal.io/v1/04bf211bd5db46f4ae97044fc9ab1a6f',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    linea: {
      url: 'https://rpc.linea.build',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    mantle: {
      url: 'https://hidden-little-pool.mantle-mainnet.quiknode.pro/6f836b80e375c33f0f8398dc95c68538bb523ac2/',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER, process.env.AIRDROP_KEY_TEST] : [],
      timeout: 100000
    },
    xlayer: {
      url: 'https://rpc.xlayer.tech',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    zeta: {
      url: 'https://zetachain-mainnet.public.blastapi.io',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    sei: {
      url: 'https://spring-practical-fog.sei-pacific.quiknode.pro/02d6bbf0074d9881643ba4e51a2e386b557d490b',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    manta: {
      url: 'https://pacific-rpc.manta.network/http',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    scroll: {
      url: 'https://divine-cosmopolitan-layer.scroll-mainnet.quiknode.pro/d0850e16885e896874465109f31fc4fc3a81b820/',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    blast: {
      url: 'https://quick-light-smoke.blast-mainnet.quiknode.pro/7ee9bb0ba80c4cc50009a450bfde87867419c851/',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    kontos: {
      url: 'https://node-temp.kontos.io:8545',
      accounts: process.env.PRIVATE_KEY_OWNER !== undefined ? [process.env.PRIVATE_KEY_OWNER, process.env.PRIVATE_KEY_DEPLOYER] : [],
      timeout: 100000
    },
    kontos_local: {
      url: 'http://localhost:8545',
      accounts: ['5a7d74d402110ba40029090b5de60e0343cd452aa6daaa224a959b8cc431822c'],
      timeout: 100000
    },
    bsc_test: {
      chainId: 97,
      url: 'https://bsc-testnet.nodereal.io/v1/19bc122834874779901b1e0c9ecc552c',
      accounts: process.env.PRIVATE_KEY_BSC !== undefined ? [process.env.PRIVATE_KEY_BSC] : [],
      blockGasLimit: 20000000,
      timeout: 100000,
    },
    eth_test: {
      url: 'https://dimensional-practical-fire.ethereum-goerli.quiknode.pro/f441a3271e6aa5fe8492a0c127366f02d2568a4c',
      accounts: ['a190928d2eeb29616a6180c390ea4229a6c975afb45ef23dd3ab1b95ddd0e20a'],
      blockGasLimit: 10000000,
      timeout: 100000000
    },
    polygon_test: {
      url: 'https://polygon-mumbai.g.alchemy.com/v2/O2mVU_nX6p-nnrTFKqASBQi74hsxCsro',
      accounts: ['bc46d0ff13316102fe14dc0f74641fe9e692b615ae20a25f0c52919da460ab61'],
      timeout: 100000
    }
  }, solidity: {
    version: '0.8.18', settings: {
      optimizer: {
        enabled: true, runs: 500, details: {
          yul: true, yulDetails: {
            stackAllocation: true, optimizerSteps: 'dhfoDgvulfnTUtnIf'
          }
        }
      }
      // viaIR: true
    }
  }, // hardhat-abi-exporter
  // command: npx hardhat export-abi
  etherscan: {
    apiKey: {
      bsc: 'DQ93XY526AZXA9VS99E2AAVTV4RAI8A8JK'
    }
  },
  sourcify: {
    // Disabled by default
    // Doesn't need an API key
    enabled: false
  },
  abiExporter: {
    path: './abi', clear: true, flat: true, pretty: false,
    // only: [':ERC20'],
    spacing: 2
  }, gasReporter: {
    enabled: true
  } // npm install --save-dev xdeployer
  /**
   * xdeploy: {
   *   contract: "ERC20Mock",
   *   constructorArgsPath: "./deploy-args.ts",
   *   salt: "WAGMI",
   *   signer: process.env.PRIVATE_KEY,
   *   networks: ["hardhat", "goerli", "sepolia"],
   *   rpcUrls: ["hardhat", process.env.ETH_GOERLI_TESTNET_URL, process.env.ETH_SEPOLIA_TESTNET_URL],
   *   gasLimit: 1.2 * 10 ** 6,
   * },
   */
}
