-- HOSPITAL DATABASE ANALYSIS
-- Author: Meghana Atluri

USE hospital_db;

-- Join Tables
SELECT 
    a.appointment_id,
    p.first_name AS patient_name,
    d.first_name AS doctor_name,
    a.appointment_date,
    a.reason_for_visit
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
JOIN doctors d ON a.doctor_id = d.doctor_id
LIMIT 5;


-- ======================
-- APPOINTMENTS INSIGHTS
-- ======================

-- List all appointments with patient and doctor names
SELECT 
    a.appointment_id,
    p.first_name AS patient_name,
    d.first_name AS doctor_name,
    a.appointment_date,
    a.reason_for_visit
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
JOIN doctors d ON a.doctor_id = d.doctor_id
ORDER BY a.appointment_date;

-- Appointments only for male patients
SELECT 
    a.appointment_id, p.first_name, p.gender, a.appointment_date
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
WHERE p.gender = 'M';

-- Appointments that happened in the past 2 years
SELECT 
    appointment_id, 
    appointment_date, 
    status
FROM appointments
WHERE appointment_date >= CURDATE() - INTERVAL 730 DAY;

-- List of appointments that were cancelled
SELECT *
FROM appointments
WHERE status = 'Cancelled';

-- Appointment Rate by status
SELECT 
    status,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM appointments), 2) AS percentage
FROM appointments
GROUP BY status;

-- Latest appointment for each patient
SELECT 
    a.patient_id, 
    MAX(a.appointment_date) AS last_appointment
FROM appointments a
GROUP BY a.patient_id;

-- Appointments scheduled at a specific time
SELECT *
FROM appointments
WHERE MONTH(appointment_date) = 12
  AND YEAR(appointment_date) = 2023
  
-- Top 5 most common reasons patients visited
SELECT 
    reason_for_visit, 
    COUNT(*) AS total_visits
FROM appointments
GROUP BY reason_for_visit
ORDER BY total_visits DESC
LIMIT 5; 


-- =====================
-- PATIENT DEMOGRAPHICS
-- =====================

-- Categorize patients into age groups: Child, Adult, Senior
SELECT 
    patient_id,
    first_name,
    last_name,
    TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) AS age,
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) < 18 THEN 'Child'
        WHEN TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) BETWEEN 18 AND 59 THEN 'Adult'
        ELSE 'Senior'
    END AS age_group
FROM patients;

-- List patients who have not provided insurance details
SELECT * 
FROM patients
WHERE insurance_provider IS NULL OR insurance_number IS NULL;

-- Patients who had more than 3 appointments
SELECT 
    p.patient_id,
    p.first_name,
    COUNT(a.appointment_id) AS total_appointments
FROM patients p
JOIN appointments a ON p.patient_id = a.patient_id
GROUP BY p.patient_id, p.first_name
HAVING COUNT(a.appointment_id) > 3
ORDER BY total_appointments DESC;

-- Find duplicate patient records by email
SELECT email, COUNT(*) 
FROM patients
GROUP BY email
HAVING COUNT(*) > 1;


-- =========
-- BILLING 
-- =========

-- Calculate total revenue from fully paid bills
SELECT 
    ROUND(SUM(amount),2)  AS total_revenue
FROM billing
WHERE payment_status = 'Paid';

-- Find unpaid bills along with patient details
SELECT 
    b.bill_id, 
    p.first_name, 
    b.amount, 
    b.payment_status
FROM billing b
JOIN patients p ON b.patient_id = p.patient_id
WHERE b.payment_status != 'Paid';

-- All bills where amount > 3000
SELECT *
FROM billing
WHERE amount > 3000
ORDER BY amount DESC;

-- Total amount spent by each patient
SELECT 
    p.patient_id, 
    p.first_name, 
    SUM(b.amount) AS total_spent
FROM patients p
JOIN billing b ON p.patient_id = b.patient_id
GROUP BY p.patient_id, p.first_name
ORDER BY total_spent DESC;

-- Count by payment method
SELECT 
    payment_method, 
    COUNT(*) AS num_payments
FROM billing
GROUP BY payment_method
ORDER BY num_payments DESC;

-- Average Bill Amount by Payment Method
SELECT 
    payment_method,
    ROUND(AVG(amount), 2) AS avg_bill
FROM billing
GROUP BY payment_method
ORDER BY avg_bill DESC;

-- Patients who spent more than the average treatment cost
SELECT *
FROM patients
WHERE patient_id IN (
  SELECT b.patient_id
  FROM billing b
  JOIN treatments t ON b.treatment_id = t.treatment_id
  GROUP BY b.patient_id
  HAVING SUM(b.amount) > (
      SELECT AVG(cost) FROM treatments
  )
);

-- Rank patients by total billing amount 
SELECT 
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    SUM(b.amount) AS total_spent,
    RANK() OVER (ORDER BY SUM(b.amount) DESC) AS spend_rank
FROM billing b
JOIN patients p ON b.patient_id = p.patient_id
GROUP BY p.patient_id;


-- ================
-- DOCTOR ANALYSIS
-- ================

-- List experienced doctors with 20+ years of service
SELECT 
    first_name, 
    last_name, 
    specialization, 
    years_experience
FROM doctors
WHERE years_experience >= 20;

-- Total number of appointments per doctor
SELECT 
    d.first_name, 
    COUNT(a.appointment_id) AS num_appointments
FROM doctors d
JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.first_name
ORDER BY num_appointments DESC;

-- Number of doctors in each specialization
SELECT 
    specialization, 
    COUNT(*) AS num_doctors
FROM doctors
GROUP BY specialization
ORDER BY num_doctors DESC;

-- Revenue by Specialization
SELECT 
    d.specialization,
    ROUND(SUM(b.amount), 2) AS total_revenue
FROM appointments a
JOIN doctors d ON a.doctor_id = d.doctor_id
JOIN billing b ON a.patient_id = b.patient_id
WHERE b.payment_status = 'Paid'
GROUP BY d.specialization
ORDER BY total_revenue DESC;


-- ====================
-- TREATMENT ANALYTICS
-- ====================

-- Average cost of each treatment type
SELECT 
    treatment_type, 
    ROUND(AVG(cost), 2) AS avg_cost
FROM treatments
GROUP BY treatment_type
ORDER BY avg_cost DESC;

-- Top 5 most expensive treatments
SELECT *
FROM treatments
ORDER BY cost DESC
LIMIT 5;

-- Top 3 most commonly performed treatment types
SELECT 
    treatment_type, 
    COUNT(*) AS frequency
FROM treatments
GROUP BY treatment_type
ORDER BY frequency DESC
LIMIT 3;


-- ==========
-- SECTION 6
-- ==========

-- Combined list of all unique emails (patients and doctors)
SELECT email FROM patients
UNION
SELECT email FROM doctors;

-- appointment info
CREATE VIEW appointment_summary AS
SELECT 
    a.appointment_id,
    p.first_name AS patient,
    d.first_name AS doctor,
    a.appointment_date,
    a.reason_for_visit
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
JOIN doctors d ON a.doctor_id = d.doctor_id;
SELECT * FROM appointment_summary WHERE appointment_date > '2023-12-01';


 
















