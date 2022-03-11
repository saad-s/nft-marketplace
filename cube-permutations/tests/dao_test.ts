import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from "https://deno.land/x/clarinet@v0.14.0/index.ts";
import { assertEquals } from "https://deno.land/std@0.90.0/testing/asserts.ts";

Clarinet.test({
  name: "Ensure that dao owner is the deployer",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;
    let call = chain.callReadOnlyFn(
      "dao",
      "get-dao-owner",
      [],
      deployer.address
    );
    call.result.expectPrincipal(deployer.address);
  },
});

Clarinet.test({
  name: "Ensure that dao owner can set the new owner",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;
    let newOwner = accounts.get("wallet_1")!.address;
    let call = chain.callReadOnlyFn(
      "dao",
      "set-dao-owner",
      [types.principal(newOwner)],
      deployer.address
    );
    call.result.expectOk().expectBool(true);
  },
});

Clarinet.test({
  name: "Ensure that unauthorized user can't set the new owner",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;
    let newOwner = accounts.get("wallet_1")!.address;
    let call = chain.callReadOnlyFn(
      "dao",
      "set-dao-owner",
      [types.principal(newOwner)],
      newOwner
    );
    call.result.expectErr().expectUint(401);
  },
});

Clarinet.test({
  name: "Ensure that get-contract-identifier returns error when contract isn't listed",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let wallet1 = accounts.get("wallet_1")!.address;
    let call = chain.callReadOnlyFn(
      "dao",
      "get-contract-identifier",
      [types.ascii("cube-nft-project")],
      wallet1
    );
    call.result.expectErr().expectUint(402);
  },
});

Clarinet.test({
  name: "Ensure that get-contract-identifier returns correct contract address",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;
    let wallet1 = accounts.get("wallet_1")!.address;
    let call = chain.callReadOnlyFn(
      "dao",
      "get-contract-identifier",
      [types.ascii("cube-nft")],
      wallet1
    );
    call.result
      .expectOk()
      .expectPrincipal(`${deployer.address}.cube-permutations`);
  },
});

Clarinet.test({
  name: "Ensure that dao owner can add trusted contract",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let deployer = accounts.get("deployer")!;
    let call = chain.callReadOnlyFn(
      "dao",
      "set-contract-identifier",
      [
        types.ascii("marketplace"),
        types.principal(`${deployer.address}.market`),
      ],
     deployer.address
    );
    call.result.expectOk().expectBool(true);
  },
});


Clarinet.test({
    name: "Ensure that dao owner can update the contract address",
    async fn(chain: Chain, accounts: Map<string, Account>) {
      let deployer = accounts.get("deployer")!;
      let call = chain.callReadOnlyFn(
        "dao",
        "set-contract-identifier",
        [
          types.ascii("cube-nft"),
          types.principal(`${deployer.address}.cube-permutations-v1`),
        ],
       deployer.address
      );
      call.result.expectOk().expectBool(true);
    },
  });
  

  Clarinet.test({
    name: "Ensure that updating the contract address by unauthorized address returns error",
    async fn(chain: Chain, accounts: Map<string, Account>) {
      let deployer = accounts.get("deployer")!;
      let wallet1 = accounts.get("wallet_1")!.address;
      let call = chain.callReadOnlyFn(
        "dao",
        "set-contract-identifier",
        [
          types.ascii("cube-nft"),
          types.principal(`${deployer.address}.cube-permutations-v1`),
        ],
        wallet1
      );
      call.result.expectErr().expectUint(401);
    },
  });
  