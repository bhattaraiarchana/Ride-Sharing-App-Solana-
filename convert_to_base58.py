import base58

# Your byte array
byte_array = [108, 53, 238, 21, 113, 182, 171, 173, 50, 22, 153, 160, 252, 68, 164, 175, 143, 152, 44, 37, 90, 70, 154, 158, 146, 221, 133, 121, 114, 197, 200, 215, 3, 96, 248, 147, 13, 172, 255, 232, 65, 40, 130, 50, 0, 237, 178, 231, 149, 163, 132, 76, 245, 80, 54, 234, 213, 92, 192, 177, 76, 239, 246, 83]

# Convert byte array to bytes object
byte_object = bytes(byte_array)

# Convert bytes object to Base58 string
public_key = base58.b58encode(byte_object).decode('utf-8')

print(public_key)


