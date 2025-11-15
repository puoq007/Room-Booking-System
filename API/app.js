// ---------------------- IMPORTS ----------------------
const express = require('express');
const app = express();
const bodyParser = require('body-parser');
const bcrypt = require('bcryptjs');
const con = require('./db'); // Database connection
const jwt = require('jsonwebtoken');
const path = require('path');
const multer = require('multer');
const cors = require('cors');
const fs = require('fs');

// ---------------------- MIDDLEWARE ----------------------
app.use(cors());
app.use(bodyParser.json());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ---------------------- JWT CONFIG ----------------------
const JWT_KEY = 'M0bileIs2Easy';

const middleware = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    if (!authHeader) return res.status(401).json({ message: "Authorization header missing" });

    const token = authHeader.split(" ")[1];
    if (!token) return res.status(400).json({ message: "Token missing" });

    try {
        const decoded = jwt.verify(token, JWT_KEY);
        req.user = decoded;
        next();
    } catch (err) {
        return res.status(403).json({ message: "Invalid or expired token" });
    }
};

// ใช้กับ profile / dashboard
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) return res.sendStatus(401);

    jwt.verify(token, JWT_KEY, (err, user) => {
        if (err) return res.sendStatus(403);
        req.user = user;
        next();
    });
}

// ---------------------- DATABASE ----------------------
con.connect(err => {
    if (err) {
        console.error('Database connection error:', err);
        process.exit(1);
    }
    console.log('Connected to database');
});

// ---------------------- ROOM SECTION ----------------------
app.use('/roomPicture', express.static(path.join(__dirname, 'roomPicture')));

const roomStorage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, path.join(__dirname, 'roomPicture')),
    filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});
const roomUpload = multer({ storage: roomStorage });

// Get all rooms
app.get('/room', (req, res) => {
    const sql = 'SELECT room_id, room_name, size, image, slot_1, slot_2, slot_3, slot_4 FROM room';
    con.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        results.forEach(room => {
            room.image = room.image ? `/roomPicture/${room.image}` : '/roomPicture/default.jpeg';
        });
        res.status(200).json(results);
    });
});

// Upload room image
app.post('/upload', roomUpload.single('image'), (req, res) => {
    if (!req.file) return res.status(400).json({ error: 'ไม่มีไฟล์อัปโหลด' });
    const validTypes = ['image/jpeg', 'image/png'];
    if (!validTypes.includes(req.file.mimetype)) return res.status(415).json({ error: 'ประเภทไฟล์ไม่รองรับ' });

    res.status(200).json({ message: 'ไฟล์อัปโหลดสำเร็จ', file: `/roomPicture/${req.file.filename}` });
});

// Add new room
app.post('/add-room', middleware, roomUpload.single('image'), (req, res) => {
    const { room_name, size, slot_1, slot_2, slot_3, slot_4 } = req.body;
    const image = req.file ? req.file.filename : null;
    if (!room_name || !size) return res.status(400).json({ error: 'Missing required fields' });

    const sql = `
      INSERT INTO room (room_name, size, image, slot_1, slot_2, slot_3, slot_4)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;
    con.query(sql, [room_name, size, image, slot_1, slot_2, slot_3, slot_4], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ message: 'Room added successfully' });
    });
});

// Update room
app.put('/room/:id', middleware, (req, res) => {
    const { id } = req.params;
    const { room_name, size, image, slot_1, slot_2, slot_3, slot_4 } = req.body;
    const imagePath = image ? path.basename(image) : null;
    const sql = `
      UPDATE room SET room_name = ?, size = ?, image = ?, slot_1 = ?, slot_2 = ?, slot_3 = ?, slot_4 = ?
      WHERE room_id = ?
    `;
    con.query(sql, [room_name, size, imagePath, slot_1, slot_2, slot_3, slot_4, id], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        if (results.affectedRows === 0) return res.status(404).json({ message: 'Room not found' });
        res.status(200).json({ message: 'Room updated successfully' });
    });
});

// ---------------------- PROFILE SECTION ----------------------
app.use('/profilePictures', express.static(path.join(__dirname, 'profilePictures')));

const profileStorage = multer.diskStorage({
    destination: (req, file, cb) => {
        const dir = path.join(__dirname, 'profilePictures');
        if (!fs.existsSync(dir)) fs.mkdirSync(dir);
        cb(null, dir);
    },
    filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname))
});
const profileUpload = multer({ storage: profileStorage });

// Upload profile image
app.post('/profile/upload', authenticateToken, profileUpload.single('profile_image'), (req, res) => {
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
    const userId = req.user.user_id;
    const filename = req.file.filename;
    con.query("UPDATE users SET profile_image = ? WHERE user_id = ?", [filename, userId], (err) => {
        if (err) return res.status(500).json({ error: 'DB error' });
        res.json({ message: "Upload success", profile_image: `/profilePictures/${filename}` });
    });
});

// Get profile
app.get('/profile', authenticateToken, (req, res) => {
    const userId = req.user.user_id;
    con.query("SELECT user_id, user_name, role, profile_image FROM users WHERE user_id = ?", [userId], (err, result) => {
        if (err) return res.status(500).json({ error: 'DB error' });
        if (result.length === 0) return res.status(404).json({ error: 'User not found' });
        const user = result[0];
        user.profile_image = user.profile_image ? `/profilePictures/${user.profile_image}` : null;
        res.json(user);
    });
});

// ---------------------- AUTH SECTION ----------------------
// Register
app.post('/register', (req, res) => {
    const { user_name, username, password } = req.body;
    const role = '1';
    if (!user_name || !username || !password) return res.status(400).send("Please provide name, username, and password");

    bcrypt.hash(password, 10, (err, hashedPassword) => {
        if (err) return res.status(500).send('Server error');
        const sql = 'INSERT INTO `users` (user_name, username, password, role) VALUES (?, ?, ?, ?)';
        con.query(sql, [user_name, username, hashedPassword, role], (err) => {
            if (err) return res.status(500).send('Database error');
            res.status(200).send('Account created successfully');
        });
    });
});

// Login
app.post('/login', (req, res) => {
    const { username, password } = req.body;
    const sql = 'SELECT user_id, password, role FROM users WHERE username = ?';
    con.query(sql, [username], (err, results) => {
        if (err) return res.status(500).send('Database error');
        if (results.length !== 1) return res.status(401).send('Username not found');
        const { password: hash, role, user_id } = results[0];
        bcrypt.compare(password, hash, (err, isMatch) => {
            if (err) return res.status(500).send('Server error');
            if (!isMatch) return res.status(401).send('Incorrect password');
            const payload = { username, role, user_id };
            const token = jwt.sign(payload, JWT_KEY, { expiresIn: '1d' });
            res.send({ token });
        });
    });
});

// ---------------------- RESERVATION SECTION ----------------------

// Reserve room
app.post('/reserve', (req, res) => {
    const { user_id, room_id, slot, borrowed_by } = req.body;
    if (!user_id || !room_id || !slot || !borrowed_by) return res.status(400).json({ error: 'Missing required fields' });

    const allowedSlots = ['slot_1', 'slot_2', 'slot_3', 'slot_4'];
    if (!allowedSlots.includes(slot)) return res.status(400).json({ error: 'Invalid slot' });

    const checkSql = 'SELECT ?? FROM room WHERE room_id = ?';
    con.query(checkSql, [slot, room_id], (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (results.length === 0) return res.status(404).json({ error: 'Room not found' });
        if (results[0][slot] === 2) return res.status(400).json({ error: 'This slot is already reserved' });

        const reserveSlotSql = 'UPDATE room SET ?? = 2 WHERE room_id = ?';
        con.query(reserveSlotSql, [slot, room_id], (err) => {
            if (err) return res.status(500).json({ error: 'Database error' });

            const reserveSql = `
                INSERT INTO information
                (user_id, room_id, slot, borrowed_by, borrowed_date, status)
                VALUES (?, ?, ?, ?, NOW(), '0')
            `;
            con.query(reserveSql, [user_id, room_id, slot, borrowed_by], (err, results) => {
                if (err) return res.status(500).json({ error: 'Database error' });
                res.json({ message: 'Reservation request submitted successfully', reservation_id: results.insertId });
            });
        });
    });
});

// Get information (history)
app.get('/information', middleware, (req, res) => {
    const userId = req.user.user_id;
    const userRole = req.user.role;
    let sql = `
    SELECT
        information.borrowed_date AS booking_date,
        room.room_name AS room_name,
        CASE
            WHEN information.slot = 'slot_1' THEN room.slot_1
            WHEN information.slot = 'slot_2' THEN room.slot_2
            WHEN information.slot = 'slot_3' THEN room.slot_3
            WHEN information.slot = 'slot_4' THEN room.slot_4
            ELSE 'unknown'
        END AS room_status,
        users.user_name AS booked_by,
        approvers.user_name AS approved_by,
        information.status AS status
    FROM
        information
    JOIN room ON information.room_id = room.room_id
    JOIN users ON information.borrowed_by = users.user_id
    LEFT JOIN users AS approvers ON information.approved_by = approvers.user_id
    `;
    if (userRole !== 3) sql += `WHERE information.borrowed_by = ? OR information.approved_by = ?`;

    con.query(sql, userRole === 3 ? [] : [userId, userId], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

// Pending reservations
app.get('/pending', middleware, (req, res) => {
    const userId = req.user.user_id;
    const sql = `
        SELECT information.id, information.borrowed_date AS booking_date, room.room_name AS room_name,
        CASE
            WHEN information.slot = 'slot_1' THEN room.slot_1
            WHEN information.slot = 'slot_2' THEN room.slot_2
            WHEN information.slot = 'slot_3' THEN room.slot_3
            WHEN information.slot = 'slot_4' THEN room.slot_4
            ELSE 'unknown'
        END AS room_status,
        users.user_name AS booked_by,
        approvers.user_name AS approver_name,
        information.status AS status
        FROM information
        JOIN room ON information.room_id = room.room_id
        JOIN users ON information.borrowed_by = users.user_id
        LEFT JOIN users AS approvers ON information.approved_by = approvers.user_id
        WHERE information.status = 0
    `;
    con.query(sql, [userId], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(results);
    });
});

// Approve / Disapprove
app.put('/approve/:reservationId', middleware, (req, res) => {
    const { reservationId } = req.params;
    const { user_id, action } = req.body;
    if (!['approve', 'disapprove'].includes(action)) return res.status(400).json({ error: 'Invalid action' });
    const status = action === 'approve' ? 1 : 2;

    const approveSql = `UPDATE information SET approved_by = ?, status = ? WHERE id = ? AND status = 0`;
    con.query(approveSql, [user_id, status, reservationId], (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error' });
        if (results.affectedRows === 0) return res.status(404).json({ message: 'Reservation not found or processed' });

        const fetchSlotSql = `SELECT room_id, slot FROM information WHERE id = ?`;
        con.query(fetchSlotSql, [reservationId], (err, result) => {
            if (err) return res.status(500).json({ error: 'Database error' });
            const { room_id, slot } = result[0];
            const newSlotStatus = action === 'approve' ? 'reserve' : 'free';
            const updateSlotSql = `UPDATE room SET ?? = ? WHERE room_id = ?`;
            con.query(updateSlotSql, [slot, newSlotStatus, room_id], (err) => {
                if (err) return res.status(500).json({ error: 'Database error' });
                const message = action === 'approve' ? 'Reservation approved' : 'Reservation denied';
                res.json({ message, approved_by: user_id, status, reservationId, slot, room_id });
            });
        });
    });
});

// Search reservations
app.post('/search', (req, res) => {
    const { user_id, room_id, status } = req.body;
    if (!user_id || !room_id || !status) return res.status(400).send('user_id, room_id, and status are required');
    const sql = 'SELECT * FROM information WHERE user_id = ? AND room_id = ? AND status = ?';
    con.query(sql, [user_id, room_id, status], (err, results) => {
        if (err) return res.status(500).send('Server error');
        if (results.length === 0) return res.status(401).send('No matching records found.');
        res.status(200).json(results);
    });
});

// ---------------------- DASHBOARD SECTION ----------------------
app.get('/dashboard', (req, res) => {
    const sql = `
        SELECT
            COUNT(DISTINCT room_id) AS totalRooms,
            COUNT(*) * 4 AS totalSlots, -- 4 slot ต่อ room
            SUM(
                IF(slot_1 = 'free', 1, 0) + IF(slot_2 = 'free', 1, 0) +
                IF(slot_3 = 'free', 1, 0) + IF(slot_4 = 'free', 1, 0)
            ) AS freeSlots,
            SUM(
                IF(slot_1 = 'reserve', 1, 0) + IF(slot_2 = 'reserve', 1, 0) +
                IF(slot_3 = 'reserve', 1, 0) + IF(slot_4 = 'reserve', 1, 0)
            ) AS reservedSlots,
            SUM(
                IF(slot_1 = 'disable', 1, 0) + IF(slot_2 = 'disable', 1, 0) +
                IF(slot_3 = 'disable', 1, 0) + IF(slot_4 = 'disable', 1, 0)
            ) AS disabledSlots,
            SUM(
                IF(slot_1 = 'pending', 1, 0) + IF(slot_2 = 'pending', 1, 0) +
                IF(slot_3 = 'pending', 1, 0) + IF(slot_4 = 'pending', 1, 0)
            ) AS pendingSlots
        FROM room
    `;

    con.query(sql, (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json(result[0]);
    });
});

// ---------------------- START SERVER ----------------------
const PORT = 5554;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));