CREATE DATABASE IF NOT EXISTS bonair_inn_db;
USE bonair_inn_db;

-- 1. User Roles Table
CREATE TABLE ROLES (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT NULL
) ENGINE=InnoDB;

-- 2. Staff Accounts Table
CREATE TABLE USERS (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    role_id INT NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_roles FOREIGN KEY (role_id) 
        REFERENCES ROLES(role_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 3. Staff Shift Logging Table
CREATE TABLE USER_SHIFT_LOGS (
    shift_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    shift_start TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    shift_end TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT fk_shift_users FOREIGN KEY (user_id) 
        REFERENCES USERS(user_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 4. Inn Global Settings Table
CREATE TABLE SYSTEM_SETTINGS (
    setting_id INT AUTO_INCREMENT PRIMARY KEY,
    setting_key VARCHAR(100) NOT NULL UNIQUE,
    setting_value VARCHAR(255) NOT NULL,
    updated_by_user_id INT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_settings_users FOREIGN KEY (updated_by_user_id) 
        REFERENCES USERS(user_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 5. Room Categories & Pricing Table
CREATE TABLE ROOM_TYPES (
    type_id INT AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL UNIQUE,
    base_rate DECIMAL(10, 2) NOT NULL,
    max_occupancy INT NOT NULL DEFAULT 2,
    description TEXT NULL
) ENGINE=InnoDB;

-- 6. Physical Rooms & Live Status Table
CREATE TABLE ROOMS (
    room_id INT AUTO_INCREMENT PRIMARY KEY,
    type_id INT NOT NULL,
    room_number VARCHAR(20) NOT NULL UNIQUE,
    floor_level VARCHAR(20) NOT NULL,
    current_status ENUM('Available', 'Reserved', 'Occupied', 'Cleaning', 'Under Maintenance') NOT NULL DEFAULT 'Available',
    is_ready BOOLEAN NOT NULL DEFAULT FALSE,
    last_cleaned_at TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT fk_rooms_types FOREIGN KEY (type_id) 
        REFERENCES ROOM_TYPES(type_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 7. Master Inclusions & Amenities Catalog Table
CREATE TABLE AMENITIES (
    amenity_id INT AUTO_INCREMENT PRIMARY KEY,
    amenity_name VARCHAR(50) NOT NULL UNIQUE,
    category VARCHAR(50) NOT NULL
) ENGINE=InnoDB;

-- 8. Room-Amenities Mapping Junction Table
CREATE TABLE ROOM_AMENITIES (
    room_id INT NOT NULL,
    amenity_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    PRIMARY KEY (room_id, amenity_id),
    CONSTRAINT fk_ra_rooms FOREIGN KEY (room_id) 
        REFERENCES ROOMS(room_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ra_amenities FOREIGN KEY (amenity_id) 
        REFERENCES AMENITIES(amenity_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 9. Housekeeping Work Orders Table
CREATE TABLE HOUSEKEEPING_TASKS (
    task_id INT AUTO_INCREMENT PRIMARY KEY,
    room_id INT NOT NULL,
    assigned_to_user_id INT NULL,
    task_type ENUM('Turnover Cleaning', 'Deep Cleaning', 'Routine Cleaning') NOT NULL DEFAULT 'Turnover Cleaning',
    priority ENUM('High', 'Medium', 'Low') NOT NULL DEFAULT 'Medium',
    task_status ENUM('Pending', 'In Progress', 'Completed') NOT NULL DEFAULT 'Pending',
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT fk_ht_rooms FOREIGN KEY (room_id) 
        REFERENCES ROOMS(room_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ht_users FOREIGN KEY (assigned_to_user_id) 
        REFERENCES USERS(user_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 10. Inspection Criteria Catalog Table
CREATE TABLE CHECKLIST_ITEMS (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    is_required BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- 11. Room Readiness Inspection Sessions Table
CREATE TABLE READINESS_INSPECTIONS (
    inspection_id INT AUTO_INCREMENT PRIMARY KEY,
    room_id INT NOT NULL,
    inspected_by_user_id INT NOT NULL,
    overall_result ENUM('Passed', 'Failed') NOT NULL,
    inspection_notes TEXT NULL,
    inspected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ri_rooms FOREIGN KEY (room_id) 
        REFERENCES ROOMS(room_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ri_users FOREIGN KEY (inspected_by_user_id) 
        REFERENCES USERS(user_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 12. Individual Checklist Results Table
CREATE TABLE INSPECTION_DETAILS (
    inspection_detail_id INT AUTO_INCREMENT PRIMARY KEY,
    inspection_id INT NOT NULL,
    item_id INT NOT NULL,
    is_passed BOOLEAN NOT NULL DEFAULT FALSE,
    remarks VARCHAR(255) NULL,
    CONSTRAINT fk_id_inspections FOREIGN KEY (inspection_id) 
        REFERENCES READINESS_INSPECTIONS(inspection_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_id_items FOREIGN KEY (item_id) 
        REFERENCES CHECKLIST_ITEMS(item_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 13. Room Repair & Maintenance Records Table
CREATE TABLE MAINTENANCE_RECORDS (
    maintenance_id INT AUTO_INCREMENT PRIMARY KEY,
    room_id INT NOT NULL,
    reported_by_user_id INT NOT NULL,
    resolved_by_user_id INT NULL,
    issue_category VARCHAR(50) NOT NULL,
    issue_description TEXT NOT NULL,
    maintenance_status ENUM('Pending', 'In Progress', 'Completed') NOT NULL DEFAULT 'Pending',
    start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completion_date TIMESTAMP NULL DEFAULT NULL,
    CONSTRAINT fk_mr_rooms FOREIGN KEY (room_id) 
        REFERENCES ROOMS(room_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_mr_reporter FOREIGN KEY (reported_by_user_id) 
        REFERENCES USERS(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_mr_resolver FOREIGN KEY (resolved_by_user_id) 
        REFERENCES USERS(user_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 14. Guest Demographics Table
CREATE TABLE GUESTS (
    guest_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    contact_number VARCHAR(20) NOT NULL,
    email VARCHAR(100) NULL,
    address VARCHAR(255) NULL,
    id_type VARCHAR(50) NULL,
    id_number VARCHAR(50) NULL
) ENGINE=InnoDB;

-- 15. Staff-Encoded Room Reservations Table
CREATE TABLE RESERVATIONS (
    reservation_id INT AUTO_INCREMENT PRIMARY KEY,
    guest_id INT NOT NULL,
    room_id INT NOT NULL,
    encoded_by_user_id INT NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    booking_status ENUM('Confirmed', 'Cancelled', 'Fulfilled') NOT NULL DEFAULT 'Confirmed',
    special_requests TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_res_guests FOREIGN KEY (guest_id) 
        REFERENCES GUESTS(guest_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_res_rooms FOREIGN KEY (room_id) 
        REFERENCES ROOMS(room_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_res_users FOREIGN KEY (encoded_by_user_id) 
        REFERENCES USERS(user_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 16. Active & Historical Stay Records Table
CREATE TABLE CHECK_IN_OUT (
    stay_id INT AUTO_INCREMENT PRIMARY KEY,
    reservation_id INT NULL,
    guest_id INT NOT NULL,
    room_id INT NOT NULL,
    processed_by_user_id INT NOT NULL,
    actual_check_in TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actual_check_out TIMESTAMP NULL DEFAULT NULL,
    number_of_guests INT NOT NULL DEFAULT 1,
    stay_status ENUM('Active', 'Checked-Out') NOT NULL DEFAULT 'Active',
    CONSTRAINT fk_stay_reservations FOREIGN KEY (reservation_id) 
        REFERENCES RESERVATIONS(reservation_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_stay_guests FOREIGN KEY (guest_id) 
        REFERENCES GUESTS(guest_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_stay_rooms FOREIGN KEY (room_id) 
        REFERENCES ROOMS(room_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_stay_users FOREIGN KEY (processed_by_user_id) 
        REFERENCES USERS(user_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 17. Additional Room Companions Table
CREATE TABLE GUEST_COMPANIONS (
    companion_id INT AUTO_INCREMENT PRIMARY KEY,
    stay_id INT NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    contact_number VARCHAR(20) NULL,
    id_type VARCHAR(50) NULL,
    id_number VARCHAR(50) NULL,
    relationship_to_primary VARCHAR(50) NOT NULL,
    CONSTRAINT fk_comp_stay FOREIGN KEY (stay_id) 
        REFERENCES CHECK_IN_OUT(stay_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 18. Stay Extensions Log Table
CREATE TABLE STAY_EXTENSIONS (
    extension_id INT AUTO_INCREMENT PRIMARY KEY,
    stay_id INT NOT NULL,
    approved_by_user_id INT NOT NULL,
    extra_hours INT NOT NULL DEFAULT 0,
    extra_days INT NOT NULL DEFAULT 0,
    additional_charge DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    reason TEXT NULL,
    extended_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ext_stay FOREIGN KEY (stay_id) 
        REFERENCES CHECK_IN_OUT(stay_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ext_users FOREIGN KEY (approved_by_user_id) 
        REFERENCES USERS(user_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 19. Payment Tender Types Lookup Table
CREATE TABLE PAYMENT_METHODS (
    method_id INT AUTO_INCREMENT PRIMARY KEY,
    method_name VARCHAR(50) NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- 20. Recorded Payment Amounts Table (No online gateway integration)
CREATE TABLE PAYMENTS (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    stay_id INT NOT NULL,
    recorded_by_user_id INT NOT NULL,
    method_id INT NOT NULL,
    amount_paid DECIMAL(10, 2) NOT NULL,
    payment_stage ENUM('Deposit', 'Partial', 'Full Payment') NOT NULL DEFAULT 'Full Payment',
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    remarks TEXT NULL,
    CONSTRAINT fk_pay_stay FOREIGN KEY (stay_id) 
        REFERENCES CHECK_IN_OUT(stay_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_pay_users FOREIGN KEY (recorded_by_user_id) 
        REFERENCES USERS(user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_pay_methods FOREIGN KEY (method_id) 
        REFERENCES PAYMENT_METHODS(method_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 21. Real-Time Dashboard Notifications Table
CREATE TABLE SYSTEM_NOTIFICATIONS (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    room_id INT NULL,
    notification_type ENUM('Unready Room Alert', 'Overdue Checkout', 'Pending Cleaning', 'Double Booking Attempt') NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_users FOREIGN KEY (user_id) 
        REFERENCES USERS(user_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_notif_rooms FOREIGN KEY (room_id) 
        REFERENCES ROOMS(room_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 22. Historical Room Status Audit Trail Table
CREATE TABLE ROOM_STATUS_LOGS (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    room_id INT NOT NULL,
    changed_by_user_id INT NOT NULL,
    previous_status VARCHAR(50) NOT NULL,
    new_status ENUM('Available', 'Reserved', 'Occupied', 'Cleaning', 'Under Maintenance') NOT NULL,
    is_ready_at_change BOOLEAN NOT NULL DEFAULT FALSE,
    logged_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_log_rooms FOREIGN KEY (room_id) 
        REFERENCES ROOMS(room_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_log_users FOREIGN KEY (changed_by_user_id) 
        REFERENCES USERS(user_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

INSERT INTO ROLES (role_id, role_name, description) VALUES
(1, 'Administrator', 'Full operational access, user account management, and report generation')[cite: 3, 5],
(2, 'Receptionist / Front Desk', 'Day-to-day reservations, room monitoring, check-in/out, and payment logging')[cite: 3, 5];

-- Payment Methods lookup
INSERT INTO PAYMENT_METHODS (method_id, method_name, is_active) VALUES
(1, 'Cash', TRUE),
(2, 'GCash', TRUE),
(3, 'Bank Transfer', TRUE);

-- Initial System Settings
INSERT INTO SYSTEM_SETTINGS (setting_id, setting_key, setting_value, updated_by_user_id) VALUES
(1, 'STANDARD_CHECKIN_TIME', '14:00', 1),
(2, 'STANDARD_CHECKOUT_TIME', '12:00', 1);