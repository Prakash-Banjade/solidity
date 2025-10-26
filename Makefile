-include .env

deploy-mainnet:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(MAINNET_RPC_URL) --private-key $(DEPLOYER_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv