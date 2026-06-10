const { pool } = require('./src/config/db');

const BACKEND_URL = 'http://localhost:3000';
const TEST_VENUE_ID = 'smash-arena';
const TEST_DATE = '2026-06-15'; // A future date
const TEST_TIME = '10:00';

async function runTest() {
  console.log('--- STARTING CONCURRENCY STRESS TEST ---');
  
  // 1. Clear existing bookings in database to ensure clean state
  console.log('1. Cleaning bookings table...');
  await pool.query('DELETE FROM bookings');
  console.log('Bookings table cleared.');

  // 2. Prepare 10 concurrent requests from 10 different users
  const numberOfUsers = 10;
  console.log(`2. Preparing ${numberOfUsers} concurrent booking requests for:`);
  console.log(`   Venue: ${TEST_VENUE_ID}`);
  console.log(`   Date: ${TEST_DATE}`);
  console.log(`   Time: ${TEST_TIME}`);

  const requests = Array.from({ length: numberOfUsers }).map((_, index) => {
    const userId = `user_stress_${index + 1}`;
    
    return fetch(`${BACKEND_URL}/bookings`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': userId,
      },
      body: JSON.stringify({
        venue_id: TEST_VENUE_ID,
        date: TEST_DATE,
        start_time: TEST_TIME,
      }),
    })
      .then(async (response) => {
        const body = await response.json();
        return {
          userId,
          status: response.status,
          body,
        };
      })
      .catch((err) => {
        return {
          userId,
          status: 'ERROR',
          message: err.message,
        };
      });
  });

  // 3. Fire all requests concurrently using Promise.all
  console.log('3. Firing all requests concurrently...');
  const results = await Promise.all(requests);
  console.log('All requests completed.');

  // 4. Analyze results
  console.log('4. Analyzing results...');
  let successCount = 0;
  let conflictCount = 0;
  let errorCount = 0;
  let successfulUser = null;

  results.forEach((res) => {
    if (res.status === 201) {
      successCount++;
      successfulUser = res.userId;
      console.log(`   [SUCCESS] ${res.userId} booked the slot (Status 201)`);
    } else if (res.status === 409) {
      conflictCount++;
      console.log(`   [BLOCKED] ${res.userId} failed - slot taken (Status 409)`);
    } else {
      errorCount++;
      console.log(`   [ERROR] ${res.userId} encountered error status ${res.status}:`, res.body || res.message);
    }
  });

  console.log('--- SUMMARY ---');
  console.log(`Successes (201): ${successCount}`);
  console.log(`Conflicts (409): ${conflictCount}`);
  console.log(`Errors:         ${errorCount}`);

  // 5. Verify database state
  console.log('5. Verifying database state directly...');
  const dbBookings = await pool.query(
    'SELECT * FROM bookings WHERE venue_id = $1 AND booking_date = $2 AND start_time = $3',
    [TEST_VENUE_ID, TEST_DATE, TEST_TIME]
  );

  console.log(`   Bookings found in database: ${dbBookings.rows.length}`);
  if (dbBookings.rows.length === 1) {
    const bookedByUser = dbBookings.rows[0].user_id;
    console.log(`   Booked by user in DB: ${bookedByUser}`);
    
    if (bookedByUser === successfulUser && successCount === 1 && conflictCount === numberOfUsers - 1 && errorCount === 0) {
      console.log('\n✅ TEST PASSED: Concurrency check succeeded perfectly! Exactly one user booked the slot, and all others were rejected with 409 Conflict.');
    } else {
      console.log('\n❌ TEST FAILED: Discrepancy detected between response status counts and database records.');
    }
  } else {
    console.log('\n❌ TEST FAILED: Database does not contain exactly 1 booking for this slot.');
  }

  // Close the DB connection pool
  await pool.end();
}

// Run the test
runTest().catch((err) => {
  console.error('Fatal error during test:', err);
  pool.end();
});
