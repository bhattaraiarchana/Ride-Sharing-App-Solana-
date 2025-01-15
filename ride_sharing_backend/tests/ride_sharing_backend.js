"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const anchor = __importStar(require("@project-serum/anchor"));
const assert = __importStar(require("assert"));
describe("ride_sharing_backend", () => {
    const provider = anchor.AnchorProvider.env();
    anchor.setProvider(provider);
    const program = anchor.workspace.RideSharing;
    it("Is initialized!", () => __awaiter(void 0, void 0, void 0, function* () {
        // Airdrop SOL to the payer (rider) account
        const airdropSignature = yield provider.connection.requestAirdrop(provider.wallet.publicKey, 2 * anchor.web3.LAMPORTS_PER_SOL // 2 SOL
        );
        yield provider.connection.confirmTransaction(airdropSignature);
        // Generate a keypair for the ride account
        const rideAccount = anchor.web3.Keypair.generate();
        try {
            // Call the create_ride method
            const tx = yield program.methods
                .createRide(new anchor.BN(1000)) // Pass a fare value (e.g., 1000)
                .accounts({
                ride: rideAccount.publicKey,
                rider: provider.wallet.publicKey,
                systemProgram: anchor.web3.SystemProgram.programId,
            })
                .signers([rideAccount])
                .rpc();
            console.log("Transaction successful, signature:", tx);
            // Fetch the ride account data and verify it
            const rideAccountData = yield program.account.ride.fetch(rideAccount.publicKey);
            console.log("Ride account data:", rideAccountData);
            // Assertions
            assert.equal(rideAccountData.fare.toString(), "1000", "Fare does not match");
            assert.deepEqual(rideAccountData.status, { requested: {} }, "Status is not 'Requested'");
        }
        catch (err) {
            console.error("Transaction failed:", err);
        }
    }));
});
