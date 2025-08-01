require('dotenv').config();
const express = require('express');
const { Connection, PublicKey, Keypair, SystemProgram } = require('@solana/web3.js');
const { Program, AnchorProvider, Wallet } = require('@project-serum/anchor');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken'); // For JWT authentication
const mongoose = require('mongoose');
const crypto = require('crypto');
const axios = require('axios');
const fs = require('fs');
const { getDistance } = require('geolib');
const anchor = require('@project-serum/anchor');
const cors = require('cors'); // Import cors
const { exec } = require("child_process");
const app = express(); // Initialize app here
app.use(cors()); // Use cors middleware after app initialization
app.use(express.json()); // Parse incoming JSON requests

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

// JWT Secret Key
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key';

// Driver Pool: Store available drivers with their locations
const driverPool = [];

// Function to calculate fare based on distance and duration
function calculateFare(pickup, drop, duration) {
  const distance = getDistance(pickup, drop) / 1000; // Convert to kilometers
  return baseFare + distance * perKmFare + duration * perMinFare + additionalCharges;
}

// Function to trigger airdrop
const triggerAirdrop = async (publicKey) => {
  return new Promise((resolve, reject) => {
    exec(`solana airdrop 2 ${publicKey}`, (err, stdout, stderr) => {
      if (err) {
        reject(`Error: ${stderr}`);
      } else {
        resolve(stdout);
      }
    });
  });
};

// Fetch recent blockhash to use in transaction
const fetchBlockhash = async () => {
  try {
    const { blockhash } = await connection.getLatestBlockhash('confirmed');
    return blockhash;
  } catch (error) {
    console.error('Error fetching blockhash:', error);
    throw new Error('Failed to fetch recent blockhash');
  }
};

// **Register a User (Driver or Rider)**
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

    // Trigger airdrop for the user when they register
    await triggerAirdrop(publicKey);

    res.status(201).json({
      message: 'User registered successfully',
      publicKey,
    });
  } catch (error) {
    console.error('Error registering user:', error);
    res.status(500).json({ message: 'Failed to register user', error: error.message });
  }
});

// login endpoint
app.post('/login', async (req, res) => {
  try {
    const { username, number, password } = req.body;

    // Validate request
    if ((!username && !number) || !password) {
      return res.status(400).json({ message: 'Username/contact and password are required' });
    }

    // Determine if the identifier is username or contact
    const identifier = username || number;
    console.log('Identifier provided for login:', identifier);

    // Search for the user by 'name' or 'contact'
    const users = await User.find({
      $or: [{ name: identifier }, { contact: identifier }],
    });

    // Handle cases where multiple accounts are found
    if (users.length > 1) {
      return res.status(400).json({ message: 'Multiple accounts found. Please contact support.' });
    }

    const user = users[0]; // Take the first user from the array

    console.log('User found:', user);

    // If user is not found, return an error
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // Compare passwords
    const isMatch = await bcrypt.compare(password, user.password);
    console.log('Password Match:', isMatch);

    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: user._id, publicKey: user.publicKey, userType: user.userType },
      process.env.JWT_SECRET || 'your_jwt_secret',
      { expiresIn: '1h' }
    );

    // Respond with required fields
    res.status(200).json({
      message: 'Login successful',
      token, // Send the JWT token
      userType: user.userType, // Send user type
      publicKey: user.publicKey, // Send public key
    });
  } catch (error) {
    console.error('Error during login:', error);
    res.status(500).json({ message: 'Failed to login', error: error.message });
  }
});

// **Function to decrypt the encrypted private key and return keypair**
function getKeypairFromEncrypted(encryptedPrivateKey) {
  const decryptedPrivateKey = decrypt(encryptedPrivateKey); // Decrypt the encrypted key
  const privateKeyArray = JSON.parse(decryptedPrivateKey); // Parse the decrypted private key
  return Keypair.fromSecretKey(Uint8Array.from(privateKeyArray)); // Return the keypair
}

// **Create a Ride**
app.post('/create-ride', async (req, res) => {
  try {
    const { riderPublicKey, pickup, drop, startTime, endTime } = req.body;

    if (!riderPublicKey || !pickup || !drop || !startTime || !endTime) {
      return res.status(400).json({ message: 'Invalid request body. Missing required fields.' });
    }

    const rider = await User.findOne({ publicKey: riderPublicKey, userType: 'Rider' });
    if (!rider) {
      return res.status(404).json({ message: 'Rider not found' });
    }

    const riderKeypair = getKeypairFromEncrypted(rider.encryptedPrivateKey);
    const uniqueId = Date.now();
    const [rideAccountPublicKey, bump] = await PublicKey.findProgramAddress(
      [
        Buffer.from('ride'),
        riderKeypair.publicKey.toBuffer(),
        Buffer.from(new anchor.BN(uniqueId).toArray('le', 8)),
      ],
      program.programId
    );

    const duration = (new Date(endTime) - new Date(startTime)) / (1000 * 60); // Duration in minutes
    const distance = getDistance(pickup, drop) / 1000; // Distance in kilometers
    const fare = calculateFare(pickup, drop, duration);

    // Fetch the recent blockhash
    const recentBlockhash = await fetchBlockhash();

    // Create Ride Transaction
    await program.rpc.createRide(
      new anchor.BN(uniqueId),
      new anchor.BN(fare),
      new anchor.BN(distance),
      {
        accounts: {
          ride: rideAccountPublicKey,
          rider: riderKeypair.publicKey,
          systemProgram: SystemProgram.programId,
        },
        signers: [riderKeypair],
        recentBlockhash: recentBlockhash,
      }
    );

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

    // Trigger airdrop for the ride account to ensure it has enough SOL for the transaction
    await triggerAirdrop(rideAccountPublicKey.toString());

    res.status(201).json({ message: 'Ride created successfully', ride: newRide });
  } catch (error) {
    console.error('Error creating ride:', error);
    res.status(500).json({ message: 'Failed to create ride', error: error.message });
  }
});

// **Get Route**
app.post('/get-route', async (req, res) => {
  const { origin, destination } = req.body;

  try {
    // Construct the OSRM API URL
    const url = `https://router.project-osrm.org/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson`;

    // Fetch the route from OSRM
    const response = await axios.get(url);

    // Send the route back to the client
    res.status(200).json({ route: response.data });
  } catch (error) {
    console.error('Error fetching route:', error.message);
    res.status(500).json({ message: 'Error fetching route', error: error.message });
  }
});

// **Get Available Rides**
app.get('/get-available-rides', async (req, res) => {
  try {
    const rides = await Ride.find({ status: 'Requested' }); // Fetch rides with status 'Requested'
    res.status(200).json(rides);
  } catch (error) {
    console.error('Error fetching available rides:', error);
    res.status(500).json({ message: 'Failed to fetch available rides', error: error.message });
  }
});

// **Get Ride Status**
app.get('/ride-status', async (req, res) => {
  try {
    const { rideId } = req.query;

    if (!rideId) {
      return res.status(400).json({ message: 'Missing rideId in request' });
    }

    const ride = await Ride.findOne({ rideId });
    if (!ride) {
      return res.status(404).json({ message: 'Ride not found' });
    }

    res.status(200).json({ message: 'Ride found', ride });
  } catch (error) {
    console.error('Error fetching ride status:', error);
    res.status(500).json({ message: 'Failed to fetch ride status', error: error.message });
  }
});

// **Accept a Ride**
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

// **Complete a Ride**
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

// **Cancel a Ride**
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

// **Start the Server**
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
