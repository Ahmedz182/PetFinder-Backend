const express = require('express');
const mysql = require('mysql');
const bodyParser = require('body-parser'); // Import body-parser
const cors = require('cors'); // Import cors

const app = express();
const port = 3000;
// Middleware to parse JSON bodies
app.use(bodyParser.json()); // Use body-parser to parse JSON
// Middleware to parse JSON requests
app.use(express.json());
// Enable CORS for all routes
app.use(cors()); // Add this line to enable CORS
// MySQL connection
const connection = mysql.createConnection({
    host: 'localhost',
    user: 'root',     // MySQL root user
    password: '',     // No password
    database: 'pets'  // Your database name
});

// Connect to MySQL
connection.connect((err) => {
    if (err) {
        console.error('Error connecting to MySQL:', err);
        return;
    }
    console.log('Connected to MySQL database.');
});

// Routes for get all  Users
app.get('/api/users', (req, res) => {
    connection.query('SELECT * FROM Users', (err, results) => {
        if (err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

// Routes for get single user 
app.post('/api/user', (req, res) => {  // Change GET to POST
    const { email, password } = req.body; // Get email and password from body

    if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required' });
    }

    // Use a parameterized query to prevent SQL injection
    const query = 'SELECT * FROM Users WHERE Email = ? AND Password = ?';
    connection.query(query, [email, password], (err, results) => {
        if (err) return res.status(500).json({ error: err });

        // Check if any user matches the email and password
        if (results.length === 0) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        // If there's a match, return the user details
        res.json(results[0]); // Return the first matching user
    });
});


// Create a new user
app.post('/api/users', (req, res) => {
    const newUser = req.body;
    connection.query('INSERT INTO Users SET ?', newUser, (err, result) => {
        if (err) return res.status(500).json({ error: err });
        res.status(201).json({ id: result.insertId, ...newUser });
    });
});
// Route for get all Categories
app.get('/api/categories', (req, res) => {
    connection.query('SELECT * FROM Categories', (err, results) => {
        if (err) return res.status(500).json({ error: err });
        res.json(results);
    });
});
// Route for adding a new category
app.post('/api/categories', (req, res) => {
    const { categoryName } = req.body; // Get category name from the request body

    // Validate input
    if (!categoryName || typeof categoryName !== 'string') {
        return res.status(400).json({ error: 'Category name is required and must be a string.' });
    }

    // Prepare the SQL query to insert a new category
    const query = 'INSERT INTO Categories (CategoryName) VALUES (?)';

    connection.query(query, [categoryName], (err, results) => {
        if (err) {
            // Handle duplicate category names or other errors
            if (err.code === 'ER_DUP_ENTRY') {
                return res.status(409).json({ error: 'Category already exists.' });
            }
            return res.status(500).json({ error: err });
        }
        // Respond with the newly created category's ID
        res.status(201).json({ message: 'Category added successfully', categoryId: results.insertId });
    });
});
// // Routes for Pets
// app.get('/api/pets', (req, res) => {
//     connection.query('SELECT * FROM Pets', (err, results) => {
//         if (err) return res.status(500).json({ error: err });
//         res.json(results);
//     });
// });


// Routes for Pets
app.get('/api/pets', (req, res) => {
    const { category, location } = req.query; // Extract category and location from query parameters

    // Base query
    let sql = 'SELECT * FROM Pets';
    const queryParams = [];

    // Add filters based on the query parameters
    if (category) {
        sql += ' WHERE CategoryName = ?';
        queryParams.push(category); // Push the category to the parameters array
    }

    if (location) {
        // If location is provided, we need to handle it
        if (queryParams.length > 0) {
            sql += ' AND Location LIKE ?'; // Use AND if category is already in the query
        } else {
            sql += ' WHERE Location LIKE ?'; // Use WHERE if category is not in the query
        }
        queryParams.push(`%${location}%`); // Using LIKE for partial matches
    }

    // Execute the query
    connection.query(sql, queryParams, (err, results) => {
        if (err) return res.status(500).json({ error: err });
        res.json(results);
    });
});


// Get a single pet by ID
app.get('/api/pet', (req, res) => {
    const petId = req.query.id;

    // Log the incoming query parameter
    console.log('Received Pet ID:', petId);

    if (!petId) {
        return res.status(400).json({ message: 'Pet ID is required' });
    }

    // Log the query being executed
    console.log('Executing Query: SELECT * FROM Pets WHERE PetID = ?', [petId]);

    connection.query('SELECT * FROM Pets WHERE PetID = ?', [petId], (err, results) => {
        if (err) {
            console.error('Database Error:', err);
            return res.status(500).json({ error: err });
        }

        // Log the results returned from the database
        console.log('Query Results:', results);

        if (results.length === 0) {
            return res.status(404).json({ message: 'Pet not found' });
        }

        res.json(results[0]);
    });
});
//Edit Pet 
app.put('/api/pet/:id', (req, res) => {
    console.log("Update request received for pet ID:", req.params.id); // Log incoming request
    const petId = req.params.id;
    const updatedPetData = req.body; // Assuming you send updated data in the request body

    // Build the query to update pet details
    const query = 'UPDATE Pets SET ? WHERE PetID = ?';

    connection.query(query, [updatedPetData, petId], (err, result) => {
        if (err) {
            console.error('Error updating pet:', err);
            return res.status(500).json({ error: 'Error updating pet.' });
        }

        console.log("Update result:", result); // Log result of update operation

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Pet not found.' });
        }

        res.status(200).json({ message: 'Pet updated successfully.' });
    });
});



// Delete Pet
app.delete('/api/pet/:id', (req, res) => {
    console.log("Delete request received for pet ID:", req.params.id); // Log incoming request
    const petId = req.params.id;

    // First, delete related records from PetStatusChangeLog
    const deleteChangelogQuery = 'DELETE FROM PetStatusChangeLog WHERE PetID = ?';

    connection.query(deleteChangelogQuery, [petId], (err) => {
        if (err) {
            console.error('Error deleting from PetStatusChangeLog:', err);
            return res.status(500).json({ error: 'Error deleting related records.' });
        }

        // Next, delete related records from AdoptionBookings
        const deleteBookingsQuery = 'DELETE FROM AdoptionBookings WHERE PetID = ?';

        connection.query(deleteBookingsQuery, [petId], (err) => {
            if (err) {
                console.error('Error deleting from AdoptionBookings:', err);
                return res.status(500).json({ error: 'Error deleting related records.' });
            }

            // Finally, delete the pet
            const deletePetQuery = 'DELETE FROM Pets WHERE PetID = ?';

            connection.query(deletePetQuery, [petId], (err, result) => {
                if (err) {
                    console.error('Error deleting pet:', err);
                    return res.status(500).json({ error: 'Error deleting pet.' });
                }

                if (result.affectedRows === 0) {
                    return res.status(404).json({ error: 'Pet not found.' });
                }

                res.status(200).json({ message: 'Pet deleted successfully.' });
            });
        });
    });
});









// Create a new pet
app.post('/api/pets', (req, res) => {
    const newPet = req.body;
    connection.query('INSERT INTO Pets SET ?', newPet, (err, result) => {
        if (err) return res.status(500).json({ error: err });
        res.status(201).json({ id: result.insertId, ...newPet });
    });
});

// Routes for AdoptionBookings
app.get('/api/adoptionBookings', (req, res) => {
    connection.query('SELECT * FROM AdoptionBookings', (err, results) => {
        if (err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

// Create a new adoption booking
app.post('/api/adoptionBookings', (req, res) => {
    const newBooking = req.body;
    connection.query('INSERT INTO AdoptionBookings SET ?', newBooking, (err, result) => {
        if (err) return res.status(500).json({ error: err });
        res.status(201).json({ id: result.insertId, ...newBooking });
    });
});


// Route to get all adoption bookings
app.get('/api/adoptionBookings', (req, res) => {
    connection.query('SELECT * FROM AdoptionBookings', (err, results) => {
        if (err) {
            return res.status(500).json({ error: err });
        }
        res.status(200).json(results);
    });
});

// Route to get adoption bookings by PetID
app.get('/api/adoptionBookings/:petId', (req, res) => {
    const petId = req.params.petId; // Get the petId from the URL parameter

    // Query the database for the booking status based on the petId
    connection.query('SELECT * FROM AdoptionBookings WHERE PetID = ?', [petId], (err, results) => {
        if (err) {
            return res.status(500).json({ error: err });
        }
        if (results.length === 0) {
            return res.status(404).json({ message: "No booking found for the given PetID" });
        }
        res.status(200).json(results); // Return the found booking(s)
    });
});


// Routes for get all Vendors
app.get('/api/vendors', (req, res) => {
    connection.query('SELECT * FROM Vendors', (err, results) => {
        if (err) return res.status(500).json({ error: err });
        res.json(results);
    });
});


// Routes for get Single Vendors

app.post('/api/vendor', (req, res) => {  // Change GET to POST
    const { email, password } = req.body; // Get email and password from body

    if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required' });
    }

    // Use a parameterized query to prevent SQL injection
    const query = 'SELECT * FROM Vendors WHERE Email = ? AND Password = ?';
    connection.query(query, [email, password], (err, results) => {
        if (err) return res.status(500).json({ error: err });

        // Check if any vendor matches the email and password
        if (results.length === 0) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        // If there's a match, return the vendor details
        res.json(results[0]); // Return the first matching vendor
    });
});



// Create a new vendor
app.post('/api/vendors', (req, res) => {
    const newVendor = req.body;
    connection.query('INSERT INTO Vendors SET ?', newVendor, (err, result) => {
        if (err) return res.status(500).json({ error: err });
        res.status(201).json({ id: result.insertId, ...newVendor });
    });
});

// Routes for PetStatusChangeLog
app.get('/api/petStatusChangeLog', (req, res) => {
    connection.query('SELECT * FROM PetStatusChangeLog', (err, results) => {
        if (err) return res.status(500).json({ error: err });
        res.json(results);
    });
});

// Create a new status change log entry
app.post('/api/petStatusChangeLog', (req, res) => {
    const newLog = req.body;

    // First, insert the new log into PetStatusChangeLog
    connection.query('INSERT INTO PetStatusChangeLog SET ?', newLog, (err, result) => {
        if (err) {
            return res.status(500).json({ error: err });
        }

        // If insert is successful, update the pet's status
        const petID = newLog.PetID;  // Assuming the PetID is passed in the request body
        const newStatus = newLog.NewStatus;  // Assuming the new status is passed in the request body

        connection.query('UPDATE Pets SET Status = ? WHERE PetID = ?', [newStatus, petID], (updateErr) => {
            if (updateErr) {
                // Rollback the log insert if the update fails
                connection.query('DELETE FROM PetStatusChangeLog WHERE LogID = ?', [result.insertId], (rollbackErr) => {
                    if (rollbackErr) {
                        console.error("Rollback failed:", rollbackErr);
                    }
                });
                return res.status(500).json({ error: updateErr });
            }

            // If both operations are successful, respond with the new log entry
            res.status(201).json({ id: result.insertId, ...newLog });
        });
    });
});


// Define the default route
app.get('/api/', (req, res) => {
    res.send('Welcome to Petfinder');
});

// Start the server
app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});
