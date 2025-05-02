import fs from "fs";
import { getYaku } from "@yusuke4869/mahjong";

const raw = fs.readFileSync("tmp/yaku_input.json", "utf-8");
const input = JSON.parse(raw);
const yaku = getYaku(input);
console.log(JSON.stringify(yaku));
