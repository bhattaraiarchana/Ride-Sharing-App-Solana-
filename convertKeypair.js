const fs = require('fs');

function extractSecretKey(inputPath, outputPath) {
    try {
        const data = JSON.parse(fs.readFileSync(inputPath, 'utf8'));
        const secretKey = Object.values(data._keypair.secretKey);
        fs.writeFileSync(outputPath, JSON.stringify(secretKey, null, 2));
        console.log(`Converted and saved to ${outputPath}`);
    } catch (error) {
        console.error(`Failed to process ${inputPath}:`, error.message);
    }
}

// Convert rider and driver keypair files
extractSecretKey('./rider-keypair.json', './rider-keypair-converted.json');
extractSecretKey('./driver-keypair.json', './driver-keypair-converted.json');
