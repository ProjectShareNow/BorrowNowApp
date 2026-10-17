const fs = require('fs');
const path = require('path');
const os = require('os');
const https = require('https');

// 1. Retrieve access token from Firebase Tools configuration
function getAccessToken() {
  const configPath = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  if (!fs.existsSync(configPath)) {
    throw new Error('firebase-tools config not found at ' + configPath);
  }
  const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const token = config.tokens?.access_token;
  if (!token) {
    throw new Error('No access_token found in firebase-tools.json');
  }
  return token;
}

// 2. Convert standard JS values to Firestore REST API typed values
function toFirestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (typeof val === 'number') {
    if (Number.isInteger(val)) return { integerValue: val.toString() };
    return { doubleValue: val };
  }
  if (typeof val === 'string') {
    if (/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/.test(val)) return { timestampValue: val };
    return { stringValue: val };
  }
  if (val instanceof Date) return { timestampValue: val.toISOString() };
  if (Array.isArray(val)) return { arrayValue: { values: val.map(toFirestoreValue) } };
  if (typeof val === 'object') return { mapValue: { fields: toFirestoreFields(val) } };
  return { stringValue: String(val) };
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [key, value] of Object.entries(obj)) {
    if (value !== undefined) fields[key] = toFirestoreValue(value);
  }
  return fields;
}

// 3. Make REST API request to Firestore
function writeDocument(token, projectId, docPath, data) {
  return new Promise((resolve, reject) => {
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${docPath}`;
    const postData = JSON.stringify({ fields: toFirestoreFields(data) });

    const req = https.request(url, {
      method: 'PATCH',
      headers: {
        'Authorization': 'Bearer ' + token,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(body));
        } else {
          reject(new Error(`Failed to write ${docPath}: [${res.statusCode}] ${body}`));
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

const projectId = 'borrownow-585b5';

// Standard 28-character Firebase UIDs
const U_ARUN = 'Uc8oUAyM7CS7nwmpBGknLG5wcOq1';
const U_PRIYA = '0KrMYdYj5JWywNu6TYwGobcHO7X2';
const U_KAVYA = 'poq0JITxfMRZ3OTa61OQhxKccbv2';
const U_ADMIN = '0HZHzddi3sgIUXzD850L4C711I22';

// Standard 20-character Firestore Document IDs
const I_CALC = 'c7WkL0pQ4rT9vX2zA5bC';
const I_DRAFT = 'd8XmN1qR5sU0wY3aB6cD';
const I_COAT = 'e9YnO2rS6tV1xZ4bC7dE';
const I_ARDU = 'f0ZoP3sT7uW2yA5cD8eF';
const I_CHRG = 'g1ApQ4tU8vX3zB6dE9fG';

const R_CALC = 'h2BqR5uV9wY4aC7eF0gH';
const R_DRAFT = 'i3CrS6vW0xZ5bD8fG1hI';

const T_ARDU = 'j4DsT7wX1yA6cE9gH2iJ';
const T_COAT = 'k5EtU8xY2zB7dF0hI3jK';

const C_CHAT = 'l6FuV9yZ3aC8eG1iJ4kL';
const M_MSG1 = 'm7GvW0zA4bD9fH2jK5lM';
const M_MSG2 = 'n8HwX1aB5cE0gI3kL6mN';

const N_REQ = 'o9IxY2bC6dF1hJ4lM7nO';
const N_HAND = 'p0JyZ3cD7eG2iK5mN8oP';
const N_ITEM = 'q1KzA4dE8fH3jL6nO9pQ';

const RAT_1 = 'r2LaB5eF9gI4kM7oP0qR';
const RAT_2 = 's3MbC6fG0hJ5lN8pQ1rS';

const REP_1 = 't4NcD7gH1iK6mO9qR2sT';

const ANN_1 = 'u5OdE8hI2jL7nP0rS3tU';
const ANN_2 = 'v6PeF9iJ3kM8oQ1sT4uV';

const LOG_1 = 'w7QfG0jK4lN9pR2tU5vW';
const LOG_2 = 'x8RhH1kL5mO0qS3uV6wX';

const users = [
  {
    _id: U_ADMIN,
    uid: U_ADMIN,
    fullName: 'Campus Admin - Student Affairs',
    name: 'Campus Administrator',
    email: 'admin@college.edu',
    collegeName: 'National Institute of Technology',
    department: 'Student Affairs & Administration',
    academicYear: 'Faculty',
    registerNumber: 'FAC-SA-01',
    idCardImageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
    role: 'admin',
    verificationStatus: 'verified',
    isActive: true,
    rating: 5.0,
    ratingCount: 50,
    completedBorrows: 0,
    completedLends: 0,
    fcmToken: 'fcm_token_admin_001',
    createdAt: '2026-01-01T08:00:00.000Z',
    updatedAt: '2026-09-30T08:00:00.000Z'
  }
];

const items = [
  {
    _id: I_CALC,
    id: I_CALC,
    itemId: I_CALC,
    title: 'Casio fx-991EX ClassWiz Scientific Calculator',
    name: 'Casio fx-991EX ClassWiz Scientific Calculator',
    description: 'High-resolution scientific calculator ideal for Engineering Mathematics and Physics exams. Clean condition with protective cover.',
    category: 'Electronics',
    condition: 'Excellent',
    images: ['https://images.unsplash.com/photo-1587145820266-a5951ee6f620?w=600'],
    ownerId: U_ARUN,
    ownerName: 'Arun Kumar',
    ownerDepartment: 'Computer Science & Engineering',
    ownerRating: 4.9,
    status: 'available',
    isAvailable: true,
    pickupLocation: 'Central Library / CSE Block Floor 2',
    maxBorrowDurationDays: 3,
    rules: 'Handle with care. Return with hard slide case intact.',
    createdAt: '2026-09-01T10:00:00.000Z',
    updatedAt: '2026-09-30T12:00:00.000Z'
  },
  {
    _id: I_DRAFT,
    id: I_DRAFT,
    itemId: I_DRAFT,
    title: 'Omega Professional Mini Drafter with Sheet Clips',
    name: 'Omega Professional Mini Drafter with Sheet Clips',
    description: 'Stainless steel rods with 360-degree protractor head. Essential for Engineering Graphics and Machine Drawing practicals.',
    category: 'Stationery',
    condition: 'Good',
    images: ['https://images.unsplash.com/photo-1581291518857-4e27b48ff24e?w=600'],
    ownerId: U_KAVYA,
    ownerName: 'Kavya Sundaram',
    ownerDepartment: 'Mechanical Engineering',
    ownerRating: 5.0,
    status: 'available',
    isAvailable: true,
    pickupLocation: 'Mechanical Engineering Block / Workshop Area',
    maxBorrowDurationDays: 5,
    rules: 'Do not overtighten clamping knob. Keep protractor clean.',
    createdAt: '2026-09-05T14:30:00.000Z',
    updatedAt: '2026-09-28T15:00:00.000Z'
  },
  {
    _id: I_COAT,
    id: I_COAT,
    itemId: I_COAT,
    title: 'White Cotton Chemistry Lab Coat (Size L)',
    name: 'White Cotton Chemistry Lab Coat (Size L)',
    description: '100% pure cotton lab coat with deep side pockets. Laundered and pressed, compliant with college Chemistry & Bio labs safety.',
    category: 'Lab Equipment',
    condition: 'Good',
    images: ['https://images.unsplash.com/photo-1584467735871-8e85353a8413?w=600'],
    ownerId: U_PRIYA,
    ownerName: 'Priya Sharma',
    ownerDepartment: 'Electronics & Communication',
    ownerRating: 4.8,
    status: 'available',
    isAvailable: true,
    pickupLocation: 'Science Block / Ground Floor Chemistry Lab Entrance',
    maxBorrowDurationDays: 2,
    rules: 'Return washed and folded neatly.',
    createdAt: '2026-09-10T09:15:00.000Z',
    updatedAt: '2026-09-29T10:00:00.000Z'
  },
  {
    _id: I_ARDU,
    id: I_ARDU,
    itemId: I_ARDU,
    title: 'Arduino Uno Starter Kit with Sensors & Jumper Wires',
    name: 'Arduino Uno Starter Kit with Sensors & Jumper Wires',
    description: 'Genuine Arduino Uno R3 with breadboard, ultrasonic sensor, IR module, servo motor, and complete jumper wire set.',
    category: 'Electronics',
    condition: 'Like New',
    images: ['https://images.unsplash.com/photo-1553406830-ef2513450d76?w=600'],
    ownerId: U_ARUN,
    ownerName: 'Arun Kumar',
    ownerDepartment: 'Computer Science & Engineering',
    ownerRating: 4.9,
    status: 'borrowed',
    isAvailable: false,
    pickupLocation: 'CSE Dept - Hardware Lab Room 204',
    maxBorrowDurationDays: 7,
    rules: 'Double-check polarity before powering sensors.',
    createdAt: '2026-09-12T16:00:00.000Z',
    updatedAt: '2026-09-30T11:00:00.000Z'
  },
  {
    _id: I_CHRG,
    id: I_CHRG,
    itemId: I_CHRG,
    title: '65W USB-C GaN Fast Laptop & Mobile Charger',
    name: '65W USB-C GaN Fast Laptop & Mobile Charger',
    description: 'Multi-port GaN power adapter with 2m braided cable. Compatible with Dell, HP, Lenovo ThinkPad, MacBook, and Android devices.',
    category: 'Electronics',
    condition: 'Excellent',
    images: ['https://images.unsplash.com/photo-1583863788434-e58a36330cf0?w=600'],
    ownerId: U_PRIYA,
    ownerName: 'Priya Sharma',
    ownerDepartment: 'Electronics & Communication',
    ownerRating: 4.8,
    status: 'available',
    isAvailable: true,
    pickupLocation: 'Girls Hostel 2 Security Desk / ECE Dept',
    maxBorrowDurationDays: 2,
    rules: 'Return with cable clip properly fastened.',
    createdAt: '2026-09-15T11:00:00.000Z',
    updatedAt: '2026-09-29T16:00:00.000Z'
  }
];

const borrowRequests = [
  {
    _id: R_CALC,
    id: R_CALC,
    requestId: R_CALC,
    itemId: I_CALC,
    itemName: 'Casio fx-991EX ClassWiz Scientific Calculator',
    itemPhotoUrl: 'https://images.unsplash.com/photo-1587145820266-a5951ee6f620?w=600',
    ownerId: U_ARUN,
    ownerName: 'Arun Kumar',
    borrowerId: U_PRIYA,
    borrowerName: 'Priya Sharma',
    borrowerDepartment: 'Electronics & Communication',
    borrowerPhotoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
    borrowerRating: 4.8,
    status: 'pending',
    requiredDate: '2026-10-02T09:00:00.000Z',
    requiredTime: '09:00 AM',
    duration: '2 days',
    pickupLocation: 'Central Library / CSE Block Floor 2',
    message: 'Need calculator for Friday semester internal exam in Signals & Systems. Will return right after!',
    createdAt: '2026-09-30T14:20:00.000Z',
    updatedAt: '2026-09-30T14:20:00.000Z'
  },
  {
    _id: R_DRAFT,
    id: R_DRAFT,
    requestId: R_DRAFT,
    itemId: I_DRAFT,
    itemName: 'Omega Professional Mini Drafter with Sheet Clips',
    itemPhotoUrl: 'https://images.unsplash.com/photo-1581291518857-4e27b48ff24e?w=600',
    ownerId: U_KAVYA,
    ownerName: 'Kavya Sundaram',
    borrowerId: U_ARUN,
    borrowerName: 'Arun Kumar',
    borrowerDepartment: 'Computer Science & Engineering',
    borrowerPhotoUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=400',
    borrowerRating: 4.9,
    status: 'approved',
    requiredDate: '2026-10-01T10:00:00.000Z',
    requiredTime: '10:00 AM',
    duration: '3 days',
    pickupLocation: 'Mechanical Engineering Block / Workshop Area',
    message: 'Need for CAD drafting assignment submission.',
    createdAt: '2026-09-29T16:00:00.000Z',
    updatedAt: '2026-09-30T09:00:00.000Z'
  }
];

const transactions = [
  {
    _id: T_ARDU,
    id: T_ARDU,
    transactionId: T_ARDU,
    requestId: R_CALC,
    itemId: I_ARDU,
    itemName: 'Arduino Uno Starter Kit with Sensors & Jumper Wires',
    itemPhotoUrl: 'https://images.unsplash.com/photo-1553406830-ef2513450d76?w=600',
    ownerId: U_ARUN,
    ownerName: 'Arun Kumar',
    borrowerId: U_KAVYA,
    borrowerName: 'Kavya Sundaram',
    status: 'active',
    ownerHandoverConfirmed: true,
    borrowerHandoverConfirmed: true,
    handedOverAt: '2026-09-25T11:00:00.000Z',
    dueDate: '2026-10-02T11:00:00.000Z',
    isReturned: false,
    createdAt: '2026-09-25T10:30:00.000Z',
    updatedAt: '2026-09-25T11:00:00.000Z'
  },
  {
    _id: T_COAT,
    id: T_COAT,
    transactionId: T_COAT,
    requestId: R_DRAFT,
    itemId: I_COAT,
    itemName: 'White Cotton Chemistry Lab Coat (Size L)',
    itemPhotoUrl: 'https://images.unsplash.com/photo-1584467735871-8e85353a8413?w=600',
    ownerId: U_PRIYA,
    ownerName: 'Priya Sharma',
    borrowerId: U_ARUN,
    borrowerName: 'Arun Kumar',
    status: 'completed',
    ownerHandoverConfirmed: true,
    borrowerHandoverConfirmed: true,
    handedOverAt: '2026-09-20T09:00:00.000Z',
    returnedAt: '2026-09-22T17:00:00.000Z',
    dueDate: '2026-09-22T18:00:00.000Z',
    isReturned: true,
    createdAt: '2026-09-20T08:30:00.000Z',
    updatedAt: '2026-09-22T17:00:00.000Z'
  }
];

const chats = [
  {
    _id: C_CHAT,
    id: C_CHAT,
    chatId: C_CHAT,
    requestId: R_CALC,
    itemId: I_CALC,
    itemName: 'Casio fx-991EX ClassWiz Scientific Calculator',
    itemPhotoUrl: 'https://images.unsplash.com/photo-1587145820266-a5951ee6f620?w=600',
    ownerId: U_ARUN,
    ownerName: 'Arun Kumar',
    borrowerId: U_PRIYA,
    borrowerName: 'Priya Sharma',
    participants: [U_ARUN, U_PRIYA],
    lastMessage: 'Sure Priya, I will bring it to the library 2nd floor at 9 AM.',
    lastMessageTime: '2026-09-30T15:05:00.000Z',
    lastSenderId: U_ARUN,
    unreadCount: 0,
    createdAt: '2026-09-30T14:30:00.000Z',
    updatedAt: '2026-09-30T15:05:00.000Z'
  }
];

const chatMessages = [
  {
    _id: M_MSG1,
    chatId: C_CHAT,
    messageId: M_MSG1,
    senderId: U_PRIYA,
    senderName: 'Priya Sharma',
    text: 'Hi Arun! Could we meet near the library entrance for the calculator handover?',
    isRead: true,
    timestamp: '2026-09-30T14:45:00.000Z'
  },
  {
    _id: M_MSG2,
    chatId: C_CHAT,
    messageId: M_MSG2,
    senderId: U_ARUN,
    senderName: 'Arun Kumar',
    text: 'Sure Priya, I will bring it to the library 2nd floor at 9 AM.',
    isRead: true,
    timestamp: '2026-09-30T15:05:00.000Z'
  }
];

const notifications = [
  {
    _id: N_REQ,
    id: N_REQ,
    notificationId: N_REQ,
    recipientId: U_ARUN,
    senderId: U_PRIYA,
    senderName: 'Priya Sharma',
    type: 'request_received',
    title: 'New Borrow Request',
    message: 'Priya Sharma requested to borrow "Casio fx-991EX ClassWiz Scientific Calculator".',
    relatedId: R_CALC,
    isRead: false,
    createdAt: '2026-09-30T14:20:00.000Z'
  },
  {
    _id: N_HAND,
    id: N_HAND,
    notificationId: N_HAND,
    recipientId: U_PRIYA,
    senderId: U_ARUN,
    senderName: 'Arun Kumar',
    type: 'handover_ready',
    title: 'Item Ready for Handover! 🤝',
    message: 'Arun is waiting at Central Library for the Casio calculator handover.',
    relatedId: T_ARDU,
    isRead: true,
    createdAt: '2026-09-30T15:00:00.000Z'
  },
  {
    _id: N_ITEM,
    id: N_ITEM,
    notificationId: N_ITEM,
    recipientId: U_KAVYA,
    senderId: 'system',
    senderName: 'BorrowNow Campus',
    type: 'system',
    title: '🎉 Welcome to BorrowNow!',
    message: 'Your college student profile has been verified! Start borrowing and lending within your campus.',
    relatedId: I_ARDU,
    isRead: true,
    createdAt: '2026-09-28T09:00:00.000Z'
  }
];

const ratings = [
  {
    _id: RAT_1,
    id: RAT_1,
    ratingId: RAT_1,
    transactionId: T_ARDU,
    itemId: I_ARDU,
    fromUserId: U_KAVYA,
    fromUserName: 'Kavya Sundaram',
    toUserId: U_ARUN,
    toUserName: 'Arun Kumar',
    rating: 5.0,
    review: 'Kit was in pristine condition with all sensors neatly organized. Super helpful lender!',
    role: 'borrower_to_owner',
    createdAt: '2026-09-26T12:00:00.000Z'
  },
  {
    _id: RAT_2,
    id: RAT_2,
    ratingId: RAT_2,
    transactionId: T_COAT,
    itemId: I_COAT,
    fromUserId: U_PRIYA,
    fromUserName: 'Priya Sharma',
    toUserId: U_ARUN,
    toUserName: 'Arun Kumar',
    rating: 4.8,
    review: 'Returned punctually right on schedule. Would gladly lend to Arun again!',
    role: 'owner_to_borrower',
    createdAt: '2026-09-22T17:30:00.000Z'
  }
];

const reports = [
  {
    _id: REP_1,
    id: REP_1,
    reportId: REP_1,
    reporterId: U_KAVYA,
    reporterName: 'Kavya Sundaram',
    reportedUserId: 'O67sdFTrNUbS5HUNg8sxqrNpZDm1',
    reportedUserName: 'Karthik Raja',
    itemId: I_DRAFT,
    itemTitle: 'Omega Professional Mini Drafter with Sheet Clips',
    reason: 'Slight looseness in clamping screw upon inspection',
    details: 'The mini drafter clamp was loose when returned. Resolved with Allen wrench adjustment.',
    status: 'resolved',
    adminNotes: 'Resolved mutually between students without penalty.',
    createdAt: '2026-09-25T11:00:00.000Z',
    resolvedAt: '2026-09-26T14:00:00.000Z'
  }
];

const deviceTokens = [
  {
    _id: U_ARUN,
    userId: U_ARUN,
    token: 'fcm_token_arun_android_device_sample',
    deviceType: 'android',
    updatedAt: '2026-10-01T08:00:00.000Z'
  },
  {
    _id: U_PRIYA,
    userId: U_PRIYA,
    token: 'fcm_token_priya_android_device_sample',
    deviceType: 'android',
    updatedAt: '2026-10-01T08:15:00.000Z'
  }
];

const announcements = [
  {
    _id: ANN_1,
    announcementId: ANN_1,
    title: 'Mid-Semester Exam Equipment Sharing Drive',
    message: 'Engineering Mathematics and Physics practical exams commence next week. Please lend unused scientific calculators and drafting kits to juniors.',
    createdBy: U_ADMIN,
    createdByName: 'Campus Administrator',
    targetAudience: 'all',
    isActive: true,
    createdAt: '2026-09-28T10:00:00.000Z',
    updatedAt: '2026-09-28T10:00:00.000Z'
  },
  {
    _id: ANN_2,
    announcementId: ANN_2,
    title: 'IoT & Embedded Systems Lab Hardware Available',
    message: 'Arduino Mega 2560 and Raspberry Pi kits are available for final-year mini projects in Hostel 4 common hub.',
    createdBy: U_ADMIN,
    createdByName: 'Campus Administrator',
    targetAudience: 'department',
    department: 'Computer Science & Engineering',
    isActive: true,
    createdAt: '2026-09-29T14:00:00.000Z',
    updatedAt: '2026-09-29T14:00:00.000Z'
  }
];

const adminAuditLogs = [
  {
    _id: LOG_1,
    logId: LOG_1,
    adminUid: U_ADMIN,
    adminName: 'Campus Administrator',
    actionType: 'student_verification_approved',
    targetCollection: 'users',
    targetDocumentId: U_ARUN,
    reason: 'ID Card verified against college roster 2022CSE108',
    details: { studentName: 'Arun Kumar', registerNumber: '2022CSE108' },
    createdAt: '2026-09-20T10:30:00.000Z'
  },
  {
    _id: LOG_2,
    logId: LOG_2,
    adminUid: U_ADMIN,
    adminName: 'Campus Administrator',
    actionType: 'student_verification_approved',
    targetCollection: 'users',
    targetDocumentId: U_PRIYA,
    reason: 'ID Card photo and department details verified',
    details: { studentName: 'Priya Sharma', registerNumber: '2023ECE045' },
    createdAt: '2026-09-21T11:15:00.000Z'
  }
];

// 5. Execution Runner
async function runSeeder() {
  console.log('🚀 Starting Firebase Firestore Seeder for project: ' + projectId);
  const token = getAccessToken();

  const collections = [
    { name: 'users', data: users },
    { name: 'items', data: items },
    { name: 'borrow_requests', data: borrowRequests },
    { name: 'transactions', data: transactions },
    { name: 'chats', data: chats },
    { name: 'notifications', data: notifications },
    { name: 'ratings', data: ratings },
    { name: 'reports', data: reports },
    { name: 'device_tokens', data: deviceTokens },
    { name: 'announcements', data: announcements },
    { name: 'admin_audit_logs', data: adminAuditLogs }
  ];

  for (const col of collections) {
    console.log(`\n📂 Seeding collection [${col.name}] (${col.data.length} documents)...`);
    for (const doc of col.data) {
      const docId = doc._id;
      const cleanDoc = { ...doc };
      delete cleanDoc._id;
      try {
        await writeDocument(token, projectId, `${col.name}/${docId}`, cleanDoc);
        console.log(`  ✓ Written ${col.name}/${docId}`);
      } catch (err) {
        console.error(`  ✗ Error writing ${col.name}/${docId}:`, err.message);
      }
    }
  }

  // Seed Subcollection: chats/{chatId}/messages/{messageId}
  console.log('\n💬 Seeding subcollection [chats/.../messages]...');
  for (const msg of chatMessages) {
    const chatId = msg.chatId;
    const msgId = msg._id;
    const cleanMsg = { ...msg };
    delete cleanMsg.chatId;
    delete cleanMsg._id;
    try {
      await writeDocument(token, projectId, `chats/${chatId}/messages/${msgId}`, cleanMsg);
      console.log(`  ✓ Written chats/${chatId}/messages/${msgId}`);
    } catch (err) {
      console.error(`  ✗ Error writing message ${msgId}:`, err.message);
    }
  }

  console.log('\n======================================================');
  console.log('🎉 ALL 11 FIRESTORE COLLECTIONS SEEDED WITH NORMAL IDS!');
  console.log('Refresh your Firebase Console to see all collections:');
  console.log(`https://console.firebase.google.com/u/0/project/${projectId}/firestore/databases/-default-/data`);
  console.log('======================================================\n');
}

runSeeder().catch(err => {
  console.error('Fatal Seeder Error:', err);
  process.exit(1);
});
