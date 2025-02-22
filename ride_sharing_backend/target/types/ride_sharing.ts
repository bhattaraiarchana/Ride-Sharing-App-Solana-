export type RideSharing = {
  "version": "0.1.0",
  "name": "ride_sharing",
  "instructions": [
    {
      "name": "createRide",
      "accounts": [
        {
          "name": "ride",
          "isMut": true,
          "isSigner": false
        },
        {
          "name": "rider",
          "isMut": true,
          "isSigner": true
        },
        {
          "name": "systemProgram",
          "isMut": false,
          "isSigner": false
        }
      ],
      "args": [
        {
          "name": "uniqueId",
          "type": "u64"
        },
        {
          "name": "fare",
          "type": "u64"
        },
        {
          "name": "distance",
          "type": "u64"
        }
      ]
    },
    {
      "name": "acceptRide",
      "accounts": [
        {
          "name": "ride",
          "isMut": true,
          "isSigner": false
        },
        {
          "name": "driver",
          "isMut": false,
          "isSigner": true
        }
      ],
      "args": []
    },
    {
      "name": "completeRide",
      "accounts": [
        {
          "name": "ride",
          "isMut": true,
          "isSigner": false
        },
        {
          "name": "user",
          "isMut": false,
          "isSigner": true
        }
      ],
      "args": []
    },
    {
      "name": "cancelRide",
      "accounts": [
        {
          "name": "ride",
          "isMut": true,
          "isSigner": false
        },
        {
          "name": "user",
          "isMut": false,
          "isSigner": true
        }
      ],
      "args": [
        {
          "name": "byRider",
          "type": "bool"
        }
      ]
    },
    {
      "name": "closeRide",
      "accounts": [
        {
          "name": "ride",
          "isMut": true,
          "isSigner": false
        },
        {
          "name": "rider",
          "isMut": true,
          "isSigner": true
        }
      ],
      "args": []
    }
  ],
  "accounts": [
    {
      "name": "ride",
      "type": {
        "kind": "struct",
        "fields": [
          {
            "name": "rider",
            "type": "publicKey"
          },
          {
            "name": "driver",
            "type": "publicKey"
          },
          {
            "name": "uniqueId",
            "type": "u64"
          },
          {
            "name": "fare",
            "type": "u64"
          },
          {
            "name": "distance",
            "type": "u64"
          },
          {
            "name": "status",
            "type": {
              "defined": "RideStatus"
            }
          },
          {
            "name": "bump",
            "type": "u8"
          }
        ]
      }
    }
  ],
  "types": [
    {
      "name": "RideStatus",
      "type": {
        "kind": "enum",
        "variants": [
          {
            "name": "Requested"
          },
          {
            "name": "Accepted"
          },
          {
            "name": "Completed"
          },
          {
            "name": "Cancelled"
          }
        ]
      }
    }
  ],
  "errors": [
    {
      "code": 6000,
      "name": "RideAlreadyCompleted",
      "msg": "The ride is already completed and cannot be modified."
    },
    {
      "code": 6001,
      "name": "InvalidRideState",
      "msg": "The ride is not in the expected state for this operation."
    }
  ]
};

export const IDL: RideSharing = {
  "version": "0.1.0",
  "name": "ride_sharing",
  "instructions": [
    {
      "name": "createRide",
      "accounts": [
        {
          "name": "ride",
          "isMut": true,
          "isSigner": false
        },
        {
          "name": "rider",
          "isMut": true,
          "isSigner": true
        },
        {
          "name": "systemProgram",
          "isMut": false,
          "isSigner": false
        }
      ],
      "args": [
        {
          "name": "uniqueId",
          "type": "u64"
        },
        {
          "name": "fare",
          "type": "u64"
        },
        {
          "name": "distance",
          "type": "u64"
        }
      ]
    },
    {
      "name": "acceptRide",
      "accounts": [
        {
          "name": "ride",
          "isMut": true,
          "isSigner": false
        },
        {
          "name": "driver",
          "isMut": false,
          "isSigner": true
        }
      ],
      "args": []
    },
    {
      "name": "completeRide",
      "accounts": [
        {
          "name": "ride",
          "isMut": true,
          "isSigner": false
        },
        {
          "name": "user",
          "isMut": false,
          "isSigner": true
        }
      ],
      "args": []
    },
    {
      "name": "cancelRide",
      "accounts": [
        {
          "name": "ride",
          "isMut": true,
          "isSigner": false
        },
        {
          "name": "user",
          "isMut": false,
          "isSigner": true
        }
      ],
      "args": [
        {
          "name": "byRider",
          "type": "bool"
        }
      ]
    },
    {
      "name": "closeRide",
      "accounts": [
        {
          "name": "ride",
          "isMut": true,
          "isSigner": false
        },
        {
          "name": "rider",
          "isMut": true,
          "isSigner": true
        }
      ],
      "args": []
    }
  ],
  "accounts": [
    {
      "name": "ride",
      "type": {
        "kind": "struct",
        "fields": [
          {
            "name": "rider",
            "type": "publicKey"
          },
          {
            "name": "driver",
            "type": "publicKey"
          },
          {
            "name": "uniqueId",
            "type": "u64"
          },
          {
            "name": "fare",
            "type": "u64"
          },
          {
            "name": "distance",
            "type": "u64"
          },
          {
            "name": "status",
            "type": {
              "defined": "RideStatus"
            }
          },
          {
            "name": "bump",
            "type": "u8"
          }
        ]
      }
    }
  ],
  "types": [
    {
      "name": "RideStatus",
      "type": {
        "kind": "enum",
        "variants": [
          {
            "name": "Requested"
          },
          {
            "name": "Accepted"
          },
          {
            "name": "Completed"
          },
          {
            "name": "Cancelled"
          }
        ]
      }
    }
  ],
  "errors": [
    {
      "code": 6000,
      "name": "RideAlreadyCompleted",
      "msg": "The ride is already completed and cannot be modified."
    },
    {
      "code": 6001,
      "name": "InvalidRideState",
      "msg": "The ride is not in the expected state for this operation."
    }
  ]
};
