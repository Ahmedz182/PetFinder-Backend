-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS pets;
USE pets;

-- Create Users table
CREATE TABLE IF NOT EXISTS Users (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    Username VARCHAR(50) NOT NULL UNIQUE,
    Password VARCHAR(255) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    UserType VARCHAR(10) NOT NULL CHECK (UserType IN ('Admin', 'Customer', 'Vendor')),
    MobileNo VARCHAR(255),
    Address VARCHAR(255),
    imgUrl VARCHAR(255)
);

-- Create Customers table
CREATE TABLE IF NOT EXISTS Customers (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT UNIQUE,
    CustomerName VARCHAR(100),
    Email VARCHAR(100),
    Password VARCHAR(255),
    ContactInformation VARCHAR(255),
    Address VARCHAR(255),
    PaymentDetails VARCHAR(255),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- Create Vendors table (VendorID is the same as UserID)
CREATE TABLE IF NOT EXISTS Vendors (
    VendorID INT PRIMARY KEY,
    UserID INT UNIQUE,
    VendorName VARCHAR(100),
    ContactInformation VARCHAR(255),
    Address VARCHAR(255),
    imgUrl VARCHAR(255),
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- Create Categories table
CREATE TABLE IF NOT EXISTS Categories (
    CategoryID INT AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(50) NOT NULL UNIQUE
);

-- Create Pets table
CREATE TABLE IF NOT EXISTS Pets (
    PetID INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(50),
    Age INT,
    Breed VARCHAR(50),
    Size VARCHAR(20),
    Color VARCHAR(20),
    EnergyLevel VARCHAR(10) NOT NULL CHECK (EnergyLevel IN ('Low', 'Medium', 'High')),
    Friendliness VARCHAR(10) NOT NULL CHECK (Friendliness IN ('Low', 'Medium', 'High')),
    EaseOfTraining VARCHAR(10) NOT NULL CHECK (EaseOfTraining IN ('Easy', 'Moderate', 'Difficult')),
    Status VARCHAR(20) NOT NULL DEFAULT 'Available' CHECK (Status IN ('Available', 'Booked', 'Not Available')),
    Price DECIMAL(10, 2),
    UserID INT,
    imgUrl VARCHAR(255),
    CategoryName VARCHAR(50),
    Location VARCHAR(255),
    PaymentStatus VARCHAR(10) NOT NULL DEFAULT 'N/A' CHECK (PaymentStatus IN ('N/A', 'Pending', 'Completed')),
    DeliveryStatus VARCHAR(10) NOT NULL DEFAULT 'N/A' CHECK (DeliveryStatus IN ('N/A', 'Pending', 'Delivered')),
    FOREIGN KEY (UserID) REFERENCES Vendors(UserID),
    FOREIGN KEY (CategoryName) REFERENCES Categories(CategoryName)
);

-- Create AdoptionBookings table
CREATE TABLE IF NOT EXISTS AdoptionBookings (
    BookingID INT AUTO_INCREMENT PRIMARY KEY,
    UserID INT,
    PetID INT,
    BookingDate DATETIME,
    PaymentStatus VARCHAR(10) NOT NULL CHECK (PaymentStatus IN ('Pending', 'Completed')),
    DeliveryStatus VARCHAR(10) NOT NULL CHECK (DeliveryStatus IN ('Pending', 'Delivered')),
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (PetID) REFERENCES Pets(PetID)
);

-- Create PetStatusChangeLog table
CREATE TABLE IF NOT EXISTS PetStatusChangeLog (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    PetID INT,
    PreviousStatus VARCHAR(10) NOT NULL CHECK (PreviousStatus IN ('Available', 'Booked', 'Not Available')),
    NewStatus VARCHAR(20) NOT NULL CHECK (NewStatus IN ('Available', 'Booked', 'Not Available')),
    ChangeDate DATETIME,
    ChangedBy INT,
    FOREIGN KEY (PetID) REFERENCES Pets(PetID),
    FOREIGN KEY (ChangedBy) REFERENCES Users(UserID)
);

-- Drop trigger if it already exists
DROP TRIGGER IF EXISTS after_user_insert;

-- Trigger to automatically add a vendor entry when a vendor user is added
DELIMITER $$

CREATE TRIGGER after_user_insert
AFTER INSERT ON Users
FOR EACH ROW
BEGIN
    -- Check if the new user is a Vendor
    IF NEW.UserType = 'Vendor' THEN
        INSERT INTO Vendors (VendorID, UserID, VendorName, ContactInformation, Address, imgUrl)
        VALUES (NEW.UserID, NEW.UserID, 'Default Vendor Name', 'Default Contact Info', NEW.Address, NEW.imgUrl);
    END IF;
    IF NEW.UserType = 'Admin' THEN
        INSERT INTO Vendors (VendorID, UserID, VendorName, ContactInformation, Address, imgUrl)
        VALUES (NEW.UserID, NEW.UserID, 'Admin', 'Admin Contact', NEW.Address, NEW.imgUrl);
    END IF;
END$$

DELIMITER ;

-- Drop trigger if it already exists for pet status update
DROP TRIGGER IF EXISTS before_pet_status_update;

-- Trigger to update PaymentStatus and DeliveryStatus based on Status changes
DELIMITER $$

CREATE TRIGGER before_pet_status_update
BEFORE UPDATE ON Pets
FOR EACH ROW
BEGIN
    -- If the pet's status is updated to 'Booked', update PaymentStatus and DeliveryStatus to 'Pending'
    IF NEW.Status = 'Booked' THEN
        SET NEW.PaymentStatus = 'Pending';
        SET NEW.DeliveryStatus = 'Pending';
    END IF;

    -- If the status changes from 'Booked' to 'Not Available', set PaymentStatus to 'Completed' and DeliveryStatus to 'Delivered'
    IF OLD.Status = 'Booked' AND NEW.Status = 'Not Available' THEN
        SET NEW.PaymentStatus = 'Completed';
        SET NEW.DeliveryStatus = 'Delivered';
    END IF;
END$$

DELIMITER ;

-- Drop the event if it exists
DROP EVENT IF EXISTS reset_pet_status_event;

-- Event to reset pet status and update PaymentStatus/DeliveryStatus after 3 hours if PaymentStatus remains 'Pending'
DELIMITER $$

CREATE EVENT reset_pet_status_event
ON SCHEDULE EVERY 3 HOUR
DO
BEGIN
    -- Update pets with pending payment after 3 hours
    UPDATE Pets
    SET Status = 'Available', 
        PaymentStatus = 'N/A',
        DeliveryStatus = 'N/A'
    WHERE PetID IN (
        SELECT PetID 
        FROM AdoptionBookings 
        WHERE PaymentStatus = 'Pending' 
        AND BookingDate <= NOW() - INTERVAL 3 HOUR
    );
END$$

DELIMITER ;

-- Insert sample data into Users table
INSERT INTO Users (Username, Password, Email, UserType, MobileNo, Address, imgUrl) 
VALUES 
('admin', '1221', 'i@i.com', 'Admin', '111-111-1111', 'Admin Address', 'http://example.com/admin.jpg'),
('vendor1', 'hashed_password_vendor1', 'vendor1@example.com', 'Vendor', '111-222-3333', '101 Shelter Rd', 'http://example.com/vendor1.jpg'),
('customer1', 'hashed_password_customer1', 'customer1@example.com', 'Customer', '098-765-4321', '456 Customer Ave', 'http://example.com/customer1.jpg'),
('vendor2', 'hashed_password', 'vendofrg10g1@example.com', 'Vendor', '123-456-7890', '123 New St', 'http://example.com/customer2.jpg');

-- Insert sample data into Vendors table
-- This will automatically insert during the User insert due to the trigger

-- Insert sample data into Categories table
INSERT INTO Categories (CategoryName) 
VALUES ('Dog'), ('Cat'), ('Bird');

-- Insert sample data into Pets table
INSERT INTO Pets (Name, Age, Breed, Size, Color, EnergyLevel, Friendliness, EaseOfTraining, Status, Price, UserID, imgUrl, CategoryName, Location) 
VALUES 
('Buddy', 2, 'Golden Retriever', 'Large', 'Golden', 'High', 'High', 'Easy', 'Available', 500.00, 3, 'http://example.com/buddy.jpg', 'Dog', 'New York');

-- Insert sample data into AdoptionBookings table
INSERT INTO AdoptionBookings (UserID, PetID, BookingDate, PaymentStatus, DeliveryStatus) 
VALUES 
(2, 1, '2024-10-16 10:00:00', 'Pending', 'Pending');

-- Insert sample data into PetStatusChangeLog table
INSERT INTO PetStatusChangeLog (PetID, PreviousStatus, NewStatus, ChangeDate, ChangedBy) 
VALUES 
(1, 'Available', 'Booked', NOW(), 2);

-- Fetch all pets and their status
SELECT * FROM Pets;

-- Fetch all bookings with user and pet details
SELECT AdoptionBookings.*, Users.Username, Pets.Name AS PetName, Pets.CategoryName
FROM AdoptionBookings
JOIN Users ON AdoptionBookings.UserID = Users.UserID
JOIN Pets ON AdoptionBookings.PetID = Pets.PetID;

-- Fetch all vendors
SELECT * FROM Vendors;
