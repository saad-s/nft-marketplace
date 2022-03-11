import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
} from "https://deno.land/x/clarinet@v0.14.0/index.ts";
import { assertEquals } from "https://deno.land/std@0.90.0/testing/asserts.ts";

const red = types.uint(73);
const green = types.uint(79);
const blue = types.uint(83);
const white = types.uint(89);
const yellow = types.uint(97);
const orange = types.uint(101);

const cube = [
    red, red, red, red, red, red, red, red, red,
    blue, blue, blue, blue, blue, blue, blue, blue, blue,
    white, white, white, white, white, white, white, white, white,
    green, green, green, green, green, green, green, green, green,
    yellow, yellow, yellow, yellow, yellow, yellow, yellow, yellow, yellow,
    orange, orange, orange, orange, orange, orange, orange, orange, orange,
];

Clarinet.test({
  name: "Ensure that an item can be put on sale with correct trait passed as argument",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let eCaller = accounts.get("deployer")!;
    let block = chain.mineBlock([
      Tx.contractCall(
        "cube-permutations",
        "mint",
        [types.list(cube), types.none()],
        eCaller.address
      ),
      Tx.contractCall(
        "market",
        "put-on-sale",
        [
          types.principal(`${eCaller.address}.cube-permutations`),
          types.uint(1),
          types.uint(59),
          types.uint(77),
          types.ascii("cube-nft"),
        ],
        eCaller.address
      ),
    ]);
    block.receipts[0].result.expectOk().expectTuple();
    block.receipts[1].result.expectOk().expectUint(0);
  },
});

Clarinet.test({
  name: "Ensure that put on sale throws error with incorrect key for trusted contracts passed as argument",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let eCaller = accounts.get("deployer")!;
    let block = chain.mineBlock([
      Tx.contractCall(
        "cube-permutations",
        "mint",
        [types.list(cube), types.none()],
        eCaller.address
      ),
      Tx.contractCall(
        "market",
        "put-on-sale",
        [
          types.principal(`${eCaller.address}.cube-permutations`),
          types.uint(1),
          types.uint(59),
          types.uint(77),
          types.ascii("nft"),
        ],
        eCaller.address
      ),
    ]);
    block.receipts[0].result.expectOk().expectTuple();
    block.receipts[1].result.expectErr().expectUint(402);
  },
});

Clarinet.test({
  name: "Ensure that put on sale throws error with incorrect trait is passed as argument",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let eCaller = accounts.get("deployer")!;
    let block = chain.mineBlock([
      Tx.contractCall(
        "cube-permutations",
        "mint",
        [types.list(cube), types.none()],
        eCaller.address
      ),
      Tx.contractCall(
        "market",
        "put-on-sale",
        [
          types.principal(`${eCaller.address}.cube-permutations-v1`),
          types.uint(1),
          types.uint(59),
          types.uint(77),
          types.ascii("cube-nft"),
        ],
        eCaller.address
      ),
    ]);
    block.receipts[0].result.expectOk().expectTuple();
    block.receipts[1].result.expectErr().expectUint(207);
  },
});

Clarinet.test({
  name: "Ensure that complete-auction throws error with incorrect key for trusted contracts passed as argument",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let eCaller = accounts.get("deployer")!;
    let block = chain.mineBlock([
      Tx.contractCall(
        "cube-permutations",
        "mint",
        [types.list(cube), types.none()],
        eCaller.address
      ),
      Tx.contractCall(
        "market",
        "put-on-sale",
        [
          types.principal(`${eCaller.address}.cube-permutations`),
          types.uint(1),
          types.uint(59),
          types.uint(77),
          types.ascii("cube-nft"),
        ],
        eCaller.address
      ),
      Tx.contractCall(
        "market",
        "complete-auction",
        [
          types.principal(`${eCaller.address}.cube-permutations`),
          types.uint(1),
          types.ascii("nft"),
        ],
        eCaller.address
      ),
    ]);
    block.receipts[0].result.expectOk().expectTuple();
    block.receipts[1].result.expectOk().expectUint(0);
    block.receipts[2].result.expectErr().expectUint(402);
  },
});
