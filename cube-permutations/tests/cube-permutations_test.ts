import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types,
  // @ts-ignore
} from "https://deno.land/x/clarinet@v0.14.0/index.ts";
// @ts-ignore
import { assertEquals } from "https://deno.land/std@0.90.0/testing/asserts.ts";

const red = types.uint(73);
const green = types.uint(79);
const blue = types.uint(83);
const white = types.uint(89);
const yellow = types.uint(97);
const orange = types.uint(101);

// prettier-ignore
const cube = [
  red, red, red, red, red, red, red, red, red,
  blue, blue, blue, blue, blue, blue, blue, blue, blue,
  white, white, white, white, white, white, white, white, white,
  green, green, green, green, green, green, green, green, green,
  yellow, yellow, yellow, yellow, yellow, yellow, yellow, yellow, yellow,
  orange, orange, orange, orange, orange, orange, orange, orange, orange,
];

Clarinet.test({
  name: "mint a cube token",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    let eCaller = accounts.get("deployer")!;
    let block = chain.mineBlock([
      Tx.contractCall(
        "cube-permutations",
        "mint",
        [types.list(cube), types.none()],
        eCaller.address
      ),
    ]);
    block.receipts[0].result.expectOk().expectTuple();
  },
});
