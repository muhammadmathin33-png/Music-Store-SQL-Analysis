create database music_store_analysis;

//*1. Who is the senior most employee based on job title?*/

SELECT *
FROM employee
ORDER BY levels DESC
LIMIT 1;


//**Which countries have the most invoices?*/

SELECT billing_country, COUNT(*) AS total_invoices
FROM invoice
GROUP BY billing_country
ORDER BY total_invoices DESC;


//**What are the top 3 values of total invoice?*/

SELECT total
FROM invoice
ORDER BY total DESC
LIMIT 3;

//**Which city has the best customers (highest total sales)?*/

SELECT billing_city, SUM(total) AS total_revenue
FROM invoice
GROUP BY billing_city
ORDER BY total_revenue DESC
LIMIT 1;


//**Who is the best customer (highest total spend)?*/

SELECT c.customer_id, c.first_name, c.last_name, 
       SUM(i.total) AS total_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 1;


//**Rock music listeners (email, name, genre)?*/

SELECT DISTINCT c.email, c.first_name, c.last_name, g.name AS genre
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email;


//**. Top 10 artists who wrote most Rock music?*/

SELECT ar.name AS artist_name, 
       COUNT(t.track_id) AS total_tracks
FROM artist ar
JOIN album2 al ON ar.artist_id = al.artist_id
JOIN track t ON al.album_id = t.album_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
GROUP BY ar.artist_id, ar.name
ORDER BY total_tracks DESC
LIMIT 10;


//**Tracks longer than average song length?*/

SELECT name, milliseconds
FROM track
WHERE milliseconds > (
    SELECT AVG(milliseconds)
    FROM track
)
ORDER BY milliseconds DESC;


//**Amount spent by each customer on each artist?*/

SELECT 
    c.first_name, 
    c.last_name, 
    ar.name AS artist_name,
    SUM(il.unit_price * il.quantity) AS total_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN album2 al ON t.album_id = al.album_id
JOIN artist ar ON al.artist_id = ar.artist_id
GROUP BY 
    c.customer_id, 
    c.first_name, 
    c.last_name,
    ar.artist_id,
    ar.name
ORDER BY total_spent DESC;


//**Most popular music genre for each country?*/

WITH genre_sales AS (
    SELECT i.billing_country, g.name AS genre,
           COUNT(il.invoice_line_id) AS purchases,
           RANK() OVER (
               PARTITION BY i.billing_country 
               ORDER BY COUNT(il.invoice_line_id) DESC
           ) AS rank_genre
    FROM invoice i
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY i.billing_country, g.name
)
SELECT billing_country, genre, purchases
FROM genre_sales
WHERE rank_genre = 1;


//**Top customer by spending for each country?*/

WITH customer_spending AS (
    SELECT 
        i.billing_country, 
        c.customer_id,
        c.first_name, 
        c.last_name,
        SUM(i.total) AS total_spent,
        RANK() OVER (
            PARTITION BY i.billing_country
            ORDER BY SUM(i.total) DESC
        ) AS rank_customer
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    GROUP BY 
        i.billing_country, 
        c.customer_id, 
        c.first_name, 
        c.last_name
)
SELECT 
    billing_country, 
    first_name, 
    last_name, 
    total_spent
FROM customer_spending
WHERE rank_customer = 1;

