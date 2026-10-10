#!/usr/bin/env node
// Prints the current 6-digit TOTP code for a base32 key, the way an
// authenticator app would. For e2e runs against a local id: enrol a second
// factor at id's /security with the "enter this key manually" value, then
// answer each prompt with this.
//
//   node totp.mjs <base32-key> [unix-seconds]
//
// Exit 0 ok, 2 usage. Tests: totp.test.sh
import { createHmac } from "node:crypto";

const [key, at] = process.argv.slice(2);
if (!key) {
  console.error("usage: node totp.mjs <base32-key> [unix-seconds]");
  process.exit(2);
}
const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
let bits = "";
for (const c of key.toUpperCase().replace(/[=\s]/g, "")) {
  const v = ALPHABET.indexOf(c);
  if (v < 0) {
    console.error(`not base32: ${c}`);
    process.exit(2);
  }
  bits += v.toString(2).padStart(5, "0");
}
const secret = Buffer.from(bits.match(/.{8}/g).map((b) => parseInt(b, 2)));
const seconds = at === undefined ? Date.now() / 1000 : Number(at);
const counter = Buffer.alloc(8);
counter.writeBigUInt64BE(BigInt(Math.floor(seconds / 30)));
const h = createHmac("sha1", secret).update(counter).digest();
const offset = h[h.length - 1] & 15;
console.log(String((h.readUInt32BE(offset) & 0x7fffffff) % 1e6).padStart(6, "0"));
