-- 1. База для RFM
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