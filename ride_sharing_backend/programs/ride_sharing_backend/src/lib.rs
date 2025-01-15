#![allow(unused)]
use anchor_lang::prelude::*;

declare_id!("F8PqJddLMwqQA7tKx6CCL8twfGeDQwV7XbCF1Ppxf5gH"); // Replace this with the deployed program ID

#[program]
pub mod ride_sharing {
    use super::*;

    // Create a new ride
    pub fn create_ride(ctx: Context<CreateRide>, unique_id: u64, fare: u64, distance: u64) -> Result<()> {
        let ride_pda = ctx.accounts.ride.key();
        let ride = &mut ctx.accounts.ride;

        msg!("🚀 New ride created! PDA: {}", ride_pda);
        msg!("Expected Seeds: [b\"ride\", {:?}, {:?}]", ctx.accounts.rider.key(), unique_id);

        // Set account data
        ride.rider = ctx.accounts.rider.key();
        ride.driver = Pubkey::default(); // Initialize as empty
        ride.unique_id = unique_id;
        ride.fare = fare;
        ride.distance = distance; // Store distance on-chain
        ride.status = RideStatus::Requested;
        ride.bump = *ctx.bumps.get("ride").unwrap();

        msg!("🚀 New ride created! Distance: {} meters, Fare: {}", distance, fare);

        Ok(())
    }

    // Accept a ride request
    pub fn accept_ride(ctx: Context<AcceptRide>) -> Result<()> {
        let ride = &mut ctx.accounts.ride;
        require!(ride.status == RideStatus::Requested, RideError::InvalidRideState);

        // Assign driver to the ride
        ride.driver = ctx.accounts.driver.key();
        ride.status = RideStatus::Accepted;

        msg!("🚗 Ride accepted by driver: {:?}", ride.driver);

        Ok(())
    }

    // Complete the ride
    pub fn complete_ride(ctx: Context<CompleteRide>) -> Result<()> {
        let ride = &mut ctx.accounts.ride;
        require!(ride.status == RideStatus::Accepted, RideError::InvalidRideState);

        ride.status = RideStatus::Completed;

        msg!("✅ Ride completed successfully!");

        Ok(())
    }

    // Cancel the ride
    pub fn cancel_ride(ctx: Context<CancelRide>, by_rider: bool) -> Result<()> {
        let ride = &mut ctx.accounts.ride;
        require!(ride.status != RideStatus::Completed, RideError::RideAlreadyCompleted);

        ride.status = RideStatus::Cancelled;

        if by_rider {
            msg!("❌ Ride cancelled by the rider.");
        } else {
            msg!("❌ Ride cancelled by the driver.");
        }

        Ok(())
    }

    // Close the ride account
    pub fn close_ride(ctx: Context<CloseRide>) -> Result<()> {
        let ride = &mut ctx.accounts.ride;
        ride.close(ctx.accounts.rider.to_account_info())?; // Transfer rent to the rider
        msg!("Ride account closed successfully!");
        Ok(())
    }
}

// Contexts
#[derive(Accounts)]
#[instruction(unique_id: u64)]
pub struct CreateRide<'info> {
    #[account(
        init,
        payer = rider,
        space = 8 + 32 + 32 + 8 + 8 + 8 + 1 + 1, // Updated space calculation (added distance field)
        seeds = [b"ride", rider.key().as_ref(), unique_id.to_le_bytes().as_ref()],
        bump
    )]
    pub ride: Account<'info, Ride>,
    #[account(mut)]
    pub rider: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct AcceptRide<'info> {
    #[account(
        mut,
        seeds = [b"ride", ride.rider.as_ref(), ride.unique_id.to_le_bytes().as_ref()],
        bump = ride.bump
    )]
    pub ride: Account<'info, Ride>,
    pub driver: Signer<'info>,
}

#[derive(Accounts)]
pub struct CompleteRide<'info> {
    #[account(
        mut,
        seeds = [b"ride", ride.rider.as_ref(), ride.unique_id.to_le_bytes().as_ref()],
        bump = ride.bump
    )]
    pub ride: Account<'info, Ride>,
    pub user: Signer<'info>,
}

#[derive(Accounts)]
pub struct CancelRide<'info> {
    #[account(
        mut,
        seeds = [b"ride", ride.rider.as_ref(), ride.unique_id.to_le_bytes().as_ref()],
        bump = ride.bump
    )]
    pub ride: Account<'info, Ride>,
    pub user: Signer<'info>,
}

#[derive(Accounts)]
pub struct CloseRide<'info> {
    #[account(
        mut,
        close = rider,
        seeds = [b"ride", ride.rider.as_ref(), ride.unique_id.to_le_bytes().as_ref()],
        bump = ride.bump
    )]
    pub ride: Account<'info, Ride>,
    #[account(mut)]
    pub rider: Signer<'info>,
}

// Data Models
#[account]
pub struct Ride {
    pub rider: Pubkey,       // Public key of the rider
    pub driver: Pubkey,      // Public key of the driver
    pub unique_id: u64,      // Unique ID for the ride
    pub fare: u64,           // Fare for the ride
    pub distance: u64,       // Distance in meters (new field)
    pub status: RideStatus,  // Current status of the ride
    pub bump: u8,            // PDA bump
}

#[derive(Clone, Copy, Debug, PartialEq, AnchorSerialize, AnchorDeserialize)]
pub enum RideStatus {
    Requested, // Ride has been requested but not yet accepted
    Accepted,  // Ride has been accepted by a driver
    Completed, // Ride has been completed
    Cancelled, // Ride has been cancelled
}

// Error Codes
#[error_code]
pub enum RideError {
    #[msg("The ride is already completed and cannot be modified.")]
    RideAlreadyCompleted,
    #[msg("The ride is not in the expected state for this operation.")]
    InvalidRideState,
}
