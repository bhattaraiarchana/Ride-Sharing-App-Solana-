import * as anchor from "@project-serum/anchor";
import { Program } from "@project-serum/anchor";
import { RideSharing } from "../target/types/ride_sharing";
import * as assert from "assert";
import { PublicKey } from "@solana/web3.js";

// Program ID for the deployed Solana program
const programId = new PublicKey("F8PqJddLMwqQA7tKx6CCL8twfGeDQwV7XbCF1Ppxf5gH");

describe("ride_sharing_backend", () => {
  const provider = anchor.AnchorProvider.env(); // Set up the provider
  anchor.setProvider(provider);

  const program = anchor.workspace.RideSharing as Program<RideSharing>; // Load the program

  let rideAccountPDA: PublicKey; // Store the PDA of the ride account
  const uniqueId = Date.now() + Math.floor(Math.random() * 100000); // Generate a unique ID

  beforeEach(async () => {
    // Simulate dynamic distance and time for the test
    const distance = 5; // Example: 5 kilometers
    const time = 30; // Example: 30 minutes

    // Calculate the fare dynamically
    const baseFare = 50;
    const perKmFare = 15;
    const perMinFare = 2;
    const additionalCharges = 10;

    const calculatedFare = baseFare + distance * perKmFare + time * perMinFare + additionalCharges;

    // Derive the PDA for the ride account
    const [pda] = await PublicKey.findProgramAddress(
      [
        Buffer.from("ride"),
        provider.wallet.publicKey.toBuffer(),
        new anchor.BN(uniqueId).toArrayLike(Buffer, "le", 8), // Convert unique_id to u64
      ],
      programId
    );
    rideAccountPDA = pda;

    console.log("Derived PDA:", rideAccountPDA.toBase58()); // Log the PDA

    // Cleanup logic: Check if the PDA exists and close it
    try {
      await program.account.ride.fetch(rideAccountPDA); // Try to fetch the account
      console.log("Cleaning up existing account:", rideAccountPDA.toBase58());

      // Close the existing account
      await program.methods
        .closeRide()
        .accounts({
          ride: rideAccountPDA,
          rider: provider.wallet.publicKey,
        })
        .rpc();

      console.log("Closed existing account:", rideAccountPDA.toBase58());
    } catch (err) {
      console.log("No existing account to clean up:", rideAccountPDA.toBase58());
    }

    // Airdrop SOL to the payer (rider) account
    const airdropSignature = await provider.connection.requestAirdrop(
      provider.wallet.publicKey,
      2 * anchor.web3.LAMPORTS_PER_SOL
    );
    await provider.connection.confirmTransaction(airdropSignature);

    // Create and initialize the ride account
    await program.methods
      .createRide(new anchor.BN(uniqueId), new anchor.BN(calculatedFare), new anchor.BN(distance)) // Pass unique_id, fare, and distance
      .accounts({
        ride: rideAccountPDA,
        rider: provider.wallet.publicKey,
        systemProgram: anchor.web3.SystemProgram.programId,
      })
      .rpc();
  });

  it("Is initialized!", async () => {
    const distance = 5; // Example: 5 kilometers
    const time = 30; // Example: 30 minutes
    const baseFare = 50;
    const perKmFare = 15;
    const perMinFare = 2;
    const additionalCharges = 10;
  
    // Calculate the expected fare dynamically
    const expectedFare = baseFare + distance * perKmFare + time * perMinFare + additionalCharges;
  
    // Fetch the ride account data
    const rideAccountData = await program.account.ride.fetch(rideAccountPDA);
  
    // Assertions
    assert.equal(
      rideAccountData.fare.toString(),
      expectedFare.toString(),
      `Fare does not match. Expected: ${expectedFare}, Actual: ${rideAccountData.fare}`
    );
    assert.deepEqual(rideAccountData.status, { requested: {} }, "Status is not 'Requested'");
  });
  

  // Ride accept
  it("Driver accepts the ride", async () => {
    const driverAccount = anchor.web3.Keypair.generate(); // Generate a new driver account

    // Airdrop SOL to the driver
    const airdropSignature = await provider.connection.requestAirdrop(
      driverAccount.publicKey,
      2 * anchor.web3.LAMPORTS_PER_SOL
    );
    await provider.connection.confirmTransaction(airdropSignature);

    // Call the acceptRide method
    const tx = await program.methods
      .acceptRide()
      .accounts({
        ride: rideAccountPDA,
        driver: driverAccount.publicKey,
      })
      .signers([driverAccount]) // Driver signs the transaction
      .rpc();

    console.log("Transaction Signature (Accept Ride):", tx);

    // Fetch the updated ride account data
    const rideAccountData = await program.account.ride.fetch(rideAccountPDA);

    // Assertions
    assert.equal(
      rideAccountData.driver.toBase58(),
      driverAccount.publicKey.toBase58(),
      "Driver public key does not match"
    );
    assert.deepEqual(rideAccountData.status, { accepted: {} }, "Status is not 'Accepted'");
  });

  // Ride complete
  it("Ride is completed", async () => {
    const driverAccount = anchor.web3.Keypair.generate(); // Generate a driver account

    // Airdrop SOL to the driver
    const airdropSignature = await provider.connection.requestAirdrop(
      driverAccount.publicKey,
      2 * anchor.web3.LAMPORTS_PER_SOL
    );
    await provider.connection.confirmTransaction(airdropSignature);

    // Call the acceptRide method first
    const acceptTx = await program.methods
      .acceptRide()
      .accounts({
        ride: rideAccountPDA,
        driver: driverAccount.publicKey,
      })
      .signers([driverAccount])
      .rpc();

    console.log("Transaction Signature (Accept Ride):", acceptTx);

    // Now, call the completeRide method
    const completeTx = await program.methods
      .completeRide()
      .accounts({
        ride: rideAccountPDA,
        user: provider.wallet.publicKey, // Rider completes the ride
      })
      .rpc();

    console.log("Transaction Signature (Complete Ride):", completeTx);

    // Fetch the updated ride account data
    const rideAccountData = await program.account.ride.fetch(rideAccountPDA);

    // Assertions
    assert.deepEqual(rideAccountData.status, { completed: {} }, "Status is not 'Completed'");
  });

  // Ride cancel
  it("Ride is cancelled by the rider", async () => {
    // Call the cancelRide method
    const tx = await program.methods
      .cancelRide(true) // true indicates the rider cancels the ride
      .accounts({
        ride: rideAccountPDA,
        user: provider.wallet.publicKey,
      })
      .rpc();

    console.log("Transaction Signature (Cancel Ride):", tx);

    // Fetch the updated ride account data
    const rideAccountData = await program.account.ride.fetch(rideAccountPDA);

    // Assertions
    assert.deepEqual(rideAccountData.status, { cancelled: {} }, "Status is not 'Cancelled'");
  });
});
