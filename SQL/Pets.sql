-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS if0_37723587_pets;
USE if0_37723587_pets;

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
VALUES ('Dog'), ('Cat'), ('Bird'),('Fish');

-- Insert sample data into Pets table
INSERT INTO Pets (Name, Age, Breed, Size, Color, EnergyLevel, Friendliness, EaseOfTraining, Status, Price, UserID, imgUrl, CategoryName, Location) 
VALUES 
('Buddy', 2, 'Golden Retriever', 'Large', 'Golden', 'High', 'High', 'Easy', 'Available', 500.00, 3, 'http://example.com/buddy.jpg', 'Dog', 'New York'),
('Leo', 2, 'Golden Retriever', 'Large', 'Golden', 'High', 'High', 'Easy', 'Not Available', 500.00, 1, 'http://example.com/buddy.jpg', 'Bird', 'New York', 'Completed', 'Delivered'),
('Ragdoll', 2, 'Ragdoll', 'Small', 'Cream and White', 'Medium', 'High', 'Easy', 'Available', 20000.00, 1, 'http://example.com/ragdoll.jpg', 'Cat', 'Lahore', 'N/A', 'N/A'),
( 'Shih Tzu', 3, 'Shih Tzu', 'Small', 'White and Brown', 'High', 'High', 'Easy', 'Available', 60000.00, 1, 'http://example.com/shih-tzu.jpg', 'Dog', 'Lahore', 'N/A', 'N/A'),
('German Shepherd', 2, 'German Shepherd', 'Large', 'Black and Tan', 'High', 'High', 'Easy', 'Available', 150000.00, 1, 'http://example.com/german-shepherd.jpg', 'Dog', 'Islamabad', 'N/A', 'N/A'),
( 'Labrador Retriever', 2, 'Labrador Retriever', 'Large', 'Yellow', 'High', 'High', 'Easy', 'Available', 50000.00, 1, 'http://example.com/labrador.jpg', 'Dog', 'Lahore', 'N/A', 'N/A'),
( 'Golden Retriever', 1, 'Golden Retriever', 'Medium-Large', 'Golden', 'High', 'High', 'Moderate', 'Available', 105000.00, 1, 'http://example.com/golden-retriever.jpg', 'Dog', 'DHA Defence, KRC', 'N/A', 'N/A'),
( 'Siberian Husky', 2, 'Siberian Husky', 'Medium', 'Black and White', 'High', 'High', 'Easy', 'Available', 65000.00, 1, 'http://example.com/husky.jpg', 'Dog', 'Lahore', 'N/A', 'N/A'),
( 'Beagle', 1, 'Beagle', 'Medium', 'Tricolor', 'Medium', 'High', 'Easy', 'Available', 10000.00, 1, 'http://example.com/beagle.jpg', 'Dog', 'DHA Defence, KRC', 'N/A', 'N/A'),
( 'Alaskan Malamute', 2, 'Alaskan Malamute', 'Large', 'Gray and White', 'High', 'High', 'Easy', 'Available', 77000.00, 1, 'http://example.com/malamute.jpg', 'Dog', 'Multan', 'N/A', 'N/A'),
( 'Australian Cattle Dog', 2, 'Australian Cattle Dog', 'Medium', 'Blue', 'High', 'High', 'Easy', 'Available', 65000.00, 1, 'http://example.com/cattle-dog.jpg', 'Dog', 'Lahore', 'N/A', 'N/A'),
( 'Rottweiler', 1, 'Rottweiler', 'Large', 'Black and Tan', 'High', 'High', 'Easy', 'Available', 70000.00, 1, 'http://example.com/rottweiler.jpg', 'Dog', 'Islamabad', 'N/A', 'N/A'),
( 'Border Collie', 2, 'Border Collie', 'Medium', 'Black and White', 'Medium', 'High', 'Easy', 'Available', 75000.00, 1, 'http://example.com/collie.jpg', 'Dog', 'Karachi', 'N/A', 'N/A'),
( 'Maine Coon', 1, 'Maine Coon', 'Small', 'Brown Tabby', 'Low', 'High', 'Easy', 'Available', 55000.00, 1, 'http://example.com/mainecoon.jpg', 'Cat', 'Islamabad', 'N/A', 'N/A'),
( 'Persian Cat', 1, 'Persian Cat', 'Small', 'White', 'Low', 'High', 'Easy', 'Available', 23000.00, 1, 'http://example.com/persian.jpg', 'Cat', 'Multan', 'N/A', 'N/A'),
( 'Siamese Cat', 2, 'Siamese Cat', 'Small', 'Seal Point', 'Medium', 'High', 'Easy', 'Available', 20000.00, 1, 'http://example.com/siamese.jpg', 'Cat', 'Lahore', 'N/A', 'N/A'),
( 'British Shorthair', 2, 'British Shorthair', 'Small', 'Blue-Grey', 'Low', 'High', 'Easy', 'Available', 230000.00, 1, 'http://example.com/britishshorthair.jpg', 'Cat', 'Islamabad', 'N/A', 'N/A'),
( 'Sphynx Cats', 2, 'Sphynx', 'Small', 'Pinkish Beige', 'Low', 'High', 'Easy', 'Available', 155000.00, 1, 'http://example.com/sphynx.jpg', 'Cat', 'Lahore', 'N/A', 'N/A'),
( 'Scottish Fold', 2, 'Scottish Fold', 'Small', 'Grey and White', 'Low', 'High', 'Easy', 'Available', 200000.00, 1, 'http://example.com/scottishfold.jpg', 'Cat', 'Islamabad', 'N/A', 'N/A'),
( 'Devon Rex', 2, 'Devon Rex', 'Small', 'Brown and White', 'Low', 'High', 'Easy', 'Available', 25000.00, 1, 'http://example.com/devonrex.jpg', 'Cat', 'Lahore', 'N/A', 'N/A'),
( 'American Shorthair', 1, 'American Shorthair', 'Small', 'Silver Tabby', 'Medium', 'High', 'Easy', 'Available', 20000.00, 1, 'http://example.com/americanshorthair.jpg', 'Cat', 'Islamabad', 'N/A', 'N/A'),
( 'Abyssinian', 1, 'Abyssinian', 'Small', 'Ruddy', 'Low', 'High', 'Easy', 'Available', 55000.00, 1, 'http://example.com/abyssinian.jpg', 'Cat', 'Lahore', 'N/A', 'N/A'),
( 'Birman', 2, 'Birman', 'Small', 'Cream and Brown', 'Medium', 'High', 'Easy', 'Available', 55000.00, 1, 'http://example.com/birman.jpg', 'Cat', 'Islamabad', 'N/A', 'N/A'),
( 'Bella', 1, 'Ragdoll', 'Small', 'White', 'Medium', 'High', 'Easy', 'Available', 20000.00, 1, 'https://cfa.org/wp-content/uploads/2024/06/2024-c23c-ZeusRagdollXiaoYao-1024x768.webp', 'Cat', 'Lahore', 'Completed', 'Delivered'),
( 'Daisy', 1, 'Maine Coon', 'Small', 'Brown', 'Low', 'High', 'Easy', 'Available', 55000.00, 1, '/images?q=tbn:ANd9GcS4aFE-r1XOKSEODggVC2pybTKBlUzLyo4rMA&s', 'Cat', 'Islamabad', 'N/A', 'N/A'),
( 'Casper', 1, 'Persian', 'Small', 'Gray', 'Medium', 'High', 'Easy', 'Available', 23000.00, 1, 'https://pangovet.com/wp-content/uploads/2024/06/persian-cat-in-grass_Cattrall-shutterstock-e1666280664132.jpg', 'Cat', 'Multan', 'N/A', 'N/A'),
( 'Alice', 2, 'Siamese', 'Small', 'White', 'Medium', 'High', 'Easy', 'Available', 20000.00, 1, '/images?q=tbn:ANd9GcS4aFE-r1XOKSEODggVC2pybTKBlUzLyo4rMA&s', 'Cat', 'Lahore', 'Completed', 'Delivered'),
( 'Alice', 2, 'Siamese', 'Small', 'White', 'Medium', 'High', 'Easy', 'Available', 20000.00, 1, '/images?q=tbn:ANd9GcS4aFE-r1XOKSEODggVC2pybTKBlUzLyo4rMA&s', 'Cat', 'Lahore', 'Completed', 'Delivered'),
('Toby', 7, 'Goldfish', 'Medium', 'Orange', 'High', 'High', 'Moderate', 'Available', 56000.00, 1, '/images?q=tbn:ANd9GcT0BO-hL7NYusHi9M3v6l_vJh9zbeemjbKksg&s', 'Fish', 'City', 'N/A', 'N/A'),
( 'Penny', 9, 'Cichlid', 'Medium', 'Blue', 'Medium', 'High', 'Moderate', 'Available', 58000.00, 1, '/images?q=tbn:ANd9GcRUlslt2BQxGv66D57_6WZQFL1wZjA0Yc5kJw&s', 'Fish', 'Town', 'N/A', 'N/A'),
( 'Dory', 10, 'Discus', 'Large', 'Colorful', 'High', 'Medium', 'Easy', 'Available', 59000.00, 1, '/images?q=tbn:ANd9GcQhRdfnVskQsh9RYKkBsZxezgp-ppLw1RlLyg&s', 'Fish', 'City', 'Completed', 'Delivered'),
( 'Penny', 9, 'Cichlid', 'Medium', 'Orange/Blue', 'Medium', 'High', 'Moderate', 'Available', 58000.00, 1, '/images?q=tbn:ANd9GcRUlslt2BQxGv66D57_6WZQFL1wZjA0Yc5kJw&s', 'Fish', 'Town', 'N/A', 'N/A'),
( 'Bubbles', 1, 'Discus', 'Small', 'Colorful', 'Medium', 'High', 'Easy', 'Available', 50000.00, 1, '/images?q=tbn:ANd9GcQI8IueCVQ0YZlFMkDvmRuwg6Qt_VJlrdw-Tw&s', 'Fish', 'Town', 'N/A', 'N/A'),
( 'Marley', 2, 'Goldfish', 'Small', 'Orange', 'High', 'High', 'Moderate', 'Available', 51000.00, 1, '/images?q=tbn:ANd9GcTbLfUQ31JMi3TeW0LOkz1zq4Qh2Y7htMFpVg&s', 'Fish', 'City', 'Completed', 'Delivered'),
( 'Cleo', 3, 'Clownfish', 'Small', 'Orange/White', 'Medium', 'High', 'Easy', 'Available', 52000.00, 1, '/images?q=tbn:ANd9GcTXYFLkFkv5x0FdItjA9flgaBeMJvFCyRRJ0w&s', 'Fish', 'Town', 'N/A', 'N/A'),
( 'Ziggy', 4, 'Neon Tetra', 'Small', 'Blue/Red', 'Medium', 'High', 'Moderate', 'Available', 53000.00, 1, '/images?q=tbn:ANd9GcRSN6l7RITD3P76v_hoNe6oMBpWB3g_9drFGw&s', 'Fish', 'City', 'Completed', 'Delivered'),
( 'Lucky', 5, 'Angelfish', 'Small', 'Silver', 'Medium', 'High', 'Easy', 'Available', 54000.00, 1, '/images?q=tbn:ANd9GcSv5LFG_-IbV9iN8t50vQp7e5_xwIduJABv1Q&s', 'Fish', 'Town', 'N/A', 'N/A'),
( 'Zara', 6, 'Betta', 'Small', 'Red/Blue', 'High', 'Medium', 'Easy', 'Available', 55000.00, 1, '/images?q=tbn:ANd9GcTlG7NY9ptjOCEQfJ5y7qdANZRVJ5f_RBcxOw&s', 'Fish', 'Town', 'Completed', 'Delivered'),
( 'Sasha', 8, 'Rainbow Fish', 'Small', 'Colorful', 'Medium', 'High', 'Moderate', 'Available', 57000.00, 1, '/images?q=tbn:ANd9GcQNZXhyQKZq3AXvhlL4RYT-GJqEGoTHjcy9zQ&s', 'Fish', 'Town', 'Completed', 'Delivered'),
( 'Penny', 9, 'Cichlid', 'Medium', 'Orange/Blue', 'Medium', 'High', 'Moderate', 'Available', 58000.00, 1, '/images?q=tbn:ANd9GcRUlslt2BQxGv66D57_6WZQFL1wZjA0Yc5kJw&s', 'Fish', 'Town', 'N/A', 'N/A'),
( 'Bella', 1, 'Persian', 'Medium', 'White', 'Low', 'Medium', 'Easy', 'Available', 60000.00, 1, '/images?q=tbn:ANd9GcS3v4TLagdbCyqK0Yqv_tzLSkiK9VhfRlxVXg&s', 'Cat', 'City', 'N/A', 'N/A'),
( 'Milo', 2, 'Siamese', 'Small', 'Blue', 'High', 'High', 'Moderate', 'Available', 61000.00, 1, '/images?q=tbn:ANd9GcS7OGh7uFvly9twcvkkit0fAhqD2xtBO0JgoA&s', 'Cat', 'Town', 'Completed', 'Delivered'),
( 'Charlie', 3, 'Golden Retriever', 'Large', 'Golden', 'Low', 'Medium', 'Moderate', 'Available', 62000.00, 1, '/images?q=tbn:ANd9GcT4VfD7hhrpFwVzpzVVubO4JvuoPL9QUzEzIu4&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Rocky', 4, 'Labrador Retriever', 'Large', 'Yellow', 'Low', 'Low', 'Moderate', 'Available', 63000.00, 1, '/images?q=tbn:ANd9GcT2Tb8wH2cH-FG3fA7zN5lQNRfKvRsvAe4ojQ&s', 'Dog', 'City', 'Completed', 'Delivered'),
( 'Max', 1, 'Beagle', 'Medium', 'Tri-color', 'Medium', 'Medium', 'Moderate', 'Available', 64000.00, 1, '/images?q=tbn:ANd9GcQHWFzKvx1V1lzhhg-uFL8DNHGlsdtdgweFBw&s', 'Dog', 'Town', 'N/A', 'N/A'),
( 'Lucy', 1, 'French Bulldog', 'Small', 'Brindle', 'Low', 'Medium', 'Moderate', 'Available', 65000.00, 1, '/images?q=tbn:ANd9GcR-pEm36xlIu51aG9iW0-M3MFehD7vfaTcQKQ&s', 'Dog', 'City', 'Completed', 'Delivered'),
( 'Luna', 7, 'Shih Tzu', 'Small', 'White', 'Low', 'Medium', 'Easy', 'Available', 66000.00, 1, '/images?q=tbn:ANd9GcQBxmgwvM6yL-dFkFVff9B2p3bjbE7PlPrh5Q&s', 'Dog', 'Town', 'N/A', 'N/A'),
( 'Oscar', 8, 'Bulldog', 'Medium', 'Fawn', 'Low', 'Medium', 'Moderate', 'Available', 67000.00, 1, '/images?q=tbn:ANd9GcQ1BLZKqUtNfDC80mtfNf3f9Z-qb_UcjbcdO8g&s', 'Dog', 'City', 'Completed', 'Delivered'),
( 'Sadie', 1, 'Poodle', 'Medium', 'White', 'Low', 'Medium', 'Easy', 'Available', 68000.00, 1, '/images?q=tbn:ANd9GcRyJl26EfeGqO0Yh4JlNRwMcfI4UNtV5MiRHw&s', 'Dog', 'Town', 'N/A', 'N/A'),
( 'Buddy', 2, 'Rottweiler', 'Large', 'Black/Tan', 'High', 'Medium', 'Moderate', 'Available', 69000.00, 1, '/images?q=tbn:ANd9GcQrrbJYy_xJEyQ30UuXtmew9Db-7B3VYpWdrw&s', 'Dog', 'City', 'Completed', 'Delivered'),
( 'Bailey', 2, 'Boxer', 'Large', 'Fawn', 'Medium', 'High', 'Moderate', 'Available', 70000.00, 1, '/images?q=tbn:ANd9GcQ47tmIzoV5yckxIM-vqdujz0a-rZ7qLlr4fcw&s', 'Dog', 'Town', 'N/A', 'N/A'),
( 'Daisy', 2, 'Cocker Spaniel', 'Medium', 'Golden', 'Low', 'Medium', 'Easy', 'Available', 71000.00, 1, '/images?q=tbn:ANd9GcTpdlR8GzE5rzoYfeItbsjj_FcMjifFhfTTnQ&s', 'Dog', 'City', 'Completed', 'Delivered'),
( 'Maggie', 3, 'Yorkshire Terrier', 'Small', 'Tan/Blue', 'Low', 'Low', 'Easy', 'Available', 72000.00, 1, '/images?q=tbn:ANd9GcS02ovN1Tk0CvDnxp8MFHXgytLluyz64MmRDA&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Zoe', 2, 'Pomeranian', 'Small', 'Orange', 'Low', 'Medium', 'Easy', 'Available', 73000.00, 1, '/images?q=tbn:ANd9GcQmyQCVP1vZ7OqLl6_JvsMNpx9M0EYq8j44hQ&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Coco', 2, 'Chihuahua', 'Small', 'Fawn', 'Low', 'High', 'Easy', 'Available', 74000.00, 1, '/images?q=tbn:ANd9GcTbEV7sb-jo-0AV2BdNKX2d6bhG27E2bqBkdg&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Mia', 2, 'Schnauzer', 'Medium', 'Salt and Pepper', 'Low', 'Medium', 'Moderate', 'Available', 75000.00, 1, '/images?q=tbn:ANd9GcQR9N0AfP-ugv7zS05FfY0GmT5b9gIIYYfrDg&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Toby', 2, 'Dachshund', 'Small', 'Red', 'Low', 'Low', 'Easy', 'Available', 76000.00, 1, '/images?q=tbn:ANd9GcSlBbS2hSznNxFqgBLjiT5nCEVJ3Kw9ZZkwqA&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Sammy', 2, 'Shiba Inu', 'Medium', 'Red', 'Medium', 'Medium', 'Moderate', 'Available', 77000.00, 1, '/images?q=tbn:ANd9GcQgZge6j0I1g4cIekQ-Tph1C6jmch4wK9t_tg&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Buster', 2, 'Saint Bernard', 'Large', 'Brown/White', 'Low', 'Medium', 'Moderate', 'Available', 78000.00, 1, '/images?q=tbn:ANd9GcQkpa8AfhcdV7yFwpA7ahSgkSmbnMmzIK2UJg&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Jasper', 3, 'Great Dane', 'Large', 'Blue', 'Medium', 'Medium', 'Moderate', 'Available', 79000.00, 1, '/images?q=tbn:ANd9GcQA_bGzFQx7GcHHv-mx9G1knvHTibkq5FftDg&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Rocky', 3, 'Doberman', 'Medium', 'Black/Tan', 'High', 'Medium', 'Moderate', 'Available', 80000.00, 1, '/images?q=tbn:ANd9GcQ_F5_pKlhU4BkgdtERj8g1TwXfrtIBu5lt8g&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Bella', 2, 'Shih Tzu', 'Small', 'Black/White', 'Low', 'Low', 'Easy', 'Available', 81000.00, 1, '/images?q=tbn:ANd9GcRP-pwyT2xEG2s7x7kJ71hBxZyr6QsIvWGx8w&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Rex', 3, 'German Shepherd', 'Large', 'Black/Tan', 'High', 'High', 'Difficult', 'Available', 82000.00, 1, '/images?q=tbn:ANd9GcTLHZvlq5HjOD_AY8L58k_VyXZbX5Is8K8x9w&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Max', 4, 'Labrador Retriever', 'Large', 'Yellow', 'Medium', 'Medium', 'Moderate', 'Available', 83000.00, 1, '/images?q=tbn:ANd9GcR9hQpHTV7C2NqvfQcz_xTEVAG1aRSjzYY1uA&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Sadie', 5, 'Golden Retriever', 'Large', 'Golden', 'Medium', 'Medium', 'Easy', 'Available', 84000.00, 1, '/images?q=tbn:ANd9GcRUu_njaHR68_t5bcA0AWDYPyDQ4No_oEvgFg&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Duke', 3, 'English Bulldog', 'Medium', 'Brindle', 'Low', 'Low', 'Moderate', 'Available', 85000.00, 1, '/images?q=tbn:ANd9GcT_1Uo9XkH1TXohXa16VZAWkDeZx6RGfu-yDw&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Luna', 3, 'Poodle', 'Medium', 'White', 'Low', 'Medium', 'Easy', 'Available', 86000.00, 1, '/images?q=tbn:ANd9GcS9-VPOqs57J5nReIcq0mngxyTcT6KoMwgbKg&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Teddy', 3, 'Cavalier King Charles Spaniel', 'Small', 'Chestnut/White', 'Low', 'Low', 'Easy', 'Available', 87000.00, 1, '/images?q=tbn:ANd9GcSg-VvHg8zZC8W0YjLEzjl_SuhT02uflfFhBQ&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Lily', 3, 'French Bulldog', 'Small', 'Fawn', 'Low', 'Low', 'Easy', 'Available', 88000.00, 1, '/images?q=tbn:ANd9GcQ0zHkbiwQs2IXM0S07H5lzABzDYo-0UzJWykQ&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Milo', 4, 'Airedale Terrier', 'Medium', 'Tan/Blue', 'Medium', 'Medium', 'Moderate', 'Available', 89000.00, 1, '/images?q=tbn:ANd9GcQ7vVeA3cy9wnJvKTxFyA7Aw5dH2v6ThwFmrw&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Oscar', 1, 'Basset Hound', 'Medium', 'Tan/White', 'Low', 'Low', 'Easy', 'Available', 90000.00, 1, '/images?q=tbn:ANd9GcR-K4YjF_hQFz3J0TKRfV0KMcXyqeVydfFFoA&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Zoe', 2, 'Boxer', 'Large', 'Fawn/White', 'High', 'Medium', 'Moderate', 'Available', 91000.00, 1, '/images?q=tbn:ANd9GcTANHfXBIBV9fDopjwFOc7t2E9VJ-xcmUk2cA&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Chloe', 3, 'Pomeranian', 'Small', 'Orange', 'Low', 'Low', 'Easy', 'Available', 92000.00, 1, '/images?q=tbn:ANd9GcRXgB3JlzGVBzU2vFtpXj5Xf_xRh9Ev76E_lw&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Bailey', 4, 'Beagle', 'Medium', 'Tri-color', 'Medium', 'Low', 'Moderate', 'Available', 93000.00, 1, '/images?q=tbn:ANd9GcSzGFzRrQy7cFC7yZULYYJrxN5Y9-Rv4yyv0g&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Toby', 4, 'Chihuahua', 'Small', 'Fawn', 'Low', 'Low', 'Easy', 'Available', 94000.00, 1, '/images?q=tbn:ANd9GcTYYrcDLyBpnZtR-SvoMZvbOLChQL5_mO1lMw&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Scout', 6, 'Cocker Spaniel', 'Medium', 'Golden', 'Medium', 'Medium', 'Moderate', 'Available', 95000.00, 1, '/images?q=tbn:ANd9GcQJvUJvI7kVltXzqlpKLYvKugU7viXvblREUg&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Lola', 4, 'Dachshund', 'Small', 'Red', 'Low', 'Low', 'Easy', 'Available', 96000.00, 1, '/images?q=tbn:ANd9GcTswcmI8uDbS-vbHZjxHDspukZhsDdJ7M9fvA&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Nina', 4, 'Yorkshire Terrier', 'Small', 'Black/Tan', 'Low', 'Low', 'Easy', 'Available', 97000.00, 1, '/images?q=tbn:ANd9GcQoD4xolFm4gISbhcTrkMlq9Kw7gXv03eq3YQ&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Jack', 4, 'Maltese', 'Small', 'White', 'Low', 'Low', 'Easy', 'Available', 98000.00, 1, '/images?q=tbn:ANd9GcSPGs42YmJ5NO-DFMYNjh1Dzi7nTmBhFiEv5Q&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Maggie', 5, 'Pug', 'Small', 'Fawn/Black', 'Low', 'Low', 'Easy', 'Available', 99000.00, 1, '/images?q=tbn:ANd9GcQYkvh5yxeI2uo8eqtmWSYovXbYFgzF5UNcpw&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Bella', 2, 'Shih Tzu', 'Small', 'Black/White', 'Low', 'Low', 'Easy', 'Available', 101000.00, 1, '/images?q=tbn:ANd9GcThmj9f43uyV6boWrczj35bGGhRPG4w3f6A2Q&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Max', 3, 'Doberman Pinscher', 'Large', 'Black/Tan', 'High', 'High', 'Moderate', 'Available', 102000.00, 1, '/images?q=tbn:ANd9GcQED3Cr1wxeC8w7ZG8nkVLOzGq9ahDlFOg19A&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Luna', 5, 'Australian Shepherd', 'Large', 'Merle', 'High', 'High', 'Moderate', 'Available', 104000.00, 1, '/images?q=tbn:ANd9GcT3lL_Xd64xtqFbMbTn38KAl6Yg3mIhzQ_0Qw&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Rusty', 6, 'Border Collie', 'Medium', 'Black/White', 'High', 'High', 'Moderate', 'Available', 105000.00, 1, '/images?q=tbn:ANd9GcR2nMwIkd7NJv_9-uB8gGeuXyl3jKX8OlwPRQ&s', 'Dog', 'Town', 'Completed', 'Delivered'),
( 'Buddy', 7, 'Golden Retriever', 'Large', 'Golden', 'High', 'Medium', 'Moderate', 'Available', 106000.00, 1, '/images?q=tbn:ANd9GcQF4ih08RnxCn8RmXiJdQ-i0sIepXMY2SY_7w&s', 'Dog', 'City', 'N/A', 'N/A'),
( 'Sasha', 8, 'Pit Bull', 'Medium', 'Blue', 'High', 'Medium', 'Moderate', 'Available', 107000.00, 1, '/images?q=tbn:ANd9GcT7gg5ZFX5C6ya3uAXaJ4WRHH0d2gVOhxl8dA&s', 'Dog', 'Town', 'Completed', 'Delivered');

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
