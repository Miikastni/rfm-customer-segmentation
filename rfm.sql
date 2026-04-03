-- 1. База для RFM (Pipeline)
CREATE TABLE rfm_base AS
SELECT
    CustomerID,
    MAX(InvoiceDate) AS last_purchase,
    COUNT(DISTINCT InvoiceNo) AS frequency,
    SUM(Quantity * UnitPrice) AS monetary
FROM retail_clean
WHERE CustomerID IS NOT NULL
  AND Quantity > 0
  AND UnitPrice > 0
GROUP BY CustomerID;

-- 2. Добавляем recency (в днях)
CREATE TABLE rfm AS
SELECT
    CustomerID,
    last_purchase,
    ('2011-12-31'::date - last_purchase::date) AS recency,
    frequency,
    monetary
FROM rfm_base;

-- 3. Присваиваем RFM scores
CREATE TABLE rfm_scores AS
SELECT
    *,
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency) AS f_score,
    NTILE(5) OVER (ORDER BY monetary) AS m_score
FROM rfm;

-- 4. Финальный RFM сегмент
CREATE TABLE rfm_final AS
SELECT
    *,
    CONCAT(r_score, f_score, m_score) AS rfm_segment
FROM rfm_scores;

-- Распределение клиентов по сегментам (Запросы)
SELECT
    rfm_segment,
    COUNT(*) AS users_count
FROM rfm_final
GROUP BY rfm_segment
ORDER BY users_count DESC;

-- Топ клиенты (лучшие)
SELECT *
FROM rfm
ORDER BY rfm_score DESC
LIMIT 10;

-- Худшие клиенты
SELECT *
FROM rfm
ORDER BY r_score + f_score + m_score DESC
LIMIT 10;

-- Средние показатели по сегментам 
SELECT 
    rfm_segment, 
    ROUND(AVG(recency), 2 ) AS avg_recency, 
    ROUND(AVG(frequency), 2 ) AS avg_frequency, 
    ROUND(AVG(monetary), 2 ) AS avg_monetary 
FROM rfm 
GROUP BY rfm_segment ORDER BY avg_monetary DESC ; 

-- Вклад сегментов в выручку
SELECT
    rfm_segment,
    SUM(monetary) AS total_revenue
FROM rfm
GROUP BY rfm_segment
ORDER BY total_revenue DESC;

-- Доля клиентов по сегментам
SELECT
    rfm_segment,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS percent
FROM rfm
GROUP BY rfm_segment
ORDER BY percent DESC;
