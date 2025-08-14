const express = require('express');
const app = express();
const bodyParser = require('body-parser');
const bcrypt = require('bcrypt');
const con = require('./db'); // Import connection to the database
const jwt = require('jsonwebtoken');
const path = require('path');
const multer = require('multer');
const cors = require('cors');


// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// JWT Authentication Middleware
const JWT_KEY = 'M0bileIs2Easy';
const middleware = (req, res, next) => {
    console.log('Headers:', req.headers); // เช็ค Header ทั้งหมด
    const authHeader = req.headers['authorization'];
    if (!authHeader) {
        console.error('Authorization header is missing');
        return res.status(401).json({ message: "Authorization header missing" });
    }

    const token = authHeader.split(" ")[1];
    if (!token) {
        console.error('Token is missing in authorization header');
        return res.status(400).json({ message: "Token missing in authorization header" });
    }

    try {
        const decoded = jwt.verify(token, JWT_KEY);
        console.log('Decoded Token:', decoded); // Log ค่า Token
        req.user = decoded;
        next();
    } catch (err) {
        console.error('Invalid or expired token:', err.message);
        return res.status(403).json({ message: "Invalid or expired token" });
    }
};


// Role checking middleware
const checkRole = (role) => (req, res, next) => {
    if (req.user.role === role) {
        next();
    } else {
        res.status(403).send('Access denied');
    }
};

// Database connection
con.connect(err => {
    if (err) {
        console.error('Database connection error:', err);
        process.exit(1); // Exit if DB connection fails
    }
    console.log('Connected to database');
});

// Serve static files
app.use('/roomPicture', express.static(path.join(__dirname, 'roomPicture')));

// Multer configuration
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, path.join(__dirname, 'roomPicture')),
    filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname)),
});
const upload = multer({ storage });

// Slots data
const slots = [
    { id: 'slot_1', time: '08:00-10:00' },
    { id: 'slot_2', time: '10:00-12:00' },
    { id: 'slot_3', time: '13:00-15:00' },
    { id: 'slot_4', time: '15:00-17:00' },
];

// Get all rooms
app.get('/room', (req, res) => {
    const sql = 'SELECT room_id, room_name, size, image, slot_1, slot_2, slot_3, slot_4 FROM room';
    con.query(sql, (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error', details: err.message });

        results.forEach(room => {
            room.image = room.image ? `/roomPicture/${room.image}` : '/roomPicture/default.jpeg';
        });

        res.status(200).json(results);
    });
});

// อัปโหลดรูปภาพของห้อง
app.post('/upload', upload.single('image'), (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'ไม่มีไฟล์อัปโหลด' });
    }

    // ตรวจสอบประเภทของไฟล์ (สามารถเลือกไฟล์ที่รองรับได้)
    const validTypes = ['image/jpeg', 'image/png'];
    if (!validTypes.includes(req.file.mimetype)) {
        return res.status(415).json({ error: 'ประเภทไฟล์ไม่รองรับ' });
    }

    res.status(200).json({
        message: 'ไฟล์อัปโหลดสำเร็จ',
        file: `/roomPicture/${req.file.filename}`
    });
});

// Update room details
app.put('/room/:id', middleware, (req, res) => {
    const { id } = req.params;
    const { room_name, size, image, slot_1, slot_2, slot_3, slot_4 } = req.body;

    // แปลง URL หรือเส้นทางให้เป็นชื่อไฟล์
    const imagePath = image ? path.basename(image) : null;

    const sql = 'UPDATE room SET room_name = ?, size = ?, image = ?, slot_1 = ?, slot_2 = ?, slot_3 = ?, slot_4 = ? WHERE room_id = ?';
    con.query(sql, [room_name, size, imagePath, slot_1, slot_2, slot_3, slot_4, id], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        if (results.affectedRows === 0) return res.status(404).json({ message: 'Room not found' });

        res.status(200).json({ message: 'Room updated successfully' });
    });
});


// Add new room
app.post('/add-room', middleware, upload.single('image'), (req, res) => {
    const { room_name, size, slot_1, slot_2, slot_3, slot_4 } = req.body;
    const image = req.file ? req.file.filename : null;

    if (!room_name || !size) return res.status(400).json({ error: 'Missing required fields' });

    const sql = `
      INSERT INTO room (room_name, size, image, slot_1, slot_2, slot_3, slot_4)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;
    con.query(sql, [room_name, size, image, slot_1, slot_2, slot_3, slot_4], (err, results) => {
        if (err) return res.status(500).json({ error: 'Database error', details: err.message });
        res.status(200).json({
            message: 'Room added successfully',
            room: { room_name, size, image, slot_1, slot_2, slot_3, slot_4 }
        });
    });
});


// Endpoint สำหรับการสร้างบัญชีผู้ใช้ (Register)
app.post('/register', (req, res) => {
    const { user_name, username, password } = req.body;
    const role = '1'; // ตั้งค่า role เป็น 'student' อัตโนมัติ

    if (!user_name || !username || !password) {
        return res.status(400).send("Please provide name, username, and password");
    }

    bcrypt.hash(password, 10, (err, hashedPassword) => {
        if (err) {
            console.error('Error hashing password:', err);
            return res.status(500).send('Server error');
        }

        const sql = 'INSERT INTO `users` (user_name, username, password, role) VALUES (?, ?, ?, ?)';
        con.query(sql, [user_name, username, hashedPassword, role], (err, results) => {
            if (err) {
                console.error('Database error:', err);
                return res.status(500).send('Database error');
            }
            res.status(200).send('Account created successfully');
        });
    });
});

// Endpoint สำหรับการเข้าสู่ระบบ (Login)
app.post('/login', (req, res) => {
    const { username, password } = req.body;

    // แก้ไข SQL Query ให้ดึง user_id มาด้วย
    const sql = 'SELECT user_id, password, role FROM users WHERE username = ?';
    con.query(sql, [username], (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).send('Database error');
        }

        if (results.length !== 1) {
            return res.status(401).send('Username not found');
        }

        const { password: hash, role, user_id } = results[0];  // ดึง user_id มาด้วย
        bcrypt.compare(password, hash, (err, isMatch) => {
            if (err) {
                console.error('Error comparing password:', err);
                return res.status(500).send('Server error');
            }

            if (isMatch) {
                // สร้าง JWT token โดยเพิ่ม user_id ลงไปใน payload
                const payload = { username, role, user_id };  // เพิ่ม user_id ใน payload
                const token = jwt.sign(payload, JWT_KEY, { expiresIn: '1d' });

                // ส่ง token กลับไปใน response
                res.send({ token });
            } else {
                res.status(401).send('Incorrect password');
            }
        });
    });
});

 // POST: จองห้อง (นักศึกษา)
app.post('/reserve', (req, res) => {
    const { user_id, room_id, slot, borrowed_by } = req.body;

    // ตรวจสอบฟิลด์ที่จำเป็น
    if (!user_id || !room_id || !slot || !borrowed_by) {
        return res.status(400).json({ error: 'Missing required fields' });
    }

    // ตรวจสอบว่าสล็อตที่เลือกถูกต้องหรือไม่
    const allowedSlots = ['slot_1', 'slot_2', 'slot_3', 'slot_4'];
    if (!allowedSlots.includes(slot)) {
        return res.status(400).json({ error: 'Invalid slot' });
    }

    // ตรวจสอบสถานะของสล็อตในฐานข้อมูล
    const checkSql = 'SELECT ?? FROM room WHERE room_id = ?';
    con.query(checkSql, [slot, room_id], (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ error: 'Database error' });
        }

        if (results.length === 0) {
            return res.status(404).json({ error: 'Room not found' });
        }

        if (results[0][slot] === 2) {
            return res.status(400).json({ error: 'This slot is already reserved' });
        }

        // อัปเดต slot ที่เลือกเป็นสถานะ "reserved"
        const reserveSlotSql = 'UPDATE room SET ?? = 2 WHERE room_id = ?';
        con.query(reserveSlotSql, [slot, room_id], (err) => {
            if (err) {
                console.error('Database error:', err);
                return res.status(500).json({ error: 'Database error' });
            }

            // บันทึกการจองลงในตาราง information
            const reserveSql = `
                INSERT INTO information
                (user_id, room_id, slot, borrowed_by, borrowed_date, status)
                VALUES (?, ?, ?, ?, NOW(), '0')
            `;
            con.query(reserveSql, [user_id, room_id, slot, borrowed_by], (err, results) => {
                if (err) {
                    console.error('Database error:', err);
                    return res.status(500).json({ error: 'Database error' });
                }
                res.json({
                    message: 'Reservation request submitted successfully',
                    reservation_id: results.insertId
                });
            });
        });
    });
});

// Endpoint สำหรับการดูประวัติการจอง
app.get('/information', middleware, (req, res) => {
    const userId = req.user.user_id; // ใช้ user_id ที่ได้จาก Token
    const userRole = req.user.role; // ดึง role จาก Token (ค่าตรงนี้มาจากฐานข้อมูล เป็น 1, 2 หรือ 3)

    // SQL Query สำหรับดึงข้อมูล
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
    JOIN
        room ON information.room_id = room.room_id
    JOIN
        users ON information.borrowed_by = users.user_id
    LEFT JOIN
        users AS approvers ON information.approved_by = approvers.user_id
    `;

    // ตรวจสอบสิทธิ์ role
    if (userRole === 3) {
        // หาก role คือ 3 (staff) ให้ดูข้อมูลทั้งหมด
        console.log('Staff (role 3) is accessing all booking information');
    } else {
        // สำหรับ role อื่น ๆ เช่น student (1) หรือ approver (2) ให้กรองเฉพาะข้อมูลที่เกี่ยวข้อง
        sql += `WHERE information.borrowed_by = ? OR information.approved_by = ?`;
    }

    // Debug log
    console.log('User ID:', userId, 'Role:', userRole);

    // Query ข้อมูลจากฐานข้อมูล
    con.query(sql, userRole === 3 ? [] : [userId, userId], (err, results) => {
        if (err) {
            console.error('Error executing query:', err);
            return res.status(500).json({ error: err.message });
        }

        // ส่งข้อมูลกลับไปในรูป JSON
        res.json(results);
    });
});

// get_pending (Approve)
app.get('/pending', middleware, (req, res) => {
    const userId = req.user.user_id;  // ดึง user_id จากการยืนยันตัวตน
    const sql = `
        SELECT
            information.id,
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
            approvers.user_name AS approver_name,
            information.status AS status          
        FROM
            information
        JOIN
            room ON information.room_id = room.room_id
        JOIN
            users ON information.borrowed_by = users.user_id
        LEFT JOIN
            users AS approvers ON information.approved_by = approvers.user_id
        WHERE
            information.status = 0
    `;
    con.query(sql, [userId], (err, results) => {
        if (err) {
            console.error('Error executing query:', err);
            return res.status(500).json({ error: err.message });
        }
        res.json(results);  // ส่งผลลัพธ์การจองที่มีสถานะ '0' (รออนุมัติ) กลับ
    });
});

// Endpoint สำหรับการอนุมัติหรือไม่อนุมัติ request (Approve)
app.put('/approve/:reservationId', middleware, (req, res) => {
    const { reservationId } = req.params;
    const { user_id, action } = req.body;

    // Validate that the action is either 'approve' or 'disapprove'
    if (!['approve', 'disapprove'].includes(action)) {
        return res.status(400).json({ error: 'Invalid action. It must be "approve" or "disapprove".' });
    }

    // Determine the status (1 = Approved, 2 = Denied)
    const status = action === 'approve' ? 1 : 2;

    // SQL query to update the information table (approval/denial)
    const approveSql = `
        UPDATE information
        SET approved_by = ?, status = ?
        WHERE id = ? AND status = 0
    `;

    con.query(approveSql, [user_id, status, reservationId], (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).json({ error: 'Database error' });
        }

        if (results.affectedRows === 0) {
            return res.status(404).json({ message: 'Reservation not found or already processed' });
        }

        // Fetch room_id and slot for the reservation
        const fetchSlotSql = `
            SELECT room_id, slot
            FROM information
            WHERE id = ?
        `;
        con.query(fetchSlotSql, [reservationId], (err, result) => {
            if (err) {
                console.error('Database error:', err);
                return res.status(500).json({ error: 'Database error' });
            }

            if (result.length === 0) {
                return res.status(404).json({ message: 'Room or slot not found for the reservation' });
            }

            const { room_id, slot } = result[0];

            // Update the slot status in the room table
            const newSlotStatus = action === 'approve' ? 'reserve' : 'free';
            const updateSlotSql = `
                UPDATE room
                SET ?? = ?
                WHERE room_id = ?
            `;
            con.query(updateSlotSql, [slot, newSlotStatus, room_id], (err) => {
                if (err) {
                    console.error('Database error:', err);
                    return res.status(500).json({ error: 'Database error' });
                }

                // Construct success message based on the action
                const message = action === 'approve'
                    ? 'Reservation approved and slot marked as reserved'
                    : 'Reservation denied and slot marked as free';

                res.json({
                    message,
                    approved_by: user_id,
                    status,
                    reservationId,
                    slot,
                    room_id
                });
            });
        });
    });
});


// // Endpoint สำหรับการดูประวัติการจอง
// app.get('/history/:user_id', (req, res) => {
//     const userId = req.params.user_id;

//     const roleSql = 'SELECT role FROM users WHERE user_id = ?';

//     con.query(roleSql, [userId], (err, userResults) => {
//         if (err) {
//             console.error('Error retrieving user role:', err);
//             return res.status(500).json('Database error');
//         }

//         if (userResults.length === 0) {
//             return res.status(404).json('User not found');
//         }

//         const userRole = userResults[0].role;
//         let historySql = '';
//         let fields = '';

//         // Construct the query based on the role
//         if (userRole === 1) {
//             fields = 'borrowed_date, room_id, approved_by, status';
//         } else if (userRole === 2) {
//             fields = 'borrowed_date, room_id, borrowed_by, status';
//         } else if (userRole === 3) {
//             fields = 'borrowed_date, room_id, approved_by, borrowed_by, status';
//         } else {
//             return res.status(403).json('Invalid role');
//         }

//         historySql = `SELECT ${fields} FROM information`;

//         // Execute the query to get the reservation history based on the role
//         con.query(historySql, (err, historyResults) => {
//             if (err) {
//                 console.error('Error retrieving reservation history:', err);
//                 return res.status(500).json('Database error');
//             }

//             if (historyResults.length === 0) {
//                 return res.status(404).json('No reservations found');
//             }

//             res.status(200).json(historyResults);
//         });
//     });
// });

// // Endpoint สำหรับการดูการจองทั้งหมด (เฉพาะ staff)
// app.get('/all-reservations', (req, res) => {
//     const sql = 'SELECT room_name, size, slot_1, slot_2, slot_3, slot_4 FROM room';
//     con.query(sql, (err, results) => {
//         if (err) {
//             console.error('Database error:', err);
//             return res.status(500).send('Database error');
//         }
//         res.json(results);
//     });
// });

// Endpoints profile
app.get('/profile', middleware, (req, res) => {
    const {user_id} = req.user;
    const sql = 'SELECT user_name, role FROM users WHERE user_id = ?';

    con.query(sql, [user_id], (err, results) => {
        if (err) {
            console.error('Error retrieving profile:', err);
            return res.status(500).json('Database error');
        }

        if (results.length === 0) {
            return res.status(401).json('User not found');
        } 

        res.status(200).json(results[0]);
    });
});

// app.get('/profile/:user_id', (req, res) => {
//     const userId = req.params.user_id;
//     const sql = 'SELECT user_name, role FROM users WHERE user_id = ?';

//     con.query(sql, [userId], (err, results) => {
//         if (err) {
//             console.error('Error retrieving profile:', err);
//             return res.status(500).json('Database error');
//         }

//         if (results.length === 0) {
//             return res.status(404).json('User not found');
//         }

//         res.status(200).json(results[0]);
//     });
// });

//dashboard

app.get('/dashboard', (req, res) => {
    const sql = `
        SELECT 
            COUNT(DISTINCT room_id) AS totalRooms,
            SUM(
                IF(slot_1 = 'free', 1, 0) + 
                IF(slot_2 = 'free', 1, 0) + 
                IF(slot_3 = 'free', 1, 0) + 
                IF(slot_4 = 'free', 1, 0)
            ) AS freeSlots,
            SUM(
                IF(slot_1 = 'reserve', 1, 0) + 
                IF(slot_2 = 'reserve', 1, 0) + 
                IF(slot_3 = 'reserve', 1, 0) + 
                IF(slot_4 = 'reserve', 1, 0)
            ) AS reservedSlots,
            SUM(
                IF(slot_1 = 'pending', 1, 0) + 
                IF(slot_2 = 'pending', 1, 0) + 
                IF(slot_3 = 'pending', 1, 0) + 
                IF(slot_4 = 'pending', 1, 0)
            ) AS pendingSlots,
            SUM(
                IF(slot_1 = 'disable', 1, 0) + 
                IF(slot_2 = 'disable', 1, 0) + 
                IF(slot_3 = 'disable', 1, 0) + 
                IF(slot_4 = 'disable', 1, 0)
            ) AS disabledSlots,
            COUNT(room_id) * 4 AS totalSlots
        FROM room;
    `;

    con.query(sql, (err, results) => {
        if (err) {
            console.error('Error retrieving data:', err);
            return res.status(500).json('Database query error');
        }

        if (results.length === 0 || !results[0].totalRooms) {
            return res.status(401).json('No data found');
        }

        const dashboard = {
            totalRoom: results[0].totalRooms,
            totalSlot: results[0].totalSlots,
            freeSlot: results[0].freeSlots,
            pendingRequest: results[0].pendingSlots,
            reservedSlot: results[0].reservedSlots,
            disableSlot: results[0].disabledSlots
        };

        res.status(200).json(dashboard);
    });
});

// Endpoint: /search - ค้นหาประวัติ
app.post('/search', (req, res) => {
    const { user_id, room_id, status } = req.body; // รับ user_id, room_id และ status

    // ตรวจสอบว่า user_id, room_id, status มีค่าหรือไม่
    if (!user_id || !room_id || !status) {
        return res.status(400).send('user_id, room_id, and status are required');
    }

    // คำสั่ง SQL เพื่อค้นหาข้อมูลจากตาราง information โดยใช้ user_id, room_id, และ status
    const sql = 'SELECT * FROM information WHERE user_id = ? AND room_id = ? AND status = ?';

    con.query(sql, [user_id, room_id, status], (err, results) => {
        if (err) {
            console.error('Database error:', err);
            return res.status(500).send('Server error');
        }

        if (results.length === 0) {
            return res.status(401).send('No matching records found.');
        }
        // ถ้าพบข้อมูล ก็ส่งผลลัพธ์กลับไป
        res.status(200).json(results);
    });
});

// // DELETE: ลบข้อมูลในตาราง information
// app.delete('/information/:id', (req, res) => {
//     const { id } = req.params;
//     const sql = 'DELETE FROM information WHERE id = ?';
//     con.query(sql, [id], (err, results) => {
//         if (err) {
//             console.error('Error executing query:', err);
//             return res.status(500).json({ error: err.message });
//         }
//         if (results.affectedRows === 0) return res.status(404).json({ message: 'Information not found' });
//         res.json({ message: 'Information deleted successfully' });
//     });
// });

// Start the server
const PORT = 5554;
app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});