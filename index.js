require('dotenv').config();
const express = require('express');
const { Connection, PublicKey, Keypair, SystemProgram } = require('@solana/web3.js');
const { Program, AnchorProvider, Wallet } = require('@project-serum/anchor');
const bcrypt = require('bcrypt');
const mongoose = require('mongoose');
const crypto = require('crypto');
const fs = require('fs');
const { getDistance } = require('geolib');
const anchor = require('@project-serum/anchor');


// Constants for fare calculation
const baseFare = 50;
const perKmFare = 15;
const perMinFare = 2;
const additionalCharges = 10;

// Solana connection setup
const connection = new Connection(process.env.SOLANA_CLUSTER_URL, 'confirmed');
const walletKeyPair = Keypair.fromSecretKey(
  Uint8Array.from(JSON.parse(fs.readFileSync(process.env.ANCHOR_WALLET, 'utf8'))),
);
const wallet = new Wallet(walletKeyPair);
const provider = new AnchorProvider(connection, wallet, AnchorProvider.defaultOptions());

// Program setup
const idl = require('./ride_sharing_backend/target/idl/ride_sharing.json');
const programId = new PublicKey(process.env.PROGRAM_ID);
const program = new Program(idl, programId, provider);

// MongoDB models
const UserSchema = new mongoose.Schema({
  publicKey: String,
  encryptedPrivateKey: String,
  userType: { type: String, enum: ['Driver', 'Rider'] },
  name: String,
  contact: String,
  password: String,
});
const User = mongoose.model('User', UserSchema);

const RideSchema = new mongoose.Schema({
  rideId: String,
  rider: String,
  driver: String,
  fare: Number,
  status: String,
  pickup: { lat: Number, lng: Number },
  drop: { lat: Number, lng: Number },
  startTime: Date,
  endTime: Date,
  distance: Number,
  duration: Number,
});
const Ride = mongoose.model('Ride', RideSchema);

// MongoDB connection
mongoose.connect(process.env.MONGO_URI);
mongoose.connection.on('open', () => console.log('🚀 MongoDB connected successfully.'));
mongoose.connection.on('error', (err) => console.error('❌ MongoDB connection error:', err));

// Encryption Helpers
const ENCRYPTION_KEY = crypto.createHash('sha256').update(String(process.env.ENCRYPTION_KEY)).digest('base64').substr(0, 32);
const IV_LENGTH = 16;

function encrypt(text) {
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv('aes-256-cbc', Buffer.from(ENCRYPTION_KEY), iv);
  let encrypted = cipher.update(text);
  encrypted = Buffer.concat([encrypted, cipher.final()]);
  return iv.toString('hex') + ':' + encrypted.toString('hex');
}

function decrypt(text) {
  const textParts = text.split(':');
  const iv = Buffer.from(textParts.shift(), 'hex');
  const encryptedText = Buffer.from(textParts.join(':'), 'hex');
  const decipher = crypto.createDecipheriv('aes-256-cbc', Buffer.from(ENCRYPTION_KEY), iv);
  let decrypted = decipher.update(encryptedText);
  decrypted = Buffer.concat([decrypted, decipher.final()]);
  return decrypted.toString();
}

function validateKeypair(keypair) {
  if (!keypair || !Array.isArray(keypair) || keypair.length !== 64) {
    throw new Error('Invalid keypair format.');
  }
}

function getKeypairFromEncrypted(encryptedKey) {
  const decryptedKey = decrypt(encryptedKey);
  const keypairArray = JSON.parse(decryptedKey);
  validateKeypair(keypairArray);
  return Keypair.fromSecretKey(Uint8Array.from(keypairArray));
}

// Express setup
const app = express();
app.use(express.json());

// Driver Pool: Store available drivers with their locations
const driverPool = [];

// Function to calculate fare based on distance and duration
function calculateFare(pickup, drop, duration) {
  const distance = getDistance(pickup, drop) / 1000; // Convert to kilometers
  return baseFare + distance * perKmFare + duration * perMinFare + additionalCharges;
}

// Register a user (Driver or Rider)
app.post('/register', async (req, res) => {
  try {
    const { name, contact, userType, password } = req.body;

    const keypair = Keypair.generate();
    const publicKey = keypair.publicKey.toString();
    const privateKey = Array.from(keypair.secretKey);

    const encryptedPrivateKey = encrypt(JSON.stringify(privateKey));
    const hashedPassword = await bcrypt.hash(password, 10);

    const user = new User({
      name,
      contact,
      userType,
      password: hashedPassword,
      publicKey,
      encryptedPrivateKey,
    });

    await user.save();

    if (userType === 'Driver') {
      driverPool.push({ publicKey, location: null }); // Add the driver to the pool
    }

    res.status(201).json({
      message: 'User registered successfully',
      publicKey,
    });
  } catch (error) {
    console.error('Error registering user:', error);
    res.status(500).json({ message: 'Failed to register user', error: error.message });
  }
});

// Update driver location
app.post('/update-location', async (req, res) => {
  try {
    const { driverPublicKey, location } = req.body;

    const driver = driverPool.find((d) => d.publicKey === driverPublicKey);
    if (!driver) {
      return res.status(404).json({ message: 'Driver not found in the pool' });
    }

    driver.location = location;
    res.status(200).json({ message: 'Location updated successfully' });
  } catch (error) {
    console.error('Error updating location:', error);
    res.status(500).json({ message: 'Failed to update location', error: error.message });
  }
});

app.post('/create-ride', async (req, res) => {
  try {
    const { riderPublicKey, pickup, drop, startTime, endTime } = req.body;

    // Log debugging information
    console.log("Received request body:", req.body);

    if (!riderPublicKey || !pickup || !drop || !startTime || !endTime) {
      return res.status(400).json({ message: 'Invalid request body. Missing required fields.' });
    }

    // Validate the rider
    const rider = await User.findOne({ publicKey: riderPublicKey, userType: 'Rider' });
    if (!rider) {
      return res.status(404).json({ message: 'Rider not found' });
    }

    // Decrypt rider's private key
    const riderKeypair = getKeypairFromEncrypted(rider.encryptedPrivateKey);

    // Generate unique ID
    const uniqueId = Date.now();
    console.log("Unique ID:", uniqueId);

    // Derive PDA using matching seeds from the Rust program
    const [rideAccountPublicKey, bump] = await PublicKey.findProgramAddress(
      [
        Buffer.from('ride'),
        riderKeypair.publicKey.toBuffer(),
        Buffer.from(new anchor.BN(uniqueId).toArray('le', 8)),
      ],
      program.programId
    );
    console.log("Derived Ride Account Public Key:", rideAccountPublicKey.toString());

    // Calculate ride details
    const duration = (new Date(endTime) - new Date(startTime)) / (1000 * 60); // Duration in minutes
    const distance = getDistance(pickup, drop) / 1000; // Distance in kilometers
    const fare = calculateFare(pickup, drop, duration);

    console.log("Calculated Distance (km):", distance);
    console.log("Calculated Duration (minutes):", duration);
    console.log("Calculated Fare:", fare);

    // Interact with the Solana program
    await program.rpc.createRide(
      new anchor.BN(uniqueId), // Pass unique ID
      new anchor.BN(fare),
      new anchor.BN(distance),
      {
        accounts: {
          ride: rideAccountPublicKey,
          rider: riderKeypair.publicKey,
          systemProgram: SystemProgram.programId,
        },
        signers: [riderKeypair],
      }
    );
    console.log("Ride successfully created on Solana.");

    // Save to MongoDB
    const newRide = new Ride({
      rideId: rideAccountPublicKey.toString(),
      rider: riderKeypair.publicKey.toString(),
      driver: null,
      fare,
      status: 'Requested',
      pickup,
      drop,
      startTime,
      endTime,
      distance,
      duration,
    });
    await newRide.save();
    console.log("Ride saved to MongoDB:", newRide);

    // Send response
    res.status(201).json({ message: 'Ride created successfully', ride: newRide });
  } catch (error) {
    console.error('Error creating ride:', error);
    res.status(500).json({ message: 'Failed to create ride', error: error.message });
  }
});

// Get Ride Status
app.get('/ride-status', async (req, res) => {
  try {
    const { rideId } = req.query; // Use `req.query` for GET request parameters

    if (!rideId) {
      return res.status(400).json({ message: 'Missing rideId in request' });
    }

    // Find the ride in the database
    const ride = await Ride.findOne({ rideId });
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }

    // Return the ride details
    res.status(200).json({ message: 'Ride found', ride });
  } catch (error) {
    console.error('Error fetching ride status:', error);
    res.status(500).json({ message: 'Failed to fetch ride status', error: error.message });
  }
});


// Accept a ride
app.post('/accept-ride', async (req, res) => {
  try {
    const { rideId, driverPublicKey } = req.body;

    const ride = await Ride.findOne({ rideId });
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }

    ride.driver = driverPublicKey;
    ride.status = 'Accepted';
    await ride.save();

    res.status(200).json({ message: 'Ride accepted successfully', ride });
  } catch (error) {
    console.error('Error accepting ride:', error);
    res.status(500).json({ message: 'Failed to accept ride', error: error.message });
  }
});

// Complete a ride
app.post('/complete-ride', async (req, res) => {
  try {
    const { rideId } = req.body;

    const ride = await Ride.findOne({ rideId });
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }

    ride.status = 'Completed';
    await ride.save();

    res.status(200).json({ message: 'Ride completed successfully', ride });
  } catch (error) {
    console.error('Error completing ride:', error);
    res.status(500).json({ message: 'Failed to complete ride', error: error.message });
  }
});

// Cancel a ride
app.post('/cancel-ride', async (req, res) => {
  try {
    const { rideId } = req.body;

    const ride = await Ride.findOne({ rideId });
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }

    ride.status = 'Cancelled';
    await ride.save();

    res.status(200).json({ message: 'Ride cancelled successfully', ride });
  } catch (error) {
    console.error('Error cancelling ride:', error);
    res.status(500).json({ message: 'Failed to cancel ride', error: error.message });
  }
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
